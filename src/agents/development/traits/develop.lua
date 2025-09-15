-- Enhanced develop.lua with flattened context structure
local json = require("json")
local uuid = require("uuid")
local ctx = require("ctx")
local registry = require("registry")
local funcs = require("funcs")
local client = require("develop_client")
local consts = require("df_consts")
local text = require("text")

local CLASS_NAME = "development"
local ENABLE_SEARCH = false

local NODE_TYPE_AGENT = "userspace.dataflow.node.agent:node"
local INIT_FUNC_ARTIFACT = "userspace.dataflow.session:artifact"
local EXPLORE_FUNC_ID = "keeper.overlay.traits.explore:explore"

local function deduplicate_array(arr)
    local seen = {}
    local result = {}
    for _, item in ipairs(arr or {}) do
        if not seen[item] then
            seen[item] = true
            table.insert(result, item)
        end
    end
    return result
end

local function extract_smart_context(context_string)
    if type(context_string) ~= "string" then
        return context_string
    end

    local context = {
        namespaces = {},
        files = {},
        entries = {}
    }

    -- Namespace:entry pattern (e.g., "userspace.kb9:query_service")
    local entry_regex, err = text.regexp.compile("([a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*):([a-z][a-z0-9_]*)")
    if not err and entry_regex then
        local matches = entry_regex:find_all_string_submatch(context_string)
        for _, match in ipairs(matches or {}) do
            if #match >= 3 then
                local full_id = match[1] .. ":" .. match[2]
                table.insert(context.entries, full_id)

                -- Add namespace too
                local namespace = match[1]
                local found = false
                for _, ns in ipairs(context.namespaces) do
                    if ns == namespace then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(context.namespaces, namespace)
                end
            end
        end
    end

    -- File path patterns (e.g., "userspace/kb9/views/manage.jet", "_index.yaml")
    local file_regex, err = text.regexp.compile("([a-z][a-z0-9]*(?:/[a-z][a-z0-9_]*)*\\.(?:lua|yaml|jet|json|md))")
    if not err and file_regex then
        local matches = file_regex:find_all_string(context_string)
        for _, file_path in ipairs(matches or {}) do
            table.insert(context.files, file_path)
        end
    end

    -- Quoted file paths (e.g., "userspace/kb9/views/manage.jet")
    local quoted_file_regex, err = text.regexp.compile("\"([^\"]+\\.(?:lua|yaml|jet|json|md))\"")
    if not err and quoted_file_regex then
        local matches = quoted_file_regex:find_all_string_submatch(context_string)
        for _, match in ipairs(matches or {}) do
            if #match >= 2 then
                table.insert(context.files, match[2])
            end
        end
    end

    -- _index.yaml references
    local index_regex, err = text.regexp.compile("([a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*)")
    if not err and index_regex then
        local matches = index_regex:find_all_string(context_string)
        for _, namespace in ipairs(matches or {}) do
            -- Add _index.yaml files for namespaces
            local index_path = namespace:gsub("%.", "/") .. "/_index.yaml"
            local found = false
            for _, file in ipairs(context.files) do
                if file == index_path then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(context.files, index_path)
            end

            -- Add to namespaces if not already there
            local ns_found = false
            for _, ns in ipairs(context.namespaces) do
                if ns == namespace then
                    ns_found = true
                    break
                end
            end
            if not ns_found then
                table.insert(context.namespaces, namespace)
            end
        end
    end

    return context
end

local function load_workspace_context()
    local workspace_id, _ = ctx.get("workspace_id")
    if not workspace_id then
        return ""
    end

    local executor = funcs.new()

    local workspace_result, workspace_err = executor:call("keeper.overlay.traits.explore:workspace", {
        include_context = true,
        verbose = true
    })

    if workspace_result and not workspace_err then
        return "\n\n## Active Workspace Context\n\n" .. workspace_result
    else
        return ""
    end
end

