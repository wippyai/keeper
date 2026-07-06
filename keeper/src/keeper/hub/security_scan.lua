local hub_sdk = require("hub")
local json = require("json")
local llm = require("llm")
local prompt = require("prompt")
local registry = require("registry")
local time = require("time")
local planner = require("planner")

local M = {}

local Scanner = {}
Scanner.__index = Scanner

M.DEFAULT_MODEL = "class:smart"
M.DEFAULT_MAX_TOKENS = 2000
M.DEFAULT_CONTENT_LIMIT = 60000
M.DEFAULT_MAX_MODULES = 40
M.DEFAULT_TIME_BUDGET_MS = 120000

local STATUS_RANK = {
    clean = 0,
    warnings = 1,
    error = 1,
    critical = 2,
}

local SYSTEM_PROMPT = table.concat({
    "You are a security reviewer for Wippy Hub modules before installation.",
    "Review only the supplied module manifest and source. Do not assume code is safe",
    "because it is from a package registry.",
    "",
    "Evaluate:",
    "- Dangerous permissions, policies, requirements, or broad resource access.",
    "- Endpoint exposure, public routers, missing or weak security policies.",
    "- Suspicious code patterns such as shell execution, network calls, filesystem",
    "  access, process control, dynamic loading, or reflection beyond the module purpose.",
    "- Secrets handling, logging of credentials, hardcoded tokens, or exfiltration paths.",
    "",
    "Severity rules:",
    "- critical: likely credential exposure, unauthenticated sensitive endpoint,",
    "  arbitrary command execution, or clear exfiltration/destructive behavior.",
    "- warning: risky behavior requiring operator review.",
    "- info: noteworthy but low-risk context.",
    "",
    "OUTPUT: a single JSON object, no markdown, no prose. Shape:",
    '{"status":"clean|warnings|critical","summary":"short sentence","findings":[{"severity":"info|warning|critical","title":"short","detail":"optional","location":"entry id or kind"}]}',
}, "\n")

local function trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
end

local function now_ms()
    local ok, value = pcall(function()
        return math.floor(time.now():unix_nano() / 1e6)
    end)
    if ok then return value end
    return 0
end

local function encode(value)
    local ok, result = pcall(function() return json.encode(value) end)
    if ok and result then return tostring(result) end
    return tostring(value or "")
end

local function decode(text)
    local ok, result, err = pcall(function() return json.decode(text) end)
    if ok then return result, err end
    return nil, result
end

local function normalize_severity(value)
    value = trim(value):lower()
    if value == "critical" then return "critical" end
    if value == "warning" or value == "warn" then return "warning" end
    return "info"
end

local function status_from_findings(findings)
    local worst = "clean"
    for _, finding in ipairs(findings or {}) do
        local severity = normalize_severity(tostring(finding.severity or ""))
        if severity == "critical" then return "critical" end
        if severity == "warning" or severity == "info" then worst = "warnings" end
    end
    return worst
end

local function normalize_status(value, findings)
    local from_findings = status_from_findings(findings)
    value = trim(value):lower()
    if value == "critical" then
        return from_findings == "critical" and "critical" or from_findings
    end
    if value == "warnings" or value == "warning" then
        return from_findings == "clean" and "warnings" or from_findings
    end
    if value == "error" then return "error" end
    return from_findings
end

local function normalize_finding(raw, module, version, fallback_title)
    raw = type(raw) == "table" and raw or {}
    local title = trim(raw.title)
    if title == "" then title = fallback_title or "Security review finding" end
    local finding = {
        module = module,
        version = version,
        severity = normalize_severity(raw.severity),
        title = title,
    }
    local detail = trim(raw.detail)
    if detail ~= "" then finding.detail = detail end
    local location = trim(raw.location)
    if location ~= "" then finding.location = location end
    return finding
end

local function error_finding(module, version, title, detail, location)
    return {
        module = module,
        version = version,
        severity = "warning",
        title = title,
        detail = detail,
        location = location,
    }
end

local function entry_source(entry)
    if type(entry) ~= "table" then return "" end
    local data = type(entry.data) == "table" and entry.data or {}
    return trim(entry.source) ~= "" and tostring(entry.source)
        or (trim(data.source) ~= "" and tostring(data.source))
        or (trim(entry.content) ~= "" and tostring(entry.content))
        or (trim(data.content) ~= "" and tostring(data.content))
        or ""
