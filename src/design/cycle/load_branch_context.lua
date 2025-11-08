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
    local branch, err = reader:with_data(branch_id):one()
    if err or not branch then
        return nil, "Branch not found: " .. (err or branch_id)
    end

    local iterations = reader
        :with_type("iteration")
        :with_parent_direct(branch_id)
        :order_by_position()
        :all()

    local current_iteration = #(iterations or {}) + 1

    local output = {}

    table.insert(output, "# CURRENT ITERATION: " .. current_iteration)
    table.insert(output, "")
    table.insert(output, "# Design Context")
    table.insert(output, "")
    table.insert(output, "**Branch**: " .. (branch.metadata.title or branch_id))
    table.insert(output, "**Status**: " .. branch.status)
    table.insert(output, "")

    table.insert(output, "## Original Prompt")
    table.insert(output, "")
    if branch.content then
        table.insert(output, branch.content)
    end
    table.insert(output, "")

    local context_docs = reader
        :with_type("context")
        :with_parent_direct(branch_id)
        :with_statuses("current")
        :order_by_position()
        :all()

    if #(context_docs or {}) > 0 then
        table.insert(output, "## Stable Context")
        table.insert(output, "")
        table.insert(output, "*These are persistent discoveries that remain visible across iterations. Reference them in your design.*")
        table.insert(output, "")
        for _, doc in ipairs(context_docs) do
            local key = doc.discriminator or "context"
            local comment = (doc.metadata or {}).comment or ""
            table.insert(output, "### context:" .. key)
            if comment and comment ~= "" then
                table.insert(output, "*" .. comment .. "*")
                table.insert(output, "")
            end
            table.insert(output, doc.content or "")
            table.insert(output, "")
        end
    end

    local branch_feedback = reader
        :with_type("feedback")
        :with_parent_direct(branch_id)
        :order_by_position()
        :all()

    if #(branch_feedback or {}) > 0 then
        table.insert(output, "## Branch Feedback")
        table.insert(output, "")
        for _, fb in ipairs(branch_feedback) do
            local fb_meta = fb.metadata or {}
            local fb_type = fb_meta.feedback_type or fb.discriminator or "feedback"
            table.insert(output, "**" .. fb_type:gsub("^%l", string.upper) .. "**: " .. (fb.content or ""))
            table.insert(output, "")
        end
    end

    if #(iterations or {}) > 0 then
        table.insert(output, "## Reasoning Chain")
        table.insert(output, "")
        for i, iter in ipairs(iterations) do
            table.insert(output, "### Iteration " .. i)
            table.insert(output, "")
            table.insert(output, iter.content or "")
            table.insert(output, "")
        end
    end

    local all_designs = reader
        :with_type("design_version")
        :with_parent_direct(branch_id)
        :order_by_position()
        :all()

    local current_design = nil
    local previous_designs = {}

    for _, design in ipairs(all_designs or {}) do
        if design.status == "current" then
            current_design = design
        elseif design.status == "superseded" then
            table.insert(previous_designs, design)
        end
    end

    local last_design_iteration = nil
    if current_design and current_design.metadata then
        last_design_iteration = current_design.metadata.created_in_iteration
    end

    if #previous_designs > 0 then
        table.insert(output, "## Previous Design Versions")
        table.insert(output, "")
        for _, design in ipairs(previous_designs) do
            local meta = design.metadata or {}
            local version = meta.version or "?"
            local title = meta.title or "Design Spec"
            local comment = meta.comment or ""
            local iteration = meta.created_in_iteration or "?"

            table.insert(output, string.format("- **%s** (v%s, iteration %s, superseded) [ID: %s]", title, version, iteration, design.data_id))
            if comment and comment ~= "" then
                table.insert(output, "  *" .. comment .. "*")
            end
        end
        table.insert(output, "")
    end

    if current_design then
        table.insert(output, "## Current Design")
        table.insert(output, "")
        table.insert(output, current_design.content or "")
        table.insert(output, "")
    end

    local all_research = reader
        :with_type("research")
        :with_parent_direct(branch_id)
        :with_statuses("completed")
        :order_by_position()
        :all()

    local new_research = {}
    local previous_research = {}

    if last_design_iteration then
        for _, r in ipairs(all_research) do
            local meta = r.metadata or {}
            local req_iter = meta.requested_in_iteration or 0
            if req_iter > last_design_iteration then
                table.insert(new_research, r)
            else
                table.insert(previous_research, r)
            end
        end
    else
        new_research = all_research
    end

    if #previous_research > 0 then
        table.insert(output, "## Previous Research Results")
        table.insert(output, "")
        for _, r in ipairs(previous_research) do
            local meta = r.metadata or {}
            local title = meta.title or "Research"
            local agent_id = meta.agent_id or "unknown"
            local iteration = meta.requested_in_iteration or "?"
            local comment = meta.comment or ""

            table.insert(output, string.format("- **%s** (by %s, iteration %s, completed) [ID: %s]", title, agent_id, iteration, r.data_id))
            if comment and comment ~= "" then
                table.insert(output, "  *" .. comment .. "*")
            end
        end
        table.insert(output, "")
    end

    if #new_research > 0 then
        table.insert(output, "## New Research Results")
        table.insert(output, "")
        for _, r in ipairs(new_research) do
            local meta = r.metadata or {}
            table.insert(output, "### " .. (meta.title or "Research"))
            table.insert(output, "")
            table.insert(output, "**Agent**: " .. (meta.agent_id or "unknown"))
            table.insert(output, "")
            if r.content then
                table.insert(output, r.content)
                table.insert(output, "")
            end

            local research_feedback = reader
                :with_type("feedback")
                :with_parent_direct(r.data_id)
                :order_by_position()
                :all()

            if #(research_feedback or {}) > 0 then
                for _, fb in ipairs(research_feedback) do
                    local fb_meta = fb.metadata or {}
                    local fb_type = fb_meta.feedback_type or fb.discriminator or "feedback"
                    table.insert(output, "*" .. fb_type:gsub("^%l", string.upper) .. "*: " .. (fb.content or ""))
                    table.insert(output, "")
                end
            end
        end
    end

    local my_questions = reader
        :with_type("question")
        :with_parent_direct(branch_id)
        :with_statuses("open")
        :order_by_position()
        :all()

    if #(my_questions or {}) > 0 then
        table.insert(output, "## Open Questions")
        table.insert(output, "")
        for i, q in ipairs(my_questions) do
            local meta = q.metadata or {}
            table.insert(output, "### Question " .. i)
            table.insert(output, "")
            table.insert(output, "**ID**: " .. q.data_id)
            table.insert(output, "**Blocking**: " .. tostring(meta.blocking or false))
            table.insert(output, "")
            table.insert(output, q.content)
            table.insert(output, "")
            if meta.comment then
                table.insert(output, "*Context: " .. meta.comment .. "*")
                table.insert(output, "")
            end
        end
    end

    local answered_questions = reader
        :with_type("question")
        :with_parent_direct(branch_id)
        :with_statuses("answered")
        :order_by_position()
        :all()

    if #(answered_questions or {}) > 0 then
        table.insert(output, "## Answered Questions")
        table.insert(output, "")
        for i, q in ipairs(answered_questions) do
            local meta = q.metadata or {}
            table.insert(output, "### Question " .. i .. " (Answered) [ID: " .. q.data_id .. "]")
            table.insert(output, "")
            table.insert(output, q.content)
            table.insert(output, "")

            local feedback = reader
                :with_type("feedback")
                :with_parent_direct(q.data_id)
                :order_by_position()
                :all()

            if #(feedback or {}) > 0 then
                for _, fb in ipairs(feedback) do
                    local fb_meta = fb.metadata or {}
                    local fb_type = fb_meta.feedback_type or fb.discriminator or "feedback"
                    table.insert(output, "**" .. fb_type:gsub("^%l", string.upper) .. "**: " .. (fb.content or ""))
                    table.insert(output, "")
                end
            end
        end
    end

    local children = reader
        :with_type("design")
        :with_parent_direct(branch_id)
        :order_by_position()
        :all()

    if #(children or {}) > 0 then
        table.insert(output, "## Child Branches")
        table.insert(output, "")
        for i, child in ipairs(children) do
            local meta = child.metadata or {}
            table.insert(output, string.format("%d. **%s** (Status: %s, ID: %s)",
                i,
                meta.title or "Untitled",
                child.status,
                child.data_id))

            local child_questions = reader
                :with_type("question")
                :with_parent_direct(child.data_id)
                :with_statuses("open")
                :count()

            if child_questions and child_questions > 0 then
                table.insert(output, string.format("   - ⚠ Has %d open questions", child_questions))
            end
            table.insert(output, "")
        end
    end

    return table.concat(output, "\n")
end

return { run = run }