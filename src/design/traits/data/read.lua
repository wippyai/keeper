local ctx = require("ctx")
local design_reader = require("design_reader")

local function handler(params)
    if not params or not params.data_ids or type(params.data_ids) ~= "table" then
        return nil, "data_ids array required"
    end

    if #params.data_ids == 0 then
        return nil, "data_ids array cannot be empty"
    end

    local workspace_id, err = ctx.get("active_workspace_id")
    if not err and workspace_id and workspace_id ~= "" then
    else
        return nil, "No active workspace (use workspace open first)"
    end

    local reader, err = design_reader.for_workspace(workspace_id)
    if err then
        return nil, err
    end

    local results = {}
    local not_found = {}

    for _, data_id in ipairs(params.data_ids) do
        local data, err = reader:with_data(data_id):one()

        if err then
            table.insert(not_found, data_id)
        elseif data then
            table.insert(results, {
                data_id = data.data_id,
                type = data.type,
                discriminator = data.discriminator,
                status = data.status,
                content = data.content,
                metadata = data.metadata
            })
        else
            table.insert(not_found, data_id)
        end
    end

    local output = {}

    if #results > 0 then
        table.insert(output, "# Retrieved Data Nodes (" .. #results .. ")")
        table.insert(output, "")

        for _, data in ipairs(results) do
            local meta = data.metadata or {}
            local title = meta.title or data.type

            table.insert(output, "## " .. title)
            table.insert(output, "")
            table.insert(output, "**Data ID**: " .. data.data_id)
            table.insert(output, "**Type**: " .. data.type)
            if data.discriminator and data.discriminator ~= "" then
                table.insert(output, "**Discriminator**: " .. data.discriminator)
            end
            if data.status and data.status ~= "" then
                table.insert(output, "**Status**: " .. data.status)
            end
            table.insert(output, "")

            if data.content and data.content ~= "" then
                table.insert(output, data.content)
                table.insert(output, "")
            end
        end
    end

    if #not_found > 0 then
        table.insert(output, "## Not Found")
        table.insert(output, "")
        for _, id in ipairs(not_found) do
            table.insert(output, "- " .. id)
        end
        table.insert(output, "")
    end

    return table.concat(output, "\n")
end

return { handler = handler }