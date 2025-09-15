-- Namespace Diff Module
local ns_diff = {}

-- Helper function to normalize metadata for comparison (nil vs empty table equivalence)
local function normalize_metadata(meta)
    if not meta then
        return nil
    end
    if type(meta) ~= "table" then
        return meta
    end
    if not next(meta) then
        return nil -- Empty table becomes nil for comparison
    end
    return meta
end

-- Helper function to clean data field by removing duplicate top-level fields
local function clean_data_field(data)
    if not data or type(data) ~= "table" then
        return data
    end

    local cleaned_data = {}
    for k, v in pairs(data) do
        -- Skip duplicate fields that exist at top level: kind, name, meta
        if k ~= "kind" and k ~= "meta" and k ~= "name" then
            cleaned_data[k] = v
        end
    end

    -- Return nil if cleaned data is empty
    if not next(cleaned_data) then
        return nil
    end

    return cleaned_data
end

-- Helper function to normalize an entry for comparison
local function normalize_entry_for_comparison(entry)
    if not entry then
        return nil
    end

    local normalized = {}
    for k, v in pairs(entry) do
        if k == "meta" then
            normalized[k] = normalize_metadata(v)
        elseif k == "data" then
            -- Clean data field to remove duplicates before comparison
            normalized[k] = clean_data_field(v)
        else
            normalized[k] = v
        end
    end

    return normalized
end

-- Deep comparison of tables (ignores key ordering and handles nil vs empty table for meta)
local function deep_compare(a, b, path)
    path = path or "root"

    -- Normalize both values first
    local norm_a = a
    local norm_b = b

    -- Special handling for meta field comparison
    if path:match("%.meta$") or path == "meta" then
        norm_a = normalize_metadata(a)
        norm_b = normalize_metadata(b)
    end

    if type(norm_a) ~= type(norm_b) then
        return false
    end

    if type(norm_a) ~= "table" then
        return norm_a == norm_b
    end

    -- Count keys in both tables
    local a_keys, b_keys = {}, {}
    for k in pairs(norm_a) do a_keys[k] = true end
    for k in pairs(norm_b) do b_keys[k] = true end

    -- Check if same number of keys
    local a_count, b_count = 0, 0
    for _ in pairs(a_keys) do a_count = a_count + 1 end
    for _ in pairs(b_keys) do b_count = b_count + 1 end

    if a_count ~= b_count then
        return false
    end

    -- Compare all key-value pairs
    for key in pairs(a_keys) do
        if not b_keys[key] then
            return false
        end

        if not deep_compare(norm_a[key], norm_b[key], path .. "." .. tostring(key)) then
            return false
        end
    end

    return true
end

-- Find differences between two tables
local function find_table_differences(original, new, path)
    path = path or ""
    local differences = {}

    if type(original) ~= "table" or type(new) ~= "table" then
        if original ~= new then
            table.insert(differences, {
                path = path,
                type = "value_change",
                old_value = original,
                new_value = new
            })
        end
        return differences
    end

    -- Find all unique keys
    local all_keys = {}
    for k in pairs(original) do all_keys[k] = true end
    for k in pairs(new) do all_keys[k] = true end

    for key in pairs(all_keys) do
        local key_path = path == "" and tostring(key) or path .. "." .. tostring(key)
        local old_val = original[key]
        local new_val = new[key]

        -- Special handling for meta field
        if key == "meta" then
            old_val = normalize_metadata(old_val)
            new_val = normalize_metadata(new_val)
        end

        if old_val == nil and new_val ~= nil then
            table.insert(differences, {
                path = key_path,
                type = "addition",
                new_value = new_val
            })
        elseif old_val ~= nil and new_val == nil then
            table.insert(differences, {
                path = key_path,
                type = "removal",
                old_value = old_val
            })
        elseif old_val ~= nil and new_val ~= nil then
            local nested_diffs = find_table_differences(old_val, new_val, key_path)
            for _, diff in ipairs(nested_diffs) do
                table.insert(differences, diff)
            end
        end
    end

    return differences
