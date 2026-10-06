local json = require("json")

local M = {}

function M.strings(value)
    local result, decode_err = json.decode("[]")
    if decode_err then return nil, decode_err end
    if value == nil then return result, nil end
    if type(value) ~= "table" then return nil, "expected a string array" end
    local count = 0
    for key, item in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or type(item) ~= "string" then
            return nil, "expected a string array"
        end
        count = count + 1
    end
    for position = 1, count do
        if value[position] == nil then return nil, "expected a contiguous string array" end
        result[position] = value[position]
    end
    return result, nil
end

function M.decode(value)
    if value == nil or value == "" then return M.strings(nil) end
    local decoded, decode_err = json.decode(value)
    if decode_err then return nil, decode_err end
    if decoded == nil then return nil, "expected a string array" end
    return M.strings(decoded)
end

return M
