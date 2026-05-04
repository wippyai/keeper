local M = {}

-- The Keeper module test host declares app:gateway on :19097 in keeper/test/_index.yaml.
-- API auth tests run without an actor/scope, so they must not depend on env.get().
local TEST_PUBLIC_API_URL = "http://localhost:19097"

function M.endpoint(path)
    return TEST_PUBLIC_API_URL .. path
end

return M
