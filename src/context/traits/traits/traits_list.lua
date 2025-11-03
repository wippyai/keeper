local registry = require("registry")

local function handler(params)
    local criteria = {
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.trait"
    }

    if params and params.namespace then
        criteria[".ns"] = params.namespace
    end

    local entries, err = registry.find(criteria)
    if err then
        return nil, "Failed to fetch traits: " .. err
    end

    if not entries or #entries == 0 then
        return "No traits found"
    end

    local traits_list = {}
    for _, entry in ipairs(entries) do
        local meta = entry.meta or {}
        local data = entry.data or {}
        table.insert(traits_list, {
            id = entry.id,
            title = meta.title or "",
            description = meta.comment or "",
            has_tools = data.tools and #data.tools > 0,
            has_prompt = data.prompt ~= nil,
            has_build_func = data.build_func_id ~= nil
        })
    end

    table.sort(traits_list, function(a, b)
        return a.id < b.id
    end)

    local lines = {}
    table.insert(lines, "Available Traits (" .. #traits_list .. "):")
    table.insert(lines, "")

    for _, trait in ipairs(traits_list) do
        table.insert(lines, "- Trait ID: " .. trait.id)
        if trait.title ~= "" then
            table.insert(lines, "  Title: " .. trait.title)
        end
        if trait.description ~= "" then
            table.insert(lines, "  Description: " .. trait.description)
        end
        local features = {}
        if trait.has_tools then table.insert(features, "tools") end
        if trait.has_prompt then table.insert(features, "prompt") end
        if trait.has_build_func then table.insert(features, "build_func") end
        if #features > 0 then
            table.insert(lines, "  Features: " .. table.concat(features, ", "))
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }