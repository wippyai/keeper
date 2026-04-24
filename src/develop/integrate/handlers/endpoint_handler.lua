-- Endpoint handler. Probes every pushed http.endpoint via
-- keeper.components.tools:test_endpoint. Up = probe + assert <500 status;
-- Down = no-op (probes are read-only).

local funcs = require("funcs")
local registry = require("registry")

local function endpoint_url(entry)
    local method = (entry.meta and (entry.meta.method or entry.method)) or entry.method or "GET"
    local path   = entry.path or (entry.meta and entry.meta.path)
    if not path or path == "" then return nil, nil end
    return method:upper(), path
end

local function probe(method, path)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new failed: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.components.tools:test_endpoint",
        { method = method, path = path, timeout_s = 30 })
    if not ok then return nil, "test_endpoint panic: " .. tostring(result) end
    if call_err then return nil, "test_endpoint: " .. tostring(call_err) end
    return result, nil
end

local function handler(params)
    local entry_ids = params.entry_ids or {}
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
        local method, path = endpoint_url(entry)
        if not path then
            table.insert(rows, {
                id = id, success = true,
                data = { operation = "up", status = "skipped",
                    description = "endpoint missing path — nothing to probe" },
            })
        else
            local result, perr = probe(method, path)
            local status_code = result and (result.status or result.status_code)
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

return { handler = handler }
