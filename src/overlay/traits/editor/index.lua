local json = require("json")
local security = require("security")
local ctx = require("ctx")
local ns = require("ns")
local workspace = require("workspace")
local snapshot = require("snapshot")
local yaml = require("yaml")

-- Helper function to normalize namespace path
local function normalize_namespace_path(path)
    if not path or type(path) ~= "string" or path == "." then
        return path
    end
    -- Convert slash notation to dot notation for internal use
    return path:gsub("/", ".")
end

-- Helper function to get namespace entries efficiently
local function get_namespace_entries(namespace, session)
    return snapshot.get_namespace_snapshot(session, namespace)
end

-- Helper function to parse YAML entry using ns functionality
local function parse_yaml_entry(entry_yaml, namespace, session)
    if not entry_yaml or type(entry_yaml) ~= "string" then
        return nil, "Entry YAML must be a string"
    end

    local parsed_entry, err = yaml.decode(entry_yaml)
    if not parsed_entry then
        return nil, "Failed to parse YAML: " .. (err or "unknown error")
    end

    -- Handle both direct object format and YAML list format
    local entry_data
    if type(parsed_entry) == "table" then
        if parsed_entry.name and parsed_entry.kind then
            -- Direct object format: {name: "...", kind: "...", ...}
            entry_data = parsed_entry
        elseif type(parsed_entry[1]) == "table" and parsed_entry[1].name and parsed_entry[1].kind then
            -- YAML list format: [{name: "...", kind: "...", ...}] or multiple entries
            if #parsed_entry > 1 then
                return nil, "Multiple entries found - please specify one entry at a time"
            end
            entry_data = parsed_entry[1]
        else
            return nil, "Entry must have 'name' and 'kind' fields"
        end
    else
        return nil, "Entry must have 'name' and 'kind' fields"
    end

    -- Get existing entries to create namespace context for resolution
    local existing_entries, _ = get_namespace_entries(namespace, session)
    if not existing_entries then
        existing_entries = {}
    end

    -- Create namespace object with existing entries
    local namespace_obj = ns.new(namespace, existing_entries)

    -- Create minimal YAML with just this entry for resolution
    local single_entry_yaml = "version: \"1.0\"\nnamespace: " .. namespace .. "\nentries:\n  - " ..
                              entry_yaml:gsub("\n", "\n    ")

    -- Use ns resolve functionality to handle file:// references and content preservation
    local resolved_entries, resolve_err = namespace_obj:resolve(single_entry_yaml)
    if not resolved_entries then
        return nil, "Failed to resolve entry YAML: " .. (resolve_err or "unknown error")
    end

    if #resolved_entries ~= 1 then
        return nil, "Expected exactly one resolved entry, got " .. #resolved_entries
    end

    return resolved_entries[1], nil
end

