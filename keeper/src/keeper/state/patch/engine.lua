local text = require("text")
local yaml = require("yaml")
local cs_client = require("cs_client")
local cs_consts = require("cs_consts")
local state_reader = require("state_reader")
local materialize = require("materialize")
local gov_consts = require("gov_consts")
local branch_ctx = require("branch_ctx")
local entry_lib = require("entry_lib")
local function_config = require("function_config")
local patch_consts = require("patch_consts")
local patch_validate = require("patch_validate")

local M = {}

local TARGETS  = patch_consts.TARGETS
local OPS      = patch_consts.OPS
local ERR      = patch_consts.ERR
local EDIT_KINDS = cs_consts.EDIT_KINDS
local EDIT_TIMEOUT = "10s"
local MAX_FS_BYTES = 512 * 1024

local validate_entry_id          = entry_lib.validate_entry_id
local extract_kind_from_definition = entry_lib.extract_kind_from_definition
local validate_function_config   = function_config.validate
local resolve_changeset_id       = branch_ctx.resolve_changeset_id
local get_active_branch          = branch_ctx.get_active_branch
local get_active_branch_chain    = branch_ctx.get_active_branch_chain

type RegistryEntry = {
    id: string,
    kind: string,
    meta: {[string]: unknown}?,
    data: {[string]: unknown}?,
}

type FileConfig = {
    extension: string?,
    source_field: string?,
}

type MaterializedEntry = {
    definition: string,
    content: string?,
    attributes: {[string]: unknown}?,
}

type MaterializeModule = {
    entry: (RegistryEntry) -> (MaterializedEntry?, string?),
    get_file_config: (RegistryEntry) -> FileConfig?,
}

local materializer = materialize :: MaterializeModule

local function err(code, message, fix_hint)
    return { code = code, message = message, fix_hint = fix_hint }
end

local function registry_set(changeset_id, entry_id, kind, definition, content)
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

local function registry_delete(changeset_id, entry_id)
    return cs_client.edit({
        changeset_id = changeset_id,
        kind         = EDIT_KINDS.REGISTRY_DELETE,
        entry_id     = entry_id,
    }, EDIT_TIMEOUT)
end

local function fs_write(changeset_id, rel_path, content)
    return cs_client.edit({
        changeset_id = changeset_id,
        kind         = EDIT_KINDS.FS_WRITE,
        rel_path     = rel_path,
        content      = content,
    }, EDIT_TIMEOUT)
end

local function fs_delete_op(changeset_id, rel_path)
    return cs_client.edit({
        changeset_id = changeset_id,
        kind         = EDIT_KINDS.FS_DELETE,
        rel_path     = rel_path,
    }, EDIT_TIMEOUT)
end

local function perform_text_replacement(content: string, old_str: string, new_str: string)
    local differ, derr = text.diff.new({
        diff_timeout = 5.0,
        match_threshold = 0.3,
        match_distance = 1000,
        patch_margin = 4
    })
    if derr then
        return nil, "Failed to create text differ: " .. derr
    end

    local exact_start, exact_end = content:find(old_str, 1, true)
    if exact_start then
        local second_exact = content:find(old_str, (exact_end or 0) + 1, true)
        if second_exact then
            local _, count = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), old_str)
            return nil, string.format(
                "Error: Found %d matches for replacement text. Please provide more context to make a unique match.\n\nSearched for:\n%s",
                count, old_str:sub(1, 200))
        end
        return content:sub(1, (exact_start or 0) - 1) .. new_str .. content:sub((exact_end or 0) + 1), nil
    end

    local target_content = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), new_str, 1)
    if target_content == content then
        local search_preview = old_str:sub(1, 200)
        local content_preview = content:sub(1, 300)
        local old_first_line = old_str:match("([^\n]+)") or ""
        local similar_pos = content:find(old_first_line, 1, true)
        local similarity_hint = ""
        if similar_pos then
            local pos = tonumber(similar_pos) or 0
            local context_start = math.max(1, pos - 50)
            local context_end = math.min(#content, pos + #old_first_line + 50)
            similarity_hint = "\n\nFound similar text near position " .. similar_pos .. ":\n" ..
                content:sub(context_start, context_end)
        end
        return nil, string.format(
            "Error: No match found.\n\nSearched for:\n%s%s\n\nContent starts with:\n%s%s",
            search_preview, #old_str > 200 and "..." or "", content_preview, similarity_hint)
    end

    local patches, perr = differ:patch_make(tostring(content), tostring(target_content))
    if perr then
        return nil, "Failed to create patches: " .. perr
    end
    if not patches or #patches == 0 then
        return nil, "No changes detected"
    end
    local result, ok = differ:patch_apply(patches, tostring(content))
    if not ok then
        return nil, "Fuzzy patch application failed"
    end
    if result == content then
        return nil, "No actual changes made"
    end
    return result, nil
end

local function parse_file_text(file_text)
    if not file_text or file_text == "" then
        return nil, nil, "file_text is empty"
    end

    local def_start = file_text:find("<definition>", 1, true)
    local def_end = file_text:find("</definition>", 1, true)
    if not def_start or not def_end then
        return nil, nil, "file_text missing <definition> tags"
    end
    if def_end <= def_start + 12 then
        return nil, nil, "<definition> block is empty"
    end

    local definition = file_text:sub(def_start + 12, def_end - 1):match("^%s*(.-)%s*$")

    local src_start = file_text:find("<source", def_end + 13, true)
    local content = nil
    if src_start then
        local src_tag_end = file_text:find(">", src_start, true)
        if not src_tag_end then
            return nil, nil, "Malformed <source> tag"
        end
        local src_close = file_text:find("</source>", src_tag_end + 1, true)
        local after_tag
        if src_close then
            after_tag = file_text:sub(src_tag_end + 1, src_close - 1)
        else
            after_tag = file_text:sub(src_tag_end + 1)
        end
        content = after_tag:match("^%s*(.-)%s*$")
    end

    return definition, content, nil
end

local function format_lines(formatted, view_range, raw_mode)
    if view_range and type(view_range) == "table" and #view_range == 2 then
        local start_line = tonumber(view_range[1])
        local end_line = tonumber(view_range[2])
        if start_line and end_line and start_line > 0 then
            local lines = {}
            local line_num = 1
            for line in (formatted .. "\n"):gmatch("([^\n]*)\n") do
                if line_num >= start_line and (end_line == -1 or line_num <= end_line) then
                    if raw_mode then
                        table.insert(lines, line)
                    else
                        table.insert(lines, line_num .. ": " .. line)
                    end
                end
                line_num = line_num + 1
                if end_line ~= -1 and line_num > end_line then break end
            end
            return table.concat(lines, "\n")
        end
    end
    if raw_mode then return formatted end
    local lines = {}
    local line_num = 1
    for line in (formatted .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line_num .. ": " .. line)
        line_num = line_num + 1
    end
    return table.concat(lines, "\n")
end

local function view_entry(patch)
    local namespace, name = validate_entry_id(patch.id)
    if not namespace then
        return nil, err(ERR.INVALID_TARGET, name)
    end

    local branches = get_active_branch_chain()
    local reader, rerr = state_reader.for_branch(unpack(branches))
    if rerr then
        return nil, err(ERR.READ_FAILED, rerr)
    end
    reader = reader:with_entries(patch.id):include_chunks()

    local entries, lerr = reader:all()
    if lerr then
        return nil, err(ERR.READ_FAILED, "Failed to read entry: " .. lerr)
    end
    if #entries == 0 then
        return nil, err(ERR.NOT_FOUND, "Entry not found: " .. patch.id)
    end

    local formatted = materialize.format_entry_structured(entries[1], false)
    if not formatted then
        return nil, err(ERR.READ_FAILED, "Failed to format entry")
    end

    return { content = format_lines(formatted, patch.view_range, patch.raw == true) }, nil
end

local function str_replace_entry(patch, branch, changeset_id)
    local namespace, name = validate_entry_id(patch.id)
    if not namespace then
        return nil, err(ERR.INVALID_TARGET, name)
    end

    local branches = get_active_branch_chain()
    local reader, rerr = state_reader.for_branch(unpack(branches))
    if rerr then
        return nil, err(ERR.READ_FAILED, rerr)
    end
    reader = reader:with_entries(patch.id):include_chunks()

    local entries, lerr = reader:all()
    if lerr then
        return nil, err(ERR.READ_FAILED, "Failed to read entry: " .. lerr)
    end
    if #entries == 0 then
        return nil, err(ERR.NOT_FOUND, "Entry not found: " .. patch.id)
    end

    local entry = entries[1]
    local definition_content, source_content
    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then definition_content = chunk.content
            elseif chunk.type == "content" then source_content = chunk.content end
        end
    end
    if not definition_content then
        return nil, err(ERR.READ_FAILED, "Entry has no definition chunk")
    end

    local inner_definition = definition_content
    local entries_pos = definition_content:find("entries:", 1, true)
    if entries_pos then
        local entry_lines = {}
        local after = definition_content:sub(entries_pos + 8)
        for line in after:gmatch("[^\n]+") do
            if line:match("^%s*#") then
            elseif line:match("^  %- ") then
                table.insert(entry_lines, line:sub(5))
            elseif line:match("^    ") then
                table.insert(entry_lines, line:sub(5))
            end
        end
        inner_definition = table.concat(entry_lines, "\n")
    end

    local function strip_wrappers(s)
        s = s:gsub("^<definition>\n", ""):gsub("\n</definition>$", "")
        s = s:gsub("^<source[^>]*>\n", ""):gsub("\n</source>$", "")
        return s
    end

    local applied = 0
    for idx, item in ipairs(patch.replace) do
        local old_str = strip_wrappers(tostring(item.old))
        local new_str = strip_wrappers(tostring(item.new))

        local in_source = source_content and source_content:find(old_str, 1, true)
        local in_definition = inner_definition:find(old_str, 1, true)
        if not in_definition then
            in_definition = definition_content:find(old_str, 1, true)
        end

        if in_definition and in_source then
            return nil, err(ERR.REPLACE_FAILED, string.format(
                "replace[%d]: Text appears in both definition and source. Please be more specific.\n\nSearched for:\n%s",
                idx, old_str:sub(1, 200)))
        end
        if not in_definition and not in_source then
            local formatted = materialize.format_entry_structured(entry, false) or ""
            return nil, err(ERR.REPLACE_FAILED, string.format(
                "replace[%d]: No match found in entry.\n\nSearched for:\n%s%s\n\nUse view first to see current content.\n\nEntry content:\n%s",
                idx, old_str:sub(1, 200), #old_str > 200 and "..." or "", formatted:sub(1, 600)))
        end

        if in_source then
            local new_content, repl_err = perform_text_replacement(source_content :: string, old_str, new_str)
            if repl_err then
                return nil, err(ERR.REPLACE_FAILED, "replace[" .. idx .. "] source: " .. repl_err)
            end
            source_content = new_content
        else
            local new_definition, repl_err = perform_text_replacement(definition_content, old_str, new_str)
            if repl_err then
                local new_inner, inner_err = perform_text_replacement(inner_definition, old_str, new_str)
                if inner_err then
                    return nil, err(ERR.REPLACE_FAILED, "replace[" .. idx .. "] definition: " .. inner_err)
                end
                local header = definition_content:match("^(.-entries:%s*\n)")
                if not header then
                    return nil, err(ERR.REPLACE_FAILED, "replace[" .. idx .. "] definition: cannot re-wrap")
                end
                local comment_line = "  # " .. patch.id .. "\n"
                local indented_lines = {}
                local marker_placed = false
                for line in (new_inner .. "\n"):gmatch("([^\n]*)\n") do
                    if line == "" then
                        table.insert(indented_lines, "")
                    elseif not marker_placed then
                        table.insert(indented_lines, "  - " .. line)
                        marker_placed = true
                    else
                        table.insert(indented_lines, "    " .. line)
                    end
                end
                new_definition = header .. comment_line .. table.concat(indented_lines, "\n")
            end
            definition_content = new_definition
            inner_definition = definition_content
            local entries_anchor = definition_content:find("entries:", 1, true)
            if entries_anchor then
                local body_lines = {}
                local after = definition_content:sub(entries_anchor + 8)
                for ln in after:gmatch("[^\n]+") do
                    if ln:match("^%s*#") then
                    elseif ln:match("^  %- ") then
                        table.insert(body_lines, ln:sub(5))
                    elseif ln:match("^    ") then
                        table.insert(body_lines, ln:sub(5))
                    end
                end
                inner_definition = table.concat(body_lines, "\n")
            end
            local parsed_entry, parse_yaml_err = yaml.decode(inner_definition)
            if not parse_yaml_err and type(parsed_entry) == "table" then
                local cfg_err = validate_function_config(parsed_entry, source_content)
                if cfg_err then
                    return nil, err(ERR.VALIDATION_FAILED, "replace[" .. idx .. "]: " .. cfg_err)
                end
            end
        end

        applied = applied + 1
    end

    local kind, kind_err = extract_kind_from_definition(definition_content)
    if kind_err then
        return nil, err(ERR.PARSE_FAILED, kind_err)
    end

    local _, save_err = registry_set(changeset_id, patch.id, kind, definition_content, source_content)
    if save_err then
        return nil, err(ERR.APPLY_FAILED, "Failed to save: " .. tostring(save_err))
    end

    return { applied = true, target = "entry", op = OPS.STR_REPLACE, replacements = applied }, nil
end

local function create_entry(patch, branch, changeset_id)
    local patch_id = type(patch.id) == "string" and patch.id or ""
    local namespace, name = validate_entry_id(patch_id)
    if not namespace then
        return nil, err(ERR.INVALID_TARGET, name)
    end

    if not gov_consts.is_namespace_managed(namespace) then
        local managed = table.concat(gov_consts.get_managed_namespaces(), ", ")
        return nil, err(ERR.VALIDATION_FAILED,
            "Cannot create entry in unmanaged namespace '" .. namespace ..
            "'. Managed namespaces: " .. managed ..
            ". Drop the overlay and start a clean changeset rather than authoring cleanup entries.")
    end

    local branches = get_active_branch_chain()
    local reader, rerr = state_reader.for_branch(unpack(branches))
    if rerr then
        return nil, err(ERR.READ_FAILED, rerr)
    end
    reader = reader:with_entries(patch_id)
    local existing, lerr = reader:all()
    if lerr then
        return nil, err(ERR.READ_FAILED, "Failed to check existing entries: " .. lerr)
    end
    if #existing > 0 then
        return nil, err(ERR.ALREADY_EXISTS,
            "Entry already exists: " .. patch_id .. ". Use str_replace to modify it, or delete it first.")
    end

    local definition_yaml, content, parse_err = parse_file_text(patch.file_text)
    if parse_err then
        return nil, err(ERR.PARSE_FAILED, "Failed to parse file_text: " .. parse_err)
    end

    local parsed_entry, yaml_err = yaml.decode(definition_yaml)
    if yaml_err then
        return nil, err(ERR.PARSE_FAILED, "Failed to parse entry YAML: " .. yaml_err)
    end
    if not parsed_entry.name or not parsed_entry.kind then
        return nil, err(ERR.VALIDATION_FAILED, "Entry YAML missing required fields: name and kind")
    end
    if parsed_entry.name ~= name then
        return nil, err(ERR.VALIDATION_FAILED,
            "Entry name mismatch: expected '" .. name .. "', got '" .. parsed_entry.name .. "'")
    end

    local cfg_err = validate_function_config(parsed_entry, content)
    if cfg_err then
        return nil, err(ERR.VALIDATION_FAILED, cfg_err)
    end

    local parsed_kind = type(parsed_entry.kind) == "string" and parsed_entry.kind or ""
    local parsed_meta = type(parsed_entry.meta) == "table" and (parsed_entry.meta :: {[string]: unknown}) or nil
    local registry_entry: RegistryEntry = {
        id = patch_id, kind = parsed_kind, meta = parsed_meta, data = {}
    }
    for k, v in pairs(parsed_entry) do
        if type(k) == "string" and k ~= "name" and k ~= "kind" and k ~= "meta" then
            registry_entry.data[k] = v
        end
    end
    if content and content ~= "" then
        local config = materializer.get_file_config(registry_entry)
        if config and config.source_field then
            registry_entry.data[config.source_field] = content
        end
    end

    local materialized, mat_err = materializer.entry(registry_entry)
    if mat_err then
        return nil, err(ERR.VALIDATION_FAILED, "Failed to materialize entry: " .. mat_err)
    end

    local parsed_def, parse_def_err = yaml.decode(materialized.definition)
    if parse_def_err then
        return nil, err(ERR.PARSE_FAILED, "Generated invalid YAML: " .. parse_def_err ..
            "\n\nGenerated definition:\n" .. materialized.definition)
    end
    if not parsed_def.entries or #parsed_def.entries == 0 then
        return nil, err(ERR.VALIDATION_FAILED, "Generated definition has no entries array\n\nGenerated definition:\n" ..
            materialized.definition)
    end

    local _, save_err = registry_set(
        changeset_id, patch.id, registry_entry.kind,
        materialized.definition, materialized.content or content or "")
    if save_err then
        return nil, err(ERR.APPLY_FAILED, "Failed to create: " .. tostring(save_err))
    end

    return { applied = true, target = "entry", op = OPS.CREATE, id = patch.id }, nil
end

local function delete_entry(patch, branch, changeset_id)
    local namespace, name = validate_entry_id(patch.id)
    if not namespace then
        return nil, err(ERR.INVALID_TARGET, name)
    end

    local branches = get_active_branch_chain()
    local reader, rerr = state_reader.for_branch(unpack(branches))
    if rerr then
        return nil, err(ERR.READ_FAILED, rerr)
    end
    reader = reader:with_entries(patch.id):include_deleted()
    local existing, lerr = reader:all()
    if lerr then
        return nil, err(ERR.READ_FAILED, "Failed to check existing entry: " .. lerr)
    end
    if #existing == 0 then
        return nil, err(ERR.NOT_FOUND, "Entry does not exist on branch: " .. patch.id)
    end
    if existing[1].deleted == 1 then
        return { applied = true, target = "entry", op = OPS.DELETE, id = patch.id, already_deleted = true }, nil
    end

    local _, del_err = registry_delete(changeset_id, patch.id)
    if del_err then
        return nil, err(ERR.APPLY_FAILED, "Failed to delete: " .. tostring(del_err))
    end

    return { applied = true, target = "entry", op = OPS.DELETE, id = patch.id }, nil
end

local function open_fs_view(changeset_id)
    local fs_view = require("fs_view")
    local view, verr = fs_view.open(changeset_id)
    if verr then return nil, err(ERR.READ_FAILED, "fs_view open failed: " .. tostring(verr)) end
    return view, nil
end

local function view_fs(patch)
    local path = type(patch.path) == "string" and patch.path or ""
    if path == "" then return nil, err(ERR.MISSING_FIELD, "fs view requires path") end
    local changeset_id = resolve_changeset_id()
    if not changeset_id then
        local fs = require("fs")
        local project_fs, ferr = fs.get(cs_consts.FS.PROJECT_VOLUME)
        if ferr then return nil, err(ERR.READ_FAILED, "project_fs open failed: " .. tostring(ferr)) end
        if not project_fs:exists(path) then return nil, err(ERR.NOT_FOUND, "not found: " .. path) end
        local content = project_fs:readfile(path)
        return { content = format_lines(content, patch.view_range, patch.raw == true) }, nil
    end
    local view, verr = open_fs_view(changeset_id)
    if verr then return nil, verr end
    local content, rerr = view:read(path)
    if rerr then return nil, err(ERR.READ_FAILED, rerr) end
    if not content then return nil, err(ERR.NOT_FOUND, "not found: " .. path) end
    return { content = format_lines(content, patch.view_range, patch.raw == true) }, nil
end

local function create_fs(patch, branch, changeset_id)
    local path = type(patch.path) == "string" and patch.path or ""
    if #patch.content > MAX_FS_BYTES then
        return nil, err(ERR.VALIDATION_FAILED,
            "content exceeds " .. MAX_FS_BYTES .. " bytes (" .. #patch.content .. ")")
    end
    local view, verr = open_fs_view(changeset_id)
    if verr then return nil, verr end
    local exists = view:exists(path)
    if exists then
        return nil, err(ERR.ALREADY_EXISTS, "already exists: " .. path .. " — use rewrite or str_replace")
    end
    local result, werr = fs_write(changeset_id, path, patch.content)
    if werr then return nil, err(ERR.APPLY_FAILED, "fs create failed: " .. tostring(werr)) end
    return {
        applied = true, target = "fs", op = OPS.CREATE, path = path,
        bytes = #patch.content, content_hash = (result and result.current_hash) or "",
    }, nil
end

local function rewrite_fs(patch, branch, changeset_id)
    if #patch.content > MAX_FS_BYTES then
        return nil, err(ERR.VALIDATION_FAILED,
            "content exceeds " .. MAX_FS_BYTES .. " bytes (" .. #patch.content .. ")")
    end
    local result, werr = fs_write(changeset_id, patch.path, patch.content)
    if werr then return nil, err(ERR.APPLY_FAILED, "fs rewrite failed: " .. tostring(werr)) end
    return {
        applied = true, target = "fs", op = OPS.REWRITE, path = patch.path,
        bytes = #patch.content, content_hash = (result and result.current_hash) or "",
    }, nil
end

local function str_replace_fs(patch, branch, changeset_id)
    local path = type(patch.path) == "string" and patch.path or ""
    local old_str = type(patch.old_str) == "string" and patch.old_str or ""
    local new_str = type(patch.new_str) == "string" and patch.new_str or ""
    local view, verr = open_fs_view(changeset_id)
    if verr then return nil, verr end
    local current, rerr = view:read(path)
    if rerr then return nil, err(ERR.READ_FAILED, rerr) end
    if not current then return nil, err(ERR.NOT_FOUND, "not found: " .. path) end

    local updated, repl_err = perform_text_replacement(current :: string, old_str, new_str)
    if repl_err then return nil, err(ERR.REPLACE_FAILED, repl_err) end

    if #updated > MAX_FS_BYTES then
        return nil, err(ERR.VALIDATION_FAILED,
            "result exceeds " .. MAX_FS_BYTES .. " bytes after replacement")
    end

    local result, werr = fs_write(changeset_id, path, updated)
    if werr then return nil, err(ERR.APPLY_FAILED, "fs str_replace failed: " .. tostring(werr)) end
    return {
        applied = true, target = "fs", op = OPS.STR_REPLACE, path = patch.path,
        bytes = #updated, content_hash = (result and result.current_hash) or "",
    }, nil
end

local function delete_fs(patch, branch, changeset_id)
    local view, verr = open_fs_view(changeset_id)
    if verr then return nil, verr end
    if not view:exists(patch.path) then
        return nil, err(ERR.NOT_FOUND, "not found: " .. patch.path)
    end
    local _, derr = fs_delete_op(changeset_id, patch.path)
    if derr then return nil, err(ERR.APPLY_FAILED, "fs delete failed: " .. tostring(derr)) end
    return { applied = true, target = "fs", op = OPS.DELETE, path = patch.path }, nil
end

local function set_entry(patch, branch, changeset_id)
    local _, save_err = registry_set(changeset_id, patch.id, patch.kind, patch.definition, patch.content)
    if save_err then
        return nil, err(ERR.APPLY_FAILED, "Failed to set: " .. tostring(save_err))
    end
    return { applied = true, target = "entry", op = OPS.SET, id = patch.id, kind = patch.kind }, nil
end

local ENTRY_DISPATCH = {
    [OPS.VIEW]        = function(p, _b, _c) return view_entry(p) end,
    [OPS.CREATE]      = create_entry,
    [OPS.STR_REPLACE] = str_replace_entry,
    [OPS.DELETE]      = delete_entry,
    [OPS.SET]         = set_entry,
}

local FS_DISPATCH = {
    [OPS.VIEW]        = function(p, _b, _c) return view_fs(p) end,
    [OPS.CREATE]      = create_fs,
    [OPS.REWRITE]     = rewrite_fs,
    [OPS.STR_REPLACE] = str_replace_fs,
    [OPS.DELETE]      = delete_fs,
}

function M.apply_one(patch, opts)
    opts = opts or {}

    local validated, verr = patch_validate.validate(patch)
    if not validated then
        return nil, verr
    end
    patch = validated

    local needs_cs = patch.op ~= OPS.VIEW
    local branch = opts.branch or get_active_branch()
    local changeset_id = opts.changeset_id

    if needs_cs then
        if branch == "main" then
            return nil, err(ERR.NO_BRANCH,
                "Cannot modify main branch (set branch first)",
                "call set_branch with a feature branch name")
        end
        if not changeset_id then
            local cs_id, cs_err = resolve_changeset_id(branch)
            if not cs_id then
                return nil, err(ERR.NO_CHANGESET,
                    "no active changeset for branch '" .. tostring(branch) .. "' (" ..
                    tostring(cs_err or "missing changeset_id") .. ")",
                    "call set_branch to open or resume a workspace before mutating")
            end
            changeset_id = cs_id
        end
    end

    local dispatch = (patch.target == TARGETS.ENTRY) and ENTRY_DISPATCH or FS_DISPATCH
    local handler = dispatch[patch.op]
    if not handler then
        return nil, err(ERR.INVALID_OP,
            "no handler for " .. patch.target .. "/" .. patch.op)
    end

    return handler(patch, branch, changeset_id)
end

return M
