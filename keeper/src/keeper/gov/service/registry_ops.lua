-- keeper.gov.service:registry_ops
--
-- Registry CRUD business layer for keeper.gov.api.registry handlers.
-- Owns snapshot reads, filter/pagination, namespace grouping, and the
-- full update-entry orchestration (deep copy + merge semantics + materialize
-- + governance changeset run). HTTP handlers become thin adapters.

local registry = require("registry")

local materialize = require("materialize")
local gov_client = require("gov_client")
local gov_consts = require("gov_consts")

local M = {}

M.ERR = {
    BAD_REQUEST  = "bad_request",
    NOT_FOUND    = "not_found",
    FORBIDDEN    = "forbidden",
    UNAUTHORIZED = "unauthorized",
    CONFLICT     = "conflict",
    INTERNAL     = "internal",
}

local function fail(code, message, extra)
    local err = { code = code, message = message }
    if extra then
        for k, v in pairs(extra) do err[k] = v end
    end
    return nil, err
end

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

function M.entry_matches_query(entry, query)
    local q = lower(query)
    if q == "" then return true end
    local meta = entry.meta or {}
    for _, value in pairs({
        id = entry.id,
        kind = entry.kind,
        meta_type = meta.type,
        title = meta.title,
        name = meta.name,
        comment = meta.comment,
        description = meta.description,
    }) do
        if lower(value):find(q, 1, true) then return true end
    end
    return false
end

function M.deep_copy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = M.deep_copy(value)
    end
    return copy
end
local deep_copy = M.deep_copy

function M.is_empty_table(t)
    if type(t) ~= "table" then return false end
    return next(t) == nil
end
local is_empty_table = M.is_empty_table

function M.is_json_array(t)
    if type(t) ~= "table" then return false end
    local n = #t
    if n == 0 then return false end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
            return false
        end
    end
    return true
end
local is_json_array = M.is_json_array

-- Merge semantics: empty tables mean "clear this field", arrays replace,
-- plain maps recurse.
function M.merge_explicit(target, source)
    local result = deep_copy(target)
    for key, value in pairs(source) do
        if type(value) == "table" and is_empty_table(value) then
            result[key] = nil
        elseif type(value) == "table" and type(result[key]) == "table" then
            if is_json_array(value) or is_json_array(result[key]) then
                result[key] = deep_copy(value)
            else
                result[key] = M.merge_explicit(result[key], value)
            end
        else
            result[key] = value
        end
    end
    return result
end
local merge_explicit = M.merge_explicit

-- Pure: given an existing entry and an update payload, produce the updated
-- entry along with an `updates_made` flag. No registry / materialize calls.
function M.apply_updates(entry, update_data, should_merge)
    local updated = {
        id   = entry.id,
        kind = entry.kind,
        meta = deep_copy(entry.meta) or {},
        data = deep_copy(entry.data) or {},
    }
    local updates_made = false

    if update_data.kind then
        updated.kind = update_data.kind
        updates_made = true
    end
    if update_data.meta then
        updated.meta = should_merge and merge_explicit(updated.meta, update_data.meta) or update_data.meta
        updates_made = true
    end
    if update_data.data then
        updated.data = should_merge and merge_explicit(updated.data, update_data.data) or update_data.data
        updates_made = true
    end

    return updated, updates_made
end

function M.update_changeset(entry)
    local materialized, mat_err = materialize.entry(deep_copy(entry))
    if not materialized then
        return nil, "Failed to materialize entry: " .. tostring(mat_err)
    end

    local chunks = {
        { type = "definition", content = materialized.definition },
    }
    if materialized.content and materialized.content ~= "" then
        table.insert(chunks, { type = "content", content = materialized.content })
    end

    local registry_entry, rt_err = materialize.state_entry_to_registry({
        id = materialized.id,
        kind = materialized.kind,
        chunks = chunks,
    })
    if not registry_entry then
        return nil, "Failed to convert materialized entry: " .. tostring(rt_err)
    end

    return {
        {
            kind = gov_consts.REGISTRY_OPERATIONS.UPDATE,
            entry = registry_entry,
        },
    }, nil
end

function M.get_entry(entry_id)
    if not entry_id or entry_id == "" then
        return fail(M.ERR.BAD_REQUEST, "Missing required query parameter: id")
    end

    local entry, err = registry.get(entry_id)
    if not entry then
        return fail(M.ERR.NOT_FOUND, "Entry not found: " .. entry_id)
    end

    local version_info
    local version = registry.current_version()
    if version then
        version_info = {
            id       = version:id(),
            previous = version:previous() and version:previous():id() or nil,
            string   = version:string(),
        }
    end

    return {
        entry = {
            id   = entry.id,
            kind = entry.kind,
            meta = entry.meta or {},
            data = entry.data or {},
        },
        version = version_info,
    }
