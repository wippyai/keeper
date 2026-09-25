local M = {}

local ERROR_KIND = {
    CANDIDATE_UNAVAILABLE = errors.UNAVAILABLE,
}

local function failure(code, message, info)
    local details = { code = code }
    if type(info) == "table" then
        for key, value in pairs(info) do details[key] = value end
    elseif info ~= nil then
        details.cause = tostring(info)
    end
    return errors.new({ kind = ERROR_KIND[code] or errors.INTERNAL,
        message = message, details = details })
end

local function is_migration(entry)
    return type(entry) == "table" and type(entry.meta) == "table"
        and entry.meta.type == "migration"
end

-- Execution order through the real runner is the resolver's return order, so
-- this mirrors wippy.migration:registry.compare exactly: ascending
-- tostring(meta.timestamp or "") with the full id as deterministic
-- tie-breaker (framework src/migration/registry.lua migration_timestamp).
-- An id-only sort would run timestamped migrations out of sequence.
local function staged_timestamp(entry)
    local meta = entry and entry.meta
    if type(meta) ~= "table" or meta.timestamp == nil then return "" end
    return tostring(meta.timestamp)
end

local function staged_compare(a, b)
    local a_time, b_time = staged_timestamp(a), staged_timestamp(b)
    if a_time ~= b_time then return a_time < b_time end
    return tostring(a and a.id or "") < tostring(b and b.id or "")
end

local function staged_of(artifact)
    if type(artifact) ~= "table" then return {} end
    if type(artifact.migrations) == "table" then return artifact.migrations end
    local collected = {}
    for _, entry in ipairs(artifact.entries or {}) do
        if is_migration(entry) then collected[#collected + 1] = entry end
    end
    return collected
end

-- Production staged-closure resolver for the framework candidate runner.
--
-- Authority: CONTRACTS §19 (the resolver only exposes the staged immutable
-- closure); FINAL-DESIGN-v4 §12.1 P0 step 2 (candidate_migrations_up runs
-- against migration entries in the staged closure through an isolated
-- migration-only resolver).
--
-- The resolver closes over the digest-verified staged candidate closure the
-- installer merged for this install and returns those exact entry tables, so
-- the bytes the runner executes are the bytes that will be published. Keeper
-- refuses duplicate ids with differing content in staged_migrations before
-- the runner is called, so no filtering here can hide a divergence.
function M.for_closure(closure)
    if type(closure) ~= "table" then
        return nil, failure("CANDIDATE_UNAVAILABLE", "staged candidate closure required")
    end
    local resolver = { closure = closure }

    function resolver:find(options)
        local target = type(options) == "table" and options.target_db or nil
        local collected = {}
        for _, artifact in ipairs(self.closure) do
            for _, entry in ipairs(staged_of(artifact)) do
                if is_migration(entry)
                    and (target == nil or entry.meta.target_db == target) then
                    collected[#collected + 1] = entry
                end
            end
        end
        table.sort(collected, staged_compare)
        return collected, nil
    end

    return resolver, nil
end

return M
