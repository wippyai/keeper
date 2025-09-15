---@class OverlayReader
---@field _user_id string|nil
---@field _workspace_id string|nil
---@field _workspace_ids string[]|nil
---@field _workspace_statuses string[]|nil
---@field _entry_ids string[]|nil
---@field _entry_operation_types string[]|nil
---@field _review_ids string[]|nil
---@field _review_statuses string[]|nil
---@field _op_ids string[]|nil
---@field _permission_types string[]|nil
---@field _include_entries boolean
---@field _include_permissions boolean
---@field _include_reviews boolean
---@field _include_ops boolean
---@field _include_context boolean
---@field _fetch_metadata boolean
---@field _limit number|nil
---@field _mode string

local sql = require("sql")
local json = require("json")
local consts = require("consts")

local overlay_reader = {}
local methods = {}
local reader_mt = { __index = methods }

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

---Create an immutable copy of a reader
---@param self OverlayReader
---@return OverlayReader
function methods:_copy()
    local new_instance = {}
    for k, v in pairs(self) do
        new_instance[k] = v
    end
    return setmetatable(new_instance, reader_mt)
end

---Create a simple IN clause for arrays
---@param field string
---@param values string[]
---@return table|nil
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

---Get database connection
---@return table|nil, string|nil
local function get_db()
    local db, err = sql.get(consts.get_db_resource())
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db, nil
end

---Parse JSON metadata string into table
---@param metadata_str string|nil
---@return table
local function parse_json_metadata(metadata_str)
    if not metadata_str or type(metadata_str) ~= "string" then
        return {}
    end

    local parsed, err = json.decode(metadata_str)
    if err then
        return {}
    else
        return parsed
    end
end

---Parse metadata in result rows
---@param rows table[]
---@return table[]
local function parse_metadata(rows)
    for i, row in ipairs(rows) do
        if row.metadata then
            row.metadata = parse_json_metadata(row.metadata)
        else
            row.metadata = {}
        end

        if row.entry_data then
            row.entry_data = parse_json_metadata(row.entry_data)
        end

        if row.entry_meta then
            row.entry_meta = parse_json_metadata(row.entry_meta)
        end

        if row.meta then
            row.meta = parse_json_metadata(row.meta)
        end

        if row.operation_data then
            row.operation_data = parse_json_metadata(row.operation_data)
        end
    end
    return rows
end

-- ============================================================================
-- FLUENT API INITIALIZATION
-- ============================================================================

---Initialize a new reader for a user's workspaces
---@param user_id string
---@return OverlayReader|nil, string|nil
function overlay_reader.for_user(user_id)
    if not user_id or user_id == "" then
        return nil, "User ID is required"
    end

    local instance = {
        _user_id = user_id,
        _workspace_ids = nil,
        _workspace_statuses = nil,
        _include_entries = false,
        _include_permissions = false,
        _include_reviews = false,
        _include_ops = false,
        _include_context = false,
        _entry_operation_types = nil,
        _permission_types = nil,
        _fetch_metadata = true,
        _limit = nil,
        _mode = "workspaces"
    }
    return setmetatable(instance, reader_mt), nil
end

---Initialize a new reader for workspace entries
---@param workspace_id string
---@return OverlayReader|nil, string|nil
function overlay_reader.for_workspace(workspace_id)
    if not workspace_id or workspace_id == "" then
        return nil, "Workspace ID is required"
    end

    local instance = {
        _workspace_id = workspace_id,
        _entry_ids = nil,
        _entry_operation_types = nil,
        _fetch_metadata = true,
        _limit = nil,
        _mode = "entries"
    }
    return setmetatable(instance, reader_mt), nil
end

---Initialize a new reader for workspace reviews
---@param workspace_id string
---@return OverlayReader|nil, string|nil
function overlay_reader.for_reviews(workspace_id)
    if not workspace_id or workspace_id == "" then
        return nil, "Workspace ID is required"
    end

    local instance = {
        _workspace_id = workspace_id,
        _review_ids = nil,
        _review_statuses = nil,
        _fetch_metadata = true,
        _limit = nil,
        _mode = "reviews"
    }
    return setmetatable(instance, reader_mt), nil
