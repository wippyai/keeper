-- POST /api/v1/keeper/git/clusters/{id}/split
-- Body: { groups: [{title, plain_summary?, change_ids: []}] }
-- Returns: { snapshot, split_result }
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
    local groups = body.groups
    if type(groups) ~= "table" or #groups == 0 then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "groups[] required" })
        return
    end

    local snapshot, err = git_client.split_cluster(cid, groups)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, snapshot = snapshot })
end

return { handler = handler }
