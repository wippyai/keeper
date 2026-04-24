local yaml = require("yaml")
local hash = require("hash")
local consts = require("overlay_consts")
local state_ops = require("state_ops")

local materialize = {}

local function get_file_config(entry)
    local config = consts.RFS.EXTENSIONS[entry.kind]

    if not config then
        return nil, nil
    end

    if type(config) == "table" and config.extension then
        return config.extension, config.source_field
    end

    if type(config) == "table" and entry.meta and entry.meta.type then
        local type_config = config[entry.meta.type]
        if type_config and type_config.extension then
            return type_config.extension, type_config.source_field
        end
    end

    return nil, nil
end

local function build_yaml_entry(entry)
    local entry_ns, entry_name = entry.id:match("([^:]+):(.+)")
    if not entry_ns or not entry_name then
        return nil, "Invalid entry ID format: " .. entry.id
    end

    local yaml_entry = {
        name = entry_name,
        kind = entry.kind
    }

    if entry.meta and next(entry.meta) then
        yaml_entry.meta = entry.meta
    end

    if entry.data then
        for k, v in pairs(entry.data) do
            yaml_entry[k] = v
        end
    end

    local entry_yaml, err = yaml.encode(yaml_entry, {
        indent = 2,
        field_order = consts.FIELD_ORDER,
        sort_unordered = true
    })

    if err then
        return nil, "Failed to encode entry YAML: " .. err
    end

    return entry_yaml, nil
end

function materialize.entry(entry)
    if not entry or not entry.id or not entry.kind then
        return nil, "Invalid entry: missing id or kind"
    end

    local entry_ns, entry_name = entry.id:match("([^:]+):(.+)")
    if not entry_ns or not entry_name then
        return nil, "Invalid entry ID format: " .. entry.id
    end

    local header_yaml, err = yaml.encode({
        version = "1.0",
        namespace = entry_ns
    }, {
        indent = 2,
        field_order = consts.FIELD_ORDER,
        sort_unordered = true
    })

    if err then
        return nil, "Failed to encode header: " .. err
    end

    local extension, source_field = get_file_config(entry)
    local content = nil
    local content_hash = nil

    if extension and source_field then
        if entry.data and entry.data[source_field] then
            local field_value = entry.data[source_field]

            if type(field_value) == "string" and field_value ~= "" then
                if not field_value:match("^file://") then
                    content = field_value

                    local hash_err
                    content_hash, hash_err = hash.sha256(content)
                    if hash_err then
                        return nil, "Failed to hash content: " .. hash_err
                    end

                    local filename = entry_name
                    if not filename:match(extension .. "$") then
                        filename = filename .. extension
                    end

                    if not entry.data then
                        entry.data = {}
                    end
                    entry.data[source_field] = consts.RFS.PATH.FILE_PROTOCOL .. filename
                end
            end
        end
    end

    local entry_yaml, err = build_yaml_entry(entry :: any)
    if err then
        return nil, err
    end

    local definition = header_yaml .. "\nentries:\n  # " .. entry.id .. "\n  - " .. entry_yaml:gsub("\n", "\n    ")

    local def_hash, hash_err = hash.sha256(definition)
    if hash_err then
        return nil, "Failed to hash definition: " .. hash_err
    end

    local attributes = {}
    if entry.meta and type(entry.meta) == "table" then
        for k, v in pairs(entry.meta) do
            if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
                attributes["meta." .. k] = tostring(v)
            end
        end
    end

    return {
        id = entry.id,
        kind = entry.kind,
        definition = definition,
        definition_hash = def_hash,
        content = content,
        content_hash = content_hash,
        attributes = attributes
    }
end

function materialize.format_entry_structured(entry, include_filename)
    if not entry or not entry.id then
        return nil
    end

    local lines = {}

    local definition_content = nil
    local source_content = nil
    local source_filename = nil

    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then
                definition_content = chunk.content
            elseif chunk.type == "content" then
                source_content = chunk.content
            end
        end
    end

    if definition_content then
        table.insert(lines, "<definition>")

        -- Dedent each entry block by 4 chars. The entry list marker `  - ` is 4
        -- chars; continuation lines are 4-space indented. Nested lists like
        -- `      - http` dedent to `  - http`, preserving YAML list structure.
        local in_entries_section = false
        local entry_lines = {}

        for line in definition_content:gmatch("[^\n]+") do
            if line:match("^entries:") then
                in_entries_section = true
            elseif in_entries_section then
                if line:match("^%s*#") then
                    -- skip comments
                elseif line:match("^  %- ") then
                    table.insert(entry_lines, line:sub(5))
                elseif line:match("^    ") then
                    table.insert(entry_lines, line:sub(5))
                end
            end
        end

        for _, line in ipairs(entry_lines) do
            if line:match("^source:%s*file://") then
                source_filename = line:match("^source:%s*file://(.+)$")
            end
            table.insert(lines, line)
        end

        table.insert(lines, "</definition>")
    end

    if source_content and source_content ~= "" then
        table.insert(lines, "")
        if include_filename and source_filename then
            table.insert(lines, "<source filename=\"" .. source_filename .. "\">")
        else
            table.insert(lines, "<source>")
        end
        table.insert(lines, source_content)
        table.insert(lines, "</source>")
    end

    return table.concat(lines, "\n")
end

function materialize.to_set_command(materialized, branch)
    if not materialized then
        return nil, "Materialized entry required"
    end

    return {
        type = state_ops.COMMAND.SET_ENTRY,
        payload = {
            id = materialized.id,
            kind = materialized.kind,
            definition = materialized.definition,
            content = materialized.content,
            attributes = materialized.attributes,
            branch = branch or consts.BRANCH.MAIN
        }
    }
end

function materialize.to_delete_command(entry_id, branch)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID required"
    end

    return {
        type = state_ops.COMMAND.DELETE_ENTRY,
        payload = {
            id = entry_id,
            branch = branch or consts.BRANCH.MAIN
        }
    }
end

local function extract_value(value)
    if type(value) == "string" and value ~= "" then
        return {value}
    elseif type(value) == "table" then
        local results = {}
        for _, v in ipairs(value) do
            if type(v) == "string" and v ~= "" then
                table.insert(results, v)
            end
        end
        return results
    end
    return {}
end

local function extract_from_nested(data, path_parts, index)
    if not data or index > #path_parts then
        return {}
    end

    local segment = path_parts[index]

    if segment == "*" then
        local results = {}
        if type(data) == "table" then
            for _, value in pairs(data) do
                if index == #path_parts then
                    local extracted = extract_value(value)
                    for _, v in ipairs(extracted) do
                        table.insert(results, v)
                    end
                else
                    local nested = extract_from_nested(value, path_parts, index + 1)
                    for _, v in ipairs(nested) do
                        table.insert(results, v)
                    end
                end
            end
        end
        return results
    end

    if type(data) ~= "table" or not data[segment] then
        return {}
    end

    if index == #path_parts then
        return extract_value(data[segment])
    end

    return extract_from_nested(data[segment], path_parts, index + 1)
end

