local hash = require("hash")
local state_reader = require("state_reader")

local M = {}

function M.extract_namespace(entry_id)
    if type(entry_id) ~= "string" or entry_id == "" then return nil end
    local colon_pos: integer? = entry_id:find(":", 1, true)
    if colon_pos then
        return entry_id:sub(1, colon_pos - 1)
    end
    return nil
end

function M.extract_name(entry_id)
    if type(entry_id) ~= "string" or entry_id == "" then return nil end
    local colon_pos: integer? = entry_id:find(":", 1, true)
    if colon_pos then
        return entry_id:sub(colon_pos + 1)
    end
    return entry_id
end

function M.validate_entry_id(entry_id)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end
    if type(entry_id) ~= "string" then
        return nil, "entry_id must be a string, got " .. type(entry_id)
    end

    local colon_pos: integer? = entry_id:find(":", 1, true)
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

function M.extract_kind_from_definition(definition_yaml)
    local entries_start = definition_yaml:find("entries:", 1, true)
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

function M.entry_content(entry)
    local definition, source = "", ""
    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then
                definition = chunk.content or ""
            elseif chunk.type == "content" then
                source = chunk.content or ""
            end
        end
    end
    return definition, source
end

function M.content_hash(definition, source)
    local combined = (definition or "") .. "\n---\n" .. (source or "")
    local h, err = hash.sha256(combined)
    if err then return nil end
    return h
end

function M.load_branch_entries(branches)
    local reader, err = state_reader.for_branch(unpack(branches))
    if err then return nil, err end

    reader = reader:include_chunks():include_deleted()
    local entries, rerr = reader:all()
    if rerr then return nil, rerr end

    local map = {}
    for _, entry in ipairs(entries) do
        map[entry.id] = entry
    end
    return map, nil
end

function M.classify_changes(base_map, target_map)
    local added, deleted, modified = {}, {}, {}

    for id, target_entry in pairs(target_map) do
        local base_entry = base_map[id]
        if target_entry.deleted == 1 then
            if base_entry and base_entry.deleted == 0 then
                table.insert(deleted, { id = id, entry = base_entry })
            end
        elseif not base_entry or base_entry.deleted == 1 then
            table.insert(added, { id = id, entry = target_entry })
        else
            local base_def, base_src = M.entry_content(base_entry)
            local target_def, target_src = M.entry_content(target_entry)
            if M.content_hash(base_def, base_src) ~= M.content_hash(target_def, target_src) then
                table.insert(modified, { id = id, entry = target_entry })
            end
        end
    end

    local function by_id(a, b) return a.id < b.id end
    table.sort(added, by_id)
    table.sort(deleted, by_id)
    table.sort(modified, by_id)

    return added, deleted, modified
end

return M
