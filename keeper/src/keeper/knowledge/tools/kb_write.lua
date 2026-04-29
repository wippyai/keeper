local kb_repo = require("kb_repo")
local kb_consts = require("kb_consts")
local embedder = require("embedder")
local kb_helpers = require("kb_helpers")
local audit = require("audit")

local resolve_kb_id = kb_helpers.resolve_kb_id

type EmbedArgs = {
    node_id: string?,
    model: string?,
}

type Embedder = {
    embed: (EmbedArgs) -> (unknown, string?),
}

local embedder_mod = embedder :: Embedder

local function do_handler(params)
    local action = params.action
    if not action then return nil, "action is required" end

    if action == "create" then
        if not params.title or params.title == "" then return nil, "title is required" end
        if not params.node_type then return nil, "node_type is required" end

        local kb_id, kb_err = resolve_kb_id(params)
        if kb_err then return nil, kb_err end

        local lookup_kb_id = kb_id or kb_consts.DEFAULT_KB_ID
        local existing, find_err = kb_repo.find_by_title(lookup_kb_id, params.title)
        if find_err then return nil, find_err end
        if existing then
            return nil, "Already exists: [" .. existing.node_type .. "] " ..
                existing.title .. " (id:" .. existing.id:sub(1, 8) ..
                ") — use action=update with node_id=" .. existing.id ..
                " to modify, or search_knowledge to review before creating a variant"
        end

        local node, err = kb_repo.create({
            kb_id = kb_id,
            node_type = params.node_type,
            title = params.title,
            summary = params.summary or "",
            content = params.content or "",
            source = "agent",
            confidence = params.confidence or 0.8,
            refs = params.refs,
            workspace_id = params.workspace_id,
            scope_namespace = params.scope_namespace,
            scope_kind = params.scope_kind,
            scope_meta_type = params.scope_meta_type,
        })
        if err or not node then return nil, err end
        pcall(function() embedder_mod.embed({ node_id = node.id }) end)
        return "Created [" .. node.node_type .. "] " .. node.title .. " (id:" .. node.id:sub(1, 8) .. ")"

    elseif action == "update" then
        if not params.node_id then return nil, "node_id is required" end
        local updates = {}
        if params.title then updates.title = params.title end
        if params.content then updates.content = params.content end
        if params.node_type then updates.node_type = params.node_type end
        if params.confidence then updates.confidence = params.confidence end
        if params.refs then updates.refs = params.refs end

        local result, err = kb_repo.update(params.node_id, updates)
        if err then return nil, err end
        return "Updated node " .. params.node_id:sub(1, 8)

    elseif action == "delete" then
        if not params.node_id then return nil, "node_id is required" end
        local result, err = kb_repo.delete(params.node_id)
        if err then return nil, err end
        return "Deleted node " .. params.node_id:sub(1, 8)

    else
        return nil, "Unknown action: " .. action
    end
end

local function handler(params)
    params = params or {}
    local action = params.action or "?"
    return audit.wrap({
        tool          = "kb_write",
        discriminator = "kb_write." .. action,
        target        = params.title or params.node_id,
        params        = { action = action, title = params.title, node_id = params.node_id, node_type = params.node_type },
        summarise = function(result, err)
            if err then return "kb_write failed: " .. tostring(err) end
            if type(result) == "string" then return result end
            return "kb_write " .. action
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
