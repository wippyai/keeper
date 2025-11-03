local client = require("client")

local function run(version)
    if not version then
        return nil, "Version required"
    end

    local version_num = tonumber(version)
    if not version_num then
        return nil, "Invalid version: must be number"
    end

    if version_num < 0 then
        return nil, "Invalid version: must be non-negative"
    end

    local result, err = client.request_version(version_num)
    if err then
        return nil, "Rollback failed: " .. err
    end

    return result
end

return {run = run}
