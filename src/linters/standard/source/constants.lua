local logger = require("logger")
local json = require("json")
local ctx = require("ctx")
local treesitter = require("treesitter")

local log = logger:named("lint.constants")

-- Constants for operations and Lua kinds
local CONST = table.freeze({
    OPERATIONS = table.freeze({
        CREATE = "entry.create",
        UPDATE = "entry.update",
        DELETE = "entry.delete"
    }),
    LUA_KINDS = table.freeze({
        "function.lua",
        "library.lua",
        "process.lua",
        "workflow.lua"
    }),
    MAX_INLINE_STRING_LENGTH = 100,
    MIN_CONSTANT_NAME_LENGTH = 3
})

-- Patterns that indicate a variable should be a constant
local CONSTANT_INDICATORS = table.freeze({
    NAMING_PATTERNS = table.freeze({
        "^[A-Z][A-Z0-9_]*$",  -- ALL_CAPS
        "^CONST_",            -- CONST_ prefix
        "^CONFIG_",           -- CONFIG_ prefix
        "^DEFAULT_",          -- DEFAULT_ prefix
        "^ERROR_",            -- ERROR_ prefix
        "^STATUS_",           -- STATUS_ prefix
        "_CONST$",            -- _CONST suffix
        "_CONFIG$"            -- _CONFIG suffix
    })
})

-- Check if entry kind is a Lua type
local function is_lua_entry(kind)
    for _, lua_kind in ipairs(CONST.LUA_KINDS) do
        if kind == lua_kind then
            return true
        end
    end
    return false
end

-- Check if variable name suggests it should be a constant
local function should_be_constant(var_name)
    if not var_name or #var_name < CONST.MIN_CONSTANT_NAME_LENGTH then
        return false
    end

    for _, pattern in ipairs(CONSTANT_INDICATORS.NAMING_PATTERNS) do
        if var_name:match(pattern) then
            return true
        end
    end

    return false
end

-- Extract line number from position
local function get_line_number(source, pos)
    local line = 1
    for i = 1, pos do
        if source:sub(i, i) == '\n' then
            line = line + 1
        end
    end
    return line
end

-- Check if table.freeze is used
local function is_table_freeze_call(node, source)
    if not node or node:kind() ~= "function_call" then
        return false
    end

    local func_name = node:child(0)
    if not func_name then
        return false
    end

    -- Check for table.freeze
    if func_name:kind() == "dot_index_expression" then
        local obj = func_name:child(0)
        local method = func_name:child(2)
        if obj and method and
           obj:text(source) == "table" and
           method:text(source) == "freeze" then
            return true
        end
    end

    return false
end

-- Check if a node is at root level (not inside a function)
local function is_root_level_assignment(node, source)
    -- Walk up the parent chain to see if we're inside a function
    local current = node
    while current do
        local parent = current:parent()
        if not parent then
            break
        end

        -- If we find a function declaration in the parent chain, we're not at root level
        if parent:kind() == "function_declaration" or parent:kind() == "local_function_statement" then
            return false
        end

        current = parent
    end

    -- If we made it here without finding a function declaration, we're at root level
    return true
end

