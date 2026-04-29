-- Runtime JSON-schema validator for MCP tool inputs.
--
-- Enforces the inputSchema declared in surface.META_TOOLS and in each
-- dynamic tool's meta.input_schema at dispatch time, so handlers can
-- trust their parameter types without per-handler guard soup.
--
-- Supported keywords: type (object/array/string/number/integer/boolean),
-- properties, required, items, enum. Extra schema fields are ignored;
-- the validator is strict on declared fields and lenient on anything
-- the schema doesn't mention (additionalProperties is effectively true).

local M = {}

function M.type_name(v)
    local t = type(v)
    if t == "table" then
        if next(v) == nil then return "object" end
        if type(next(v)) == "number" then return "array" end
        return "object"
    end
    return t
end
local type_name = M.type_name

function M.check_type(value, expected, path)
    if expected == "object" then
        if type(value) ~= "table" then
            return path .. " must be object, got " .. type_name(value)
        end
    elseif expected == "array" then
        if type(value) ~= "table" then
            return path .. " must be array, got " .. type_name(value)
        end
    elseif expected == "string" then
        if type(value) ~= "string" then
            return path .. " must be string, got " .. type_name(value)
        end
    elseif expected == "number" then
        if type(value) ~= "number" then
            return path .. " must be number, got " .. type_name(value)
        end
    elseif expected == "integer" then
        if type(value) ~= "number" or math.floor(value) ~= value then
            return path .. " must be integer, got " .. type_name(value)
        end
    elseif expected == "boolean" then
        if type(value) ~= "boolean" then
            return path .. " must be boolean, got " .. type_name(value)
        end
    end
    return nil
end
local check_type = M.check_type

function M.validate_node(value, schema, path)
    if not schema or type(schema) ~= "table" then return nil end

    local expected = schema.type
    if type(expected) == "string" then
        local err = check_type(value, expected, path)
        if err then return err end
    end

    if schema.enum and type(schema.enum) == "table" then
        local ok = false
        for _, allowed in ipairs(schema.enum) do
            if value == allowed then ok = true; break end
        end
        if not ok then
            return path .. " must be one of the allowed values"
        end
    end

    if expected == "object" and type(value) == "table" then
        if type(schema.required) == "table" then
            for _, req in ipairs(schema.required) do
                if value[req] == nil then
                    return path .. "." .. req .. " is required"
                end
            end
        end
        if type(schema.properties) == "table" then
            for key, prop in pairs(schema.properties) do
                if value[key] ~= nil then
                    local err = M.validate_node(value[key], prop, path .. "." .. key)
                    if err then return err end
                end
            end
        end
    end

    if expected == "array" and type(value) == "table" then
        if schema.items then
            for i, item in ipairs(value) do
                local err = M.validate_node(item, schema.items, path .. "[" .. i .. "]")
                if err then return err end
            end
        end
    end

    return nil
end

-- Validate `args` (decoded JSON) against `schema` (decoded JSON).
-- Returns nil on success, or a human-readable error string.
function M.check(args, schema)
    if not schema or type(schema) ~= "table" then return nil end
    return M.validate_node(args or {}, schema, "arguments")
end

return M
