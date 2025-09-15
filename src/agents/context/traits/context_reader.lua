-- context_reader.lua
local json = require("json")
local security = require("security")
local ctx = require("ctx")
local reader = require("reader")

local function handler(params)
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

    if not params.command then
        return nil, "Missing command (list, get)"
    end

    local valid_commands = { list = true, get = true }
    if not valid_commands[params.command] then
        return nil, "Invalid command: " .. params.command .. " (must be: list, get)"
    end

    -- Create context reader
    local context_reader, reader_err = reader.for_context(workspace_id)
    if reader_err then
        return nil, "Failed to create context reader: " .. reader_err
    end

    if params.command == "list" then
        -- Apply filters if provided
        if params.labels and #params.labels > 0 then
            context_reader = context_reader:with_labels(unpack(params.labels))
        end

        if params.content_types and #params.content_types > 0 then
            context_reader = context_reader:with_content_types(unpack(params.content_types))
        end

        if params.limit then
            context_reader = context_reader:limit(params.limit)
        end

        -- Fetch results
        local results, fetch_err = context_reader:all()
        if fetch_err then
            return nil, "Failed to fetch context: " .. fetch_err
        end

        -- Format output
        local output = {}
        table.insert(output, "=== WORKSPACE CONTEXT ===")
        table.insert(output, "Workspace: " .. workspace_id)
        table.insert(output, "Found: " .. #results .. " context entries")

        if #results > 0 then
            table.insert(output, "")
            for _, context_entry in ipairs(results) do
                local line = "• " .. context_entry.label
                if context_entry.content_type and context_entry.content_type ~= "text/plain" then
                    line = line .. " (" .. context_entry.content_type .. ")"
                end
                line = line .. " [" .. context_entry.context_id .. "]"
                table.insert(output, line)

                if params.include_content and context_entry.content then
                    local content_lines = {}
                    for content_line in context_entry.content:gmatch("[^\r\n]+") do
                        table.insert(content_lines, "  " .. content_line)
                    end
                    if #content_lines > 0 then
                        table.insert(output, table.concat(content_lines, "\n"))
                    end
                    table.insert(output, "")
                end
            end
        else
            table.insert(output, "No context entries found")
        end

        return table.concat(output, "\n"), nil

    elseif params.command == "get" then
        if not params.context_id and not params.label then
            return nil, "Either context_id or label is required for get command"
        end

        -- Filter by context_id or label
        if params.context_id then
            context_reader = context_reader:with_context_ids(params.context_id)
        elseif params.label then
            context_reader = context_reader:with_labels(params.label)
        end

        -- Fetch the context entry
        local result, fetch_err = context_reader:one()
        if fetch_err then
            return nil, "Failed to fetch context: " .. fetch_err
        end

        if not result then
            local identifier = params.context_id or params.label
            return nil, "Context not found: " .. identifier
        end

        -- Format output
        local output = {}
        table.insert(output, "=== CONTEXT ENTRY ===")
        table.insert(output, "ID: " .. result.context_id)
        table.insert(output, "Label: " .. result.label)
        table.insert(output, "Content Type: " .. (result.content_type or "text/plain"))
        table.insert(output, "Created: " .. result.created_at)
        table.insert(output, "Updated: " .. result.updated_at)

        if result.metadata and next(result.metadata) then
            table.insert(output, "Metadata: " .. json.encode(result.metadata))
        end

        table.insert(output, "")
        table.insert(output, "Content:")
        table.insert(output, result.content or "")

        return table.concat(output, "\n"), nil
    end
end

return { handler = handler }