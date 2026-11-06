local process = require("process")
local security = require("security")
local time = require("time")

local M = {}

local function report(args, step)
    process.send(args.observer, args.topic, step)
end

function M.install(args, opts)
    local started = args.dry_run == true and "dry_run" or "apply_started"
    report(args, started)
    time.sleep(args.apply_for or "1ms")
    report(args, "apply_done")
    report(args, "migrations")
    report(args, "bootloaders")
    if args.fail then
        return nil, errors.new({
            kind = errors.INTERNAL,
            message = "migrations failed",
            details = { code = "MIGRATIONS_FAILED", baseline_version = 7 },
        })
    end
    local actor = security.actor()
    return {
        operation_id = "op-1",
        warnings = {},
        actor_option = opts.actor_id,
        actor = actor and actor:id(),
        can_report = security.can("process.send", args.observer),
    }, nil
end

return M
