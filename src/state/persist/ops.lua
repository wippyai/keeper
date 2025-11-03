local sql = require("sql")
local json = require("json")
local time = require("time")
local hash = require("hash")
local consts = require("overlay_consts")

local state_ops = {}

state_ops.COMMAND = {
    SET_ENTRY = "set_entry",
    DELETE_ENTRY = "delete_entry",
    SET_EDGE = "set_edge",
    DELETE_EDGE = "delete_edge",
    SET_ATTRIBUTE = "set_attribute",
    DELETE_ATTRIBUTE = "delete_attribute",
}

local handlers = {}

handlers[state_ops.COMMAND.SET_ENTRY] = function(tx, cmd)
    local p = cmd.payload
    if not p.id or not p.kind or not p.definition then
        return nil, "Missing required fields: id, kind, definition"
    end

    local branch = p.branch or consts.BRANCH.MAIN
    local now = time.now():format("RFC3339Nano")

    local def_hash, err = hash.sha256(p.definition)
    if err then
        return nil, "Definition hash failed: " .. err
    end

    local success, err = tx:execute([[
        INSERT OR REPLACE INTO overlay_entries
        (id, branch, kind, deleted, created_at, updated_at)
        VALUES (?, ?, ?, 0, ?, ?)
    ]], {
        p.id,
        branch,
        p.kind,
        now,
        now
    })

    if err then
        return nil, "Entry insert failed: " .. err
    end

    tx:execute([[
        DELETE FROM overlay_chunks
        WHERE entry_id = ? AND branch = ?
    ]], {p.id, branch})

    tx:execute([[
        DELETE FROM overlay_chunks_fts
        WHERE entry_id = ? AND branch = ?
    ]], {p.id, branch})

    success, err = tx:execute([[
        INSERT INTO overlay_chunks
        (entry_id, branch, chunk_type, content, content_hash, created_at)
        VALUES (?, ?, 'definition', ?, ?, ?)
    ]], {
        p.id,
        branch,
        p.definition,
        def_hash,
        now
    })

    if err then
        return nil, "Definition chunk insert failed: " .. err
    end

    success, err = tx:execute([[
        INSERT INTO overlay_chunks_fts
        (entry_id, branch, content)
        VALUES (?, ?, ?)
    ]], {p.id, branch, p.definition})

    if err then
        return nil, "Definition FTS insert failed: " .. err
    end

    if p.content and p.content ~= "" then
        local content_hash, hash_err = hash.sha256(p.content)
        if hash_err then
            return nil, "Content hash failed: " .. hash_err
        end

        success, err = tx:execute([[
            INSERT INTO overlay_chunks
            (entry_id, branch, chunk_type, content, content_hash, created_at)
            VALUES (?, ?, 'content', ?, ?, ?)
        ]], {
            p.id,
            branch,
            p.content,
            content_hash,
            now
        })

        if err then
            return nil, "Content chunk insert failed: " .. err
        end

        success, err = tx:execute([[
            INSERT INTO overlay_chunks_fts
            (entry_id, branch, content)
            VALUES (?, ?, ?)
        ]], {p.id, branch, p.content})

        if err then
            return nil, "Content FTS insert failed: " .. err
        end
    end

    if p.attributes and type(p.attributes) == "table" then
        tx:execute([[
            DELETE FROM overlay_attributes
            WHERE entry_id = ? AND branch = ?
        ]], {p.id, branch})

        for k, v in pairs(p.attributes) do
            success, err = tx:execute([[
                INSERT INTO overlay_attributes
                (entry_id, branch, attr_key, attr_value)
                VALUES (?, ?, ?, ?)
            ]], {p.id, branch, k, tostring(v)})

            if err then
                return nil, "Attribute insert failed: " .. err
            end
        end
    end

    return {
        entry_id = p.id,
        branch = branch,
        changes_made = true
    }
end

handlers[state_ops.COMMAND.DELETE_ENTRY] = function(tx, cmd)
    local p = cmd.payload
    if not p.id then
        return nil, "Missing required field: id"
    end

    local branch = p.branch or consts.BRANCH.MAIN
    local now = time.now():format("RFC3339Nano")

    local kind_result, err = tx:query([[
        SELECT kind FROM overlay_entries
        WHERE id = ? AND branch IN (?, 'main')
        ORDER BY CASE WHEN branch = ? THEN 0 ELSE 1 END
        LIMIT 1
    ]], {p.id, branch, branch})

    if err then
        return nil, "Failed to lookup entry: " .. err
    end

    if not kind_result or #kind_result == 0 then
        return nil, "Entry not found: " .. p.id
    end

    local kind = kind_result[1].kind
    local success, err = tx:execute([[
        INSERT OR REPLACE INTO overlay_entries
        (id, branch, kind, deleted, created_at, updated_at)
        VALUES (?, ?, ?, 1, ?, ?)
    ]], {p.id, branch, kind, now, now})

    if err then
        return nil, "Entry delete failed: " .. err
    end

    return {
        entry_id = p.id,
        branch = branch,
        changes_made = true
    }
end