end

-- Build lookup map from entry list
local function build_entry_map(entries)
    local map = {}
    for i, entry in ipairs(entries) do
        map[entry.id] = {
            index = i,
            entry = entry
        }
    end
    return map
end

-- Validate input parameters
local function validate_parameters(param_name, param_value, expected_type)
    if not param_value then
        return nil, param_name .. " is required"
    end

    if expected_type and type(param_value) ~= expected_type then
        return nil, param_name .. " must be a " .. expected_type .. ", got " .. type(param_value)
    end

    return true, nil
end

-- Compare two sets of registry entries
function ns_diff.compare_entries(original_entries, new_entries)
    local valid, err = validate_parameters("original_entries", original_entries, "table")
    if not valid then
        return nil, err
    end

    valid, err = validate_parameters("new_entries", new_entries, "table")
    if not valid then
        return nil, err
    end

    local original_map = build_entry_map(original_entries)
    local new_map = build_entry_map(new_entries)

    local changes = {}

    -- Find additions and modifications
    for entry_id, new_info in pairs(new_map) do
        local original_info = original_map[entry_id]

        if not original_info then
            -- Entry added
            table.insert(changes, {
                type = "addition",
                entry_id = entry_id,
                entry = new_info.entry
            })
        else
            -- Normalize both entries for comparison
            local norm_original = normalize_entry_for_comparison(original_info.entry)
            local norm_new = normalize_entry_for_comparison(new_info.entry)

            if not deep_compare(norm_original, norm_new) then
                -- Entry modified
                local differences = find_table_differences(original_info.entry, new_info.entry)
                table.insert(changes, {
                    type = "modification",
                    entry_id = entry_id,
                    original_entry = original_info.entry,
                    new_entry = new_info.entry,
                    differences = differences
                })
            end
        end
    end

    -- Find deletions
    for entry_id, original_info in pairs(original_map) do
        if not new_map[entry_id] then
            table.insert(changes, {
                type = "deletion",
                entry_id = entry_id,
                entry = original_info.entry
            })
        end
    end

    -- Sort changes for consistent output
    table.sort(changes, function(a, b)
        if a.type ~= b.type then
            local type_order = { addition = 1, modification = 2, deletion = 3 }
            return type_order[a.type] < type_order[b.type]
        end
        return a.entry_id < b.entry_id
    end)

    return changes, nil
end

-- Compare namespace with edited YAML content
function ns_diff.compare_namespace_with_yaml(original_namespace, edited_yaml_content)
    local valid, err = validate_parameters("original_namespace", original_namespace, "table")
    if not valid then
        return nil, err
    end

    if not original_namespace.resolve then
        return nil, "original_namespace must be a namespace object with resolve method"
    end

    valid, err = validate_parameters("edited_yaml_content", edited_yaml_content, "string")
    if not valid then
        return nil, err
    end

    if edited_yaml_content:match("^%s*$") then
        return nil, "Edited YAML content cannot be empty or whitespace only"
    end

    -- Resolve the edited YAML using the original namespace
    local resolved_entries, resolve_err = original_namespace:resolve(edited_yaml_content)
    if not resolved_entries then
        return nil, "Failed to resolve edited YAML: " .. (resolve_err or "unknown error")
    end

    -- REMOVED: No data restoration logic - let data be clean without duplicates

    -- Compare original entries with resolved entries
    local changes, compare_err = ns_diff.compare_entries(original_namespace.entries, resolved_entries)
    if not changes then
        return nil, "Failed to compare entries: " .. (compare_err or "unknown error")
    end

    return {
        namespace = original_namespace.name,
        changes = changes,
        change_count = #changes,
        original_entry_count = #original_namespace.entries,
        new_entry_count = #resolved_entries
    }, nil
end

