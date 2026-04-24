local text = require("text")
local yaml = require("yaml")
local state_reader = require("state_reader")
local materialize = require("materialize")
local gov_consts = require("gov_consts")
local audit = require("audit")
local branch_ctx = require("branch_ctx")
local entry_lib = require("entry_lib")
local registry_edit = require("registry_edit")
local function_config = require("function_config")

local resolve_changeset_id = branch_ctx.resolve_changeset_id
local get_active_branch = branch_ctx.get_active_branch
local get_active_branch_chain = branch_ctx.get_active_branch_chain
local validate_entry_id = entry_lib.validate_entry_id
local registry_set = registry_edit.registry_set
local registry_delete = registry_edit.registry_delete

local function perform_text_replacement(content: string, old_str: string, new_str: string)
    local differ, err = text.diff.new({
        diff_timeout = 5.0,
        match_threshold = 0.3,
        match_distance = 1000,
        patch_margin = 4
    })
    if err then
        return nil, "Failed to create text differ: " .. err
    end

    local exact_start, exact_end = content:find(old_str, 1, true)

    if exact_start then
        local second_exact = content:find(old_str, (exact_end or 0) + 1, true)
        if second_exact then
            local _, count = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), old_str)
            return nil, string.format(
                "Error: Found %d matches for replacement text. Please provide more context to make a unique match.\n\nSearched for:\n%s",
                count,
                old_str:sub(1, 200)
            )
        end

        return content:sub(1, (exact_start or 0) - 1) .. new_str .. content:sub((exact_end or 0) + 1), nil
    end

    local target_content = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), new_str, 1)

    if target_content == content then
        local preview_len = 300
        local search_preview = old_str:sub(1, 200)
        local content_preview = content:sub(1, preview_len)

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
            search_preview,
            #old_str > 200 and "..." or "",
            content_preview,
            similarity_hint
        )
    end

    local patches, err = differ:patch_make(tostring(content), tostring(target_content))
    if err then
        return nil, "Failed to create patches: " .. err
    end

    if not patches or #patches == 0 then
        return nil, "No changes detected"
    end

    local result, success = differ:patch_apply(patches, tostring(content))
    if not success then
        return nil, "Fuzzy patch application failed"
    end

    if result == content then
        return nil, "No actual changes made"
    end

    return result, nil
end

local extract_kind_from_definition = entry_lib.extract_kind_from_definition
local validate_function_config = function_config.validate

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

local function view_command(params)
    local namespace, name = validate_entry_id(params.path)
    if not namespace then
        return nil, name
    end

    local branches = get_active_branch_chain()

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:with_entries(params.path):include_chunks()

    local entries, err = reader:all()
    if err then
        return nil, "Failed to read entry: " .. err
    end

    if #entries == 0 then
        return nil, "Entry not found: " .. params.path
    end

    local entry = entries[1]
    local formatted = materialize.format_entry_structured(entry, false)

    if not formatted then
        return nil, "Failed to format entry"
    end

    local raw_mode = params.raw == true

    if params.view_range and type(params.view_range) == "table" and #params.view_range == 2 then
        local start_line = tonumber(params.view_range[1])
        local end_line = tonumber(params.view_range[2])

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
                if end_line ~= -1 and line_num > end_line then
                    break
                end
            end
            return table.concat(lines, "\n"), nil
        end
    end

    if raw_mode then
        return formatted, nil
    end

    local lines = {}
    local line_num = 1
    for line in (formatted .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line_num .. ": " .. line)
        line_num = line_num + 1
    end

    return table.concat(lines, "\n"), nil
end