end

---Initialize a new reader for ops audit trail
---@param workspace_id string
---@return OverlayReader|nil, string|nil
function overlay_reader.for_ops(workspace_id)
    if not workspace_id or workspace_id == "" then
        return nil, "Workspace ID is required"
    end

    local instance = {
        _workspace_id = workspace_id,
        _op_ids = nil,
        _fetch_metadata = true,
        _limit = nil,
        _mode = "ops"
    }
    return setmetatable(instance, reader_mt), nil
end

---Initialize a new reader for workspace context
---@param workspace_id string
---@return OverlayReader|nil, string|nil
function overlay_reader.for_context(workspace_id)
    if not workspace_id or workspace_id == "" then
        return nil, "Workspace ID is required"
    end

    local instance = {
        _workspace_id = workspace_id,
        _context_ids = nil,
        _context_labels = nil,
        _fetch_metadata = true,
        _mode = "context"
    }
    return setmetatable(instance, reader_mt), nil
end

-- ============================================================================
-- FILTERING METHODS
-- ============================================================================

---Filter by specific workspaces (for user queries)
---@param ... string
---@return OverlayReader
function methods:with_workspaces(...)
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._workspace_ids = { ... }
    return new_instance
end

---Filter by workspace statuses
---@param ... string
---@return OverlayReader
function methods:with_statuses(...)
    if self._mode ~= "workspaces" and self._mode ~= "reviews" then
        return self
    end

    local new_instance = self:_copy()
    if self._mode == "workspaces" then
        new_instance._workspace_statuses = { ... }
    else
        new_instance._review_statuses = { ... }
    end
    return new_instance
end

---Filter by specific entries (for workspace entry queries)
---@param ... string
---@return OverlayReader
function methods:with_entries(...)
    if self._mode ~= "entries" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._entry_ids = { ... }
    return new_instance
end

---Filter by specific reviews
---@param ... string
---@return OverlayReader
function methods:with_reviews(...)
    if self._mode ~= "reviews" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._review_ids = { ... }
    return new_instance
end

---Filter by specific ops
---@param ... string
---@return OverlayReader
function methods:with_ops(...)
    if self._mode ~= "ops" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._op_ids = { ... }
    return new_instance
end

---Filter by specific context records
---@param ... string
---@return OverlayReader
function methods:with_context(...)
    if self._mode ~= "context" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._context_ids = { ... }
    return new_instance
end

---Filter by context labels
---@param ... string
---@return OverlayReader
function methods:with_labels(...)
    if self._mode ~= "context" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._context_labels = { ... }
    return new_instance
end

---Filter by entry operation types
---@param ... string
---@return OverlayReader
function methods:with_operations(...)
    local new_instance = self:_copy()
    new_instance._entry_operation_types = { ... }
    return new_instance
end

---Filter by permission types
---@param ... string
---@return OverlayReader
function methods:with_permission_types(...)
    local new_instance = self:_copy()
    new_instance._permission_types = { ... }
    return new_instance
end

---Limit the number of results
---@param count number
---@return OverlayReader
function methods:limit(count)
    if not count or type(count) ~= "number" or count <= 0 then
        return self
    end

    local new_instance = self:_copy()
    new_instance._limit = count
    return new_instance
end

-- ============================================================================
-- INCLUDE METHODS
-- ============================================================================

---Include entries in workspace results
---@return OverlayReader
function methods:include_entries()
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_entries = true
    return new_instance
end

---Include permissions in workspace results
---@return OverlayReader
function methods:include_permissions()
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_permissions = true
    return new_instance
end

---Include reviews in workspace results
---@return OverlayReader
function methods:include_reviews()
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_reviews = true
    return new_instance
end

---Include ops in workspace results
---@return OverlayReader
function methods:include_ops()
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_ops = true
    return new_instance
end

---Include context in workspace results
---@return OverlayReader
function methods:include_context()
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._include_context = true
    return new_instance
end

