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
    local search_query = params.search
    local branches = get_active_branch()

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, "Failed to initialize state reader: " .. err
    end

    reader = reader:with_kinds("registry.entry")
        :with_attributes({ ["meta.type"] = "module.spec" })
        :include_attributes()

    if search_query and search_query ~= "" then
        reader = reader:with_search(search_query)
    end

    local entries, err = reader:all()
    if err then
        return nil, "Failed to fetch entries: " .. err
    end

    local specs = {}
    for _, entry in ipairs(entries) do
        local module = extract_name(entry.id)
        local title = entry.attributes and entry.attributes["meta.title"] or ""
        local comment = entry.attributes and entry.attributes["meta.comment"] or ""
        local tags = parse_tags(entry.attributes and entry.attributes["meta.tags"] or "")

        table.insert(specs, {
            id = entry.id,
            module = module,
            title = title,
            comment = comment,
            tags = tags
        })
    end

    table.sort(specs, function(a, b)
        return a.id < b.id
    end)

    return {
        success = true,
        specs = specs,
        count = #specs
    }
end

return { handler = handler }
