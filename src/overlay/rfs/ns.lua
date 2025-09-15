local yaml = require("yaml")
local consts = require("consts")

-- Namespace Operations Module
local ns = {}

-- Field order for YAML generation
local FIELD_ORDER = {
    "version", "namespace",
    "name", "kind", "contract",
    "meta", "type", "title", "comment", "group", "tags", "icon", "description", "order", "content_type",
    "prompt", "model", "temperature", "max_tokens", "tools", "memory", "delegate",
    "source", "modules", "imports", "method",
    "depends_on", "router", "set", "resources", "entries"
}

-- Namespace class
local namespace_methods = {}
local namespace_mt = { __index = namespace_methods }

-- Create new namespace representation
function ns.new(namespace_name, entries)
    local instance = {
        name = namespace_name,
        version = "1.0",
        entries = entries or {},
        -- Internal file mappings
        _file_owners = {},    -- filename -> entry_name
        _entry_files = {}     -- entry_name -> {filenames}
    }

    setmetatable(instance, namespace_mt)
    instance:_rebuild_file_mappings()

    return instance
end

-- Get file configuration for an entry
function ns.get_file_config(entry)
    if not entry or not entry.kind then
        return nil
    end

    -- Handle registry.entry with meta.type
    if entry.kind == "registry.entry" then
        if entry.meta and entry.meta.type then
            local registry_extensions = consts.RFS.EXTENSIONS["registry.entry"]
            if registry_extensions and registry_extensions[entry.meta.type] then
                return {
                    source_field = "source",
                    extension = registry_extensions[entry.meta.type]
                }
            end
        end
        return nil
    end

    -- Handle direct kind mappings
    local extension = consts.RFS.EXTENSIONS[entry.kind]
    if extension and type(extension) == "string" then
        return {
            source_field = "source",
            extension = extension
        }
    end

    return nil
end

-- Extract filename from file:// URL
function ns.extract_filename_from_url(file_url)
    if not file_url or type(file_url) ~= "string" then
        return nil
    end
    return file_url:match("^" .. consts.RFS.PATH.FILE_PROTOCOL .. "(.+)$")
end

-- Generate filename for entry
function ns.generate_filename(entry_name, config)
    if not config or not config.extension then
        return nil
    end

    local filename = entry_name
    if not filename:match(config.extension .. "$") then
        filename = filename .. config.extension
    end

    return filename
end

-- Rebuild internal file mappings
function namespace_methods:_rebuild_file_mappings()
    self._file_owners = {}
    self._entry_files = {}

    for _, entry in ipairs(self.entries) do
        local _, entry_name = entry.id:match("([^:]+):(.+)")
        if entry_name then
            local config = ns.get_file_config(entry)
            if config then
                local filename = nil
                local source_field = config.source_field

                -- Check for file:// reference or generate filename
                if entry.data and entry.data[source_field] then
                    local existing_filename = ns.extract_filename_from_url(entry.data[source_field])
                    if existing_filename then
                        filename = existing_filename
                    else
                        filename = ns.generate_filename(entry_name, config)
                    end
                end

                if filename then
                    self._file_owners[filename] = entry_name
                    if not self._entry_files[entry_name] then
                        self._entry_files[entry_name] = {}
                    end
                    table.insert(self._entry_files[entry_name], filename)
                end
            end
        end
    end
end

-- Get entry by name
function namespace_methods:get_entry(entry_name)
    for _, entry in ipairs(self.entries) do
        local _, name = entry.id:match("([^:]+):(.+)")
        if name == entry_name then
            return entry
        end
    end
    return nil
end

-- Get all files this namespace generates
function namespace_methods:list_files()
    local files = {consts.RFS.PATH.INDEX_FILENAME}

    for filename, _ in pairs(self._file_owners) do
        table.insert(files, filename)
    end

    table.sort(files)
    return files
end

-- Get which entry owns a file
function namespace_methods:get_file_owner(filename)
    return self._file_owners[filename]
end

