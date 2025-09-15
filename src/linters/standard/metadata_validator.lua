local logger = require("logger")
local json = require("json")
local ctx = require("ctx")

local log = logger:named("lint.metadata")

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
    log:info("Starting metadata validation")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to metadata validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Validating metadata fields", {
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

        -- Skip DELETE operations (don't need metadata validation)
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

        -- Check if meta is nil
        if op.entry.meta == nil then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "NIL_METADATA",
                message = "Entry missing required 'meta' field",
                entry_id = entry_id
            })
            goto continue
        end

        -- Check if meta is not a table
        if type(op.entry.meta) ~= "table" then
            entries_failed = entries_failed + 1
            table.insert(issues, {
                level = "error",
                code = "INVALID_METADATA_TYPE",
                message = string.format("Entry meta must be a table, got: %s", type(op.entry.meta)),
                entry_id = entry_id
            })
            goto continue
        end

        -- Check if meta is empty table (WARNING, not ERROR)
        local field_count = 0
        for _ in pairs(op.entry.meta) do
            field_count = field_count + 1
        end

        if field_count == 0 then
            table.insert(issues, {
                level = "warning",
                code = "EMPTY_METADATA",
                message = "Entry meta is empty table",
                entry_id = entry_id
            })
        end

        -- Metadata is valid, include in filtered changeset
        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Metadata validation completed", {
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
        message = entries_failed > 0 and 
            string.format("Metadata validation found %d entries with invalid metadata", entries_failed) or
            "Metadata validation completed"
    }
end

return { handle = handle }