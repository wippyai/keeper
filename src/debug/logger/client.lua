local time = require("time")
local uuid = require("uuid")
local consts = require("consts")

local logger_client = {}

local function generate_id()
    local id, err = uuid.v4()
    if err then
        error("Failed to generate UUID: " .. err)
    end
    return id
end

local function generate_channel_name()
    local id, err = uuid.v4()
    if err then
        error("Failed to generate UUID for channel name: " .. err)
    end
    return "logger.response." .. id
end

local function send_and_wait(message, timeout_ms)
    timeout_ms = timeout_ms or 5000

    local response_channel_name = generate_channel_name()
    message.respond_to = response_channel_name
    message.id = generate_id()

    local response_channel = process.listen(response_channel_name)

    local ok = process.send(consts.PROCESS_NAMES.LOGGER, consts.TOPICS.COMMANDS, message)
    if not ok then
        return nil, "Failed to send message to logger service"
    end

    local timeout = time.after(timeout_ms)

    local result = channel.select({
        response_channel:case_receive(),
        timeout:case_receive()
    })

    if result.channel == timeout then
        return nil, "Operation timed out after " .. (timeout_ms / 1000) .. " seconds"
    end

    local response = result.value

    if not response.success then
        return nil, response.error or "Operation failed"
    end

    return response, nil
end

---@param count? number
---@param filter? string
---@param reverse? boolean
---@param timeout_ms? number
---@return table? logs
---@return string? error
function logger_client.get_logs(count, filter, reverse, timeout_ms)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.GET_LOGS,
        count = count,
        filter = filter,
        reverse = reverse,
    }, timeout_ms)

    if err then
        return nil, err
    end

    return {
        logs = response.logs,
        total_count = response.total_count,
        filtered = response.filtered,
    }, nil
end

---@param filter? string
---@param timeout_ms? number
---@return table? composition
---@return string? error
function logger_client.get_composition(filter, timeout_ms)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.COMPOSITION,
        filter = filter,
    }, timeout_ms)

    if err then
        return nil, err
    end

    return {
        composition = response.composition,
    }, nil
end

---@param timeout_ms? number
---@return table? stats
---@return string? error
function logger_client.get_stats(timeout_ms)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.GET_STATS,
    }, timeout_ms)

    if err then
        return nil, err
    end

    return response.stats, nil
end

---@param timeout_ms? number
---@return boolean success
---@return string? error
function logger_client.clear(timeout_ms)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.CLEAR,
    }, timeout_ms)

    if err then
        return false, err
    end

    return true, nil
end

---@param buffer_size number
---@param timeout_ms? number
---@return boolean success
---@return string? error
function logger_client.configure(buffer_size, timeout_ms)
    if not buffer_size or buffer_size <= 0 then
        return false, "Invalid buffer size"
    end

    local response, err = send_and_wait({
        operation = consts.OPERATIONS.CONFIGURE,
        buffer_size = buffer_size,
    }, timeout_ms)

    if err then
        return false, err
    end

    return true, nil
end

return logger_client