-- POST /api/v1/keeper/git/clusters/{id}/suggest-split
-- Body: { mode: "ai" | "by_prefix" | "by_kind", depth?, model? }
-- Returns: { groups: [{title, plain_summary, change_ids}] }
local http = require("http")
local security = require("security")
local git_client = require("git_client")

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

    local cid = req:param("id")
    if not cid or cid == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "cluster id required" })
        return
    end

    local body = req:body_json() or {}
    local result, err = git_client.suggest_split(cid, {
        mode       = body.mode or "ai",
        depth      = tonumber(body.depth),
        model      = body.model,
        request_id = body.request_id,
    })
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
        mode    = result.mode,
        groups  = result.groups,
        model   = result.model,
        duration_ms = result.duration_ms,
    })
end

return { handler = handler }
