local json = require("json")
local uuid = require("uuid")
local ctx = require("ctx")
local registry = require("registry")
local funcs = require("funcs")
local client = require("develop_client")
local consts = require("df_consts")
local text = require("text")

local CLASS_NAME = "research"
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

local function xml_escape(str)
    if not str then return "" end
    str = tostring(str)
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub("\"", "&quot;")
    str = str:gsub("'", "&apos;")
    return str
end

local function parse_workspace_status(workspace_text)
    local status = {
        modified_files = 0,
        new_files = 0,
        deleted_files = 0
    }
    
    if not workspace_text then
        return status
    end
    
    -- Count status indicators in workspace output
    for line in workspace_text:gmatch("[^\r\n]+") do
        if line:match("~modified") then
            status.modified_files = status.modified_files + 1
        elseif line:match("%+new") then
            status.new_files = status.new_files + 1
        elseif line:match("%-deleted") then
            status.deleted_files = status.deleted_files + 1
        end
    end
    
    return status
end

local function extract_workspace_permissions(workspace_text)
    local permissions = {}
    
    if not workspace_text then
        return permissions
    end
    
    -- Extract permission information from workspace text
    local in_permissions = false
    for line in workspace_text:gmatch("[^\r\n]+") do
        if line:match("^Permissions:") then
            in_permissions = true
        elseif in_permissions and line:match("^%s+") then
            local scope, access = line:match("^%s+([^:]+):%s*(.+)")
            if scope and access then
                table.insert(permissions, {
                    scope = scope:gsub("%s+", ""),
                    access = access:gsub("%s+", "")
                })
            end
        elseif in_permissions and not line:match("^%s") then
            in_permissions = false
        end
    end
    
    return permissions
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

    if not workspace_result or workspace_err then
        return ""
    end

    -- Extract workspace title and description from result
    local title = workspace_result:match("([^\r\n]+)") or "Unknown Workspace"
    local description = ""
    
    -- Look for description pattern in workspace output
    local desc_match = workspace_result:match("Description:%s*([^\r\n]+)")
    if desc_match then
        description = desc_match
    end
    
    local status = parse_workspace_status(workspace_result)
    local permissions = extract_workspace_permissions(workspace_result)
    
    local xml_parts = {}
    table.insert(xml_parts, "  <workspace>")
    table.insert(xml_parts, "    <id>" .. xml_escape(workspace_id) .. "</id>")
    table.insert(xml_parts, "    <title>" .. xml_escape(title) .. "</title>")
    if description ~= "" then
        table.insert(xml_parts, "    <description>" .. xml_escape(description) .. "</description>")
    end
    
    table.insert(xml_parts, "    <permissions>")
    for _, perm in ipairs(permissions) do
        table.insert(xml_parts, "      <permission scope=\"" .. xml_escape(perm.scope) .. 
                    "\" access=\"" .. xml_escape(perm.access) .. "\"/>")
    end
    table.insert(xml_parts, "    </permissions>")
    
    table.insert(xml_parts, "    <status>")
    table.insert(xml_parts, "      <modified_files>" .. status.modified_files .. "</modified_files>")
    table.insert(xml_parts, "      <new_files>" .. status.new_files .. "</new_files>")
    table.insert(xml_parts, "      <deleted_files>" .. status.deleted_files .. "</deleted_files>")
    table.insert(xml_parts, "    </status>")
    
    table.insert(xml_parts, "  </workspace>")
    
    return table.concat(xml_parts, "\n")
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

local function parse_file_status(file_path, files_content)
    -- Determine file status from workspace output patterns
    if not files_content then return "active" end
    
    -- Look for status indicators in the files content
    local status_pattern = file_path:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    
    if files_content:match(status_pattern .. "[^\r\n]*%+new") then
        return "new"
    elseif files_content:match(status_pattern .. "[^\r\n]*~modified") then
        return "modified"
    elseif files_content:match(status_pattern .. "[^\r\n]*%-deleted") then
        return "deleted"
    end
    
    return "active"
end