local function handler(params)
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end
    local user_id = actor:id()

    local workspace_id, err = ctx.get("workspace_id")
    if err then
        return nil, "Cannot access workspace context: " .. err
    end
    if not workspace_id or workspace_id == "" then
        return nil, "No active workspace"
    end

    local session, err = workspace.open(workspace_id, user_id)
    if err then
        return nil, "Cannot access workspace: " .. err
    end

    if not params.action then
        return nil, "Missing action (view, append, delete, update)"
    end

    local valid_actions = { view = true, append = true, delete = true, update = true }
    if not valid_actions[params.action] then
        return nil, "Invalid action: " .. params.action .. " (must be: view, append, delete, update)"
    end

    if not params.namespace then
        return nil, "Missing namespace"
    end

    local namespace = normalize_namespace_path(params.namespace)
    if not namespace then
        return nil, "Invalid namespace path"
    end

    if params.action == "view" then
        -- Get current entries and generate YAML
        local entries, err = get_namespace_entries(namespace, session)
        if err then
            -- If namespace doesn't exist, return empty index
            entries = {}
        end

        local namespace_obj = ns.new(namespace, entries)
        local yaml_content, yaml_err = namespace_obj:to_yaml()
        if yaml_err then
            return nil, "Failed to generate YAML: " .. yaml_err
        end

        return yaml_content, nil

    elseif params.action == "append" then
        if not params.entry_id then
            return nil, "Missing entry_id for append action"
        end
        if not params.entry_yaml then
            return nil, "Missing entry_yaml for append action"
        end

        -- Parse the entry YAML using ns resolution
        local new_entry, parse_err = parse_yaml_entry(params.entry_yaml, namespace, session)
        if parse_err then
            return nil, "Entry parsing failed: " .. parse_err
        end

        -- Verify entry_id matches the parsed name
        if params.entry_id ~= new_entry.id then
            return nil, "Entry ID mismatch: expected " .. new_entry.id .. ", got " .. params.entry_id
        end

        -- Check if entry already exists
        local existing_entries, _ = get_namespace_entries(namespace, session)
        if existing_entries then
            for _, entry in ipairs(existing_entries) do
                if entry.id == params.entry_id then
                    return nil, "Entry already exists: " .. params.entry_id .. " (use update action instead)"
                end
            end
        end

        -- Create the entry
        local entry_info = {
            kind = new_entry.kind,
            data = new_entry.data,
            meta = new_entry.meta
        }
        local result, upsert_err = session:upsert_entry(params.entry_id, entry_info)
        if upsert_err then
            return nil, "Failed to create entry: " .. upsert_err
        end

        return "Entry appended successfully: " .. params.entry_id, nil

    elseif params.action == "delete" then
        if not params.entry_id then
            return nil, "Missing entry_id for delete action"
        end

        -- Check if entry exists in workspace
        local workspace_entry, _ = session:get_workspace(params.entry_id)
        local original_entry, _ = session:get_original(params.entry_id)

        if not workspace_entry and not original_entry then
            return nil, "Entry not found: " .. params.entry_id
        end

        if original_entry then
            -- Entry exists in main registry, mark it as deleted
            local result, delete_err = session:delete_entry(params.entry_id)
            if delete_err then
                return nil, "Failed to delete entry: " .. delete_err
            end
        else
            -- Entry doesn't exist in main registry (was created in workspace)
            -- Reset it instead of deleting
            local result, reset_err = session:reset_entry(params.entry_id)
            if reset_err then
                return nil, "Failed to reset entry: " .. reset_err
            end
        end

        return "Entry deleted successfully: " .. params.entry_id, nil

    elseif params.action == "update" then
        if not params.entry_id then
            return nil, "Missing entry_id for update action"
        end
        if not params.entry_yaml then
            return nil, "Missing entry_yaml for update action"
        end

        -- Parse the entry YAML using ns resolution
        local updated_entry, parse_err = parse_yaml_entry(params.entry_yaml, namespace, session)
        if parse_err then
            return nil, "Entry parsing failed: " .. parse_err
        end

        -- Verify entry_id matches the parsed name
        if params.entry_id ~= updated_entry.id then
            return nil, "Entry ID mismatch: expected " .. updated_entry.id .. ", got " .. params.entry_id
        end

        -- Check if entry exists
        local workspace_entry, _ = session:get_workspace(params.entry_id)
        local original_entry, _ = session:get_original(params.entry_id)

        if not workspace_entry and not original_entry then
            return nil, "Entry not found: " .. params.entry_id .. " (use append action to create)"
        end

        -- Update the entry
        local entry_info = {
            kind = updated_entry.kind,
            data = updated_entry.data,
            meta = updated_entry.meta
        }
        local result, upsert_err = session:upsert_entry(params.entry_id, entry_info)
        if upsert_err then
            return nil, "Failed to update entry: " .. upsert_err
        end

        return "Entry updated successfully: " .. params.entry_id, nil
    end
end

return { handler = handler }