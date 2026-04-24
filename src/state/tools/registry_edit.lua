local cs_client = require("cs_client")
local cs_consts = require("cs_consts")

local EDIT_KINDS = cs_consts.EDIT_KINDS
local EDIT_TIMEOUT = "10s"

local M = {}

M.EDIT_TIMEOUT = EDIT_TIMEOUT

function M.registry_set(changeset_id, entry_id, kind, definition, content)
    if not changeset_id or changeset_id == "" then
        return nil, "no active changeset"
    end
    return cs_client.edit({
        changeset_id = changeset_id,
        kind         = EDIT_KINDS.REGISTRY_SET,
        entry        = {
            id         = entry_id,
            kind       = kind,
            definition = definition,
            content    = content,
        },
    }, EDIT_TIMEOUT)
end

function M.registry_delete(changeset_id, entry_id)
    if not changeset_id or changeset_id == "" then
        return nil, "no active changeset"
    end
    return cs_client.edit({
        changeset_id = changeset_id,
        kind         = EDIT_KINDS.REGISTRY_DELETE,
        entry_id     = entry_id,
    }, EDIT_TIMEOUT)
end

return M
