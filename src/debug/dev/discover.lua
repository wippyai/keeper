local http = require("http")
local registry = require("registry")
local time = require("time")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then
        return nil, "Failed to create HTTP context"
    end

    local options = { ["meta.type"] = "test" }

    local group = req:query("group")
    if group and group ~= "" then
        options.group = group
    end

    local tests, err = registry.find(options)
    if err then
        res:set_status(500)
        res:set_content_type("application/json")
        res:write_json({ success = false, error = tostring(err) })
        return
    end

    local suites = {}
    local suite_set = {}
    for _, t in ipairs(tests or {}) do
        local suite = t.meta and t.meta.suite or "default"
        if not suite_set[suite] then
            suite_set[suite] = true
            table.insert(suites, suite)
        end
    end
    table.sort(suites)

    res:set_content_type("application/json")
    res:write_json({
        success = true,
        tests = tests or {},
        suites = suites,
        count = #(tests or {}),
        timestamp = time.now():unix()
    })
end

return { handler = handler }