---Configure fetch options
---@param options table
---@return OverlayReader
function methods:fetch_options(options)
    if not options or type(options) ~= "table" then
        return self
    end

    local new_instance = self:_copy()

    if options.metadata ~= nil then
        new_instance._fetch_metadata = options.metadata
    end

    return new_instance
end

-- ============================================================================
-- QUERY BUILDING
-- ============================================================================

---Build workspaces query
---@return table|nil, string|nil
function methods:_build_workspaces_query()
    if self._mode ~= "workspaces" then
        return nil, "Invalid mode for workspace query"
    end

    local select_fields = { "w.workspace_id", "w.user_id", "w.status",
        "w.title", "w.description", "w.created_at", "w.updated_at" }

    if self._fetch_metadata then
        table.insert(select_fields, "w.metadata")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("overlay_registry_workspaces w")
        :where("w.user_id = ?", self._user_id)

    -- Apply workspace filters
    if self._workspace_ids and #self._workspace_ids > 0 then
        local ws_clause = create_in_clause("w.workspace_id", self._workspace_ids)
        if ws_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(ws_clause)))
        end
    end

    if self._workspace_statuses and #self._workspace_statuses > 0 then
        local status_clause = create_in_clause("w.status", self._workspace_statuses)
        if status_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(status_clause)))
        end
    end

    query_builder = query_builder:order_by("w.created_at DESC")

    -- Apply limit if specified
    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

---Build entries query
---@return table|nil, string|nil
function methods:_build_entries_query()
    if self._mode ~= "entries" then
        return nil, "Invalid mode for entries query"
    end

    local select_fields = { "we.workspace_entry_id", "we.workspace_id", "we.operation_type",
        "we.entry_id", "we.entry_kind", "we.created_at", "we.updated_at" }

    if self._fetch_metadata then
        table.insert(select_fields, "we.entry_data")
        table.insert(select_fields, "we.entry_meta")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("overlay_registry_workspace_entries we")
        :where("we.workspace_id = ?", self._workspace_id)

    -- Apply entry filters
    if self._entry_ids and #self._entry_ids > 0 then
        local entry_clause = create_in_clause("we.entry_id", self._entry_ids)
        if entry_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(entry_clause)))
        end
    end

    if self._entry_operation_types and #self._entry_operation_types > 0 then
        local op_clause = create_in_clause("we.operation_type", self._entry_operation_types)
        if op_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(op_clause)))
        end
    end

    query_builder = query_builder:order_by("we.created_at DESC")

    -- Apply limit if specified
    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

---Build reviews query
---@return table|nil, string|nil
function methods:_build_reviews_query()
    if self._mode ~= "reviews" then
        return nil, "Invalid mode for reviews query"
    end

    local select_fields = { "wr.review_id", "wr.workspace_id", "wr.name",
        "wr.content", "wr.content_type", "wr.status",
        "wr.created_at", "wr.updated_at" }

    if self._fetch_metadata then
        table.insert(select_fields, "wr.meta")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("overlay_registry_workspace_reviews wr")
        :where("wr.workspace_id = ?", self._workspace_id)

    -- Apply review filters
    if self._review_ids and #self._review_ids > 0 then
        local review_clause = create_in_clause("wr.review_id", self._review_ids)
        if review_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(review_clause)))
        end
    end

    if self._review_statuses and #self._review_statuses > 0 then
        local status_clause = create_in_clause("wr.status", self._review_statuses)
        if status_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(status_clause)))
        end
    end

    query_builder = query_builder:order_by("wr.created_at DESC")

    -- Apply limit if specified
    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

---Build ops query
---@return table|nil, string|nil
function methods:_build_ops_query()
    if self._mode ~= "ops" then
        return nil, "Invalid mode for ops query"
    end

    local select_fields = { "wo.op_id", "wo.workspace_id", "wo.operation_type",
        "wo.user_id", "wo.created_at" }

    if self._fetch_metadata then
        table.insert(select_fields, "wo.operation_data")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("overlay_registry_ops wo")
        :where("wo.workspace_id = ?", self._workspace_id)

    -- Apply ops filters
    if self._op_ids and #self._op_ids > 0 then
        local op_clause = create_in_clause("wo.op_id", self._op_ids)
        if op_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(op_clause)))
        end
    end

    query_builder = query_builder:order_by("wo.created_at DESC")
    -- Apply limit if specified
    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

---Build context query
---@return table|nil, string|nil
function methods:_build_context_query()
    if self._mode ~= "context" then
        return nil, "Invalid mode for context query"
    end

    local select_fields = { "wc.context_id", "wc.workspace_id", "wc.label",
        "wc.content", "wc.content_type", "wc.created_at", "wc.updated_at" }

    if self._fetch_metadata then
        table.insert(select_fields, "wc.metadata")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("overlay_registry_workspace_context wc")
        :where("wc.workspace_id = ?", self._workspace_id)

    -- Apply context filters
    if self._context_ids and #self._context_ids > 0 then
        local context_clause = create_in_clause("wc.context_id", self._context_ids)
        if context_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(context_clause)))
        end
    end

    if self._context_labels and #self._context_labels > 0 then
        local label_clause = create_in_clause("wc.label", self._context_labels)
        if label_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(label_clause)))
        end
    end

    query_builder = query_builder:order_by("wc.created_at DESC")

    -- Apply limit if specified
    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

---Build workspaces with related data query using separate queries to avoid cartesian products
---@return table|nil, string|nil
function methods:_build_workspaces_with_related_query()
    -- We'll use separate queries to avoid cartesian products and duplication
    return self:_build_workspaces_query()
end

-- ============================================================================
-- RESULT PROCESSING
-- ============================================================================

