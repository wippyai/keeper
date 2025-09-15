local http = require("http")
local json = require("json")
local agent_registry = require("agent_registry")
local security = require("security")
local start_tokens = require("start_tokens")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then
        -- This error is internal and shouldn't typically reach the user
        return nil, "Failed to get HTTP context"
    end

    -- Security check: Ensure user is authenticated
    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    -- Get agent name/ID from path parameter 'id' or query parameter 'agent'
    local agent_identifier = req:param("id") or req:query("agent")
    if not agent_identifier or agent_identifier == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "Agent name/ID is required (use path param 'id' or query param 'agent')" })
        return
    end

    -- Determine if it's an ID (contains ':') or a name
    local agent_spec, spec_err
    if agent_identifier:find(":") then
        -- It's an ID in ns:name format
        agent_spec, spec_err = agent_registry.get_by_id(agent_identifier)
    else
        -- It's a name
        agent_spec, spec_err = agent_registry.get_by_name(agent_identifier)
    end

    if not agent_spec then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({ success = false, error = spec_err or ("Agent not found: " .. agent_identifier) })
        return
    end

    -- Determine model and kind: Use query params > agent spec > defaults
    local model = req:query("model") or agent_spec.model or "gpt-4o"
    local kind = req:query("kind") or "default"

    -- Prepare parameters for the start token
    local token_params = {
        agent = agent_spec.id,
        model = model,
        kind = kind
    }

    -- Generate the start token
    local token, token_err = start_tokens.pack(token_params)
    if not token then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = "Failed to generate start token: " .. (token_err or "unknown error") })
        return
    end

    -- Return the start token successfully
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, start_token = token })
end

return {
    handler = handler
}