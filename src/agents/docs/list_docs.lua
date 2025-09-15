local registry = require("registry")

local function handler(params)
    local response = {
        success = false,
        docs = {},
        count = 0,
        error = nil
    }

    -- Get registry snapshot
    local snapshot, err = registry.snapshot()
    if not snapshot then
        response.error = "Failed to get registry snapshot: " .. (err or "unknown error")
        return response
    end

    -- Get all entries and filter for documentation
    local entries, err = snapshot:entries({ limit = 1000 })
    if err then
        response.error = "Failed to get documentation entries: " .. err
        return response
    end

    -- Filter and process entries
    local docs = {}
    local filter = params.filter and params.filter:lower()
    local include_summary = params.include_summary or false

    for _, entry in ipairs(entries) do
        -- Skip non-wippy.docs namespace entries
        local ns = entry.id:match("^([^:]+):")
        if ns ~= "wippy.docs" then
            goto continue
        end

        -- Skip non-module.spec entries
        if not entry.meta or entry.meta.type ~= "module.spec" then
            goto continue
        end

        -- Extract module name from full ID
        local module_name = entry.id:match("^wippy%.docs:(.+)$")
        if not module_name then
            goto continue
        end

        -- Apply filter if provided
        if filter then
            local matches = false

            -- Check full ID
            if entry.id:lower():find(filter, 1, true) then
                matches = true
            end

            -- Check module name
            if not matches and module_name:lower():find(filter, 1, true) then
                matches = true
            end

            -- Check tags
            if not matches and entry.meta.tags then
                for _, tag in ipairs(entry.meta.tags) do
                    if tag:lower():find(filter, 1, true) then
                        matches = true
                        break
                    end
                end
            end

            -- Check comment
            if not matches and entry.meta.comment then
                if entry.meta.comment:lower():find(filter, 1, true) then
                    matches = true
                end
            end

            if not matches then
                goto continue
            end
        end

        -- Build doc entry with full ID
        local doc_entry = {
            id = entry.id,
            module = module_name,
            tags = entry.meta.tags or {}
        }

        if include_summary then
            doc_entry.summary = entry.meta.comment or "No description available"
        end

        table.insert(docs, doc_entry)

        ::continue::
    end

    -- Sort by module name
    table.sort(docs, function(a, b)
        return a.module < b.module
    end)

    response.success = true
    response.docs = docs
    response.count = #docs
    response.filter_applied = filter

    return response
end

return { handler = handler }