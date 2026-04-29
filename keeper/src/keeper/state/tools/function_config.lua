local M = {}

local FUNCTION_KINDS = {
    ["function.lua"]  = true,
    ["function.wasm"] = true,
    ["process.lua"]   = true,
    ["process.wasm"]  = true,
}

local LIBRARY_KINDS = {
    ["library.lua"]  = true,
    ["library.wasm"] = true,
}

local function count_keys(t)
    local n, list_only = 0, true
    for k in pairs(t) do
        n = n + 1
        if type(k) ~= "number" then list_only = false end
    end
    return n, list_only
end

local function validate_modules_field(modules: unknown)
    if modules == nil then return nil end
    if type(modules) ~= "table" then
        return "'modules' must be a YAML list of strings, got " .. type(modules)
    end
    local n, list_only = count_keys(modules)
    if n == 0 then
        return "'modules' is present but empty — remove the key or add at least one module (e.g. [fs, text])"
    end
    if not list_only then
        return "'modules' must be a YAML list (e.g. [fs, text]), not a map"
    end
    for i = 1, n do
        local m = modules[i]
        if type(m) ~= "string" or m == "" then
            return "'modules[" .. i .. "]' must be a non-empty string"
        end
        if m:find(":", 1, true) then
            return "'modules[" .. i .. "]' = '" .. m .. "' cannot contain ':'; module names have no namespace"
        end
    end
    return nil
end

local function validate_imports_field(imports: unknown)
    if imports == nil then return nil end
    if type(imports) ~= "table" then
        return "'imports' must be a YAML map of alias to entry id, got " .. type(imports)
    end
    local n, list_only = count_keys(imports)
    if n == 0 then
        return "'imports' is present but empty — remove the key or add at least one import (alias: namespace:name)"
    end
    if list_only then
        return "'imports' must be a YAML map (e.g. alias: namespace:name), not a list"
    end
    for alias, id in pairs(imports) do
        if type(alias) ~= "string" or alias == "" then
            return "import alias must be a non-empty string"
        end
        if type(id) ~= "string" or id == "" then
            return "import '" .. alias .. "' must point to an entry id string, got " .. type(id)
        end
        if not id:find(":", 1, true) then
            return "import '" .. alias .. "' = '" .. id .. "' must be fully qualified (namespace:name)"
        end
    end
    return nil
end

-- Shape check for http handler functions: function.lua entries whose source
-- is wired to an http.endpoint must use the platform's handler convention.
-- The convention is `local function <method>()` with zero parameters and
-- the body must call `http.response()` and `http.request()` to get the
-- req/res pair. Developers keep writing `function handler(req, res)` (common
-- Express-style reflex) which is invalid on this platform.
local function validate_http_handler_shape(parsed_entry, source)
    if not source or source == "" then return nil end
    if parsed_entry.kind ~= "function.lua" then return nil end
    local method = parsed_entry.method
    if type(method) ~= "string" or method == "" then return nil end

    -- Only gate http handlers. A function.lua that doesn't require the http
    -- module isn't subject to this check.
    local modules = parsed_entry.modules
    if type(modules) ~= "table" then return nil end
    local has_http = false
    for _, m in ipairs(modules) do if m == "http" then has_http = true; break end end
    if not has_http then return nil end

    -- Require the handler function to exist with exactly zero parameters.
    -- Match both `local function M.handler(` and `local function handler(`
    -- styles. If we see `function <method>(<something>)` with args, reject.
    local pat1 = "function%s+" .. method:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1") .. "%s*%("
    local start_idx, end_idx = source:find(pat1)
    if not start_idx then
        -- Maybe referenced as `M.<method>` or `_M.<method>`; find that shape.
        local pat2 = "%w+%s*%." .. method:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1") .. "%s*=%s*function%s*%("
        start_idx, end_idx = source:find(pat2)
    end
    local end_pos = tonumber(end_idx)
    if start_idx and end_pos then
        -- Look at characters immediately after the `(`.
        local rest = source:sub(end_pos + 1, end_pos + 120) or ""
        local args = rest:match("^(.-)%)")
        if args and args:match("%S") then
            return "http handler '" .. method .. "' must take zero arguments — " ..
                "use `local function " .. method .. "()` and call `http.request()` / " ..
                "`http.response()` to get the req/res pair. Found `function " ..
                method .. "(" .. args:gsub("^%s+",""):gsub("%s+$","") .. ")`."
        end
    end

    -- And require the canonical req/res accessors if the source reads params.
    -- This is a soft check: a handler that never needs request data can skip
    -- them, but the vast majority don't.
    local calls_request  = source:find("http%.request%s*%(") ~= nil
    local calls_response = source:find("http%.response%s*%(") ~= nil
    local uses_req       = source:find("[%a_][%w_]*:param%s*%(") ~= nil
        or source:find("[%a_][%w_]*:query%s*%(") ~= nil
        or source:find("[%a_][%w_]*:body_json%s*%(") ~= nil
        or source:find("[%a_][%w_]*:body%s*%(") ~= nil
    if uses_req and not calls_request then
        return "http handler '" .. method .. "' reads request data but never " ..
            "calls `http.request()`; the req object comes from that call " ..
            "(not from a function argument). See any existing endpoint in " ..
            "the codebase for the pattern."
    end
    if uses_req and not calls_response then
        return "http handler '" .. method .. "' processes a request but never " ..
            "calls `http.response()`; the res object comes from that call. " ..
            "See any existing endpoint in the codebase for the pattern."
    end
    return nil
end

function M.validate(parsed_entry, source)
    if type(parsed_entry) ~= "table" then
        return "parsed_entry must be a table"
    end
    local kind = parsed_entry.kind
    if not kind then return nil end

    if FUNCTION_KINDS[kind] then
        local method = parsed_entry.method
        if type(method) ~= "string" or method == "" then
            return "kind '" .. kind .. "' requires non-empty 'method' (the exported handler name)"
        end
    end

    if FUNCTION_KINDS[kind] or LIBRARY_KINDS[kind] then
        local mod_err = validate_modules_field(parsed_entry.modules)
        if mod_err then return mod_err end

        local imp_err = validate_imports_field(parsed_entry.imports)
        if imp_err then return imp_err end
    end

    local shape_err = validate_http_handler_shape(parsed_entry, source)
    if shape_err then return shape_err end

    return nil
end

return M
