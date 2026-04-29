-- keeper.state.publish:governance
--
-- Pure governance publisher. One call — changeset goes through the
-- governance pipeline (lint-gate + version bump + registry apply). No
-- migration, no test, no build — those are per-kind handlers owned by the
-- integrate runner. This is the primitive both the legacy push path and
-- the new integrate runner call.

local gov_client = require("gov_client")

local M = {}

-- Return the current registry version as reported by governance state.
-- Used by the integrate runner to snapshot a rollback target before
-- publishing.
function M.current_version()
    local state, err = gov_client.get_state()
    if err or not state or not state.registry then
        return nil, "gov_state: " .. tostring(err or "empty state")
    end
    return state.registry.current_version
end

-- Publish a changeset. Thin wrapper over gov_client.request_changes so
-- callers don't touch the governance transport directly. `options` is
-- forwarded verbatim (branch, base_branch, message, user_id, session_id,
-- request_hil, …).
function M.publish(changeset, options)
    if not changeset then return nil, "publish: changeset required" end
    return gov_client.request_changes(changeset, options or {})
end

-- Restore the registry to a previously captured version. Used by the
-- integrate / rollback runners when a downstream handler fails.
function M.restore_version(version_id, reason)
    if version_id == nil or version_id == "" then
        return nil, "restore_version: version_id required"
    end
    local num = tonumber(version_id)
    if not num then return nil, "restore_version: version_id must be numeric" end
    if num < 0 then return nil, "restore_version: version_id must be non-negative" end

    local options = { message = reason or "registry restored" }
    local result, err = gov_client.request_version(num, options)
    if err then return nil, "restore_version: " .. tostring(err) end
    return result
end

return M
