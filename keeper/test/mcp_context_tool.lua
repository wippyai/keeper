local ctx = require("ctx")

local function handler(args)
    if args.native_error then
        return nil, errors.new({ kind = errors.INVALID, message = "Invalid test limit", retryable = false,
            details = { code = "invalid_limit", field = "limit" } })
    end
    return {
        overlay_branch = ctx.get("overlay_branch"),
        changeset_id = ctx.get("changeset_id"),
        _control = { context = { session = { set = args.set, delete = args.delete } } },
    }
end
return { handler = handler }
