local http = require("http")

local scanner = require("scanner")
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

    local path = req:query("path")
    if not path or path == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "path query param required" })
        return
    end

    local content, err = scanner.read_doc(path)
    if not content then
        res:set_status(http.STATUS.NOT_FOUND)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err or "not found" })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, path = path, content = content })
end

return { handler = handler }
