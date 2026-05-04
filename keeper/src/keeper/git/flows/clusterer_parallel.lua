-- Parallel AI clustering for arbitrarily large change sets.
--
-- Partitions changes by 2nd-level path prefix; oversized buckets recurse to
-- depth+1 (cap depth=5). Fires one clusterer.run per bucket via coroutine,
-- gathers results within a hard timeout. On bucket failure or timeout, the
-- bucket's files are preserved in a fallback cluster so no input is lost.

local channel = require("channel")
local logger = require("logger")
local time = require("time")
local clusterer = require("clusterer")
local consts = require("git_consts")

local log = logger:named("keeper.git.clusterer_parallel")

local M = {}

type SelectResult = {
    ok?: boolean,
    channel?: unknown,
    value?: unknown,
}

type BucketMessage = {
    idx?: integer,
    key: string,
    count: integer,
    result?: {
        ok?: boolean,
        clusters?: {[integer]: {[string]: unknown}},
        duration_ms?: integer,
        error?: string,
    },
}

-- Bucket size below which we skip parallelism and call clusterer once —
-- a single coherent prompt produces better grouping than slicing small inputs.
M.SOFT_LIMIT = 250
-- Hard ceiling per bucket so a runaway LLM call can't hang the whole rebuild.
M.BUCKET_TIMEOUT_SEC = 90
M.DEFAULT_MAX_PARALLEL = consts.DEFAULT_CLUSTER_MAX_PARALLEL

local function effective_max_parallel(value, bucket_count)
    local n = tonumber(value or M.DEFAULT_MAX_PARALLEL) or M.DEFAULT_MAX_PARALLEL
    n = math.floor(n)
    if n < 1 then n = 1 end
    if bucket_count and bucket_count > 0 and n > bucket_count then n = bucket_count end
    return n
end

local function path_prefix(path, depth)
    local parts = {}
    for seg in (path or ""):gmatch("[^/]+") do
        table.insert(parts, seg)
        if #parts >= depth then break end
    end
    if #parts == 0 then return "root/" end
    return table.concat(parts, "/") .. "/"
end

local function partition(changes, depth, max_depth)
    depth = depth or 2
    max_depth = max_depth or 5

    local buckets = {}
    for _, ch in ipairs(changes) do
        local key = path_prefix(ch.target or ch.path, depth)
        buckets[key] = buckets[key] or { key = key, items = {} }
        table.insert(buckets[key].items, ch)
    end

    local out = {}
    for _, b in pairs(buckets) do
        if #b.items <= M.SOFT_LIMIT or depth >= max_depth then
            table.insert(out, b)
        else
            for _, sub in ipairs(partition(b.items, depth + 1, max_depth)) do
                table.insert(out, sub)
            end
        end
    end
    return out
end

local function bucket_change_ids(bucket)
    local ids = {}
    for _, ch in ipairs(bucket.items) do table.insert(ids, ch.change_id) end
    return ids
end

