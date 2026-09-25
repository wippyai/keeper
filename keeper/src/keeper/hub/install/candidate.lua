local hash = require("hash")

local M = {}

local ERROR_KIND = {
    BAD_REQUEST = errors.INVALID,
    CANDIDATE_INVALID = errors.INVALID,
    NOT_FOUND = errors.NOT_FOUND,
    CONFLICT = errors.CONFLICT,
    CANDIDATE_HASH_MISMATCH = errors.CONFLICT,
    CANDIDATE_UNAVAILABLE = errors.UNAVAILABLE,
    INSTALLED_CLOSURE_UNAVAILABLE = errors.UNAVAILABLE,
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

local function trim(value)
    return type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
end

-- Reopen each exact version selected by the planner. Read the digest from the
-- opened package: planner.inspect_artifact may fall back to the selected digest
-- when the package has none, which cannot prove what was staged.
function M.stage(planner, graph)
    if not planner or type(planner.new) ~= "function" then
        return nil, failure("CANDIDATE_UNAVAILABLE", "candidate planner unavailable")
    end
    local instance = planner.new()
    local versions = instance and instance.catalog and instance.catalog.versions
    if not versions or type(versions.open) ~= "function" then
        return nil, failure("CANDIDATE_UNAVAILABLE", "artifact open unavailable")
    end
    local closure, identity = {}, {}
    for _, node in ipairs(graph or {}) do
        local selected = node.__selected or { version = node.version, id = node.version_id }
        local ref
        if trim(selected.version) ~= "" then
            ref = { version = selected.version }
        elseif trim(selected.id) ~= "" then
            ref = { id = selected.id }
        else
            return nil, failure("CANDIDATE_UNAVAILABLE", "selected version missing for " .. tostring(node.module))
        end
        local artifact, artifact_err = versions.open(node.module, ref)
        if not artifact then
            return nil, failure("CANDIDATE_UNAVAILABLE", "cannot stage " .. tostring(node.module), artifact_err)
        end
        if type(artifact.close) ~= "function" then
            return nil, failure("CANDIDATE_UNAVAILABLE", "staged artifact has no close method")
        end
        local actual = trim(artifact.digest)
        local entries, entries_err
        if type(artifact.entries) == "function" then
            entries, entries_err = artifact:entries({ include_data = true })
        end
        local closed, close_err = artifact:close()
        if close_err or closed == false then
            return nil, failure("CANDIDATE_UNAVAILABLE", "cannot close staged artifact " .. tostring(node.module), close_err)
        end
        if type(entries) ~= "table" or entries_err then
            return nil, failure("CANDIDATE_UNAVAILABLE", "staged entry list unavailable for " .. tostring(node.module), entries_err)
        end
        local expected = trim(node.digest)
        if expected == "" or actual == "" or expected ~= actual then
            return nil, failure("CANDIDATE_HASH_MISMATCH", "staged artifact digest differs from plan", {
                module = node.module, expected = expected, actual = actual,
            })
        end
        local metadata = selected.metadata or {}
        local floor = trim(metadata.min_wippy_version or metadata.min_runtime or selected.min_runtime)
        local migrations = {}
        for _, entry in ipairs(entries) do
            if entry.meta and entry.meta.type == "migration" then
                if trim(entry.id) == "" or trim(entry.meta.target_db) == "" then
                    return nil, failure("CANDIDATE_INVALID", "migration lacks id or target DB")
                end
                migrations[#migrations + 1] = entry
            end
        end
        table.sort(migrations, function(a, b) return a.id < b.id end)
        closure[#closure + 1] = {
            module = node.module, version = node.version, hash = actual,
            min_runtime = floor, entries = entries, migrations = migrations,
        }
        identity[#identity + 1] = tostring(node.module) .. "\0" .. tostring(node.version)
            .. "\0" .. actual
    end
    table.sort(closure, function(a, b) return a.module < b.module end)
    table.sort(identity)
    local candidate_hash, hash_err = hash.sha256(table.concat(identity, "\n"))
    if not candidate_hash then return nil, failure("CANDIDATE_HASH_FAILED", tostring(hash_err)) end
    return { closure = closure, hash = candidate_hash }, nil
end

function M.installed(registry)
    if not registry or type(registry.snapshot) ~= "function" then
        return nil, failure("INSTALLED_CLOSURE_UNAVAILABLE", "registry snapshot unavailable")
    end
    local snapshot, snapshot_err = registry.snapshot()
    if not snapshot or snapshot_err or type(snapshot.state) ~= "function" then
        return nil, failure("INSTALLED_CLOSURE_UNAVAILABLE", "registry state unavailable", snapshot_err)
    end
    local state, state_err = snapshot:state()
    if not state or state_err or not state.resolution or type(state.resolution.modules) ~= "table" then
        return nil, failure("INSTALLED_CLOSURE_UNAVAILABLE", "resolved module inventory unavailable", state_err)
    end
    local artifacts = {}
    for _, module in ipairs(state.resolution.modules) do
        local digest = trim(module.digest)
        if digest == "" then
            return nil, failure("UNKNOWN_HASH", "installed module lacks exact digest", module.name)
        end
        artifacts[#artifacts + 1] = {
            name = module.name, version = module.version, hash = digest,
        }
    end
    return artifacts, nil
end

return M
