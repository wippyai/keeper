-- keeper.components.ui:replay
--
-- Calls into the Playwright runner container. A container respawned after an
-- idle kill replays the last successful open, so the session and current page
-- survive; a session whose admin token was minted by the supervisor gets a
-- fresh token once it is older than refresh_after_s.
--
-- new(deps) takes:
--   spawn(state) -> ok, err                       start the runner container
--   send(state, op, args, timeout_s) -> msg, err  one runner request
--   mint() -> token, err                          admin session token
--   base_url() -> url, err                        host origin
--   storage_state(origin, token) -> table         session storage for origin
--   now() -> seconds
--   refresh_after_s                               minted token lifetime on replay
--   log                                           named logger

local M = {}

function M.new(deps)
    local self = {}

    -- Rebuild storage_state with a freshly minted admin token. Caller-provided
    -- tokens are never refreshed; the caller owns them.
    function self.refresh(last_open)
        if not last_open or last_open.token_source ~= "minted" then return last_open end
        local age = deps.now() - (last_open.minted_at or 0)
        if age < deps.refresh_after_s then return last_open end
        local token, err = deps.mint()
        if not token then
            deps.log:warn("token refresh skipped, mint failed", { error = err })
            return last_open
        end
        local origin = last_open.origin
        if not origin or origin == "" then
            local base, base_err = deps.base_url()
            if not base then
                deps.log:warn("token refresh skipped, host URL unavailable", { error = base_err })
                return last_open
            end
            origin = base
        end
        last_open.storage_state = deps.storage_state(origin, token)
        last_open.minted_at = deps.now()
        deps.log:info("refreshed minted token on replay", { age_s = age })
        return last_open
    end

    function self.call(state, op, args, timeout_s)
        local authenticated_goto = op == "goto" and args and args.storage_state
        local previous = state.last_open
        -- These operations replace or discard the saved session, even when
        -- navigation fails after the browser has already switched contexts.
        if authenticated_goto or op == "open" or op == "close" then
            state.last_open = nil
        end
        if op == "close" and not state.proc then
            state.next_id = state.next_id + 1
            return { id = state.next_id, ok = true }
        end
        local fresh = false
        if not state.proc then
            local ok, err = deps.spawn(state)
            if not ok then return nil, err end
            fresh = true
        end
        if fresh and state.last_open then
            deps.log:info("replaying last open on fresh container")
            state.last_open = self.refresh(state.last_open)
            local replayed, rerr = deps.send(state, "open", state.last_open, 60)
            if not replayed or not replayed.ok then
                deps.log:warn("open replay failed", { error = rerr or (replayed and replayed.error) })
                state.last_open = nil
                return nil, rerr or (replayed and replayed.error) or "open replay failed"
            end
        end
        if fresh and authenticated_goto and previous then
            args.viewport = previous.viewport
            args.color_scheme = previous.color_scheme
        end
        local response, err = deps.send(state, op, args, timeout_s)
        if response and response.ok then
            if op == "open" then
                args.minted_at = deps.now()
                state.last_open = args
            elseif authenticated_goto then
                state.last_open = {
                    start_url = args.url, origin = args.origin,
                    storage_state = args.storage_state, token_source = "caller",
                    wait_until = args.wait_until, goto_timeout = args.timeout,
                    viewport = previous and previous.viewport,
                    color_scheme = previous and previous.color_scheme,
                }
            elseif op == "goto" and state.last_open then
                state.last_open.start_url = args.url
                state.last_open.wait_until = args.wait_until
                state.last_open.goto_timeout = args.timeout
            end
        end
        return response, err
    end

    return self
end

return M
