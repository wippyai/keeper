local channel = require("channel")
local time = require("time")
local json = require("json")
local flow = require("flow")
local planner = require("planner")

local M = {}

M.SCANNER_AGENT = "keeper.hub.scan:module_scanner"
M.SUMMARIZER_AGENT = "keeper.hub.scan:scan_summarizer"
M.LIST_TOOL = "keeper.hub.scan:list_module"
M.READ_TOOL = "keeper.hub.scan:read_module"

M.DEFAULT_MAX_PARALLEL = 5
M.SCAN_TIMEOUT_SEC = 420
M.SCANNER_MAX_ITERATIONS = 16
M.SUMMARIZER_MAX_ITERATIONS = 12

type Target = { module: string, version: string, digest?: unknown }
type Finding = { severity?: string, title?: string, detail?: string, location?: string }
type ModuleResult = {
    module: string,
    version: string,
    digest?: unknown,
    status: string,
    summary?: string,
    findings: { Finding },
}
type ScanFlowResult = { status?: string, summary?: string, findings?: { Finding } }
type SummaryModule = { module: string, status?: string, summary?: string }
type Summary = { overall_status: string, overall_summary?: string, modules: { SummaryModule } }
type ScanReport = {
    overall_status: string,
    overall_summary?: string,
    modules: { ModuleResult },
    scanned: number,
    total: number,
}
type PlanNode = { module?: string, version?: string, digest?: unknown }
type InstallPlan = { graph?: { PlanNode } }

local STATUS_RANK: {[string]: number} = { clean = 0, warnings = 1, error = 2, critical = 3 }

local FINDINGS_SCHEMA = {
    type = "object",
    properties = {
        status = {
            type = "string",
            enum = { "clean", "warnings", "critical", "error" },
            description = "Overall verdict for this module.",
        },
        summary = {
            type = "string",
            description = "One or two sentences on what the module does and any concern.",
        },
        findings = {
            type = "array",
            items = {
                type = "object",
                properties = {
                    severity = { type = "string", enum = { "info", "warning", "critical" } },
                    title = { type = "string", description = "Short title of the issue." },
                    detail = { type = "string", description = "What the code does and why it is risky." },
                    location = { type = "string", description = "Entry id / kind where it was found." },
                },
                required = { "severity", "title" },
                additionalProperties = false,
            },
        },
    },
    required = { "status", "findings" },
    additionalProperties = false,
}

local SUMMARY_SCHEMA = {
    type = "object",
    properties = {
        overall_status = { type = "string", enum = { "clean", "warnings", "critical", "error" } },
        overall_summary = { type = "string", description = "Short headline verdict across all modules." },
        modules = {
            type = "array",
            items = {
                type = "object",
                properties = {
                    module = { type = "string" },
                    status = { type = "string", enum = { "clean", "warnings", "critical", "error" } },
                    summary = { type = "string" },
                },
                required = { "module", "status" },
                additionalProperties = false,
            },
        },
    },
    required = { "overall_status", "modules" },
    additionalProperties = false,
}

local function trim(s: unknown): string return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1")) end

local function worst_status(statuses: { string }): string
    local worst: string = "clean"
    for _, s in ipairs(statuses) do
        if (STATUS_RANK[s] or 0) > (STATUS_RANK[worst] or 0) then worst = s end
    end
    return worst
end

local function effective_parallel(value: unknown, count: number): number
    local n = tonumber(value or M.DEFAULT_MAX_PARALLEL) or M.DEFAULT_MAX_PARALLEL
    n = math.floor(n)
    if n < 1 then n = 1 end
    if count > 0 and n > count then n = count end
    return n
end

local function resolve_targets(args: unknown): ({ Target }?, unknown?)
    local plan, err = planner.plan_install(args)
    if not plan then return nil, err end
    local resolved = plan :: InstallPlan
    local out: { Target } = {}
    local seen: {[string]: boolean} = {}
    for _, node in ipairs(resolved.graph or {}) do
        local module = trim(node.module)
        if module ~= "" and not seen[module] then
            seen[module] = true
            out[#out + 1] = { module = module, version = trim(node.version), digest = node.digest }
        end
    end
    return out, nil
end

local function scan_one(node: Target): ModuleResult
    local module = node.module
    local version = node.version
    local message = table.concat({
        "You are scanning a Wippy module BEFORE it is installed. Decide whether its code is safe to install.",
        "Module: " .. module,
        "Version: " .. version,
        "",
        "Map its structure with list_module_namespaces, then read every code namespace with " ..
        'read_module_entries (module="' .. module .. '", version="' .. version .. '"), review the code, ' ..
        "and return findings via the exit schema.",
    }, "\n")

    local ok, result, err = pcall(function()
        return flow.create()
            :with_title("Scan " .. module .. "@" .. version)
            :with_input({ message = message })
            :agent(M.SCANNER_AGENT, {
                arena = {
                    max_iterations = M.SCANNER_MAX_ITERATIONS,
                    tool_calling = "auto",
                    tools = {
                        { id = M.LIST_TOOL },
                        { id = M.READ_TOOL },
                    },
                    exit_schema = FINDINGS_SCHEMA,
                },
            })
            :run()
    end)

    if not ok then
        return { module = module, version = version, status = "error", findings = {},
            summary = "scan crashed: " .. tostring(result) }
    end
    if err or type(result) ~= "table" then
        return { module = module, version = version, status = "error", findings = {},
            summary = "scan failed: " .. tostring(err or "no result") }
    end

    local data = result :: ScanFlowResult
    local findings: { Finding } = {}
    local raw_findings = data.findings
    if type(raw_findings) == "table" then findings = raw_findings end
    local status = type(data.status) == "string" and data.status
        or (#findings > 0 and "warnings" or "clean")
    return {
        module = module,
        version = version,
        digest = node.digest,
        status = status,
        summary = type(data.summary) == "string" and data.summary or nil,
        findings = findings,
    }
end

local function fallback_summary(per_module: { ModuleResult }): Summary
    local statuses: { string } = {}
    local mods: { SummaryModule } = {}
    for _, r in ipairs(per_module) do
        statuses[#statuses + 1] = r.status
        mods[#mods + 1] = { module = r.module, status = r.status, summary = r.summary }
    end
    local overall = worst_status(statuses)
    return {
        overall_status = overall,
        overall_summary = "Scanned " .. #per_module .. " module(s); worst status: " .. overall .. ".",
        modules = mods,
    }
end

local function summarize(per_module: { ModuleResult }): Summary
    if #per_module == 0 then
        return { overall_status = "clean", overall_summary = "Nothing to scan.", modules = {} }
    end
    local install_set: { { module: string, version: string } } = {}
    local payload: { ModuleResult } = {}
    for _, r in ipairs(per_module) do
        install_set[#install_set + 1] = { module = r.module, version = r.version }
        payload[#payload + 1] = {
            module = r.module, version = r.version, status = r.status,
            summary = r.summary, findings = r.findings,
        }
    end
    local message = table.concat({
        "Modules being installed (module + version):",
        json.encode(install_set),
        "",
        "Sub-agent per-module scan results:",
        json.encode(payload),
        "",
        "Review these, spot-check the risky or doubtful modules yourself with list_module_namespaces / read_module_entries, then return the final verdict via the exit schema.",
    }, "\n")

    local ok, result, err = pcall(function()
        return flow.create()
            :with_title("Scan review")
            :with_input({ message = message })
            :agent(M.SUMMARIZER_AGENT, {
                arena = {
                    max_iterations = M.SUMMARIZER_MAX_ITERATIONS,
                    tool_calling = "auto",
                    tools = {
                        { id = M.LIST_TOOL },
                        { id = M.READ_TOOL },
                    },
                    exit_schema = SUMMARY_SCHEMA,
                },
            })
            :run()
    end)
    if not ok or err or type(result) ~= "table" then
        return fallback_summary(per_module)
    end
    local data = result :: Summary
    if type(data.overall_status) ~= "string" then
        return fallback_summary(per_module)
    end
    return data
end

function M.run(args: {[string]: unknown}?): (ScanReport?, unknown?)
    args = args or {}

    local targets, err = resolve_targets(args)
    if not targets then return nil, err end
    if #targets == 0 then
        return { overall_status = "clean", overall_summary = "No modules to scan.",
            modules = {}, scanned = 0, total = 0 }
    end

    local done = channel.new(#targets)
    local next_i = 1
    local workers = effective_parallel(args.max_parallel, #targets)

    for _ = 1, workers do
        coroutine.spawn(function()
            while true do
                local i = next_i
                next_i = next_i + 1
                local node = targets[i]
                if not node then return end
                done:send({ module = node.module, result = scan_one(node) })
            end
        end)
    end

    local timeout_ch = time.after(M.SCAN_TIMEOUT_SEC .. "s")
    local per_module: { ModuleResult } = {}
    local received = 0
    while received < #targets do
        local sel = channel.select({
            done:case_receive(),
            timeout_ch:case_receive(),
        })
        if not sel.ok or sel.channel == timeout_ch then
            -- Deadline hit: mark any module that has not reported as errored.
            local got: {[string]: boolean} = {}
            for _, r in ipairs(per_module) do got[r.module] = true end
            for _, node in ipairs(targets) do
                if not got[node.module] then
                    per_module[#per_module + 1] = { module = node.module, version = node.version,
                        status = "error", findings = {}, summary = "scan timed out" }
                end
            end
            break
        end
        received = received + 1
        if sel.value and sel.value.result then
            per_module[#per_module + 1] = sel.value.result
        end
    end

    local summary = summarize(per_module)

    for _, r in ipairs(per_module) do
        for _, m in ipairs(summary.modules or {}) do
            if m.module == r.module then
                local m_status = m.status
                local m_summary = m.summary
                if type(m_status) == "string" and m_status ~= "" then r.status = m_status end
                if type(m_summary) == "string" and m_summary ~= "" then r.summary = m_summary end
                break
            end
        end
    end

    return {
        overall_status = summary.overall_status,
        overall_summary = summary.overall_summary,
        modules = per_module,
        scanned = #per_module,
        total = #targets,
    }
end

return { run = M.run }
