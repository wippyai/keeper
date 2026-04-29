local http = require("http")

local client = require("client")
local security = require("security")
-- POST /keeper/workspaces/:id/edits
-- Body shapes (discriminated by "kind"):
--   { kind = "registry_set", entry = { id, kind, definition, content?, attributes? } }
--   { kind = "registry_delete", entry_id = "..." }
--   { kind = "fs_write", rel_path = "foo/Button.vue", content = "..." }
--   { kind = "fs_delete", rel_path = "foo/Button.vue" }
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

    local changeset_id = req:param("id") or req:query("id")
    if not changeset_id or changeset_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "workspace id is required" })
        return
    end

    local body = req:body_json()
    if not body or not body.kind then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "kind is required in request body" })
        return
    end

    local result, err = client.edit({
        changeset_id = changeset_id,
        kind         = body.kind,
        entry        = body.entry,
        entry_id     = body.entry_id,
        rel_path     = body.rel_path,
        content      = body.content,
        actor_id     = actor:id(),
    })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, result = result })
end

return { handler = handler }
