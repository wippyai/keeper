local client = require("client")

local function run()
    local state, err = client.get_state()
    if err then
        return nil, err
    end
    return state.registry.current_version
end

return {run = run}
