local http = require("http")
local security = require("security")
local reader = require("reader")

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

    local include_entries = req:query("include_entries") == "true"
    local include_permissions = req:query("include_permissions") == "true"
    local include_reviews = req:query("include_reviews") == "true"
    local include_ops = req:query("include_ops") == "true"
    local include_context = req:query("include_context") == "true"

    local workspace_reader, reader_err = reader.for_user(user_id)
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to create workspace reader: " .. reader_err
        })
        return
    end

    workspace_reader = workspace_reader:with_workspaces(workspace_id)

    if include_entries then
        workspace_reader = workspace_reader:include_entries()
    end

    if include_permissions then
        workspace_reader = workspace_reader:include_permissions()
    end

    if include_reviews then
        workspace_reader = workspace_reader:include_reviews()
    end

    if include_ops then
        workspace_reader = workspace_reader:include_ops()
    end

    local workspace, err = workspace_reader:one()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve workspace: " .. err
        })
        return
    end

    if not workspace then
        res:set_status(http.STATUS.NOT_FOUND)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Workspace not found"
        })
        return
    end

    -- Fetch contexts if requested
    local contexts = nil
    if include_context then
        local context_reader, reader_err = reader.for_context(workspace_id)
        if reader_err then
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Failed to create context reader: " .. reader_err
            })
            return
        end

        local context_list, context_err = context_reader:all()
        if context_err then
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Failed to retrieve workspace contexts: " .. context_err
            })
            return
        end
        contexts = context_list
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    local response = {
        success = true,
        workspace = workspace
    }
    if contexts then
        response.contexts = contexts
    end
    res:write_json(response)
end

return {
    handler = handler
}