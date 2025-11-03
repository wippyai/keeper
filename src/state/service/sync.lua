local json = require("json")
local logger = require("logger")
local sql = require("sql")
local consts = require("consts")
local materialize = require("materialize")
local state_ops = require("state_ops")

local log = logger:named("state.sync")

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

    local commands = {}
    local conversion_errors = {}

    for i, op in ipairs(args.changeset) do
        log:debug("Processing changeset operation", {
            index = i,
            kind = op.kind,
            entry_id = op.entry and op.entry.id or "unknown"
        })

        if op.kind == "entry.create" or op.kind == "entry.update" then
            local mat, mat_err = materialize.entry(op.entry)
            if not mat then
                log:warn("Failed to materialize entry", {
                    entry_id = op.entry.id,
                    error = mat_err
                })
                table.insert(conversion_errors, {
                    index = i,
                    entry_id = op.entry.id,
                    error = "Materialization failed: " .. (mat_err or "unknown error")
                })
            else
                local cmd, cmd_err = materialize.to_set_command(mat, consts.BRANCH.MAIN)
                if not cmd then
                    log:warn("Failed to create set command", {
                        entry_id = op.entry.id,
                        error = cmd_err
                    })
                    table.insert(conversion_errors, {
                        index = i,
                        entry_id = op.entry.id,
                        error = "Command creation failed: " .. (cmd_err or "unknown error")
                    })
                else
                    table.insert(commands, cmd)

                    local edges = materialize.extract_edges(op.entry)
                    local edge_commands = materialize.edges_to_commands(edges, consts.BRANCH.MAIN)
                    for _, edge_cmd in ipairs(edge_commands) do
                        table.insert(commands, edge_cmd)
                    end
                end
            end
        elseif op.kind == "entry.delete" then
            local cmd, cmd_err = materialize.to_delete_command(op.entry.id, consts.BRANCH.MAIN)
            if not cmd then
                log:warn("Failed to create delete command", {
                    entry_id = op.entry.id,
                    error = cmd_err
                })
                table.insert(conversion_errors, {
                    index = i,
                    entry_id = op.entry.id,
                    error = "Delete command creation failed: " .. (cmd_err or "unknown error")
                })
            else
                table.insert(commands, cmd)
            end
        end
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

    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then
        log:error("Failed to connect to database", {error = err})
        return {
            success = false,
            error = consts.ERRORS.DB_CONNECTION_FAILED .. ": " .. err
        }
    end

    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        log:error("Failed to begin transaction", {error = tx_err})
        return {
            success = false,
            error = "Failed to begin transaction: " .. tx_err
        }
    end

    local result, exec_err = state_ops.execute(tx, commands)
    if exec_err then
        tx:rollback()
        db:release()
        log:error("Command execution failed", {error = exec_err})
        return {
            success = false,
            error = "Command execution failed: " .. exec_err
        }
    end

    local commit_success, commit_err = tx:commit()
    if commit_err then
        tx:rollback()
        db:release()
        log:error("Failed to commit transaction", {error = commit_err})
        return {
            success = false,
            error = "Failed to commit transaction: " .. commit_err
        }
    end

    db:release()

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

return { run = run }