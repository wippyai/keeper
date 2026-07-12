local hub_sdk = require("hub")
local json = require("json")
local llm = require("llm")
local prompt = require("prompt")
local registry = require("registry")
local time = require("time")
local planner = require("planner")
local keeper_config = require("keeper_config")

local M = {}

local Scanner = {}
Scanner.__index = Scanner

type ScanNode = {
    module: string,
    version: string?,
    version_id: string?,
    id: string?,
    digest: string?,
    entry_kinds: { string }?,
    requirements: { unknown }?,
    dependencies: { unknown }?,
    installed: boolean?,
    direct: boolean?,
}
type ScanFinding = {
    module: string?,
    version: string?,
    severity: string?,
    title: string?,
    detail: string?,
    location: string?,
}
type ScanArtifact = {
    module: string?,
    version: string?,
    digest: string?,
    metadata: unknown?,
    resources: { unknown }?,
    resource_error: unknown?,
    close_error: unknown?,
    entries: { unknown }?,
    artifact: { entries: { unknown }? }?,
    manifest: { entries: { unknown }? }?,
}
type ReviewChunk = {
    index: number,
    total: number,
    entries: { unknown },
    bytes: number,
}
type ScannerDeps = {
    planner: unknown?,
    catalog: unknown?,
    registry: unknown?,
    llm: unknown?,
    config: unknown?,
    model: string?,
    max_tokens: number?,
    content_limit: number?,
    max_modules: number?,
    time_budget_ms: number?,
}

M.DEFAULT_MODEL = "class:fast"
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

local function trim(value: unknown): string
    return string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
end

local function resolve_model(deps: ScannerDeps): string
    local explicit = trim(deps.model)
    if explicit ~= "" then return explicit end

    local config = deps.config or keeper_config
    if type(config) == "table" and type(config.read_default) == "function" then
        local configured = config.read_default("hub_security_scan_model")
        configured = trim(configured)
        if configured ~= "" then return configured end
    end
    return M.DEFAULT_MODEL
end

local function now_ms(): number
    local ok, value = pcall(function()
        return math.floor(time.now():unix_nano() / 1e6)
    end)
    if ok then return value end
    return 0
end

local function encode(value: unknown): string
    local ok, result = pcall(function() return json.encode(value) end)
    if ok and result then return tostring(result) end
    return tostring(value or "")
end

local function decode(text: unknown)
    local ok, result, err = pcall(function() return json.decode(text) end)
    if ok then return result :: unknown, err :: unknown end
    return nil, result :: unknown
end

local function normalize_severity(value: unknown): string
    value = trim(value):lower()
    if value == "critical" then return "critical" end
    if value == "warning" or value == "warn" then return "warning" end
    return "info"
end

local function status_from_findings(findings: { ScanFinding }?): string
    local worst = "clean"
    for _, finding in ipairs(findings or {}) do
        local severity = normalize_severity(tostring(finding.severity or ""))
        if severity == "critical" then return "critical" end
        if severity == "warning" or severity == "info" then worst = "warnings" end
    end
    return worst
end

local function normalize_status(value: unknown, findings: { ScanFinding }): string
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

local function normalize_finding(raw: unknown, module: string, version: string?, fallback_title: string?): ScanFinding
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

local function error_finding(module: string, version: string?, title: string, detail: string, location: string?): ScanFinding
    return {
        module = module,
        version = version,
        severity = "warning",
        title = title,
        detail = detail,
        location = location,
    }
end

local function entry_source(entry: unknown): string
    if type(entry) ~= "table" then return "" end
    local data = type(entry.data) == "table" and entry.data or {}
    return entry.source ~= nil and tostring(entry.source)
        or (data.source ~= nil and tostring(data.source))
        or (entry.content ~= nil and tostring(entry.content))
        or (data.content ~= nil and tostring(data.content))
        or ""
end

local function data_without_source(entry: unknown): unknown
    if type(entry) ~= "table" or type(entry.data) ~= "table" then return type(entry) == "table" and entry.data or nil end
    local out: { [string]: unknown } = {}
    for key, value in pairs(entry.data :: { [string]: unknown }) do
        if key ~= "source" and key ~= "content" then out[key] = value end
    end
    return out
