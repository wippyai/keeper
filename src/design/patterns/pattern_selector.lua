local json = require("json")

local pattern_selector = {}

pattern_selector._deps = {
    pattern_registry = require("pattern_registry"),
    llm = require("llm")
}

local CONFIG = table.freeze({
    MODEL = "gpt-5-nano",
    TEMPERATURE = 0,
    PROMPT_TEMPLATE = [[
You select patterns only when there is a CLEAR, DIRECT match to the user's request.

User Request: "%s"

%s

Available Patterns:
%s

CRITICAL RULES:
- Return EMPTY ARRAY when no pattern clearly matches
- Only select when pattern content DIRECTLY relates to request
- When uncertain or vague request, return ZERO patterns
- Better to return nothing than to guess

Examples of when NOT to select:
- Generic requests without clear context
- Requests where pattern might tangentially apply
- Any doubt about relevance

Only select patterns with obvious, direct relevance to the specific request.

Return the IDs of selected patterns as an array (empty if no clear matches).
]]
})

local function format_patterns_for_prompt(patterns)
    local n = #patterns
    if n == 0 then
        return "<patterns></patterns>"
    end

    local lines = table.create(n * 2 + 2, 0)
    local idx = 1
    lines[idx] = "<patterns>"
    idx = idx + 1

    for i = 1, n do
        local p = patterns[i]
        local classes_str = table.concat(p.class or {}, ", ")
        local tags_str = table.concat(p.tags or {}, ", ")
        lines[idx] = string.format(
            '<pattern id="%s" title="%s" classes="%s" tags="%s">\n%s\n</pattern>',
            p.id or "",
            p.title or "",
            classes_str,
            tags_str,
            p.content or ""
        )
        idx = idx + 1
    end

    lines[idx] = '</patterns>'

    return table.concat(lines, "\n", 1, idx)
end

local function format_patterns_xml(patterns)
    local n = #patterns
    if n == 0 then
        return "<patterns></patterns>"
    end

    local lines = table.create(n * 2 + 2, 0)
    local idx = 1
    lines[idx] = "<patterns>"
    idx = idx + 1

    for i = 1, n do
        local p = patterns[i]
        lines[idx] = string.format('<pattern id="%s" title="%s">%s</pattern>', p.id or "", p.title or "", p.content or "")
        idx = idx + 1
    end

    lines[idx] = '</patterns>'

    return table.concat(lines, "\n", 1, idx)
end

function pattern_selector.select_patterns(user_prompt, classes, system_guidance, output_format)
    output_format = output_format or "json"

    if not user_prompt or user_prompt == "" then
        return nil, "User prompt is required"
    end

    if not classes or #classes == 0 then
        return nil, "Classes array is required"
    end

    local patterns = pattern_selector._deps.pattern_registry.list_by_classes(classes)
    local n_patterns = #patterns

    if n_patterns == 0 then
        if output_format == "xml" then
            return "<patterns></patterns>", nil
        else
            return { patterns = table.create(0, 0), reasoning = "" }, nil
        end
    end

    local guidance_section = ""
    if system_guidance and system_guidance ~= "" then
        guidance_section = string.format("Additional Context:\n%s\n", system_guidance)
    end

    local selection_prompt = string.format(
        CONFIG.PROMPT_TEMPLATE,
        user_prompt,
        guidance_section,
        format_patterns_for_prompt(patterns)
    )

    local response_schema = {
        type = "object",
        properties = {
            selected_pattern_ids = {
                type = "array",
                items = { type = "string" },
                description = "Array of selected pattern IDs (can be empty)"
            },
            reasoning = {
                type = "string",
                description = "Brief explanation of selection"
            }
        },
        required = { "selected_pattern_ids", "reasoning" },
        additionalProperties = false
    }

    local response, err = pattern_selector._deps.llm.structured_output(response_schema, selection_prompt, {
        model = CONFIG.MODEL,
        temperature = CONFIG.TEMPERATURE
    })

    if err then
        return nil, "Failed to select patterns: " .. err
    end

    if not response or not response.result then
        return nil, "Invalid response from LLM"
    end

    local result = response.result
    local selected_ids = result.selected_pattern_ids or table.create(0, 0)
    local n_selected = #selected_ids

    local selected_patterns = table.create(n_selected, 0)
    local selected_count = 0

    for i = 1, n_selected do
        local selected_id = selected_ids[i]
        for j = 1, n_patterns do
            if patterns[j].id == selected_id then
                selected_count = selected_count + 1
                selected_patterns[selected_count] = patterns[j]
                break
            end
        end
    end

    if output_format == "xml" then
        return format_patterns_xml(selected_patterns), nil
    else
        return {
            patterns = selected_patterns,
            reasoning = result.reasoning or ""
        }, nil
    end
end

function pattern_selector.execute(input)
    if not input then
        return nil, "Input is required"
    end

    return pattern_selector.select_patterns(
        input.user_prompt,
        input.classes,
        input.system_guidance,
        input.output_format
    )
end

return pattern_selector