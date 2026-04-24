local security = require("security")
local http_client = require("http_client")
local json = require("json")
local audit = require("audit")
local consts = require("consts")

local TOKEN_STORE_ID = "userspace.user.security:tokens"
local TOKEN_EXPIRATION = "5m"
local DEFAULT_TIMEOUT = 30

local function do_handler(input)
    if not input.method or not input.path then
        return nil, "method and path are required"
    end

    local actor = security.actor()
    local scope = security.scope()
    if not actor or not scope then
        return nil, "No security context available"
    end

    local token_store, err = security.token_store(TOKEN_STORE_ID)
    if err then
        return nil, "Token store failed: " .. tostring(err)
    end

    local token, terr = token_store:create(actor, scope, {
        expiration = TOKEN_EXPIRATION,
        meta = { source = "test_endpoint" },
    })
    token_store:close()

    if terr then
        return nil, "Token creation failed: " .. tostring(terr)
    end

    local url = consts.DEFAULT_HOST_URL .. input.path

    local headers = input.headers or {}
    headers["Authorization"] = "Bearer " .. token

    if input.body and not headers["Content-Type"] then
        headers["Content-Type"] = "application/json"
    end

    local opts = {
        headers = headers,
        timeout = tostring(input.timeout or DEFAULT_TIMEOUT) .. "s",
    }

    if input.body then
        if type(input.body) == "table" then
            opts.body = json.encode(input.body)
        else
            opts.body = tostring(input.body)
        end
    end

    local response, rerr
    local m = string.upper(input.method)
    if m == "GET" then
        response, rerr = http_client.get(url, opts)
    elseif m == "POST" then
        response, rerr = http_client.post(url, opts)
    elseif m == "PUT" then
        response, rerr = http_client.put(url, opts)
    elseif m == "DELETE" then
        response, rerr = http_client.delete(url, opts)
    elseif m == "PATCH" then
        response, rerr = http_client.patch(url, opts)
    else
        return nil, "Unsupported HTTP method: " .. input.method
    end

    if rerr then
        local result = input.method .. " " .. input.path .. " -> ERROR: " .. tostring(rerr)
        return result
    end

    local status = response.status_code
    local body = response.body or ""
    local resp_headers = response.headers or {}

    local content_type = ""
    for k, v in pairs(resp_headers) do
        if string.lower(k) == "content-type" then
            content_type = type(v) == "table" and (v[1] or "") or tostring(v)
            break
        end
    end

    local body_head = body:sub(1, 200)
    local looks_like_html = body_head:find("<!DOCTYPE", 1, true)
        or body_head:find("<html", 1, true)
        or string.find(string.lower(content_type), "text/html", 1, true)

    if looks_like_html then
        local summary = input.method .. " " .. input.path .. " -> SPA fallback (endpoint not registered)"
        local result = summary ..
            "\n\nGot HTML from SPA catch-all route instead of your API handler." ..
            "\nThe endpoint is not live. Either:" ..
            "\n  1. You haven't pushed yet (overlay branches are not served by HTTP — push to main first)" ..
            "\n  2. The router prefix + path is wrong (app:api router uses prefix /api/v1/, so path /foo becomes /api/v1/foo)" ..
            "\n  3. The http.endpoint entry was not created or the func reference is broken" ..
            "\n\nContent-Type: " .. content_type ..
            "\nBody starts: " .. body_head:gsub("\n", " ")
        return nil, result
    end

    local summary = input.method .. " " .. input.path .. " -> " .. tostring(status)
    if input.expected_status and status ~= input.expected_status then
        summary = summary .. " (expected " .. tostring(input.expected_status) .. ")"
    end

    local result_lines = { summary, "Content-Type: " .. content_type }
    if body ~= "" then
        if #body > 500 then
            table.insert(result_lines, "Response body (" .. #body .. " bytes): " .. body:sub(1, 500) .. "...")
        else
            table.insert(result_lines, "Response body: " .. body)
        end
    end

    local result = table.concat(result_lines, "\n")

    if input.expected_status and status ~= input.expected_status then
        return result .. "\n\nSTATUS MISMATCH: got " .. tostring(status) .. ", expected " .. tostring(input.expected_status)
    end

    return result
end

local function handler(input)
    input = input or {}
    return audit.wrap({
        tool          = "test_endpoint",
        discriminator = "test_endpoint." .. (input.method and string.lower(input.method) or "?"),
        target        = input.path,
        params        = { method = input.method, path = input.path, expected_status = input.expected_status },
        summarise = function(result, err)
            if err then return "test_endpoint error" end
            if type(result) == "string" then
                local line = result:match("^[^\n]+")
                return line or "test_endpoint"
            end
            return "test_endpoint"
        end,
    }, function()
        return do_handler(input)
    end)
end

return { handler = handler }
