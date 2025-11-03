local http = require("http")
local security = require("security")
local sql = require("sql")
local json = require("json")

local function list_workspace_ops_handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    local workspace_id = req:param("id")
    if not workspace_id or workspace_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing workspace ID"
        })
        return
    end

    local limit = tonumber(req:query("limit")) or 50
    local operation_type = req:query("operation_type")

    if limit > 200 then
        limit = 200
    elseif limit < 1 then
        limit = 1
    end

    local query = sql.builder.select("op_id", "workspace_id", "user_id", "operation_type",
        "operation_data", "created_at")
        :from("design_workspace_ops")
        :where("workspace_id = ?", workspace_id)

    if operation_type and operation_type ~= "" then
        query = query:where("operation_type = ?", operation_type)
    end

    query = query:order_by("created_at DESC"):limit(limit)

    local db, db_err = sql.get("app:db")
    if db_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Database connection failed"
        })
        return
    end

    local executor = query:run_with(db)
    local ops, err = executor:query()
    db:release()

    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    for i, op in ipairs(ops) do
        if op.operation_data then
            local parsed, parse_err = json.decode(op.operation_data)
            if not parse_err then
                op.operation_data = parsed
            end
        end
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        operations = ops or {},
        count = #ops
    })
end

return {
    handler = list_workspace_ops_handler
}