local json = require("json")
local ctx = require("ctx")
local state_reader = require("state_reader")
local state_client = require("state_client")
local consts = require("consts")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return overlay_branch
    end
    return "main"
end

local function get_active_branch_chain()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return {overlay_branch, "main"}
    end
    return {"main"}
end

local function validate_entry_id(entry_id)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    local colon_pos = entry_id:find(":")
    if not colon_pos then
        return nil, "Invalid entry ID format (must be namespace:name)"
    end

    local namespace = entry_id:sub(1, colon_pos - 1)
    local name = entry_id:sub(colon_pos + 1)

    if namespace == "" or name == "" then
        return nil, "Invalid entry ID format (namespace or name empty)"
    end

    return namespace, name
end

local function extract_kind_from_definition(definition_yaml)
    local entries_start = definition_yaml:find("entries:")

    if not entries_start then
        return nil, "Definition missing 'entries:' section"
    end

    local entry_yaml = definition_yaml:sub(entries_start)
    local kind_match = entry_yaml:match("kind:%s*([%w%.%-_]+)")

    if not kind_match then
        return nil, "Cannot find 'kind:' field in definition"
    end

    return kind_match, nil
end

local function delete_operation(entry_id, branch)
    if branch == "main" then
        return nil, "Cannot delete from main branch"
    end

    local namespace, name = validate_entry_id(entry_id)
    if not namespace then
        return nil, name
    end

    local result, err = state_client.delete_entry(entry_id, branch)
    if err then
        return nil, "Failed to delete: " .. err
    end

    return "Deleted " .. entry_id .. " in branch " .. branch, nil
end

local function reset_operation(entry_id, from_branch, to_branch)
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

    local result, save_err = state_client.set_entry(
        entry_id,
        kind,
        definition_content,
        source_content,
        nil,
        to_branch
    )

    if save_err then
        return nil, "Failed to reset: " .. save_err
    end

    return "Reset " .. entry_id .. " from " .. from_branch .. " to " .. to_branch, nil
end

local function handler(params)
    if not params.operation or params.operation == "" then
        return nil, "Missing operation (delete, reset)"
    end

    if not params.entry_id or params.entry_id == "" then
        return nil, "Missing entry_id"
    end

    local current_branch = get_active_branch()

    if params.operation == "delete" then
        return delete_operation(params.entry_id, current_branch)

    elseif params.operation == "reset" then
        local from_branch = params.from_branch or "main"
        return reset_operation(params.entry_id, from_branch, current_branch)

    else
        return nil, "Invalid operation: " .. params.operation .. " (must be delete or reset)"
    end
end

return { handler = handler }