local function parse_entry_info_from_content(entry_id, content)
    -- Extract entry metadata from _index.yaml content
    local entry_info = {
        kind = "unknown",
        meta_type = "",
        title = "",
        comment = "",
        source = "",
        modules = {},
        imports = {}
    }
    
    if not content then return entry_info end
    
    -- Look for the specific entry in the YAML content
    local entry_name = entry_id:match(":([^:]+)$")
    if not entry_name then return entry_info end
    
    -- Find the entry block
    local entry_pattern = "%-%-%-[^\r\n]*" .. entry_name .. "[^\r\n]*\r?\n"
    local entry_start = content:find(entry_pattern)
    if not entry_start then
        -- Try simpler pattern
        entry_pattern = "name:%s*" .. entry_name
        entry_start = content:find(entry_pattern)
    end
    
    if entry_start then
        local entry_block = content:sub(entry_start, entry_start + 2000) -- Get reasonable chunk
        
        -- Extract kind
        local kind = entry_block:match("kind:%s*([^\r\n]+)")
        if kind then entry_info.kind = kind:gsub("%s+", "") end
        
        -- Extract meta type
        local meta_type = entry_block:match("type:%s*([^\r\n]+)")
        if meta_type then entry_info.meta_type = meta_type:gsub("%s+", "") end
        
        -- Extract title and comment
        local title = entry_block:match("title:%s*([^\r\n]+)")
        if title then entry_info.title = title:gsub("%s+", "") end
        
        local comment = entry_block:match("comment:%s*([^\r\n]+)")
        if comment then entry_info.comment = comment:gsub("^%s*", ""):gsub("%s*$", "") end
        
        -- Extract source
        local source = entry_block:match("source:%s*([^\r\n]+)")
        if source then entry_info.source = source:gsub("%s+", "") end
    end
    
    return entry_info
end

