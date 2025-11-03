local ctx = require("ctx")
local state_reader = require("state_reader")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function handler()
    local branches = get_active_branch()

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return "Error: Failed to initialize state reader"
    end

    reader = reader:with_kinds("registry.entry")
        :with_attributes({ ["meta.type"] = "module.spec" })
        :include_attributes()

    local entries, err = reader:all()
    if err then
        return "Error: Failed to fetch entries"
    end

    local specs = {}
    for _, entry in ipairs(entries) do
        local title = entry.attributes and entry.attributes["meta.title"] or ""
        local comment = entry.attributes and entry.attributes["meta.comment"] or ""

        table.insert(specs, {
            id = entry.id,
            title = title,
            comment = comment
        })
    end

    table.sort(specs, function(a, b)
        return a.id < b.id
    end)

    if #specs == 0 then
        return "No module specifications found in the system."
    end

    local lines = {}
    table.insert(lines, "Available Module Specifications (" .. #specs .. "):")
    table.insert(lines, "")

    for _, spec in ipairs(specs) do
        table.insert(lines, "- " .. spec.id)
        if spec.title ~= "" then
            table.insert(lines, "  Title: " .. spec.title)
        end
        if spec.comment ~= "" then
            table.insert(lines, "  " .. spec.comment)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
