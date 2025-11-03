local logger = require("logger")
local time = require("time")
local json = require("json")
local expr = require("expr")
local events = require("events")
local consts = require("consts")

local log = logger:named("keeper.logger")

local function create_circular_buffer(size)
    local buffer = table.create(size, 0)
    return {
        data = buffer,
        size = size,
        head = 1,
        count = 0,
    }
end

local function buffer_add(buf, item)
    buf.data[buf.head] = item
    buf.head = buf.head % buf.size + 1
    if buf.count < buf.size then
        buf.count = buf.count + 1
    end
end

local function buffer_get_all(buf)
    local result = table.create(buf.count, 0)
    if buf.count == 0 then
        return result
    end

    if buf.count < buf.size then
        for i = 1, buf.count do
            result[i] = buf.data[i]
        end
    else
        local idx = 1
        for i = buf.head, buf.size do
            result[idx] = buf.data[i]
            idx = idx + 1
        end
        for i = 1, buf.head - 1 do
            result[idx] = buf.data[i]
            idx = idx + 1
        end
    end

    return result
end

local function apply_filter(logs, filter_expr)
    if not filter_expr or filter_expr == "" then
        return logs, nil
    end

    local program, err = expr.compile(filter_expr)
    if err then
        return nil, consts.ERRORS.FILTER_COMPILE_FAILED .. ": " .. err
    end

    local filtered = {}

    for _, entry in ipairs(logs) do
        local match, eval_err = program:run(entry)
        if eval_err then
            return nil, "Filter evaluation failed: " .. eval_err
        end

        if match then
            table.insert(filtered, entry)
        end
    end

    return filtered, nil
end

local function reverse_array(arr)
    local len = #arr
    for i = 1, math.floor(len / 2) do
        arr[i], arr[len - i + 1] = arr[len - i + 1], arr[i]
    end
end

local function take_count(logs, count)
    if not count or count <= 0 or count >= #logs then
        return logs
    end

    local result = table.create(count, 0)
    for i = 1, count do
        result[i] = logs[i]
    end
    return result
end

local function calculate_composition(logs)
    local by_level = {}
    local by_path = {}
    local field_keys = {}

    for _, entry in ipairs(logs) do
        local level = entry.level
        by_level[level] = (by_level[level] or 0) + 1

        local path = entry.path or "unknown"
        by_path[path] = (by_path[path] or 0) + 1

        if entry.fields then
            for k, _ in pairs(entry.fields) do
                field_keys[k] = (field_keys[k] or 0) + 1
            end
        end
    end

    return {
        by_level = by_level,
        by_path = by_path,
        field_keys = field_keys,
        total_logs = #logs,
    }
end

local function handle_get_logs(state, payload, from)
    local all_logs = buffer_get_all(state.buffer)

    local logs = all_logs
    local was_filtered = false

    if payload.filter then
        local filtered, err = apply_filter(all_logs, payload.filter)
        if err then
            process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                success = false,
                error = err,
                request_id = payload.id,
            })
            return
        end
        logs = filtered
        was_filtered = true
    end

    local count = payload.count
    if not count then
        count = 1000
    end

    logs = take_count(logs, count)

    local should_reverse = payload.reverse
    if should_reverse == nil then
        should_reverse = true
    end

    if should_reverse then
        reverse_array(logs)
    end

    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        logs = logs,
        total_count = state.buffer.count,
        filtered = was_filtered,
        request_id = payload.id,
    })
end

local function handle_composition(state, payload, from)
    local all_logs = buffer_get_all(state.buffer)

    local logs = all_logs

    if payload.filter then
        local filtered, err = apply_filter(all_logs, payload.filter)
        if err then
            process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                success = false,
                error = err,
                request_id = payload.id,
            })
            return
        end
        logs = filtered
    end

    local composition = calculate_composition(logs)

    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        composition = composition,
        request_id = payload.id,
    })
end