local function str_replace_command(params, branch, changeset_id)
    if not params.old_str then
        return nil, "old_str required for str_replace"
    end

    if params.new_str == nil then
        return nil, "new_str required for str_replace"
    end

    local namespace, name = validate_entry_id(params.path)
    if not namespace then
        return nil, name
    end

    local branches = get_active_branch_chain()

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:with_entries(params.path):include_chunks()

    local entries, err = reader:all()
    if err then
        return nil, "Failed to read entry: " .. err
    end

    if #entries == 0 then
        return nil, "Entry not found: " .. params.path
    end

    local entry = entries[1]

    local definition_content = nil
    local source_content = nil

    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then
                definition_content = chunk.content
            elseif chunk.type == "content" then
                source_content = chunk.content
            end
        end
    end

    if not definition_content then
        return nil, "Entry has no definition chunk"
    end

    -- Match against the same formatted representation the agent sees via view,
    -- which is produced by materialize.format_entry_structured: unwraps the
    -- version/namespace/entries wrapper by dedenting 4 chars. Nested list items
    -- (`      - http` → `  - http`) keep their dashes so YAML stays valid.
    local inner_definition = definition_content
    local entries_pos = definition_content:find("entries:", 1, true)
    if entries_pos then
        local entry_lines = {}
        local after = definition_content:sub(entries_pos + 8)
        for line in after:gmatch("[^\n]+") do
            if line:match("^%s*#") then
                -- skip comments
            elseif line:match("^  %- ") then
                table.insert(entry_lines, line:sub(5))
            elseif line:match("^    ") then
                table.insert(entry_lines, line:sub(5))
            end
        end
        inner_definition = table.concat(entry_lines, "\n")
    end

    local old_str = tostring(params.old_str)
    local new_str = tostring(params.new_str)

    -- Agents often copy view output verbatim into old_str/new_str, including
    -- the <definition>/<source> wrapper tags. Strip them so the match works.
    local function strip_wrappers(s)
        s = s:gsub("^<definition>\n", ""):gsub("\n</definition>$", "")
        s = s:gsub("^<source[^>]*>\n", ""):gsub("\n</source>$", "")
        return s
    end
    old_str = strip_wrappers(old_str)
    new_str = strip_wrappers(new_str)

    local in_source = source_content and source_content:find(old_str, 1, true)
    local in_definition = inner_definition:find(old_str, 1, true)
    -- Also check raw definition as fallback
    if not in_definition then
        in_definition = definition_content:find(old_str, 1, true)
    end

    if in_definition and in_source then
        return nil, string.format(
            "Error: Text appears in both definition and source. Please be more specific.\n\nSearched for:\n%s",
            old_str:sub(1, 200)
        )
    end

    if not in_definition and not in_source then
        local formatted = materialize.format_entry_structured(entry, false) or ""
        return nil, string.format(
            "Error: No match found in entry.\n\nSearched for:\n%s%s\n\nUse view command first to see current content.\n\nEntry content:\n%s",
            old_str:sub(1, 200),
            #old_str > 200 and "..." or "",
            formatted:sub(1, 600)
        )
    end

    if in_source then
        local new_content, replace_err = perform_text_replacement(source_content :: string, old_str, new_str)
        if replace_err then
            return nil, "Source replacement failed: " .. replace_err
        end

        local kind, kind_err = extract_kind_from_definition(definition_content)
        if kind_err then
            return nil, kind_err
        end

        local _, save_err = registry_set(changeset_id, params.path, kind, definition_content, new_content)
        if save_err then
            return nil, "Failed to save: " .. save_err
        end

        return "Replaced text in source", nil
    else
        -- Replace in the raw definition (which includes wrapper)
        local new_definition, replace_err = perform_text_replacement(definition_content, old_str, new_str)
        if replace_err then
            -- Try replacing in inner definition and re-wrapping
            local new_inner, inner_err = perform_text_replacement(inner_definition, old_str, new_str)
            if inner_err then
                return nil, "Definition replacement failed: " .. inner_err
            end
            -- Re-wrap: prefix each line with 4 chars to restore the entry
            -- indent. First non-empty line gets `  - ` (entry list marker);
            -- the rest get `    ` so nested lists keep their relative indent.
            local header = definition_content:match("^(.-entries:%s*\n)")
            if header then
                local comment_line = "  # " .. params.path .. "\n"
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
            else
                return nil, "Definition replacement failed: cannot re-wrap"
            end
        end

        local kind, kind_err = extract_kind_from_definition(new_definition)
        if kind_err then
            return nil, kind_err
        end

        local inner_yaml = new_definition
        local entries_anchor = new_definition:find("entries:", 1, true)
        if entries_anchor then
            local body_lines = {}
            local after = new_definition:sub(entries_anchor + 8)
            for ln in after:gmatch("[^\n]+") do
                if ln:match("^%s*#") then
                    -- skip comments
                elseif ln:match("^  %- ") then
                    table.insert(body_lines, ln:sub(5))
                elseif ln:match("^    ") then
                    table.insert(body_lines, ln:sub(5))
                end
            end
            inner_yaml = table.concat(body_lines, "\n")
        end

        local parsed_entry, parse_yaml_err = yaml.decode(inner_yaml)
        if not parse_yaml_err and type(parsed_entry) == "table" then
            local cfg_err = validate_function_config(parsed_entry, source_content)
            if cfg_err then
                return nil, "Definition invalid after replacement: " .. cfg_err
            end
        end

        local _, save_err = registry_set(changeset_id, params.path, kind, new_definition, source_content)
        if save_err then
            return nil, "Failed to save: " .. save_err
        end

        return "Replaced text in definition", nil
    end
end

local function create_command(params, branch, changeset_id)
    if not params.file_text or params.file_text == "" then
        return nil, "file_text required for create"
    end

    local namespace, name = validate_entry_id(params.path)
    if not namespace then
        return nil, name
    end

    -- Reject new entries in namespaces governance does not manage. Without
    -- this check, agents recovering from a failed push improvise cleanup
    -- functions in `_cleanup` / `_admin` / `_temp`, which are themselves
    -- unmanaged — the next push fails the same way with more tombstones.
    -- Catching it here breaks the spiral at the first write.
    if not gov_consts.is_namespace_managed(namespace) then
        local managed = table.concat(gov_consts.get_managed_namespaces(), ", ")
        return nil, "Cannot create entry in unmanaged namespace '" .. namespace ..
            "'. Managed namespaces: " .. managed ..
            ". Drop the overlay and start a clean changeset rather than authoring cleanup entries."
    end

    local branches = get_active_branch_chain()
    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:with_entries(params.path)
    local existing_entries, err = reader:all()
    if err then
        return nil, "Failed to check existing entries: " .. err
    end

    if #existing_entries > 0 then
        return nil, "Entry already exists: " .. params.path .. ". Use str_replace to modify it, or delete it first."
    end

    local definition_yaml, content, parse_err = parse_file_text(params.file_text)
    if parse_err then
        return nil, "Failed to parse file_text: " .. parse_err
    end

    local parsed_entry, yaml_err = yaml.decode(definition_yaml)
    if yaml_err then
        return nil, "Failed to parse entry YAML: " .. yaml_err
    end

    if not parsed_entry.name or not parsed_entry.kind then
        return nil, "Entry YAML missing required fields: name and kind"
    end

    if parsed_entry.name ~= name then
        return nil, "Entry name mismatch: expected '" .. name .. "', got '" .. parsed_entry.name .. "'"
    end

    local cfg_err = validate_function_config(parsed_entry, content)
    if cfg_err then
        return nil, cfg_err
    end

    local registry_entry = {
        id = params.path,
        kind = parsed_entry.kind,
        meta = parsed_entry.meta,
        data = {}
    }

    for k, v in pairs(parsed_entry) do
        if k ~= "name" and k ~= "kind" and k ~= "meta" then
            registry_entry.data[k] = v
        end
    end

    if content and content ~= "" then
        local config = (materialize :: any).get_file_config and (materialize :: any).get_file_config(registry_entry)
        if config and config.source_field then
            registry_entry.data[config.source_field] = content
        end
    end

    local materialized, mat_err = materialize.entry(registry_entry)
    if mat_err then
        return nil, "Failed to materialize entry: " .. mat_err
    end

    local parsed_def, parse_def_err = yaml.decode(materialized.definition)
    if parse_def_err then
        return nil, "Generated invalid YAML: " .. parse_def_err .. "\n\nGenerated definition:\n" .. materialized.definition
    end

    if not parsed_def.entries or #parsed_def.entries == 0 then
        return nil, "Generated definition has no entries array\n\nGenerated definition:\n" .. materialized.definition
    end

    local _, save_err = registry_set(
        changeset_id,
        params.path,
        registry_entry.kind,
        materialized.definition,
        materialized.content or content or ""
    )
    if save_err then
        return nil, "Failed to create: " .. save_err
    end

    return "Created " .. params.path, nil