---Group workspace results with related data using separate queries
---@param workspaces table[]
---@param fetch_metadata boolean
---@param include_permissions boolean
---@param include_entries boolean
---@param include_reviews boolean
---@param include_ops boolean
---@param include_context boolean
---@param db table
---@return table[]
local function fetch_related_data_for_workspaces(workspaces, fetch_metadata, include_permissions, include_entries, include_reviews, include_ops, include_context, db)
    if #workspaces == 0 then
        return workspaces
    end

    -- Collect workspace IDs
    local workspace_ids = {}
    local workspace_map = {}
    for _, workspace in ipairs(workspaces) do
        table.insert(workspace_ids, workspace.workspace_id)
        workspace_map[workspace.workspace_id] = workspace

        -- Initialize related data arrays
        if include_permissions then
            workspace.permissions = {}
        end
        if include_entries then
            workspace.entries = {}
        end
        if include_reviews then
            workspace.reviews = {}
        end
        if include_ops then
            workspace.ops = {}
        end
        if include_context then
            workspace.context = {}
        end
    end

    -- Fetch permissions if needed
    if include_permissions then
        local perm_clause = create_in_clause("wp.workspace_id", workspace_ids)
        if perm_clause then
            local perm_query = sql.builder.select("wp.permission_id", "wp.workspace_id", "wp.namespace_pattern", "wp.permission_type", "wp.created_at")
                :from("overlay_registry_workspace_permissions wp")
                :where(sql.builder.expr(unpack(perm_clause)))
                :order_by("wp.created_at DESC")

            local perm_executor = perm_query:run_with(db)
            local perm_results, perm_err = perm_executor:query()

            if not perm_err and perm_results then
                for _, perm in ipairs(perm_results) do
                    local workspace = workspace_map[perm.workspace_id]
                    if workspace then
                        table.insert(workspace.permissions, {
                            permission_id = perm.permission_id,
                            workspace_id = perm.workspace_id,
                            namespace_pattern = perm.namespace_pattern,
                            permission_type = perm.permission_type,
                            created_at = perm.created_at
                        })
                    end
                end
            end
        end
    end

    -- Fetch entries if needed
    if include_entries then
        local entry_clause = create_in_clause("we.workspace_id", workspace_ids)
        if entry_clause then
            local entry_fields = { "we.workspace_entry_id", "we.workspace_id", "we.operation_type", "we.entry_id",
                "we.entry_kind", "we.created_at", "we.updated_at" }
            if fetch_metadata then
                table.insert(entry_fields, "we.entry_data")
                table.insert(entry_fields, "we.entry_meta")
            end

            local entry_query = sql.builder.select(unpack(entry_fields))
                :from("overlay_registry_workspace_entries we")
                :where(sql.builder.expr(unpack(entry_clause)))
                :order_by("we.created_at DESC")

            local entry_executor = entry_query:run_with(db)
            local entry_results, entry_err = entry_executor:query()

            if not entry_err and entry_results then
                if fetch_metadata then
                    entry_results = parse_metadata(entry_results)
                end

                for _, entry in ipairs(entry_results) do
                    local workspace = workspace_map[entry.workspace_id]
                    if workspace then
                        local entry_data = {
                            workspace_entry_id = entry.workspace_entry_id,
                            workspace_id = entry.workspace_id,
                            operation_type = entry.operation_type,
                            entry_id = entry.entry_id,
                            entry_kind = entry.entry_kind,
                            created_at = entry.created_at,
                            updated_at = entry.updated_at
                        }

                        if fetch_metadata then
                            entry_data.entry_data = entry.entry_data or {}
                            entry_data.entry_meta = entry.entry_meta or {}
                        end

                        table.insert(workspace.entries, entry_data)
                    end
                end
            end
        end
    end

    -- Fetch reviews if needed
    if include_reviews then
        local rev_clause = create_in_clause("wr.workspace_id", workspace_ids)
        if rev_clause then
            local rev_fields = { "wr.review_id", "wr.workspace_id", "wr.name", "wr.content_type", "wr.status", "wr.created_at", "wr.updated_at" }
            if fetch_metadata then
                table.insert(rev_fields, "wr.content")
                table.insert(rev_fields, "wr.meta")
            end

            local rev_query = sql.builder.select(unpack(rev_fields))
                :from("overlay_registry_workspace_reviews wr")
                :where(sql.builder.expr(unpack(rev_clause)))
                :order_by("wr.created_at DESC")

            local rev_executor = rev_query:run_with(db)
            local rev_results, rev_err = rev_executor:query()

            if not rev_err and rev_results then
                if fetch_metadata then
                    rev_results = parse_metadata(rev_results)
                end

                for _, rev in ipairs(rev_results) do
                    local workspace = workspace_map[rev.workspace_id]
                    if workspace then
                        local rev_data = {
                            review_id = rev.review_id,
                            workspace_id = rev.workspace_id,
                            name = rev.name,
                            content_type = rev.content_type,
                            status = rev.status,
                            created_at = rev.created_at,
                            updated_at = rev.updated_at
                        }

                        if fetch_metadata then
                            rev_data.content = rev.content
                            rev_data.meta = rev.meta or {}
                        end

                        table.insert(workspace.reviews, rev_data)
                    end
                end
            end
        end
    end

    -- Fetch ops if needed
    if include_ops then
        local ops_clause = create_in_clause("wo.workspace_id", workspace_ids)
        if ops_clause then
            local ops_fields = { "wo.op_id", "wo.workspace_id", "wo.operation_type", "wo.user_id", "wo.created_at" }
            if fetch_metadata then
                table.insert(ops_fields, "wo.operation_data")
            end

            local ops_query = sql.builder.select(unpack(ops_fields))
                :from("overlay_registry_ops wo")
                :where(sql.builder.expr(unpack(ops_clause)))
                :order_by("wo.created_at DESC")

            local ops_executor = ops_query:run_with(db)
            local ops_results, ops_err = ops_executor:query()

            if not ops_err and ops_results then
                if fetch_metadata then
                    ops_results = parse_metadata(ops_results)
                end

                for _, op in ipairs(ops_results) do
                    local workspace = workspace_map[op.workspace_id]
                    if workspace then
                        local op_data = {
                            op_id = op.op_id,
                            workspace_id = op.workspace_id,
                            operation_type = op.operation_type,
                            user_id = op.user_id,
                            created_at = op.created_at
                        }

                        if fetch_metadata and op.operation_data then
                            op_data.operation_data = op.operation_data
                        end

                        table.insert(workspace.ops, op_data)
                    end
                end
            end
        end
    end

    -- Fetch context if needed
    if include_context then
        local context_clause = create_in_clause("wc.workspace_id", workspace_ids)
        if context_clause then
            local context_fields = { "wc.context_id", "wc.workspace_id", "wc.label", "wc.content_type", "wc.created_at", "wc.updated_at" }
            if fetch_metadata then
                table.insert(context_fields, "wc.content")
                table.insert(context_fields, "wc.metadata")
            end

            local context_query = sql.builder.select(unpack(context_fields))
                :from("overlay_registry_workspace_context wc")
                :where(sql.builder.expr(unpack(context_clause)))
                :order_by("wc.created_at DESC")

            local context_executor = context_query:run_with(db)
            local context_results, context_err = context_executor:query()

            if not context_err and context_results then
                if fetch_metadata then
                    context_results = parse_metadata(context_results)
                end

                for _, ctx in ipairs(context_results) do
                    local workspace = workspace_map[ctx.workspace_id]
                    if workspace then
                        local ctx_data = {
                            context_id = ctx.context_id,
                            workspace_id = ctx.workspace_id,
                            label = ctx.label,
                            content_type = ctx.content_type,
                            created_at = ctx.created_at,
                            updated_at = ctx.updated_at
                        }

                        if fetch_metadata then
                            ctx_data.content = ctx.content
                            ctx_data.metadata = ctx.metadata or {}
                        end

                        table.insert(workspace.context, ctx_data)
                    end
                end
            end
        end
    end

    return workspaces
