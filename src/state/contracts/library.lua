local M = {}

M.ERR = {
    SCHEMA_MISSING_FIELD   = "SCHEMA_MISSING_FIELD",
    SCHEMA_WRONG_TYPE      = "SCHEMA_WRONG_TYPE",
    SCHEMA_EMPTY_VALUE     = "SCHEMA_EMPTY_VALUE",
    SCHEMA_UNKNOWN_KIND    = "SCHEMA_UNKNOWN_KIND",
    SCHEMA_FORBIDDEN_FIELD = "SCHEMA_FORBIDDEN_FIELD",
    SCHEMA_EMPTY_ARRAY     = "SCHEMA_EMPTY_ARRAY",
}

-- Per-kind rules. `required_data` and `required_meta` enumerate fields on
-- registry_entry.data / registry_entry.meta that must be non-empty. `forbidden_data`
-- fields trigger a hint when present; convention violations, not blockers.
-- `array_fields` must be non-empty tables. `string_fields` enforce type=string.
-- Unknown kinds are not an error here — kinds the registry doesn't load still
-- get caught by governance lint; we flag only what we know.
M.KINDS = {
    ["function.lua"] = {
        required_data = { "source", "method" },
        string_fields = { source = true, method = true },
        fix_hint = {
            source = "set `source: file://<name>.lua` or inline `source:`",
            method = "set `method: handler` (or the Lua function your module exports)",
        },
    },
    ["library.lua"] = {
        required_data = { "source" },
        forbidden_data = { method = "library.lua has no `method`; export an `M` table and require it via imports" },
        string_fields = { source = true },
        fix_hint = {
            source = "set `source: file://<name>.lua` or inline `source:`",
        },
    },
    ["process.lua"] = {
        required_data = { "source", "method" },
        string_fields = { source = true, method = true },
        fix_hint = {
            source = "set `source: file://<name>.lua`",
            method = "set `method: run` (or the entry point of your process)",
        },
    },
    ["http.endpoint"] = {
        required_data = { "method", "path", "func" },
        required_meta = { "router" },
        string_fields = { method = true, path = true, func = true },
        fix_hint = {
            method = "HTTP method, e.g. `method: GET`",
            path   = "route path, e.g. `path: /api/tasks`",
            func   = "function entry id to handle the request, e.g. `func: list_tasks`",
            router = "set `meta.router: app:api` so the endpoint is actually routed",
        },
    },
    ["contract.definition"] = {
        required_data = { "methods" },
        array_fields  = { methods = true },
        fix_hint = {
            methods = "contract must declare at least one method: `methods: [{ name: ..., description: ... }]`",
        },
    },
    ["contract.binding"] = {
        required_data = { "contracts" },
        array_fields  = { contracts = true },
        fix_hint = {
            contracts = "binding must bind at least one contract: `contracts: [{ contract: ns:name, methods: {...} }]`",
        },
    },
    ["env.variable"] = {
        required_data = { "storage", "variable" },
        string_fields = { storage = true, variable = true },
        fix_hint = {
            storage  = "reference the storage entry id, e.g. `storage: app.env:store`",
            variable = "name of the env var to resolve, e.g. `variable: MCP_ACCESS_TOKEN`",
        },
    },
    ["fs.directory"] = {
        required_data = { "directory" },
        string_fields = { directory = true },
    },
    ["ns.dependency"] = {
        required_data = { "component", "version" },
        string_fields = { component = true, version = true },
    },
}

function M.err_entry(code, stage, target, message, fix_hint)
    return {
        code      = code,
        stage     = stage,
        target    = target,
        message   = message,
        retryable = false,
        fix_hint  = fix_hint,
    }
end

local function err(code, target, message, fix_hint)
    return M.err_entry(code, "validate", target, message, fix_hint)
end

local function empty(v)
    if v == nil then return true end
    if type(v) == "string" and v == "" then return true end
    if type(v) == "table" and next(v) == nil then return true end
    return false
end

-- validate_registry checks a parsed registry entry {id, kind, meta, data}. Returns
-- a list of structured errors (empty on success). The caller composes these with
-- patch-level validation; nothing in this module touches storage or side effects.
function M.validate_registry(entry)
    local errors = {}

    if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" then
        table.insert(errors, err(M.ERR.SCHEMA_WRONG_TYPE, tostring(entry and entry.id or "?"),
            "entry must be a table with an `id` field", "pass a registry entry {id,kind,meta,data}"))
        return errors
    end

    if type(entry.kind) ~= "string" or entry.kind == "" then
        table.insert(errors, err(M.ERR.SCHEMA_MISSING_FIELD, entry.id,
            "entry.kind is required", "set `kind: function.lua` (or library.lua, http.endpoint, ...)"))
        return errors
    end

    local rules = M.KINDS[entry.kind]
    if not rules then
        -- Unknown kinds pass through; governance lint owns final authority.
        return errors
    end

    local data = entry.data or {}
    local meta = entry.meta or {}
    local hints = rules.fix_hint or {}

    if rules.required_data then
        for _, field in ipairs(rules.required_data) do
            if empty(data[field]) then
                table.insert(errors, err(M.ERR.SCHEMA_MISSING_FIELD, entry.id,
                    entry.kind .. " requires `" .. field .. "` (missing or empty)",
                    hints[field] or ("add the `" .. field .. "` field to this entry")))
            end
        end
    end

    if rules.required_meta then
        for _, field in ipairs(rules.required_meta) do
            if empty(meta[field]) then
                table.insert(errors, err(M.ERR.SCHEMA_MISSING_FIELD, entry.id,
                    entry.kind .. " requires `meta." .. field .. "` (missing or empty)",
                    hints[field] or ("add `meta." .. field .. "` to this entry")))
            end
        end
    end

    if rules.string_fields then
        for field, _ in pairs(rules.string_fields) do
            local val = data[field]
            if val ~= nil and type(val) ~= "string" then
                table.insert(errors, err(M.ERR.SCHEMA_WRONG_TYPE, entry.id,
                    "`" .. field .. "` must be a string (got " .. type(val) .. ")",
                    hints[field] or ("set `" .. field .. "` to a string value")))
            end
        end
    end

    if rules.array_fields then
        for field, _ in pairs(rules.array_fields) do
            local val = data[field]
            if val ~= nil then
                if type(val) ~= "table" then
                    table.insert(errors, err(M.ERR.SCHEMA_WRONG_TYPE, entry.id,
                        "`" .. field .. "` must be an array (got " .. type(val) .. ")",
                        hints[field] or ("set `" .. field .. "` to a non-empty array")))
                elseif #val == 0 then
                    table.insert(errors, err(M.ERR.SCHEMA_EMPTY_ARRAY, entry.id,
                        "`" .. field .. "` must be a non-empty array",
                        hints[field] or ("add at least one item to `" .. field .. "`")))
                end
            end
        end
    end

    if rules.forbidden_data then
        for field, reason in pairs(rules.forbidden_data) do
            if data[field] ~= nil then
                table.insert(errors, err(M.ERR.SCHEMA_FORBIDDEN_FIELD, entry.id,
                    entry.kind .. " must not define `" .. field .. "`: " .. reason,
                    "remove the `" .. field .. "` field"))
            end
        end
    end

    return errors
end

-- Convenience: validate many parsed registry entries, flatten errors.
function M.validate_many(entries)
    local all_errors = {}
    for _, entry in ipairs(entries or {}) do
        for _, e in ipairs(M.validate_registry(entry)) do
            table.insert(all_errors, e)
        end
    end
    return all_errors
end

return M