local function extract_dependencies_from_path(entry, path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    if #parts == 0 then
        return {}
    end

    local root = parts[1]
    local data = nil

    if root == "meta" then
        data = entry.meta
    elseif root == "data" then
        data = entry.data
    else
        return {}
    end

    if not data or #parts == 1 then
        return {}
    end

    return extract_from_nested(data, parts, 2)
end

local function resolve_id(value, entry_namespace, path)
    if type(value) ~= "string" or value == "" then
        return value
    end

    if value:match(":") then
        return value
    end

    if path == "data.modules" then
        return value
    end

    return entry_namespace .. ":" .. value
end

function materialize.extract_edges(entry)
    local edges = {}

    if not entry or not entry.id then
        return edges
    end

    local entry_ns = entry.id:match("([^:]+):")
    if not entry_ns then
        return edges
    end

    local seen = {}

    for edge_type, paths in pairs(consts.DEPENDENCY_PATHS) do
        for _, path in ipairs(paths) do
            local deps = extract_dependencies_from_path(entry, path)

            for _, dep_id in ipairs(deps) do
                local resolved_id = resolve_id(dep_id, entry_ns, path)

                local key = resolved_id .. "|" .. edge_type
                if not seen[key] then
                    seen[key] = true
                    table.insert(edges, {
                        source_id = entry.id,
                        target_id = resolved_id,
                        edge_type = edge_type,
                        metadata = {}
                    })
                end
            end
        end
    end

    return edges
end

function materialize.edges_to_commands(edges, branch)
    local commands = {}

    for _, edge in ipairs(edges) do
        if type(edge.source_id) == "string" and edge.source_id ~= "" and
           type(edge.target_id) == "string" and edge.target_id ~= "" and
           type(edge.edge_type) == "string" and edge.edge_type ~= "" then
            table.insert(commands, {
                type = state_ops.COMMAND.SET_EDGE,
                payload = {
                    source_id = edge.source_id,
                    target_id = edge.target_id,
                    edge_type = edge.edge_type,
                    metadata = edge.metadata,
                    branch = branch or consts.BRANCH.MAIN
                }
            })
        end
    end

    return commands
end

-- Convert state entry (with chunks) to registry entry format
function materialize.state_entry_to_registry(state_entry)
    if not state_entry or not state_entry.id or not state_entry.kind then
        return nil, "Invalid state entry: missing id or kind"
    end

    -- Extract definition and content from chunks
    local definition_content = nil
    local source_content = nil

    if state_entry.chunks then
        for _, chunk in ipairs(state_entry.chunks) do
            if chunk.type == "definition" then
                definition_content = chunk.content
            elseif chunk.type == "content" then
                source_content = chunk.content
            end
        end
    end

    if not definition_content or definition_content == "" then
        return nil, "State entry has no definition chunk"
    end

    -- Parse the definition YAML
    local parsed, err = yaml.decode(definition_content)
    if err then
        return nil, "Failed to parse definition YAML: " .. err
    end

    if not parsed.entries or #parsed.entries == 0 then
        return nil, "Definition has no entries"
    end

    local yaml_entry = parsed.entries[1]

    -- Build registry entry structure
    local registry_entry = {
        id = state_entry.id,
        kind = state_entry.kind,
        meta = nil,
        data = {}
    }

    -- Extract meta if present
    if yaml_entry.meta and next(yaml_entry.meta) then
        registry_entry.meta = yaml_entry.meta
    end

    -- Build data field - exclude name, kind, meta
    for k, v in pairs(yaml_entry) do
        if k ~= "name" and k ~= "kind" and k ~= "meta" then
            registry_entry.data[k] = v
        end
    end

    -- If there's source content and a source field with file:// reference, resolve it
    if source_content and source_content ~= "" then
        local extension, source_field = get_file_config(registry_entry)
        if source_field then
            if registry_entry.data[source_field] then
                local filename = registry_entry.data[source_field]:match("^" .. consts.RFS.PATH.FILE_PROTOCOL .. "(.+)$")
                if filename then
                    -- Replace file:// reference with actual content
                    registry_entry.data[source_field] = source_content
                end
            else
                -- No source field in data, add it
                registry_entry.data[source_field] = source_content
            end
        end
    end

    -- function.lua config normalization. 99% of entries want `method = "handler"`
    -- and empty `modules`/`imports` tables make Go unmarshal reject the config
    -- (slices reject `{}`, maps reject `[]`). Defaulting here means every caller
    -- — submit preflight, push, test — sees a well-formed registry entry.
    if registry_entry.kind == "function.lua" then
        local data = registry_entry.data
        if not data.method or data.method == "" then
            data.method = "handler"
        end
        if type(data.modules) == "table" and next(data.modules) == nil then
            data.modules = nil
        end
        if type(data.imports) == "table" and next(data.imports) == nil then
            data.imports = nil
        end
    end

    return registry_entry, nil
end

return materialize