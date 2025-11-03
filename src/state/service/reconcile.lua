local registry = require("registry")
local sql = require("sql")
local logger = require("logger")
local time = require("time")
local consts = require("consts")
local state_client = require("state_client")
local state_reader = require("state_reader")
local materialize = require("materialize")

local log = logger:named("state.reconcile")

local function get_state_entries(branch)
    log:info("Loading state entries", {branch = branch})

    local reader, err = state_reader.for_branch(branch)
    if err then
        log:error("Failed to create state reader", {error = err})
        return nil, err
    end

    local entries, err = reader:include_chunks():all()
    if err then
        log:error("Failed to read state entries", {error = err})
        return nil, err
    end

    log:info("State entries loaded", {count = #entries})

    local entries_by_id = {}
    for _, entry in ipairs(entries) do
        local def_hash = nil
        local content_hash = nil

        if entry.chunks then
            for _, chunk in ipairs(entry.chunks) do
                if chunk.type == consts.CHUNK_TYPE.DEFINITION then
                    def_hash = chunk.hash
                elseif chunk.type == consts.CHUNK_TYPE.CONTENT then
                    content_hash = chunk.hash
                end
            end
        end

        entries_by_id[entry.id] = {
            id = entry.id,
            kind = entry.kind,
            definition_hash = def_hash,
            content_hash = content_hash
        }
    end

    return entries_by_id, nil
end

local function get_state_edges(branch)
    log:info("Loading state edges", {branch = branch})

    local reader, err = state_reader.for_edges(branch)
    if err then
        log:error("Failed to create edge reader", {error = err})
        return nil, err
    end

    local edges, err = reader:all()
    if err then
        log:error("Failed to read state edges", {error = err})
        return nil, err
    end

    log:info("State edges loaded", {count = #edges})

    local edge_map = {}
    for _, edge in ipairs(edges) do
        local key = edge.source_id .. "|" .. edge.target_id .. "|" .. edge.edge_type
        edge_map[key] = true
    end

    return edge_map, nil
end

local function reconcile()
    log:info("Starting state reconciliation")

    log:info("Getting registry snapshot")
    local snapshot, err = registry.snapshot()
    if err then
        log:error("Failed to get registry snapshot", { error = err })
        return nil, err
    end

    log:info("Getting registry entries")
    local registry_entries, err = snapshot:entries()
    if err then
        log:error("Failed to get registry entries", { error = err })
        return nil, err
    end

    log:info("Retrieved registry entries", { count = #registry_entries })

    log:info("Loading state entries from database")
    local state_entries, err = get_state_entries(consts.BRANCH.MAIN)
    if err then
        log:error("Failed to get state entries", { error = err })
        return nil, err
    end

    log:info("Loading state edges from database")
    local state_edges, err = get_state_edges(consts.BRANCH.MAIN)
    if err then
        log:error("Failed to get state edges", { error = err })
        return nil, err
    end

    local state_count = 0
    for _ in pairs(state_entries) do
        state_count = state_count + 1
    end

    log:info("Retrieved state entries", { count = state_count })
    log:info("Starting entry reconciliation", { total = #registry_entries })

    local commands = {}
    local stats = {
        created = 0,
        updated = 0,
        unchanged = 0,
        failed = 0
    }

    local registry_ids = {}
    local progress_interval = 100
    local last_progress = 0

    for i, entry in ipairs(registry_entries) do
        log:debug("Processing entry", { index = i, id = entry.id })

        if i - last_progress >= progress_interval then
            log:info("Reconciliation progress", {
                processed = i,
                total = #registry_entries,
                percent = math.floor((i / #registry_entries) * 100),
                created = stats.created,
                updated = stats.updated,
                unchanged = stats.unchanged,
                failed = stats.failed
            })
            last_progress = i
        end

        registry_ids[entry.id] = true

        local materialized, mat_err = materialize.entry(entry)
        if not materialized then
            log:warn("Failed to materialize entry", { id = entry.id, error = mat_err })
            stats.failed = stats.failed + 1
            goto continue
        end

        local state_entry = state_entries[entry.id]

        if not state_entry then
            local cmd, cmd_err = materialize.to_set_command(materialized, consts.BRANCH.MAIN)
            if cmd then
                table.insert(commands, cmd)
                stats.created = stats.created + 1

                local edges = materialize.extract_edges(entry)
                local edge_commands = materialize.edges_to_commands(edges, consts.BRANCH.MAIN)
                for _, edge_cmd in ipairs(edge_commands) do
                    table.insert(commands, edge_cmd)
                end
            else
                log:warn("Failed to create command", { id = entry.id, error = cmd_err })
                stats.failed = stats.failed + 1
            end
        else
            local needs_update = false

            if state_entry.definition_hash ~= materialized.definition_hash then
                needs_update = true
            end

            if materialized.content_hash and state_entry.content_hash ~= materialized.content_hash then
                needs_update = true
            end

            if needs_update then
                local cmd, cmd_err = materialize.to_set_command(materialized, consts.BRANCH.MAIN)
                if cmd then
                    table.insert(commands, cmd)
                    stats.updated = stats.updated + 1

                    local edges = materialize.extract_edges(entry)
                    local edge_commands = materialize.edges_to_commands(edges, consts.BRANCH.MAIN)
                    for _, edge_cmd in ipairs(edge_commands) do
                        table.insert(commands, edge_cmd)
                    end
                else
                    log:warn("Failed to create update command", { id = entry.id, error = cmd_err })
                    stats.failed = stats.failed + 1
                end
            else
                stats.unchanged = stats.unchanged + 1

                local edges = materialize.extract_edges(entry)
                for _, edge in ipairs(edges) do
                    local edge_key = edge.source_id .. "|" .. edge.target_id .. "|" .. edge.edge_type
                    if not state_edges[edge_key] then
                        local edge_commands = materialize.edges_to_commands({ edge }, consts.BRANCH.MAIN)
                        for _, edge_cmd in ipairs(edge_commands) do
                            table.insert(commands, edge_cmd)
                        end
                    end
                end
            end
        end

        ::continue::
    end

    log:info("Checking for deleted entries")

    for entry_id, _ in pairs(state_entries) do
        if not registry_ids[entry_id] then
            local cmd, cmd_err = materialize.to_delete_command(entry_id, consts.BRANCH.MAIN)
            if cmd then
                table.insert(commands, cmd)
                log:info("Entry deleted from registry", { id = entry_id })
            else
                log:warn("Failed to create delete command", { id = entry_id, error = cmd_err })
            end
        end
    end

    log:info("Reconciliation analysis complete", {
        total_commands = #commands,
        created = stats.created,
        updated = stats.updated,
        unchanged = stats.unchanged,
        failed = stats.failed
    })

    if #commands == 0 then
        log:info("No changes to apply")
        return {
            success = true,
            changes_made = false,
            stats = stats
        }
    end

    local batch_size = 100
    local total_batches = math.ceil(#commands / batch_size)

    log:info("Sending commands in batches", {
        total_commands = #commands,
        batch_size = batch_size,
        total_batches = total_batches
    })

    for i = 1, #commands, batch_size do
        local batch_end = math.min(i + batch_size - 1, #commands)
        local batch = {}
        for j = i, batch_end do
            table.insert(batch, commands[j])
        end

        local batch_num = math.floor((i - 1) / batch_size) + 1
        log:info("Preparing to send batch", {
            batch = batch_num,
            total = total_batches,
            commands = #batch
        })

        log:info("Calling state_client.execute_commands", {
            batch = batch_num,
            command_count = #batch
        })

        local success, send_err = state_client.execute_commands(batch)

        log:info("state_client.execute_commands returned", {
            batch = batch_num,
            success = success,
            error = send_err
        })

        if not success then
            log:error("Failed to send batch", {
                batch = batch_num,
                error = send_err
            })
            return nil, send_err
        end

        log:info("Batch sent successfully", {
            batch = batch_num,
            total = total_batches
        })
    end

    log:info("Reconciliation completed successfully", stats)

    return {
        success = true,
        changes_made = true,
        stats = stats,
        commands_sent = #commands
    }
end

local function run(args)
    log:info("State reconciliation worker starting")

    local result, err = reconcile()
    if err then
        log:error("Reconciliation failed", { error = err })
        return { success = false, error = err }
    end

    log:info("Reconciliation worker exiting with result", {
        success = result.success,
        changes_made = result.changes_made
    })

    return result
end

return { run = run }