local function normalize_context_params(params)
    -- Handle both flattened structure and legacy nested context
    local context_params = {
        namespaces = params.namespaces or {},
        files = params.files or {},
        entries = params.entries or {},
        search = params.search or {}
    }

    -- If legacy context structure is provided, merge it
    if params.context and type(params.context) == "table" then
        context_params.namespaces = params.context.namespaces or context_params.namespaces
        context_params.files = params.context.files or context_params.files
        context_params.entries = params.context.entries or context_params.entries
        context_params.search = params.context.search or context_params.search
    end

    -- Apply smart context extraction if request is a string with embedded context
    -- BUT DO NOT extract search terms heuristically
    if params.request and type(params.request) == "string" then
        local extracted = extract_smart_context(params.request)
        if extracted and type(extracted) == "table" then
            -- Merge extracted context with existing context
            for _, ns in ipairs(extracted.namespaces or {}) do
                table.insert(context_params.namespaces, ns)
            end
            for _, file in ipairs(extracted.files or {}) do
                table.insert(context_params.files, file)
            end
            for _, entry in ipairs(extracted.entries or {}) do
                table.insert(context_params.entries, entry)
            end
            -- NO heuristic search extraction
        end
    end

    -- Deduplicate all arrays
    context_params.namespaces = deduplicate_array(context_params.namespaces)
    context_params.files = deduplicate_array(context_params.files)
    context_params.entries = deduplicate_array(context_params.entries)
    context_params.search = deduplicate_array(context_params.search)

    return context_params
end

local function load_context_data(context_params)
    if not context_params then
        return ""
    end

    local context_sections = {}
    local executor = funcs.new()

    if context_params.namespaces and #context_params.namespaces > 0 then
        table.insert(context_sections, "## Namespace Structures")
        for _, namespace in ipairs(context_params.namespaces) do
            local tree_result, tree_err = executor:call(EXPLORE_FUNC_ID, {
                operation = "tree",
                root = namespace,
                depth = 2,
                show_entries = true
            })
            if tree_result and not tree_err then
                table.insert(context_sections, "### " .. namespace)
                table.insert(context_sections, tree_result)
            else
                table.insert(context_sections, "### " .. namespace .. " (error: " .. (tree_err or "unknown") .. ")")
            end
        end
    end

    if context_params.files and #context_params.files > 0 then
        table.insert(context_sections, "## File Contents")
        local files_result, files_err = executor:call(EXPLORE_FUNC_ID, {
            operation = "files",
            paths = context_params.files
        })
        if files_result and not files_err then
            table.insert(context_sections, files_result)
        else
            table.insert(context_sections, "Error loading files: " .. (files_err or "unknown"))
        end
    end

    if context_params.entries and #context_params.entries > 0 then
        table.insert(context_sections, "## Registry Entries")
        local entry_files = {}
        for _, entry_id in ipairs(context_params.entries) do
            local namespace = entry_id:match("^([^:]+):")
            if namespace then
                local namespace_path = namespace:gsub("%.", "/")
                table.insert(entry_files, namespace_path .. "/_index.yaml")
            end
        end

        if #entry_files > 0 then
            -- Deduplicate entry files
            entry_files = deduplicate_array(entry_files)
            local entries_result, entries_err = executor:call(EXPLORE_FUNC_ID, {
                operation = "files",
                paths = entry_files
            })
            if entries_result and not entries_err then
                table.insert(context_sections, entries_result)
            else
                table.insert(context_sections, "Error loading entries: " .. (entries_err or "unknown"))
            end
        end
    end

    -- Only run search when ENABLE_SEARCH is true AND search params are provided
    if ENABLE_SEARCH and context_params.search and #context_params.search > 0 then
        table.insert(context_sections, "## Search Results")
        for _, search_query in ipairs(context_params.search) do
            local search_result, search_err = executor:call(EXPLORE_FUNC_ID, {
                operation = "search",
                query = search_query,
                search_type = "regex",
                limit = 20
            })
            if search_result and not search_err then
                table.insert(context_sections, "### Search: " .. search_query)
                table.insert(context_sections, search_result)
            else
                table.insert(context_sections,
                    "### Search: " .. search_query .. " (error: " .. (search_err or "unknown") .. ")")
            end
        end
    end

    if #context_sections > 0 then
        return "\n\n" .. table.concat(context_sections, "\n\n")
    else
        return ""
    end
end

local function extract_data_field(result)
    if not result then
        return "No result returned"
    elseif type(result) == "string" then
        return result
    elseif type(result) == "table" then
        -- Check if this looks like a dataflow result structure
        if result.data then
            -- Extract the data field
            if type(result.data) == "string" then
                return result.data
            else
                return json.encode(result.data)
            end
        else
            -- Fallback to full JSON if no data field
            return json.encode(result)
        end
    else
        return tostring(result)
    end
