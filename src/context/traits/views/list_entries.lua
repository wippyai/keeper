local ctx = require("ctx")
local state_reader = require("state_reader")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function handler(params)
    local show_views = params.show_views ~= false
    local show_templates = params.show_templates or false
    local show_resources = params.show_resources or false
    local namespace_filter = params.namespace

    local branches = get_active_branch()
    local lines = {}

    -- Fetch views (template.jet with meta.type=view.page)
    if show_views then
        local reader, err = state_reader.for_branch(unpack(branches))
        if err then
            return nil, "Failed to initialize state reader: " .. err
        end

        reader = reader:with_kinds("template.jet")
            :with_attributes({ ["meta.type"] = "view.page" })
            :include_attributes()

        if namespace_filter and namespace_filter ~= "" then
            reader = reader:with_namespaces(namespace_filter)
        end

        local entries, err = reader:all()
        if err then
            return nil, "Failed to fetch views: " .. err
        end

        if #entries > 0 then
            table.sort(entries, function(a, b) return a.id < b.id end)

            table.insert(lines, "VIEWS (" .. #entries .. "):")
            table.insert(lines, "")

            for _, entry in ipairs(entries) do
                local title = entry.attributes and entry.attributes["meta.title"] or ""
                local description = entry.attributes and entry.attributes["meta.comment"] or
                                  entry.attributes and entry.attributes["meta.description"] or ""
                local order = entry.attributes and tonumber(entry.attributes["meta.order"])

                table.insert(lines, "- " .. entry.id)
                if title ~= "" then
                    table.insert(lines, "  Title: " .. title)
                end
                if description ~= "" then
                    table.insert(lines, "  " .. description)
                end
                if order and order ~= 9999 then
                    table.insert(lines, "  Order: " .. order)
                end
                table.insert(lines, "")
            end
        end
    end

    -- Fetch templates (template.jet without meta.type=view.page)
    if show_templates then
        local reader, err = state_reader.for_branch(unpack(branches))
        if err then
            return nil, "Failed to initialize state reader: " .. err
        end

        reader = reader:with_kinds("template.jet")
            :include_attributes()

        if namespace_filter and namespace_filter ~= "" then
            reader = reader:with_namespaces(namespace_filter)
        end

        local entries, err = reader:all()
        if err then
            return nil, "Failed to fetch templates: " .. err
        end

        local templates = {}
        for _, entry in ipairs(entries) do
            local is_view_page = entry.attributes and entry.attributes["meta.type"] == "view.page"
            if not is_view_page then
                table.insert(templates, entry)
            end
        end

        if #templates > 0 then
            table.sort(templates, function(a, b) return a.id < b.id end)

            table.insert(lines, "TEMPLATES (" .. #templates .. "):")
            table.insert(lines, "")

            for _, entry in ipairs(templates) do
                local name = entry.attributes and entry.attributes["meta.name"] or ""
                local description = entry.attributes and entry.attributes["meta.description"] or
                                  entry.attributes and entry.attributes["meta.comment"] or ""

                table.insert(lines, "- " .. entry.id)
                if name ~= "" then
                    table.insert(lines, "  Name: " .. name)
                end
                if description ~= "" then
                    table.insert(lines, "  " .. description)
                end
                table.insert(lines, "")
            end
        end
    end

    -- Fetch resources (registry.entry with meta.type=view.resource)
    if show_resources then
        local reader, err = state_reader.for_branch(unpack(branches))
        if err then
            return nil, "Failed to initialize state reader: " .. err
        end

        reader = reader:with_kinds("registry.entry")
            :with_attributes({ ["meta.type"] = "view.resource" })
            :include_attributes()

        if namespace_filter and namespace_filter ~= "" then
            reader = reader:with_namespaces(namespace_filter)
        end

        local entries, err = reader:all()
        if err then
            return nil, "Failed to fetch resources: " .. err
        end

        if #entries > 0 then
            table.sort(entries, function(a, b) return a.id < b.id end)

            table.insert(lines, "RESOURCES (" .. #entries .. "):")
            table.insert(lines, "")

            for _, entry in ipairs(entries) do
                local name = entry.attributes and entry.attributes["meta.name"] or ""
                local resource_type = entry.attributes and entry.attributes["meta.resource_type"] or ""
                local order = entry.attributes and tonumber(entry.attributes["meta.order"])

                table.insert(lines, "- " .. entry.id)
                if name ~= "" then
                    table.insert(lines, "  Name: " .. name)
                end
                if resource_type ~= "" then
                    table.insert(lines, "  Type: " .. resource_type)
                end
                if order and order ~= 9999 then
                    table.insert(lines, "  Order: " .. order)
                end
                table.insert(lines, "")
            end
        end
    end

    if #lines == 0 then
        return "No entries found matching criteria."
    end

    return table.concat(lines, "\n")
end

return { handler = handler }