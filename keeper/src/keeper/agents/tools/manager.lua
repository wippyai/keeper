local registry = require("registry")

local M = {}

local function has_class(entry, class_name)
    local class = entry and entry.meta and entry.meta.class
    if type(class) ~= "table" then return false end
    for _, value in ipairs(class) do
        if value == class_name then return true end
    end
    return false
end

local function truthy(value)
    if value == true then return true end
    if value == false or value == nil then return false end
    value = tostring(value):lower()
    return value == "1" or value == "true" or value == "yes"
end

local function short_agent(entry, opts)
    opts = opts or {}
    local meta = entry.meta or {}
    local data = entry.data or {}
    local out = {
        id = entry.id,
        title = meta.title or "",
        comment = meta.comment or "",
        icon = meta.icon or "",
        class = meta.class or {},
        tags = meta.tags or {},
        public = has_class(entry, "public"),
        model = meta.model or data.model,
        order = meta.order or 500,
    }
    if opts.include_runtime then
        out.temperature = data.temperature
        out.max_tokens = data.max_tokens
        out.session_kind = meta.session_kind or "default"
    end
    if opts.include_links then
        out.tools = data.tools or {}
        out.traits = data.traits or {}
        out.delegates = data.delegates or {}
        out.context_chain = meta.context_chain or {}
    end
    if opts.include_prompt then
        out.prompt = data.prompt or ""
    end
    return out
end

local function list_agents(args)
    args = args or {}
    local entries, err = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.gen1",
    })
    if err then return nil, err end

    local out = {}
    for _, entry in ipairs(entries or {}) do
        if entry.meta then
            if truthy(args.public_only) and not has_class(entry, "public") then goto continue end
            if args.class and args.class ~= "" and not has_class(entry, args.class) then goto continue end
            if args.namespace and args.namespace ~= "" then
                local ns = entry.id:match("^([^:]+):") or ""
                if ns ~= args.namespace and ns:sub(1, #args.namespace + 1) ~= args.namespace .. "." then
                    goto continue
                end
            end
            table.insert(out, short_agent(entry, {
                include_runtime = truthy(args.include_runtime),
                include_links = truthy(args.include_links),
                include_prompt = false,
            }))
        end
        ::continue::
    end

    table.sort(out, function(a, b)
        if a.order == b.order then return tostring(a.title) < tostring(b.title) end
        return (a.order or 500) < (b.order or 500)
    end)

    local total = #out
    local limit = tonumber(args.limit) or #out
    if limit < #out then
        local trimmed = {}
        for i = 1, limit do trimmed[i] = out[i] end
        out = trimmed
    end
    return { agents = out, count = #out, total = total }
end

local function get_agent(args)
    if not args or type(args.id) ~= "string" or args.id == "" then
        return nil, "id required"
    end
    local entry, err = registry.get(args.id)
    if not entry then return nil, err or ("agent not found: " .. args.id) end
    if not entry.meta or entry.meta.type ~= "agent.gen1" then
        return nil, "entry is not an agent: " .. args.id
    end
    if truthy(args.public_only) and not has_class(entry, "public") then
        return nil, "agent is not public: " .. args.id
    end
    return {
        agent = short_agent(entry, {
            include_runtime = true,
            include_links = true,
            include_prompt = truthy(args.include_prompt),
        }),
    }
end

function M.handler(args)
    args = args or {}
    local action = args.action or "list"
    if action == "list" then return list_agents(args) end
    if action == "get" then return get_agent(args) end
    return nil, "unsupported action: " .. tostring(action)
end

M._has_class = has_class
M._list_agents = list_agents

return M
