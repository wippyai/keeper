local ctx = require("ctx")
local state_reader = require("state_reader")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function extract_name(entry_id)
    if not entry_id or entry_id == "" then
        return nil
    end
    local colon_pos = entry_id:find(":")
    if colon_pos then
        return entry_id:sub(colon_pos + 1)
    end
    return entry_id
end

local function parse_tags(tags_str)
    if not tags_str or tags_str == "" then
        return {}
    end

    local tags = {}
    for tag in tags_str:gmatch("[^,]+") do
        tag = tag:gsub("^%s+", ""):gsub("%s+$", "")
        if tag ~= "" then
            table.insert(tags, tag)
        end
    end
    return tags
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
        :with_attributes({ ["meta.type"] = "module.spec" })
        :include_chunks()
        :include_attributes()

    local entries, err = reader:all()
    if err then
        return nil, "Failed to fetch entries: " .. err
    end

    local found = {}
    local not_found = {}

    for _, id in ipairs(params.ids) do
        local found_entry = false
        for _, entry in ipairs(entries) do
            if entry.id == id then
                found_entry = true
                break
            end
        end
        if not found_entry then
            table.insert(not_found, id)
        end
    end

    local specs = {}
    for _, entry in ipairs(entries) do
        local module = extract_name(entry.id)
        local title = entry.attributes and entry.attributes["meta.title"] or ""
        local comment = entry.attributes and entry.attributes["meta.comment"] or ""
        local tags = parse_tags(entry.attributes and entry.attributes["meta.tags"] or "")

        local content = ""
        if entry.chunks then
            for _, chunk in ipairs(entry.chunks) do
                if chunk.type == "content" then
                    content = chunk.content
                    break
                end
            end
        end

        table.insert(specs, {
            id = entry.id,
            module = module,
            title = title,
            comment = comment,
            tags = tags,
            content = content
        })
    end

    table.sort(specs, function(a, b)
        return a.id < b.id
    end)

    if #specs == 0 and #not_found == 0 then
        return "No specifications found for the provided IDs."
    end

    local lines = {}

    if #not_found > 0 then
        table.insert(lines, "Not found: " .. table.concat(not_found, ", "))
        table.insert(lines, "")
    end

    for i, spec in ipairs(specs) do
        if i > 1 then
            table.insert(lines, "")
            table.insert(lines, "---")
            table.insert(lines, "")
        end

        table.insert(lines, "# " .. spec.id)
        table.insert(lines, "")

        if spec.title ~= "" then
            table.insert(lines, "**Title:** " .. spec.title)
            table.insert(lines, "")
        end

        if spec.comment ~= "" then
            table.insert(lines, "**Description:** " .. spec.comment)
            table.insert(lines, "")
        end

        if #spec.tags > 0 then
            table.insert(lines, "**Tags:** " .. table.concat(spec.tags, ", "))
            table.insert(lines, "")
        end

        if spec.content ~= "" then
            table.insert(lines, "## Content")
            table.insert(lines, "")
            table.insert(lines, spec.content)
        end
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
