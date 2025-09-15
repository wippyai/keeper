local funcs = require("funcs")
local json = require("json")

local function handler(params)
    local response = {
        success = false,
        function_id = params.function_id,
        parameters = params.parameters,
        result = nil,
        error = nil
    }

    -- Validate required parameters
    if not params.function_id or type(params.function_id) ~= "string" or params.function_id:gsub("%s", "") == "" then
        response.error = "Missing or empty function_id parameter"
        return response
    end

    -- Validate function_id format (should contain colon)
    if not params.function_id:match("^[^:]+:[^:]+$") then
        response.error = "Invalid function_id format. Expected 'namespace:function_name'"
        return response
    end

    -- Default parameters to empty object if not provided
    local function_params = params.parameters or {}

    -- Create function executor
    local executor = funcs.new()

    -- Call the function
    local result, err = executor:call(params.function_id, function_params)
    
    if err then
        response.error = "Function call failed: " .. tostring(err)
        return response
    end

    -- Return successful result
    response.success = true
    response.result = result
    return response
end

return { handler = handler }