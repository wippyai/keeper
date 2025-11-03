local ctx = require("ctx")
local state_reader = require("state_reader")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function extract_namespace(entry_id)
    if not entry_id or entry_id == "" then
        return nil
    end
    local colon_pos = entry_id:find(":")
    if colon_pos then
        return entry_id:sub(1, colon_pos - 1)
    end
    return nil
end

local function handler()
    local branches = get_active_branch()

    local all_entries = {}

    local views_reader, err = state_reader.for_branch(unpack(branches))
    if not err then
        views_reader = views_reader:with_kinds("template.jet")
            :with_attributes({ ["meta.type"] = "view.page" })
            :include_attributes()

        local views, _ = views_reader:all()
        if views then
            for _, entry in ipairs(views) do
                entry._category = "view"
                table.insert(all_entries, entry)
            end
        end
    end

    local templates_reader, err = state_reader.for_branch(unpack(branches))
    if not err then
        templates_reader = templates_reader:with_kinds("template.jet")
            :include_attributes()

        local templates, _ = templates_reader:all()
        if templates then
            for _, entry in ipairs(templates) do
                local is_view = entry.attributes and entry.attributes["meta.type"] == "view.page"
                if not is_view then
                    entry._category = "template"
                    table.insert(all_entries, entry)
                end
            end
        end
    end

    local sets_reader, err = state_reader.for_branch(unpack(branches))
    if not err then
        sets_reader = sets_reader:with_kinds("template.set")
            :include_attributes()

        local sets, _ = sets_reader:all()
        if sets then
            for _, entry in ipairs(sets) do
                entry._category = "template_set"
                table.insert(all_entries, entry)
            end
        end
    end

    local resources_reader, err = state_reader.for_branch(unpack(branches))
    if not err then
        resources_reader = resources_reader:with_kinds("registry.entry")
            :with_attributes({ ["meta.type"] = "view.resource" })
            :include_attributes()

        local resources, _ = resources_reader:all()
        if resources then
            for _, entry in ipairs(resources) do
                entry._category = "resource"
                table.insert(all_entries, entry)
            end
        end
    end

    local namespace_map = {}
    for _, entry in ipairs(all_entries) do
        local ns = extract_namespace(entry.id)
        if ns then
            if not namespace_map[ns] then
                namespace_map[ns] = {
                    views = {},
                    templates = {},
                    template_sets = {},
                    resources = {}
                }
            end

            if entry._category == "view" then
                table.insert(namespace_map[ns].views, entry)
            elseif entry._category == "template" then
                table.insert(namespace_map[ns].templates, entry)
            elseif entry._category == "template_set" then
                table.insert(namespace_map[ns].template_sets, entry)
            elseif entry._category == "resource" then
                table.insert(namespace_map[ns].resources, entry)
            end
        end
    end

    local sorted_namespaces = {}
    for ns, _ in pairs(namespace_map) do
        table.insert(sorted_namespaces, ns)
    end
    table.sort(sorted_namespaces)

    local lines = {}
    table.insert(lines, "VIEW ECOSYSTEM")
    table.insert(lines, "")

    for _, ns in ipairs(sorted_namespaces) do
        local data = namespace_map[ns]
        local total = #data.views + #data.templates + #data.template_sets + #data.resources

        table.insert(lines, ns .. " [" .. total .. "]")

        if #data.template_sets > 0 then
            table.insert(lines, "  Template Sets:")
            table.sort(data.template_sets, function(a, b)
                return a.id < b.id
            end)
            for _, entry in ipairs(data.template_sets) do
                local desc = entry.attributes and entry.attributes["meta.description"] or ""
                if desc ~= "" then
                    table.insert(lines, "    " .. entry.id)
                    table.insert(lines, "      " .. desc)
                else
                    table.insert(lines, "    " .. entry.id)
                end
            end
            table.insert(lines, "")
        end

        if #data.views > 0 then
            table.insert(lines, "  Views:")
            table.sort(data.views, function(a, b)
                local order_a = tonumber(a.attributes and a.attributes["meta.order"]) or 9999
                local order_b = tonumber(b.attributes and b.attributes["meta.order"]) or 9999
                if order_a == order_b then
                    return a.id < b.id
                end
                return order_a < order_b
            end)
            for _, entry in ipairs(data.views) do
                local title = entry.attributes and entry.attributes["meta.title"] or ""
                local desc = entry.attributes and entry.attributes["meta.comment"] or
                    entry.attributes and entry.attributes["meta.description"] or ""
                local order = tonumber(entry.attributes and entry.attributes["meta.order"]) or 9999
                local icon = entry.attributes and entry.attributes["meta.icon"] or ""
                local group = entry.attributes and entry.attributes["meta.group"] or ""
                local announced = entry.attributes and entry.attributes["meta.announced"]

                local meta_parts = {}
                if order ~= 9999 then
                    table.insert(meta_parts, "order: " .. order)
                end
                if icon ~= "" then
                    table.insert(meta_parts, "icon: " .. icon)
                end
                if group ~= "" then
                    table.insert(meta_parts, "group: " .. group)
                end
                if announced == true or announced == "true" then
                    table.insert(meta_parts, "announced")
                end

                local line = "    " .. entry.id
                if title ~= "" then
                    line = line .. " (" .. title .. ")"
                end
                if #meta_parts > 0 then
                    line = line .. " [" .. table.concat(meta_parts, "] [") .. "]"
                end
                table.insert(lines, line)

                if desc ~= "" then
                    table.insert(lines, "      " .. desc)
                end
            end
            table.insert(lines, "")
        end

        if #data.templates > 0 then
            table.insert(lines, "  Templates:")
            table.sort(data.templates, function(a, b)
                return a.id < b.id
            end)
            for _, entry in ipairs(data.templates) do
                local template_name = entry.attributes and entry.attributes["meta.name"] or ""
                local desc = entry.attributes and entry.attributes["meta.description"] or ""
                local set = entry.attributes and entry.attributes["set"] or ""

                local line = "    " .. entry.id
                if template_name ~= "" then
                    line = line .. " (" .. template_name .. ")"
                end
                if set ~= "" then
                    line = line .. " [set: " .. set .. "]"
                end
                table.insert(lines, line)

                if desc ~= "" then
                    table.insert(lines, "      " .. desc)
                end
            end
            table.insert(lines, "")
        end

        if #data.resources > 0 then
            table.insert(lines, "  Resources:")
            table.sort(data.resources, function(a, b)
                local order_a = tonumber(a.attributes and a.attributes["meta.order"]) or 9999
                local order_b = tonumber(b.attributes and b.attributes["meta.order"]) or 9999
                if order_a == order_b then
                    return a.id < b.id
                end
                return order_a < order_b
            end)
            for _, entry in ipairs(data.resources) do
                local resource_name = entry.attributes and entry.attributes["meta.name"] or ""
                local resource_type = entry.attributes and entry.attributes["meta.resource_type"] or ""
                local url = entry.attributes and entry.attributes["meta.url"] or ""
                local order = tonumber(entry.attributes and entry.attributes["meta.order"]) or 9999
                local defer = entry.attributes and entry.attributes["meta.defer"]

                local meta_parts = {}
                if order ~= 9999 then
                    table.insert(meta_parts, "order: " .. order)
                end
                if resource_type ~= "" then
                    table.insert(meta_parts, resource_type)
                end
                if defer == true or defer == "true" then
                    table.insert(meta_parts, "defer")
                end

                local line = "    " .. entry.id
                if resource_name ~= "" then
                    line = line .. " (" .. resource_name .. ")"
                end
                if #meta_parts > 0 then
                    line = line .. " [" .. table.concat(meta_parts, "] [") .. "]"
                end
                table.insert(lines, line)

                if url ~= "" then
                    table.insert(lines, "      URL: " .. url)
                end
            end
            table.insert(lines, "")
        end
    end
    return table.concat(lines, "\n")
end

return { handler = handler }