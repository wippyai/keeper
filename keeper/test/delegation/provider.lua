local store = require("store")

local function generate()
    local state = assert(store.get("app.delegation:state"))
    assert(state:set("calls", (state:get("calls") or 0) + 1))
    state:release()
    return {
        success = true,
        result = { content = "native delegated answer", tool_calls = {} },
        finish_reason = "stop",
        tokens = { prompt_tokens = 1, completion_tokens = 1, total_tokens = 2 },
    }
end


return { generate = generate }
