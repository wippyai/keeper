local hash = require("hash")

-- Tokens at rest move from plaintext primary key to sha256(raw_token).
-- Raw tokens are returned once on create; they never hit the DB again.
-- session_state rows are re-keyed to the hashed value so they still resolve
-- on the next request (clients keep sending the raw token, lookup hashes).

local function sha256_hex(raw)
    local digest, err = hash.sha256(raw)
    if err then error("sha256 failed: " .. tostring(err)) end
    return digest
end

local function is_postgres(db)
    local ok, t = pcall(function() return db:type() end)
    return ok and t == "postgres"
end

local function rekey(db, table_name, digest, raw)
    local stmt = "UPDATE " .. table_name .. " SET token = ? WHERE token = ?"
    if is_postgres(db) then
        stmt = "UPDATE " .. table_name .. " SET token = $1 WHERE token = $2"
    end
    return db:execute(stmt, { digest, raw })
end

return require("migration").define(function()
    migration("MCP tokens: store sha256(token) at rest", function()
        database("sqlite", function()
            up(function(db)
                local rows, err = db:query(
                    "SELECT token FROM keeper_mcp_tokens"
                )
                if err then error("read tokens: " .. err) end

                for _, row in ipairs(rows or {}) do
                    local raw = row.token
                    local digest = sha256_hex(raw)
                    if digest ~= raw then
                        local _, s_err = rekey(db, "keeper_mcp_session_state", digest, raw)
                        if s_err then error("rekey session_state: " .. s_err) end

                        local _, t_err = rekey(db, "keeper_mcp_tokens", digest, raw)
                        if t_err then error("rehash token: " .. t_err) end
                    end
                end

                return true
            end)

            down(function(db)
                return true
            end)
        end)

        database("postgres", function()
            up(function(db)
                local rows, err = db:query(
                    "SELECT token FROM keeper_mcp_tokens"
                )
                if err then error("read tokens: " .. err) end

                for _, row in ipairs(rows or {}) do
                    local raw = row.token
                    local digest = sha256_hex(raw)
                    if digest ~= raw then
                        local _, s_err = rekey(db, "keeper_mcp_session_state", digest, raw)
                        if s_err then error("rekey session_state: " .. s_err) end

                        local _, t_err = rekey(db, "keeper_mcp_tokens", digest, raw)
                        if t_err then error("rehash token: " .. t_err) end
                    end
                end

                return true
            end)

            down(function(db)
                return true
            end)
        end)
    end)
end)
