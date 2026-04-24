local sql = require("sql")
local json = require("json")
local consts = require("overlay_consts")

local state_reader = {}
local methods = {}
local reader_mt = { __index = methods }

local function get_db()
    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then
        return nil, consts.ERRORS.DB_CONNECTION_FAILED .. ": " .. err
    end
    return db, nil
end

local function parse_json_metadata(metadata_str: string?)
    if not metadata_str or type(metadata_str) ~= "string" then
        return {}
    end

    local parsed, err = json.decode(metadata_str)
    if err then
        return {}
    end
    return parsed
end

local function create_in_clause(field, values)
    if not values or #values == 0 then
        return nil
    end

    if #values == 1 then
        return { field .. " = ?", values[1] }
    end

    local placeholders = {}
    for i = 1, #values do
        table.insert(placeholders, "?")
    end

    return { field .. " IN (" .. table.concat(placeholders, ", ") .. ")", unpack(values) }
end

local function apply_in_filter(qb, field, values)
    local clause = create_in_clause(field, values)
    if clause then
        qb = qb:where(sql.builder.expr(unpack(clause)))
    end
    return qb
end

local function sanitize_fts_query(query)
    if not query or query == "" then
        return nil
    end

    local sanitized = query:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?:/!~&|<>=;#@\\,{}]', ' ')
    sanitized = sanitized:gsub('"', ' ')
    sanitized = sanitized:gsub('%s+', ' ')
    sanitized = sanitized:gsub('^%s+', '')
    sanitized = sanitized:gsub('%s+$', '')

    if sanitized == "" then
        return nil
    end

    return sanitized
end

function methods:_copy(): StateReader
    local new_instance = {}
    for k, v in pairs(self) do
        new_instance[k] = v
    end
    return setmetatable(new_instance, reader_mt) :: StateReader
end

function state_reader.for_branch(...): (StateReader, string?)
    local branches = {...}
    if #branches == 0 then
        branches = {"main"}
    end

    local instance = {
        _branches = branches,
        _entry_ids = nil,
        _kinds = nil,
        _namespaces = nil,
        _attribute_filters = nil,
        _deleted = false,
        _limit = nil,
        _include_chunks = false,
        _include_attributes = false,
        _search_query = nil,
        _mode = "entries"
    }
    return setmetatable(instance, reader_mt) :: StateReader, nil
end

function state_reader.for_edges(...): (StateReader, string?)
    local branches = {...}
    if #branches == 0 then
        branches = {"main"}
    end

    local instance = {
        _branches = branches,
        _source_ids = nil,
        _target_ids = nil,
        _edge_types = nil,
        _limit = nil,
        _mode = "edges"
    }
    return setmetatable(instance, reader_mt) :: StateReader, nil
end

function methods:with_entries(...)
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._entry_ids = { ... }
    return new_instance
end

function methods:with_kinds(...)
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._kinds = { ... }
    return new_instance
end

function methods:with_namespaces(...)
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._namespaces = { ... }
    return new_instance
end

function methods:with_attributes(filters)
    if self._mode ~= "entries" then
        return self
    end

    if not filters or type(filters) ~= "table" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._attribute_filters = filters
    return new_instance
end

function methods:with_search(query)
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._search_query = query
    return new_instance
end

function methods:with_sources(...)
    if self._mode ~= "edges" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._source_ids = { ... }
    return new_instance
end

function methods:with_targets(...)
    if self._mode ~= "edges" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._target_ids = { ... }
    return new_instance
end

function methods:with_edge_types(...)
    if self._mode ~= "edges" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._edge_types = { ... }
    return new_instance
end

function methods:include_deleted()
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._deleted = true
    return new_instance
end

function methods:include_chunks()
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_chunks = true
    return new_instance
end

function methods:include_attributes()
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_attributes = true
    return new_instance
end

function methods:limit(count)
    if not count or type(count) ~= "number" or count <= 0 then
        return self
    end

    local new_instance = self:_copy()
    new_instance._limit = count
    return new_instance
end