end

-- ============================================================================
-- EXECUTION METHODS
-- ============================================================================

---Get all matching results
---@return table[]|nil, string|nil
function methods:all()
    local db, err = get_db()
    if err then
        return nil, err
    end

    if self._mode == "workspaces" then
        -- Use separate queries to avoid cartesian products when including related data
        if self._include_entries or self._include_permissions or self._include_reviews or self._include_ops or self._include_context then
            local query = self:_build_workspaces_query()
            if not query then
                db:release()
                return nil, "Failed to build workspaces query"
            end

            local executor = query:run_with(db)
            local results, err = executor:query()

            if err then
                db:release()
                return nil, "Failed to fetch workspaces: " .. err
            end

            if self._fetch_metadata then
                results = parse_metadata(results)
            end

            -- Fetch related data using separate queries
            results = fetch_related_data_for_workspaces(results, self._fetch_metadata,
                self._include_permissions, self._include_entries,
                self._include_reviews, self._include_ops, self._include_context, db)

            db:release()
            return results, nil
        else
            -- Simple workspaces query
            local query = self:_build_workspaces_query()
            if not query then
                db:release()
                return nil, "Failed to build workspaces query"
            end

            local executor = query:run_with(db)
            local results, err = executor:query()
            db:release()

            if err then
                return nil, "Failed to fetch workspaces: " .. err
            end

            if self._fetch_metadata then
                results = parse_metadata(results)
            end

            return results, nil
        end
    elseif self._mode == "entries" then
        local query = self:_build_entries_query()
        if not query then
            db:release()
            return nil, "Failed to build entries query"
        end

        local executor = query:run_with(db)
        local results, err = executor:query()
        db:release()

        if err then
            return nil, "Failed to fetch entries: " .. err
        end

        if self._fetch_metadata then
            results = parse_metadata(results)
        end

        return results, nil
    elseif self._mode == "reviews" then
        local query = self:_build_reviews_query()
        if not query then
            db:release()
            return nil, "Failed to build reviews query"
        end

        local executor = query:run_with(db)
        local results, err = executor:query()
        db:release()

        if err then
            return nil, "Failed to fetch reviews: " .. err
        end

        if self._fetch_metadata then
            results = parse_metadata(results)
        end

        return results, nil
    elseif self._mode == "ops" then
        local query = self:_build_ops_query()
        if not query then
            db:release()
            return nil, "Failed to build ops query"
        end

        local executor = query:run_with(db)
        local results, err = executor:query()
        db:release()

        if err then
            return nil, "Failed to fetch ops: " .. err
        end

        if self._fetch_metadata then
            results = parse_metadata(results)
        end

        return results, nil
    elseif self._mode == "context" then
        local query = self:_build_context_query()
        if not query then
            db:release()
            return nil, "Failed to build context query"
        end

        local executor = query:run_with(db)
        local results, err = executor:query()
        db:release()

        if err then
            return nil, "Failed to fetch context: " .. err
        end

        if self._fetch_metadata then
            results = parse_metadata(results)
        end

        return results, nil
    else
        db:release()
        return nil, "Invalid mode: " .. (self._mode or "nil")
    end
