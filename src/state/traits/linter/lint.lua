local json = require("json")
local ctx = require("ctx")
local contract = require("contract")
local hash = require("hash")
local state_reader = require("state_reader")
local materialize = require("materialize")
local consts = require("consts")

local function get_branch_from_context_or_param(params_branch)
    if params_branch and params_branch ~= "" then
        return params_branch
    end

    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return overlay_branch
    end

    return nil, "No branch specified and no active branch in context"
end

local function get_entry_content(entry)
    local definition_content = ""
    local source_content = ""

    if entry.chunks then
        for _, chunk in ipairs(entry.chunks) do
            if chunk.type == "definition" then
                definition_content = chunk.content or ""
            elseif chunk.type == "content" then
                source_content = chunk.content or ""
            end
        end
    end

    return definition_content, source_content
end

local function compute_content_hash(definition, source)
    local combined = definition .. "\n---\n" .. source
    local content_hash, err = hash.sha256(combined)
    if err then
        return nil
    end
    return content_hash
end

local function load_branch_entries(branches)
    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:include_chunks():include_deleted()

    local entries, err = reader:all()
    if err then
        return nil, err
    end

    local entry_map = {}
    for _, entry in ipairs(entries) do
        entry_map[entry.id] = entry
    end

    return entry_map, nil
end

local function classify_changes(base_map, target_map)
    local added = {}
    local deleted = {}
    local modified = {}

    for id, target_entry in pairs(target_map) do
        local base_entry = base_map[id]

        if target_entry.deleted == 1 then
            if base_entry and base_entry.deleted == 0 then
                table.insert(deleted, {id = id, entry = base_entry})
            end
        elseif not base_entry or base_entry.deleted == 1 then
            table.insert(added, {id = id, entry = target_entry})
        else
            local base_def, base_src = get_entry_content(base_entry)
            local target_def, target_src = get_entry_content(target_entry)

            local base_hash = compute_content_hash(base_def, base_src)
            local target_hash = compute_content_hash(target_def, target_src)

            if base_hash ~= target_hash then
                table.insert(modified, {id = id, entry = target_entry})
            end
        end
    end

    table.sort(added, function(a, b) return a.id < b.id end)
    table.sort(deleted, function(a, b) return a.id < b.id end)
    table.sort(modified, function(a, b) return a.id < b.id end)

    return added, deleted, modified
end

local function convert_to_changeset(added, deleted, modified)
    local changeset = {}

    for _, item in ipairs(added) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            return nil, "Failed to convert added entry " .. item.id .. ": " .. err
        end

        table.insert(changeset, {
            kind = "entry.create",
            entry = registry_entry
        })
    end

    for _, item in ipairs(modified) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            return nil, "Failed to convert modified entry " .. item.id .. ": " .. err
        end

        table.insert(changeset, {
            kind = "entry.update",
            entry = registry_entry
        })
    end

    for _, item in ipairs(deleted) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            return nil, "Failed to convert deleted entry " .. item.id .. ": " .. err
        end

        table.insert(changeset, {
            kind = "entry.delete",
            entry = registry_entry
        })
    end

    return changeset, nil
end

local function handler(params)
    local level = params.level or 1
    if level < 1 then level = 1 end
    if level > 100 then level = 100 end

    local target_branch, err = get_branch_from_context_or_param(params.branch)
    if err then
        return nil, err
    end

    if target_branch == "main" then
        return nil, "Cannot lint main branch (specify a feature branch)"
    end

    local base_branch = params.base or "main"

    local base_branches = base_branch == "main" and {"main"} or {base_branch, "main"}
    local target_branches = {target_branch, "main"}

    local base_map, err = load_branch_entries(base_branches)
    if err then
        return nil, "Failed to load base branch: " .. err
    end

    local target_map, err = load_branch_entries(target_branches)
    if err then
        return nil, "Failed to load target branch: " .. err
    end

    local added, deleted, modified = classify_changes(base_map, target_map)

    local total_changes = #added + #deleted + #modified
    if total_changes == 0 then
        return "No changes to validate in branch '" .. target_branch .. "'", nil
    end

    local changeset, err = convert_to_changeset(added, deleted, modified)
    if err then
        return nil, err
    end

    local lint_request = {
        changeset = changeset,
        options = {
            level = level,
            halt_on_error = false,
            halt_on_warning = false
        }
    }

    local pipeline_contract, err = contract.get("keeper.linters:pipeline")
    if err then
        return nil, "Failed to get linting pipeline: " .. err
    end

    local pipeline_instance, err = pipeline_contract:open()
    if err then
        return nil, "Failed to open linting pipeline: " .. err
    end

    local result, err = pipeline_instance:lint(lint_request)
    if err then
        return nil, "Linting failed: " .. err
    end

    local output = {}
    table.insert(output, "Branch: " .. target_branch .. " -> " .. base_branch)
    table.insert(output, "Changes: +" .. #added .. " ~" .. #modified .. " -" .. #deleted .. " | Level: " .. level .. "/100")
    table.insert(output, "")

    local error_count = 0
    local warning_count = 0
    local info_count = 0
    local errors = {}
    local warnings = {}
    local infos = {}

    for _, issue in ipairs(result.issues or {}) do
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

    if error_count > 0 or warning_count > 0 or info_count > 0 then
        table.insert(output, "Issues: " .. error_count .. " errors, " .. warning_count .. " warnings, " .. info_count .. " info")
        table.insert(output, "")
    else
        table.insert(output, "No issues found")
        table.insert(output, "")
    end

    if error_count > 0 then
        table.insert(output, "ERRORS:")
        for _, issue in ipairs(errors) do
            local entry_info = issue.entry_id and (" [" .. issue.entry_id .. "]") or ""
            table.insert(output, "  " .. issue.code .. ": " .. issue.message .. entry_info)
        end
        table.insert(output, "")
    end

    if warning_count > 0 then
        table.insert(output, "WARNINGS:")
        for _, issue in ipairs(warnings) do
            local entry_info = issue.entry_id and (" [" .. issue.entry_id .. "]") or ""
            table.insert(output, "  " .. issue.code .. ": " .. issue.message .. entry_info)
        end
        table.insert(output, "")
    end

    if info_count > 0 then
        table.insert(output, "INFO:")
        for _, issue in ipairs(infos) do
            local entry_info = issue.entry_id and (" [" .. issue.entry_id .. "]") or ""
            table.insert(output, "  " .. issue.code .. ": " .. issue.message .. entry_info)
        end
        table.insert(output, "")
    end

    return table.concat(output, "\n"), nil
end

return { handler = handler }