local function load_context_data(context_params)
    if not context_params then
        return ""
    end

    local xml_sections = {}
    local executor = funcs.new()

    -- Generate namespaces section
    if context_params.namespaces and #context_params.namespaces > 0 then
        table.insert(xml_sections, "  <namespaces>")
        
        for _, namespace in ipairs(context_params.namespaces) do
            local tree_result, tree_err = executor:call(EXPLORE_FUNC_ID, {
                operation = "tree",
                root = namespace,
                depth = 2,
                show_entries = true
            })
            
            if tree_result and not tree_err then
                table.insert(xml_sections, "    <namespace path=\"" .. xml_escape(namespace) .. "\" depth=\"2\"/>")
                table.insert(xml_sections, tree_result)
                table.insert(xml_sections, "")
            else
                table.insert(xml_sections, "    <namespace path=\"" .. xml_escape(namespace) .. "\" depth=\"2\" error=\"" .. 
                           xml_escape(tree_err or "unknown") .. "\"/>")
                table.insert(xml_sections, "")
            end
        end
        
        table.insert(xml_sections, "  </namespaces>")
    end

    -- Generate files section
    if context_params.files and #context_params.files > 0 then
        table.insert(xml_sections, "  <files>")
        
        local files_result, files_err = executor:call(EXPLORE_FUNC_ID, {
            operation = "files",
            paths = context_params.files
        })
        
        if files_result and not files_err then
            -- Parse individual files from the result
            local current_file = nil
            local current_content = {}
            
            for line in files_result:gmatch("[^\r\n]+") do
                local file_match = line:match("^%-%-%-+ ([^%s]+) %-%-%-+$")
                if file_match then
                    -- Save previous file if exists
                    if current_file then
                        local status = parse_file_status(current_file, files_result)
                        table.insert(xml_sections, "    <file path=\"" .. xml_escape(current_file) .. 
                                   "\" status=\"" .. status .. "\">")
                        table.insert(xml_sections, "      <content><![CDATA[")
                        table.insert(xml_sections, table.concat(current_content, "\n"))
                        table.insert(xml_sections, "      ]]></content>")
                        table.insert(xml_sections, "    </file>")
                    end
                    
                    -- Start new file
                    current_file = file_match
                    current_content = {}
                else
                    -- Add line to current file content
                    if current_file then
                        table.insert(current_content, line)
                    end
                end
            end
            
            -- Save last file
            if current_file then
                local status = parse_file_status(current_file, files_result)
                table.insert(xml_sections, "    <file path=\"" .. xml_escape(current_file) .. 
                           "\" status=\"" .. status .. "\">")
                table.insert(xml_sections, "      <content><![CDATA[")
                table.insert(xml_sections, table.concat(current_content, "\n"))
                table.insert(xml_sections, "      ]]></content>")
                table.insert(xml_sections, "    </file>")
            end
        else
            table.insert(xml_sections, "    <!-- Error loading files: " .. xml_escape(files_err or "unknown") .. " -->")
        end
        
        table.insert(xml_sections, "  </files>")
    end

    -- Generate entries section
    if context_params.entries and #context_params.entries > 0 then
        table.insert(xml_sections, "  <entries>")
        
        local entry_files = {}
        local entry_to_namespace = {}
        
        for _, entry_id in ipairs(context_params.entries) do
            local namespace = entry_id:match("^([^:]+):")
            if namespace then
                local namespace_path = namespace:gsub("%.", "/")
                local index_file = namespace_path .. "/_index.yaml"
                table.insert(entry_files, index_file)
                entry_to_namespace[entry_id] = index_file
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
                -- Parse entry information for each requested entry
                for _, entry_id in ipairs(context_params.entries) do
                    local index_file = entry_to_namespace[entry_id]
                    if index_file then
                        -- Extract content for this index file
                        local file_content = ""
                        local in_file = false
                        
                        for line in entries_result:gmatch("[^\r\n]+") do
                            local file_match = line:match("^%-%-%-+ ([^%s]+) %-%-%-+$")
                            if file_match then
                                in_file = (file_match == index_file)
                            elseif in_file then
                                file_content = file_content .. line .. "\n"
                            end
                        end
                        
                        local entry_info = parse_entry_info_from_content(entry_id, file_content)
                        
                        table.insert(xml_sections, "    <entry id=\"" .. xml_escape(entry_id) .. "\">")
                        table.insert(xml_sections, "      <kind>" .. xml_escape(entry_info.kind) .. "</kind>")
                        
                        if entry_info.meta_type ~= "" or entry_info.title ~= "" or entry_info.comment ~= "" then
                            local meta_attrs = {}
                            if entry_info.meta_type ~= "" then
                                table.insert(meta_attrs, "type=\"" .. xml_escape(entry_info.meta_type) .. "\"")
                            end
                            if entry_info.title ~= "" then
                                table.insert(meta_attrs, "title=\"" .. xml_escape(entry_info.title) .. "\"")
                            end
                            if entry_info.comment ~= "" then
                                table.insert(meta_attrs, "comment=\"" .. xml_escape(entry_info.comment) .. "\"")
                            end
                            
                            table.insert(xml_sections, "      <meta " .. table.concat(meta_attrs, " ") .. "/>")
                        end
                        
                        table.insert(xml_sections, "      <data>")
                        if entry_info.source ~= "" then
                            table.insert(xml_sections, "        <source>" .. xml_escape(entry_info.source) .. "</source>")
                        end
                        table.insert(xml_sections, "      </data>")
                        table.insert(xml_sections, "    </entry>")
                    end
                end
            else
                table.insert(xml_sections, "    <!-- Error loading entries: " .. xml_escape(entries_err or "unknown") .. " -->")
            end
        end
        
        table.insert(xml_sections, "  </entries>")
    end

    -- Generate search section
    if ENABLE_SEARCH and context_params.search and #context_params.search > 0 then
        table.insert(xml_sections, "  <search enabled=\"true\">")
        
        for _, search_query in ipairs(context_params.search) do
            local search_result, search_err = executor:call(EXPLORE_FUNC_ID, {
                operation = "search",
                query = search_query,
                search_type = "regex",
                limit = 20
            })
            
            if search_result and not search_err then
                table.insert(xml_sections, "    <query term=\"" .. xml_escape(search_query) .. "\" type=\"regex\" limit=\"20\">")
                table.insert(xml_sections, "      <results><![CDATA[")
                table.insert(xml_sections, search_result)
                table.insert(xml_sections, "      ]]></results>")
                table.insert(xml_sections, "    </query>")
            else
                table.insert(xml_sections, "    <query term=\"" .. xml_escape(search_query) .. "\" type=\"regex\" limit=\"20\" error=\"" .. 
                           xml_escape(search_err or "unknown") .. "\">")
                table.insert(xml_sections, "    </query>")
            end
        end
        
        table.insert(xml_sections, "  </search>")
    else
        table.insert(xml_sections, "  <search enabled=\"false\"/>")
    end

    return table.concat(xml_sections, "\n")
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
    
    -- Wrap everything in XML delegation_context root element
    local xml_parts = {}
    table.insert(xml_parts, "<delegation_context>")
    
    if workspace_context ~= "" then
        table.insert(xml_parts, workspace_context)
    end
    
    if context_data ~= "" then
        table.insert(xml_parts, context_data)
    end
    
    table.insert(xml_parts, "</delegation_context>")
    
    local full_context = table.concat(xml_parts, "\n")

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