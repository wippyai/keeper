local json = require("json")
local renderer = require("renderer")

local function handler(params)
    local operation = params.operation or "up"
    local entry_ids = params.entry_ids or {}

    print("=== VIEW HANDLER ===")
    print("Operation:", operation)
    print("Entry IDs:", json.encode(entry_ids))

    if operation == "down" then
        local results = {}
        for _, entry_id in ipairs(entry_ids) do
            results[entry_id] = {
                success = true,
                data = { operation = operation, status = "skipped" }
            }
        end
        return results
    end

    local results = {}
    local failed_view = nil
    local error_message = nil

    for _, entry_id in ipairs(entry_ids) do
        print("Rendering view:", entry_id)

        local content, err = renderer.render(entry_id, {}, {})

        if err then
            print("ERROR:", err)
            results[entry_id] = {
                success = false,
                error = "Render failed: " .. tostring(err),
                data = { operation = operation }
            }

            if not failed_view then
                failed_view = entry_id
                error_message = "Render failed: " .. tostring(err)
            end
        else
            print("SUCCESS: Rendered", #content, "bytes")
            results[entry_id] = {
                success = true,
                data = {
                    operation = operation,
                    status = "validated",
                    size = #content
                }
            }
        end
    end

    if failed_view then
        return nil, error_message .. " (failed at: " .. failed_view .. ")"
    end

    return results
end

return { handler = handler }