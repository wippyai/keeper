local security = require("security")
local audit = require("audit")
local hub_service = require("hub_service")
local helpers = require("helpers")

local M = {}

type HandleDeps = {
    actor_id: string?,
    hub_service: unknown?,
}

function M._handle(input: unknown?, deps: HandleDeps?)
    deps = deps or {}
    input = input or {}
    local args_input = input :: any
    local action = args_input.action or "list"
    local svc = (deps.hub_service or hub_service) :: any
    local args = helpers.copy_args(args_input)

    if action == "list" then
        return svc.list_migrations(args)
    elseif action == "run" then
        if not deps.actor_id or deps.actor_id == "" then
            return nil, "actor_id is required"
        end
        return svc.run_migrations(args, { actor_id = deps.actor_id })
    end

    return nil, "unknown Hub migration action: " .. tostring(action)
end

local function handler(input)
    input = input or {}
    return audit.wrap({
        tool = "hub_migrations",
        discriminator = "hub_migrations." .. tostring(input.action or "list"),
        target = input.component,
        params = {
            action = input.action,
            component = input.component,
            entry_ids = input.entry_ids,
            operation = input.operation,
            dry_run = input.dry_run,
        },
        summarise = function(result, err)
            if err then return "hub migration operation failed" end
            if type(result) ~= "table" then return "hub migration operation" end
            if input.action == "run" then
                return "selected " .. tostring(result.count or 0) .. " Hub migrations for " .. tostring(result.operation or input.operation or "up")
            end
            return "listed " .. tostring(result.count or 0) .. " Hub migrations"
        end,
    }, function()
        local actor_id, actor_err
        if (input.action or "list") == "run" then
            actor_id, actor_err = helpers.current_actor_id(security)
            if not actor_id then return nil, actor_err end
        end

        local result, err = M._handle(input, { actor_id = actor_id })
        if not result then return nil, helpers.service_error(err, "Hub migration operation failed") end
        return result, nil
    end)
end

return { handler = handler, _handle = M._handle }
