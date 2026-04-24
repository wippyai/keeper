local registry = require("registry")
local logger = require("logger")
local materialize = require("materialize")
local state_ops = require("state_ops")

local log = logger:named("state.sync_branch")

local M = {}

function M.validate_args(args)
    if not args or not args.branch or args.branch == "" then
        return "Branch parameter required"
    end
    if not args.entry_ids or type(args.entry_ids) ~= "table" or #args.entry_ids == 0 then
        return "entry_ids parameter required (non-empty array)"
    end
    return nil
end
local validate_args = M.validate_args

function M.build_branch_commands(entries, entry_ids, mat, branch)
    local entry_id_set = {}
    for _, id in ipairs(entry_ids) do entry_id_set[id] = true end

    local commands = {}
    local errors = {}

    for _, entry in ipairs(entries) do
        if entry_id_set[entry.id] then
            local m, mat_err = mat.entry(entry)
            if not m then
                table.insert(errors, {
                    entry_id = entry.id,
                    error = "Materialization failed: " .. (mat_err or "unknown error"),
                })
            else
                table.insert(commands, mat.to_set_command(m, branch))
                local edges = mat.extract_edges(entry)
                local edge_commands = mat.edges_to_commands(edges, branch)
                for _, edge_cmd in ipairs(edge_commands) do
                    table.insert(commands, edge_cmd)
                end
            end
        end
    end

    return commands, errors
end
local build_branch_commands = M.build_branch_commands

local function run(args)
    log:info("Branch sync worker starting", {
        branch = args.branch,
        entry_count = args.entry_ids and #args.entry_ids or 0
    })

    local verr = validate_args(args)
    if verr then
        log:error("Invalid sync_branch args", { error = verr })
        return { success = false, error = verr }
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

    log:info("Materializing entries for branch", {
        branch = args.branch,
        total_entries = #entries
    })

    local commands, materialization_errors = build_branch_commands(entries, args.entry_ids, materialize, args.branch)

    for _, e in ipairs(materialization_errors) do
        log:warn("Failed to materialize entry", { entry_id = e.entry_id, error = e.error })
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

    local _, apply_err = state_ops.apply_commands(commands)
    if apply_err then
        log:error("Failed to apply commands", { error = apply_err })
        return {
            success = false,
            error = apply_err
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

M.run = run
return M
