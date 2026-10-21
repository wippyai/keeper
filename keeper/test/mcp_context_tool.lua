local ctx = require("ctx")

local function handler(args)
    return {
        overlay_branch = ctx.get("overlay_branch"),
        changeset_id = ctx.get("changeset_id"),
        _control = { context = { session = { set = args.set, delete = args.delete } } },
    }
end
return { handler = handler }
