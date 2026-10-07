local expr = require("expr")

local filter = {}

local SYNTAX = 'Filter is an expression over the log entry fields level, message, path, logger_name, caller and fields.<key>, '
    .. 'using ==, !=, >=, <=, <, >, contains, startsWith, endsWith, and, or, not and parentheses. '
    .. 'A single word without spaces matches as a substring of message. '
    .. 'Examples: job_worker | message contains "lease expired" | level >= 1 and path startsWith "gov"'

filter.SYNTAX = SYNTAX

local KEYWORDS = { ["true"] = true, ["false"] = true, ["nil"] = true, ["null"] = true }

local function is_bare_token(text: string): boolean
    if not text:match("^[%w_][%w_%.:/%-]*$") then return false end
    if KEYWORDS[text] then return false end
    if tonumber(text) then return false end
    return true
end

-- A bare token is a substring match on message; any other text is an expression.
function filter.normalize(text: string?): string?
    if type(text) ~= "string" then return text end
    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil end
    if is_bare_token(trimmed) then
        return 'message contains "' .. trimmed .. '"'
    end
    return trimmed
end

function filter.compile(text: string)
    local normalized = filter.normalize(text)
    if not normalized then return nil, "Filter is empty. " .. SYNTAX end
    local program, err = expr.compile(normalized)
    if err then
        return nil, tostring(err) .. ". " .. SYNTAX
    end
    return program, nil
end

return filter
