-- Shared parser + validator for LLM responses that return arrays of named
-- groups of change_ids (clusterer + suggest_split). Both flows want:
--   1. tolerate ```json fences
--   2. require a specific top-level key (clusters/groups)
--   3. drop hallucinated change_ids
--   4. drop duplicate assignments across groups
--   5. funnel unassigned change_ids into a single fallback bucket so no
--      input is silently lost

local json = require("json")

local M = {}

-- Strip optional markdown fences and require decoded[opts.root_key] to be a table.
function M.parse(raw, opts)
    if type(raw) ~= "string" or raw == "" then return nil, "empty response" end
    local stripped: string = raw
    stripped = stripped:gsub("^```%w*\n", "")
    stripped = stripped:gsub("\n```%s*$", "")
    local decoded, err = json.decode(stripped)
    if err then return nil, "json decode failed: " .. tostring(err) end
    if type(decoded) ~= "table" or type(decoded[opts.root_key]) ~= "table" then
        return nil, "response missing " .. opts.root_key .. "[]"
    end
    return decoded, nil
end

-- Validate decoded[opts.root_key] against expected_ids[].
-- Returns (groups[], nil) or (nil, err). Hallucinated and duplicate ids are
-- dropped silently; unassigned ids land in a single fallback group titled
-- opts.fallback_title with summary opts.fallback_summary so the input set
-- is preserved end-to-end.
function M.validate(decoded, expected_ids, opts)
    local seen = {}
    for _, id in ipairs(expected_ids) do seen[id] = false end

    local out = {}
    for i, g in ipairs(decoded[opts.root_key]) do
        if type(g.title) ~= "string" or g.title == "" then
            return nil, opts.root_key:sub(1, -2) .. " " .. i .. " missing title"
        end
        if type(g.change_ids) ~= "table" or #g.change_ids == 0 then
            return nil, opts.root_key:sub(1, -2) .. " " .. i .. " missing change_ids"
        end
        local clean_ids = {}
        for _, id in ipairs(g.change_ids) do
            if seen[id] == false then
                seen[id] = true
                table.insert(clean_ids, id)
            end
        end
        if #clean_ids > 0 then
            table.insert(out, {
                title         = g.title,
                plain_summary = g.plain_summary or "",
                change_ids    = clean_ids,
            })
        end
    end

    local missed = {}
    for id, was_seen in pairs(seen) do
        if not was_seen then table.insert(missed, id) end
    end
    if #missed > 0 then
        table.insert(out, {
            title         = opts.fallback_title,
            plain_summary = opts.fallback_summary,
            change_ids    = missed,
        })
    end
    return out, nil
end

return M
