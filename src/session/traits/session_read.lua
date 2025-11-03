local session_repo = require("session_repo")
local message_repo = require("message_repo")
local security = require("security")

-- Helper function to format session metadata
local function format_meta(meta, title)
    if not meta then return title .. ": None" end
    
    local lines = {}
    table.insert(lines, title .. ":")
    
    -- Check for tokens sub-table first
    local tokens = meta.tokens
    if tokens and type(tokens) == "table" then
        table.insert(lines, "  Tokens:")
        for key, value in pairs(tokens) do
            if type(value) == "number" then
                table.insert(lines, string.format("    %s: %d", key, value))
            else
                table.insert(lines, string.format("    %s: %s", key, tostring(value)))
            end
        end
    else
        -- Token information at top level
        if meta.total_tokens or meta.total then
            table.insert(lines, string.format("  Total Tokens: %d", meta.total_tokens or meta.total or 0))
        end
        if meta.prompt_tokens or meta.prompt then
            table.insert(lines, string.format("  Prompt Tokens: %d", meta.prompt_tokens or meta.prompt or 0))
        end
        if meta.completion_tokens or meta.completion then
            table.insert(lines, string.format("  Completion Tokens: %d", meta.completion_tokens or meta.completion or 0))
        end
    end
    
    -- Model information
    if meta.model then
        table.insert(lines, string.format("  Model: %s", meta.model))
    end
    
    -- Context information
    if meta.context_id then
        table.insert(lines, string.format("  Context ID: %s", meta.context_id))
    end
    
    -- Checkpoints information
    if meta.checkpoints and type(meta.checkpoints) == "table" then
        table.insert(lines, "  Checkpoints:")
        for key, value in pairs(meta.checkpoints) do
            table.insert(lines, string.format("    %s: %s", key, tostring(value)))
        end
    end
    
    -- Any other fields (excluding already processed ones)
    for key, value in pairs(meta) do
        if not (key == "total_tokens" or key == "total" or key == "prompt_tokens" or 
                key == "prompt" or key == "completion_tokens" or key == "completion" or
                key == "model" or key == "context_id" or key == "tokens" or key == "checkpoints" or
                key == "title" or key == "agent_id" or key == "agent") then
            if type(value) == "table" then
                local count = 0
                for _ in pairs(value) do count = count + 1 end
                table.insert(lines, string.format("  %s: [table with %d items]", key, count))
            else
                table.insert(lines, string.format("  %s: %s", key, tostring(value)))
            end
        end
    end
    
    return table.concat(lines, "\n")
end

-- Helper function to format timestamp
local function format_timestamp(timestamp)
    if not timestamp then return "Unknown" end
    
    -- Handle different timestamp formats
    if type(timestamp) == "string" then
        return timestamp -- Already formatted string
    elseif type(timestamp) == "number" then
        return os.date("%Y-%m-%d %H:%M:%S", timestamp)
    else
        return string.format("Unknown format: %s (%s)", tostring(timestamp), type(timestamp))
    end
end

function handler(params)
    if not params.session_id then
        return "ERROR: session_id is required"
    end
    
    -- Get user ID from authenticated context
    local actor = security.actor()
    if not actor then
        return "ERROR: Authentication required"
    end
    local user_id = actor:id()
    
    -- Get session details
    local session, err = session_repo.get(params.session_id)
    if err then
        return "ERROR: Failed to fetch session: " .. err
    end
    
    if not session then
        return "ERROR: Session not found: " .. params.session_id
    end
    
    -- Verify user has access to this session
    if session.user_id ~= user_id then
        return "ERROR: Access denied to session: " .. params.session_id
    end
    
    -- Build detailed session output
    local output = {}
    table.insert(output, "=== SESSION DETAILS ===")
    table.insert(output, "")
    table.insert(output, string.format("Session ID: %s", session.session_id))
    -- Extract title from meta if not available at top level
    local title = session.title
    if not title and session.meta and session.meta.title then
        title = session.meta.title
    end
    table.insert(output, string.format("Title: %s", title or "(No title)"))
    
    table.insert(output, string.format("Status: %s", session.status or "unknown"))
    table.insert(output, string.format("Kind: %s", session.kind or "unknown"))
    table.insert(output, string.format("User ID: %s", session.user_id))
    
    -- Extract agent info from meta
    if session.meta then
        if session.meta.agent_id or session.meta.agent then
            table.insert(output, string.format("Agent: %s", session.meta.agent_id or session.meta.agent))
        end
        if session.meta.model then
            table.insert(output, string.format("Model: %s", session.meta.model))
        end
    end
    table.insert(output, string.format("Created: %s", format_timestamp(session.created_at)))
    table.insert(output, string.format("Updated: %s", format_timestamp(session.updated_at)))
    
    if session.primary_context_id then
        table.insert(output, string.format("Primary Context: %s", session.primary_context_id))
    end
    
    table.insert(output, "")
    
    -- Session metadata
    if session.meta then
        table.insert(output, format_meta(session.meta, "Session Metadata"))
        table.insert(output, "")
    end
    
    -- Public metadata  
    if session.public_meta then
        table.insert(output, format_meta(session.public_meta, "Public Metadata"))
        table.insert(output, "")
    end
    
    -- Configuration
    if session.config then
        table.insert(output, "Configuration:")
        for key, value in pairs(session.config) do
            table.insert(output, string.format("  %s: %s", key, tostring(value)))
        end
        table.insert(output, "")
    end
    
    -- Get message summary if requested
    if params.include_messages and params.include_messages == true then
        local message_limit = params.message_limit or 10
        local messages_result, msg_err = message_repo.list_by_session(params.session_id, message_limit)
        
        if not msg_err and messages_result and messages_result.messages then
            local messages = messages_result.messages
            table.insert(output, string.format("Recent Messages (%d shown):", #messages))
            
            for i, message in ipairs(messages) do
                table.insert(output, string.format("  %d. [%s] %s", i, message.type or "unknown", 
                    string.sub(tostring(message.data or ""), 1, 100) .. (string.len(tostring(message.data or "")) > 100 and "..." or "")))
            end
            table.insert(output, "")
        end
    end
    
    table.insert(output, "Use include_messages=true and message_limit=N to see message content")
    
    return table.concat(output, "\n")
end