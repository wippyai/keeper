local logger = require("logger")
local json = require("json")
local ctx = require("ctx")

local log = logger:named("lint.modules")

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
    VALID_MODULES = table.freeze({
        base64 = true,
        btea = true,
        cloudstorage = true,
        contract = true,
        crypto = true,
        ctx = true,
        env = true,
        events = true,
        excel = true,
        exec = true,
        fs = true,
        funcs = true,
        hash = true,
        html = true,
        http = true,
        http_client = true,
        iframe = true,
        jet = true,
        json = true,
        loader = true,
        logger = true,
        otel = true,
        registry = true,
        security = true,
        sql = true,
        store = true,
        stream = true,
        system = true,
        templates = true,
        text = true,
        time = true,
        treesitter = true,
        upstream = true,
        uuid = true,
        websocket = true,
        yaml = true,
        expr = true,
    }),
    FORBIDDEN_MODULES = table.freeze({
        process = true,
        channel = true,
    }),
})

-- Helper: Check if entry kind is a Lua type
local function is_lua_entry(kind)
    for _, lua_kind in ipairs(CONST.LUA_KINDS) do
        if kind == lua_kind then
            return true
        end
    end
    return false
end

-- Helper: Check if string matches registry ref pattern namespace:entry
local function is_registry_ref(value)
    if type(value) ~= "string" then
        return false
    end
    return value:match("^[%w_%.%-]+:[%w_%.%-]+$") ~= nil
end

-- Main handler function
local function handle(request)
    log:info("Starting modules validation linter")

    if not request then
        return {
            success = false,
            changeset = {},
            issues = {{
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to modules validator"
            }},
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local issues = {}
    local valid_changeset = {}
    local entries_processed = 0
    local entries_failed = 0

    for i, op in ipairs(changeset) do
        entries_processed = entries_processed + 1

        -- Skip DELETE operations
        if op.kind == CONST.OPERATIONS.DELETE then
            table.insert(valid_changeset, op)
            goto continue
        end

        -- Validate entry presence
        if not op.entry then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "MISSING_ENTRY",
                message = string.format("Operation missing entry object at index %d", i),
                entry_id = "unknown"
            })
            goto continue
        end

        local entry_id = op.entry.id or ("index:" .. i)

        -- Only process Lua kinds
        if not is_lua_entry(op.entry.kind) then
            table.insert(valid_changeset, op)
            goto continue
        end

        -- Validate data section presence
        if not op.entry.data then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "MISSING_DATA",
                message = "Entry data section is missing",
                entry_id = entry_id
            })
            goto continue
        end

        local modules_array = op.entry.data.modules or {}
        local imports_map = op.entry.data.imports or {}

        -- Validate modules array
        for idx, mod in ipairs(modules_array) do
            if CONST.FORBIDDEN_MODULES[mod] then
                entries_failed = entries_failed + 1
                table.insert(issues, {
                    level = "error",
                    code = "FORBIDDEN_MODULE",
                    message = string.format("Forbidden module '%s' found in modules array", mod),
                    entry_id = entry_id
                })
            elseif not CONST.VALID_MODULES[mod] then
                entries_failed = entries_failed + 1
                table.insert(issues, {
                    level = "error",
                    code = "INVALID_MODULE",
                    message = string.format("Invalid module '%s' found in modules array", mod),
                    entry_id = entry_id
                })
            end
        end

        -- Validate imports map values
        for alias, val in pairs(imports_map) do
            if CONST.FORBIDDEN_MODULES[val] then
                entries_failed = entries_failed + 1
                table.insert(issues, {
                    level = "error",
                    code = "FORBIDDEN_IMPORT",
                    message = string.format("Forbidden module '%s' found in imports", val),
                    entry_id = entry_id
                })
            elseif not (CONST.VALID_MODULES[val] or is_registry_ref(val)) then
                entries_failed = entries_failed + 1
                table.insert(issues, {
                    level = "error",
                    code = "INVALID_IMPORT",
                    message = string.format("Invalid import value '%s' for alias '%s'", val, alias),
                    entry_id = entry_id
                })
            end
        end

        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Modules validation completed", {
        entries_processed = entries_processed,
        entries_failed = entries_failed,
        issues_count = #issues
    })

    -- Always return success to allow pipeline to handle issues
    return {
        success = true,
        changeset = valid_changeset,
        issues = issues,
        message = entries_failed > 0 and string.format("Modules validation found %d invalid entries", entries_failed) or "Modules validation completed"
    }
end

return { handle = handle }