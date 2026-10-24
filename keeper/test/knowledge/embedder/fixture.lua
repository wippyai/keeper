type Failure = string | error

local M = {
    EMBED = { DIMENSIONS = 3 },
    TOPIC = "knowledge-test",
    EVENTS = { NODE_EMBEDDED = "embedded" },
}

function M.reset()
    M.responses = {}
    M.calls = {}
    M.writes = {}
    M.insert_error = nil
    M.notifications = 0
end

function M.embedding_models(requested: string?): { string }
    return { requested or "primary", "fallback" }
end

function M.embed(text: string, options: table): (table?, Failure?)
    M.calls[#M.calls + 1] = { text = text, model = options.model }
    local response = M.responses[#M.calls] or {}
    return response.result, response.error
end

function M.db_id(): string return "embedding-test-db" end
function M.get(id: string): table
    if id == "embedding-test-db" then return {} end
    return { id = id, title = "Title", content = "Content" }
end

local function statement(operation: string): table
    local query = {}
    function query:where(...) return self end
    function query:run_with(...) return self end
    function query:set_map(...) return self end
    function query:set(...) return self end
    function query:exec(): (table?, Failure?)
        M.writes[#M.writes + 1] = operation
        if operation == "insert" and M.insert_error then return nil, M.insert_error end
        return { rows_affected = 1 }, nil
    end
    return query
end

M.builder = {
    delete = function(...) return statement("delete") end,
    insert = function(...) return statement("insert") end,
    update = function(...) return statement("update") end,
}

function M.publish(...)
    M.notifications = M.notifications + 1
    return true
end

return M
