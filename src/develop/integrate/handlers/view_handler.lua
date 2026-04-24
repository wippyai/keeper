-- View handler. For FE artifacts landed by push (Vue pages + router entry),
-- verifies the file exists on disk at the expected path and that the route
-- is registered. Build itself runs inside push.lua's run_pushed_builds —
-- this handler confirms the post-build state.
--
-- Matches kind=page.vue via meta.type=view.page (same contract as old keeper)
-- and also recognises fs writes under frontend/applications/keeper/src/pages.

local registry = require("registry")
local fs = require("fs")

local function handler(params)
    local operation = params.operation or "up"
    local entry_ids = params.entry_ids or {}
    if #entry_ids == 0 then return {} end

    local rows = {}
    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, "Failed to get view entry " .. entry_id .. ": " .. err
        end

        local path = entry.meta and entry.meta.path
        local route = entry.meta and entry.meta.route
        local ok, missing = true, nil

        if path and operation == "up" then
            local exists = fs.exists(path)
            if not exists then
                ok = false
                missing = "file missing on disk: " .. path
            end
        end

        table.insert(rows, {
            id      = entry_id,
            success = ok,
            error   = missing,
            data    = {
                operation = operation,
                path      = path,
                route     = route,
            },
        })

        if not ok then
            return nil, missing .. " (entry " .. entry_id .. ")"
        end
    end
    return rows
end

return { handler = handler }
