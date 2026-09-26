local hash = require("hash")

local M = {}

local function failure(code, message)
    return errors.new({ kind = errors.INVALID, message = message,
        details = { code = code } })
end

local function canonical(value, seen)
    local kind = type(value)
    if kind == "nil" then return "n" end
    if kind == "boolean" then return value and "b1" or "b0" end
    if kind == "number" then return "d" .. tostring(value) .. ";" end
    if kind == "string" then return "s" .. tostring(#value) .. ":" .. value end
    if kind ~= "table" then return nil, failure("BAD_REQUEST", "unsupported candidate value: " .. kind) end
    if seen[value] then return nil, failure("BAD_REQUEST", "candidate contains a cycle") end
    seen[value] = true
    local keys = {}
    for key in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            seen[value] = nil
            return nil, failure("BAD_REQUEST", "unsupported candidate key")
        end
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) < type(b)
    end)
    local parts = { "t", tostring(#keys), ":" }
    for _, key in ipairs(keys) do
        local encoded_key, key_err = canonical(key, seen)
        if not encoded_key then seen[value] = nil; return nil, key_err end
        local encoded_value, value_err = canonical(value[key], seen)
        if not encoded_value then seen[value] = nil; return nil, value_err end
        parts[#parts + 1] = encoded_key
        parts[#parts + 1] = encoded_value
    end
    seen[value] = nil
    return table.concat(parts), nil
end

function M.sha256(value)
    local bytes, canonical_err = canonical(value, {})
    if not bytes then return nil, canonical_err end
    return hash.sha256(bytes)
end

return M
