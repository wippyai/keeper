local http = require("http")
local sql  = require("sql")
local consts  = require("task_consts")

local M = {}

-- Module-level load time; reset whenever the function module is reloaded.
local start_time = os.time()
local VERSION = 1  -- numeric so the test's "all three are numbers" invariant holds

function M.compute(db)
    local rows, err = db:query([[SELECT COUNT(*) AS c FROM keeper_tasks]], {})
    if err then return nil, err end
    local count = (rows and rows[1] and tonumber(rows[1].c)) or 0
    return {
        version         = VERSION,
        uptime_seconds  = os.time() - start_time,
        task_count      = count,
    }, nil
end

function M.handler()
    local res = http.response()
    if not res then return nil, "Failed to get HTTP context" end

    local db, derr = sql.get(consts.DATABASE.RESOURCE_ID)
    if derr or not db then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = tostring(derr or "db unavailable") })
        return
    end

    local status, err = M.compute(db)
    db:release()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = tostring(err) })
        return
    end

    do
        local _ok_body = status or {}
        _ok_body.success = true
        res:set_status(http.STATUS.OK)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json(_ok_body)
    end
end

return M