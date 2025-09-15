local logger = require("logger")
local json = require("json")
local ctx = require("ctx")
local treesitter = require("treesitter")

local log = logger:named("lint.error_handling")

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

-- Check if function call is pcall
local function is_pcall(node, source)
    if not node or node:kind() ~= "function_call" then
        return false
    end

    local func_name = node:child(0)
    if func_name and func_name:kind() == "identifier" then
        return func_name:text(source) == "pcall"
    end

    return false
end

-- Check if function call is xpcall
local function is_xpcall(node, source)
    if not node or node:kind() ~= "function_call" then
        return false
    end

    local func_name = node:child(0)
    if func_name and func_name:kind() == "identifier" then
        return func_name:text(source) == "xpcall"
    end

    return false
end

-- Check if function call is error()
local function is_error_call(node, source)
    if not node or node:kind() ~= "function_call" then
        return false
    end

    local func_name = node:child(0)
    if func_name and func_name:kind() == "identifier" then
        return func_name:text(source) == "error"
    end

    return false
end

-- Extract function call arguments for analysis
local function extract_call_args(node, source)
    local args = {}

    if not node or node:kind() ~= "function_call" then
        return args
    end

    local arg_list = node:child(1)
    if arg_list and arg_list:kind() == "arguments" then
        for i = 0, arg_list:named_child_count() - 1 do
            local arg = arg_list:named_child(i)
            if arg then
                table.insert(args, arg:text(source))
            end
        end
    end

    return args
end

-- Check if code is likely to be used in coroutine context
local function analyze_coroutine_context(source)
    -- Look for coroutine-related keywords/patterns
    local coroutine_indicators = {
        "coroutine%.create",
        "coroutine%.resume",
        "coroutine%.yield",
        "coroutine%.wrap",
        "coroutine%.running",
        "yield%s*%(",
        "co_create",
        "co_resume",
        "co_yield"
    }

    for _, pattern in ipairs(coroutine_indicators) do
        if source:find(pattern) then
            return true, pattern
        end
    end

    return false
end

-- Check if function might return data, err pattern
local function has_data_err_pattern(source)
    -- Look for common data/err return patterns
    local data_err_patterns = {
        "return%s+[%w_]+%s*,%s*nil",
        "return%s+nil%s*,%s*[%w_\"']+",
        "return%s+[%w_]+%s*,%s*err",
        "return%s+data%s*,%s*err",
        "return%s+result%s*,%s*error",
        "local%s+[%w_]+%s*,%s*err%s*=",
        "local%s+data%s*,%s*[%w_]*err"
    }

    for _, pattern in ipairs(data_err_patterns) do
        if source:find(pattern) then
            return true
        end
    end

    return false
end

