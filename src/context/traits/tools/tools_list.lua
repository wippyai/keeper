local registry = require("registry")

local function handler(params)
    local criteria = {
        ["meta.type"] = "tool"
    }

    if params and params.namespace then
        criteria[".ns"] = params.namespace
    end

    local entries, err = registry.find(criteria)
    if err then
        return nil, "Failed to fetch tools: " .. err
    end

    if not entries or #entries == 0 then
        return "No tools found"
    end

    local tools = {}
    for _, entry in ipairs(entries) do
        local meta = entry.meta or {}
        table.insert(tools, {
            id = entry.id,
            alias = meta.llm_alias or "",
            description = meta.llm_description or meta.comment or ""
        })
    end

    table.sort(tools, function(a, b)
        return a.id < b.id
    end)

    local lines = {}
    table.insert(lines, "Available Tools (" .. #tools .. "):")
    table.insert(lines, "")

    for _, tool in ipairs(tools) do
        table.insert(lines, "- Tool ID: " .. tool.id)
        if tool.alias ~= "" then
            table.insert(lines, "  Alias: " .. tool.alias)
        end
        if tool.description ~= "" then
            table.insert(lines, "  Description: " .. tool.description)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }