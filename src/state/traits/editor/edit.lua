local json = require("json")
local ctx = require("ctx")
local text = require("text")
local yaml = require("yaml")
local state_reader = require("state_reader")
local state_client = require("state_client")
local materialize = require("materialize")
local consts = require("consts")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return overlay_branch
    end
    return "main"
end

local function get_active_branch_chain()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return {overlay_branch, "main"}
    end
    return {"main"}
end

local function validate_entry_id(entry_id)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    local colon_pos = entry_id:find(":")
    if not colon_pos then
        return nil, "Invalid entry ID format (must be namespace:name)"
    end

    local namespace = entry_id:sub(1, colon_pos - 1)
    local name = entry_id:sub(colon_pos + 1)

    if namespace == "" or name == "" then
        return nil, "Invalid entry ID format (namespace or name empty)"
    end

    return namespace, name
end

local function perform_text_replacement(content, old_str, new_str)
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
        local second_exact = content:find(old_str, exact_end + 1, true)
        if second_exact then
            local _, count = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), old_str)
            return nil, string.format(
                "Error: Found %d matches for replacement text. Please provide more context to make a unique match.\n\nSearched for:\n%s",
                count,
                old_str:sub(1, 200)
            )
        end

        return content:sub(1, exact_start - 1) .. new_str .. content:sub(exact_end + 1), nil
    end

    local target_content = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), new_str, 1)

    if target_content == content then
        local preview_len = 300
        local search_preview = old_str:sub(1, 200)
        local content_preview = content:sub(1, preview_len)

        local old_first_line = old_str:match("([^\n]+)")
        local similar_pos = content:find(old_first_line, 1, true)
        local similarity_hint = ""
        if similar_pos then
            local context_start = math.max(1, similar_pos - 50)
            local context_end = math.min(#content, similar_pos + #old_first_line + 50)
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

    local patches, err = differ:patch_make(content, target_content)
    if err then
        return nil, "Failed to create patches: " .. err
    end

    if not patches or #patches == 0 then
        return nil, "No changes detected"
    end

    local result, success = differ:patch_apply(patches, content)
    if not success then
        return nil, "Fuzzy patch application failed"
    end

    if result == content then
        return nil, "No actual changes made"
    end

    return result, nil
end

local function extract_kind_from_definition(definition_yaml)
    local entries_start = definition_yaml:find("entries:", 1, true)
    if not entries_start then
        return nil, "Definition missing 'entries:' section"
    end

    local entry_yaml = definition_yaml:sub(entries_start)
    local kind_match = entry_yaml:match("kind:%s*([%w%.%-_]+)")

    if not kind_match then
        return nil, "Cannot find 'kind:' field in definition"
    end

    return kind_match, nil
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

local function str_replace_command(params, branch)
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

    local in_definition = definition_content:find(params.old_str, 1, true)
    local in_source = source_content and source_content:find(params.old_str, 1, true)

    if in_definition and in_source then
        return nil, string.format(
            "Error: Text appears in both definition and source. Please be more specific.\n\nSearched for:\n%s",
            params.old_str:sub(1, 200)
        )
    end

    if not in_definition and not in_source then
        local def_preview = definition_content:sub(1, 300)
        local src_preview = source_content and source_content:sub(1, 300) or "none"

        return nil, string.format(
            "Error: No match found in entry.\n\nSearched for:\n%s%s\n\nDefinition starts with:\n%s...\n\nSource starts with:\n%s...",
            params.old_str:sub(1, 200),
            #params.old_str > 200 and "..." or "",
            def_preview,
            src_preview
        )
    end

    if in_definition then
        local new_definition, replace_err = perform_text_replacement(definition_content, params.old_str, params.new_str)
        if replace_err then
            return nil, "Definition replacement failed: " .. replace_err
        end

        local kind, kind_err = extract_kind_from_definition(new_definition)
        if kind_err then
            return nil, kind_err
        end

        local result, save_err = state_client.set_entry(
            params.path,
            kind,
            new_definition,
            source_content,
            nil,
            branch
        )

        if save_err then
            return nil, "Failed to save: " .. save_err
        end

        return "Replaced text in definition", nil

    else
        local new_content, replace_err = perform_text_replacement(source_content, params.old_str, params.new_str)
        if replace_err then
            return nil, "Source replacement failed: " .. replace_err
        end

        local kind, kind_err = extract_kind_from_definition(definition_content)
        if kind_err then
            return nil, kind_err
        end

        local result, save_err = state_client.set_entry(
            params.path,
            kind,
            definition_content,
            new_content,
            nil,
            branch
        )

        if save_err then
            return nil, "Failed to save: " .. save_err
        end

        return "Replaced text in source", nil
    end
end

local function create_command(params, branch)
    if not params.file_text or params.file_text == "" then
        return nil, "file_text required for create"
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
        local config = materialize.get_file_config and materialize.get_file_config(registry_entry)
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

    local result, save_err = state_client.set_entry(
        params.path,
        registry_entry.kind,
        materialized.definition,
        materialized.content or content or "",
        nil,
        branch
    )

    if save_err then
        return nil, "Failed to create: " .. save_err
    end

    return "Created " .. params.path, nil
end

local function handler(params)
    if not params.command or params.command == "" then
        return nil, "Missing command (view, str_replace, create)"
    end

    if not params.path or params.path == "" then
        return nil, "Missing path (entry ID)"
    end

    local branch = get_active_branch()

    if branch == "main" and params.command ~= "view" then
        return nil, "Cannot modify main branch (set branch first)"
    end

    if params.command == "view" then
        return view_command(params)
    elseif params.command == "str_replace" then
        return str_replace_command(params, branch)
    elseif params.command == "create" then
        return create_command(params, branch)
    else
        return nil, "Invalid command: " .. params.command
    end
end

return { handler = handler }