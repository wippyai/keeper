local ctx = require("ctx")
local state_reader = require("state_reader")
local materialize = require("materialize")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function handler(params)
    if not params.ids or #params.ids == 0 then
        return nil, "ids array is required"
    end

    local branches = get_active_branch()

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, "Failed to initialize state reader: " .. err
    end

    reader = reader:with_entries(unpack(params.ids))
        :include_chunks()

    local entries, err = reader:all()
    if err then
        return nil, "Failed to fetch entries: " .. err
    end

    if #entries == 0 then
        return "No entries found for provided IDs: " .. table.concat(params.ids, ", ")
    end

    table.sort(entries, function(a, b)
        return a.id < b.id
    end)

    local lines = {}

    for i, entry in ipairs(entries) do
        if i > 1 then
            table.insert(lines, "")
            table.insert(lines, "---")
            table.insert(lines, "")
        end

        table.insert(lines, "=== " .. entry.id .. " ===")
        table.insert(lines, "")

        local formatted = materialize.format_entry_structured(entry, false)
        if formatted then
            table.insert(lines, formatted)
        end
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
