local kb_repo = require("kb_repo")

local M = {}

function M.resolve_kb_id(params)
    if not params.kb then return nil end
    local kb = kb_repo.resolve_kb(params.kb)
    if not kb then return nil, "Knowledge base not found: " .. params.kb end
    return kb.id
end

return M
