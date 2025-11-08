local ctx = require("ctx")
local pattern_registry = require("pattern_registry")

local function handler(params)
    local pattern_class = params and params.pattern_class

    if not pattern_class or (type(pattern_class) == "table" and #pattern_class == 0) then
        local context_class, err = ctx.get("pattern_class")
        if not err and context_class and context_class ~= "" then
            if type(context_class) == "string" then
                pattern_class = {context_class}
            else
                pattern_class = context_class
            end
        end
    end

    local patterns
    if pattern_class and #pattern_class > 0 then
        patterns = pattern_registry.list_by_classes(pattern_class)
    else
        patterns = pattern_registry.list_all()
    end

    if not patterns or #patterns == 0 then
        return "No patterns found"
    end

    table.sort(patterns, function(a, b)
        return a.id < b.id
    end)

    local lines = {}
    table.insert(lines, "Optional patterns to read (using read_pattern) (" .. #patterns .. "):")
    table.insert(lines, "")

    for _, pattern in ipairs(patterns) do
        table.insert(lines, "- Pattern ID: " .. pattern.id)
        if pattern.title and pattern.title ~= "" then
            table.insert(lines, "  Title: " .. pattern.title)
        end
        if pattern.comment and pattern.comment ~= "" then
            table.insert(lines, "  Description: " .. pattern.comment)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }