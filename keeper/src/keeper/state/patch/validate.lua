local consts = require("patch_consts")

local M = {}

local TARGETS  = consts.TARGETS
local OPS      = consts.OPS
local ERR      = consts.ERR
local FE_PREFIX = consts.FE_PREFIX
local PLUGIN_FRONTEND_PATTERN = consts.PLUGIN_FRONTEND_PATTERN

local ENTRY_OPS = {
    [OPS.CREATE]      = true,
    [OPS.STR_REPLACE] = true,
    [OPS.DELETE]      = true,
    [OPS.VIEW]        = true,
    [OPS.SET]         = true,
}

local FS_OPS = {
    [OPS.CREATE]      = true,
    [OPS.REWRITE]     = true,
    [OPS.DELETE]      = true,
    [OPS.VIEW]        = true,
    [OPS.STR_REPLACE] = true,
}

local function err(code, message, fix_hint)
    return { code = code, message = message, fix_hint = fix_hint }
end

local function validate_entry(patch)
    local id = patch.id
    if type(id) ~= "string" or id == "" then
        return nil, err(ERR.MISSING_FIELD,
            "entry patch requires 'id' (string)",
            "set patch.id = 'namespace:name'")
    end
    if not id:find(":", 1, true) then
        return nil, err(ERR.INVALID_TARGET,
            "entry id must be 'namespace:name', got '" .. id .. "'",
            "example: 'keeper.state.tools:edit'")
    end

    local op = patch.op
    if not op or op == "" then
        return nil, err(ERR.MISSING_FIELD,
            "entry patch requires 'op'",
            "op is one of: create, str_replace, delete, view")
    end
    if not ENTRY_OPS[op] then
        return nil, err(ERR.INVALID_OP,
            "invalid entry op '" .. tostring(op) .. "'",
            "entry ops: create, str_replace, delete, view")
    end

    if op == OPS.CREATE then
        if type(patch.file_text) ~= "string" or patch.file_text == "" then
            return nil, err(ERR.MISSING_FIELD,
                "entry create requires 'file_text' (string)",
                "file_text wraps definition+source: '<definition>...</definition>[<source>...</source>]'")
        end
    elseif op == OPS.SET then
        if type(patch.kind) ~= "string" or patch.kind == "" then
            return nil, err(ERR.MISSING_FIELD,
                "entry set requires 'kind' (string)",
                "set is a system primitive — pass already-materialized {kind, definition, content}")
        end
        if type(patch.definition) ~= "string" then
            return nil, err(ERR.MISSING_FIELD,
                "entry set requires 'definition' (string)",
                "pass the materialized YAML definition")
        end
    elseif op == OPS.STR_REPLACE then
        if type(patch.replace) ~= "table" or #patch.replace == 0 then
            return nil, err(ERR.MISSING_FIELD,
                "entry str_replace requires 'replace' (non-empty array of {old,new})",
                "replace = { { old = '...', new = '...' } }")
        end
        for i, item in ipairs(patch.replace) do
            if type(item) ~= "table" then
                return nil, err(ERR.INVALID_PATCH,
                    "replace[" .. i .. "] must be an object {old, new}",
                    "each replace item is { old = '...', new = '...' }")
            end
            if type(item.old) ~= "string" then
                return nil, err(ERR.MISSING_FIELD,
                    "replace[" .. i .. "].old must be a string",
                    "old is the literal text being matched in the entry")
            end
            if type(item.new) ~= "string" then
                return nil, err(ERR.MISSING_FIELD,
                    "replace[" .. i .. "].new must be a string",
                    "new replaces 'old'; use empty string to delete the matched text")
            end
        end
    end

    return patch, nil
end

local function validate_fs(patch)
    local path = patch.path
    if type(path) ~= "string" or path == "" then
        return nil, err(ERR.MISSING_FIELD,
            "fs patch requires 'path' (string)",
            "set patch.path = 'frontend/applications/.../file.ts' or 'plugins/<module>/frontend/.../file.ts'")
    end
    if path:sub(1, #FE_PREFIX) ~= FE_PREFIX and not path:match(PLUGIN_FRONTEND_PATTERN) then
        return nil, err(ERR.INVALID_TARGET,
            "fs path must start with '" .. FE_PREFIX .. "' or match plugins/<module>/frontend/, got '" .. path .. "'",
            "all fs writes go through host or local-module frontend roots")
    end
    if path:find("%.%.") then
        return nil, err(ERR.INVALID_TARGET,
            "fs path must not contain '..'",
            "use a clean relative path under frontend/")
    end

    local op = patch.op
    if not op or op == "" then
        return nil, err(ERR.MISSING_FIELD,
            "fs patch requires 'op'",
            "fs ops: create, rewrite, delete, view")
    end
    if not FS_OPS[op] then
        return nil, err(ERR.INVALID_OP,
            "invalid fs op '" .. tostring(op) .. "'",
            "fs ops: create, rewrite, delete, view")
    end

    if op == OPS.CREATE or op == OPS.REWRITE then
        if type(patch.content) ~= "string" then
            return nil, err(ERR.MISSING_FIELD,
                "fs " .. op .. " requires 'content' (string)",
                "content is the full file body to write")
        end
    elseif op == OPS.STR_REPLACE then
        if type(patch.old_str) ~= "string" then
            return nil, err(ERR.MISSING_FIELD,
                "fs str_replace requires 'old_str' (string)",
                "literal text to find in the file")
        end
        if type(patch.new_str) ~= "string" then
            return nil, err(ERR.MISSING_FIELD,
                "fs str_replace requires 'new_str' (string)",
                "replacement text; empty string deletes")
        end
    end

    return patch, nil
end

function M.validate(patch)
    if type(patch) ~= "table" then
        return nil, err(ERR.INVALID_PATCH,
            "patch must be a table",
            "shape: {target, op, ...}")
    end

    local target = patch.target
    if not target or target == "" then
        return nil, err(ERR.MISSING_FIELD,
            "patch.target is required",
            "target must be 'entry' or 'fs'")
    end
    if target ~= TARGETS.ENTRY and target ~= TARGETS.FS then
        return nil, err(ERR.INVALID_TARGET,
            "invalid target '" .. tostring(target) .. "'",
            "target must be 'entry' or 'fs'")
    end

    if target == TARGETS.ENTRY then
        return validate_entry(patch)
    end
    return validate_fs(patch)
end

return M
