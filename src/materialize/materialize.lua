local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local uuid = require("uuid")
local design_reader = require("design_reader")
local design_writer = require("design_writer")

local function handler(args)
    local branch_id = args.branch_id
    local max_iterations = args.max_iterations or 8

    if not branch_id then
        local workspace_id = ctx.get("active_workspace_id")
        if not workspace_id then
            return nil, "active_workspace_id not set and branch_id not provided"
        end

        local reader = design_reader.for_workspace(workspace_id)
        local root, err = reader
            :with_type("design")
            :with_discriminator("root")
            :with_depth(0)
            :one()

        if err or not root then
            return nil, "Root branch not found: " .. (err or "not found")
        end

        branch_id = root.data_id
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

    local meta = branch.metadata or {}
    if not meta.is_final then
        return nil, "Design must be marked final before materialization"
    end

    local materialize_node_id = ctx.get("materialize_node_id")
    local overlay_branch = ctx.get("overlay_branch")

    if not materialize_node_id or not overlay_branch then
        local materialize_node = reader
            :with_type("materialize")
            :with_discriminator("root")
            :one()

        if not materialize_node then
            local new_branch = "impl-" .. uuid.v7():sub(1, 8)

            local ws = design_writer.existing_workspace(workspace_id)
            ws:data({
                type = "materialize",
                discriminator = "root",
                content = "Implementation materialization for: " .. (meta.title or branch_id),
                content_type = "text/plain",
                status = "active",
                position = 0,
                metadata = {
                    parent_branch_id = branch_id,
                    overlay_branch = new_branch,
                    created_at_iteration = 0
                }
            })

            local result, exec_err = ws:execute()
            if exec_err then
                return nil, "Failed to create materialize node: " .. exec_err
            end

            materialize_node_id = result.results[1].data_id
            overlay_branch = new_branch
        else
            materialize_node_id = materialize_node.data_id
            local node_meta = materialize_node.metadata or {}
            overlay_branch = node_meta.overlay_branch

            if not overlay_branch then
                overlay_branch = "impl-" .. uuid.v7():sub(1, 8)
                node_meta.overlay_branch = overlay_branch

                local ws = design_writer.existing_workspace(workspace_id)
                ws:update_data(materialize_node_id, {
                    metadata = node_meta
                })
                ws:execute()
            end
        end

        local control = {
            context = {
                session = {
                    set = {
                        materialize_node_id = materialize_node_id,
                        overlay_branch = overlay_branch
                    }
                },
                public_meta = {
                    set = {
                        {
                            id = "materialize_info",
                            title = "Materialization",
                            display_name = "Materialization: " .. (meta.title or branch_id),
                            type = "materialize",
                            icon = "tabler:code",
                            url = nil,
                            materialize_node_id = materialize_node_id,
                            branch = overlay_branch
                        }
                    }
                }
            }
        }

        return {
            materialize_node_id = materialize_node_id,
            overlay_branch = overlay_branch,
            branch_id = branch_id,
            message = "Materialization context initialized. Call materialize again to begin implementation cycle.",
            _control = control
        }
    end

    return flow.create()
        :with_title("Building Your Design")
        :with_input({
            branch_id = branch_id,
            materialize_node_id = materialize_node_id
        })
        :as("input")

        :cycle({
            func_id = "keeper.materialize.cycle:materialize_cycle",
            max_iterations = max_iterations,
            initial_state = {
                branch_id = branch_id,
                materialize_node_id = materialize_node_id,
                iterations_run = 0,
                has_integrated = false
            },
            metadata = {
                title = "Creating Features",
                icon = "tabler:code"
            }
        })
        :as("cycle")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { handler = handler }