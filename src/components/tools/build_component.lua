local security = require("security")
local time = require("time")
local builds = require("builds")
local audit = require("audit")

local TERMINAL = { success = true, failed = true, cancelled = true }
local DEFAULT_TIMEOUT_S = 180
local POLL_INTERVAL = "500ms"
local TAIL_LINES = 40
local ERROR_LINES = 60

local function wait_for_build(build_id, timeout_s)
    local deadline = os.time() + timeout_s
    while os.time() < deadline do
        local b = builds.get(build_id)
        if b and TERMINAL[b.status] then return b end
        time.sleep(POLL_INTERVAL)
    end
    return builds.get(build_id)
end

local function do_handler(params)
    params = params or {}

    local component_id = params.component_id
    if type(component_id) ~= "string" or component_id == "" then
        return nil, "component_id is required"
    end

    local actor = security.actor()
    local actor_id = actor and actor:id() or "agent"

    local build_id, err = builds.start(component_id, {
        trigger = "agent",
        triggered_by = actor_id,
    })
    if not build_id then
        return nil, "build start failed: " .. tostring(err)
    end

    local wait = params.wait
    if wait == nil then wait = true end

    if not wait then
        return {
            component_id = component_id,
            build_id     = build_id,
            status       = "queued",
            waited       = false,
        }
    end

    local timeout = tonumber(params.timeout_s) or DEFAULT_TIMEOUT_S
    if timeout < 10 then timeout = 10 end
    if timeout > 600 then timeout = 600 end

    local final = wait_for_build(build_id, timeout)
    if not final then
        return nil, "build status unknown (build_id=" .. build_id .. ")"
    end

    local status   = final.status or "unknown"
    local ok       = status == "success"
    local duration = final.duration_ms
    local exit_code = final.exit_code

    local with_lines = builds.get_with_lines(build_id)
    local lines = (with_lines and with_lines.lines) or {}
    local total = #lines

    local function fmt(ln)
        return "[" .. (ln.stream or "stdout") .. "] " .. tostring(ln.text or "")
    end

    local tail_parts = {}
    local tail_start = total > TAIL_LINES and (total - TAIL_LINES) or 0
    for i = tail_start + 1, total do
        if lines[i] and lines[i].text then
            table.insert(tail_parts, fmt(lines[i]))
        end
    end
    local tail_text = table.concat(tail_parts, "\n")

    local error_output = ""
    if not ok then
        local err_parts = {}
        for i = 1, total do
            local ln = lines[i]
            if ln and ln.text and (ln.stream == "stderr" or ln.stream == "system") then
                table.insert(err_parts, fmt(ln))
            end
        end
        if #err_parts > ERROR_LINES then
            local drop = #err_parts - ERROR_LINES
            local trimmed = { "... (" .. drop .. " earlier stderr/system lines omitted)" }
            for i = drop + 1, #err_parts do
                table.insert(trimmed, err_parts[i])
            end
            err_parts = trimmed
        end
        error_output = table.concat(err_parts, "\n")
    end

    local result = {
        component_id = component_id,
        build_id     = build_id,
        status       = status,
        success      = ok,
        duration_ms  = duration,
        exit_code    = exit_code,
        error        = final.error,
        log_tail     = tail_text,
        waited       = true,
    }
    if not ok and error_output ~= "" then
        result.error_output = error_output
    end
    return result
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "build_component",
        discriminator = "build_component",
        target        = params.component_id,
        params        = { component_id = params.component_id, wait = params.wait, timeout_s = params.timeout_s },
        summarise = function(result, err)
            if err then return "build failed: " .. tostring(err) end
            if type(result) == "table" then
                return "build " .. (result.status or "?") .. " for " .. (params.component_id or "?")
            end
            return "build done"
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
