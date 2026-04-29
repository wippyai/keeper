local cs_consts = require("cs_consts")

local M = {}

M.TARGETS = {
    ENTRY = "entry",
    FS    = "fs",
}

M.OPS = {
    CREATE      = "create",
    UPDATE      = "update",
    DELETE      = "delete",
    STR_REPLACE = "str_replace",
    VIEW        = "view",
    REWRITE     = "rewrite",
    SET         = "set",
}

M.ERR = {
    INVALID_PATCH      = "INVALID_PATCH",
    INVALID_TARGET     = "INVALID_TARGET",
    INVALID_OP         = "INVALID_OP",
    MISSING_FIELD      = "MISSING_FIELD",
    NO_CHANGESET       = "NO_CHANGESET",
    NO_BRANCH          = "NO_BRANCH",
    READ_FAILED        = "READ_FAILED",
    APPLY_FAILED       = "APPLY_FAILED",
    NOT_FOUND          = "NOT_FOUND",
    ALREADY_EXISTS     = "ALREADY_EXISTS",
    REPLACE_FAILED     = "REPLACE_FAILED",
    PARSE_FAILED       = "PARSE_FAILED",
    VALIDATION_FAILED  = "VALIDATION_FAILED",
}

M.SOURCES         = cs_consts.SOURCES
M.CHANGE_STATUSES = cs_consts.CHANGE_STATUSES
M.EDIT_KINDS      = cs_consts.EDIT_KINDS

M.FE_PREFIX = "frontend/"
M.PLUGIN_FRONTEND_PATTERN = "^plugins/[^/]+/frontend/"

return M
