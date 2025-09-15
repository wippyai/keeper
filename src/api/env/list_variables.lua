local http = require("http")
local json = require("json")
local env = require("env")
local registry = require("registry")

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Check HTTP method
    if req:method() ~= http.METHOD.GET then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Only GET method is allowed"
        })
        return
    end

    -- Get registry snapshot
    local snapshot, err = registry.snapshot()
    if not snapshot then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to get registry snapshot: " .. (err or "unknown error")
        })
        return
    end

    -- Find all environment variable entries
    local criteria = {
        [".kind"] = "env.variable"
    }

    local entries, err = registry.find(criteria)
    if not entries then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to find environment variables: " .. (err or "unknown error")
        })
        return
    end

    -- Process each variable and check if it has a value
    local variables = {}
    for _, entry in ipairs(entries) do
        if entry and entry.id and not (entry.meta and entry.meta.private) then
            local env_var = entry.data.variable or entry.id

            -- Check if the variable has a value
            local value, _ = env.get(env_var)
            local has_value = value ~= nil and value ~= ""

            -- Build variable info
            local variable_info = {
                id = entry.id,
                env_var = env_var,
                readonly = entry.readonly == true,
                description = (entry.meta and entry.meta.comment) or "No description available",
                icon = (entry.meta and entry.meta.icon) or nil,
                has_value = has_value
            }

            table.insert(variables, variable_info)
        end
    end

    -- Sort variables by name
    table.sort(variables, function(a, b)
        return a.id < b.id
    end)

    -- Return the list
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        count = #variables,
        variables = variables
    })
end

return {
    handler = handler
}