-- Track table mutations in source code
local function find_table_mutations(source)
    local mutations = {} -- {var_name = {line1, line2, ...}}
    
    local tree, parse_err = treesitter.parse("lua", source)
    if not tree then
        return mutations
    end

    if tree:root_node():has_error() then
        tree:close()
        return mutations
    end

    local function walk_for_mutations(node)
        if not node then return end
        
        local node_kind = node:kind()
        
        -- Look for assignments to table fields: table.field = value or table[key] = value
        if node_kind == "assignment_statement" then
            local var_list = nil
            for i = 0, node:named_child_count() - 1 do
                local child = node:named_child(i)
                if child and child:kind() == "variable_list" then
                    var_list = child
                    break
                end
            end
            
            if var_list then
                for i = 0, var_list:named_child_count() - 1 do
                    local var_node = var_list:named_child(i)
                    if var_node then
                        -- local var_text = var_node:text(source) -- unused
                        local base_var = nil
                        
                        -- Extract base variable name from dot notation (table.field)
                        if var_node:kind() == "dot_index_expression" then
                            local obj = var_node:child(0)
                            if obj then
                                base_var = obj:text(source)
                            end
                        -- Extract base variable name from bracket notation (table[key])
                        elseif var_node:kind() == "bracket_index_expression" then
                            local obj = var_node:child(0)
                            if obj then
                                base_var = obj:text(source)
                            end
                        end
                        
                        if base_var then
                            local line = get_line_number(source, var_node:start_byte())
                            if not mutations[base_var] then
                                mutations[base_var] = {}
                            end
                            table.insert(mutations[base_var], line)
                        end
                    end
                end
            end
        end
        
        -- Look for table.insert, table.remove calls
        if node_kind == "function_call" then
            local func_name = node:child(0)
            if func_name and func_name:kind() == "dot_index_expression" then
                local obj = func_name:child(0)
                local method = func_name:child(2)
                if obj and method then
                    -- local obj_name = obj:text(source) -- unused
                    local method_name = method:text(source)
                    
                    -- Check for table modification methods
                    if method_name == "insert" or method_name == "remove" or method_name == "sort" then
                        -- Get the first argument (the table being modified)
                        local args = node:child(1)
                        if args and args:kind() == "arguments" and args:named_child_count() > 0 then
                            local first_arg = args:named_child(0)
                            if first_arg then
                                local table_name = first_arg:text(source)
                                local line = get_line_number(source, node:start_byte())
                           if not mutations[table_name] then
                                    mutations[table_name] = {}
                                end
                                table.insert(mutations[table_name], line)
                            end
                        end
                    end
                end
            end
        end
        
        -- Recursively check children
        for i = 0, node:named_child_count() - 1 do
            local child = node:named_child(i)
            if child then
                walk_for_mutations(child)
            end
        end
    end
    
    walk_for_mutations(tree:root_node())
    tree:close()
    return mutations
end