end

local function delete_command(params, branch, changeset_id)
    local namespace, name = validate_entry_id(params.path)
    if not namespace then
        return nil, name
    end

    local branches = get_active_branch_chain()
    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:with_entries(params.path):include_deleted()
    local existing, err = reader:all()
    if err then
        return nil, "Failed to check existing entry: " .. err
    end

    if #existing == 0 then
        return nil, "Entry does not exist on branch: " .. params.path
    end

    local current = existing[1]
    if current.deleted == 1 then
        return "Already deleted on branch: " .. params.path, nil
    end

    local _, del_err = registry_delete(changeset_id, params.path)
    if del_err then
        return nil, "Failed to delete: " .. del_err
    end

    return "Deleted " .. params.path .. " on branch " .. branch, nil
end

local function do_handler(params)
    if not params.command or params.command == "" then
        return nil, "Missing command (view, str_replace, create, delete)"
    end

    if not params.path or params.path == "" then
        return nil, "Missing path (entry ID)"
    end

    local branch = get_active_branch()

    if branch == "main" and params.command ~= "view" then
        return nil, "Cannot modify main branch (set branch first)"
    end

    local changeset_id
    if params.command ~= "view" then
        local cs_id, cs_err = resolve_changeset_id(branch)
        if cs_err or not cs_id then
            return nil, "No active changeset for branch '" .. branch ..
                "'. Call set_branch to open or resume a workspace before editing. (" ..
                tostring(cs_err or "missing changeset_id") .. ")"
        end
        changeset_id = cs_id
    end

    if params.command == "view" then
        return view_command(params)
    elseif params.command == "str_replace" then
        return str_replace_command(params, branch, changeset_id)
    elseif params.command == "create" then
        return create_command(params, branch, changeset_id)
    elseif params.command == "delete" then
        return delete_command(params, branch, changeset_id)
    end
    return nil, "Invalid command: " .. params.command
end

local function summarise_edit(params, result, err)
    if err then return "edit failed: " .. tostring(err) end
    local cmd = params.command or "?"
    local path = params.path or "?"
    if cmd == "view" then
        return "viewed " .. path
    elseif cmd == "create" then
        local file_text = params.file_text or ""
        local _, lines = file_text:gsub("\n", "\n")
        return "created " .. path .. " (" .. lines .. " lines)"
    elseif cmd == "str_replace" then
        return "str_replace on " .. path
    elseif cmd == "delete" then
        return "deleted " .. path
    end
    return cmd .. " on " .. path
end

local function handler(params)
    params = params or {}
    local cmd = params.command or "?"
    local path = params.path or "?"
    return audit.wrap({
        tool          = "edit",
        discriminator = "edit." .. cmd,
        target        = path,
        title         = cmd:sub(1, 1):upper() .. cmd:sub(2) .. " " .. path,
        params        = {
            command   = params.command,
            path      = params.path,
            file_text = params.file_text and (#params.file_text > 400
                and params.file_text:sub(1, 400) .. "…"
                or params.file_text) or nil,
            old_str   = params.old_str,
            new_str   = params.new_str,
        },
        summarise = function(result, err) return summarise_edit(params, result, err) end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }