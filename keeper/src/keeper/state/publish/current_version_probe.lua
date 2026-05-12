local governance = require("governance")

local function handle()
    local version, err = governance.current_version()
    if err then return nil, err end
    return { version = version }
end

return { handle = handle }