end

local function entry_payload(entry: unknown, source: string?, source_part: unknown?): unknown
    if type(entry) ~= "table" then return entry end
    local out: { [string]: unknown } = {
        id = entry.id,
        kind = entry.kind,
        meta = entry.meta,
        data = data_without_source(entry),
        source = source or entry_source(entry),
    }
    if source_part ~= nil then out.source_part = source_part end
    return out
end

local function artifact_entries(artifact: ScanArtifact?): { unknown }
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

local function entry_summary(entry: unknown, source_slice_limit: number): unknown
    if type(entry) ~= "table" then return entry end
    local source = entry_source(entry)
    return {
        id = entry.id,
        kind = entry.kind,
        meta = entry.meta,
        data = data_without_source(entry),
        has_source = source ~= "",
        source_bytes = #source,
        source_parts = source ~= "" and math.max(1, math.ceil(#source / source_slice_limit)) or 0,
    }
end

local function artifact_tree(node: ScanNode, artifact: ScanArtifact, source_slice_limit: number): unknown
    local entries = {}
    for _, entry in ipairs(artifact_entries(artifact)) do
        table.insert(entries, entry_summary(entry, source_slice_limit))
    end
    return {
        module = node.module,
        version = node.version or artifact.version,
        digest = node.digest or artifact.digest,
        entry_kinds = node.entry_kinds or {},
        requirements = node.requirements or {},
        dependencies = node.dependencies or {},
        metadata = artifact.metadata,
        resources = artifact.resources or {},
        entries = entries,
    }
end

local function source_slice_limit(content_limit: number): number
    local limit = math.floor(content_limit * 0.60)
    if limit < 12000 then limit = 12000 end
    if limit > 50000 then limit = 50000 end
    return limit
end

local function review_units(artifact: ScanArtifact, slice_limit: number): { unknown }
    local units = {}
    for _, entry in ipairs(artifact_entries(artifact)) do
        local source = entry_source(entry)
        if source == "" or #source <= slice_limit then
            table.insert(units, entry_payload(entry, source, nil))
        else
            local total = math.ceil(#source / slice_limit)
            local index = 1
            local offset = 1
            while offset <= #source do
                local last = math.min(#source, offset + slice_limit - 1)
                table.insert(units, entry_payload(entry, string.sub(source, offset, last), {
                    index = index,
                    total = total,
                    offset_start = offset,
                    offset_end = last,
                    complete_entry_source = false,
                }))
                index = index + 1
                offset = last + 1
            end
        end
    end
    return units
end

local function build_review_chunks(artifact: ScanArtifact, content_limit: number): { ReviewChunk }
    local slice_limit = source_slice_limit(content_limit)
    local max_chunk_bytes = math.max(16000, math.floor(content_limit * 0.85))
    local chunks: { ReviewChunk } = {}
    local current: { unknown } = {}
    local current_bytes = 0

    for _, unit in ipairs(review_units(artifact, slice_limit)) do
        local unit_bytes = #encode(unit)
        if #current > 0 and current_bytes + unit_bytes > max_chunk_bytes then
            table.insert(chunks, { index = #chunks + 1, total = 0, entries = current, bytes = current_bytes })
            current = {}
            current_bytes = 0
        end
        table.insert(current, unit)
        current_bytes = current_bytes + unit_bytes
    end
    if #current > 0 or #chunks == 0 then
        table.insert(chunks, { index = #chunks + 1, total = 0, entries = current, bytes = current_bytes })
    end
    for _, chunk in ipairs(chunks) do chunk.total = #chunks end
    return chunks
end

local function build_user_prompt(node: ScanNode, tree: unknown, chunk: ReviewChunk, entry_count: number): string
    local payload = {
        artifact_tree = tree,
        review_chunk = {
            index = chunk.index,
            total = chunk.total,
            bytes = chunk.bytes,
            entries = chunk.entries,
        },
    }
    local lines = {
        "Module: " .. tostring(node.module),
        "Version: " .. tostring(node.version or ""),
        "Total artifact entries: " .. tostring(entry_count or 0),
        "Review chunk: " .. tostring(chunk.index) .. " of " .. tostring(chunk.total),
        "Content truncated: no",
        "",
        "The artifact_tree is the full module entry/resource tree. The review_chunk",
        "contains complete source for the entries or source slices assigned to this",
        "chunk. Other chunks are reviewed separately, so do not report missing content",
        "only because another chunk is not in this prompt.",
        "",
        "Module manifest, tree, and source JSON:",
        encode(payload),
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

function M.new(deps: ScannerDeps?)
    local d: ScannerDeps = deps or {}
    return setmetatable({
        planner = d.planner or planner,
        catalog = d.catalog or hub_sdk,
        registry = d.registry or registry,
        llm = d.llm or llm,
        model = resolve_model(d),
        max_tokens = d.max_tokens or M.DEFAULT_MAX_TOKENS,
        content_limit = d.content_limit or M.DEFAULT_CONTENT_LIMIT,
        max_modules = d.max_modules or M.DEFAULT_MAX_MODULES,
        time_budget_ms = d.time_budget_ms or M.DEFAULT_TIME_BUDGET_MS,
    }, Scanner)
end

function Scanner:planner_instance(): unknown
    if type(self.planner) == "table" and self.planner.new then
        return self.planner.new({ registry = self.registry, catalog = self.catalog })
    end
    return self.planner
end

function Scanner:plan(args: unknown)
    local p = self:planner_instance()
    if type(p) == "table" and p.plan_install then
        local out, plan_err = p:plan_install(args)
        return out :: unknown, plan_err :: unknown
    end
    return nil, "hub install planner unavailable"
end

local function version_ref(node: ScanNode): unknown?
    if trim(node and node.version) ~= "" then
        return { version = node.version }
    end
    if trim(node and node.version_id) ~= "" then
        return { id = node.version_id }
    end
    if trim(node and node.id) ~= "" then
        return { id = node.id }
    end
    return nil
end

function Scanner:open_module(node: ScanNode): (ScanArtifact?, unknown?)
    if not self.catalog or not self.catalog.versions or type(self.catalog.versions.open) ~= "function" then
        return nil, "hub artifact open API unavailable"
    end
    local ref = version_ref(node)
    if not ref then
        return nil, "cannot open Hub artifact without version id or version"
    end

    local pkg, open_err = self.catalog.versions.open(node.module, ref)
    if not pkg then
        return nil, open_err or "hub artifact open failed"
    end

    local entries_raw, entries_err = pkg:entries({ include_data = true })
    local resources_raw, resources_err = pkg:resources()
    local metadata_raw, metadata_err = pkg:metadata()
    local close_ok: boolean, close_err: unknown = pcall(function() return pkg:close() end)
    if not close_ok then close_err = tostring(close_err) end

    if type(entries_raw) ~= "table" then
        return nil, entries_err or "hub artifact entries unavailable"
    end

    local artifact: ScanArtifact = {
        module = node.module,
        version = trim(pkg.version) ~= "" and tostring(pkg.version) or node.version,
        digest = trim(pkg.digest) ~= "" and tostring(pkg.digest) or node.digest,
        metadata = type(metadata_raw) == "table" and (metadata_raw :: unknown) or { error = metadata_err },
        resources = type(resources_raw) == "table" and (resources_raw :: { unknown }) or {},
        resource_error = resources_err,
        close_error = close_err,
        entries = entries_raw :: { unknown },
    }
    return artifact, nil
end

function Scanner:inspect_module(node: ScanNode): (ScanArtifact?, unknown?)
    local opened, open_err = self:open_module(node)
    if opened then return opened, nil end

    local p = self:planner_instance()
    if not p or type(p.inspect_artifact) ~= "function" then
        return nil, "hub artifact open failed: " .. tostring(open_err)
    end
    local inspected, inspect_err = p:inspect_artifact(node.module, { version = node.version, id = node.version_id })
    if inspected then return inspected, nil end
    return nil, "hub artifact open failed: " .. tostring(open_err)
        .. "; inspect fallback failed: " .. tostring(inspect_err)
end

local function append_findings(out: { ScanFinding }, seen: { [string]: boolean }, raw_findings: unknown, node: ScanNode)
    for _, raw in ipairs(type(raw_findings) == "table" and raw_findings or {}) do
        local item = normalize_finding(raw, node.module, node.version)
        local key = table.concat({
            normalize_severity(item.severity),
            trim(item.title),
            trim(item.location),
            trim(item.detail),
        }, "\n")
        if not seen[key] then
            seen[key] = true
            table.insert(out, item)
        end
    end
end

function Scanner:review_module(node: ScanNode, artifact: ScanArtifact)
    if not self.llm or type(self.llm.generate) ~= "function" then
        return module_result(node, "error", "Security review unavailable.", {
            error_finding(node.module, node.version, "Security review unavailable",
                "No LLM model interface is configured for Keeper Hub security scans."),
        })
    end

    local content_limit = tonumber(self.content_limit or M.DEFAULT_CONTENT_LIMIT) or M.DEFAULT_CONTENT_LIMIT
    local slice_limit = source_slice_limit(content_limit)
    local tree = artifact_tree(node, artifact, slice_limit)
    local chunks = build_review_chunks(artifact, content_limit)
    local entry_count = #artifact_entries(artifact)
    local findings: { ScanFinding } = {}
    local seen: { [string]: boolean } = {}
    local summaries: { string } = {}
    local declared_status = "clean"

    for _, chunk in ipairs(chunks) do
        local p = prompt.new()
        p:add_system(SYSTEM_PROMPT)
        p:add_user(build_user_prompt(node, tree, chunk, entry_count))

        local resp, err = self.llm.generate(p, {
            model = self.model,
            max_tokens = self.max_tokens,
        })
        if err or not resp or trim(resp.result) == "" then
            return module_result(node, "error", "Security review unavailable.", {
                error_finding(node.module, node.version, "Security review unavailable",
                    "The LLM reviewer could not complete chunk " .. tostring(chunk.index) .. " of "
                        .. tostring(chunk.total) .. " for this module: " .. tostring(err or "empty response"),
                    node.module),
            })
        end

        local decoded, decode_err = decode(resp.result)
        if type(decoded) ~= "table" then
            return module_result(node, "error", "Security review response was invalid.", {
                error_finding(node.module, node.version, "Security review response invalid",
                    "The LLM reviewer returned non-JSON or malformed JSON for chunk "
                        .. tostring(chunk.index) .. " of " .. tostring(chunk.total) .. ": "
                        .. tostring(decode_err or "decode failed"),
                    node.module),
            })
        end

        local decoded_map = decoded :: { [string]: unknown }
        append_findings(findings, seen, decoded_map.findings, node)
        local chunk_status = normalize_status(decoded_map.status, findings)
        if (STATUS_RANK[chunk_status] or 0) > (STATUS_RANK[declared_status] or 0) then
            declared_status = chunk_status
        end
        local summary = trim(decoded_map.summary)
        if summary ~= "" then table.insert(summaries, summary) end
    end

    local status = normalize_status(declared_status, findings)
    local summary = ""
    if #summaries > 0 and status ~= "clean" then
        summary = summaries[1]
    end
    if summary == "" then
        summary = status == "clean"
            and ("Reviewed " .. tostring(entry_count) .. " entries across " .. tostring(#chunks) .. " chunk(s); no risky patterns found.")
            or ("Reviewed " .. tostring(entry_count) .. " entries across " .. tostring(#chunks) .. " chunk(s); security review found items to review.")
    end
    return module_result(node, status, summary, findings)
end

function Scanner:scan(args: unknown): (unknown?, unknown?)
    local args_map = (type(args) == "table" and args or {}) :: { [string]: unknown }
    local started = now_ms()

    local plan, plan_err = self:plan(args_map)
    if not plan then return nil, plan_err end

    local modules = {}
    local scanned = 0
    local plan_map = plan :: { [string]: unknown }
    local graph = (type(plan_map.graph) == "table" and plan_map.graph or {}) :: { unknown }
    local scan_limit = tonumber(args_map.max_scan_modules or self.max_modules) or self.max_modules

    for _, raw_node in ipairs(graph) do
        local node = raw_node :: ScanNode
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
