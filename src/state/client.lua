local consts = require("state_consts")
local uuid = require("uuid")
local time = require("time")

local state_client = {}

local function generate_channel_name()
    local id, err = uuid.v4()
    if err then
        error("Failed to generate UUID for channel name: " .. err)
    end
    return "state.response." .. id
end

local function send_and_wait(message, timeout)
    timeout = timeout or "5s"

    local response_channel_name = generate_channel_name()
    message.respond_to = response_channel_name
    local response_channel = process.listen(response_channel_name)

    local ok = process.send(consts.PROCESS_NAMES.ORCHESTRATOR, consts.TOPICS.COMMANDS, message)
    if not ok then
        return nil, "Failed to send message to orchestrator"
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
        return nil, response.error or "Unknown error"
    end

    return response, nil
end

function state_client.sync_branch(branch, entry_ids, timeout)
    if not branch or branch == "" then
        return nil, "Branch parameter required"
    end

    if not entry_ids or type(entry_ids) ~= "table" or #entry_ids == 0 then
        return nil, "entry_ids parameter required (non-empty array)"
    end

    local message = {
        operation = consts.OPERATIONS.SYNC_BRANCH,
        branch = branch,
        entry_ids = entry_ids
    }

    local response, err = send_and_wait(message, timeout)
    if not response then
        return nil, err
    end

    return true, nil
end

return state_client