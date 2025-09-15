local session_repo = require("session_repo")
local message_repo = require("message_repo")
local security = require("security")

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
    
    if not params.query then
        return "ERROR: query parameter is required"
    end
    
    local limit = params.limit or 20
    local offset = params.offset or 0
    
    -- Get user's sessions  
    local sessions, err = session_repo.list_by_user(user_id, 100, 0) -- Search through recent sessions
    if err then
        return "ERROR: Failed to fetch sessions: " .. err
    end
    
    local all_matches = {}
    local query = params.query
    local sessions_scanned = 0
    local messages_scanned = 0
    
    -- Scan through each session
    for _, session in ipairs(sessions) do
        sessions_scanned = sessions_scanned + 1
        
        -- Get messages for this session
        local messages_result, msg_err = message_repo.list_by_session(session.session_id, 500)
        local messages = {}
        if not msg_err and messages_result then
            messages = messages_result.messages or {}
        end
        
        -- Search through messages
        for _, message in ipairs(messages) do
            messages_scanned = messages_scanned + 1
            
            -- Text query matching in message data
            if message.data then
                local data_str = tostring(message.data)
                if string.find(data_str:lower(), query:lower()) then
                    -- Extract context around match
                    local match_start = string.find(data_str:lower(), query:lower())
                    local context_start = math.max(1, match_start - 50)
                    local context_end = math.min(string.len(data_str), match_start + string.len(query) + 50)
                    local context = string.sub(data_str, context_start, context_end)
                    
                    -- Extract title from meta if not available at top level
                    local title = session.title
                    if not title and session.meta and session.meta.title then
                        title = session.meta.title
                    end
                    
                    table.insert(all_matches, {
                        session_id = session.session_id,
                        session_title = title or "(No title)",
                        message_type = message.type or "unknown",
                        context = context,
                        timestamp = message.date,
                        match_position = match_start
                    })
                end
            end
        end
    end
    
    -- Sort matches by timestamp (most recent first)
    table.sort(all_matches, function(a, b)
        if not a.timestamp then return false end
        if not b.timestamp then return true end
        return a.timestamp > b.timestamp
    end)
    
    -- Apply pagination
    local total_matches = #all_matches
    local start_index = offset + 1
    local end_index = math.min(offset + limit, total_matches)
    
    -- Build output
    local output = {}
    table.insert(output, "=== SESSION SCAN RESULTS ===")
    table.insert(output, "")
    table.insert(output, string.format("Query: '%s'", query))
    table.insert(output, string.format("Found %d matches in %d messages across %d sessions", 
        total_matches, messages_scanned, sessions_scanned))
    table.insert(output, string.format("Showing matches %d-%d:", start_index, end_index))
    table.insert(output, "")
    
    if total_matches == 0 then
        table.insert(output, "No matches found.")
    else
        for i = start_index, end_index do
            if all_matches[i] then
                local match = all_matches[i]
                table.insert(output, string.format("%d. Session: %s", i, match.session_id))
                table.insert(output, string.format("   Title: %s", match.session_title))
                table.insert(output, string.format("   Type: %s", match.message_type))
                table.insert(output, string.format("   Time: %s", format_timestamp(match.timestamp)))
                table.insert(output, string.format("   Context: ...%s...", match.context))
                table.insert(output, "")
            end
        end
        
        if end_index < total_matches then
            table.insert(output, string.format("Use offset=%d to see more matches", end_index))
        end
    end
    
    return table.concat(output, "\n")
end