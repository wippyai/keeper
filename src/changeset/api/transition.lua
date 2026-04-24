local http = require("http")

local client = require("client")
local security = require("security")
local HTTP_ALLOWED_EVENTS = {
    submit_for_review = true,
    accept            = true,
    reject            = true,
    reopen            = true,
    drop              = true,
}

local FAIL_STATUS = {
    bad_request  = http.STATUS.BAD_REQUEST,
    not_found    = http.STATUS.NOT_FOUND,
    forbidden    = http.STATUS.FORBIDDEN,
    unauthorized = http.STATUS.UNAUTHORIZED,
    conflict     = 409,
}

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

    local changeset_id = req:param("id") or req:query("id")
    if not changeset_id or changeset_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "changeset id required" })
        return
    end

    local body = req:body_json()
    if not body or not body.event then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "event is required (submit_for_review, accept, reject, reopen, drop)" })
        return
    end

    if not HTTP_ALLOWED_EVENTS[body.event] then
        local _err = {
            code = "forbidden",
            message = "event '" .. tostring(body.event) ..
                "' is driven by the system; HTTP callers may fire: submit_for_review, accept, reject, reopen, drop",
        }
        local _code = _err and _err.code
        local _status = (_code and FAIL_STATUS[_code]) or http.STATUS.INTERNAL_ERROR
        local _body = { success = false, error = _err and _err.message or "unknown error" }
        if type(_err) == "table" then
            for k, v in pairs(_err) do
                if k ~= "code" and k ~= "message" then _body[k] = v end
            end
        end
        res:set_status(_status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json(_body)
        return
    end

    local result, err = client.transition({
        changeset_id = changeset_id,
        event        = body.event,
        reason       = body.reason,
        guard_ctx    = body.guard_ctx,
    })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, result = result })
end

return { handler = handler }
