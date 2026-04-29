local http = require("http")
local embedder = require("embedder")
local security = require("security")

type EmbedArgs = {
    node_id: string?,
    model: string?,
}

type Embedder = {
    embed: (EmbedArgs) -> (unknown, string?),
}

local FAIL_STATUS: {[string]: number} = {
    bad_request  = http.STATUS.BAD_REQUEST,
    not_found    = http.STATUS.NOT_FOUND,
    forbidden    = http.STATUS.FORBIDDEN,
    unauthorized = http.STATUS.UNAUTHORIZED,
    conflict     = 409,
}

local embedder_mod = embedder :: Embedder

local function normalize_body(raw_body: unknown): EmbedArgs
    if type(raw_body) ~= "table" then return {} end
    local raw = raw_body :: {[string]: unknown}
    local node_id = raw.node_id
    local model = raw.model
    return {
        node_id = type(node_id) == "string" and node_id or nil,
        model = type(model) == "string" and model or nil,
    }
end

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

    local body = normalize_body(req:body_json())

    local result, err = embedder_mod.embed(body)
    if err then
        local _err = { code = "internal", message = err }
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
    res:write_json({ success = true, result = result })
end

return { handler = handler }
