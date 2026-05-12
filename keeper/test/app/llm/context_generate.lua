local function response_tokens()
    return {
        prompt_tokens = 8,
        completion_tokens = 16,
        thinking_tokens = 0,
        total_tokens = 24,
    }
end

local function handler(contract_args)
    local messages = (contract_args and contract_args.messages) or {}
    local text = ""
    for _, message in ipairs(messages) do
        local content = message.content
        if type(content) == "string" then
            text = text .. "\n" .. content
        elseif type(content) == "table" then
            for _, item in ipairs(content) do
                if type(item) == "table" and type(item.text) == "string" then
                    text = text .. "\n" .. item.text
                end
            end
        end
    end

    local lower = string.lower(text)
    local marker = "migration precedent context"
    if string.find(lower, "http", 1, true) or string.find(lower, "endpoint", 1, true) then
        marker = "http endpoint precedent context"
    elseif string.find(lower, "view", 1, true) or string.find(lower, "vue", 1, true) then
        marker = "view precedent context"
    elseif string.find(lower, "persist", 1, true) or string.find(lower, "repo", 1, true) then
        marker = "persist precedent context"
    end

    return {
        success = true,
        result = {
            content = marker .. ": target_db app:db; next migration number 01; observed patterns verified.",
            tool_calls = {},
        },
        finish_reason = "stop",
        tokens = response_tokens(),
        metadata = {
            provider = "app.llm:context_provider",
        },
    }
end

return { handler = handler }
