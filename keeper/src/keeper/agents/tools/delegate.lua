local flow = require("flow")
local ctx = require("ctx")
local agent_registry = require("agent_registry")
local audit = require("audit")

local M = {}

local deps = {
    flow = flow,
    ctx = ctx,
    agent_registry = agent_registry,
}

local TOOL_CALLING = {
    auto = true,
    any = true,
}

local function trim(value: unknown): string?
    if type(value) ~= "string" then return nil end
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function truthy(value)
    if value == true then return true end
    if value == false or value == nil then return false end
    value = tostring(value):lower()
    return value == "1" or value == "true" or value == "yes"
end

local function copy_table(value)
    local out = {}
    if type(value) ~= "table" then return out end
    for k, v in pairs(value) do out[k] = v end
    return out
end

local function required_string(args: table?, key: string): (string?, string?)
    local raw = args and args[key] or nil
    local value = trim(raw)
    if type(value) ~= "string" or value == "" then
        return nil, key .. " required"
    end
    return value
end

function M.normalize_args(args)
    if type(args) ~= "table" then return nil, "params table required" end

    local agent_id, agent_err = required_string(args, "agent_id")
    if agent_err then return nil, agent_err end

    local message, msg_err = required_string(args, "message")
    if msg_err then return nil, msg_err end

    local max_iterations = tonumber(args.max_iterations) or 16
    if max_iterations < 1 or max_iterations > 64 then
        return nil, "max_iterations must be 1..64"
    end

    local min_iterations = tonumber(args.min_iterations) or 1
    if min_iterations < 1 or min_iterations > max_iterations then
        return nil, "min_iterations must be 1..max_iterations"
    end

    local tool_calling = trim(args.tool_calling) or "auto"
    if not TOOL_CALLING[tool_calling] then
        return nil, "tool_calling must be auto or any"
    end

    local context = args.context
    if context ~= nil and type(context) ~= "table" then
        return nil, "context must be an object"
    end

    local system_prompt = trim(args.system_prompt) or ""
    if system_prompt == "" then
        system_prompt = "Complete the delegated request. Return a concise answer with any important evidence or blockers."
    end

    local model = trim(args.model) or ""
    if model == "" then model = nil end

    local title = trim(args.title) or ""
    if title == "" then title = nil end

    return {
        agent_id = agent_id,
        message = message,
        context = context or {},
        detached = truthy(args.detached),
        max_iterations = max_iterations,
        min_iterations = min_iterations,
        tool_calling = tool_calling,
        system_prompt = system_prompt,
        model = model,
        title = title,
    }
end

function M.resolve_agent(agent_id: string)
    local agent, err = deps.agent_registry.get_by_id(agent_id)
    if not agent then return nil, err or ("agent not found: " .. tostring(agent_id)) end
    return agent
end

function M.build_context(args)
    local base, err = deps.ctx.all()
    if err or type(base) ~= "table" then base = {} end

    local out = copy_table(base)
    for k, v in pairs(args.context or {}) do out[k] = v end

    out.from_agent_id = out.from_agent_id or base.agent_id or "keeper.agents.tools:delegate"
    out.delegate_target_agent_id = args.agent_id
    out.max_iterations = args.max_iterations
    return out
end

local function agent_title(agent, agent_id)
    return agent and (agent.title or agent.name) or agent_id
end

function M.build_flow(args, agent)
    local run_context = M.build_context(args)
    local title = args.title or ("Delegate to " .. agent_title(agent, args.agent_id))

    local agent_config = {
        inputs = { required = { "task" } },
        input_transform = { task = "inputs.task" },
        arena = {
            prompt = args.system_prompt,
            max_iterations = args.max_iterations,
            min_iterations = args.min_iterations,
            tool_calling = args.tool_calling,
            context = run_context,
        },
        metadata = {
            title = agent_title(agent, args.agent_id),
            icon = agent and agent.icon or "tabler:robot",
            delegation_from = run_context.from_agent_id,
        },
    }
    if args.model then agent_config.model = args.model end

    local f = deps.flow.create()
        :with_title(title)
        :with_metadata({
            type = "keeper_agent_delegate",
            target_agent = args.agent_id,
            created_by = "keeper.agents.tools:delegate",
        })
        :with_input(run_context)

    f:with_data(args.message)
        :as("task")
        :to("delegate", "task")

    f:agent(args.agent_id, agent_config)
        :as("delegate")
        :to("@success")
        :error_to("@fail")

    return f
end

local function do_handler(raw_args)
    local args, arg_err = M.normalize_args(raw_args)
    if arg_err then return nil, arg_err end

    local agent_id = args.agent_id
    if type(agent_id) ~= "string" then return nil, "agent_id required" end

    local agent, agent_err = M.resolve_agent(agent_id)
    if agent_err then return nil, agent_err end

    local f = M.build_flow(args, agent)
    if args.detached then
        local dataflow_id, start_err = f:start()
        if start_err then return nil, start_err end
        return {
            detached = true,
            dataflow_id = dataflow_id,
            agent_id = args.agent_id,
            title = args.title,
        }
    end

    local result, run_err = f:run()
    if run_err then return nil, run_err end
    return {
        detached = false,
        agent_id = args.agent_id,
        result = result,
    }
end

function M.handler(args)
    args = args or {}
    return audit.wrap({
        tool = "delegate_agent",
        discriminator = "delegate_agent",
        target = args.agent_id,
        params = {
            agent_id = args.agent_id,
            detached = args.detached,
            max_iterations = args.max_iterations,
            tool_calling = args.tool_calling,
        },
        summarise = function(_result, err)
            if err then return "delegate_agent failed: " .. tostring(err) end
            return "delegate_agent ok"
        end,
    }, function()
        return do_handler(args)
    end)
end

function M._set_deps(next_deps)
    local old = deps
    deps = next_deps or deps
    return old
end

return M
