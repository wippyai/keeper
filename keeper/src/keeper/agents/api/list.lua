local http = require("http")
local security = require("security")
local registry = require("registry")

local start_tokens = require("start_tokens")

local function has_class(entry, class_name)
    local class = entry and entry.meta and entry.meta.class
    if type(class) ~= "table" then return false end
    for _, value in ipairs(class) do
        if value == class_name then return true end
    end
    return false
end

local function truthy(value)
    value = tostring(value or ""):lower()
    return value == "1" or value == "true" or value == "yes"
end

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

    local public_only = truthy(req:query("public_only"))
    local class_filter = req:query("class")
    local agents = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            if public_only and not has_class(entry, "public") then goto continue end
            if class_filter and class_filter ~= "" and not has_class(entry, class_filter) then goto continue end

            local model = entry.meta.model or (entry.data and entry.data.model)
            local kind = entry.meta.session_kind or "default"
            local class = entry.meta.class or {}

            local token = start_tokens.pack({
                agent = entry.id or "",
                model = model,
                kind = kind,
            })

            if token then
                local data = entry.data or {}
                local traits = data.traits or {}
                local tools = data.tools or {}
                local delegates = data.delegates or {}
                local memory = data.memory or {}
                table.insert(agents, {
                    id = entry.id,
                    title = entry.meta.title or "",
                    comment = entry.meta.comment or "",
                    icon = entry.meta.icon or "",
                    model = model,
                    class = class,
                    public = has_class(entry, "public"),
                    order = entry.meta.order or 500,
                    start_token = token,
                    max_tokens = data.max_tokens,
                    temperature = data.temperature,
                    thinking_effort = data.thinking_effort,
                    traits_count = #traits,
                    tools_count = #tools,
                    delegates_count = #delegates,
                    memory_contract = memory.contract,
                    has_prompt = (data.prompt or data.system_prompt) ~= nil,
                    prompt_preview = (function()
                        local p = data.prompt or data.system_prompt or ""
                        if type(p) ~= "string" then return "" end
                        return p:sub(1, 240)
                    end)(),
                })
            end
        end
        ::continue::
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
