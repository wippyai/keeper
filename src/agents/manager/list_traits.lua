local registry = require("registry")
local json = require("json")
local traits = require("traits")

local function handler(params)
    local response = {
        success = false,
        traits = {},
        error = nil,
        count = 0
    }

    local criteria = {
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.trait"
    }

    local entries, err = registry.find(criteria)
    if err then
        response.error = "Failed to query registry: " .. tostring(err)
        return response
    end

    if not entries or #entries == 0 then
        response.success = true
        response.traits = {}
        response.count = 0
        return response
    end

    local processed_traits = {}

    for _, entry in ipairs(entries) do
        local namespace, name
        if type(entry.id) == "string" then
            namespace, name = entry.id:match("([^:]+):(.+)")
        end

        local trait = {
            id = entry.id,
            name = name or "unknown",
            namespace = namespace or "unknown",
            description = "",
            has_build_func = entry.data and entry.data.build_func_id ~= nil or false,
            has_prompt_func = entry.data and entry.data.prompt_func_id ~= nil or false,
            has_step_func = entry.data and entry.data.step_func_id ~= nil or false,
            tools_count = 0,
            prompt_length = 0
        }

        if entry.meta then
            if entry.meta.description then
                trait.description = entry.meta.description
            elseif entry.meta.comment then
                trait.description = entry.meta.comment
            end
        end

        if entry.data then
            if entry.data.tools then
                trait.tools_count = #entry.data.tools
            end

            if entry.data.prompt then
                trait.prompt_length = #entry.data.prompt
            end
        end

        table.insert(processed_traits, trait)
    end

    table.sort(processed_traits, function(a, b)
        if a.namespace == b.namespace then
            return a.name < b.name
        else
            return a.namespace < b.namespace
        end
    end)

    response.success = true
    response.traits = processed_traits
    response.count = #processed_traits
    return response
end

return { handler = handler }