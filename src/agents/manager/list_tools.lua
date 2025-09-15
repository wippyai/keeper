local registry = require("registry")
local json = require("json")

local function handler(params)
    local response = {
        success = false,
        tools = {},
        error = nil,
        count = 0,
        filters_applied = {}
    }

    params = params or {}
    local limit = params.limit or 50
    local include_schemas = params.include_schemas == true

    if limit < 1 or limit > 1000 then
        response.error = "Invalid limit: must be between 1 and 1000"
        return response
    end

    local criteria = {
        ["meta.type"] = "tool"
    }

    if params.namespace then
        criteria[".ns"] = params.namespace
        response.filters_applied.namespace = params.namespace
    end

    local entries, err = registry.find(criteria)
    if err then
        response.error = "Failed to query registry: " .. tostring(err)
        return response
    end

    if not entries or #entries == 0 then
        response.success = true
        response.tools = {}
        response.count = 0
        return response
    end

    local processed_tools = {}

    for _, entry in ipairs(entries) do
        local namespace, name
        if type(entry.id) == "string" then
            namespace, name = entry.id:match("([^:]+):(.+)")
        end

        local tool = {
            id = entry.id,
            name = name or "unknown",
            namespace = namespace or "unknown",
            description = "",
            llm_alias = "",
            kind = entry.kind
        }

        if entry.meta then
            if entry.meta.llm_description then
                tool.description = entry.meta.llm_description
            elseif entry.meta.description then
                tool.description = entry.meta.description
            elseif entry.meta.comment then
                tool.description = entry.meta.comment
            end

            if entry.meta.llm_alias then
                tool.llm_alias = entry.meta.llm_alias
            end

            if entry.meta.title then
                tool.title = entry.meta.title
            end
        end

        if include_schemas and entry.meta and entry.meta.input_schema then
            if type(entry.meta.input_schema) == "string" then
                local schema, decode_err = json.decode(entry.meta.input_schema)
                if not decode_err then
                    tool.input_schema = schema
                else
                    tool.input_schema_raw = entry.meta.input_schema
                end
            else
                tool.input_schema = entry.meta.input_schema
            end
        end

        table.insert(processed_tools, tool)
    end

    table.sort(processed_tools, function(a, b)
        if a.namespace == b.namespace then
            return a.name < b.name
        else
            return a.namespace < b.namespace
        end
    end)

    if limit < #processed_tools then
        local limited_tools = {}
        for i = 1, limit do
            table.insert(limited_tools, processed_tools[i])
        end
        processed_tools = limited_tools
    end

    response.filters_applied.include_schemas = include_schemas

    response.success = true
    response.tools = processed_tools
    response.count = #processed_tools
    response.total_before_limit = #entries
    response.limit = limit
    return response
end

return { handler = handler }