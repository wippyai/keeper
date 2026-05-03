-- Single LLM call grouping changes into topical clusters. The parallel
-- runner partitions oversized inputs and calls this per bucket.

local llm = require("llm")
local prompt = require("prompt")
local logger = require("logger")
local time = require("time")
local llm_groups = require("llm_groups")

local log = logger:named("keeper.git.clusterer")

local M = {}

M.DEFAULT_MODEL = "class:smart"
M.DEFAULT_MAX_TOKENS = 16000
-- Per-call ceiling. Above this we ask callers to partition first.
M.PER_CALL_LIMIT = 250

local SYSTEM_PROMPT = table.concat({
    "You are a code review assistant that groups unstaged changes into topical clusters",
    "for human review. Each cluster represents one logical unit of work that should",
    "ship as a single PR.",
    "",
    "RULES:",
    "- Group by topic intent (the *why*) not by namespace or file extension.",
    "- Every input change must belong to exactly one cluster.",
    "- A cluster title is 2-5 words, Title Case, plain English (e.g. 'Audit Trail Fix',",
    "  'State Patch Engine', 'Cancel Button UI').",
    "- A plain_summary is one sentence in plain English explaining what the cluster does",
    "  and why a reader should care. Avoid jargon and namespace IDs.",
    "- Aim for clusters of 5-25 changes. Avoid singletons unless truly standalone.",
    "- Tightly cohesive small clusters beat large catch-all clusters.",
    "",
    "OUTPUT: a single JSON object, no prose, no markdown fences. Shape:",
    '{"clusters":[{"title":"…","plain_summary":"…","change_ids":["id1","id2",…]}]}',
}, "\n")

local function build_user_prompt(changes)
    local lines = { "Here are " .. #changes .. " unstaged changes to cluster.",
                    "Each line is: change_id | op | category | target",
                    "" }
    for _, ch in ipairs(changes) do
        table.insert(lines, string.format("%s | %s | %s | %s",
            ch.change_id, ch.op, ch.category, ch.target))
    end
    table.insert(lines, "")
    table.insert(lines, "Respond with the JSON object only.")
    return table.concat(lines, "\n")
end

local PARSE_OPTS = {
    root_key         = "clusters",
    fallback_title   = "Misc",
    fallback_summary = "Changes the clusterer didn't fit into a named topic.",
}

-- Cluster `changes` (orphans already peeled off) into topic groups.
-- Returns { ok=true, clusters={…} } or { ok=false, error="…" }.
function M.run(changes, opts)
    opts = opts or {}
    if not changes or #changes == 0 then
        return { ok = true, clusters = {}, model = nil, duration_ms = 0 }
    end

    local max_in = opts.max_input or M.PER_CALL_LIMIT
    if #changes > max_in then
        return {
            ok = false,
            error = string.format(
                "single-call limit exceeded: %d files (max %d). Use clusterer_parallel.",
                #changes, max_in),
        }
    end

    local p = prompt.new()
    p:add_system(SYSTEM_PROMPT)
    p:add_user(build_user_prompt(changes))

    local model = opts.model or M.DEFAULT_MODEL
    local started_ns = time.now():unix_nano()

    local resp, err = llm.generate(p, {
        model      = model,
        max_tokens = opts.max_tokens or M.DEFAULT_MAX_TOKENS,
    })

    local duration_ms = math.floor((time.now():unix_nano() - started_ns) / 1e6)

    if err or not resp or not resp.result or resp.result == "" then
        log:warn("clusterer llm failed", {
            model = model, duration_ms = duration_ms,
            error = tostring(err or "empty"),
        })
        return { ok = false, error = "llm: " .. tostring(err or "empty response"),
                 model = model, duration_ms = duration_ms }
    end

    local decoded, perr = llm_groups.parse(resp.result, PARSE_OPTS)
    if perr then
        log:warn("clusterer json parse failed", { error = perr, sample = resp.result:sub(1, 200) })
        return { ok = false, error = perr, model = model, duration_ms = duration_ms }
    end

    local expected_ids = {}
    for _, ch in ipairs(changes) do table.insert(expected_ids, ch.change_id) end

    local clusters, verr = llm_groups.validate(decoded, expected_ids, PARSE_OPTS)
    if verr then
        return { ok = false, error = verr, model = model, duration_ms = duration_ms }
    end

    log:info("clusterer ok", {
        model = model, duration_ms = duration_ms,
        cluster_count = #clusters, change_count = #changes,
    })

    return {
        ok = true,
        clusters = clusters,
        model = model,
        duration_ms = duration_ms,
        usage = rawget(resp, "usage"),
    }
end

M._build_user_prompt = build_user_prompt

return M
