local json = require("json")
local uuid = require("uuid")
local ctx = require("ctx")
local logger = require("logger")
local time = require("time")
local artifact_repo = require("artifact_repo")

local log = logger:named("lint.hil")

local function create_approval_artifact(request_id, session_id, changeset, options)
    local title = string.format("Approve %d Registry Changes", #changeset)

    local view_params = {
        request_id = request_id,
        changeset_count = #changeset,
        changeset = changeset,
        options = options
    }

    local params_json, json_err = json.encode(view_params)
    if json_err then
        return false, "Failed to encode view parameters: " .. json_err
    end

    local artifact, err = artifact_repo.create(
        request_id,
        session_id,
        "view_ref",
        title,
        params_json,
        {
            content_type = "text/html",
            description = "Human-in-loop approval for registry changes",
            status = "active",
            page_id = "keeper.hil.views:approval",
            display_type = "inline-interactive",
            urgent = true
        }
    )

    if err then
        return false, "Failed to create artifact: " .. err
    end

    process.send("session." .. session_id, "command", {
        command = "artifact",
        artifact_id = request_id,
        urgent = true
    })

    return true, nil
end

local function handle(request)
    log:info("HIL linter executing")

    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to HIL linter"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    if not options.request_hil then
        log:debug("HIL not requested, passing through")
        return {
            success = true,
            changeset = changeset,
            issues = {},
            message = "HIL not requested, changeset passed through"
        }
    end

    log:info("HIL approval requested", {
        changeset_count = #changeset,
        has_session_id = options.session_id ~= nil
    })

    if not options.session_id or options.session_id == "" then
        log:error("HIL requested but no session_id provided")
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "HIL_NO_SESSION",
                message = "Human-in-loop approval requires active session"
            } },
            message = "HIL approval requires active session"
        }
    end

    local hil_request_id = uuid.v4()
    if not hil_request_id then
        log:error("Failed to generate HIL request ID")
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "HIL_ID_GENERATION_FAILED",
                message = "Failed to generate HIL request ID"
            } },
            message = "HIL ID generation failed"
        }
    end

    local process_name = "hil.request." .. hil_request_id
    process.registry.register(process_name, process.pid())

    local artifact_success, artifact_err = create_approval_artifact(hil_request_id, options.session_id, changeset, options)
    if not artifact_success then
        log:error("Failed to create approval artifact", { error = artifact_err })
        process.registry.unregister(process_name)
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "HIL_ARTIFACT_FAILED",
                message = "Failed to create approval interface: " .. (artifact_err or "unknown error")
            } },
            message = "HIL artifact creation failed"
        }
    end

    local decision_channel = process.listen("hil_decision")
    local timeout = time.after("300s")

    log:info("Waiting for HIL approval", { request_id = hil_request_id })

    local result = channel.select({
        decision_channel:case_receive(),
        timeout:case_receive()
    })

    process.registry.unregister(process_name)

    if result.channel == timeout then
        log:error("HIL approval timed out", { request_id = hil_request_id })
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "HIL_TIMEOUT",
                message = "HIL approval request timed out after 5 minutes"
            } },
            message = "HIL approval timed out"
        }
    end

    local decision = result.value

    log:info("HIL approval completed", {
        request_id = hil_request_id,
        approved = decision.approved,
        reason = decision.reason
    })

    local reason = decision.reason or ""

    if decision.approved then
        local message_parts = { "Changes approved by human reviewer" }
        if reason and reason ~= "" then
            table.insert(message_parts, ": ")
            table.insert(message_parts, reason)
        end

        return {
            success = true,
            changeset = changeset,
            issues = { {
                level = "info",
                code = "HIL_APPROVED",
                message = table.concat(message_parts)
            } },
            message = table.concat(message_parts)
        }
    else
        local message_parts = { "Changes rejected by human reviewer" }
        if reason and reason ~= "" then
            table.insert(message_parts, ": ")
            table.insert(message_parts, reason)
        end

        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "HIL_REJECTED",
                message = table.concat(message_parts)
            } },
            message = table.concat(message_parts)
        }
    end
end

return {
    handle = handle
}
