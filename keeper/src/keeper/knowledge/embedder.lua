local sql = require("sql")
local json = require("json")

local kb_repo = require("kb_repo")
local consts = require("kb_consts")
local llm = require("llm")

type EmbedArgs = {
    node_id: string?,
    model: string?,
}

local function normalize_args(args: unknown): EmbedArgs
    if type(args) ~= "table" then return {} end
    local raw = args :: {[string]: unknown}
    local node_id = raw.node_id
    local model = raw.model
    return {
        node_id = type(node_id) == "string" and node_id or nil,
        model = type(model) == "string" and model or nil,
    }
end

local function get_db()
    local db = sql.get(consts.DB_ID)
    if not db then error("database " .. consts.DB_ID .. " is not available") end
    return db
end

local function embed_node(id, params)
    params = params or {}
    local model = params.model or consts.EMBED.MODEL
    local node = kb_repo.get(id)
    if not node then return nil, "Node not found" end

    local text = node.title .. "\n\n" .. node.content
    local embed_result, err = llm.embed(text, { model = model, dimensions = consts.EMBED.DIMENSIONS })
    if err or not embed_result then return nil, "Embedding failed: " .. (err or "no result") end

    local result = embed_result.result
    if not result then return nil, "Empty embedding result" end
    local embedding = type(result) == "table" and result[1] or result
    if not embedding then return nil, "No embedding vector" end

    local db = get_db()
    db:execute("DELETE FROM keeper_kb_embeddings WHERE node_id = ?", { id })
    local _, insert_err = db:execute([[
        INSERT INTO keeper_kb_embeddings (node_id, embedding, title, content_preview)
        VALUES (?, ?, ?, ?)
    ]], { id, json.encode(embedding), node.title, node.content:sub(1, 200) })
    if insert_err then return nil, "Failed to store embedding: " .. insert_err end

    db:execute("UPDATE keeper_kb_nodes SET embedded = 1 WHERE id = ?", { id })

    pcall(function()
        process.send(consts.CENTRAL, consts.TOPIC, { event = consts.EVENTS.NODE_EMBEDDED, data = { id = id, title = node.title, model = model } })
    end)

    return { id = id, embedded = true, model = model }
end

local function embed(args: unknown)
    local embed_args = normalize_args(args)
    if embed_args.node_id then
        return embed_node(embed_args.node_id, { model = embed_args.model })
    end

    -- Embed all unembedded
    local db = get_db()
    local rows = db:query("SELECT id FROM keeper_kb_nodes WHERE embedded = 0")
    local count = 0
    local errors = {}

    for _, row in ipairs(rows or {}) do
        local result, err = embed_node(row.id, { model = embed_args.model })
        if result then
            count = count + 1
            pcall(function()
                process.send(consts.CENTRAL, consts.TOPIC, {
                    event = consts.EVENTS.SCAN_PROGRESS,
                    data = { type = "embed", embedded = count, total = #rows },
                })
            end)
        elseif err then
            table.insert(errors, err)
        end
    end

    return { embedded = count, errors = errors, total = #(rows or {}) }
end

return { embed = embed }