-- Wipe namespace (delete all entries)
function ns_diff.wipe_namespace(namespace)
    local valid, err = validate_parameters("namespace", namespace, "table")
    if not valid then
        return nil, err
    end

    if not namespace.name then
        return nil, "namespace must have a name field"
    end

    if not namespace.entries then
        return nil, "namespace must have an entries field"
    end

    local changes = {}

    -- Mark all entries for deletion
    for _, entry in ipairs(namespace.entries) do
        table.insert(changes, {
            type = "deletion",
            entry_id = entry.id,
            entry = entry
        })
    end

    return {
        namespace = namespace.name,
        changes = changes,
        change_count = #changes,
        original_entry_count = #namespace.entries,
        new_entry_count = 0,
        wipe_operation = true
    }, nil
end

-- Get summary of changes
function ns_diff.get_change_summary(diff_result)
    if not diff_result or not diff_result.changes then
        return {
            total_changes = 0,
            additions = 0,
            modifications = 0,
            deletions = 0,
            metadata_only_changes = 0,
            source_content_changes = 0,
            is_wipe_operation = false
        }
    end

    local summary = {
        total_changes = diff_result.change_count,
        additions = 0,
        modifications = 0,
        deletions = 0,
        metadata_only_changes = 0,
        source_content_changes = 0,
        is_wipe_operation = diff_result.wipe_operation or false
    }

    for _, change in ipairs(diff_result.changes) do
        if change.type == "addition" then
            summary.additions = summary.additions + 1
        elseif change.type == "modification" then
            summary.modifications = summary.modifications + 1

            -- Analyze type of modification
            local has_source_change = false
            local has_metadata_change = false

            for _, diff in ipairs(change.differences or {}) do
                if diff.path:match("^data%.source$") then
                    has_source_change = true
                elseif diff.path:match("^meta%.") then
                    has_metadata_change = true
                end
            end

            if has_source_change then
                summary.source_content_changes = summary.source_content_changes + 1
            elseif has_metadata_change then
                summary.metadata_only_changes = summary.metadata_only_changes + 1
            end
        elseif change.type == "deletion" then
            summary.deletions = summary.deletions + 1
        end
    end

    return summary
end

-- Check if changes contain only metadata modifications (no source changes)
function ns_diff.is_metadata_only_changes(diff_result)
    if not diff_result or not diff_result.changes then
        return true
    end

    -- Wipe operations are not metadata-only
    if diff_result.wipe_operation then
        return false
    end

    for _, change in ipairs(diff_result.changes) do
        if change.type == "addition" or change.type == "deletion" then
            return false
        end

        if change.type == "modification" then
            for _, diff in ipairs(change.differences or {}) do
                if diff.path:match("^data%.source$") then
                    return false
                end
            end
        end
    end

    return true
end

-- Check if this is a complete namespace wipe
function ns_diff.is_wipe_operation(diff_result)
    if not diff_result then
        return false
    end

    return diff_result.wipe_operation == true
end

-- Generate workspace operations from diff result
function ns_diff.generate_workspace_operations(diff_result)
    if not diff_result or not diff_result.changes then
        return {}
    end

    local operations = {}

    for _, change in ipairs(diff_result.changes) do
        if change.type == "addition" then
            table.insert(operations, {
                operation = "upsert_entry",
                entry_id = change.entry_id,
                entry_data = change.entry.data,  -- Only data field
                entry_meta = change.entry.meta   -- Only meta field
            })
        elseif change.type == "modification" then
            table.insert(operations, {
                operation = "upsert_entry",
                entry_id = change.entry_id,
                entry_data = change.new_entry.data,  -- Only data field
                entry_meta = change.new_entry.meta   -- Only meta field
            })
        elseif change.type == "deletion" then
            table.insert(operations, {
                operation = "delete_entry",
                entry_id = change.entry_id
            })
        end
    end

    return operations
end

return ns_diff