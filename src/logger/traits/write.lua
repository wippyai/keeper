local logger = require("logger")
local logger_client = require("logger_client")

local function handler(params)
    if not params then
        return nil, "params required"
    end

    if params.operation == "clear" then
        local success, err = logger_client.clear(5000)
        if not success then
            return nil, "Failed to clear logs: " .. err
        end
        return "Log buffer cleared"
    end

    if params.operation == "configure" then
        if not params.buffer_size then
            return nil, "buffer_size required for configure"
        end
        local success, err = logger_client.configure(params.buffer_size, 5000)
        if not success then
            return nil, "Failed to configure: " .. err
        end
        return "Buffer size set to " .. params.buffer_size
    end

    if not params.message then
        return nil, "message required"
    end

    local level = params.level
    if not level then
        level = 0
    end

    local path = params.path
    if not path then
        path = "test.logger"
    end

    local log = logger:named(path)

    local fields = params.fields
    if not fields then
        fields = {}
    end

    if level == -1 then
        log:debug(params.message, fields)
    elseif level == 0 then
        log:info(params.message, fields)
    elseif level == 1 then
        log:warn(params.message, fields)
    elseif level == 2 then
        log:error(params.message, fields)
    else
        return nil, "Invalid level: " .. level .. " (use -1=DEBUG, 0=INFO, 1=WARN, 2=ERROR)"
    end

    local level_name
    if level == -1 then
        level_name = "DEBUG"
    elseif level == 0 then
        level_name = "INFO"
    elseif level == 1 then
        level_name = "WARN"
    else
        level_name = "ERROR"
    end

    return "Log written: [" .. level_name .. "] " .. path .. ": " .. params.message
end

return { handler = handler }