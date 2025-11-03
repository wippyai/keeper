local registry = require("registry")
local json = require("json")
local logger = require("logger")
local time = require("time")
local consts = require("consts")
local materialize = require("materialize")
local state_client = require("state_client")

local log = logger:named("state.sync_branch")

local function run(args)
    log:info("Branch sync worker starting", {
        branch = args.branch,
        entry_count = args.entry_ids and #args.entry_ids or 0
    })

    if not args.branch or args.branch == "" then
        log:error("Missing branch parameter")
        return {
            success = false,
            error = "Branch parameter required"
        }
    end

    if not args.entry_ids or type(args.entry_ids) ~= "table" or #args.entry_ids == 0 then
        log:error("Missing or invalid entry_ids parameter")
        return {
            success = false,
            error = "entry_ids parameter required (non-empty array)"
        }
    end

    log:info("Getting registry snapshot")
    local snapshot, err = registry.snapshot()
    if err then
        log:error("Failed to get registry snapshot", { error = err })
        return {
            success = false,
            error = "Failed to get registry snapshot: " .. err
        }
    end

    local entries = snapshot:entries()
    local entry_id_set = {}
    for _, id in ipairs(args.entry_ids) do
        entry_id_set[id] = true
    end

    log:info("Materializing entries for branch", {
        branch = args.branch,
        total_entries = #entries
    })

    local commands = {}
    local materialization_errors = {}

    for _, entry in ipairs(entries) do
        if entry_id_set[entry.id] then
            local mat, mat_err = materialize.entry(entry)
            if not mat then
                log:warn("Failed to materialize entry", {
                    entry_id = entry.id,
                    error = mat_err
                })
                table.insert(materialization_errors, {
                    entry_id = entry.id,
                    error = "Materialization failed: " .. (mat_err or "unknown error")
                })
            else
                local cmd = materialize.to_set_command(mat, args.branch)
                table.insert(commands, cmd)

                local edges = materialize.extract_edges(entry)
                local edge_commands = materialize.edges_to_commands(edges, args.branch)
                for _, edge_cmd in ipairs(edge_commands) do
                    table.insert(commands, edge_cmd)
                end
            end
        end
    end

    if #materialization_errors > 0 then
        log:error("Failed to materialize some entries", {
            error_count = #materialization_errors
        })
        return {
            success = false,
            error = "Failed to materialize entries",
            materialization_errors = materialization_errors
        }
    end

    if #commands == 0 then
        log:info("No commands to execute for branch sync")
        return {
            success = true,
            changes_made = false,
            branch = args.branch
        }
    end

    log:info("Executing commands for branch sync", {
        command_count = #commands,
        branch = args.branch
    })

    local success, exec_err = state_client.execute_commands(commands)
    if not success then
        log:error("Failed to execute commands", { error = exec_err })
        return {
            success = false,
            error = "Failed to execute commands: " .. exec_err
        }
    end

    log:info("Branch sync completed successfully", {
        branch = args.branch,
        command_count = #commands
    })

    return {
        success = true,
        changes_made = true,
        command_count = #commands,
        branch = args.branch
    }
end

return { run = run }