end

local function entry_payload(entry)
    if type(entry) ~= "table" then return entry end
    return {
        id = entry.id,
        kind = entry.kind,
        meta = entry.meta,
        data = entry.data,
        source = entry_source(entry),
    }
end

local function artifact_entries(artifact)
    if type(artifact) ~= "table" then return {} end
    if type(artifact.entries) == "table" then return artifact.entries end
    if type(artifact.artifact) == "table" and type(artifact.artifact.entries) == "table" then
        return artifact.artifact.entries
    end
    if type(artifact.manifest) == "table" and type(artifact.manifest.entries) == "table" then
        return artifact.manifest.entries
    end
    return {}
end

local function build_content(node, artifact, limit)
    local payload = {
        module = node.module,
        version = node.version,
        digest = node.digest,
        entry_kinds = node.entry_kinds or {},
        requirements = node.requirements or {},
        dependencies = node.dependencies or {},
        entries = {},
    }
    for _, entry in ipairs(artifact_entries(artifact)) do
        table.insert(payload.entries, entry_payload(entry))
    end

    local content = encode(payload)
    local truncated = false
    limit = math.floor(tonumber(limit or M.DEFAULT_CONTENT_LIMIT) or M.DEFAULT_CONTENT_LIMIT)
    if #content > limit then
        content = string.sub(content, 1, limit)
        truncated = true
    end
    return content, truncated, #payload.entries
end

local function build_user_prompt(node, content, truncated, entry_count)
    local lines = {
        "Module: " .. tostring(node.module),
        "Version: " .. tostring(node.version or ""),
        "Entry count included: " .. tostring(entry_count or 0),
        "Content truncated: " .. (truncated and "yes" or "no"),
        "",
        "Module manifest and source JSON:",
        content,
    }
    return table.concat(lines, "\n")
end

local function module_result(node, status, summary, findings)
    return {
        module = tostring(node.module or ""),
        version = trim(node.version) ~= "" and tostring(node.version) or nil,
        status = status,
        summary = summary,
        findings = findings or {},
    }
end

local function overall_status(modules)
    local worst = "clean"
    for _, row in ipairs(modules or {}) do
        local status = trim(row.status):lower()
        if (STATUS_RANK[status] or 0) > (STATUS_RANK[worst] or 0) then
            worst = status
        end
    end
    if worst == "error" then return "warnings" end
    return worst
end

local function has_module_error(modules)
    for _, row in ipairs(modules or {}) do
        if trim(row.status):lower() == "error" then return true end
    end
    return false
end

local function overall_summary(status, scanned, total, modules)
    if has_module_error(modules) then
        return "Security review unavailable for one or more modules; review findings before install."
    end
    if status == "critical" then
        return "Security review found critical issues before install."
    end
    if status == "warnings" then
        return "Security review needs operator attention before install."
    end
    return "Security review found no issues in scanned modules."
end

function M.new(deps)
    deps = deps or {}
    return setmetatable({
        planner = deps.planner or planner,
        catalog = deps.catalog or hub_sdk,
        registry = deps.registry or registry,
        llm = deps.llm or llm,
        model = deps.model or M.DEFAULT_MODEL,
        max_tokens = deps.max_tokens or M.DEFAULT_MAX_TOKENS,
        content_limit = deps.content_limit or M.DEFAULT_CONTENT_LIMIT,
        max_modules = deps.max_modules or M.DEFAULT_MAX_MODULES,
        time_budget_ms = deps.time_budget_ms or M.DEFAULT_TIME_BUDGET_MS,
    }, Scanner)
end

function Scanner:planner_instance()
    if type(self.planner) == "table" and self.planner.new then
        return self.planner.new({ registry = self.registry, catalog = self.catalog })
    end
    return self.planner
end

function Scanner:plan(args)
    local p = self:planner_instance()
    if type(p) == "table" and p.plan_install then
        return p:plan_install(args)
    end
    return nil, "hub install planner unavailable"
end

function Scanner:inspect_module(node)
    local p = self:planner_instance()
    if not p or type(p.inspect_artifact) ~= "function" then
        return nil, "hub install planner artifact inspection API unavailable"
    end
    return p:inspect_artifact(node.module, { version = node.version, id = node.version_id })
end

function Scanner:review_module(node, artifact)
    if not self.llm or type(self.llm.generate) ~= "function" then
        return module_result(node, "error", "Security review unavailable.", {
            error_finding(node.module, node.version, "Security review unavailable",
                "No LLM model interface is configured for Keeper Hub security scans."),
        })
    end

    local content_limit = tonumber(self.content_limit or M.DEFAULT_CONTENT_LIMIT) or M.DEFAULT_CONTENT_LIMIT
    local content, truncated, entry_count = build_content(node, artifact, content_limit)
    local p = prompt.new()
    p:add_system(SYSTEM_PROMPT)
    p:add_user(build_user_prompt(node, content, truncated, entry_count))

    local resp, err = self.llm.generate(p, {
        model = self.model,
        max_tokens = self.max_tokens,
    })
    if err or not resp or trim(resp.result) == "" then
        return module_result(node, "error", "Security review unavailable.", {
            error_finding(node.module, node.version, "Security review unavailable",
                "The LLM reviewer could not complete for this module: " .. tostring(err or "empty response")),
        })
    end

    local decoded, decode_err = decode(resp.result)
    if type(decoded) ~= "table" then
        return module_result(node, "error", "Security review response was invalid.", {
            error_finding(node.module, node.version, "Security review response invalid",
                "The LLM reviewer returned non-JSON or malformed JSON: " .. tostring(decode_err or "decode failed")),
        })
    end

    local findings = {}
    for _, raw in ipairs(type(decoded.findings) == "table" and decoded.findings or {}) do
        table.insert(findings, normalize_finding(raw, node.module, node.version))
    end
    if truncated then
        table.insert(findings, error_finding(node.module, node.version,
            "Module content truncated for scan",
            "Only the first " .. tostring(self.content_limit) .. " bytes were sent to the LLM reviewer.",
            tostring(node.module)))
        findings[#findings].severity = "info"
    end

    local status = normalize_status(tostring(decoded.status or ""), findings)
    local summary = trim(decoded.summary)
    if summary == "" then
        summary = status == "clean" and "No risky patterns found." or "Security review found items to review."
    end
    return module_result(node, status, summary, findings)
end

function Scanner:scan(args)
    args = args or {}
    local started = now_ms()

    local plan, plan_err = self:plan(args)
    if not plan then return nil, plan_err end

    local modules = {}
    local scanned = 0
    local graph = plan.graph or {}
    local scan_limit = tonumber(args.max_scan_modules or self.max_modules) or self.max_modules

    for _, node in ipairs(graph) do
        if node.installed == true and node.direct ~= true then
            table.insert(modules, module_result(node, "clean",
                "Module is already installed locally; existing trusted installation is skipped.", {}))
        elseif scanned >= scan_limit then
            table.insert(modules, module_result(node, "error", "Security review skipped by module limit.", {
                error_finding(node.module, node.version, "Security review skipped",
                    "The scan reached the configured module limit before reviewing this module."),
            }))
        elseif now_ms() > 0 and started > 0 and now_ms() - started > self.time_budget_ms then
            table.insert(modules, module_result(node, "error", "Security review skipped by time budget.", {
                error_finding(node.module, node.version, "Security review timed out",
                    "The scan reached the configured time budget before reviewing this module."),
            }))
        else
            scanned = scanned + 1
            local artifact, artifact_err = self:inspect_module(node)
            if not artifact then
                table.insert(modules, module_result(node, "error", "Security review could not fetch module artifact.", {
                    error_finding(node.module, node.version, "Module artifact unavailable",
                        "Keeper could not fetch the module manifest/source for review: " .. tostring(artifact_err or "unknown error")),
                }))
            else
                table.insert(modules, self:review_module(node, artifact))
            end
        end
    end

    local status = overall_status(modules)
    return {
        success = true,
        overall_status = status,
        overall_summary = overall_summary(status, scanned, #graph, modules),
        modules = modules,
        scanned = scanned,
        total = #graph,
    }, nil
end

function M.scan(args)
    local scanner = M.new() :: any
    return scanner:scan(args)
end

M._build_user_prompt = build_user_prompt

return M
