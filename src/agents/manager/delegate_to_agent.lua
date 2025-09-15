local json = require("json")
local uuid = require("uuid")
local client = require("client")
local consts = require("consts")
local agent_registry = require("agent_registry")
local ctx = require("ctx")

local function handler(params)
    local response = {
        success = false,
        agent_id = params.agent_id,
        message = params.message,
        error = nil
    }

    if not params.agent_id or type(params.agent_id) ~= "string" or params.agent_id == "" then
        response.error = "Missing required parameter: agent_id"
        return response
    end

    if not params.message or type(params.message) ~= "string" or params.message == "" then
        response.error = "Missing required parameter: message"
        return response
    end

    -- Resolve agent by ID or name
    local target_agent_id = params.agent_id
    local agent_spec, lookup_err = agent_registry.get_by_id(target_agent_id)
    if not agent_spec then
        -- Try by name if ID lookup failed
        agent_spec, lookup_err = agent_registry.get_by_name(target_agent_id)
        if agent_spec then
            -- Get the actual ID from the registry lookup
            local entries, _ = require("registry").find({
                [".kind"] = "registry.entry",
                ["meta.type"] = "agent.gen1",
                ["meta.name"] = target_agent_id
            })
            if entries and #entries > 0 then
                target_agent_id = entries[1].id
            end
        end
    end

    if not agent_spec then
        response.error = "Agent not found: " .. params.agent_id .. " (" .. (lookup_err or "unknown error") .. ")"
        return response
    end

    -- Get agent title for metadata
    local agent_title = "Delegated Agent"
    if agent_spec and agent_spec.title then
        agent_title = agent_spec.title
    elseif agent_spec and agent_spec.name then
        agent_title = agent_spec.name
    else
        agent_title = target_agent_id
    end

    -- Get all session context
    local session_context, ctx_err = ctx.all()
    if ctx_err then
        session_context = {}
    end

    -- Merge with provided context
    if params.context then
        for k, v in pairs(params.context) do
            session_context[k] = v
        end
    end

    -- Add delegation metadata
    session_context.from_agent_id = session_context.from_agent_id or "keeper.agents.manager:manager"
    session_context.to_agent_id = target_agent_id

    -- Create dataflow client
    local c, client_err = client.new()
    if client_err then
        response.error = "Failed to create dataflow client: " .. client_err
        return response
    end

    local node_id = uuid.v7()
    local input_data_id = uuid.v7()
    local node_input_id = uuid.v7()

    -- Create workflow with agent node
    local workflow_commands = {
        {
            type = consts.COMMAND_TYPES.CREATE_NODE,
            payload = {
                node_id = node_id,
                node_type = "userspace.dataflow.node.agent:node",
                status = consts.STATUS.PENDING,
                config = {
                    agent = target_agent_id,
                    arena = {
                        prompt = params.message,
                        max_iterations = session_context.max_iterations or 64,
                        min_iterations = 1,
                        tool_calling = "auto",
                        context = session_context
                    },
                    data_targets = {
                        { data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT, content_type = consts.CONTENT_TYPE.JSON }
                    }
                },
                metadata = {
                    title = agent_title,
                    delegation_from = session_context.from_agent_id,
                    delegation_type = "manager_delegation"
                }
            }
        },
        {
            type = consts.COMMAND_TYPES.CREATE_DATA,
            payload = {
                data_id = input_data_id,
                data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                content = params.message,
                content_type = consts.CONTENT_TYPE.TEXT
            }
        },
        {
            type = consts.COMMAND_TYPES.CREATE_DATA,
            payload = {
                data_id = node_input_id,
                data_type = consts.DATA_TYPE.NODE_INPUT,
                key = input_data_id,
                node_id = node_id,
                content_type = consts.CONTENT_TYPE.REFERENCE,
                content = ""
            }
        }
    }

    -- Create and execute workflow
    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
        metadata = {
            title = "Manager → " .. agent_title,
            delegation_type = "manager_delegation",
            target_agent = target_agent_id,
            source_agent = "keeper.agents.manager:manager",
            message = params.message,
            created_by = "keeper.agents.manager:delegate_to_agent"
        }
    })

    if create_err then
        response.error = "Failed to create delegation workflow: " .. create_err
        return response
    end

    -- Execute workflow
    local result, exec_err = c:execute(dataflow_id, {
        init_func_id = "userspace.dataflow.session:artifact"
    })

    if exec_err then
        response.error = "Failed to execute delegation workflow: " .. exec_err
        return response
    end

    -- Return delegation result
    response.success = true
    response.workflow_id = dataflow_id
    response.agent_title = agent_title
    response.target_agent_id = target_agent_id
    response.result = result
    return response
end

return { handler = handler }