local registry = require("registry")

local function as_array(v)
    if type(v) ~= "table" then return {} end
    return v
end

local function has_class(meta, name)
    if not meta or not meta.class then return false end
    if type(meta.class) == "string" then return meta.class == name end
    if type(meta.class) ~= "table" then return false end
    for _, c in ipairs(meta.class) do
        if c == name then return true end
    end
    return false
end

local function score(query_terms, entry)
    if #query_terms == 0 then return 0 end
    local hay = (entry.id or "") .. " "
        .. ((entry.meta and entry.meta.title) or "") .. " "
        .. ((entry.meta and entry.meta.comment) or "") .. " "
        .. ((entry.data and entry.data.prompt) or "")
    hay = hay:lower()
    local s = 0
    for _, t in ipairs(query_terms) do
        if t ~= "" then
            local _, n = hay:gsub(t, "")
            s = s + n
        end
    end
    return s
end

local function tokenize(q)
    local out = {}
    if type(q) ~= "string" then return out end
    for w in q:lower():gmatch("[%w_%-:%.]+") do
        if #w >= 2 then table.insert(out, w) end
    end
    return out
end

local function handler(params)
    params = params or {}
    local filters = params.filters or {}
    local limit = params.limit or 10
    if limit < 1 then limit = 1 end
    if limit > 50 then limit = 50 end

    local agents = registry.find({
        [".kind"]    = "registry.entry",
        ["meta.type"]= "agent.gen1",
    }) or {}

    local terms = tokenize(params.query)
    local results = {}
    for _, e in ipairs(agents) do
        local meta = e.meta or {}
        local data = e.data or {}

        if filters.namespace and not e.id:find("^" .. filters.namespace .. "[:%.]") then
            goto continue
        end
        if filters.class and not has_class(meta, filters.class) then
            goto continue
        end
        if filters.model and (data.model or "") ~= filters.model then
            goto continue
        end

        local tools_count = #as_array(data.tools)
        local traits_count = #as_array(data.traits)
        local delegates_count = #as_array(data.delegates)

        if filters.has_tools ~= nil and (tools_count > 0) ~= filters.has_tools then
            goto continue
        end
        if filters.has_traits ~= nil and (traits_count > 0) ~= filters.has_traits then
            goto continue
        end
        if filters.has_delegates ~= nil and (delegates_count > 0) ~= filters.has_delegates then
            goto continue
        end

        local s = score(terms, e)
        if #terms > 0 and s == 0 then goto continue end

        table.insert(results, {
            id              = e.id,
            title           = meta.title or "",
            comment         = meta.comment or "",
            model           = data.model or "",
            class           = meta.class or {},
            is_public       = has_class(meta, "public"),
            tools_count     = tools_count,
            traits_count    = traits_count,
            delegates_count = delegates_count,
            score           = s,
        })

        ::continue::
    end

    table.sort(results, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return (a.title ~= "" and a.title or a.id) < (b.title ~= "" and b.title or b.id)
    end)

    local trimmed = {}
    for i = 1, math.min(#results, limit) do
        trimmed[i] = results[i]
    end

    return {
        success = true,
        query   = params.query or "",
        filters = filters,
        total_matches = #results,
        results = trimmed,
    }
end

return { handler = handler }