function methods:_build_entries_query_for_branch(branch)
    local select_fields = {
        "e.id",
        "e.branch",
        "e.kind",
        "e.deleted",
        "e.created_at",
        "e.updated_at"
    }

    local query_builder

    if self._search_query then
        local sanitized = sanitize_fts_query(self._search_query)
        if not sanitized then
            return nil, "Invalid search query"
        end

        table.insert(select_fields, "snippet(keeper_overlay_chunks_fts, -1, '', '', '...', 32) as snippet")

        query_builder = sql.builder.select(unpack(select_fields))
            :from("keeper_overlay_entries e")
            :join("keeper_overlay_chunks_fts fts ON e.id = fts.entry_id AND e.branch = fts.branch")
            :where("fts.keeper_overlay_chunks_fts MATCH ?", sanitized)
            :where("e.branch = ?", branch)
    else
        query_builder = sql.builder.select(unpack(select_fields))
            :from("keeper_overlay_entries e")
            :where("e.branch = ?", branch)
    end

    if not self._deleted and #self._branches == 1 then
        query_builder = query_builder:where("e.deleted = 0")
    end

    query_builder = apply_in_filter(query_builder, "e.id", self._entry_ids)
    query_builder = apply_in_filter(query_builder, "e.kind", self._kinds)

    if self._namespaces and #self._namespaces > 0 then
        local conditions = {}
        for _, ns in ipairs(self._namespaces) do
            local escaped_ns = ns:gsub("'", "''")
            table.insert(conditions, "(SUBSTR(e.id, 1, INSTR(e.id, ':') - 1) = '" .. escaped_ns .. "' OR SUBSTR(e.id, 1, INSTR(e.id, ':') - 1) LIKE '" .. escaped_ns .. ".%')")
        end
        if #conditions > 0 then
            query_builder = query_builder:where(sql.builder.expr("(" .. table.concat(conditions, " OR ") .. ")"))
        end
    end

    if self._attribute_filters and type(self._attribute_filters) == "table" then
        for key, value in pairs(self._attribute_filters) do
            query_builder = query_builder:where(
                sql.builder.expr(
                    "EXISTS (SELECT 1 FROM keeper_overlay_attributes a WHERE a.entry_id = e.id AND a.branch = e.branch AND a.attr_key = ? AND a.attr_value = ?)",
                    key, value
                )
            )
        end
    end

    query_builder = query_builder:order_by("e.id ASC")

    if self._limit then
        query_builder = query_builder:limit(tonumber(self._limit) or 0)
    end

    return query_builder
end

function methods:_build_edges_query_for_branch(branch)
    local select_fields = {
        "e.source_id",
        "e.target_id",
        "e.branch",
        "e.edge_type",
        "e.metadata",
        "e.created_at"
    }

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("keeper_overlay_edges e")
        :where("e.branch = ?", branch)

    query_builder = apply_in_filter(query_builder, "e.source_id", self._source_ids)
    query_builder = apply_in_filter(query_builder, "e.target_id", self._target_ids)
    query_builder = apply_in_filter(query_builder, "e.edge_type", self._edge_types)

    query_builder = query_builder:order_by("e.source_id ASC, e.target_id ASC")

    if self._limit then
        query_builder = query_builder:limit(tonumber(self._limit) or 0)
    end

    return query_builder
end

function methods:_fetch_chunks(db, entry_ids, branch)
    if #entry_ids == 0 then
        return {}
    end

    local id_clause = create_in_clause("c.entry_id", entry_ids)
    if not id_clause then
        return {}
    end

    local query = sql.builder.select(
        "c.entry_id",
        "c.chunk_type",
        "c.content",
        "c.content_hash"
    )
        :from("keeper_overlay_chunks c")
        :where("c.branch = ?", branch)
        :where(sql.builder.expr(unpack(id_clause)))

    local executor = query:run_with(db)
    local results, err = executor:query()

    if err or not results then
        return {}
    end

    local chunks_by_entry = {}
    for _, chunk in ipairs(results) do
        if not chunks_by_entry[chunk.entry_id] then
            chunks_by_entry[chunk.entry_id] = {}
        end
        table.insert(chunks_by_entry[chunk.entry_id], {
            type = chunk.chunk_type,
            content = chunk.content,
            hash = chunk.content_hash
        })
    end

    return chunks_by_entry
end

function methods:_fetch_attributes(db, entry_ids, branch)
    if #entry_ids == 0 then
        return {}
    end

    local id_clause = create_in_clause("a.entry_id", entry_ids)
    if not id_clause then
        return {}
    end

    local query = sql.builder.select(
        "a.entry_id",
        "a.attr_key",
        "a.attr_value"
    )
        :from("keeper_overlay_attributes a")
        :where("a.branch = ?", branch)
        :where(sql.builder.expr(unpack(id_clause)))

    local executor = query:run_with(db)
    local results, err = executor:query()

    if err or not results then
        return {}
    end

    local attrs_by_entry = {}
    for _, attr in ipairs(results) do
        if not attrs_by_entry[attr.entry_id] then
            attrs_by_entry[attr.entry_id] = {}
        end
        attrs_by_entry[attr.entry_id][attr.attr_key] = attr.attr_value
    end

    return attrs_by_entry
