local http = require("http")
local system = require("system")
local security = require("security")

type SystemInfoProvider = { info: () -> unknown }
type SystemExtensions = {
    cpu: SystemInfoProvider?,
    runtime: SystemInfoProvider?,
}

local system_ext = system :: SystemExtensions

local function handler()
    local res = http.response()
    if not res then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local info = {}

    local mem_ok, mem = pcall(function() return system.memory.stats() end)
    if mem_ok and mem then info.memory = mem end

    local cpu_ok, cpu = pcall(function()
        return system_ext.cpu and system_ext.cpu.info() or nil
    end)
    if cpu_ok and cpu then info.cpu = cpu end

    local rt_ok, rt = pcall(function()
        return system_ext.runtime and system_ext.runtime.info() or nil
    end)
    if rt_ok and rt then info.runtime = rt end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, info = info })
end

return { handler = handler }