end

local function handler(params)
    if not params.request or type(params.request) ~= "string" or params.request:gsub("%s", "") == "" then
        return "ERROR: Missing or empty request parameter"
    end

    if not params.agent_id or type(params.agent_id) ~= "string" or params.agent_id:gsub("%s", "") == "" then
        return "ERROR: Missing or empty agent_id parameter"
    end

    local agent_entry, err = registry.get(params.agent_id)
    if err or not agent_entry then
        return "ERROR: Agent not found: " .. params.agent_id
    end

    if agent_entry.meta.type ~= "agent.gen1" then
        return "ERROR: Invalid agent type: " .. params.agent_id .. " is not an agent"
    end

    local has_valid_class = false
    if agent_entry.meta.class then
        for _, class in ipairs(agent_entry.meta.class) do
            if class == CLASS_NAME then
                has_valid_class = true
                break
            end
        end
    end

    if not has_valid_class then
        return "ERROR: Invalid agent class: " .. params.agent_id .. " must be " .. CLASS_NAME
    end

    local agent_title = agent_entry.meta.title or agent_entry.meta.name or agent_entry.name

    -- Normalize context parameters (handles both flattened and nested structure)
    local context_params = normalize_context_params(params)
    local context_data = load_context_data(context_params)
    local workspace_context = load_workspace_context()
    local full_context = workspace_context .. context_data

    local session_context, ctx_err = ctx.all()
    if ctx_err then
        session_context = {}
    end

    session_context.from_agent_id = session_context.from_agent_id or "keeper.agents.manager:manager"
    session_context.to_agent_id = params.agent_id

    if session_context.dataflow_id then
        return {
            _control = {
                delegate = {
                    {
                        agent_id = params.agent_id,
                        system_prompt = full_context,
                        input_data = params.request,
                        max_iterations = session_context.max_iterations or 64,
                        tool_calling = "auto",
                        context = session_context,
                        traits = {},
                        tools = {},
                        exit_schema = nil
                    }
                }
            }
        }
    else
        local c, client_err = client.new()
        if client_err then
            return "ERROR: Failed to create client: " .. client_err
        end

        local node_id = uuid.v7()
        local input_data_id = uuid.v7()
        local node_input_id = uuid.v7()

        local workflow_commands = table.freeze({
            {
                type = consts.COMMAND_TYPES.CREATE_NODE,
                payload = {
                    node_id = node_id,
                    node_type = NODE_TYPE_AGENT,
                    status = consts.STATUS.PENDING,
                    config = {
                        agent = params.agent_id,
                        arena = {
                            prompt = full_context,
                            max_iterations = session_context.max_iterations or 64,
                            min_iterations = 1,
                            tool_calling = "auto",
                            context = session_context
                        },
                        data_targets = {
                            { data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT, content_type = consts.CONTENT_TYPE.JSON }
                        }
                    },
                    metadata = {
                        title = agent_title
                    }
                }
            },
            {
                type = consts.COMMAND_TYPES.CREATE_DATA,
                payload = {
                    data_id = input_data_id,
                    data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                    content = params.request,
                    content_type = consts.CONTENT_TYPE.TEXT
                }
            },
            {
                type = consts.COMMAND_TYPES.CREATE_DATA,
                payload = {
                    data_id = node_input_id,
                    data_type = consts.DATA_TYPE.NODE_INPUT,
                    key = input_data_id,
                    node_id = node_id,
                    content_type = consts.CONTENT_TYPE.REFERENCE,
                    content = ""
                }
            }
        })

        local dataflow_id, create_err = c:create_workflow(workflow_commands, {
            metadata = {
                title = agent_title,
                target_agent = params.agent_id
            }
        })

        if create_err then
            return "ERROR: Failed to create workflow: " .. create_err
        end

        local result, exec_err = c:execute(dataflow_id, {
            init_func_id = INIT_FUNC_ARTIFACT
        })

        if exec_err then
            return "ERROR: Failed to execute workflow: " .. exec_err
        end

        local result_str = extract_data_field(result)

        return "DELEGATED TO: " ..
        agent_title .. " [" .. params.agent_id .. "]\nWORKFLOW: " .. dataflow_id .. "\nRESULT:\n" .. result_str
    end
end

return { handler = handler }