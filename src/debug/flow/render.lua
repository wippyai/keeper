-- keeper.debug.flow:render
--
-- Markdown rendering helpers. Tool handlers return plain markdown strings
-- (via _mcp_content = {type="text"}) so the LLM reads formatted text, not
-- JSON it has to re-parse.

local json = require("json")

local M = {}

-- Visible-length bounds.
M.PREVIEW_CHARS = 240      -- per-cell preview
M.ARGS_PREVIEW = 400       -- tool call args preview
M.OBS_PREVIEW = 500        -- tool observation preview
M.TREE_CAP = 250           -- tree row cap before truncation
M.TRANSCRIPT_CAP = 120     -- transcript entry cap

local function shorten(id)
    if type(id) ~= "string" then return tostring(id) end
    if #id <= 12 then return id end
    return id:sub(1, 8) .. ".." .. id:sub(-4)
end
M.shorten = shorten

local function clip(s, n)
    if type(s) ~= "string" then
        local ok, enc = pcall(json.encode, s)
        s = ok and enc or tostring(s)
    end
    s = s:gsub("\n", " "):gsub("  +", " ")
    if #s <= n then return s end
    return s:sub(1, n - 1) .. "..."
end
M.clip = clip

local function short_type(t)
    if type(t) ~= "string" then return tostring(t) end
    local tail = t:match("([^:]+)$")
    if tail then
        tail = tail:gsub("^node%.dataflow%.node%.", "")
                   :gsub("^userspace%.dataflow%.node%.", "")
        return tail
    end
    return t
end
M.short_type = short_type

local function status_marker(status)
    if status == "completed" then return "OK " end
    if status == "failed" then return "FAIL" end
    if status == "running" then return "RUN " end
    if status == "pending" then return "WAIT" end
    if status == "cancelled" then return "CANC" end
    if status == "terminated" then return "TERM" end
    if status == "template" then return "TMPL" end
    return (status or "?"):sub(1, 4):upper()
end
M.status_marker = status_marker

local function fmt_duration_ms(ms)
    if not ms or ms <= 0 then return "-" end
    if ms < 1000 then return ms .. "ms" end
    if ms < 60000 then return string.format("%.1fs", ms / 1000) end
    return string.format("%dm%02ds", math.floor(ms / 60000), math.floor((ms % 60000) / 1000))
end
M.fmt_duration_ms = fmt_duration_ms

local function node_title(node)
    local meta = node.metadata or {}
    if meta.title and meta.title ~= "" then return meta.title end
    if meta.status_message and meta.status_message ~= "" then return meta.status_message end
    if meta.public_meta and meta.public_meta.title then return meta.public_meta.title end
    local state = meta.state or {}
    if state.agent_id then return state.agent_id end
    return short_type(node.type)
end
M.node_title = node_title

local function node_error(node)
    local meta = node.metadata or {}
    if meta.error_message and meta.error_message ~= "" then return meta.error_message end
    if meta.error and type(meta.error) == "table" then
        if meta.error.code or meta.error.message then
            return (meta.error.code or "") .. ": " .. (meta.error.message or "")
        end
    end
    if meta.status_message and (node.status == "failed") then return meta.status_message end
    return nil
end
M.node_error = node_error

function M.table_header(cols)
    local header = "| " .. table.concat(cols, " | ") .. " |"
    local sep = "|"
    for _ = 1, #cols do sep = sep .. "---|" end
    return header .. "\n" .. sep
end

function M.table_row(cells)
    local escaped = {}
    for _, c in ipairs(cells) do
        local s = tostring(c or ""):gsub("|", "\\|"):gsub("\n", " ")
        table.insert(escaped, s)
    end
    return "| " .. table.concat(escaped, " | ") .. " |"
end

-- Convert RFC3339 or millisecond timestamp to millisecond integer for arithmetic.
function M.to_ms(ts)
    if type(ts) == "number" then
        if ts > 1e12 then return ts end
        return ts * 1000
    end
    if type(ts) ~= "string" then return 0 end
    -- RFC3339 parse: very permissive, extract seconds + millis
    local y, mo, d, h, mi, s, frac = ts:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%.?(%d*)")
    if not y then return 0 end
    local secs = os.time({
        year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h), min = tonumber(mi), sec = tonumber(s),
    }) or 0
    local ms = secs * 1000
    if frac and frac ~= "" then
        ms = ms + math.floor(tonumber("0." .. frac) * 1000)
    end
    return ms
end

return M
