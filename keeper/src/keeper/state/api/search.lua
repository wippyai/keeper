local http = require("http")
local state_reader = require("state_reader")
local security = require("security")
local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local query = req:query("q")
    if not query or query == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "q parameter required" })
        return
    end

    local ns = req:query("namespace")
    local kind = req:query("kind")
    local limit = math.floor(tonumber(req:query("limit")) or 50)

    local reader, reader_err = state_reader.for_branch("main")
    if not reader then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = reader_err or "Reader unavailable" })
        return
    end

    reader = reader:with_search(query):limit(limit)
    if ns and ns ~= "" then reader = reader:with_namespaces(ns) end
    if kind and kind ~= "" then reader = reader:with_kinds(kind) end

    local entries, err = reader:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Query failed: " .. tostring(err) })
        return
    end

    local results = {}
    for _, entry in ipairs(entries or {}) do
        table.insert(results, {
            id = entry.id,
            kind = entry.kind,
            snippet = entry.snippet or "",
        })
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, results = results,
        count = #results,
        query = query, })
end

return { handler = handler }
