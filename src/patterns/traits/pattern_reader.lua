local pattern_registry = require("pattern_registry")

local function handler(args)
    if args.pattern_id then
        return pattern_registry.get_by_id(args.pattern_id)
    end
    
    return {
        patterns = pattern_registry.list_all()
    }
end

return { handler = handler }