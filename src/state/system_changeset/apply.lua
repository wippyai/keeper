local sys_cs = require("sys_cs")
local materialize = require("materialize")

local RESERVED = { id = true, kind = true, meta = true, data = true }

local function normalize(spec)
    if type(spec) ~= "table" then return nil, "spec must be a table" end
    if not spec.id or spec.id == "" then return nil, "spec.id required (namespace:name)" end
    if not spec.kind or spec.kind == "" then return nil, "spec.kind required" end

    local entry = { id = spec.id, kind = spec.kind }
    if spec.meta then entry.meta = spec.meta end

    local data = {}
    local has_data = false
    for k, v in pairs(spec) do
        if not RESERVED[k] then data[k] = v; has_data = true end
    end
    if spec.data then
        for k, v in pairs(spec.data) do data[k] = v; has_data = true end
    end
    if has_data then entry.data = data end

    return entry
end

local function write(spec, opts)
    local entry, err = normalize(spec)
    if not entry then return nil, err end

    local materialized, merr = materialize.entry(entry)
    if not materialized then return nil, "materialize failed: " .. tostring(merr) end

    return sys_cs.run({
        kind    = "manual",
        title   = opts.title or ("Write entry " .. entry.id),
        message = opts.message or ("Apply: " .. entry.id),
        edits   = {
            {
                op    = "registry_set",
                entry = {
                    id         = materialized.id,
                    kind       = materialized.kind,
                    definition = materialized.definition,
                    content    = materialized.content,
                    attributes = materialized.attributes,
                },
            },
        },
    })
end

local function remove(id, opts)
    if not id or id == "" then return nil, "id required for remove" end
    return sys_cs.run({
        kind    = "manual",
        title   = opts.title or ("Delete entry " .. id),
        message = opts.message or ("Apply: delete " .. id),
        edits   = { { op = "registry_delete", entry_id = id } },
    })
end

local function handler(args)
    args = args or {}
    local action = args.action
    local opts = { title = args.title, message = args.message }

    if action == "write" then
        return write(args.spec, opts)

    elseif action == "write_many" then
        if type(args.specs) ~= "table" or #args.specs == 0 then
            return nil, "specs must be a non-empty array"
        end
        local last_resp
        for _, spec in ipairs(args.specs) do
            local resp, err = write(spec, opts)
            if err or not resp or resp.ok == false then
                return resp, err or "write_many halted on failure"
            end
            last_resp = resp
        end
        return last_resp

    elseif action == "remove" then
        return remove(args.id, opts)
    end

    return nil, "unknown action: " .. tostring(action)
end

return { handler = handler }
