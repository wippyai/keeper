local sql = require("sql")
local json = require("json")
local consts = require("design_consts")

local design_reader = {}

design_reader._deps = {
    security = require("security")
}

local methods = {}
local reader_mt = { __index = methods }

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

local function get_db()
    local db, err = sql.get(consts.get_db_resource())
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db, nil
end

local function parse_json_metadata(metadata_str)
    if not metadata_str or type(metadata_str) ~= "string" then
        return table.create(0, 1)
    end

    local parsed, err = json.decode(metadata_str)
    if err then
        return table.create(0, 1)
    else
        return parsed
    end
end

local function parse_metadata(rows)
    for i, row in ipairs(rows) do
        if row.metadata then
            row.metadata = parse_json_metadata(row.metadata)
        else
            row.metadata = table.create(0, 1)
        end
    end
    return rows
end

function methods:_copy()
    local new_instance = {}
    for k, v in pairs(self) do
        new_instance[k] = v
    end
    return setmetatable(new_instance, reader_mt)
end

function design_reader.for_user(user_id)
    if not user_id or user_id == "" then
        local actor = design_reader._deps.security.actor()
        if not actor then
            return nil, "Authentication required"
        end
        user_id = actor:id()
    end

    local instance = {
        _user_id = user_id,
        _workspace_ids = nil,
        _workspace_statuses = nil,
        _fetch_metadata = true,
        _limit = nil,
        _mode = "workspaces"
    }
    return setmetatable(instance, reader_mt), nil
end

function design_reader.for_workspace(workspace_id)
    if not workspace_id or workspace_id == "" then
        return nil, "Workspace ID is required"
    end

    local instance = {
        _workspace_id = workspace_id,
        _data_ids = nil,
        _types = nil,
        _discriminators = nil,
        _statuses = nil,
        _parent_data_id = nil,
        _parent_direct = false,
        _depth = nil,
        _fetch_metadata = true,
        _limit = nil,
        _order_by = nil,
        _mode = "data"
    }
    return setmetatable(instance, reader_mt), nil
end

function methods:with_workspaces(...)
    if self._mode ~= "workspaces" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._workspace_ids = { ... }
    return new_instance
end

function methods:with_statuses(...)
    local new_instance = self:_copy()
    if self._mode == "workspaces" then
        new_instance._workspace_statuses = { ... }
    else
        new_instance._statuses = { ... }
    end
    return new_instance
end

function methods:with_data(...)
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._data_ids = { ... }
    return new_instance
end

function methods:with_type(...)
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._types = { ... }
    return new_instance
end

function methods:with_discriminator(...)
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._discriminators = { ... }
    return new_instance
end

function methods:with_parent(parent_data_id)
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._parent_data_id = parent_data_id
    new_instance._parent_direct = false
    return new_instance
end

function methods:with_parent_direct(parent_data_id)
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._parent_data_id = parent_data_id
    new_instance._parent_direct = true
    return new_instance
end

function methods:with_depth(depth)
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._depth = depth
    return new_instance
end

function methods:order_by_path()
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._order_by = "path"
    return new_instance
end

function methods:order_by_position()
    if self._mode ~= "data" then
        return self
    end

    local new_instance = self:_copy()
    new_instance._order_by = "position"
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
        :from("design_workspaces w")
        :where("w.user_id = ?", self._user_id)

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

    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