-- Analyze error handling patterns in source code
local function analyze_error_handling(source, entry_id)
    local issues = {}

    if not source or source == "" then
        return issues
    end

    local tree, parse_err = treesitter.parse("lua", source)
    if not tree then
        return issues
    end

    if tree:root_node():has_error() then
        tree:close()
        return issues
    end

    -- Check for coroutine context
    local is_coroutine_code, coroutine_pattern = analyze_coroutine_context(source)
    local has_data_err = has_data_err_pattern(source)

    -- Track all pcall/xpcall/error calls
    local pcall_calls = {}
    local xpcall_calls = {}
    local error_calls = {}

    local function walk_node(node)
        if not node then
            return
        end

        local node_kind = node:kind()

        if node_kind == "function_call" then
            local line = get_line_number(source, node:start_byte())
            local call_text = node:text(source)

            if is_pcall(node, source) then
                local args = extract_call_args(node, source)
                table.insert(pcall_calls, {
                    line = line,
                    text = call_text,
                    args = args
                })
            elseif is_xpcall(node, source) then
                local args = extract_call_args(node, source)
                table.insert(xpcall_calls, {
                    line = line,
                    text = call_text,
                    args = args
                })
            elseif is_error_call(node, source) then
                local args = extract_call_args(node, source)
                table.insert(error_calls, {
                    line = line,
                    text = call_text,
                    args = args
                })
            end
        end

        -- Recursively check children
        for i = 0, node:named_child_count() - 1 do
            local child = node:named_child(i)
            if child then
                walk_node(child)
            end
        end
    end

    walk_node(tree:root_node())

    -- Generate issues for pcall usage
    if #pcall_calls > 0 then
        for _, pcall_info in ipairs(pcall_calls) do
            local level = "warning"
            local message = string.format("pcall() usage at line %d may be incompatible with coroutine code", pcall_info.line)

            if is_coroutine_code then
                level = "warning"
                message = string.format("pcall() at line %d detected in coroutine context - may catch coroutine.yield() errors inappropriately", pcall_info.line)
            end

            table.insert(issues, {
                level = level,
                code = "PCALL_COROUTINE_ISSUE",
                message = message,
                entry_id = entry_id,
                details = {
                    line_number = pcall_info.line,
                    call_text = pcall_info.text,
                    coroutine_context = is_coroutine_code,
                    coroutine_pattern = coroutine_pattern,
                    suggestion = is_coroutine_code and
                        "Consider using explicit error checking or coroutine-safe error handling instead of pcall" or
                        "Be aware that pcall catches ALL errors, including coroutine.yield() which may cause issues if coroutines are used later"
                }
            })
        end
    end

    -- Generate issues for xpcall usage (similar concerns)
    if #xpcall_calls > 0 then
        for _, xpcall_info in ipairs(xpcall_calls) do
            local level = "info"
            local message = string.format("xpcall() usage at line %d - verify coroutine compatibility", xpcall_info.line)

            if is_coroutine_code then
                level = "warning"
                message = string.format("xpcall() at line %d detected in coroutine context - may interfere with coroutine error handling", xpcall_info.line)
            end

            table.insert(issues, {
                level = level,
                code = "XPCALL_COROUTINE_ISSUE",
                message = message,
                entry_id = entry_id,
                details = {
                    line_number = xpcall_info.line,
                    call_text = xpcall_info.text,
                    coroutine_context = is_coroutine_code,
                    suggestion = "Consider if custom error handler is coroutine-aware"
                }
            })
        end
    end

    -- Generate consolidated issue for error() calls
    if #error_calls > 0 then
        local level = "info"
        local suggestion = "Consider using return nil, 'error message' pattern instead of error() for better error handling consistency"

        if has_data_err then
            level = "info"
            suggestion = "Code already uses data/err patterns - consider replacing error() with return nil, 'error message' for consistency"
        end

        -- Create line numbers list and examples
        local lines = {}
        local examples = {}
        for i, error_info in ipairs(error_calls) do
            table.insert(lines, error_info.line)
            if i <= 3 then -- Show up to 3 examples
                local example = #error_info.args > 0 and
                    string.format("return nil, %s", error_info.args[1]) or
                    "return nil, 'error message'"
                table.insert(examples, string.format("Line %d: %s", error_info.line, example))
            end
        end

        local line_text = table.concat(lines, ", ")
        if #error_calls > 3 then
            line_text = line_text .. string.format(" (%d more)", #error_calls - 3)
        end

        table.insert(issues, {
            level = level,
            code = "ERROR_CALL_PATTERN",
            message = string.format("Found %d error() calls at lines %s - typical pattern is to return data, err instead",
                                  #error_calls, line_text),
            entry_id = entry_id,
            details = {
                error_call_count = #error_calls,
                lines = lines,
                has_data_err_elsewhere = has_data_err,
                suggestion = suggestion,
                examples = examples,
                refactor_pattern = "Replace error('message') with return nil, 'message'"
            }
        })
    end

    tree:close()
    return issues
end

-- Main handler function
local function handle(request)
    log:info("Starting error handling pattern analysis for Lua entries")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to error handling validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Analyzing error handling patterns", {
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

        log:debug("Processing entry for error handling analysis", {
            entry_id = entry_id,
            kind = op.entry.kind
        })

        local entry_issues = {}

        -- Analyze source code if available
        if op.entry.data.source and op.entry.data.source ~= "" then
            local error_issues = analyze_error_handling(op.entry.data.source, entry_id)
            for _, issue in ipairs(error_issues) do
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

    log:info("Error handling pattern analysis completed", {
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
        message = entries_with_issues > 0 and
            ("Error handling pattern issues found in " .. entries_with_issues .. " entries") or
            "Error handling pattern analysis completed - good practices detected"
    }
end

return { handle = handle }