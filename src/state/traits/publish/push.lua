local json = require("json")
local security = require("security")
local ctx = require("ctx")
local state_reader = require("state_reader")
local materialize = require("materialize")
local governance_client = require("governance_client")
local hash = require("hash")
local state_client = require("state_client")

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
    local conversion_errors = {}

    for _, item in ipairs(added) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            table.insert(conversion_errors, {
                entry_id = item.id,
                error = "Failed to convert added entry: " .. err
            })
        else
            table.insert(changeset, {
                kind = "entry.create",
                entry = registry_entry
            })
        end
    end

    for _, item in ipairs(modified) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            table.insert(conversion_errors, {
                entry_id = item.id,
                error = "Failed to convert modified entry: " .. err
            })
        else
            table.insert(changeset, {
                kind = "entry.update",
                entry = registry_entry
            })
        end
    end

    for _, item in ipairs(deleted) do
        table.insert(changeset, {
            kind = "entry.delete",
            entry = {
                id = item.id
            }
        })
    end

    if #conversion_errors > 0 then
        local error_msg = "Failed to convert some entries:\n"
        for _, err_info in ipairs(conversion_errors) do
            error_msg = error_msg .. "- " .. err_info.entry_id .. ": " .. err_info.error .. "\n"
        end
        return nil, error_msg
    end

    return changeset, nil
end

local function format_result(result, added, modified, deleted, target_branch, base_branch)
    local output = {}

    table.insert(output, "=== BRANCH PUSH RESULT ===")
    table.insert(output, "")
    table.insert(output, "Branch: " .. target_branch .. " -> " .. base_branch)
    table.insert(output, "Changes: +" .. #added .. " ~" .. #modified .. " -" .. #deleted)
    table.insert(output, "")

    if result.version then
        table.insert(output, "Registry version: " .. result.version)
    end

    if result.message then
        table.insert(output, "Message: " .. result.message)
    end

    if result.details and #result.details > 0 then
        table.insert(output, "")
        table.insert(output, "Processing Details:")
        for i, detail in ipairs(result.details) do
            local detail_type = detail.type and ("[" .. detail.type:upper() .. "]") or "[INFO]"
            table.insert(output, string.format("  %d. %s %s: %s",
                i, detail_type, detail.id or "unknown", detail.message or "no message"))
        end
    end

    if result.custom_metadata then
        table.insert(output, "")
        table.insert(output, "Processor Metadata:")
        table.insert(output, json.encode(result.custom_metadata, { indent = 2 }))
    end

    return table.concat(output, "\n")
end

local function sync_branch_with_registry(branch, entry_ids)
    if not entry_ids or #entry_ids == 0 then
        return nil
    end

    local success, err = state_client.sync_branch(branch, entry_ids)
    if not success then
        return "Warning: Branch sync failed: " .. (err or "unknown error")
    end

    return nil
end

local function handler(params)
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end

    local user_id = actor:id()

    local target_branch, err = get_branch_from_context_or_param(params.branch)
    if err then
        return nil, err
    end

    if target_branch == "main" then
        return nil, "Cannot push main branch (specify a feature branch)"
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
        return {
            entry_ids = {},
            summary = "No changes to push from branch '" .. target_branch .. "'",
            version = nil,
            added = 0,
            modified = 0,
            deleted = 0,
            branch = target_branch,
            base_branch = base_branch
        }, nil
    end

    local changeset, err = convert_to_changeset(added, deleted, modified)
    if err then
        return nil, err
    end

    local options = {
        branch = target_branch,
        base_branch = base_branch,
        user_id = user_id,
        message = params.message or ("Push from branch: " .. target_branch),
        request_hil = true,
        session_id = ctx.get("session_id") or nil
    }

    local result, err = governance_client.request_changes(changeset, options)
    if err then
        return nil, "Branch push failed: " .. err
    end

    local entry_ids = {}
    for _, item in ipairs(added) do
        table.insert(entry_ids, item.id)
    end
    for _, item in ipairs(modified) do
        table.insert(entry_ids, item.id)
    end

    local sync_warning = sync_branch_with_registry(target_branch, entry_ids)

    local output = format_result(result, added, modified, deleted, target_branch, base_branch)

    if sync_warning then
        output = output .. "\n\n" .. sync_warning
    end

    return {
        entry_ids = entry_ids,
        summary = output,
        version = result.version,
        added = #added,
        modified = #modified,
        deleted = #deleted,
        branch = target_branch,
        base_branch = base_branch
    }, nil
end

return { handler = handler }