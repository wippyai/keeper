-- Thin tool wrapper for isolation-testing keeper.develop.context:prepare_context.
-- Calls the function with the supplied agent_id + prompt and returns the
-- resulting context blob verbatim so we can verify context_chain + embed
-- resolution end-to-end.

local funcs = require("funcs")

local function handler(params)
    local agent_id = params.agent_id
    local prompt = params.prompt
    if not agent_id or agent_id == "" then return nil, "agent_id required" end
    if not prompt or prompt == "" then return nil, "prompt required" end

    local result, err = funcs.new():call("keeper.develop.context:prepare_context", {
        agent_id = agent_id,
        prompt   = prompt,
    })
    if err then return nil, "prepare_context failed: " .. tostring(err) end
    return { context = result or "" }
end

return { handler = handler }
