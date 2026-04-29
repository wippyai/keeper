local http = require("http")
local writer = require("task_writer")
local abandon = require("task_abandon")
local lifecycle = require("lifecycle")
local security = require("security")

local function handler()
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

    local task_id = req:param("id") or req:query("id")
    if not task_id or task_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "task id required" })
        return
    end

    local body = req:body_json()
    if not body then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "request body required" })
        return
    end

    body.actor_id = actor:id()

    local _, err = writer.for_task(task_id):update_task(body):execute()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    -- When the caller flips the task to abandoned, the row update alone is
    -- not enough — the running dataflow keeps executing, auto-forks new
    -- changesets, and flushes FS edits to disk. abandon_task cancels the
    -- dataflows, drops the active changeset, and releases the lock so the
    -- task actually stops.
    local cleanup
    local pumped_next
    if body.status == "abandoned" then
        cleanup = abandon.abandon_task(task_id, { reason = "abandoned via update_task API" })
        -- The serial queue lock is now free; promote the next pending
        -- spec task through the same process-backed handoff used by phase
        -- completion. Best-effort — failure here doesn't affect abandon.
        local ok = lifecycle.request_queue_pump(actor:id())
        if ok then pumped_next = "requested" end
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    local resp = { success = true, task_id = task_id }
    if cleanup then resp.cleanup = cleanup end
    if pumped_next then resp.queue_promoted = pumped_next end
    res:write_json(resp)
end

return { handler = handler }
