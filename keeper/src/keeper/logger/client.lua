local time = require("time")
local uuid = require("uuid")
local consts = require("logger_consts")

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

local function send_and_wait(message, timeout)
    timeout = timeout or "5s"

    local response_channel_name = generate_channel_name()
    message.respond_to = response_channel_name
    message.id = generate_id()

    local response_channel = process.listen(response_channel_name)

    local ok = process.send(consts.PROCESS_NAMES.LOGGER, consts.TOPICS.COMMANDS, message)
    if not ok then
        return nil, "Failed to send message to logger service"
    end

    local timeout_ch = time.after(timeout)

    local result = channel.select({
        response_channel:case_receive(),
        timeout_ch:case_receive()
    })

    if result.channel == timeout_ch then
        return nil, "Operation timed out after " .. timeout
    end

    local response = result.value

    if not response.success then
        return nil, response.error or "Operation failed"
    end

    return response, nil
end

function logger_client.get_logs(count: number?, filter: string?, reverse: boolean?, timeout: string?): (table?, string?)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.GET_LOGS,
        count = count,
        filter = filter,
        reverse = reverse,
    }, timeout)

    if err then
        return nil, err
    end

    return {
        logs = response.logs,
        total_count = response.total_count,
        filtered = response.filtered,
    }, nil
end

function logger_client.get_composition(filter: string?, timeout: string?): (table?, string?)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.COMPOSITION,
        filter = filter,
    }, timeout)

    if err then
        return nil, err
    end

    return {
        composition = response.composition,
    }, nil
end

function logger_client.get_stats(timeout: string?): (table?, string?)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.GET_STATS,
    }, timeout)

    if err then
        return nil, err
    end

    return response.stats :: table?, nil
end

function logger_client.clear(timeout: string?): (boolean, string?)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.CLEAR,
    }, timeout)

    if err then
        return false, err
    end

    return true, nil
end

function logger_client.configure(buffer_size: number, timeout: string?): (boolean, string?)
    if not buffer_size or buffer_size <= 0 then
        return false, "Invalid buffer size"
    end

    local response, err = send_and_wait({
        operation = consts.OPERATIONS.CONFIGURE,
        buffer_size = buffer_size,
    }, timeout)

    if err then
        return false, err
    end

    return true, nil
end

function logger_client.get_counters(timeout)
    local response, err = send_and_wait({
        operation = consts.OPERATIONS.GET_COUNTERS,
    }, timeout or "2s")

    if err then
        return nil, err
    end

    return {
        counters = response.counters,
        total_received = response.total_received,
        stored_count = response.stored_count,
    }, nil
end

return logger_client
