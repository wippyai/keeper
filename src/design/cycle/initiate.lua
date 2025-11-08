local json = require("json")
local consts = require("design_consts")
local design_writer = require("design_writer")

local function handler(args)
    local title = args.title
    local description = args.description
    local prompt = args.prompt
    local file_ids = args.file_ids or {}

    if not title or title == "" then
        return nil, "title required"
    end

    if not prompt or prompt == "" then
        return nil, "prompt required"
    end

    local ws = design_writer.workspace(title, description, { design_type = "component" })

    local root_branch_id = nil
    local root_builder = ws:data({
        type = "design",
        discriminator = "root",
        content_type = "text/plain",
        content = prompt,
        status = "scheduled",
        metadata = {
            created_via = "initiate_design",
            has_file_references = #file_ids > 0,
            title = title
        }
    })

    for i, file_id in ipairs(file_ids) do
        root_builder:data({
            type = "reference",
            discriminator = "upload_file",
            content_type = "application/json",
            content = json.encode({
                file_id = file_id,
                source = "user_upload"
            }),
            status = "collected",
            metadata = {
                reference_type = "upload_file",
                needs_processing = true
            }
        })
    end

    local result, err = ws:execute()

    if err then
        return nil, "Failed to create workspace: " .. err
    end

    local root_data_id = result.results[1] and result.results[1].data_id

    return {
        workspace_id = result.workspace_id,
        root_branch_id = root_data_id,
        title = title,
        status = "initialized",
        message = "Design workspace created" .. (#file_ids > 0 and (" with " .. #file_ids .. " file references") or "") .. "use iterate to start design development.",
        _control = {
            context = {
                session = {
                    set = {
                        active_workspace_id = result.workspace_id
                    }
                },
                public_meta = {
                    set = {
                        {
                            id = "workspace_info",
                            title = title,
                            display_name = "Workspace: " .. title,
                            type = "workspace",
                            icon = "tabler:layout-dashboard",
                            url = nil,
                            workspace_id = result.workspace_id
                        }
                    }
                }
            }
        }
    }
end

return { handler = handler }