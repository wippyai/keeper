local time = require("time")
local uuid = require("uuid")
local security = require("security")
local logger = require("logger")
local consts = require("gov_consts")

local log = logger:named("registry.client")

local client = {}

local function format_detailed_error(response)
    local parts = { response.message or "Operation failed" }

    if response.details and type(response.details) == "table" and #response.details > 0 then
        table.insert(parts, "\nValidation Issues:")
        for i, issue in ipairs(response.details) do
            local line = string.format("  %d. [%s] %s",
                i,
                (issue.type or issue.level or "ERROR"):upper(),
                issue.message or "Unknown issue")
            if issue.id and issue.id ~= "unknown" then
                line = line .. string.format(" (Entry: %s)", issue.id)
            end
            table.insert(parts, line)
        end
    end

    if response.error and response.error ~= response.message then
        table.insert(parts, "\nAdditional Info: " .. response.error)
    end

    return table.concat(parts, "\n")
end

local function handle_response(response, operation_name)
    if response.success then
        log:info(operation_name .. " completed successfully", {
            version       = response.version,
            has_details   = response.details ~= nil,
            has_changeset = response.changeset ~= nil,
        })
        return {
            version   = response.version,
            message   = response.message,
            details   = response.details,
            changeset = response.changeset,
            stats     = response.stats,
            file_ops  = response.file_ops,
        }, nil
    end

    log:error(operation_name .. " failed", {
        error         = response.message,
        has_details   = response.details ~= nil,
        details_count = response.details and #response.details or 0,
    })
    return nil, format_detailed_error(response)
end

local function generate_id()
    local id, err = uuid.v4()
    if err then error("Failed to generate UUID: " .. err) end
    return id
end

local function generate_channel_name()
    return "registry.response." .. generate_id()
end

local function get_user_id()
    local actor = security.actor()
    if actor then return actor:id() end
    return nil
end

local function check_permission(permission, resource)
    local can, err = security.can(permission, resource)
    if err then
        log:warn("Security check error", { permission = permission, error = err })
        return false, "Security check error: " .. err
    end
    if not can then
        log:warn("Permission denied", { permission = permission, resource = resource })
        return false, "Permission denied: " .. permission .. (resource and (" for " .. resource) or "")
    end
    return true
end

local function extract_changeset(changeset)
    if type(changeset) == "table" and changeset[1] and changeset[1].kind then
        return changeset
    end
    if type(changeset) == "userdata" and type(changeset.ops) == "function" then
        return changeset:ops()
    end
    return nil, "Invalid changeset format"
end

local function send_and_wait(message, timeout)
    timeout = timeout or consts.DEFAULTS.TIMEOUT

    local response_channel_name = generate_channel_name()
    message.respond_to = response_channel_name
    local response_channel = process.listen(response_channel_name)

    local ok = process.send(consts.PROCESS_NAME, consts.TOPICS.COMMANDS, message)
    if not ok then
        log:error("Failed to send message", { recipient = consts.PROCESS_NAME })
        return nil, "Failed to send message to governance process"
    end

    log:debug("Sent message, waiting for response", {
        operation = message.operation,
        timeout   = timeout,
    })

    local timeout_ch = time.after(timeout)
    local result = channel.select({
        response_channel:case_receive(),
        timeout_ch:case_receive(),
    })

    if result.channel == timeout_ch then
        log:error("Operation timed out", { timeout = timeout })
        return nil, "Operation timed out after " .. timeout
    end

    local response = result.value
    if not response.request_id or response.request_id ~= message.id then
        log:error("Received response for different request", {
            expected = message.id,
            received = response.request_id,
        })
        return nil, "Received response for a different request"
    end

    log:debug("Received response", {
        success   = response.success,
        operation = message.operation,
    })

    return response
end

local function build_message(operation, extra)
    local message = {
        id        = generate_id(),
        operation = operation,
        options   = extra and extra.options or {},
        user_id   = get_user_id(),
        timestamp = time.now():unix(),
    }
    if extra then
        for k, v in pairs(extra) do
            if k ~= "options" then message[k] = v end
        end
    end
    return message
end

local function dispatch(spec)
    local ok, err = check_permission(spec.permission, spec.resource)
    if not ok then return nil, err end

    local message = build_message(spec.operation, spec.extra)
    log:info(spec.log_prefix, { user_id = message.user_id })

    local response, send_err = send_and_wait(message, spec.timeout)
    if not response then return nil, send_err end

    if spec.raw then return response, nil end
    return handle_response(response, spec.op_label)
end

function client.get_state(options, timeout)
    local response, err = dispatch({
        permission = consts.PERMISSIONS.READ,
        resource   = "state",
        operation  = consts.OPERATIONS.GET_STATE,
        extra      = { options = options or {} },
        log_prefix = "Requesting registry system state",
        timeout    = timeout,
        raw        = true,
    })
    if not response then return nil, err end

    if response.success then return response.state, nil end
    log:error("Failed to get registry system state", { error = response.message })
    return nil, format_detailed_error(response)
end

function client.request_changes(changeset, options, timeout)
    local processed, xerr = extract_changeset(changeset)
    if not processed then
        log:error("Failed to extract changeset", { error = xerr })
        return nil, xerr
    end
    return dispatch({
        permission = consts.PERMISSIONS.WRITE,
        resource   = "changeset",
        operation  = consts.OPERATIONS.APPLY_CHANGES,
        extra      = { changeset = processed, options = options or {} },
        log_prefix = "Requesting registry changes",
        op_label   = "Changes application",
        timeout    = timeout,
    })
end

function client.request_version(version_id, options, timeout)
    if type(version_id) ~= "string" then version_id = tostring(version_id) end
    return dispatch({
        permission = consts.PERMISSIONS.VERSION,
        resource   = "version",
        operation  = consts.OPERATIONS.APPLY_VERSION,
        extra      = { version_id = version_id, options = options or {} },
        log_prefix = "Requesting version application",
        op_label   = "Version application",
        timeout    = timeout,
    })
end

function client.request_download(options, timeout)
    return dispatch({
        permission = consts.PERMISSIONS.SYNC,
        resource   = "download",
        operation  = consts.OPERATIONS.DOWNLOAD,
        extra      = { options = options or {} },
        log_prefix = "Requesting download",
        op_label   = "Download",
        timeout    = timeout,
    })
end

function client.request_upload(options, timeout)
    return dispatch({
        permission = consts.PERMISSIONS.SYNC,
        resource   = "upload",
        operation  = consts.OPERATIONS.UPLOAD,
        extra      = { options = options or {} },
        log_prefix = "Requesting upload",
        op_label   = "Upload",
        timeout    = timeout,
    })
end

return client