-- Analyze constants and string literals in source code
local function analyze_constants_and_strings(source, entry_id)
    local issues = {}

    if not source or source == "" then
        return issues
    end

    -- Parse the Lua code
    local tree, parse_err = treesitter.parse("lua", source)
    if not tree then
        return issues
    end

    -- Check for syntax errors
    if tree:root_node():has_error() then
        tree:close()
        return issues
    end
    
    -- Find all table mutations first
    local table_mutations = find_table_mutations(source)

    -- Walk the AST safely with function scope tracking
    local function walk_node(node, function_depth)
        if not node then
            return
        end

        local node_kind = node:kind()
        local current_depth = function_depth or 0

        -- Track when we enter function declarations
        if node_kind == "function_declaration" or node_kind == "local_function_statement" then
            current_depth = current_depth + 1
        end

        -- Check for variable assignments
        if node_kind == "assignment_statement" or node_kind == "local_variable_declaration" then
            -- Find variable list and expression list
            local var_list = nil
            local expr_list = nil

            for i = 0, node:named_child_count() - 1 do
                local child = node:named_child(i)
                if child then
                    local child_kind = child:kind()
                    if child_kind == "variable_list" or child_kind == "identifier_list" then
                        var_list = child
                    elseif child_kind == "expression_list" then
                        expr_list = child
                    end
                end
            end

            -- Process variable/expression pairs
            if var_list and expr_list then
                local var_count = var_list:named_child_count()
                local expr_count = expr_list:named_child_count()
                local pairs_count = math.min(var_count, expr_count)

                for i = 0, pairs_count - 1 do
                    local var_node = var_list:named_child(i)
                    local expr_node = expr_list:named_child(i)

                    if var_node and expr_node then
                        local var_name = var_node:text(source)
                        local line_num = get_line_number(source, var_node:start_byte())

                        -- Check if this should be a constant based on naming
                        if should_be_constant(var_name) then
                            -- Check if it's a table that should be frozen
                            if expr_node:kind() == "table_constructor" then
                                -- Check if it's wrapped in table.freeze
                                local parent = expr_node:parent()
                                local is_frozen = false

                                if parent and parent:kind() == "arguments" then
                                    local grandparent = parent:parent()
                                    if grandparent and is_table_freeze_call(grandparent, source) then
                                        is_frozen = true
                                    end
                                end

                                if not is_frozen then
                                    table.insert(issues, {
                                        level = "warning",
                                        code = "CONSTANT_TABLE_NOT_FROZEN",
                                        message = string.format("Constant table '%s' should use table.freeze() for immutability at line %d",
                                                              var_name, line_num),
                                        entry_id = entry_id,
                                        details = {
                                            variable_name = var_name,
                                            line_number = line_num,
                                            suggestion = string.format("local %s = table.freeze({...})", var_name)
                                        }
                                    })
                                end
                            end
                        end

                        -- Check if assignment contains a table that could be frozen
                        if expr_node:kind() == "table_constructor" and var_name and #var_name > 3 then
                            local parent = expr_node:parent()
                            local is_frozen = false

                            if parent and parent:kind() == "arguments" then
                                local grandparent = parent:parent()
                                if grandparent and is_table_freeze_call(grandparent, source) then
                                    is_frozen = true
                                end
                            end

                            -- Count table elements
                            local element_count = 0
                            for j = 0, expr_node:named_child_count() - 1 do
                                local field = expr_node:named_child(j)
                                if field and (field:kind() == "field" or field:kind() == "expression") then
                                    element_count = element_count + 1
                                end
                            end

                            -- Only suggest freezing if table is not mutated later
                            local is_mutated = table_mutations[var_name] ~= nil
                            
                            if not is_frozen and element_count > 2 and not is_mutated then
                                table.insert(issues, {
                                    level = "info",
                                    code = "TABLE_COULD_BE_FROZEN",
                                    message = string.format("Table '%s' with %d elements could benefit from table.freeze() at line %d",
                                                          var_name, element_count, line_num),
                                    entry_id = entry_id,
                                    details = {
                                        variable_name = var_name,
                                        line_number = line_num,
                                        element_count = element_count,
                                        suggestion = "This table appears to be immutable after creation"
                                    }
                                })
                            end
                        end
                    end
                end
            end
        end

        -- Check for long string literals - ONLY inside functions
        if node_kind == "string" and current_depth > 0 then
            local string_content = node:text(source)
            local string_length = #string_content - 2 -- Subtract quotes

            if string_length > CONST.MAX_INLINE_STRING_LENGTH then
                -- Double-check that we're not in a root-level assignment
                if not is_root_level_assignment(node, source) then
                    local line_num = get_line_number(source, node:start_byte())

                    -- Extract meaningful preview - remove quotes and get first 80 chars
                    local inner_content = string_content:sub(2, -2) -- Remove quotes
                    local preview = inner_content:sub(1, 80)
                    if #inner_content > 80 then
                        preview = preview .. "..."
                    end

                    -- Clean up preview for display (escape newlines)
                    preview = preview:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")

                    table.insert(issues, {
                        level = "warning",
                        code = "LONG_STRING_INLINE",
                        message = string.format("Long string (%d chars) should be extracted to a constant at line %d: '%s'",
                                              string_length, line_num, preview),
                        entry_id = entry_id,
                        details = {
                            string_length = string_length,
                            line_number = line_num,
                            preview = preview,
                            full_preview = inner_content:sub(1, 200), -- Longer preview in details
                            suggestion = "Extract to a top-level constant like: local LONG_TEXT = [[ ... ]]"
                        }
                    })
                end
            end
        end

        -- Recursively walk children (with nil checks and function depth tracking)
        for i = 0, node:named_child_count() - 1 do
            local child = node:named_child(i)
            if child then
                walk_node(child, current_depth)
            end
        end
    end

    -- Start walking from root with depth 0
    walk_node(tree:root_node(), 0)

    -- Clean up
    tree:close()

    return issues
end

-- Main handler function
local function handle(request)
    log:info("Starting constants organization validation for Lua entries")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to constants validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Validating constants organization", {
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
            table.insert(valid_changeset, op)
            goto continue
        end

        local entry_id = op.entry.id or ("index:" .. i)

        log:debug("Processing entry for constants validation", {
            entry_id = entry_id,
            kind = op.entry.kind
        })

        local entry_issues = {}

        -- Analyze source code if available
        if op.entry.data.source and op.entry.data.source ~= "" then
            local source_issues = analyze_constants_and_strings(op.entry.data.source, entry_id)
            for _, issue in ipairs(source_issues) do
                table.insert(entry_issues, issue)
            end
        end

        -- Add issues to global list
        if #entry_issues > 0 then
            entries_with_issues = entries_with_issues + 1
            for _, issue in ipairs(entry_issues) do
                table.insert(issues, issue)
            end
        end

        -- Entry processed successfully
        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Constants validation completed", {
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
        message = entries_with_issues > 0 and ("Constants validation found issues in " .. entries_with_issues .. " entries") or
        "Constants validation completed"
    }
end

return { handle = handle }