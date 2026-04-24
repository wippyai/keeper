local state_reader = require("state_reader")
local branch_ctx = require("branch_ctx")
local entry_lib = require("entry_lib")
local registry_edit = require("registry_edit")
local audit = require("audit")

local resolve_changeset_id = branch_ctx.resolve_changeset_id
local get_active_branch = branch_ctx.get_active_branch
local validate_entry_id = entry_lib.validate_entry_id
local registry_set = registry_edit.registry_set
local registry_delete = registry_edit.registry_delete
local extract_kind_from_definition = entry_lib.extract_kind_from_definition

local function delete_operation(entry_id, branch, changeset_id)
    if branch == "main" then
        return nil, "Cannot delete from main branch"
    end

    local namespace, name = validate_entry_id(entry_id)
    if not namespace then
        return nil, name
    end

    local _, err = registry_delete(changeset_id, entry_id)
    if err then
        return nil, "Failed to delete: " .. err
    end

    return "Deleted " .. entry_id .. " in branch " .. branch, nil
end

local function reset_operation(entry_id, from_branch, to_branch, changeset_id)
    if to_branch == "main" then
        return nil, "Cannot reset to main branch"
    end

    local namespace, name = validate_entry_id(entry_id)
    if not namespace then
        return nil, name
    end

    local reader, err = state_reader.for_branch(from_branch)
    if err then
        return nil, "Failed to read from branch " .. from_branch .. ": " .. err
    end

    reader = reader:with_entries(entry_id):include_chunks()

    local entries, err = reader:all()
    if err then
        return nil, "Failed to read entry from " .. from_branch .. ": " .. err
    end

    if #entries == 0 then
        return nil, "Entry not found in branch " .. from_branch .. ": " .. entry_id
    end

    local entry = entries[1]

    local definition_content = nil
    local source_content = nil

    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then
                definition_content = chunk.content
            elseif chunk.type == "content" then
                source_content = chunk.content
            end
        end
    end

    if not definition_content then
        return nil, "Entry has no definition chunk"
    end

    local kind, kind_err = extract_kind_from_definition(definition_content)
    if kind_err then
        return nil, kind_err
    end

    local _, save_err = registry_set(
        changeset_id,
        entry_id,
        kind,
        definition_content,
        source_content
    )
    if save_err then
        return nil, "Failed to reset: " .. save_err
    end

    return "Reset " .. entry_id .. " from " .. from_branch .. " to " .. to_branch, nil
end

local function do_handler(params)
    if not params.operation or params.operation == "" then
        return nil, "Missing operation (delete, reset)"
    end

    if not params.entry_id or params.entry_id == "" then
        return nil, "Missing entry_id"
    end

    local current_branch = get_active_branch()

    if current_branch == "main" then
        return nil, "Cannot mutate main branch (set branch first)"
    end

    local changeset_id, cs_err = resolve_changeset_id(current_branch)
    if cs_err or not changeset_id then
        return nil, "No active changeset for branch '" .. current_branch ..
            "'. Call set_branch to open or resume a workspace before managing entries. (" ..
            tostring(cs_err or "missing changeset_id") .. ")"
    end

    if params.operation == "delete" then
        return delete_operation(params.entry_id, current_branch, changeset_id)

    elseif params.operation == "reset" then
        local from_branch = params.from_branch or "main"
        return reset_operation(params.entry_id, from_branch, current_branch, changeset_id)

    else
        return nil, "Invalid operation: " .. params.operation .. " (must be delete or reset)"
    end
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "manage",
        discriminator = "manage." .. (params.operation or "?"),
        target        = params.entry_id,
        params        = { operation = params.operation, entry_id = params.entry_id, from_branch = params.from_branch },
        summarise = function(result, err)
            if err then return "manage failed: " .. tostring(err) end
            if type(result) == "string" then return result end
            return (params.operation or "?") .. " " .. (params.entry_id or "?")
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }