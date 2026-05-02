local M = {}

local DEFAULT_TIMEOUT = "90s"

function M.format_stats(stats)
    if type(stats) ~= "table" then return "" end
    local parts = {}
    local ordered = {
        "created", "updated", "deleted", "unchanged", "skipped", "total",
        "create", "update", "delete",
        "skipped_unmanaged_source", "skipped_unmanaged_registry", "managed_namespaces",
    }
    for _, k in ipairs(ordered) do
        if stats[k] ~= nil then
            table.insert(parts, k .. "=" .. tostring(stats[k]))
        end
    end
    for k, v in pairs(stats) do
        local known = false
        for _, ok in ipairs(ordered) do if ok == k then known = true break end end
        if not known and type(v) ~= "table" then
            table.insert(parts, k .. "=" .. tostring(v))
        end
    end
    return table.concat(parts, " ")
end

function M.sync_options(input)
    local options = {}
    if type(input) == "table" and input.managed_namespaces ~= nil then
        options.managed_namespaces = input.managed_namespaces
    end
    return options
end

local function extract_diff_error(diff_resp)
    if not diff_resp or diff_resp.ok then return nil end
    if diff_resp.errors and diff_resp.errors[1] then
        return diff_resp.errors[1].message
    end
    return nil
end

function M.run_sync(opts, input)
    input = input or {}
    local timeout = input.timeout or DEFAULT_TIMEOUT

    local result, err = opts.gov_fn(M.sync_options(input), timeout)
    if not result then
        return nil, opts.tool_name .. " failed: " .. tostring(err or "unknown error")
    end

    local stats_line = M.format_stats(result.stats)
    local summary = opts.direction .. " completed"
    if stats_line ~= "" then summary = summary .. " (" .. stats_line .. ")" end

    local diff_resp = opts.diff_fn(result)
    local diff_rows = diff_resp and diff_resp.ok and (diff_resp.rows_written or 0) or 0
    local diff_error = extract_diff_error(diff_resp)

    return {
        summary       = summary,
        message       = result.message,
        version       = result.version,
        stats         = result.stats,
        details       = result.details,
        journaled     = diff_rows,
        journal_error = diff_error,
    }
end

return M