end

---Get a single result
---@return table|nil, string|nil
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

---Count matching results
---@return number|nil, string|nil
function methods:count()
    local db, err = get_db()
    if err then
        return nil, err
    end

    local count_query

    if self._mode == "workspaces" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("overlay_registry_workspaces w")
            :where("w.user_id = ?", self._user_id)

        if self._workspace_ids and #self._workspace_ids > 0 then
            local ws_clause = create_in_clause("w.workspace_id", self._workspace_ids)
            if ws_clause then
                count_query = count_query:where(sql.builder.expr(unpack(ws_clause)))
            end
        end

        if self._workspace_statuses and #self._workspace_statuses > 0 then
            local status_clause = create_in_clause("w.status", self._workspace_statuses)
            if status_clause then
                count_query = count_query:where(sql.builder.expr(unpack(status_clause)))
            end
        end
    elseif self._mode == "entries" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("overlay_registry_workspace_entries we")
            :where("we.workspace_id = ?", self._workspace_id)

        if self._entry_ids and #self._entry_ids > 0 then
            local entry_clause = create_in_clause("we.entry_id", self._entry_ids)
            if entry_clause then
                count_query = count_query:where(sql.builder.expr(unpack(entry_clause)))
            end
        end

        if self._entry_operation_types and #self._entry_operation_types > 0 then
            local op_clause = create_in_clause("we.operation_type", self._entry_operation_types)
            if op_clause then
                count_query = count_query:where(sql.builder.expr(unpack(op_clause)))
            end
        end
    elseif self._mode == "reviews" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("overlay_registry_workspace_reviews wr")
            :where("wr.workspace_id = ?", self._workspace_id)

        if self._review_ids and #self._review_ids > 0 then
            local review_clause = create_in_clause("wr.review_id", self._review_ids)
            if review_clause then
                count_query = count_query:where(sql.builder.expr(unpack(review_clause)))
            end
        end

        if self._review_statuses and #self._review_statuses > 0 then
            local status_clause = create_in_clause("wr.status", self._review_statuses)
            if status_clause then
                count_query = count_query:where(sql.builder.expr(unpack(status_clause)))
            end
        end
    elseif self._mode == "ops" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("overlay_registry_ops wo")
            :where("wo.workspace_id = ?", self._workspace_id)

        if self._op_ids and #self._op_ids > 0 then
            local op_clause = create_in_clause("wo.op_id", self._op_ids)
            if op_clause then
                count_query = count_query:where(sql.builder.expr(unpack(op_clause)))
            end
        end
    elseif self._mode == "context" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("overlay_registry_workspace_context wc")
            :where("wc.workspace_id = ?", self._workspace_id)

        if self._context_ids and #self._context_ids > 0 then
            local context_clause = create_in_clause("wc.context_id", self._context_ids)
            if context_clause then
                count_query = count_query:where(sql.builder.expr(unpack(context_clause)))
            end
        end

        if self._context_labels and #self._context_labels > 0 then
            local label_clause = create_in_clause("wc.label", self._context_labels)
            if label_clause then
                count_query = count_query:where(sql.builder.expr(unpack(label_clause)))
            end
        end
    else
        db:release()
        return nil, "Invalid mode for count: " .. (self._mode or "nil")
    end

    local executor = count_query:run_with(db)
    local results, err = executor:query()
    db:release()

    if err then
        return nil, "Failed to count results: " .. err
    end

    return results[1].count, nil
end

---Check if matching results exist
---@return boolean|nil, string|nil
function methods:exists()
    local count, err = self:count()
    if err then
        return nil, err
    end
    return count > 0, nil
end

return overlay_reader
