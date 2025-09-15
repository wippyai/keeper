-- Enhanced client.lua with detailed error reporting

local json = require("json")
local time = require("time")
local uuid = require("uuid")
local security = require("security")
local logger = require("logger")
local consts = require("gov_consts")

local log = logger:named("registry.client")

local client = {}

-- Helper function to format detailed error information
local function format_detailed_error(response)
    local error_parts = {}

    -- Add main error message
    table.insert(error_parts, response.message or "Operation failed")

    -- Add validation details if present
    if response.details and type(response.details) == "table" and #response.details > 0 then
        table.insert(error_parts, "\nValidation Issues:")

        for i, issue in ipairs(response.details) do
            local issue_line = string.format("  %d. [%s] %s",
                i,
                (issue.type or issue.level or "ERROR"):upper(),
                issue.message or "Unknown issue"
            )

            -- Add entry ID if available
            if issue.id and issue.id ~= "unknown" then
                issue_line = issue_line .. string.format(" (Entry: %s)", issue.id)
            end

            table.insert(error_parts, issue_line)
        end
    end

    -- Add any additional error info
    if response.error and response.error ~= response.message then
        table.insert(error_parts, "\nAdditional Info: " .. response.error)
    end

    return table.concat(error_parts, "\n")
end

-- Enhanced response handler that includes detailed errors
local function handle_response(response, operation_name)
    if response.success then
        log:info(operation_name .. " completed successfully", {
            version = response.version,
            has_details = response.details ~= nil,
            has_changeset = response.changeset ~= nil
        })

        return {
            version = response.version,
            message = response.message,
            details = response.details,
            changeset = response.changeset,
            stats = response.stats
        }, nil
    else
        local detailed_error = format_detailed_error(response)

        log:error(operation_name .. " failed", {
            error = response.message,
            has_details = response.details ~= nil,
            details_count = response.details and #response.details or 0
        })

        return nil, detailed_error
    end
end

-- Rest of your existing helper functions remain the same...
local function generate_id()
    local id, err = uuid.v4()
    if err then
        log:error("Failed to generate UUID", { error = err })
        error("Failed to generate UUID: " .. err)
    end
    return id
end

local function generate_channel_name()
    local id, err = uuid.v4()
    if err then
        log:error("Failed to generate UUID for channel name", { error = err })
        error("Failed to generate UUID for channel name: " .. err)
    end
    return "registry.response." .. id
end

local function get_user_id()
    local actor = security.actor()
    if actor then
        return actor:id()
    end
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

local function send_and_wait(message, timeout_ms)
    timeout_ms = timeout_ms or consts.DEFAULTS.TIMEOUT_MS

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
        timeout_ms = timeout_ms
    })

    local timeout = time.after(timeout_ms)

    local result = channel.select({
        response_channel:case_receive(),
        timeout:case_receive()
    })

    if result.channel == timeout then
        log:error("Operation timed out", { timeout_seconds = timeout_ms / 1000 })
        return nil, "Operation timed out after " .. (timeout_ms / 1000) .. " seconds"
    end

    local response = result.value

    if not response.request_id or response.request_id ~= message.id then
        log:error("Received response for different request", {
            expected = message.id,
            received = response.request_id
        })
        return nil, "Received response for a different request"
    end

    log:debug("Received response", {
        success = response.success,
        operation = message.operation
    })

    return response
end

function client.get_state(options, timeout_ms)
    local ok, err = check_permission(consts.PERMISSIONS.READ, "state")
    if not ok then
        return nil, err
    end

    local user_id = get_user_id()

    local message = {
        id = generate_id(),
        operation = consts.OPERATIONS.GET_STATE,
        options = options or {},
        user_id = user_id,
        timestamp = time.now():unix()
    }

    log:debug("Requesting registry system state", { user_id = user_id })

    local response, err = send_and_wait(message, timeout_ms)
    if not response then
        return nil, err
    end

    if response.success then
        log:debug("Got registry system state")
        return response.state, nil
    else
        log:error("Failed to get registry system state", {
            error = response.message
        })
        return nil, format_detailed_error(response)
    end
end

function client.request_changes(changeset, options, timeout_ms)
    local ok, err = check_permission(consts.PERMISSIONS.WRITE, "changeset")
    if not ok then
        return nil, err
    end

    local processed_changeset, err = extract_changeset(changeset)
    if not processed_changeset then
        log:error("Failed to extract changeset", { error = err })
        return nil, err
    end

    local user_id = get_user_id()

    local message = {
        id = generate_id(),
        operation = consts.OPERATIONS.APPLY_CHANGES,
        changeset = processed_changeset,
        options = options or {},
        user_id = user_id,
        timestamp = time.now():unix(),
    }

    log:info("Requesting registry changes", {
        changeset_count = #processed_changeset,
        user_id = user_id
    })

    local response, err = send_and_wait(message, timeout_ms)
    if not response then
        return nil, err
    end

    return handle_response(response, "Changes application")
end

function client.request_version(version_id, options, timeout_ms)
    local ok, err = check_permission(consts.PERMISSIONS.VERSION, "version")
    if not ok then
        return nil, err
    end

    if type(version_id) ~= "string" then
        version_id = tostring(version_id)
    end

    local user_id = get_user_id()

    local message = {
        id = generate_id(),
        operation = consts.OPERATIONS.APPLY_VERSION,
        version_id = version_id,
        options = options or {},
        user_id = user_id,
        timestamp = time.now():unix()
    }

    log:info("Requesting version application", {
        version_id = version_id,
        user_id = user_id
    })

    local response, err = send_and_wait(message, timeout_ms)
    if not response then
        return nil, err
    end

    return handle_response(response, "Version application")
end

function client.request_download(options, timeout_ms)
    local ok, err = check_permission(consts.PERMISSIONS.SYNC, "download")
    if not ok then
        return nil, err
    end

    local user_id = get_user_id()

    local message = {
        id = generate_id(),
        operation = consts.OPERATIONS.DOWNLOAD,
        options = options or {},
        user_id = user_id,
        timestamp = time.now():unix()
    }

    log:info("Requesting download", { user_id = user_id })

    local response, err = send_and_wait(message, timeout_ms)
    if not response then
        return nil, err
    end

    return handle_response(response, "Download")
end

function client.request_upload(options, timeout_ms)
    local ok, err = check_permission(consts.PERMISSIONS.SYNC, "upload")
    if not ok then
        return nil, err
    end

    local user_id = get_user_id()

    local message = {
        id = generate_id(),
        operation = consts.OPERATIONS.UPLOAD,
        options = options or {},
        user_id = user_id,
        timestamp = time.now():unix()
    }

    log:info("Requesting upload", { user_id = user_id })

    local response, err = send_and_wait(message, timeout_ms)
    if not response then
        return nil, err
    end

    return handle_response(response, "Upload")
end

-- New function to get detailed validation info from last operation
function client.get_last_validation_details()
    -- This could be expanded to cache the last response details
    -- For now, it's a placeholder for debugging
    return "Use request_changes/upload with detailed error reporting enabled"
end

return client