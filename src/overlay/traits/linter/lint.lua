local json = require("json")
local security = require("security")
local ctx = require("ctx")
local contract = require("contract")
local workspace = require("workspace")

-- Main handler function
local function handler(params)
    -- Get user context
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end

    local user_id = actor:id()

    -- Get workspace from context automatically (CONTEXT-LOCKED)
    local workspace_id, err = ctx.get("workspace_id")
    if err then
        return nil, "Cannot access workspace context: " .. err
    end

    if not workspace_id or workspace_id == "" then
        return nil, "No active workspace. Use workspace manager to open one first"
    end

    -- Open workspace session
    local session, err = workspace.open(workspace_id, user_id)
    if err then
        return nil, "Failed to open workspace session: " .. err
    end

    -- Get workspace info for context
    local workspace_info, err = session:get_workspace_info()
    if err then
        return nil, "Failed to get workspace info: " .. err
    end

    -- Get dirty entries to check if there are changes to validate
    local dirty_entries, err = session:get_dirty_entries()
    if err then
        return nil, "Failed to get workspace changes: " .. err
    end

    if #dirty_entries == 0 then
        return "No changes to validate in workspace '" .. (workspace_info.title or workspace_id) .. "'", nil
    end

    -- Convert dirty entries to changeset format
    local changeset = {}
    for i, dirty_entry in ipairs(dirty_entries) do
        table.insert(changeset, {
            kind = dirty_entry.operation_type, -- Should be "entry.create", "entry.update", or "entry.delete"
            entry = {
                id = dirty_entry.entry_id,
                kind = dirty_entry.entry_kind or "unknown",
                meta = dirty_entry.entry_meta or {},
                data = dirty_entry.entry_data or {}
            }
        })
    end

    -- Get linting level from params (default to 1, range 1-100)
    local level = params.level or 1
    if level < 1 then
        level = 1
    elseif level > 100 then
        level = 100
    end

    -- Prepare linting request
    local lint_request = {
        changeset = changeset,
        options = {
            level = level,
            halt_on_error = false,   -- Continue processing all entries
            halt_on_warning = false  -- Continue processing all entries
        }
    }

    -- Get linting pipeline contract
    local pipeline_contract, err = contract.get("keeper.linters:pipeline")
    if err then
        return nil, "Failed to get linting pipeline contract: " .. err
    end

    -- Open pipeline instance with workspace context
    local pipeline_instance, err = pipeline_contract
        :with_actor(actor)
        :with_context({
            workspace_id = workspace_id,
            request_id = ctx.get("request_id") or "lint-" .. os.time()
        })
        :open()

    if err then
        return nil, "Failed to open linting pipeline: " .. err
    end

    -- Execute linting
    local result, err = pipeline_instance:lint(lint_request)
    if err then
        return nil, "Linting pipeline execution failed: " .. err
    end

    -- Format results for agent (exclude changeset, include only issues)
    local output = {}
    table.insert(output, "Workspace: " .. (workspace_info.title or workspace_id))
    table.insert(output, "Operations: " .. #changeset .. " | Level: " .. level .. " of 100")
    table.insert(output, "")

    -- Process issues by severity
    local error_count = 0
    local warning_count = 0
    local info_count = 0
    local errors = {}
    local warnings = {}
    local infos = {}

    for i, issue in ipairs(result.issues or {}) do
        if issue.level == "error" then
            error_count = error_count + 1
            table.insert(errors, issue)
        elseif issue.level == "warning" then
            warning_count = warning_count + 1
            table.insert(warnings, issue)
        elseif issue.level == "info" then
            info_count = info_count + 1
            table.insert(infos, issue)
        end
    end

    -- Summary counts
    if error_count > 0 or warning_count > 0 or info_count > 0 then
        table.insert(output, "Issues: " .. error_count .. " errors, " .. warning_count .. " warnings, " .. info_count .. " info")
        table.insert(output, "")
    else
        table.insert(output, "No issues found")
        table.insert(output, "")
    end

    -- Show errors first (most important)
    if error_count > 0 then
        table.insert(output, "ERRORS:")
        for i, issue in ipairs(errors) do
            local entry_info = issue.entry_id and (" [" .. issue.entry_id .. "]") or ""
            table.insert(output, "  " .. issue.code .. ": " .. issue.message .. entry_info)
        end
        table.insert(output, "")
    end

    -- Show warnings
    if warning_count > 0 then
        table.insert(output, "WARNINGS:")
        for i, issue in ipairs(warnings) do
            local entry_info = issue.entry_id and (" [" .. issue.entry_id .. "]") or ""
            table.insert(output, "  " .. issue.code .. ": " .. issue.message .. entry_info)
        end
        table.insert(output, "")
    end

    -- Always show info messages if there are any
    if info_count > 0 then
        table.insert(output, "INFO:")
        for i, issue in ipairs(infos) do
            local entry_info = issue.entry_id and (" [" .. issue.entry_id .. "]") or ""
            table.insert(output, "  " .. issue.code .. ": " .. issue.message .. entry_info)
        end
        table.insert(output, "")
    end

    return table.concat(output, "\n"), nil
end

return { handler = handler }