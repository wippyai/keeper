local funcs = require("funcs")

local function handler(input)
    if not input.target then
        return {
            success = false,
            error = "target required"
        }
    end

    local executor = funcs.new()

    if input.context then
        executor = executor:with_context(input.context)
    end

    local result, err
    if input.args then
        result, err = executor:call(input.target, input.args)
    else
        result, err = executor:call(input.target)
    end

    if err then
        return {
            success = false,
            error = err
        }
    end

    return {
        success = true,
        result = result
    }
end

return {handler = handler}