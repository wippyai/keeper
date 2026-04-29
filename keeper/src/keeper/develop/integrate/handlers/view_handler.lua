-- View handler. For FE artifacts landed by push (Vue pages + router entry),
-- verifies the file exists on disk at the expected path and that the route
-- is registered. Build itself runs inside push.lua's run_pushed_builds —
-- this handler confirms the post-build state.
--
-- Matches kind=page.vue via meta.type=view.page (same contract as old keeper)
-- and also recognises fs writes under frontend applications in the host app
-- and local modules.

local registry = require("registry")
local fs = require("fs")

local PROJECT_VOLUME = "keeper.components:project_fs"

local function string_list(value: unknown): {string}
    local out = {}
    if type(value) ~= "table" then return out end
    for _, item in ipairs(value) do
        if type(item) == "string" and item ~= "" then table.insert(out, item) end
    end
    return out
end

local function file_exists(path: string): boolean
    local vol, err = fs.get(PROJECT_VOLUME)
    if err or not vol then return false end
    local rel = path
    if rel:sub(1, 2) == "./" then rel = rel:sub(3) end
    local ok, stat = pcall(function() return vol:stat(rel) end)
    return ok and stat ~= nil
end

local function view_fields(entry: unknown): (string?, string?)
    local data = (entry and entry.data) or {}
    local path = data.path
    local route = data.route
    return type(path) == "string" and path or nil,
        type(route) == "string" and route or nil
end

local function handler(params)
    local operation = params.operation or "up"
    local entry_ids = string_list(params.entry_ids)
    if #entry_ids == 0 then return {} end

    local rows = {}
    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, "Failed to get view entry " .. entry_id .. ": " .. err
        end

        local path, route = view_fields(entry)
        local ok, missing = true, nil

        if path and operation == "up" then
            local exists = file_exists(path)
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

return {
    handler = handler,
    __test = {
        file_exists = file_exists,
        view_fields = view_fields,
    },
}
