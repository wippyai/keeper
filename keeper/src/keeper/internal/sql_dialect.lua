local sql = require("sql")

local M = {}

function M.is_postgres(db: any): boolean
    local ok, t = pcall(function() return db:type() end)
    return ok and t == sql.type.POSTGRES
end

function M.bind_postgres_placeholders(statement: string, params: any): (string?, string?)
    local expected = params and #params or 0
    if expected == 0 then return statement end

    -- Keeper still has a few static rollup queries that are clearer as SQL than
    -- sql.builder chains. Bind only real placeholders and fail if the count
    -- does not match so future dialect-specific operators cannot be rewritten
    -- silently.
    local out = {}
    local i = 1
    local n = #statement
    local count = 0
    local mode = nil

    while i <= n do
        local ch = statement:sub(i, i)
        local pair = statement:sub(i, i + 1)

        if mode == "single" then
            out[#out + 1] = ch
            if ch == "'" then
                if statement:sub(i + 1, i + 1) == "'" then
                    out[#out + 1] = "'"
                    i = i + 2
                else
                    mode = nil
                    i = i + 1
                end
            else
                i = i + 1
            end
        elseif mode == "double" then
            out[#out + 1] = ch
            if ch == '"' then
                if statement:sub(i + 1, i + 1) == '"' then
                    out[#out + 1] = '"'
                    i = i + 2
                else
                    mode = nil
                    i = i + 1
                end
            else
                i = i + 1
            end
        elseif mode == "line_comment" then
            out[#out + 1] = ch
            if ch == "\n" then mode = nil end
            i = i + 1
        elseif mode == "block_comment" then
            if pair == "*/" then
                out[#out + 1] = pair
                mode = nil
                i = i + 2
            else
                out[#out + 1] = ch
                i = i + 1
            end
        elseif pair == "--" then
            out[#out + 1] = pair
            mode = "line_comment"
            i = i + 2
        elseif pair == "/*" then
            out[#out + 1] = pair
            mode = "block_comment"
            i = i + 2
        elseif ch == "'" then
            out[#out + 1] = ch
            mode = "single"
            i = i + 1
        elseif ch == '"' then
            out[#out + 1] = ch
            mode = "double"
            i = i + 1
        elseif ch == "?" then
            count = count + 1
            out[#out + 1] = "$" .. tostring(count)
            i = i + 1
        else
            out[#out + 1] = ch
            i = i + 1
        end
    end

    if count ~= expected then
        return nil, "placeholder count mismatch: expected " ..
            tostring(expected) .. ", found " .. tostring(count)
    end

    return table.concat(out)
end

function M.query(db: any, statement: string, params: any): any
    if M.is_postgres(db) then
        local bound, err = M.bind_postgres_placeholders(statement, params)
        if not bound then return nil, err end
        statement = bound
    end
    return db:query(statement, params)
end

return M
