local logger = require("logger")
local json = require("json")
local ctx = require("ctx")
local treesitter = require("treesitter")

local log = logger:named("lint.method")

-- Constants for operations and Lua kinds
local CONST = {
    OPERATIONS = {
        CREATE = "entry.create",
        UPDATE = "entry.update",
        DELETE = "entry.delete"
    },
    LUA_KINDS = {
        "function.lua",
        "process.lua",
        "workflow.lua"
    }
}

-- Check if entry kind is a Lua type
local function is_lua_entry(kind)
    for _, lua_kind in ipairs(CONST.LUA_KINDS) do
        if kind == lua_kind then
            return true
        end
    end
    return false
end

-- Extract method name from Lua source return statement
local function extract_method_from_return(source)
    if not source or source == "" then
        return nil, "Empty source code"
    end

    -- Parse the Lua code
    local tree, parse_err = treesitter.parse("lua", source)
    if not tree then
        return nil, "Parse error: " .. (parse_err or "Unknown parsing error")
    end

    -- Check for syntax errors
    if tree:root_node():has_error() then
        tree:close()
        return nil, "Syntax errors in source code"
    end

    -- Query for return statements
    local query_str = "(return_statement) @return_stmt"
    local query, query_err = treesitter.query("lua", query_str)
    if not query then
        tree:close()
        return nil, "Query error: " .. (query_err or "Unknown query error")
    end

    -- Find all return statements
    local matches = query:matches(tree:root_node(), source)
    if #matches == 0 then
        query:close()
        tree:close()
        return nil, "No return statement found"
    end

    -- Get the last return statement (module export)
    local last_match = matches[#matches]
    local return_node = nil

    for _, capture in ipairs(last_match.captures) do
        if capture.name == "return_stmt" then
            return_node = capture.node
            break
        end
    end

    if not return_node then
        query:close()
        tree:close()
        return nil, "Could not extract return statement"
    end

    -- Get expression list from return statement
    local expr_list = nil
    for i = 0, return_node:named_child_count() - 1 do
        local child = return_node:named_child(i)
        if child:kind() == "expression_list" then
            expr_list = child
            break
        end
    end

    if not expr_list or expr_list:named_child_count() == 0 then
        query:close()
        tree:close()
        return nil, "Empty return statement"
    end

    -- Get the first expression
    local first_expr = expr_list:named_child(0)
    local method_name = nil

    -- Case 1: return identifier (e.g., "return handler")
    if first_expr:kind() == "identifier" then
        method_name = first_expr:text(source)
    end

    -- Case 2: return table (e.g., "return { handler = handler }")
    if first_expr:kind() == "table_constructor" then
        -- Look for single field
        local field_count = 0
        local field_name = nil

        for i = 0, first_expr:named_child_count() - 1 do
            local child = first_expr:named_child(i)
            if child:kind() == "field" then
                field_count = field_count + 1

                -- Get field name from first field
                if field_count == 1 and child:named_child_count() >= 1 then
                    local name_node = child:named_child(0)
                    if name_node:kind() == "identifier" then
                        field_name = name_node:text(source)
                    end
                end
            end
        end

        -- Use field name if only one field
        if field_count == 1 and field_name then
            method_name = field_name
        end
    end

    -- Clean up
    query:close()
    tree:close()

    if method_name then
        return method_name, nil
    else
        return nil, "Could not determine method from return statement"
    end
end

-- Main handler function
local function handle(request)
    log:info("Starting method validation for Lua entries")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to method validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Validating methods", {
        changeset_count = #changeset
    })

    local issues = {}
    local valid_changeset = {}
    local entries_processed = 0
    local entries_with_issues = 0

    -- Process each operation in the changeset
    for i, op in ipairs(changeset) do
        entries_processed = entries_processed + 1

        -- Skip DELETE operations
        if op.kind == CONST.OPERATIONS.DELETE then
            table.insert(valid_changeset, op)
            goto continue
        end

        -- Only process Lua entries
        if not op.entry or not is_lua_entry(op.entry.kind) then
            table.insert(valid_changeset, op)
            goto continue
        end

        -- Validate operation structure
        if not op.entry.data then
            entries_with_issues = entries_with_issues + 1
            table.insert(issues, {
                level = "error",
                code = "MISSING_DATA",
                message = "Entry data section is missing",
                entry_id = op.entry.id or "unknown"
            })
            goto continue
        end

        local entry_id = op.entry.id or ("index:" .. i)

        -- Debug: log the data structure to understand what's missing
        log:debug("Processing entry", {
            entry_id = entry_id,
            kind = op.entry.kind,
            has_method = op.entry.data.method ~= nil,
            method_value = op.entry.data.method,
            has_source = op.entry.data.source ~= nil,
            source_length = op.entry.data.source and #op.entry.data.source or 0
        })

        -- Check if method field exists
        local has_method = op.entry.data.method and op.entry.data.method ~= ""
        local has_source = op.entry.data.source and op.entry.data.source ~= ""

        if not has_method then
            if not has_source then
                -- No method and no source
                entries_with_issues = entries_with_issues + 1
                table.insert(issues, {
                    level = "error",
                    code = "MISSING_METHOD_AND_SOURCE",
                    message = "Entry missing both 'method' field and source code to analyze",
                    entry_id = entry_id
                })
                goto continue
            else
                -- No method but has source - try to extract and add
                local method_name, err = extract_method_from_return(op.entry.data.source)
                if method_name then
                    -- Add the method to the entry
                    op.entry.data.method = method_name
                    table.insert(issues, {
                        level = "warning",
                        code = "METHOD_ADDED",
                        message = "Added missing method '" .. method_name .. "' based on source code analysis",
                        entry_id = entry_id
                    })
                    log:info("Added method '" .. method_name .. "' to entry: " .. entry_id)
                else
                    -- Could not determine method from source
                    entries_with_issues = entries_with_issues + 1
                    table.insert(issues, {
                        level = "error",
                        code = "MISSING_METHOD",
                        message = "Missing required 'method' field and could not determine from source: " ..
                        (err or "unknown error"),
                        entry_id = entry_id
                    })
                    goto continue
                end
            end
        else
            -- Method exists - validate against source if available
            if has_source then
                local declared_method = op.entry.data.method
                local detected_method, err = extract_method_from_return(op.entry.data.source)

                if detected_method and detected_method ~= declared_method then
                    table.insert(issues, {
                        level = "warning",
                        code = "METHOD_MISMATCH",
                        message = "Declared method '" ..
                        declared_method ..
                        "' does not match detected method '" .. detected_method .. "' from return statement",
                        entry_id = entry_id
                    })
                elseif not detected_method then
                    table.insert(issues, {
                        level = "info",
                        code = "METHOD_NOT_DETECTABLE",
                        message = "Could not verify method '" ..
                        declared_method .. "' against source: " .. (err or "unknown error"),
                        entry_id = entry_id
                    })
                end
            else
                -- Has method but no source to verify against
                table.insert(issues, {
                    level = "info",
                    code = "NO_SOURCE_TO_VERIFY",
                    message = "Method '" ..
                    op.entry.data.method .. "' declared but no source code available for verification",
                    entry_id = entry_id
                })
            end
        end

        -- Entry processed
        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Method validation completed", {
        entries_processed = entries_processed,
        entries_with_issues = entries_with_issues,
        entries_valid = #valid_changeset,
        issues_count = #issues
    })

    -- Always return success so pipeline shows detailed issues
    local success = true

    return {
        success = success,
        changeset = valid_changeset,
        issues = issues,
        message = entries_with_issues > 0 and ("Method validation found issues in " .. entries_with_issues .. " entries") or
        "Method validation completed"
    }
end

return { handle = handle }