local http = require("http")
local security = require("security")
local sql  = require("sql")
local consts  = require("task_consts")

local M = {}

function M.compute(db)
    local rows, err = db:query([[
        SELECT
            COUNT(*)                                                       AS total,
            SUM(CASE WHEN status = 'active'    THEN 1 ELSE 0 END)           AS open,
            SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END)           AS completed,
            SUM(CASE WHEN status = 'abandoned' THEN 1 ELSE 0 END)           AS cancelled,
            SUM(CASE WHEN archived = 1          THEN 1 ELSE 0 END)           AS archived,
            SUM(CASE WHEN phase = 'spec'      THEN 1 ELSE 0 END)             AS p_spec,
            SUM(CASE WHEN phase = 'design'    THEN 1 ELSE 0 END)             AS p_design,
            SUM(CASE WHEN phase = 'implement' THEN 1 ELSE 0 END)             AS p_implement,
            SUM(CASE WHEN phase = 'review'    THEN 1 ELSE 0 END)             AS p_review,
            SUM(CASE WHEN phase = 'done'      THEN 1 ELSE 0 END)             AS p_finish
        FROM keeper_tasks
    ]], {})
    if err then return nil, err end
    local r = (rows and rows[1]) or {}
    local function n(v) return tonumber(v) or 0 end
    return {
        total     = n(r.total),
        open      = n(r.open),
        completed = n(r.completed),
        cancelled = n(r.cancelled),
        archived  = n(r.archived),
        by_phase = {
            spec      = n(r.p_spec),
            design    = n(r.p_design),
            implement = n(r.p_implement),
            review    = n(r.p_review),
            finish    = n(r.p_finish),
        },
    }, nil
end

function M.handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local db, derr = sql.get(consts.DATABASE.RESOURCE_ID)
    if derr or not db then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = tostring(derr or "db unavailable") })
        return
    end

    local stats, err = M.compute(db)
    db:release()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = tostring(err) })
        return
    end

    do
        local _ok_body = stats or {}
        _ok_body.success = true
        res:set_status(http.STATUS.OK)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json(_ok_body)
    end
end

return M