end

function M.list_entries(params)
    params = params or {}
    local limit = tonumber(params.limit) or 100
    local offset = tonumber(params.offset) or 0
    local kind = params.kind
    local namespace = params.namespace
    local meta_type = params.meta_type
    local query = params.query

    local criteria = {}
    if namespace and namespace ~= "" then criteria[".ns"] = namespace end
    if kind and kind ~= "" then criteria[".kind"] = kind end
    if meta_type and meta_type ~= "" then criteria["meta.type"] = meta_type end

    local entries, err
    if next(criteria) then
        entries, err = registry.find(criteria)
    else
        local snapshot, snap_err = registry.snapshot()
        if not snapshot then
            return fail(M.ERR.INTERNAL, "Failed to get registry snapshot: " .. tostring(snap_err))
        end
        entries = snapshot:entries()
    end

    if not entries then
        return fail(M.ERR.INTERNAL, "Failed to get entries: " .. tostring(err))
    end

    if query and query ~= "" then
        local filtered = {}
        for _, entry in ipairs(entries) do
            if M.entry_matches_query(entry, query) then
                table.insert(filtered, entry)
            end
        end
        entries = filtered
    end

    local total = #entries
    local end_index = math.min(offset + limit, total)
    local page = {}
    for i = offset + 1, end_index do
        local entry = entries[i]
        if entry then
            table.insert(page, {
                id   = entry.id,
                kind = entry.kind,
                meta = entry.meta or {},
            })
        end
    end

    return {
        entries   = page,
        count     = #page,
        total     = total,
        offset    = offset,
        limit     = limit,
        namespace = namespace ~= "" and namespace or nil,
        kind      = kind ~= "" and kind or nil,
        meta_type = meta_type ~= "" and meta_type or nil,
        query     = query ~= "" and query or nil,
        has_more  = end_index < total,
    }
end

function M.list_namespaces()
    local snapshot, err = registry.snapshot()
    if not snapshot then
        return fail(M.ERR.INTERNAL, "Failed to get registry snapshot: " .. tostring(err))
    end

    local entries = snapshot:entries()
    local groups: {[string]: {name: string, count: integer}} = {}
    for _, entry in ipairs(entries) do
        local parts = registry.parse_id(entry.id)
        if parts then
            local ns = parts.ns
            if not groups[ns] then
                groups[ns] = { name = ns, count = 0 }
            end
            local group = groups[ns]
            group.count = (group.count or 0) + 1
        end
    end

    local out = {}
    for _, group in pairs(groups) do
        table.insert(out, group)
    end
    table.sort(out, function(a, b) return a.name < b.name end)

    return { namespaces = out, count = #out }
end

function M.update_entry(entry_id, update_data)
    if type(entry_id) ~= "string" then
        return fail(M.ERR.BAD_REQUEST, "id must be a string")
    end
    if not entry_id or entry_id == "" then
        return fail(M.ERR.BAD_REQUEST, "Missing required query parameter: id")
    end
    if type(update_data) ~= "table" then
        return fail(M.ERR.BAD_REQUEST, "update payload must be a table")
    end

    local should_merge = update_data.merge ~= false

    local snapshot, snap_err = registry.snapshot()
    if not snapshot then
        return fail(M.ERR.INTERNAL, "Failed to get registry snapshot: " .. tostring(snap_err))
    end

    local entry = snapshot:get(entry_id)
    if not entry then return fail(M.ERR.NOT_FOUND, "Entry not found: " .. entry_id) end

    local updated, updates_made = M.apply_updates(entry, update_data, should_merge)

    if not updates_made then
        return fail(M.ERR.BAD_REQUEST, "No updates provided (need at least one of: kind, meta, data)")
    end

    local changeset, changeset_err = M.update_changeset(updated)
    if not changeset then
        return fail(M.ERR.INTERNAL, changeset_err)
    end

    local publish_result, publish_err = gov_client.request_changes(changeset, {
        message = "HTTP update_entry: " .. entry_id,
        source = "keeper.registry",
        request_hil = true,
    })

    if publish_err or not publish_result then
        return fail(M.ERR.CONFLICT, "Failed to apply registry changes: " .. tostring(publish_err), {
            stage = "governance",
        })
    end

    return {
        message      = "Entry updated successfully",
        id           = entry_id,
        kind         = updated.kind,
        version      = publish_result.version,
        changeset_id = publish_result.changeset and publish_result.changeset.id or nil,
        merge        = should_merge,
        updated      = {
            kind = update_data.kind ~= nil,
            meta = update_data.meta ~= nil,
            data = update_data.data ~= nil,
        },
    }
end

return M
