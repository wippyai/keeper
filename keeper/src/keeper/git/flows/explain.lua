-- Per-recommendation deep-dive. Takes a cluster + recommendation + the
-- relevant change rows and asks the LLM to expand the finding into a
-- structured analysis: what's wrong, why it matters, concrete fix steps,
-- which entries to look at first.

local llm = require("llm")
local prompt = require("prompt")
local logger = require("logger")
local time = require("time")

local log = logger:named("keeper.git.explain")

local M = {}

M.DEFAULT_MODEL = "class:smart"
M.DEFAULT_MAX_TOKENS = 1500

local SYSTEM_PROMPT = table.concat({
    "You are a senior code reviewer expanding a single AI-flagged finding into",
    "a focused, actionable explanation for the engineer reviewing the change.",
    "",
    "RULES:",
    "- Be concrete: cite specific files/entries from the change list.",
    "- Be brief: 4-8 short sentences total. No preamble. No restating the rule.",
    "- Plain English. Avoid jargon and namespace IDs unless useful.",
    "- If the finding is a likely false positive, say so plainly.",
    "- End with a clear 'Fix steps' bulleted list, max 5 bullets.",
    "",
    "OUTPUT shape (plain text, no JSON):",
    "  <one paragraph: what the issue actually is>",
    "  <one paragraph: why it matters here>",
    "  Fix steps:",
    "  - step 1",
    "  - step 2",
    "  ...",
}, "\n")

local function build_user_prompt(cluster, recommendation, change_list)
    local lines = {
        "Cluster: " .. (cluster.title or "?"),
        "Cluster summary: " .. (cluster.plain_summary or "?"),
        "",
        "Finding to explain:",
        "  severity: " .. (recommendation.severity or "info"),
        "  text:     " .. (recommendation.text or ""),
    }
    if recommendation.fix_hint then
        table.insert(lines, "  fix_hint: " .. recommendation.fix_hint)
    end
    table.insert(lines, "")
    table.insert(lines, "Relevant changes (op | path):")
    -- cap at 30 changes so prompt stays cheap
    local n = math.min(#change_list, 30)
    for i = 1, n do
        local ch = change_list[i]
        local path = ch.path or ch.target or "?"
        table.insert(lines, string.format("  %s | %s", ch.op or "?", path))
    end
    if #change_list > n then
        table.insert(lines, string.format("  ... %d more files (omitted for brevity)", #change_list - n))
    end
    table.insert(lines, "")
    table.insert(lines, "Explain this finding now.")
    return table.concat(lines, "\n")
end

-- Public: explain(cluster, recommendation, change_list, opts) -> { ok, text, model, duration_ms } | { ok=false, error }
function M.run(cluster, recommendation, change_list, opts)
    opts = opts or {}
    if not cluster then return { ok = false, error = "cluster required" } end
    if not recommendation then return { ok = false, error = "recommendation required" } end

    local p = prompt.new()
    p:add_system(SYSTEM_PROMPT)
    p:add_user(build_user_prompt(cluster, recommendation, change_list or {}))

    local model = opts.model or M.DEFAULT_MODEL
    local started_ns = time.now():unix_nano()

    local resp, err = llm.generate(p, {
        model      = model,
        max_tokens = opts.max_tokens or M.DEFAULT_MAX_TOKENS,
    })
    local duration_ms = math.floor((time.now():unix_nano() - started_ns) / 1e6)

    if err or not resp or not resp.result or resp.result == "" then
        log:warn("explain llm failed", { model = model, error = tostring(err or "empty") })
        return { ok = false, error = "llm: " .. tostring(err or "empty response") }
    end

    return {
        ok          = true,
        text        = resp.result,
        model       = model,
        duration_ms = duration_ms,
        usage       = rawget(resp, "usage"),
    }
end

M._build_user_prompt = build_user_prompt

return M
