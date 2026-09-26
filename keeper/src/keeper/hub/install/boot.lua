local hub_service = require("hub_service")

local function run()
    local result, check_err = hub_service.check_installed_floors()
    if check_err then
        return { status = "error", message = "installed runtime floor check failed: "
            .. tostring(check_err) }
    end
    if not result or not result.accepted then
        local blocker = result and result.blocker or {}
        return { status = "error", message = blocker.reason or "installed runtime floor refused",
            details = blocker }
    end
    return { status = "success", message = "installed runtime floors accepted" }
end

return { run = run }
