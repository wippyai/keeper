-- keeper.components.tools:resolve_touched
--
-- Given a list of relative filesystem paths, return the unique editable
-- component ids whose source tree contains any of those paths. Invoked by
-- push.lua via funcs.new():call to avoid a scanner import collision in
-- push's transitive alias closure.

local scanner = require("scanner")

local function normalize(path)
    if type(path) ~= "string" or path == "" then return nil end
    if path:sub(1, 2) == "./" then path = path:sub(3) end
    return path
end

local function path_under(prefix, target)
    if not prefix or prefix == "" then return false end
    if target == prefix then return true end
    return target:sub(1, #prefix + 1) == (prefix .. "/")
end

local function handler(params)
    local paths = params and params.paths or {}
    if type(paths) ~= "table" or #paths == 0 then
        return { components = {} }
    end

    local normalized = {}
    for _, p in ipairs(paths) do
        local n = normalize(p)
        if n then table.insert(normalized, n) end
    end
    if #normalized == 0 then return { components = {} } end

    local result, err = scanner.scan()
    if err or not result then
        return nil, "scanner.scan failed: " .. tostring(err or "unknown")
    end

    local candidates = {}
    for _, c in ipairs(result.applications or {}) do
        if c.editable and c.path then table.insert(candidates, c) end
    end
    for _, c in ipairs(result.widgets or {}) do
        if c.editable and c.path then table.insert(candidates, c) end
    end

    local seen = {}
    local components = {}
    for _, c in ipairs(candidates) do
        local prefix = normalize(c.path)
        if prefix then
            for _, p in ipairs(normalized) do
                if path_under(prefix, p) then
                    if not seen[c.id] then
                        seen[c.id] = true
                        table.insert(components, c.id)
                    end
                    break
                end
            end
        end
    end

    return { components = components }
end

return { handler = handler }
