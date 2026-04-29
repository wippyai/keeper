-- Endpoint handler. Probes every pushed http.endpoint via
-- keeper.agents.tools:test_endpoint. Up = probe + assert <500 status;
-- Down = no-op (probes are read-only).

local funcs = require("funcs")
local registry = require("registry")

local TEST_ENDPOINT_ID = "keeper.agents.tools:test_endpoint"

local function string_list(value: unknown): {string}
    local out = {}
    if type(value) ~= "table" then return out end
    for _, item in ipairs(value) do
        if type(item) == "string" and item ~= "" then table.insert(out, item) end
    end
    return out
end

local function substitute_path_params(path: string): string
    return (path:gsub("{[^/{}]+}", "__probe__"))
end

local function join_paths(prefix: unknown, path: string): string
    prefix = tostring(prefix or "")
    path = tostring(path or "")

    if path == "" then return prefix end
    if path:sub(1, 1) ~= "/" then path = "/" .. path end

    if prefix == "" then return path end
    if prefix:sub(1, 1) ~= "/" then prefix = "/" .. prefix end
    if prefix:sub(-1) == "/" then prefix = prefix:sub(1, -2) end

    if path == prefix or path:sub(1, #prefix + 1) == prefix .. "/" then
        return path
    end

    return prefix .. path
end

local function parse_status(result)
    if type(result) == "table" then
        local status = rawget(result, "status")
        if status == nil then status = rawget(result, "status_code") end
        return tonumber(status)
    end
    if type(result) == "string" then
        local code = result:match("%-%>%s*(%d%d%d)")
        if code then return tonumber(code) end
    end
    return nil
end

local function endpoint_url(entry: unknown, router_entry: unknown): (string?, string?)
    local data = (entry and entry.data) or {}
    local method = data.method or "GET"
    local path = data.path
    if type(path) ~= "string" or path == "" then return nil, nil end

    local router_data = (router_entry and router_entry.data) or {}
    local prefix = router_data.prefix or ""
    return tostring(method):upper(), join_paths(prefix, substitute_path_params(path))
end

local function probe(method, path)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new failed: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        TEST_ENDPOINT_ID,
        { method = method, path = path, timeout = 30 })
    if not ok then return nil, "test_endpoint panic: " .. tostring(result) end
    if call_err then return nil, "test_endpoint: " .. tostring(call_err) end
    return {
        raw = result,
        status_code = parse_status(result),
    }, nil
end

local function handler(params)
    local entry_ids = string_list(params.entry_ids)
    local operation = params.operation or "up"
    if #entry_ids == 0 then return {} end

    if operation == "down" then
        local rows = {}
        for _, id in ipairs(entry_ids) do
            table.insert(rows, {
                id      = id,
                success = true,
                data    = { operation = "down", status = "noop",
                    description = "endpoint probes are read-only; nothing to reverse" },
            })
        end
        return rows
    end

    local rows, first_failure = {}, nil
    for _, id in ipairs(entry_ids) do
        local entry, gerr = registry.get(id)
        if gerr then
            return nil, "endpoint_handler: failed to load " .. id .. ": " .. tostring(gerr)
        end

        local router_entry = nil
        local router_id = entry.meta and entry.meta.router
        if type(router_id) == "string" and router_id ~= "" then
            local rerr
            router_entry, rerr = registry.get(router_id)
            if rerr then
                return nil, "endpoint_handler: failed to load router " ..
                    tostring(router_id) .. " for " .. id .. ": " .. tostring(rerr)
            end
        end

        local method, path = endpoint_url(entry, router_entry)
        if not path then
            table.insert(rows, {
                id = id, success = true,
                data = { operation = "up", status = "skipped",
                    description = "endpoint missing path — nothing to probe" },
            })
        else
            local result, perr = probe(method, path)
            local status_code = result and result.status_code
            local success = perr == nil and status_code and status_code < 500
            if not success and not first_failure then
                first_failure = {
                    id = id, method = method, path = path,
                    status = status_code, error = perr,
                }
            end
            table.insert(rows, {
                id      = id,
                success = success == true,
                error   = perr,
                data    = {
                    operation = "up",
                    status    = success and "passed" or "failed",
                    method    = method,
                    path      = path,
                    http_status = status_code,
                    response  = result and result.raw,
                },
            })
        end
    end

    if first_failure then
        return nil, "endpoint_handler: " .. first_failure.method .. " " ..
            first_failure.path .. " — " ..
            (first_failure.error or ("status=" .. tostring(first_failure.status or "?")))
    end
    return rows
end

return {
    handler = handler,
    __test = {
        endpoint_url = endpoint_url,
        join_paths = join_paths,
        parse_status = parse_status,
        substitute_path_params = substitute_path_params,
    },
}