handlers[state_ops.COMMAND.SET_EDGE] = function(tx, cmd)
    local p = cmd.payload
    if not p.source_id or not p.target_id or not p.edge_type then
        return nil, "Missing required fields: source_id, target_id, edge_type"
    end

    if type(p.source_id) ~= "string" then
        return nil, "source_id must be a string, got " .. type(p.source_id)
    end

    if type(p.target_id) ~= "string" then
        return nil, "target_id must be a string, got " .. type(p.target_id)
    end

    if type(p.edge_type) ~= "string" then
        return nil, "edge_type must be a string, got " .. type(p.edge_type)
    end

    local branch = p.branch or consts.BRANCH.MAIN
    local now = time.now():format("RFC3339Nano")

    local metadata_json = "{}"
    if p.metadata and type(p.metadata) == "table" then
        local encoded, encode_err = json.encode(p.metadata)
        if encoded and not encode_err then
            metadata_json = encoded
        end
    elseif p.metadata and type(p.metadata) == "string" then
        metadata_json = p.metadata
    end

    local check_result, check_err = tx:query([[
        SELECT metadata FROM overlay_edges
        WHERE source_id = ? AND target_id = ? AND branch = ? AND edge_type = ?
    ]], {p.source_id, p.target_id, branch, p.edge_type})

    local changes_made = true
    if check_result and #check_result > 0 then
        if check_result[1].metadata == metadata_json then
            changes_made = false
        end
    end

    local success, err = tx:execute([[
        INSERT OR REPLACE INTO overlay_edges
        (source_id, target_id, branch, edge_type, metadata, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        p.source_id,
        p.target_id,
        branch,
        p.edge_type,
        metadata_json,
        now
    })

    if err then
        return nil, "Edge insert failed: " .. err
    end

    return {
        source_id = p.source_id,
        target_id = p.target_id,
        edge_type = p.edge_type,
        branch = branch,
        changes_made = changes_made
    }
end

handlers[state_ops.COMMAND.DELETE_EDGE] = function(tx, cmd)
    local p = cmd.payload
    if not p.source_id or not p.target_id or not p.edge_type then
        return nil, "Missing required fields: source_id, target_id, edge_type"
    end

    local branch = p.branch or consts.BRANCH.MAIN

    local success, err = tx:execute([[
        DELETE FROM overlay_edges
        WHERE source_id = ? AND target_id = ? AND branch = ? AND edge_type = ?
    ]], {p.source_id, p.target_id, branch, p.edge_type})

    if err then
        return nil, "Edge delete failed: " .. err
    end

    return {
        source_id = p.source_id,
        target_id = p.target_id,
        edge_type = p.edge_type,
        branch = branch,
        changes_made = true
    }
end

handlers[state_ops.COMMAND.SET_ATTRIBUTE] = function(tx, cmd)
    local p = cmd.payload
    if not p.entry_id or not p.attr_key then
        return nil, "Missing required fields: entry_id, attr_key"
    end

    local branch = p.branch or consts.BRANCH.MAIN

    local success, err = tx:execute([[
        INSERT OR REPLACE INTO overlay_attributes
        (entry_id, branch, attr_key, attr_value)
        VALUES (?, ?, ?, ?)
    ]], {
        p.entry_id,
        branch,
        p.attr_key,
        tostring(p.attr_value or "")
    })

    if err then
        return nil, "Attribute set failed: " .. err
    end

    return {
        entry_id = p.entry_id,
        attr_key = p.attr_key,
        branch = branch,
        changes_made = true
    }
end

handlers[state_ops.COMMAND.DELETE_ATTRIBUTE] = function(tx, cmd)
    local p = cmd.payload
    if not p.entry_id or not p.attr_key then
        return nil, "Missing required fields: entry_id, attr_key"
    end

    local branch = p.branch or consts.BRANCH.MAIN

    local success, err = tx:execute([[
        DELETE FROM overlay_attributes
        WHERE entry_id = ? AND branch = ? AND attr_key = ?
    ]], {p.entry_id, branch, p.attr_key})

    if err then
        return nil, "Attribute delete failed: " .. err
    end

    return {
        entry_id = p.entry_id,
        attr_key = p.attr_key,
        branch = branch,
        changes_made = true
    }
end

function state_ops.execute(tx, commands)
    if not tx then
        return nil, consts.ERRORS.TRANSACTION_REQUIRED
    end

    if not commands then
        return nil, consts.ERRORS.COMMANDS_REQUIRED
    end

    if type(commands) ~= "table" then
        return nil, consts.ERRORS.COMMANDS_REQUIRED
    end

    if #commands == 0 then
        return nil, consts.ERRORS.COMMANDS_EMPTY
    end

    local results = {}
    local changes_made = false

    for i, cmd in ipairs(commands) do
        if not cmd.type then
            return nil, "Command " .. i .. " missing type"
        end

        local handler = handlers[cmd.type]
        if not handler then
            return nil, consts.ERRORS.UNKNOWN_COMMAND_TYPE .. ": " .. cmd.type
        end

        local result, err = handler(tx, cmd)
        if err then
            return nil, "Command " .. i .. " failed: " .. err
        end

        if result.changes_made then
            changes_made = true
        end

        table.insert(results, result)
    end

    return {
        results = results,
        changes_made = changes_made
    }
end

return state_ops