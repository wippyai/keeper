local function handler(context)
    local request_id = context.params.request_id
    local changeset_count = context.params.changeset_count or 0
    local changeset = context.params.changeset or {}

    return {
        request_id = request_id or "unknown",
        options = context.params.options or {},
        changeset_count = changeset_count,
        changeset = changeset
    }
end

return {
    handler = handler
}