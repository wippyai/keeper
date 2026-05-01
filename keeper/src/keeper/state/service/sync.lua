local logger = require("logger")
local consts = require("consts")
local materialize = require("materialize")
local state_ops = require("state_ops")
local gov_consts = require("gov_consts")
local reconcile = require("reconcile")

local log = logger:named("state.sync")

local REGISTRY_OPS = gov_consts.REGISTRY_OPERATIONS

local M = {}

type RegistryChange = {
    kind: string?,
    entry: { id: string?, kind: string? }?,
}

type SyncArgs = {
    changeset: {RegistryChange}?,
    version: unknown?,
    is_version_operation: boolean?,
}

function M.requires_reconciliation(changeset)
    if type(changeset) ~= "table" then return false end
    for _, op in ipairs(changeset) do
        local entry = type(op.entry) == "table" and op.entry or {}
        if entry.kind == "ns.dependency" then
            return true
        end
    end
    return false
end

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

local function run(args: SyncArgs, deps)
    deps = deps or {}
    local reconcile_mod = (deps.reconcile or reconcile) :: any
    local state_ops_mod = (deps.state_ops or state_ops) :: any
    local materialize_mod = (deps.materialize or materialize) :: any

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

    if M.requires_reconciliation(args.changeset) then
        log:info("Dependency directive changed; running full state reconciliation", {
            changeset_count = #args.changeset,
            version = args.version,
        })
        local result, reconcile_err = reconcile_mod.run({
            reason = "dependency directive changed",
            version = args.version,
        })
        if not result or result.success == false then
            return {
                success = false,
                error = reconcile_err or (result and result.error) or "state reconciliation failed",
                version = args.version,
            }
        end
        result.version = args.version
        result.dependency_reconcile = true
        return result
    end

    log:info("Converting changeset to state commands", {
        changeset_count = #args.changeset
    })

    local commands, conversion_errors = convert_ops(args.changeset, materialize_mod, consts.BRANCH.MAIN)

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

    local result, apply_err = state_ops_mod.apply_commands(commands)
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
