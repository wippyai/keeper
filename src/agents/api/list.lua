local http = require("http")
local security = require("security")
local registry = require("registry")

local start_tokens = require("start_tokens")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    res:set_content_type(http.CONTENT.JSON)

    if not security.actor() then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local entries, err = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.gen1",
    })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = err })
        return
    end

    local agents = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            local model = entry.meta.model or (entry.data and entry.data.model)
            local kind = entry.meta.session_kind or "default"
            local class = entry.meta.class or {}

            local token = start_tokens.pack({
                agent = entry.id or "",
                model = model,
                kind = kind,
            })

            if token then
                table.insert(agents, {
                    id = entry.id,
                    title = entry.meta.title or "",
                    comment = entry.meta.comment or "",
                    icon = entry.meta.icon or "",
                    model = model,
                    class = class,
                    order = entry.meta.order or 500,
                    start_token = token,
                })
            end
        end
    end

    table.sort(agents, function(a, b)
        if a.order == b.order then return a.title < b.title end
        return a.order < b.order
    end)

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        agents = agents,
        count = #agents,
    })
end

return { handler = handler }
