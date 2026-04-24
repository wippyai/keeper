local http = require("http")
local env = require("env")
local registry = require("registry")
local security = require("security")
local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local entries, err = registry.find({ [".kind"] = "env.variable" })
    if not entries then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Failed to find environment variables: " .. (err or "unknown error") })
        return
    end

    local variables = {}
    for _, entry in ipairs(entries) do
        if entry and entry.id and not (entry.meta and entry.meta.private) then
            local env_var = tostring(entry.data.variable or entry.id)
            local value = env.get(env_var)

            table.insert(variables, {
                id = entry.id,
                env_var = env_var,
                readonly = (entry :: any).readonly == true,
                description = (entry.meta and entry.meta.comment) or "No description available",
                icon = (entry.meta and entry.meta.icon) or nil,
                has_value = value ~= nil and value ~= "",
            })
        end
    end

    table.sort(variables, function(a, b) return a.id < b.id end)

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, count = #variables, variables = variables })
end

return { handler = handler }
