-- One LLM call: take a too-large cluster's file list, return 2-4 sub-cluster
-- proposals as { title, plain_summary, change_ids }. Used when the user picks
-- "AI suggest" in the split modal.

local llm = require("llm")
local prompt = require("prompt")
local logger = require("logger")
local time = require("time")
local llm_groups = require("llm_groups")

local log = logger:named("keeper.git.suggest_split")

local M = {}

M.DEFAULT_MODEL = "class:smart"
M.DEFAULT_MAX_TOKENS = 3000

local SYSTEM_PROMPT = table.concat({
    "You are a senior code reviewer asked to break a too-large change cluster",
    "into 2-4 cohesive sub-clusters that could each ship as their own PR.",
    "",
    "RULES:",
    "- Aim for 2-4 sub-clusters. Never fewer than 2, never more than 4.",
    "- Each sub-cluster represents ONE logical unit of work (one fix, one feature).",
    "- Group by intent (the *why*), not by namespace or extension.",
    "- Every input change_id must belong to exactly one sub-cluster.",
    "- Title: 2-5 words, Title Case, plain English.",
    "- plain_summary: one sentence in plain English.",
    "",
    "OUTPUT: a single JSON object, no prose, no markdown fences. Shape:",
    '{"groups":[{"title":"…","plain_summary":"…","change_ids":["..."]}]}',
}, "\n")

local function build_user_prompt(cluster)
    local lines = {
        "Source cluster: " .. (cluster.title or "?"),
        "Source summary: " .. (cluster.plain_summary or "?"),
        "Total files: " .. tostring(#(cluster.changes or {})),
        "",
        "Files (change_id | op | path):",
    }
    local n = math.min(#(cluster.changes or {}), 80)
    for i = 1, n do
        local ch = cluster.changes[i]
        table.insert(lines, string.format("  %s | %s | %s",
            ch.change_id, ch.op, ch.path or "?"))
    end
    if #(cluster.changes or {}) > n then
        table.insert(lines, string.format("  ... %d more files (omitted; cluster too large to list in full)",
            #cluster.changes - n))
    end
    table.insert(lines, "")
    table.insert(lines, "Propose 2-4 sub-clusters now.")
    return table.concat(lines, "\n")
end

local PARSE_OPTS = {
    root_key         = "groups",
    fallback_title   = "Remaining",
    fallback_summary = "Files the suggester did not place in a named group",
}

function M.run(cluster, opts)
    opts = opts or {}
    if not cluster then return { ok = false, error = "cluster required" } end
    local count = #(cluster.changes or {})
    if count == 0 then return { ok = false, error = "cluster has no changes" } end

    local p = prompt.new()
    p:add_system(SYSTEM_PROMPT)
    p:add_user(build_user_prompt(cluster))

    local model = opts.model or M.DEFAULT_MODEL
    local started_ns = time.now():unix_nano()

    local resp, err = llm.generate(p, {
        model      = model,
        max_tokens = opts.max_tokens or M.DEFAULT_MAX_TOKENS,
    })
    local duration_ms = math.floor((time.now():unix_nano() - started_ns) / 1e6)

    if err or not resp or not resp.result or resp.result == "" then
        log:warn("suggest_split llm failed", { error = tostring(err or "empty") })
        return { ok = false, error = "llm: " .. tostring(err or "empty") }
    end

    local decoded, perr = llm_groups.parse(resp.result, PARSE_OPTS)
    if perr then
        log:warn("suggest_split json parse failed", { error = perr })
        return { ok = false, error = perr }
    end

    local valid_ids = {}
    for _, ch in ipairs(cluster.changes or {}) do
        table.insert(valid_ids, ch.change_id)
    end
    local groups, verr = llm_groups.validate(decoded, valid_ids, PARSE_OPTS)
    if verr then return { ok = false, error = verr } end

    return {
        ok          = true,
        groups      = groups,
        model       = model,
        duration_ms = duration_ms,
    }
end

M._build_user_prompt = build_user_prompt

return M
