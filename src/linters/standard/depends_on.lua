local logger = require("logger")
local json = require("json")
local ctx = require("ctx")
local treesitter = require("treesitter")

local log = logger:named("lint.depends_on")

-- Constants for operations
local CONST = {
    OPERATIONS = {
        CREATE = "entry.create",
        UPDATE = "entry.update",
        DELETE = "entry.delete"
    }
}

-- Main handler function
local function handle(request)
    log:info("Starting depends_on deprecation check")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided to depends_on validator"
            } },
            message = "Invalid input provided"
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Checking depends_on usage", {
        changeset_count = #changeset
    })

    local issues = {}
    local valid_changeset = {}
    local entries_processed = 0

    -- Process each operation in the changeset
    for i, op in ipairs(changeset) do
        entries_processed = entries_processed + 1

        -- Skip DELETE operations
        if op.kind == CONST.OPERATIONS.DELETE then
            table.insert(valid_changeset, op)
            goto continue
        end

        -- Check all entries
        if not op.entry then
            table.insert(valid_changeset, op)
            goto continue
        end

        local entry_id = op.entry.id or ("index:" .. i)

        -- Check if entry has depends_on in meta
        if op.entry.meta and op.entry.meta.depends_on then
            table.insert(issues, {
                level = "warning",
                code = "DEPENDS_ON_DEPRECATED",
                message =
                "Field 'depends_on' is deprecated - dependencies are now properly calculated depending on entry kind",
                entry_id = entry_id
            })
            log:info("Found deprecated depends_on in entry: " .. entry_id)
        end

        -- Entry processed
        table.insert(valid_changeset, op)

        ::continue::
    end

    log:info("Depends_on check completed", {
        entries_processed = entries_processed,
        entries_valid = #valid_changeset,
        issues_count = #issues
    })

    -- Always return success
    local success = true

    return {
        success = success,
        changeset = valid_changeset,
        issues = issues,
        message = "Depends_on deprecation check completed"
    }
end

return { handle = handle }
