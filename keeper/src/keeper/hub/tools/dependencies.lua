local security = require("security")
local audit = require("audit")
local hub_service = require("hub_service")
local helpers = require("helpers")
local planner = require("planner")

local M = {}

type HandleDeps = {
    actor_id: string?,
    hub_service: unknown?,
    planner: unknown?,
}

function M._handle(input: unknown?, deps: HandleDeps?)
    deps = deps or {}
    input = input or {}
    local args_input = input :: any
    local action = args_input.action or "list"
    local svc = (deps.hub_service or hub_service) :: any
    local plan = (deps.planner or planner) :: any
    local args = helpers.copy_args(args_input)

    if action == "list" then
        return svc.list_dependencies(args)
    elseif action == "plan" then
        return plan.plan_install(args)
    elseif action == "install" then
        if not deps.actor_id or deps.actor_id == "" then
            return nil, "actor_id is required"
        end
        return svc.install(args, { actor_id = deps.actor_id })
    elseif action == "uninstall" then
        if not deps.actor_id or deps.actor_id == "" then
            return nil, "actor_id is required"
        end
        return svc.uninstall(args, { actor_id = deps.actor_id })
    end

    return nil, "unknown Hub dependency action: " .. tostring(action)
end

local function handler(input)
    input = input or {}
    return audit.wrap({
        tool = "hub_dependencies",
        discriminator = "hub_dependencies." .. tostring(input.action or "list"),
        target = input.component or input.id,
        params = {
            action = input.action,
            component = input.component,
            id = input.id,
            version = input.version,
            dry_run = input.dry_run,
            migration_policy = input.migration_policy,
        },
        summarise = function(result, err)
            if err then return "hub dependency operation failed" end
            if type(result) ~= "table" then return "hub dependency operation" end
            if input.action == "list" then
                return "listed " .. tostring(result.count or 0) .. " Hub dependencies"
            elseif input.action == "plan" then
                return "planned " .. tostring(result.module_count or 0) .. " Hub modules"
            elseif input.action == "install" then
                return "installed Hub dependency " .. tostring(result.dependency and result.dependency.component or input.component)
            elseif input.action == "uninstall" then
                return "uninstalled Hub dependency " .. tostring(result.dependency and result.dependency.component or input.component or input.id)
            end
            return "hub dependency operation"
        end,
    }, function()
        local action = input.action or "list"
        local actor_id, actor_err
        if action == "install" or action == "uninstall" then
            actor_id, actor_err = helpers.current_actor_id(security)
            if not actor_id then return nil, actor_err end
        end

        local result, err = M._handle(input, { actor_id = actor_id })
        if not result then return nil, helpers.service_error(err, "Hub operation failed") end
        return result, nil
    end)
end

return { handler = handler, _handle = M._handle }
