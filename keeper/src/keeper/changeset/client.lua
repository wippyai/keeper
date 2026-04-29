local time = require("time")
local uuid = require("uuid")
local consts = require("cs_consts")

local M = {}

local function generate_id()
    local id, err = uuid.v4()
    if err then error("uuid generation failed: " .. err) end
    return id
end

local function response_channel_name()
    local id = generate_id()
    return "keeper.changeset.response." .. id
end

-- Send a message to the central supervisor and wait for the reply.
-- The central supervisor processes messages serially, so this is inherently
-- single-op-at-a-time across the whole workspace system in v1.
local function send_and_wait(operation, args, timeout)
    timeout = timeout or "10s"

    local channel_name = response_channel_name()
    local message = {
        operation  = operation,
        args       = args or {},
        id         = generate_id(),
        respond_to = channel_name,
    }

    local reply_channel = process.listen(channel_name)

    local ok = process.send(
        consts.PROCESS_NAMES.CENTRAL,
        consts.TOPICS.COMMANDS,
        message
    )
    if not ok then
        return nil, consts.ERRORS.MAILBOX_SEND_FAILED
    end

    local timeout_ch = time.after(timeout)
    local result = channel.select({
        reply_channel:case_receive(),
        timeout_ch:case_receive(),
    })

    if result.channel == timeout_ch then
        return nil, consts.ERRORS.MAILBOX_TIMEOUT .. " after " .. timeout
    end

    local response = result.value
    if not response then
        return nil, "empty response"
    end
    if not response.success then
        return nil, response.error or "operation failed"
    end
    return response.result, nil
end

-- ============================================================================
-- Public API
-- ============================================================================

function M.create(args, timeout)
    return send_and_wait(consts.OPERATIONS.CREATE, args, timeout)
end

function M.open_or_resume(args, timeout)
    return send_and_wait(consts.OPERATIONS.OPEN_OR_RESUME, args, timeout)
end

function M.edit(args, timeout)
    return send_and_wait(consts.OPERATIONS.EDIT, args, timeout)
end

function M.drop(args, timeout)
    return send_and_wait(consts.OPERATIONS.DROP, args, timeout)
end

function M.transition(args, timeout)
    return send_and_wait(consts.OPERATIONS.TRANSITION, args, timeout)
end

function M.list_changes(changeset_id, timeout)
    return send_and_wait(consts.OPERATIONS.LIST_CHANGES, { changeset_id = changeset_id }, timeout)
end

function M.lock(changeset_id, actor_id, timeout)
    return send_and_wait(consts.OPERATIONS.LOCK, { changeset_id = changeset_id, actor_id = actor_id }, timeout)
end

function M.unlock(changeset_id, actor_id, timeout)
    return send_and_wait(consts.OPERATIONS.UNLOCK, { changeset_id = changeset_id, actor_id = actor_id }, timeout)
end

return M
