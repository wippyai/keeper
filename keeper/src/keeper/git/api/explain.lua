-- POST /api/v1/keeper/git/clusters/{id}/recommendations/{rec_id}/explain
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

    local cluster_id = req:param("id")
    local rec_id = req:param("rec_id")
    if not cluster_id or cluster_id == "" or not rec_id or rec_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "cluster id and recommendation id required" })
        return
    end

    local body = req:body_json() or {}
    local result, err = git_client.explain_recommendation(cluster_id, rec_id, {
        force      = body.force and true or false,
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
        cluster_id = result.cluster_id,
        recommendation_id = result.recommendation_id,
        text = result.text, model = result.model, cached = result.cached,
    })
end

return { handler = handler }
