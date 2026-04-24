local http_client = require("http_client")
local audit = require("audit")

local DOCS_BASE = "https://wippy.ai/llm"

local function url_encode(str)
    return str:gsub("([^%w%-%.%_%~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "+")
end

local function do_handler(params)
    local action = params.action
    if not action then return nil, "action is required" end

    if action == "search" then
        if not params.query or params.query == "" then return nil, "query is required" end

        local response, err = http_client.get(DOCS_BASE .. "/search?q=" .. url_encode(params.query))
        if err then return nil, "Docs search failed: " .. err end
        if response.status_code ~= 200 then return nil, "Docs search returned " .. response.status_code end

        local body = response.body
        if not body or body == "" then return "No results found." end

        -- Return raw text, agent will parse
        if #body > 4000 then body = body:sub(1, 4000) .. "\n...(truncated)" end
        return body

    elseif action == "fetch" then
        if not params.path or params.path == "" then return nil, "path is required" end

        local url = DOCS_BASE .. "/path/en/" .. params.path
        local response, err = http_client.get(url)
        if err then return nil, "Docs fetch failed: " .. err end
        if response.status_code ~= 200 then return nil, "Docs fetch returned " .. response.status_code end

        local body = response.body
        if not body or body == "" then return "Page not found: " .. params.path end

        if #body > 6000 then body = body:sub(1, 6000) .. "\n...(truncated)" end
        return body

    elseif action == "toc" then
        local response, err = http_client.get(DOCS_BASE .. "/toc")
        if err then return nil, "Docs TOC failed: " .. err end
        if response.status_code ~= 200 then return nil, "Docs TOC returned " .. response.status_code end

        local body = response.body
        if not body or body == "" then return "TOC unavailable." end

        if #body > 4000 then body = body:sub(1, 4000) .. "\n...(truncated)" end
        return body

    else
        return nil, "Unknown action: " .. action .. ". Use: search, fetch, toc"
    end
end

local function handler(params)
    params = params or {}
    local action = params.action or "?"
    return audit.wrap({
        tool          = "fetch_docs",
        discriminator = "fetch_docs." .. action,
        target        = params.query or params.path,
        params        = { action = action, query = params.query, path = params.path },
        summarise = function(result, err)
            if err then return "fetch_docs failed: " .. tostring(err) end
            if type(result) == "string" then return "fetched " .. #result .. " chars" end
            return "fetch_docs " .. action
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
