local json = require("json")
local funcs = require("funcs")

local function handler(params)
    local handler_id = params.handler_id
    local entry_ids = params.entry_ids or {}
    local fs_paths  = params.fs_paths or {}
    local operation = params.operation or "up"
    local data = params.data or {}
    local execute_result = params.execute_result

    local executor = funcs.new()
    local result, err = executor:call(handler_id, {
        operation      = operation,
        data           = data,
        entry_ids      = entry_ids,
        fs_paths       = fs_paths,
        execute_result = execute_result,
    })

    if err then
        return {
            handler_id = handler_id,
            entry_ids  = entry_ids,
            fs_paths   = fs_paths,
            error      = err,
        }
    end

    return {
        handler_id = handler_id,
        entry_ids  = entry_ids,
        fs_paths   = fs_paths,
        result     = result,
    }
end

return { handler = handler }
