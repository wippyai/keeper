-- Live-service upgrade coordinator. Given the set of process source entries that
-- changed in a registry changeset, finds the long-running process.service entries
-- that run them and that opted in to live upgrade (meta.upgradable == true), and
-- signals each running instance with a well-shaped upgrade event so it can call
-- process.upgrade and hot-swap to the new code without a restart.
--
-- Signalling is best-effort: the new code already lives in the registry and any
-- fresh spawn picks it up via the re-registered factory. A failed or skipped
-- signal therefore never gates the install; it is reported per service.

local registry = require("registry")

local M = {}

M.SERVICE_KIND = "process.service"
M.DEFAULT_TOPIC = "system.upgrade"
M.REASON = "module.update"
M.DEFAULT_DEADLINE = "30s"

-- The upgrade event payload contract sent to a running service.
local function build_event(process_id: string, version: any): table
    return {
        reason = M.REASON,
        process = process_id,
        version = version,
        deadline = M.DEFAULT_DEADLINE,
    }
end

-- find_targets returns the upgradable services whose backing process is in
-- changed_set. Pure with respect to messaging (only reads the registry), so it
-- is unit-testable without any running process.
function M.find_targets(changed_set: table): table
    local out = {}

    local svcs, err = registry.find({ [".kind"] = M.SERVICE_KIND })
    if err or not svcs then
        return out
    end

    for _, s in ipairs(svcs) do
        local meta = s.meta or {}
        local data = s.data or {}
        local process_id = data.process and tostring(data.process) or nil

        if meta.upgradable == true and process_id and changed_set[process_id] then
            out[#out + 1] = {
                service_id = tostring(s.id),
                process_id = process_id,
                target = meta.upgrade_target,
                topic = meta.upgrade_topic or M.DEFAULT_TOPIC,
            }
        end
    end

    return out
end

-- signal delivers the upgrade event to one target's running instance.
local function signal(target: table, version: any): (boolean, string?)
    local name = target.target
    if type(name) ~= "string" then
        return false, "service " .. tostring(target.service_id) ..
            " is upgradable but declares no meta.upgrade_target"
    end

    local topic = target.topic
    if type(topic) ~= "string" then
        topic = M.DEFAULT_TOPIC
    end

    local process_id = tostring(target.process_id)

    local existing, lookup_err = process.registry.lookup(name)
    if not existing then
        return false, "no running instance registered as '" .. name .. "'" ..
            (lookup_err and (": " .. tostring(lookup_err)) or "")
    end

    local ok, send_err = process.send(name, topic, build_event(process_id, version))
    if not ok then
        return false, send_err and tostring(send_err) or "process.send returned false"
    end

    return true, nil
end

-- run signals every upgradable service backed by one of changed_ids and returns
-- one result row per service: { service_id, process_id, target, topic, signaled, error }.
function M.run(changed_ids: table, version: any): table
    local changed_set = {}
    for _, id in ipairs(changed_ids) do
        changed_set[tostring(id)] = true
    end

    local rows = {}
    for _, t in ipairs(M.find_targets(changed_set)) do
        local ok, err = signal(t, version)
        rows[#rows + 1] = {
            service_id = t.service_id,
            process_id = t.process_id,
            target = t.target,
            topic = t.topic,
            signaled = ok,
            error = ok and nil or err,
        }
    end

    return rows
end

return M