function methods:_build_data_query()
    if self._mode ~= "data" then
        return nil, "Invalid mode for data query"
    end

    local select_fields = { "wd.data_id", "wd.workspace_id", "wd.user_id",
        "wd.parent_data_id", "wd.path", "wd.depth", "wd.position",
        "wd.type", "wd.discriminator", "wd.content", "wd.content_type",
        "wd.status", "wd.created_at", "wd.updated_at" }

    if self._fetch_metadata then
        table.insert(select_fields, "wd.metadata")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("design_workspace_data wd")
        :where("wd.workspace_id = ?", self._workspace_id)

    if self._data_ids and #self._data_ids > 0 then
        local data_clause = create_in_clause("wd.data_id", self._data_ids)
        if data_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(data_clause)))
        end
    end

    if self._types and #self._types > 0 then
        local type_clause = create_in_clause("wd.type", self._types)
        if type_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(type_clause)))
        end
    end

    if self._discriminators and #self._discriminators > 0 then
        local disc_clause = create_in_clause("wd.discriminator", self._discriminators)
        if disc_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(disc_clause)))
        end
    end

    if self._statuses and #self._statuses > 0 then
        local status_clause = create_in_clause("wd.status", self._statuses)
        if status_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(status_clause)))
        end
    end

    if self._parent_data_id then
        if self._parent_direct then
            query_builder = query_builder:where("wd.parent_data_id = ?", self._parent_data_id)
        else
            local parent_lookup = sql.builder.select("path")
                :from("design_workspace_data")
                :where("data_id = ?", self._parent_data_id)

            local db, db_err = get_db()
            if db_err then
                return nil, db_err
            end

            local parent_exec = parent_lookup:run_with(db)
            local parent_result, parent_err = parent_exec:query()
            db:release()

            if parent_err or not parent_result or #parent_result == 0 then
                return nil, "Parent data not found"
            end

            local parent_path = parent_result[1].path
            query_builder = query_builder:where("wd.path LIKE ?", parent_path .. ".%")
        end
    end

    if self._depth ~= nil then
        query_builder = query_builder:where("wd.depth = ?", self._depth)
    end

    if self._order_by == "path" then
        query_builder = query_builder:order_by("wd.path ASC")
    elseif self._order_by == "position" then
        query_builder = query_builder:order_by("wd.position ASC")
    else
        query_builder = query_builder:order_by("wd.created_at DESC")
    end

    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

function methods:all()
    local db, err = get_db()
    if err then
        return nil, err
    end

    local query
    if self._mode == "workspaces" then
        query = self:_build_workspaces_query()
    elseif self._mode == "data" then
        query = self:_build_data_query()
    else
        db:release()
        return nil, "Invalid mode: " .. (self._mode or "nil")
    end

    if not query then
        db:release()
        return nil, "Failed to build query"
    end

    local executor = query:run_with(db)
    local results, exec_err = executor:query()
    db:release()

    if exec_err then
        return nil, "Failed to fetch results: " .. exec_err
    end

    if self._fetch_metadata then
        results = parse_metadata(results)
    end

    return results, nil
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
    local db, err = get_db()
    if err then
        return nil, err
    end

    local count_query

    if self._mode == "workspaces" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("design_workspaces w")
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
    elseif self._mode == "data" then
        count_query = sql.builder.select("COUNT(*) as count")
            :from("design_workspace_data wd")
            :where("wd.workspace_id = ?", self._workspace_id)

        if self._data_ids and #self._data_ids > 0 then
            local data_clause = create_in_clause("wd.data_id", self._data_ids)
            if data_clause then
                count_query = count_query:where(sql.builder.expr(unpack(data_clause)))
            end
        end

        if self._types and #self._types > 0 then
            local type_clause = create_in_clause("wd.type", self._types)
            if type_clause then
                count_query = count_query:where(sql.builder.expr(unpack(type_clause)))
            end
        end

        if self._discriminators and #self._discriminators > 0 then
            local disc_clause = create_in_clause("wd.discriminator", self._discriminators)
            if disc_clause then
                count_query = count_query:where(sql.builder.expr(unpack(disc_clause)))
            end
        end

        if self._statuses and #self._statuses > 0 then
            local status_clause = create_in_clause("wd.status", self._statuses)
            if status_clause then
                count_query = count_query:where(sql.builder.expr(unpack(status_clause)))
            end
        end

        if self._depth ~= nil then
            count_query = count_query:where("wd.depth = ?", self._depth)
        end
    else
        db:release()
        return nil, "Invalid mode for count: " .. (self._mode or "nil")
    end

    local executor = count_query:run_with(db)
    local results, exec_err = executor:query()
    db:release()

    if exec_err then
        return nil, "Failed to count results: " .. exec_err
    end

    return results[1].count, nil
end

function methods:exists()
    local count, err = self:count()
    if err then
        return nil, err
    end
    return count > 0, nil
end

return design_reader
