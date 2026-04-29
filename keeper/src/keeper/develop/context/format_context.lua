local ctx = require("ctx")
local state_reader = require("state_reader")
local materialize = require("materialize")
local text = require("text")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function extract_entry_content(entry, mode)
    if not entry or not entry.chunks then
        return nil, "Entry has no content"
    end

    mode = mode or "full"

    if mode == "full" then
        return materialize.format_entry_structured(entry, false)
    end

    if mode == "definition" then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then
                return chunk.content
            end
        end
        return nil, "No definition found"
    end

    if mode == "source" then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "content" then
                return chunk.content
            end
        end
        return nil, "No source found"
    end

    return nil, "Unknown mode: " .. mode
end

local function mode_priority(mode)
    if mode == "full" then return 3 end
    if mode == "source" then return 2 end
    if mode == "definition" then return 1 end
    return 0
end

local function replace_embeds(content)
    local branches = get_active_branch()

    local regex, err = text.regexp.compile('<embed\\s+id="([^"]+)"(?:\\s+mode="([^"]+)")?\\s*/>')
    if err then
        return content
    end

    local matches = regex:find_all_string_submatch(content)
    if not matches or #matches == 0 then
        return content
    end

    local positions = regex:find_all_string_index(content)
    if not positions or #positions == 0 then
        return content
    end

    local entry_occurrences = {}
    for i, match in ipairs(matches) do
        local entry_id = match[2]
        local mode = match[3] or "full"
        local pos = positions[i]

        if not entry_occurrences[entry_id] then
            entry_occurrences[entry_id] = {
                positions = {},
                highest_mode = mode,
                highest_priority = mode_priority(mode)
            }
        end

        table.insert(entry_occurrences[entry_id].positions, {
            index = i,
            mode = mode,
            start_pos = pos[1],
            end_pos = pos[2]
        })

        local priority = mode_priority(mode)
        if priority > entry_occurrences[entry_id].highest_priority then
            entry_occurrences[entry_id].highest_mode = mode
            entry_occurrences[entry_id].highest_priority = priority
        end
    end

    local entry_ids = {}
    for id, _ in pairs(entry_occurrences) do
        table.insert(entry_ids, id)
    end

    if #entry_ids == 0 then
        return content
    end

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return content
    end

    reader = reader:with_entries(unpack(entry_ids)):include_chunks()

    local entries, err = reader:all()
    if err then
        return content
    end

    local entry_map = {}
    for _, entry in ipairs(entries) do
        entry_map[entry.id] = entry
    end

    local replacements = {}
    for i = 1, #matches do
        replacements[i] = nil
    end

    for entry_id, occurrence_data in pairs(entry_occurrences) do
        local entry = entry_map[entry_id]
        local first_pos_data = occurrence_data.positions[1]

        if entry then
            local entry_content, err = extract_entry_content(entry, occurrence_data.highest_mode)
            if entry_content then
                replacements[first_pos_data.index] = string.format(
                    "=== %s ===\n\n%s",
                    entry_id,
                    entry_content
                )
            else
                replacements[first_pos_data.index] = string.format(
                    "[Error: %s for %s]",
                    err or "Failed to extract content",
                    entry_id
                )
            end
        else
            replacements[first_pos_data.index] = string.format("[Error: Entry not found: %s]", entry_id)
        end

        for j = 2, #occurrence_data.positions do
            replacements[occurrence_data.positions[j].index] = ""
        end
    end

    local result = content
    for i = #matches, 1, -1 do
        local pos = positions[i]
        local replacement = replacements[i]

        if replacement ~= nil then
            result = result:sub(1, pos[1] - 1) .. replacement .. result:sub(pos[2] + 1)
        end
    end

    return result
end

local function run(input)
    local content = input.content

    if not content then
        return "No context gathered."
    end

    if type(content) == "table" then
        local parts = {}
        for _, item in ipairs(content) do
            if type(item) == "string" and item ~= "" then
                table.insert(parts, item)
            elseif type(item) == "table" and item.result then
                table.insert(parts, item.result)
            end
        end

        if #parts == 0 then
            return "No context gathered."
        end

        content = table.concat(parts, "\n\n---\n\n")
    end

    if content == "" then
        return "No context gathered."
    end

    return replace_embeds(content)
end

-- Public: resolve `<embed id="ns:name" mode="..."/>` placeholders against the
-- live state reader. Used both by the dataflow `func` entry-point (`run`,
-- consumed by prepare_context) and as a callable helper for tools that want
-- to deliver agent-ready content with sources inlined (e.g. read_context
-- on findings that researchers stamped with `<embed>` references).
local function resolve(content)
    if type(content) ~= "string" or content == "" then return content end
    return replace_embeds(content)
end

return { run = run, resolve = resolve }