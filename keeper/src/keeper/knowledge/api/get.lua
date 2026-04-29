local http = require("http")
local kb_service = require("kb_service")
local security = require("security")

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

    local node, err = kb_service.get_node(req:param("id"))
    if err then
        local _err = err
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

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, node = node })
end

return { handler = handler }