end

function methods:all()
    local db, err = get_db()
    if err then
        return nil, err
    end

    if self._mode == "entries" then
        local all_entries = {}

        for _, branch in ipairs(self._branches) do
            local query, query_err = self:_build_entries_query_for_branch(branch)
            if not query then
                db:release()
                return nil, query_err or "Failed to build entries query"
            end

            local executor = query:run_with(db)
            local results, err = executor:query()

            if err then
                db:release()
                return nil, "Failed to fetch entries: " .. err
            end

            for _, entry in ipairs(results) do
                table.insert(all_entries, entry)
            end
        end

        local merged = {}
        local seen = {}

        for _, entry in ipairs(all_entries) do
            if not seen[entry.id] then
                seen[entry.id] = true

                if entry.deleted == 0 or self._deleted then
                    merged[entry.id] = entry
                end
            end
        end

        if self._search_query then
            local seen_snippets = {}
            for _, entry in ipairs(all_entries) do
                if merged[entry.id] and entry.snippet and entry.snippet ~= "" then
                    if not seen_snippets[entry.id] then
                        seen_snippets[entry.id] = {}
                    end
                    if not seen_snippets[entry.id][entry.snippet] then
                        seen_snippets[entry.id][entry.snippet] = true
                        if merged[entry.id].snippet and merged[entry.id].snippet ~= "" then
                            merged[entry.id].snippet = merged[entry.id].snippet .. "\n...\n" .. entry.snippet
                        else
                            merged[entry.id].snippet = entry.snippet
                        end
                    end
                end
            end
        end

        local unique_results = {}
        for _, entry in pairs(merged) do
            table.insert(unique_results, entry)
        end

        if self._include_chunks or self._include_attributes then
            local by_branch = {}
            for _, entry in ipairs(unique_results) do
                if not by_branch[entry.branch] then
                    by_branch[entry.branch] = {}
                end
                table.insert(by_branch[entry.branch], entry.id)
            end

            local all_chunks = {}
            local all_attrs = {}

            for branch, entry_ids in pairs(by_branch) do
                if self._include_chunks then
                    local chunks = self:_fetch_chunks(db, entry_ids, branch)
                    for id, chunk_list in pairs(chunks) do
                        all_chunks[id] = chunk_list
                    end
                end
                if self._include_attributes then
                    local attrs = self:_fetch_attributes(db, entry_ids, branch)
                    for id, attr_map in pairs(attrs) do
                        all_attrs[id] = attr_map
                    end
                end
            end

            for _, entry in ipairs(unique_results) do
                if self._include_chunks then
                    entry.chunks = all_chunks[entry.id] or {}
                end
                if self._include_attributes then
                    entry.attributes = all_attrs[entry.id] or {}
                end
            end
        end

        db:release()
        return unique_results, nil

    elseif self._mode == "edges" then
        local all_edges = {}

        for _, branch in ipairs(self._branches) do
            local query = self:_build_edges_query_for_branch(branch)
            if not query then
                db:release()
                return nil, "Failed to build edges query"
            end

            local executor = query:run_with(db)
            local results, err = executor:query()

            if err then
                db:release()
                return nil, "Failed to fetch edges: " .. err
            end

            for _, edge in ipairs(results) do
                table.insert(all_edges, edge)
            end
        end

        local merged = {}
        for _, edge in ipairs(all_edges) do
            local key = edge.source_id .. "|" .. edge.target_id .. "|" .. edge.edge_type
            if not merged[key] then
                merged[key] = edge
            end
        end

        local results = {}
        for _, edge in pairs(merged) do
            edge.metadata = parse_json_metadata(edge.metadata)
            table.insert(results, edge)
        end

        db:release()
        return results, nil
    else
        db:release()
        return nil, "Invalid mode: " .. (self._mode or "nil")
    end
end

function methods:one()
    local results, err = self:all()
    if err then
        return nil, err
    end

    if #results == 0 then
        return nil, nil
    end

    return results[1], nil
end

function methods:count()
    local results, err = self:all()
    if err then
        return nil, err
    end
    return #results, nil
end

function methods:exists()
    local count, err = self:count()
    if err then
        return nil, err
    end
    return count > 0, nil
end

return state_reader