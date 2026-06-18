-- Integration handler: after a changeset that updates process source code is
-- applied, signal every long-running, opted-in process.service so it can hot-swap
-- to the new code via process.upgrade (no restart, no redeploy).
--
-- handles kind ^process%.lua (process.lua and process.lua.bytecode). The matched
-- entry_ids are the process definitions whose code changed; the coordinator maps
-- them to the services that run them.
--
-- Signalling is best-effort and never fails the install: the new code is already
-- committed to the registry, so a not-running or unreachable service simply keeps
-- the old code until its next spawn. Each service's real outcome is in row.data.status.

local coordinator = require("coordinator")
local registry = require("registry")

local function string_list(value: unknown): {string}
    local out: {string} = {}
    if type(value) ~= "table" then
        return out
    end
    for _, item in ipairs(value) do
        if type(item) == "string" and item ~= "" then
            out[#out + 1] = item
        end
    end
    return out
end

local function current_version_id(): any
    local v, err = registry.current_version()
    if err or not v then
        return nil
    end
    return v:id()
end

local function handler(params: table): (table?, string?)
    local operation = params.operation or "up"
    local entry_ids = string_list(params.entry_ids)

    if operation == "down" then
        local rows = {}
        for _, id in ipairs(entry_ids) do
            rows[#rows + 1] = {
                id = id,
                success = true,
                data = { operation = "down", status = "noop" },
            }
        end
        return rows
    end

    if #entry_ids == 0 then
        return {}
    end

    local version = current_version_id()
    local rows = {}
    for _, r in ipairs(coordinator.run(entry_ids, version)) do
        rows[#rows + 1] = {
            id = r.service_id,
            success = true,
            data = {
                operation = "up",
                status = r.signaled and "signaled" or "skipped",
                process = r.process_id,
                target = r.target,
                topic = r.topic,
                version = version,
                detail = r.error,
            },
        }
    end

    return rows
end

return { handler = handler }
