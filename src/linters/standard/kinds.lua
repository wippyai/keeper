local logger = require("logger")
local json = require("json")
local ctx = require("ctx")

local log = logger:named("lint.kind")

-- Known valid kinds from registry specification
local VALID_KINDS = table.freeze({
    -- Filesystem Components
    ["fs.directory"] = true,
    ["cloudstorage.s3"] = true,

    -- HTTP Components
    ["http.service"] = true,
    ["http.router"] = true,
    ["http.endpoint"] = true,
    ["http.static"] = true,

    -- Security Components
    ["security.token_store"] = true,
    ["security.policy"] = true,

    -- Data Storage Components
    ["store.memory"] = true,
    ["db.sql.sqlite"] = true,
    ["db.sql.postgres"] = true,
    ["db.sql.mysql"] = true,

    -- Process Components
    ["process.host"] = true,
    ["process.service"] = true,

    -- Lua Components
    ["function.lua"] = true,
    ["library.lua"] = true,
    ["process.lua"] = true,
    ["workflow.lua"] = true,

    -- Template Components
    ["template.set"] = true,
    ["template.jet"] = true,

    -- Dynamic configs
    ["registry.entry"] = true,
    ["ns.definition"] = true,

    ["exec.native"] = true,
    ["contract.definition"] = true,
    ["contract.binding"] = true,
    ["env.variable"] = true,
})

-- Deprecated kinds (still valid but should be migrated)
local DEPRECATED_KINDS = table.freeze({
    ["registry.entry"] = "Use more specific kinds when possible"
})

-- Get similar kinds for suggestions
local function get_similar_kinds(kind)
    if not kind then
        return {}
    end

    local similar = {}
    local prefix = kind:match("^([^.]+)%.")

    if prefix then
        -- Find related kinds with same prefix
        local prefix_pattern = "^" .. prefix .. "%."
        for valid_kind, _ in pairs(VALID_KINDS) do
            if valid_kind:match(prefix_pattern) and valid_kind ~= kind then
                table.insert(similar, valid_kind)
            end
        end
    end

    return similar
end

-- Constants for operations
local CONST = table.freeze({
    OPERATIONS = table.freeze({
        CREATE = "entry.create",
        UPDATE = "entry.update",
        DELETE = "entry.delete"
    })
})

-- Main handler function
local function handle(request)
    log:info("Starting kind validation")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to kind validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Validating kinds", {
        changeset_count = #changeset
    })

    local issues = {}
    local valid_changeset = {}
    local entries_processed = 0
    local entries_failed = 0
    local entries_skipped = 0

    -- Process each operation in the changeset
    for i, op in ipairs(changeset) do
        entries_processed = entries_processed + 1

        -- Skip DELETE operations (don't need kind validation)
        if op.kind == CONST.OPERATIONS.DELETE then
            table.insert(valid_changeset, op)
            entries_skipped = entries_skipped + 1
            goto continue
        end

        -- Validate operation structure
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

        -- Get entry ID for reporting
        local entry_id = op.entry.id or string.format("index:%d", i)

        -- Check if entry has a kind
        if not op.entry.kind then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "MISSING_KIND",
                message = "Entry missing required 'kind' field",
                entry_id = entry_id
            })
            goto continue
        end

        -- Validate kind type
        if type(op.entry.kind) ~= "string" then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "INVALID_KIND_TYPE",
                message = string.format("Entry kind must be a string, got: %s", type(op.entry.kind)),
                entry_id = entry_id
            })
            goto continue
        end

        -- Check if kind is empty
        if op.entry.kind == "" then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "EMPTY_KIND",
                message = "Entry kind cannot be empty",
                entry_id = entry_id
            })
            goto continue
        end

        -- Check if kind is valid
        if not VALID_KINDS[op.entry.kind] then
            entries_failed = entries_failed + 1
            local similar_kinds = get_similar_kinds(op.entry.kind)
            local suggestions = ""

            if #similar_kinds > 0 then
                suggestions = string.format(" Did you mean: %s?", table.concat(similar_kinds, ", "))
            end

            table.insert(issues, {
                level = "error",
                code = "UNKNOWN_KIND",
                message = string.format("Unknown entry kind: '%s'.%s", op.entry.kind, suggestions),
                entry_id = entry_id
            })
            goto continue
        end

        -- Kind is valid, include in filtered changeset
        table.insert(valid_changeset, op)

        ::continue::
    end



    log:info("Kind validation completed", {
        entries_processed = entries_processed,
        entries_failed = entries_failed,
        entries_skipped = entries_skipped,
        entries_valid = #valid_changeset,
        issues_count = #issues
    })

    -- Always return success so pipeline shows detailed issues
    -- Pipeline will determine overall failure based on error count
    local success = true

    return {
        success = success,
        changeset = valid_changeset,
        issues = issues,
        message = entries_failed > 0 and string.format("Kind validation found %d invalid entries", entries_failed) or
            "Kind validation completed"
    }
end

return { handle = handle }
