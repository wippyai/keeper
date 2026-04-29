local audit = require("audit")
local cs_client = require("cs_client")
local cs_consts = require("cs_consts")
local state_reader = require("state_reader")
local branch_ctx = require("branch_ctx")
local entry_lib = require("entry_lib")

local EDIT_KINDS = cs_consts.EDIT_KINDS
local EDIT_TIMEOUT = "10s"

local resolve_changeset_id = branch_ctx.resolve_changeset_id
local get_active_branch    = branch_ctx.get_active_branch
local validate_entry_id    = entry_lib.validate_entry_id
local extract_kind_from_definition = entry_lib.extract_kind_from_definition

local function reset_to(from_branch, to_branch, entry_id, changeset_id)
    local namespace, name = validate_entry_id(entry_id)
    if not namespace then return nil, name end

    local reader, err = state_reader.for_branch(from_branch)
    if err then
        return nil, "Failed to read from branch " .. from_branch .. ": " .. err
    end
    reader = reader:with_entries(entry_id):include_chunks()

    local entries, lerr = reader:all()
    if lerr then
        return nil, "Failed to read entry from " .. from_branch .. ": " .. lerr
    end
    if #entries == 0 then
        return nil, "Entry not found in branch " .. from_branch .. ": " .. entry_id
    end

    local entry = entries[1]
    local definition_content, source_content
    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then definition_content = chunk.content
            elseif chunk.type == "content" then source_content = chunk.content end
        end
    end
    if not definition_content then
        return nil, "Entry has no definition chunk"
    end

    local kind, kind_err = extract_kind_from_definition(definition_content)
    if kind_err then return nil, kind_err end

    local _, save_err = cs_client.edit({
        changeset_id = changeset_id,
        kind         = EDIT_KINDS.REGISTRY_SET,
        entry        = {
            id         = entry_id,
            kind       = kind,
            definition = definition_content,
            content    = source_content,
        },
    }, EDIT_TIMEOUT)
    if save_err then
        return nil, "Failed to reset: " .. tostring(save_err)
    end

    return "Reset " .. entry_id .. " from " .. from_branch .. " to " .. to_branch, nil
end

local function do_handler(params)
    if not params.entry_id or params.entry_id == "" then
        return nil, "Missing entry_id"
    end

    local to_branch = get_active_branch()
    if to_branch == "main" then
        return nil, "Cannot reset on main branch (set branch first)"
    end
    local changeset_id, cs_err = resolve_changeset_id(to_branch)
    if not changeset_id then
        return nil, "No active changeset for branch '" .. to_branch ..
            "' (" .. tostring(cs_err) .. "). Call set_branch first."
    end

    local from_branch = params.from_branch or "main"
    return reset_to(from_branch, to_branch, params.entry_id, changeset_id)
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "reset",
        discriminator = "reset",
        target        = params.entry_id,
        params        = { entry_id = params.entry_id, from_branch = params.from_branch },
        summarise = function(result, err)
            if err then return "reset failed: " .. tostring(err) end
            return tostring(result)
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
