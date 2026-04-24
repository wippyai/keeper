local audit = require("audit")
local state_reader = require("state_reader")
local materialize = require("materialize")
local branch_ctx = require("branch_ctx")
local summarize = require("summarize")

local function strip_source_chunks(entry)
    if not entry or not entry.chunks then return entry end
    local filtered = {}
    for _, chunk in ipairs(entry.chunks) do
        if chunk.type ~= "content" then
            table.insert(filtered, chunk)
        end
    end
    local stripped = {}
    for k, v in pairs(entry) do stripped[k] = v end
    stripped.chunks = filtered
    return stripped
end

local function do_handler(params)
    if not params.ids or #params.ids == 0 then
        return nil, "ids array is required"
    end

    local include_source = params.include_source
    if include_source == nil then include_source = true end

    local branches = branch_ctx.get_active_branch_chain()

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

        local target = include_source and entry or strip_source_chunks(entry)
        local formatted = materialize.format_entry_structured(target, false)
        if formatted then
            table.insert(lines, formatted)
        end
        if not include_source then
            table.insert(lines, "")
            table.insert(lines, "<source omitted: call get_entries with include_source=true to load the body before editing>")
        end
    end

    local rendered = table.concat(lines, "\n")

    if params.full ~= true then
        local goal = params.goal
        if not goal or goal == "" then
            goal = "Purpose and shape of: " .. table.concat(params.ids, ", ")
        end
        local compressed, _sum_err, was_summarized = summarize.summarize(rendered, goal, {
            tool = "get_entries",
        })
        if was_summarized then
            rendered = compressed
        end
    end

    return rendered
end

local function handler(params)
    params = params or {}
    local ids = params.ids or {}
    return audit.wrap({
        tool          = "get_entries",
        discriminator = params.include_source == false and "get_entries.meta" or "get_entries.full",
        target        = #ids == 1 and ids[1] or (tostring(#ids) .. " entries"),
        params        = {
            ids            = params.ids,
            include_source = params.include_source,
            goal           = params.goal,
            full           = params.full,
        },
        summarise = function(_result, err)
            if err then return "get_entries failed: " .. tostring(err) end
            return "loaded " .. #ids .. " entries"
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
