local json = require("json")
local security = require("security")
local ctx = require("ctx")
local workspace = require("workspace")
local snapshot = require("snapshot")
local governance_client = require("governance_client")
local registry = require("registry")
local writer = require("writer")

-- Convert workspace changes to registry changeset format with operation reconciliation
local function convert_workspace_to_changeset(session)
    -- Get all dirty entries from workspace
    local dirty_entries, err = session:get_dirty_entries()
    if err then
        return nil, "Failed to get workspace changes: " .. err
    end

    if #dirty_entries == 0 then
        return {}, nil -- Empty changeset, no error
    end

    local changeset = {}
    local conversion_errors = {}
    local skipped_entries = {}

    for _, dirty_entry in ipairs(dirty_entries) do
        -- Get full workspace entry data
        local workspace_entry_data, err = session:get_workspace(dirty_entry.entry_id)
        if not workspace_entry_data then
            table.insert(conversion_errors, {
                entry_id = dirty_entry.entry_id,
                error = "Could not retrieve workspace entry data: " .. (err or "unknown error")
            })
            goto continue
        end

        -- Check current registry state to reconcile operations
        local registry_entry, _ = registry.get(dirty_entry.entry_id)
        local exists_in_registry = registry_entry ~= nil

        if workspace_entry_data._deleted then
            -- Handle deletion - but check if entry actually exists
            if exists_in_registry then
                table.insert(changeset, {
                    kind = "entry.delete",
                    entry = {
                        id = dirty_entry.entry_id
                    }
                })
            else
                -- Entry doesn't exist in registry, skip delete operation
                table.insert(skipped_entries, {
                    entry_id = dirty_entry.entry_id,
                    reason = "Cannot delete non-existent entry"
                })
            end
        else
            -- Handle create/update - reconcile with registry state
            local registry_entry = {
                id = dirty_entry.entry_id,
                kind = workspace_entry_data.kind,
                meta = workspace_entry_data.meta or {},
                data = workspace_entry_data.data or {}
            }

            -- Determine the correct operation based on current registry state
            local operation_kind
            if dirty_entry.operation_type == "create" then
                if exists_in_registry then
                    -- Workspace thinks it's creating, but entry exists → change to update
                    operation_kind = "entry.update"
                else
                    -- Entry doesn't exist, create is correct
                    operation_kind = "entry.create"
                end
            elseif dirty_entry.operation_type == "update" then
                if exists_in_registry then
                    -- Entry exists, update is correct
                    operation_kind = "entry.update"
                else
                    -- Workspace thinks it's updating, but entry doesn't exist → change to create
                    operation_kind = "entry.create"
                end
            else
                -- Fallback to workspace operation type
                operation_kind = dirty_entry.operation_type == "create" and "entry.create" or "entry.update"
            end

            table.insert(changeset, {
                kind = operation_kind,
                entry = registry_entry
            })
        end

        ::continue::
    end

    -- Report conversion errors if any
    if #conversion_errors > 0 then
        local error_msg = "Failed to convert some workspace entries:\n"
        for _, err_info in ipairs(conversion_errors) do
            error_msg = error_msg .. "- " .. err_info.entry_id .. ": " .. err_info.error .. "\n"
        end
        return nil, error_msg
    end

    return changeset, nil
end

-- Format governance result for user display
local function format_result(result, changeset_size, skipped_count)
    local output = {}

    table.insert(output, "=== REGISTRY PUSH RESULT ===")
    table.insert(output, "")
    table.insert(output, "Processed " .. changeset_size .. " changes")

    if skipped_count and skipped_count > 0 then
        table.insert(output, "Skipped " .. skipped_count .. " operations (no-ops)")
    end

    if result.version then
        table.insert(output, "Registry version: " .. result.version)
    end

    if result.message then
        table.insert(output, "Message: " .. result.message)
    end

    -- Show validation details if present
    if result.details and #result.details > 0 then
        table.insert(output, "")
        table.insert(output, "Processing Details:")
        for i, detail in ipairs(result.details) do
            local detail_type = detail.type and ("[" .. detail.type:upper() .. "]") or "[INFO]"
            table.insert(output, string.format("  %d. %s %s: %s",
                i, detail_type, detail.id or "unknown", detail.message or "no message"))
        end
    end

    -- Show custom metadata from processors if present
    if result.custom_metadata then
        table.insert(output, "")
        table.insert(output, "Processor Metadata:")
        table.insert(output, json.encode(result.custom_metadata, { indent = 2 }))
    end

    return table.concat(output, "\n")
end

-- Main handler function
local function handler(params)
    -- Get user context
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end

    local user_id = actor:id()

    -- Get workspace from context automatically (CONTEXT-LOCKED)
    local workspace_id, err = ctx.get("workspace_id")
    if err then
        return nil, "Cannot access workspace context: " .. err
    end

    if not workspace_id or workspace_id == "" then
        return nil, "No active workspace. Use workspace manager to open one first"
    end

    -- Set status to "committed" when push starts
    local status_result, status_err = writer.update_workspace(workspace_id, {status = "committed"})
    if status_err then
        return nil, "Failed to update workspace status to committed: " .. status_err
    end

    -- Open workspace session
    local session, err = workspace.open(workspace_id, user_id)
    if err then
        -- Reset status to "active" on session failure
        writer.update_workspace(workspace_id, {status = "active"})
        return nil, "Failed to open workspace session: " .. err
    end

    -- Get workspace info for context
    local workspace_info, err = session:get_workspace_info()
    if err then
        -- Set status to "failed" on error
        writer.update_workspace(workspace_id, {status = "failed"})
        return nil, "Failed to get workspace info: " .. err
    end

    -- Convert workspace changes to registry changeset format with reconciliation
    local changeset, err = convert_workspace_to_changeset(session)
    if err then
        -- Set status to "failed" on error
        writer.update_workspace(workspace_id, {status = "failed"})
        return nil, err
    end

    if #changeset == 0 then
        -- Set status back to "active" for no-op case
        writer.update_workspace(workspace_id, {status = "active"})
        return "No changes to push (all operations were no-ops or skipped)", nil
    end

    -- Prepare options for governance client
    local options = {
        workspace_id = workspace_id,
        user_id = user_id,
        message = params.message,
        request_hil = true,
        session_id = ctx.get("session_id") or nil
    }

    -- Submit changes to governance system
    local result, err = governance_client.request_changes(changeset, options)
    if err then
        -- Set status to "failed" on error
        writer.update_workspace(workspace_id, {status = "failed"})
        return nil, "Registry push failed: " .. err
    end

    -- Set status to "integrated" on successful governance response
    local status_result, status_err = writer.update_workspace(workspace_id, {status = "integrated"})
    if status_err then
        -- Log error but don't fail push - status update is best effort
    end

    -- Format and return the result
    return format_result(result, #changeset, 0), nil
end

return { handler = handler }
