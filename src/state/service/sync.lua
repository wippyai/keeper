local logger = require("logger")
local consts = require("consts")
local materialize = require("materialize")
local state_ops = require("state_ops")
local gov_consts = require("gov_consts")

local log = logger:named("state.sync")

local REGISTRY_OPS = gov_consts.REGISTRY_OPERATIONS

local M = {}

function M.convert_ops(changeset, mat, branch)
    local commands = {}
    local delete_commands = {}
    local errors = {}

    for i, op in ipairs(changeset) do
        if op.kind == REGISTRY_OPS.CREATE or op.kind == REGISTRY_OPS.UPDATE then
            local m, mat_err = mat.entry(op.entry)
            if not m then
                table.insert(errors, {
                    index = i,
                    entry_id = op.entry.id,
                    error = "Materialization failed: " .. (mat_err or "unknown error"),
                })
            else
                local cmd, cmd_err = mat.to_set_command(m, branch)
                if not cmd then
                    table.insert(errors, {
                        index = i,
                        entry_id = op.entry.id,
                        error = "Command creation failed: " .. (cmd_err or "unknown error"),
                    })
                else
                    table.insert(commands, cmd)
                    local edges = mat.extract_edges(op.entry)
                    local edge_commands = mat.edges_to_commands(edges, branch)
                    for _, edge_cmd in ipairs(edge_commands) do
                        table.insert(commands, edge_cmd)
                    end
                end
            end
        elseif op.kind == REGISTRY_OPS.DELETE then
            local cmd, cmd_err = mat.to_delete_command(op.entry.id, branch)
            if not cmd then
                table.insert(errors, {
                    index = i,
                    entry_id = op.entry.id,
                    error = "Delete command creation failed: " .. (cmd_err or "unknown error"),
                })
            else
                table.insert(delete_commands, cmd)
            end
        end
    end

    for _, cmd in ipairs(delete_commands) do
        table.insert(commands, cmd)
    end

    return commands, errors
end
local convert_ops = M.convert_ops

local function run(args)
    log:info("Registry changeset sync worker starting", {
        changeset_count = args.changeset and #args.changeset or 0,
        version = args.version,
        is_version_operation = args.is_version_operation
    })

    if not args.changeset or #args.changeset == 0 then
        log:info("No changes to sync")
        return {
            success = true,
            changes_made = false,
            version = args.version
        }
    end

    log:info("Converting changeset to state commands", {
        changeset_count = #args.changeset
    })

    local commands, conversion_errors = convert_ops(args.changeset, materialize, consts.BRANCH.MAIN)

    for _, e in ipairs(conversion_errors) do
        log:warn("Changeset op failed", { index = e.index, entry_id = e.entry_id, error = e.error })
    end

    if #conversion_errors > 0 then
        log:error("Failed to convert some changeset operations", {
            error_count = #conversion_errors
        })
        return {
            success = false,
            error = "Failed to convert registry changes",
            conversion_errors = conversion_errors
        }
    end

    if #commands == 0 then
        log:info("No commands generated from changeset")
        return {
            success = true,
            changes_made = false,
            version = args.version
        }
    end

    log:info("Applying commands to state database", {
        command_count = #commands
    })

    local result, apply_err = state_ops.apply_commands(commands)
    if apply_err then
        log:error("Failed to apply commands", { error = apply_err })
        return {
            success = false,
            error = apply_err
        }
    end

    log:info("Changeset synced successfully", {
        command_count = #commands,
        changes_made = result.changes_made,
        version = args.version
    })

    return {
        success = true,
        changes_made = result.changes_made,
        command_count = #commands,
        version = args.version
    }
end

M.run = run
return M