local function handle_get_stats(state, payload, from)
    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        stats = {
            buffer_size = state.buffer_size,
            stored_count = state.buffer.count,
            total_received = state.total_received,
            uptime_ns = time.now():unix_nano() - state.start_time,
        },
        request_id = payload.id,
    })
end

local function handle_clear(state, payload, from)
    state.buffer = create_circular_buffer(state.buffer_size)

    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        request_id = payload.id,
    })
end

local function handle_configure(state, payload, from)
    if payload.buffer_size and payload.buffer_size > 0 then
        local new_buffer = create_circular_buffer(payload.buffer_size)
        local existing = buffer_get_all(state.buffer)

        for i = math.max(1, #existing - payload.buffer_size + 1), #existing do
            buffer_add(new_buffer, existing[i])
        end

        state.buffer = new_buffer
        state.buffer_size = payload.buffer_size
    end

    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        buffer_size = state.buffer_size,
        request_id = payload.id,
    })
end

local function flatten_log_entry(evt)
    local entry_data = evt.data and evt.data.entry or {}
    local fields_data = evt.data and evt.data.fields or {}

    local fields_flat = {}
    for _, field in ipairs(fields_data) do
        if field.key then
            if field.string ~= "" then
                fields_flat[field.key] = field.string
            else
                fields_flat[field.key] = field.int
            end
        end
    end

    local flattened = {
        timestamp = time.now():unix_nano(),
        system = evt.system,
        kind = evt.kind,
        path = evt.path,
        level = entry_data.level or 0,
        time = entry_data.time or 0,
        logger_name = entry_data.logger_name or evt.path,
        message = entry_data.message or "",
        caller = entry_data.caller or "",
        stack = entry_data.stack or "",
        fields = fields_flat,
    }

    return flattened
end

local function run()
    log:info("Starting logger service")
    process.registry.register(consts.PROCESS_NAMES.LOGGER, process.pid())

    local state = {
        buffer = create_circular_buffer(consts.DEFAULT_BUFFER_SIZE),
        buffer_size = consts.DEFAULT_BUFFER_SIZE,
        total_received = 0,
        start_time = time.now():unix_nano(),
    }

    log:info("Initializing logger service")

    local sub, err = events.subscribe(consts.LOG_SYSTEM, consts.LOG_ENTRY_KIND)
    if not sub then
        log:error("Failed to subscribe to log events", { error = err })
        return { success = false, error = err }
    end

    local log_channel = sub:channel()
    local inbox = process.inbox()
    local proc_events = process.events()

    log:info("Logger service initialized")

    while true do
        local result = channel.select({
            log_channel:case_receive(),
            inbox:case_receive(),
            proc_events:case_receive()
        })

        if not result.ok then
            break
        end

        if result.channel == log_channel then
            state.total_received = state.total_received + 1
            local evt = result.value
            local flattened = flatten_log_entry(evt)
            buffer_add(state.buffer, flattened)
        elseif result.channel == inbox then
            local msg = result.value
            local payload = msg:payload():data()
            local from = msg:from()

            if payload.operation == consts.OPERATIONS.GET_LOGS then
                handle_get_logs(state, payload, from)
            elseif payload.operation == consts.OPERATIONS.COMPOSITION then
                handle_composition(state, payload, from)
            elseif payload.operation == consts.OPERATIONS.GET_STATS then
                handle_get_stats(state, payload, from)
            elseif payload.operation == consts.OPERATIONS.CLEAR then
                handle_clear(state, payload, from)
            elseif payload.operation == consts.OPERATIONS.CONFIGURE then
                handle_configure(state, payload, from)
            else
                process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                    success = false,
                    error = consts.ERRORS.INVALID_OPERATION,
                    request_id = payload.id,
                })
            end
        elseif result.channel == proc_events then
            local event = result.value
            if event.kind == process.event.CANCEL then
                sub:close()

                log:info("Logger service shut down", {
                    total_received = state.total_received,
                    stored_count = state.buffer.count,
                })

                return {
                    total_received = state.total_received,
                    stored_count = state.buffer.count,
                }
            end
        end
    end

    return { status = "completed" }
end

return { run = run }