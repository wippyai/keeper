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

function state_client.execute_commands(commands)
    if not commands or type(commands) ~= "table" then
        return nil, "Commands must be a table"
    end

    if #commands == 0 then
        return nil, "Commands cannot be empty"
    end

    process.send(
        consts.PROCESS_NAMES.ORCHESTRATOR,
        consts.TOPICS.COMMANDS,
        {
            operation = consts.OPERATIONS.EXECUTE_COMMANDS,
            commands = commands
        }
    )

    return true
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

function state_client.set_entry(entry_id, kind, definition, content, attributes, branch)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    if not kind or kind == "" then
        return nil, "Entry kind required"
    end

    if not definition or definition == "" then
        return nil, "Entry definition required"
    end

    return state_client.execute_commands({
        {
            type = "set_entry",
            payload = {
                id = entry_id,
                kind = kind,
                definition = definition,
                content = content,
                attributes = attributes,
                branch = branch or consts.BRANCH.MAIN
            }
        }
    })
end

function state_client.delete_entry(entry_id, branch)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    return state_client.execute_commands({
        {
            type = "delete_entry",
            payload = {
                id = entry_id,
                branch = branch or consts.BRANCH.MAIN
            }
        }
    })
end

function state_client.set_edge(source_id, target_id, edge_type, metadata, branch)
    if not source_id or source_id == "" then
        return nil, "Source ID required"
    end

    if not target_id or target_id == "" then
        return nil, "Target ID required"
    end

    if not edge_type or edge_type == "" then
        return nil, "Edge type required"
    end

    return state_client.execute_commands({
        {
            type = "set_edge",
            payload = {
                source_id = source_id,
                target_id = target_id,
                edge_type = edge_type,
                metadata = metadata,
                branch = branch or consts.BRANCH.MAIN
            }
        }
    })
end

function state_client.delete_edge(source_id, target_id, edge_type, branch)
    if not source_id or source_id == "" then
        return nil, "Source ID required"
    end

    if not target_id or target_id == "" then
        return nil, "Target ID required"
    end

    if not edge_type or edge_type == "" then
        return nil, "Edge type required"
    end

    return state_client.execute_commands({
        {
            type = "delete_edge",
            payload = {
                source_id = source_id,
                target_id = target_id,
                edge_type = edge_type,
                branch = branch or consts.BRANCH.MAIN
            }
        }
    })
end

function state_client.set_attribute(entry_id, attr_key, attr_value, branch)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    if not attr_key or attr_key == "" then
        return nil, "Attribute key required"
    end

    return state_client.execute_commands({
        {
            type = "set_attribute",
            payload = {
                entry_id = entry_id,
                attr_key = attr_key,
                attr_value = attr_value,
                branch = branch or consts.BRANCH.MAIN
            }
        }
    })
end

function state_client.delete_attribute(entry_id, attr_key, branch)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    if not attr_key or attr_key == "" then
        return nil, "Attribute key required"
    end

    return state_client.execute_commands({
        {
            type = "delete_attribute",
            payload = {
                entry_id = entry_id,
                attr_key = attr_key,
                branch = branch or consts.BRANCH.MAIN
            }
        }
    })
end

return state_client