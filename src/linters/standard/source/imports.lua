local logger = require("logger")
local json = require("json")
local ctx = require("ctx")
local treesitter = require("treesitter")

local log = logger:named("lint.imports")

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
    },
    -- Modules that are enabled by default and should not be required
    FORBIDDEN_MODULES = {
        "process",
        "channel"
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

-- Check if module is forbidden (enabled by default)
local function is_forbidden_module(module)
    for _, forbidden in ipairs(CONST.FORBIDDEN_MODULES) do
        if module == forbidden then
            return true
        end
    end
    return false
end

-- Extract namespace from entry ID
local function extract_namespace(entry_id)
    if entry_id and entry_id:find(":") then
        return entry_id:match("^([^:]+):")
    end
    return nil
end

-- Extract module name from registry module
local function extract_module_name(module)
    if module and module:find(":") then
        return module:match(":([^:]+)$")
    end
    return module
end

-- Check if module is a registry module
local function is_registry_module(module)
    return module and module:find(":") ~= nil
end

-- Check if a registry module actually exists
local function module_exists_in_registry(module)
    if not is_registry_module(module) then
        return false
    end

    -- Try to access the registry to check if module exists
    local registry_available, registry = pcall(require, "registry")
    if not registry_available then
        log:warn("Registry not available for verification")
        return false -- Assume it doesn't exist if we can't verify
    end

    local entry, err = registry.get(module)
    return entry ~= nil
end

-- Extract requires from source using treesitter
local function extract_requires_from_source(source)
    local requires = {}

    if not source or source == "" then
        return requires
    end

    -- Parse the Lua code
    local tree, parse_err = treesitter.parse("lua", source)
    if not tree then
        return requires
    end

    -- Check for syntax errors
    if tree:root_node():has_error() then
        tree:close()
        return requires
    end

    -- Function to find require statements
    local function find_requires(node)
        -- Check if this is a function call
        if node:kind() == "function_call" then
            -- Get the function name node
            local func_name = node:child(0)
            if func_name and func_name:kind() == "identifier" and func_name:text(source) == "require" then
                -- This is a require statement, get the full statement text
                local statement_text = node:text(source)

                -- Also extract the module name without quotes
                local args = node:child(1)
                if args and args:named_child_count() > 0 then
                    local arg = args:named_child(0)
                    if arg and arg:kind() == "string" then
                        -- Extract the module name without quotes
                        local module_text = arg:text(source)
                        -- Remove the quotes
                        module_text = module_text:sub(2, -2)
                        -- Add to requires if not already present
                        if not requires[module_text] then
                            requires[module_text] = statement_text
                        end
                    end
                end
            end
        end

        -- Recursively check all children
        for i = 0, node:named_child_count() - 1 do
            find_requires(node:named_child(i))
        end
    end

    -- Find all require statements in the tree
    find_requires(tree:root_node())

    -- Clean up
    tree:close()

    return requires
end

-- Safe string replacement without pattern matching
local function plain_replace(source, find_text, replace_text)
    local result = ""
    local current_pos = 1
    local find_start, find_end = string.find(source, find_text, current_pos, true)

    while find_start do
        result = result .. string.sub(source, current_pos, find_start - 1) .. replace_text
        current_pos = find_end + 1
        find_start, find_end = string.find(source, find_text, current_pos, true)
    end

    result = result .. string.sub(source, current_pos)
    return result
end

-- Find unused dependencies
local function find_unused_dependencies(declared_modules, declared_imports, requires)
    local unused_modules = {}
    local unused_imports = {}

    -- Check declared modules
    if declared_modules then
        for _, module in ipairs(declared_modules) do
            if not requires[module] then
                table.insert(unused_modules, module)
            end
        end
    end

    -- Check declared imports
    if declared_imports then
        for alias, module in pairs(declared_imports) do
            local alias_used = false
            -- Check if the alias is used in requires
            for req_module, _ in pairs(requires) do
                if req_module == alias then
                    alias_used = true
                    break
                end
            end
            if not alias_used then
                table.insert(unused_imports, {alias = alias, module = module})
            end
        end
    end

    return unused_modules, unused_imports
end

-- Main handler function
local function handle(request)
    log:info("Starting enhanced imports validation for Lua entries")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to imports validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Validating imports", {
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
        local base_namespace = extract_namespace(entry_id)

        log:debug("Processing entry", {
            entry_id = entry_id,
            kind = op.entry.kind,
            base_namespace = base_namespace
        })

        -- Extract requires from source code
        local requires = {}
        local original_source = op.entry.data.source
        if original_source then
            requires = extract_requires_from_source(original_source)
        end

        -- Check for forbidden modules first
        local has_forbidden = false
        for req_module, req_stmt in pairs(requires) do
            if is_forbidden_module(req_module) then
                entries_with_errors = entries_with_errors + 1
                has_forbidden = true
                table.insert(issues, {
                    level = "error",
                    code = "FORBIDDEN_REQUIRE",
                    message = "Forbidden require of '" .. req_module .. "' - this module is enabled by default and should not be required",
                    entry_id = entry_id
                })
            end
        end

        -- Skip further processing if forbidden modules found
        if has_forbidden then
            goto continue
        end

        -- Get declared dependencies
        local declared_modules_list = op.entry.data.modules or {}
        local declared_modules = {}
        for _, module in ipairs(declared_modules_list) do
            declared_modules[module] = true
        end

        local declared_imports = op.entry.data.imports or {}

        -- Find missing dependencies with registry verification
        local missing_modules = {}
        local missing_registry = {}
        local missing_unverified = {}
        local verified_registry = {}

        for req_module, req_stmt in pairs(requires) do
            local is_declared = declared_modules[req_module] or declared_imports[req_module]

            if not is_declared then
                if is_registry_module(req_module) then
                    -- Registry module with explicit namespace - verify existence
                    if module_exists_in_registry(req_module) then
                        table.insert(verified_registry, req_module)
                    else
                        table.insert(missing_unverified, req_module)
                        entries_with_errors = entries_with_errors + 1
                        table.insert(issues, {
                            level = "error",
                            code = "REGISTRY_MODULE_NOT_FOUND",
                            message = "Registry module '" .. req_module .. "' does not exist or is not accessible",
                            entry_id = entry_id
                        })
                    end
                else
                    -- Module without namespace - treat as standard module
                    table.insert(missing_modules, req_module)
                end
            end
        end

        -- Skip further processing if unverified registry modules found
        if #missing_unverified > 0 then
            goto continue
        end

        -- Track alias mappings for source transformation
        local alias_mappings = {}

        -- Add missing standard modules
        if #missing_modules > 0 then
            if not op.entry.data.modules then
                op.entry.data.modules = {}
            end

            for _, module in ipairs(missing_modules) do
                table.insert(op.entry.data.modules, module)
                table.insert(issues, {
                    level = "warning",
                    code = "DEPENDENCY_ADDED",
                    message = "Added missing module dependency: " .. module,
                    entry_id = entry_id
                })
                log:info("Added missing module: " .. module .. " to " .. entry_id)
            end
        end

        -- Add verified registry modules as imports with alias generation
        if #verified_registry > 0 then
            if not op.entry.data.imports then
                op.entry.data.imports = {}
            end

            for _, module in ipairs(verified_registry) do
                local alias = extract_module_name(module)
                local counter = 1
                local original_alias = alias

                -- Handle alias conflicts
                while op.entry.data.imports[alias] do
                    alias = original_alias .. "_" .. counter
                    counter = counter + 1
                end

                op.entry.data.imports[alias] = module
                alias_mappings[module] = alias

                table.insert(issues, {
                    level = "warning",
                    code = "IMPORT_ADDED",
                    message = "Added missing import: " .. alias .. " -> " .. module,
                    entry_id = entry_id
                })
                log:info("Added missing import: " .. alias .. " -> " .. module .. " to " .. entry_id)
            end
        end

        -- Transform source code to use aliases
        if next(alias_mappings) and original_source then
            local transformed_source = original_source

            for module, alias in pairs(alias_mappings) do
                local original_require = requires[module]
                if original_require then
                    local new_require = string.format('require("%s")', alias)
                    transformed_source = plain_replace(transformed_source, original_require, new_require)

                    table.insert(issues, {
                        level = "info",
                        code = "SOURCE_TRANSFORMED",
                        message = "Transformed require: " .. original_require .. " -> " .. new_require,
                        entry_id = entry_id
                    })
                    log:info("Transformed require in " .. entry_id .. ": " .. original_require .. " -> " .. new_require)
                end
            end

            -- Update source if changes were made
            if transformed_source ~= original_source then
                op.entry.data.source = transformed_source
            end
        end

        -- Find and remove unused dependencies
        local unused_modules, unused_imports = find_unused_dependencies(
            declared_modules_list,
            declared_imports,
            requires
        )

        -- Remove unused modules
        if #unused_modules > 0 then
            local new_modules = {}
            for _, module in ipairs(declared_modules_list) do
                local is_unused = false
                for _, unused in ipairs(unused_modules) do
                    if module == unused then
                        is_unused = true
                        break
                    end
                end
                if not is_unused then
                    table.insert(new_modules, module)
                end
            end

            op.entry.data.modules = #new_modules > 0 and new_modules or nil

            for _, module in ipairs(unused_modules) do
                table.insert(issues, {
                    level = "warning",
                    code = "UNUSED_MODULE_REMOVED",
                    message = "Removed unused module: " .. module,
                    entry_id = entry_id
                })
                log:info("Removed unused module: " .. module .. " from " .. entry_id)
            end
        end

        -- Remove unused imports
        if #unused_imports > 0 then
            for _, unused in ipairs(unused_imports) do
                op.entry.data.imports[unused.alias] = nil
                table.insert(issues, {
                    level = "warning",
                    code = "UNUSED_IMPORT_REMOVED",
                    message = "Removed unused import: " .. unused.alias .. " -> " .. unused.module,
                    entry_id = entry_id
                })
                log:info("Removed unused import: " .. unused.alias .. " -> " .. unused.module .. " from " .. entry_id)
            end

            -- Clean up empty imports table
            if op.entry.data.imports and not next(op.entry.data.imports) then
                op.entry.data.imports = nil
            end
        end

        -- Entry processed successfully
        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Enhanced imports validation completed", {
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
        message = entries_with_errors > 0 and ("Imports validation found errors in " .. entries_with_errors .. " entries") or
        "Enhanced imports validation completed with source transformation"
    }
end

return { handle = handle }