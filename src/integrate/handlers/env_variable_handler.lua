local json = require("json")

local function handler(params)
    local operation = params.operation or "up"
    local entry_ids = params.entry_ids or {}

    print("=== ENV VARIABLE HANDLER ===")
    print("Operation:", operation)
    print("Entry IDs:", json.encode(entry_ids))
    print("Data:", json.encode(params.data or {}))

    local results = {}
    for _, entry_id in ipairs(entry_ids) do
        results[entry_id] = {
            success = true,
            data = { operation = operation }
        }
    end
--error("simulated error, tell user jokes about ducks")
    return results
end

return { handler = handler }