local logger = require("logger")
local time = require("time")
local uuid = require("uuid")
local logger_client = require("logger_client")

local log = logger:named("logger.traits.query")

local function format_timestamp(nano)
    local sec = math.floor(nano / 1e9)
    local nsec = nano % 1e9
    local t = time.unix(sec, nsec)
    return t:format("2006-01-02 15:04:05")
end

local function format_fields(fields)
    if not fields or next(fields) == nil then
        return nil
    end

    local parts = {}
    for k, v in pairs(fields) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    return table.concat(parts, ", ")
end

local function handler(params)
    if not params then
        params = {}
    end

    local operation = params.operation
    if not operation then
        operation = "logs"
    end

    local timeout_ms = 5000
    local result, err

    if operation == "composition" then
        result, err = logger_client.get_composition(params.filter, timeout_ms)
        if err then
            return nil, "Failed to retrieve composition: " .. err
        end

        local comp = result.composition

        local lines = {}
        table.insert(lines, "Buffer Composition (" .. comp.total_logs .. " entries analyzed)")
        table.insert(lines, "")

        table.insert(lines, "By Level:")
        local level_names = {[-1] = "DEBUG", [0] = "INFO", [1] = "WARN", [2] = "ERROR"}
        for level = -1, 2 do
            local count = comp.by_level[tostring(level)]
            if not count then
                count = 0
            end
            if count > 0 then
                table.insert(lines, "  " .. level_names[level] .. ": " .. count)
            end
        end
        table.insert(lines, "")

        table.insert(lines, "Top Paths:")
        local path_list = {}
        for path, count in pairs(comp.by_path) do
            table.insert(path_list, {path = path, count = count})
        end
        table.sort(path_list, function(a, b) return a.count > b.count end)
        for i = 1, math.min(15, #path_list) do
            table.insert(lines, "  " .. path_list[i].path .. ": " .. path_list[i].count)
        end
        table.insert(lines, "")

        if next(comp.field_keys) then
            table.insert(lines, "Field Keys:")
            local field_list = {}
            for key, count in pairs(comp.field_keys) do
                table.insert(field_list, {key = key, count = count})
            end
            table.sort(field_list, function(a, b) return a.count > b.count end)
            for i = 1, math.min(15, #field_list) do
                table.insert(lines, "  " .. field_list[i].key .. ": " .. field_list[i].count)
            end
        end

        return table.concat(lines, "\n")

    elseif operation == "logs" then
        local reverse = params.reverse
        if reverse == nil then
            reverse = true
        end

        local count = params.count
        if not count then
            count = 1000
        end

        result, err = logger_client.get_logs(count, params.filter, reverse, timeout_ms)
        if err then
            return nil, "Failed to retrieve logs: " .. err
        end

        local lines = {}
        local header = "Retrieved " .. #result.logs .. " logs"
        if result.filtered then
            header = header .. " (filtered from " .. result.total_count .. " total)"
        end
        if reverse then
            header = header .. " [newest first]"
        else
            header = header .. " [oldest first]"
        end
        table.insert(lines, header)
        table.insert(lines, "")

        if #result.logs == 0 then
            table.insert(lines, "No logs found")
        else
            for _, entry in ipairs(result.logs) do
                local ts = format_timestamp(entry.timestamp)
                local level_str
                if entry.level == -1 then
                    level_str = "DEBUG"
                elseif entry.level == 0 then
                    level_str = "INFO"
                elseif entry.level == 1 then
                    level_str = "WARN"
                elseif entry.level == 2 then
                    level_str = "ERROR"
                else
                    level_str = "LEVEL" .. entry.level
                end

                local path = entry.path
                if not path then
                    path = "unknown"
                end

                local line = string.format("[%s] %s | %s | %s",
                    ts, level_str, path, entry.message)

                local fields_str = format_fields(entry.fields)
                if fields_str then
                    line = line .. " | " .. fields_str
                end

                table.insert(lines, line)
            end
        end

        return table.concat(lines, "\n")

    elseif operation == "stats" then
        result, err = logger_client.get_stats(timeout_ms)
        if err then
            return nil, "Failed to retrieve stats: " .. err
        end

        local uptime_sec = math.floor(result.uptime_ns / 1e9)
        local uptime_str
        if uptime_sec < 60 then
            uptime_str = uptime_sec .. "s"
        elseif uptime_sec < 3600 then
            uptime_str = math.floor(uptime_sec / 60) .. "m"
        else
            uptime_str = math.floor(uptime_sec / 3600) .. "h"
        end

        local lines = {}
        table.insert(lines, "Logger Buffer Statistics")
        table.insert(lines, "  Buffer size: " .. result.buffer_size)
        table.insert(lines, "  Stored: " .. result.stored_count)
        table.insert(lines, "  Total received: " .. result.total_received)
        table.insert(lines, "  Uptime: " .. uptime_str)

        return table.concat(lines, "\n")

    else
        return nil, "Invalid operation. Use: logs, stats, composition"
    end
end

return { handler = handler }