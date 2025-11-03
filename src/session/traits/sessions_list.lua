local session_repo = require("session_repo")
local security = require("security")

-- Helper function to format token counts from session meta
local function format_token_info(meta)
    if not meta then return "No token data" end
    
    -- Check for tokens sub-table
    local tokens = meta.tokens or meta
    if not tokens then return "No token data" end
    
    -- Try common token field names
    local total = tokens.total_tokens or tokens.total or 0
    local prompt = tokens.prompt_tokens or tokens.prompt or 0  
    local completion = tokens.completion_tokens or tokens.completion or 0
    
    if total > 0 then
        return string.format("Total: %d (Prompt: %d, Completion: %d)", total, prompt, completion)
    else
        -- Debug: show what fields are available in tokens
        local fields = {}
        for k, v in pairs(tokens) do
            if type(v) == "number" and v > 0 then
                table.insert(fields, string.format("%s=%d", k, v))
            elseif type(v) == "string" then  
                table.insert(fields, string.format("%s=%s", k, v))
            end
        end
        if #fields > 0 then
            return "Fields: " .. table.concat(fields, ", ")
        else
            return "Token data present but no readable fields"
        end
    end
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
    -- Get user ID from authenticated context
    local actor = security.actor()
    if not actor then
        return "ERROR: Authentication required"
    end
    local user_id = actor:id()
    
    -- Set pagination parameters
    local limit = params.limit or 10
    local offset = params.offset or 0
    
    -- Get user's sessions
    local sessions, err = session_repo.list_by_user(user_id, limit, offset)
    if err then
        return "ERROR: Failed to fetch sessions: " .. err
    end
    
    if not sessions or #sessions == 0 then
        return "No sessions found for user: " .. user_id
    end
    
    -- Build YAML-like output
    local output = {}
    table.insert(output, "=== USER SESSIONS ===")
    table.insert(output, "")
    table.insert(output, string.format("Found %d sessions:", #sessions))
    table.insert(output, "")
    
    for i, session in ipairs(sessions) do
        table.insert(output, string.format("%d. Session ID: %s", i, session.session_id))
        -- Extract title from meta if not available at top level
        local title = session.title
        if not title and session.meta and session.meta.title then
            title = session.meta.title
        end
        table.insert(output, string.format("   Title: %s", title or "(No title)"))
        
        table.insert(output, string.format("   Status: %s", session.status or "unknown"))
        table.insert(output, string.format("   Created: %s", format_timestamp(session.created_at)))
        table.insert(output, string.format("   Updated: %s", format_timestamp(session.updated_at)))
        table.insert(output, string.format("   User: %s", session.user_id))
        
        -- Show token information from meta
        local token_info = format_token_info(session.meta)
        table.insert(output, string.format("   Tokens: %s", token_info))
        
        -- Show additional meta information if available
        if session.meta then
            if session.meta.model then
                table.insert(output, string.format("   Model: %s", session.meta.model))
            end
            if session.meta.agent_id or session.meta.agent then
                table.insert(output, string.format("   Agent: %s", session.meta.agent_id or session.meta.agent))
            end
            if session.meta.context_id then
                table.insert(output, string.format("   Context: %s", session.meta.context_id))
            end
            -- Show other interesting meta fields
            for key, value in pairs(session.meta) do
                if not (key == "tokens" or key == "checkpoints" or key == "title" or 
                        key == "model" or key == "agent_id" or key == "agent" or key == "context_id") and
                   type(value) ~= "table" then
                    table.insert(output, string.format("   %s: %s", key, tostring(value)))
                end
            end
        end
        
        -- Show public meta if available
        if session.public_meta then
            table.insert(output, string.format("   Public Meta: %s", tostring(session.public_meta)))
        end
        
        table.insert(output, "")
    end
    
    table.insert(output, string.format("Showing sessions %d-%d for user %s", offset + 1, offset + #sessions, user_id))
    
    return table.concat(output, "\n")
end