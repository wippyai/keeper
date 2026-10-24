-- SPDX-License-Identifier: MPL-2.0
-- Bound recovery to a complete read-only Hub plan. The caller creates a fresh
-- planner for every attempt, including its ownership and requirement caches.
local M = {}

type Refusal = {error: error}
type Attempt = () -> (any?, any?, Refusal?)

function M.refusal(err: any, snapshot: any): Refusal?
    if type(err) ~= "userdata" or not errors.is(err, errors.CONFLICT) or err:retryable() ~= true then return nil end
    local details = err:details()
    if type(details) ~= "table" or type(details.plan_version) ~= "number"
        or type(details.current_version) ~= "number"
        or details.current_version <= details.plan_version then return nil end
    local version = snapshot:version():id()
    if details.plan_version ~= version then return nil end
    return {error = err}
end

function M.run(attempt: Attempt): (any?, any?)
    local result, err, refused = attempt()
    if err and refused and refused.error == err then
        -- Only the native refusal recorded by this attempt permits recovery.
        -- A second error is returned unchanged; only read-only planning enters here.
        result, err = attempt()
    end
    return result, err
end

return M