local function fallback_cluster(bucket, suffix, reason)
    return {
        title         = bucket.key:gsub("/$", "") .. " (" .. suffix .. ")",
        plain_summary = string.format("%d files in %s — %s", #bucket.items, bucket.key, reason),
        change_ids    = bucket_change_ids(bucket),
    }
end

function M.run(changes, opts)
    opts = opts or {}
    if not changes or #changes == 0 then
        return { ok = true, clusters = {}, model = nil, duration_ms = 0 }
    end

    local started_ns = time.now():unix_nano()

    -- Small inputs: one cohesive call beats parallel slicing.
    if #changes <= M.SOFT_LIMIT then
        local single = clusterer.run(changes, opts)
        single.duration_ms = math.floor((time.now():unix_nano() - started_ns) / 1e6)
        single.bucket_results = {{ key = "all", count = #changes, ok = single.ok, error = single.error }}
        return single
    end

    local buckets = partition(changes)
    log:info("parallel clustering buckets", {
        bucket_count = #buckets, total_changes = #changes,
    })

    local done = channel.new(#buckets)
    local next_bucket = 1
    local worker_count = effective_max_parallel(opts.max_parallel or opts.cluster_max_parallel, #buckets)

    -- Start a bounded worker pool instead of one coroutine per bucket. The
    -- clusterer call may be an expensive model request; on large repos this cap
    -- turns the path partitioner into backpressure rather than fan-out.
    for _ = 1, worker_count do
        coroutine.spawn(function()
            while true do
                local idx = next_bucket
                next_bucket = next_bucket + 1
                local b = buckets[idx]
                if not b then return end
                local res = clusterer.run(b.items, opts)
                done:send({ idx = idx, key = b.key, count = #b.items, result = res })
            end
        end)
    end

    local timeout_ch = time.after(M.BUCKET_TIMEOUT_SEC .. "s")
    local all_clusters = {}
    local bucket_results = {}
    local fail_count = 0
    local received = 0

    while received < #buckets do
        local result = channel.select({
            done:case_receive(),
            timeout_ch:case_receive(),
        }) :: SelectResult

        if not result.ok or result.channel == timeout_ch then
            -- Synthesize fallback clusters for buckets that haven't reported.
            local reported = {}
            for _, br in ipairs(bucket_results) do reported[br.key] = true end
            for _, b in ipairs(buckets) do
                if not reported[b.key] then
                    fail_count = fail_count + 1
                    table.insert(bucket_results, {
                        key = b.key, count = #b.items,
                        ok = false, error = "timed out after " .. M.BUCKET_TIMEOUT_SEC .. "s",
                    })
                    table.insert(all_clusters, fallback_cluster(b, "timed out",
                        "AI clustering timed out, kept as a single bucket."))
                end
            end
            log:warn("parallel clustering partial timeout", {
                completed = received, missing = #buckets - received,
            })
            break
        end

        local msg = result.value :: BucketMessage?
        received = received + 1
        local r = msg and msg.result
        if not r then
            fail_count = fail_count + 1
            table.insert(bucket_results, { key = msg and msg.key or "?", count = 0, ok = false, error = "empty result" })
        elseif msg and r.ok and r.clusters then
            table.insert(bucket_results, {
                key = msg.key, count = msg.count, ok = true, duration_ms = r.duration_ms,
            })
            -- Prefix the title with the bucket so similar topic names from
            -- different buckets remain distinguishable in the FE list.
            local prefix = msg.key:gsub("/$", "")
            for _, c in ipairs(r.clusters) do
                if c.title:sub(1, #prefix) ~= prefix then
                    c.title = prefix .. ": " .. c.title
                end
                table.insert(all_clusters, c)
            end
        else
            fail_count = fail_count + 1
            table.insert(bucket_results, {
                key = msg.key, count = msg.count, ok = false, error = r.error,
                duration_ms = r.duration_ms,
            })
            local bucket = nil
            for _, b in ipairs(buckets) do if b.key == msg.key then bucket = b; break end end
            if bucket then
                table.insert(all_clusters, fallback_cluster(bucket, "uncategorized",
                    "AI clustering failed (" .. tostring(r.error or "unknown") .. "); kept as one bucket."))
            end
            log:warn("bucket clustering failed", { key = msg.key, error = r.error })
        end
    end

    local duration_ms = math.floor((time.now():unix_nano() - started_ns) / 1e6)
    log:info("parallel clustering done", {
        bucket_count = #buckets, fail_count = fail_count,
        cluster_count = #all_clusters, duration_ms = duration_ms,
        worker_count = worker_count,
    })

    if fail_count == #buckets then
        return {
            ok = false,
            error = "all buckets failed: " .. (bucket_results[1] and bucket_results[1].error or "unknown"),
            duration_ms = duration_ms,
            bucket_results = bucket_results,
        }
    end

    return {
        ok             = true,
        clusters       = all_clusters,
        model          = opts.model or clusterer.DEFAULT_MODEL,
        duration_ms    = duration_ms,
        bucket_results = bucket_results,
        partial        = fail_count > 0,
        worker_count   = worker_count,
    }
end

M._partition   = partition
M._path_prefix = path_prefix
M._effective_max_parallel = effective_max_parallel

return M
