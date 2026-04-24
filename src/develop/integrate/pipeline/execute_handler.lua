local json = require("json")
local funcs = require("funcs")

local function handler(params)
    local handler_id = params.handler_id
    local entry_ids = params.entry_ids or {}
    local operation = params.operation or "up"
    local data = params.data or {}

    local executor = funcs.new()
    local result, err = executor:call(handler_id, {
        operation = operation,
        data = data, -- result of up operation
        entry_ids = entry_ids
    })

    if err then
        return {
            handler_id = handler_id,
            entry_ids = entry_ids,
            error = err
        }
    end

    return {
        handler_id = handler_id,
        entry_ids = entry_ids,
        result = result
    }
end

return { handler = handler }