local json = require("json")
local ctx = require("ctx")
local design_reader = require("design_reader")

local function run(args)
    local branch_id = args.branch_id

    if not branch_id or branch_id == "" then
        return nil, "branch_id required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    local reader = design_reader.for_workspace(workspace_id)

    local branch = reader:with_data(branch_id):one()
    if not branch then
        return nil, "Branch not found: " .. branch_id
    end

    local output = {}

    table.insert(output, "# Design Specification")
    table.insert(output, "")
    table.insert(output, "**Branch**: " .. (branch.metadata.title or branch_id))
    table.insert(output, "")

    if branch.content then
        table.insert(output, "## Original Prompt")
        table.insert(output, "")
        table.insert(output, branch.content)
        table.insert(output, "")
    end

    local context_docs = reader
        :with_type("context")
        :with_parent_direct(branch_id)
        :with_statuses("current")
        :order_by_position()
        :all()

    if #(context_docs or {}) > 0 then
        table.insert(output, "## Design Context")
        table.insert(output, "")
        for _, doc in ipairs(context_docs) do
            local key = doc.discriminator or "context"
            local comment = (doc.metadata or {}).comment or ""
            table.insert(output, "### " .. key)
            if comment and comment ~= "" then
                table.insert(output, "*" .. comment .. "*")
                table.insert(output, "")
            end
            table.insert(output, doc.content or "")
            table.insert(output, "")
        end
    end

    local current_design = reader
        :with_type("design_version")
        :with_parent_direct(branch_id)
        :with_statuses("current")
        :one()

    if current_design then
        table.insert(output, "## Current Design Specification")
        table.insert(output, "")
        table.insert(output, current_design.content or "")
        table.insert(output, "")
    else
        return nil, "No current design version found"
    end

    return table.concat(output, "\n")
end

return { run = run }