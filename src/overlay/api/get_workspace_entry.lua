local http = require("http")
local security = require("security")
local workspace_session = require("workspace_session")

local function handler()
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

    local user_id = actor:id()

    local workspace_id = req:param("id")
    if not workspace_id or workspace_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing workspace ID in path"
        })
        return
    end

    local entry_id = req:param("entry_id")
    if not entry_id or entry_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing entry ID in path"
        })
        return
    end

    local session, session_err = workspace_session.open(workspace_id, user_id)
    if session_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to open workspace session: " .. session_err
        })
        return
    end

    local merged_entry, merged_err = session:get(entry_id)
    local original_entry, _ = session:get_original(entry_id)
    local workspace_entry, _ = session:get_workspace(entry_id)
    local has_override = session:has_override(entry_id)

    if merged_err then
        local status = http.STATUS.INTERNAL_ERROR
        if merged_err:match("not found") then
            status = http.STATUS.NOT_FOUND
        elseif merged_err:match("access denied") or merged_err:match("insufficient permissions") then
            status = http.STATUS.FORBIDDEN
        end

        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = merged_err
        })
        return
    end

    -- Ensure entry_meta is included in workspace_entry if it exists
    if workspace_entry and not workspace_entry.entry_meta then
        workspace_entry.entry_meta = {}
    end

    res:set_content_type(http.STATUS.OK)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        entry_id = entry_id,
        views = {
            merged = merged_entry,
            original = original_entry,
            workspace = workspace_entry
        },
        has_override = has_override
    })
end

return {
    handler = handler
}