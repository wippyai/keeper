local json = require("json")
local security = require("security")
local ctx = require("ctx")
local rfs = require("rfs")
local scanner = require("scanner")
local workspace = require("workspace")
local renderer = require("renderer")
local snapshot = require("snapshot")
local registry = require("registry")

-- Helper function to normalize path format (both slash and dot notation)
local function normalize_namespace_path(path)
    if not path or type(path) ~= "string" or path == "." then
        return path
    end

    -- Convert slash notation to dot notation for internal use
    return path:gsub("/", ".")
end

-- Helper function to safely convert workspace_id to string
local function safe_workspace_id_to_string(workspace_id)
    if not workspace_id then
        return nil
    end
    
    local id_type = type(workspace_id)
    if id_type == "string" then
        return workspace_id
    elseif id_type == "table" then
        -- If it's a table, try to extract the id field or convert to JSON
        if workspace_id.id then
            return tostring(workspace_id.id)
        elseif workspace_id[1] then
            return tostring(workspace_id[1])
        else
            -- Fallback to JSON representation for debugging
            local json = require("json")
            local success, result = pcall(json.encode, workspace_id)
            if success then
                return "table:" .. result
            else
                return "table:unparseable"
            end
        end
    else
        return tostring(workspace_id)
    end
end

-- Helper function to get namespace entries efficiently
local function get_namespace_entries(namespace, session, show_original)
    if session and not show_original then
        return snapshot.get_namespace_snapshot(session, namespace)
    else
        -- Query registry directly for the specific namespace - much more efficient
        return registry.find({[".ns"] = namespace})
    end
end

local function handler(params)
    if not params.operation then
        return nil, "operation is required (tree, files, search)"
    end

    local valid_operations = { tree = true, files = true, search = true }
    if not valid_operations[params.operation] then
        return nil, "Invalid operation. Use: tree, files, search"
    end

    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end
    local user_id = actor:id()

    local ctx_workspace_id_raw, _ = ctx.get("workspace_id")
    local ctx_workspace_id = safe_workspace_id_to_string(ctx_workspace_id_raw)
    local param_workspace_id = params.workspace_id

    if ctx_workspace_id and param_workspace_id and ctx_workspace_id ~= param_workspace_id then
        return nil, "Context conflict detected. Workspace '" .. ctx_workspace_id ..
               "' is active in context, but workspace_id parameter '" .. param_workspace_id ..
               "' was also provided. Context workspace takes precedence - remove workspace_id parameter."
    end

    local active_workspace_id = ctx_workspace_id or param_workspace_id
    local session = nil

    -- Check for show_original parameter to bypass workspace overlay
    local show_original = params.show_original or false

    if active_workspace_id and not show_original then
        local session_result, err = workspace.open(active_workspace_id, user_id)
        if err then
            return nil, "Failed to open workspace session: " .. err
        end
        session = session_result
    end

    if params.operation == "tree" then
        return tree_operation(params, session, show_original)
    elseif params.operation == "files" then
        return files_operation(params, session, show_original)
    elseif params.operation == "search" then
        return search_operation(params, session, show_original)
    end
end

function tree_operation(params, session, show_original)
    local root = params.root or "."
    local depth = params.depth or -1
    local show_entries = params.show_entries ~= false -- default true

    -- Normalize the root path to handle both slash and dot notation
    local normalized_root = normalize_namespace_path(root)

    -- Use RFS reader directly (no scanner needed for tree operations)
    local reader = rfs.reader()
    if session and not show_original then
        reader = reader:from_workspace(session)
    else
        reader = reader:from_registry()
    end

    local tree_data, err = reader:get_tree(normalized_root)
    if err then
        return nil, err
    end

    -- Enhance tree_data with entries for each namespace
    if show_entries then
        for _, ns_info in ipairs(tree_data.namespaces) do
            local entries, entries_err = get_namespace_entries(ns_info.namespace, session, show_original)
            if not entries_err and entries then
                ns_info.entries = entries
            else
                ns_info.entries = {}
            end
        end
    end

    return renderer.format_namespace_tree(tree_data, session, show_original), nil
end

function files_operation(params, session, show_original)
    if not params.paths or #params.paths == 0 then
        return nil, "paths array is required for files operation"
    end

    -- Use RFS reader directly (no scanner needed for file operations)
    local reader = rfs.reader():include_status(true)
    if session and not show_original then
        reader = reader:from_workspace(session)
    else
        reader = reader:from_registry()
    end

    local results = reader:read_files(params.paths)

    return renderer.format_file_listing(results, session, show_original), nil
end

function search_operation(params, session, show_original)
    if not params.query then
        return nil, "query is required for search operation"
    end

    local search_type = params.search_type or "text"
    local limit = params.limit or 10  -- Keep reasonable default limit

    -- Use RFS reader for search operations
    local reader = rfs.reader()
    if session and not show_original then
        reader = reader:from_workspace(session)
    else
        reader = reader:from_registry()
    end

    -- Create scanner only for search operations
    local text_scanner, err = scanner.new(reader)
    if err then
        return nil, "Failed to create scanner: " .. err
    end

    -- Build search index automatically when needed
    local scanner_instance, build_err = text_scanner:build_index()
    if build_err then
        return nil, "Failed to build search index: " .. tostring(build_err)
    end

    -- Prepare queries
    local queries = {}
    if search_type == "regex" then
        queries.main = { regex = params.query }
    else
        queries.main = params.query
    end

    -- Execute search with limit passed to scanner for early termination
    local search_results, search_err = text_scanner:search(queries, { limit = limit })
    if search_err then
        return nil, "Search failed: " .. search_err
    end

    -- Note: Scanner now handles limiting internally, but we keep this for safety
    if search_results.main and limit and #search_results.main > limit then
        local limited_results = {}
        for i = 1, limit do
            table.insert(limited_results, search_results.main[i])
        end
        search_results.main = limited_results
    end

    return renderer.format_search_results(search_results, params.query, search_type, session, show_original), nil
end

return { handler = handler }