-- Get file content (either _index.yaml or source file)
function namespace_methods:get_file_content(filename)
    if filename == consts.RFS.PATH.INDEX_FILENAME then
        return self:to_yaml()
    end

    -- Find entry that owns this file
    local entry_name = self._file_owners[filename]
    if not entry_name then
        return nil, consts.RFS.RFS_ERROR.FILE_NOT_FOUND .. ": " .. filename
    end

    local entry = self:get_entry(entry_name)
    if not entry then
        return nil, "Entry not found for file: " .. filename
    end

    local config = ns.get_file_config(entry)
    if not config then
        return nil, "Entry kind does not support source files: " .. entry.kind
    end

    local source_field = config.source_field
    if not entry.data or not entry.data[source_field] then
        return nil, "Entry has no source content"
    end

    local source_content = entry.data[source_field]
    if type(source_content) ~= "string" then
        return nil, "Source content is not a string"
    end

    -- If it's a file:// URL, we can't extract content
    local existing_filename = ns.extract_filename_from_url(source_content)
    if existing_filename then
        return nil, "Entry uses file:// reference, content not available"
    end

    return source_content, nil
end

-- Check if file exists
function namespace_methods:file_exists(filename)
    if filename == consts.RFS.PATH.INDEX_FILENAME then
        return true
    end
    return self._file_owners[filename] ~= nil
end

-- Generate _index.yaml content
function namespace_methods:to_yaml(options)
    options = options or {}
    local inline_sources = options.inline_sources or false

    local yaml_entries = table.create(1, 0)  -- Initialize as array

    for _, entry in ipairs(self.entries) do
        local _, entry_name = entry.id:match("([^:]+):(.+)")
        if not entry_name then
            return nil, "Invalid entry ID format: " .. entry.id
        end

        local yaml_entry = {
            name = entry_name,
            kind = entry.kind
        }

        -- Add meta if present and non-empty
        if entry.meta and next(entry.meta) then
            yaml_entry.meta = entry.meta
        end

        -- Add data fields
        if entry.data then
            for k, v in pairs(entry.data) do
                if k ~= "meta" then
                    local config = ns.get_file_config(entry)

                    -- Handle source field
                    if config and k == config.source_field and type(v) == "string" then
                        local existing_filename = ns.extract_filename_from_url(v)
                        if existing_filename then
                            -- Already a file:// reference
                            yaml_entry[k] = v
                        elseif inline_sources then
                            -- Keep inline content
                            yaml_entry[k] = v
                        else
                            -- Convert to file:// reference
                            local filename = ns.generate_filename(entry_name, config)
                            if filename then
                                yaml_entry[k] = consts.RFS.PATH.FILE_PROTOCOL .. filename
                            else
                                yaml_entry[k] = v
                            end
                        end
                    else
                        yaml_entry[k] = v
                    end
                end
            end
        end

        table.insert(yaml_entries, yaml_entry)
    end

    -- Sort entries by name
    table.sort(yaml_entries, function(a, b)
        return a.name < b.name
    end)

    -- Generate header (version + namespace only)
    local header_yaml, err = yaml.encode({
        version = self.version,
        namespace = self.name
    }, {
        indent = 2,
        field_order = FIELD_ORDER,
        sort_unordered = true
    })

    if err then
        return nil, "Failed to encode YAML header: " .. err
    end

    local content = header_yaml .. "\n" .. "entries:"

    -- Empty namespace case
    if #yaml_entries == 0 then
        return content, nil
    end

    -- Add entries with comments and spacing
    for i, entry in ipairs(yaml_entries) do
        -- Comment: "  # namespace:entry_name"
        content = content .. "\n" .. "  # " .. self.name .. ":" .. entry.name

        -- Entry YAML with proper indentation
        local entry_yaml, err = yaml.encode(entry, {
            indent = 2,
            field_order = FIELD_ORDER,
            sort_unordered = true
        })
        if err then
            return nil, "Failed to encode entry: " .. err
        end

        -- Add "  - " prefix and indent all lines by 4 spaces
        entry_yaml = "  - " .. entry_yaml:gsub("\n", "\n    ")
        content = content .. "\n" .. entry_yaml

        -- Blank line between entries (except last)
        if i < #yaml_entries then
            content = content .. "\n"
        end
    end

    return content, nil
end

-- Helper function to safely copy metadata without contamination
local function copy_metadata_safely(source_meta)
    if not source_meta then
        return nil
    end

    if type(source_meta) ~= "table" then
        return nil
    end

    -- Only copy if it has actual content
    if not next(source_meta) then
        return nil
    end

    -- Create clean copy, excluding any workspace-specific fields
    local clean_meta = {}
    for k, v in pairs(source_meta) do
        -- Exclude workspace entry fields that shouldn't be in registry meta
        if k ~= "entry_data" and k ~= "entry_meta" and k ~= "workspace_entry_id" and
           k ~= "workspace_id" and k ~= "operation_type" then
            clean_meta[k] = v
        end
    end

    -- Only return if we have actual content
    if next(clean_meta) then
        return clean_meta
    else
        return nil
    end
