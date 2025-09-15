local registry = require("registry")

local function handler(params)
    local response = {
        success = false,
        docs = {},
        found_count = 0,
        not_found = {},
        error = nil
    }

    -- Validate input
    if not params.ids or type(params.ids) ~= "table" or #params.ids == 0 then
        response.error = "Missing or invalid required parameter: ids (must be non-empty array of full registry IDs)"
        return response
    end

    -- Get registry snapshot
    local snapshot, err = registry.snapshot()
    if not snapshot then
        response.error = "Failed to get registry snapshot: " .. (err or "unknown error")
        return response
    end

    -- Fetch documentation for each ID
    local found_docs = {}
    local not_found = {}

    for _, doc_id in ipairs(params.ids) do
        if type(doc_id) ~= "string" or doc_id == "" then
            table.insert(not_found, "(invalid ID type: " .. type(doc_id) .. ")")
            goto continue
        end

        -- Get the documentation entry
        local entry, err = snapshot:get(doc_id)
        if not entry then
            table.insert(not_found, doc_id)
            goto continue
        end

        -- Verify it's a module spec
        if not entry.meta or entry.meta.type ~= "module.spec" then
            table.insert(not_found, doc_id .. " (not a module specification)")
            goto continue
        end

        -- Extract module name from full ID
        local module_name = doc_id:match("^wippy%.docs:(.+)$")
        if not module_name then
            module_name = doc_id
        end

        -- Build documentation object
        local documentation = {
            id = entry.id,
            module = module_name,
            title = entry.meta.title or ("Wippy " .. module_name:gsub("^%l", string.upper) .. " Module"),
            comment = entry.meta.comment or "No description available",
            tags = entry.meta.tags or {},
            content = nil
        }

        -- Get the actual documentation content
        if entry.data and entry.data.source then
            documentation.content = entry.data.source
        elseif entry.source then
            documentation.content = entry.source
        else
            documentation.content = "No documentation content available"
        end

        table.insert(found_docs, documentation)

        ::continue::
    end

    -- Sort found docs by module name
    table.sort(found_docs, function(a, b)
        return a.module < b.module
    end)

    response.success = true
    response.docs = found_docs
    response.found_count = #found_docs
    response.not_found = not_found
    response.requested_count = #params.ids

    return response
end

return { handler = handler }