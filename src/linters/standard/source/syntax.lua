local logger = require("logger")
local json = require("json")
local ctx = require("ctx")
local treesitter = require("treesitter")

local log = logger:named("lint.syntax")

-- Constants for operations and Lua kinds
local CONST = {
    OPERATIONS = {
        CREATE = "entry.create",
        UPDATE = "entry.update",
        DELETE = "entry.delete"
    },
    LUA_KINDS = {
        "function.lua",
        "library.lua",
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

-- Parse Lua source and find syntax errors with detailed location info
local function validate_lua_syntax(source, entry_id)
    if not source or source == "" then
        return {
            level = "error",
            code = "EMPTY_SOURCE",
            message = "Source code cannot be empty for Lua entries",
            entry_id = entry_id
        }
    end

    -- Parse the Lua code
    local tree, parse_err = treesitter.parse("lua", source)
    if not tree then
        return {
            level = "error",
            code = "PARSE_FAILED",
            message = "Failed to parse Lua code: " .. (parse_err or "Unknown parsing error"),
            entry_id = entry_id
        }
    end

    -- Check if the parsed tree has syntax errors
    if not tree:root_node():has_error() then
        tree:close()
        return nil -- No syntax errors
    end

    -- Find detailed error information with enhanced location tracking
    local error_details = {}

    local function find_error_nodes(node)
        if node:is_error() or node:has_error() then
            local start_point = node:start_point()
            local end_point = node:end_point()
            local error_text = node:text(source)

            -- Limit error text length for readability but preserve newlines info
            local display_text = error_text
            if #error_text > 50 then
                display_text = error_text:sub(1, 47) .. "..."
            end
            -- Clean up newlines for display
            display_text = display_text:gsub("\n", "\\n"):gsub("\r", "\\r")

            table.insert(error_details, {
                type = node:kind(),
                start_line = (start_point.row or 0) + 1,
                start_column = (start_point.column or 0) + 1,
                end_line = (end_point.row or 0) + 1,
                end_column = (end_point.column or 0) + 1,
                text = display_text,
                full_text = error_text -- Keep full text for detailed analysis if needed
            })
        end

        -- Recursively check children
        for i = 0, node:child_count() - 1 do
            find_error_nodes(node:child(i))
        end
    end

    -- Find all error nodes
    find_error_nodes(tree:root_node())
    tree:close()

    -- Format detailed error message like the old code
    local error_msg = "Lua syntax errors detected:"
    local details_array = {}

    for _, err_info in ipairs(error_details) do
        local location_info = string.format("Line %d:%d", err_info.start_line, err_info.start_column)
        if err_info.end_line ~= err_info.start_line or err_info.end_column ~= err_info.start_column then
            location_info = location_info .. string.format(" to %d:%d", err_info.end_line, err_info.end_column)
        end

        local detail_msg = string.format(
            "%s near '%s' (%s)",
            location_info,
            err_info.text,
            err_info.type
        )
        error_msg = error_msg .. "\n  • " .. detail_msg

        -- Also add structured detail for programmatic access
        table.insert(details_array, {
            location = location_info,
            type = err_info.type,
            text = err_info.text,
            start_line = err_info.start_line,
            start_column = err_info.start_column,
            end_line = err_info.end_line,
            end_column = err_info.end_column
        })
    end

    return {
        level = "error",
        code = "SYNTAX_ERROR",
        message = error_msg,
        entry_id = entry_id,
        details = details_array -- Enhanced: Add structured details for programmatic access
    }
end

-- Main handler function
local function handle(request)
    log:info("Starting Lua syntax validation")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to syntax validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Validating syntax", {
        changeset_count = #changeset
    })

    local issues = {}
    local valid_changeset = {}
    local entries_processed = 0
    local entries_with_errors = 0

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
            entries_with_errors = entries_with_errors + 1
            table.insert(issues, {
                level = "error",
                code = "MISSING_DATA",
                message = "Entry data section is missing",
                entry_id = op.entry.id or "unknown"
            })
            goto continue
        end

        local entry_id = op.entry.id or ("index:" .. i)

        -- Validate syntax if source exists
        if op.entry.data.source then
            local syntax_issue = validate_lua_syntax(op.entry.data.source, entry_id)
            if syntax_issue then
                entries_with_errors = entries_with_errors + 1
                table.insert(issues, syntax_issue)
                goto continue -- Skip entries with syntax errors
            end
        end

        -- Entry processed successfully
        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Syntax validation completed", {
        entries_processed = entries_processed,
        entries_with_errors = entries_with_errors,
        entries_valid = #valid_changeset,
        issues_count = #issues
    })

    -- Always return success so pipeline shows detailed issues
    local success = true

    return {
        success = success,
        changeset = valid_changeset,
        issues = issues,
        message = entries_with_errors > 0 and ("Syntax validation found errors in " .. entries_with_errors .. " entries") or
        "Syntax validation completed"
    }
end

return { handle = handle }