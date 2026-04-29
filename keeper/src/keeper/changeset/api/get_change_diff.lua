local http = require("http")

local diff_render = require("diff_render")
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

    local result, err = diff_render.render({
        changeset_id = req:param("id") or req:query("id"),
        target       = req:query("target"),
        category     = req:query("category"),
        part         = req:query("part"),
    })
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
    res:write_json({ success = true, target   = result.target,
        category = result.category,
        part     = result.part,
        language = result.language,
        baseline = result.baseline,
        current  = result.current, })
end

return { handler = handler }
