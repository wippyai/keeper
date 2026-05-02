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
    local db_id = consts.db_id()
    local db = sql.get(db_id)
    if not db then error("database " .. db_id .. " is not available") end
    return db
end

local function embed_text(text: string, requested_model: string?): (table?, string?, string?)
    local last_err = nil
    for _, model in ipairs(consts.embedding_models(requested_model)) do
        local result, err = llm.embed(text, { model = model, dimensions = consts.EMBED.DIMENSIONS })
        if result then
            return result, nil, model
        end
        last_err = err or "no result"
    end
    return nil, last_err or "no result", nil
end

local function embed_node(id, params)
    params = params or {}
    local node = kb_repo.get(id)
    if not node then return nil, "Node not found" end

    local text = node.title .. "\n\n" .. node.content
    local embed_result, err, model = embed_text(text, params.model)
    if err or not embed_result then return nil, "Embedding failed: " .. (err or "no result") end

    local result = embed_result.result
    if not result then return nil, "Empty embedding result" end
    local embedding = type(result) == "table" and result[1] or result
    if not embedding then return nil, "No embedding vector" end

    local db = get_db()
    sql.builder.delete("keeper_kb_embeddings")
        :where("node_id = ?", id)
        :run_with(db)
        :exec()
    local _, insert_err = sql.builder.insert("keeper_kb_embeddings")
        :set_map({
            node_id = id,
            embedding = json.encode(embedding),
            title = node.title,
            content_preview = node.content:sub(1, 200),
        })
        :run_with(db)
        :exec()
    if insert_err then return nil, "Failed to store embedding: " .. insert_err end

    sql.builder.update("keeper_kb_nodes")
        :set("embedded", 1)
        :where("id = ?", id)
        :run_with(db)
        :exec()

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
