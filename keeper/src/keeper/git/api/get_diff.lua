-- GET /api/v1/keeper/git/diff?path=<path>
-- Returns unified-diff text for one file vs the configured diff_base.
local http = require("http")
local security = require("security")
local funcs = require("funcs")

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

    local f = funcs.new()
    local result, err = f:call("keeper.git.flows:file_diff", { path = path, diff_base = req:query("base") })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        path = result.path,
        diff_text = result.diff_text or "",
        hunks = result.hunks or {},
        exit_code = result.exit_code,
    })
end

return { handler = handler }
