local audit = require("audit")

local kb_repo = require("kb_repo")
local kb_helpers = require("kb_helpers")
local summarize = require("summarize")

local resolve_kb_id = kb_helpers.resolve_kb_id

local function do_handler(params)
    local action = params.action or "search"
    local result, err

    if action == "list_kbs" then
        local kbs, kb_err = kb_repo.list_kbs()
        if kb_err then return nil, kb_err end
        if not kbs or #kbs == 0 then return "No knowledge bases found." end
        local lines = { "Knowledge bases:\n" }
        for _, kb in ipairs(kbs) do
            table.insert(lines, "- " .. kb.name .. " (" .. (kb.node_count or 0) .. " nodes)")
        end
        result = table.concat(lines, "\n")

    elseif action == "list" then
        local kb_id, kb_err = resolve_kb_id(params)
        if kb_err then return nil, kb_err end
        local nodes, list_err = kb_repo.list({
            kb_id = kb_id, node_type = params.node_type,
            scope_namespace = params.scope_namespace, scope_kind = params.scope_kind,
            limit = params.limit or 20,
        })
        if list_err then return nil, list_err end
        if not nodes or #nodes == 0 then return "No knowledge nodes found." end
        local lines = { "Knowledge nodes (" .. #nodes .. "):\n" }
        for _, node in ipairs(nodes) do
            local line = "- [" .. node.node_type .. "] " .. node.title .. " (id:" .. node.id:sub(1, 8) .. ")"
            if node.summary and node.summary ~= "" then line = line .. " -- " .. node.summary end
            table.insert(lines, line)
        end
        result = table.concat(lines, "\n")

    elseif action == "search" then
        if not params.query or params.query == "" then return nil, "query is required for search" end
        local kb_id, kb_err = resolve_kb_id(params)
        if kb_err then return nil, kb_err end
        local nodes, search_err = kb_repo.search_text(params.query, { kb_id = kb_id, limit = params.limit or 20 })
        if search_err then return nil, search_err end
        if not nodes or #nodes == 0 then return "No results for: " .. params.query end
        local lines = { "Search results for '" .. params.query .. "' (" .. #nodes .. "):\n" }
        for _, node in ipairs(nodes) do
            table.insert(lines, "## " .. node.title .. " [" .. node.node_type .. "] id:" .. node.id:sub(1, 8))
            table.insert(lines, node.content)
            if node.refs and #node.refs > 0 then
                table.insert(lines, "refs: " .. table.concat(node.refs, ", "))
            end
            table.insert(lines, "")
        end
        result = table.concat(lines, "\n")

    elseif action == "get" then
        if not params.node_id then return nil, "node_id is required for get" end
        local node = kb_repo.get(params.node_id)
        if not node then return nil, "Node not found: " .. params.node_id end
        local lines = {
            "## " .. node.title,
            "type: " .. node.node_type .. " | source: " .. node.source .. " | confidence: " .. node.confidence,
            "", node.content,
        }
        if node.refs and #node.refs > 0 then
            table.insert(lines, "\nrefs: " .. table.concat(node.refs, ", "))
        end
        result = table.concat(lines, "\n")

    else
        return nil, "Unknown action: " .. action
    end

    local summarizable = { search = true, list = true, get = true }
    if result and summarizable[action] and params.full ~= true and type(result) == "string" then
        local goal = params.goal
        if not goal or goal == "" then
            if action == "search" and params.query then
                goal = "Information relevant to: " .. params.query
            elseif action == "list" then
                goal = "Which knowledge nodes exist and what they cover"
            elseif action == "get" and params.node_id then
                goal = "Contents of knowledge node " .. params.node_id
            end
        end
        local compressed, _sum_err, was_summarized = summarize.summarize(result, goal, {
            tool = "search_knowledge:" .. action,
        })
        if was_summarized then
            result = compressed
        end
    end

    return result
end

local function handler(params)
    params = params or {}
    local action = params.action or "search"
    return audit.wrap({
        tool          = "kb_read",
        discriminator = "kb_read." .. action,
        target        = params.query or params.node_id or params.kb,
        params        = { action = action, query = params.query, kb = params.kb, node_id = params.node_id, node_type = params.node_type },
        summarise = function(result, err)
            if err then return "kb_read failed: " .. tostring(err) end
            if type(result) == "string" then
                local n = result:match("%((%d+)%)")
                if n then return action .. ": " .. n .. " results" end
            end
            return "kb " .. action
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
