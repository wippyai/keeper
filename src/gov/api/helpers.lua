local registry = require("registry")
local gov_client = require("gov_client")
local sys_cs = require("sys_cs")

local M = {}

local function snapshot_entries()
    local snapshot, err = registry.snapshot()
    if not snapshot then
        return nil, "registry.snapshot failed: " .. tostring(err)
    end
    return snapshot:entries()
end

-- Apply a target registry version via the governance client, then journal
-- the entry-level diff (before → after) with source=version_revert.
--
-- Returns:
--   { ok = true, journaled = N }, nil           — applied and journaled
--   { ok = true, journaled = 0 }, "delta_err"   — applied, journal best-effort failed
--   nil, "err"                                   — apply failed; nothing persisted
function M.apply_version_with_journal(target_version_id, timeout)
    local before_entries, snap_err = snapshot_entries()
    if not before_entries then
        return nil, snap_err
    end

    local success, apply_err = gov_client.request_version(target_version_id, {}, timeout or "90s")
    if not success then
        return nil, apply_err or "version application failed"
    end

    local after_entries, after_err = snapshot_entries()
    if not after_entries then
        return { ok = true, journaled = 0 }, after_err
    end

    local changeset, delta_err = registry.build_delta(before_entries, after_entries)
    if not changeset then
        return { ok = true, journaled = 0 }, delta_err
    end

    local diff_resp = sys_cs.record_version_revert(changeset)
    local journaled = (diff_resp and diff_resp.ok and diff_resp.rows_written) or 0
    return { ok = true, journaled = journaled }, nil
end

return M
