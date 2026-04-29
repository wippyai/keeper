local transitions = require("transitions")

local function handler(args)
    local result, err = transitions.run(args or {})
    if err then
        return { ok = false, error = tostring(err) }
    end
    return { ok = true, result = result }
end

return { handler = handler }
