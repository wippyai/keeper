local M = {}

function M.current_actor_id(security)
    local actor = security.actor()
    if not actor or type(actor.id) ~= "function" then
        return nil, "security actor is required"
    end
    return actor:id(), nil
end

function M.service_error(e, fallback)
    fallback = fallback or "Hub operation failed"
    local msg
    local code
    if e ~= nil then
        local ok_msg, method_or_err = pcall(function() return e.message end)
        if ok_msg and type(method_or_err) == "function" then
            local called, result = pcall(method_or_err, e)
            if called then msg = result end
        end
        local ok_details, details_method = pcall(function() return e.details end)
        if ok_details and type(details_method) == "function" then
            local called, details = pcall(details_method, e)
            if called and type(details) == "table" then code = details.code end
        end
        local ok_kind, kind_method = pcall(function() return e.kind end)
        if ok_kind and type(kind_method) == "function" then
            local called, kind = pcall(kind_method, e)
            if called and not code then code = kind end
        end
    end
    if type(e) == "table" then
        msg = msg or e.message or e.error
        code = code or e.code
    end
    msg = tostring(msg or e or fallback)
    if code then return tostring(code) .. ": " .. msg end
    return msg
end

function M.copy_args(input)
    local out = {}
    for k, v in pairs(input or {}) do
        if k ~= "action" then out[k] = v end
    end
    return out
end

return M