end

-- Convert edited YAML back to registry entries with resolved file:// references
function namespace_methods:resolve(edited_yaml_content)
    if not edited_yaml_content or edited_yaml_content == "" then
        return nil, "Empty YAML content"
    end

    local parsed, err = yaml.decode(edited_yaml_content)
    if not parsed then
        return nil, "Failed to parse YAML: " .. (err or "unknown error")
    end

    if not parsed.namespace then
        return nil, "Missing namespace field"
    end

    if parsed.namespace ~= self.name then
        return nil, "Namespace mismatch: expected " .. self.name .. ", got " .. parsed.namespace
    end

    if not parsed.entries or type(parsed.entries) ~= "table" then
        return nil, "Missing or invalid entries array"
    end

    -- Convert YAML entries back to registry format with resolved content
    local resolved_entries = {}

    for i, yaml_entry in ipairs(parsed.entries) do
        if not yaml_entry.name or not yaml_entry.kind then
            return nil, "Entry " .. i .. " missing name or kind"
        end

        local registry_entry = {
            id = self.name .. ":" .. yaml_entry.name,
            kind = yaml_entry.kind,
            data = {}
        }

        -- Handle meta field carefully - preserve original behavior
        local original_entry = self:get_entry(yaml_entry.name)
        if yaml_entry.meta then
            local clean_meta = copy_metadata_safely(yaml_entry.meta)
            if clean_meta then
                registry_entry.meta = clean_meta
            elseif original_entry and original_entry.meta then
                -- If YAML has meta but it's empty, and original had meta, preserve empty table
                registry_entry.meta = {}
            end
            -- If both YAML meta is empty and original had no meta, leave as nil
        else
            -- No meta in YAML - preserve original's meta state
            if original_entry and original_entry.meta then
                if next(original_entry.meta) then
                    registry_entry.meta = original_entry.meta
                else
                    registry_entry.meta = {}
                end
            end
            -- If original had no meta, leave as nil
        end

        -- Copy data fields, resolving file:// references
        for k, v in pairs(yaml_entry) do
            if k ~= "name" and k ~= "kind" and k ~= "meta" then
                local config = ns.get_file_config(registry_entry)

                -- Resolve file:// references using original entries
                if config and k == config.source_field and type(v) == "string" then
                    local filename = ns.extract_filename_from_url(v)
                    if filename then
                        -- This is a file:// reference, find original content
                        if original_entry and original_entry.data and original_entry.data[k] then
                            local original_content = original_entry.data[k]
                            -- Only use original if it's not also a file:// reference
                            if not ns.extract_filename_from_url(original_content) then
                                registry_entry.data[k] = original_content
                            else
                                registry_entry.data[k] = v -- Keep file:// reference
                            end
                        else
                            registry_entry.data[k] = v -- Keep file:// reference
                        end
                    else
                        registry_entry.data[k] = v -- Inline content
                    end
                else
                    registry_entry.data[k] = v
                end
            end
        end

        table.insert(resolved_entries, registry_entry)
    end

    return resolved_entries, nil
end

-- Extract source content from entry (helper for external use)
function ns.extract_source_content(entry)
    local config = ns.get_file_config(entry)
    if not config then
        return nil, "Entry kind does not support source extraction"
    end

    local source_field = config.source_field
    if not entry.data or not entry.data[source_field] then
        return nil, "Entry has no source content"
    end

    local source_content = entry.data[source_field]
    if type(source_content) ~= "string" then
        return nil, "Source content is not a string"
    end

    -- If it's a file:// URL, we can't extract content directly
    local existing_filename = ns.extract_filename_from_url(source_content)
    if existing_filename then
        return nil, "Entry uses file:// reference, content not available in registry"
    end

    return source_content, nil
end

-- Get namespace statistics
function namespace_methods:get_stats()
    local file_count = 0
    for _ in pairs(self._file_owners) do
        file_count = file_count + 1
    end

    return {
        name = self.name,
        version = self.version,
        entry_count = #self.entries,
        file_count = file_count + 1, -- +1 for _index.yaml
    }
end

return ns