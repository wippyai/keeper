-- keeper.internal.llm:summarize
--
-- Shared helper for tool-level output compression. Heavy read tools pipe their
-- raw text output through this so the calling agent's observation history
-- stays small. The model is told to preserve identifiers (entry ids, node
-- ids, paths, hashes) so the agent can still act on the brief.

local llm = require("llm")
local prompt = require("prompt")
local logger = require("logger")
local time = require("time")

local log = logger:named("keeper.internal.llm.summarize")

local function snippet(s, n)
    if type(s) ~= "string" then return "" end
    if #s <= n then return s end
    return s:sub(1, n) .. "..."
end

local function usage_of(resp)
    if type(resp) ~= "table" then return nil end
    if type(resp.usage) == "table" then return resp.usage end
    if type(resp.tokens) == "table" then return resp.tokens end
    return nil
end

local function elapsed_ms(started_ns)
    if type(started_ns) ~= "number" then return nil end
    return math.floor((time.now():unix_nano() - started_ns) / 1e6)
end

local M = {}

M.DEFAULT_THRESHOLD = 6000
M.DEFAULT_MAX_TOKENS = 2000
M.DEFAULT_MODEL = "class:nano"
M.MIN_COMPRESSION_RATIO = 0.8

local SYSTEM_PROMPT = table.concat({
    "You compress tool output for an AI agent that cannot see the raw payload.",
    "Preserve every identifier the agent needs to act: entry ids (namespace:name),",
    "node ids, file paths, branch names, hashes, version numbers, kinds, meta.type,",
    "status fields, counts. Drop prose, marketing, repeated boilerplate, and any",
    "content that does not advance the stated goal.",
    "Use compact structured formatting: one line per item, bullet lists, or short",
    "sections. Do NOT invent information. If the goal is generic, keep the most",
    "structurally important rows first and trim the rest.",
    "End as soon as the goal is covered — do not pad."
}, " ")

function M.summarize(raw, goal, opts)
    opts = opts or {}

    if type(raw) ~= "string" then
        return raw, nil, false
    end

    local threshold = opts.threshold or M.DEFAULT_THRESHOLD
    if #raw < threshold then
        if log then
            log:info("summarize skip (under threshold)", {
                tool = opts.tool or "?",
                raw_bytes = #raw,
                threshold = threshold,
            })
        end
        return raw, nil, false
    end

    if log then
        log:info("summarize invoked", {
            tool = opts.tool or "?",
            raw_bytes = #raw,
            threshold = threshold,
            goal = snippet(goal, 120),
        })
    end

    local p = prompt.new()
    p:add_system(SYSTEM_PROMPT)

    local goal_text = goal
    if not goal_text or goal_text == "" then
        goal_text = "general overview of this tool output"
    end

    p:add_user("Goal: " .. goal_text)
    if opts.tool and opts.tool ~= "" then
        p:add_user("Tool: " .. opts.tool)
    end
    p:add_user("Raw output:\n" .. raw)
    p:add_user("Return the compact brief now.")

    local model = opts.model or M.DEFAULT_MODEL
    local max_tokens = opts.max_tokens or M.DEFAULT_MAX_TOKENS
    local started_ns
    do
        local ok, now = pcall(function() return time.now():unix_nano() end)
        if ok and type(now) == "number" then started_ns = now end
    end

    local resp, err = llm.generate(p, {
        model       = model,
        max_tokens  = max_tokens,
    })

    local duration_ms = elapsed_ms(started_ns)

    if err or not resp or not resp.result or resp.result == "" then
        if log then
            log:warn("summarize bypass (llm error)", {
                tool = opts.tool or "?",
                model = model,
                raw_bytes = #raw,
                duration_ms = duration_ms,
                goal = snippet(goal_text, 120),
                error = tostring(err or "empty_response"),
                resp_kind = type(resp),
                result_kind = type(resp) == "table" and type(resp.result) or "nil",
            })
        end
        return raw, err, false
    end

    local brief = resp.result
    local ratio = #brief / math.max(#raw, 1)
    local usage = usage_of(resp)
    local threshold_bytes = math.floor(#raw * M.MIN_COMPRESSION_RATIO)

    if #brief >= threshold_bytes then
        if log then
            log:info("summarize bypass (below threshold)", {
                tool = opts.tool or "?",
                model = model,
                raw_bytes = #raw,
                brief_bytes = #brief,
                ratio = string.format("%.3f", ratio),
                min_ratio = M.MIN_COMPRESSION_RATIO,
                threshold_bytes = threshold_bytes,
                duration_ms = duration_ms,
                goal = snippet(goal_text, 120),
                usage = usage,
            })
        end
        return raw, "compression_below_threshold", false
    end

    if log then
        log:info("summarize ok", {
            tool = opts.tool or "?",
            model = model,
            raw_bytes = #raw,
            brief_bytes = #brief,
            ratio = string.format("%.3f", ratio),
            duration_ms = duration_ms,
            goal = snippet(goal_text, 120),
            usage = usage,
        })
    end

    local footer = string.format(
        "\n\n[compressed by %s (%d chars -> %d). Pass full=true or a narrower query to receive raw output.]",
        model, #raw, #brief)

    return brief .. footer, nil, true
end

return M
