local logger = require("logger")
local process = require("process")
local api_http = require("api_http")
local keeper_config = require("keeper_config")

local log = logger:named("keeper.hub.install")

local M = {}

M.WORKER = "keeper.hub.api:install_worker"

-- Held for the life of the worker and released by its exit, so a repeat that
-- arrives while an install is still finishing is rejected rather than interleaved.
M.LOCK_NAME = "keeper.hub.install"

-- Starts the install in its own process and writes the worker's response. A
-- client disconnect cancels the request and ends this function; the worker has
-- its own lifetime and finishes the install.
function M.respond(res, raw_body, opts, worker_id)
    local events = process.events()
    local worker, spawn_err = process.spawn_monitored(
        worker_id or M.WORKER, keeper_config.process_host(), raw_body, opts)
    if not worker then
        api_http.write_service_error(res, { code = "INTERNAL", message = "install worker: " .. tostring(spawn_err) })
        return
    end

    while true do
        local event = events:receive()
        if event and event.kind == process.event.EXIT and event.from == worker then
            local response = event.result and event.result.value
            if response then
                api_http.write_encoded_response(res, response)
            else
                local reason = event.result and event.result.error or "no result"
                api_http.write_service_error(res, { code = "INTERNAL", message = "install worker: " .. tostring(reason) })
            end
            return
        end
    end
end

-- Runs in the worker. The returned response is the worker's exit result.
function M.serve(service, raw_body, opts)
    local args, body_err = api_http.decode_json_body(raw_body)
    if not args then
        return api_http.encoded_response(nil, { code = "BAD_REQUEST", message = body_err })
    end

    if args.dry_run ~= true then
        local locked, lock_err = process.registry.register(M.LOCK_NAME)
        if not locked then
            if errors.is(lock_err, errors.ALREADY_EXISTS) then
                return api_http.encoded_response(nil, {
                    code = "CONFLICT",
                    message = "another Hub install is still running",
                })
            end
            return api_http.encoded_response(nil, {
                code = "INTERNAL",
                message = "install lock: " .. tostring(lock_err),
            })
        end
    end

    local result, service_err = service.install(args, opts)
    if not result then
        log:error("Hub install failed", { error = tostring(service_err), actor_id = opts.actor_id })
    end
    return api_http.encoded_response(result, service_err)
end

return M
