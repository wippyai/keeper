local function handler(params)
    local operation = params.operation or "up"
    local entry_ids = params.entry_ids or {}

    local results = {}
    for _, entry_id in ipairs(entry_ids) do
        table.insert(results, {
            id = entry_id,
            success = true,
            data = { operation = operation }
        })
    end
    return results
end

return { handler = handler }
