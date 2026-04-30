local registry = require("registry")
local hub_sdk = require("hub")

type ServiceError = unknown
type Parameter = { name: string, value: string }
type RequirementTarget = { entry?: string, path?: string }
type HubRequirement = {
    name?: string,
    description?: string,
    default?: string,
    targets?: { RequirementTarget },
}
type HubDependencyRef = {
    org?: string,
    name?: string,
    version?: string,
    version_constraint?: string,
}
type VersionPart = {
    major: number,
    minor: number,
    patch: number,
    prerelease: string,
    raw: string,
}
type VersionItem = {
    id?: string,
    version: string,
    yanked?: boolean,
    dependencies?: { HubDependencyRef },
    requirements?: { HubRequirement },
    entry_count?: number,
    entry_kinds?: { string },
    lua_modules?: { string },
    size_bytes?: number,
    digest?: string,
    protected?: boolean,
}
type DependencyEntryData = {
    component: string,
    version: string,
    parameters?: { Parameter },
}
type DependencyEntry = {
    id: string,
    kind: string,
    meta: {[string]: unknown},
    data: DependencyEntryData,
}
type GraphNode = {
    module: string,
    org: string,
    name: string,
    namespace: string,
    version: string,
    version_id?: string,
    constraint: string,
    depth: number,
    parent: string?,
    path: string,
    direct: boolean,
    dependencies: { HubDependencyRef },
    requirements: { HubRequirement },
}
type ConstraintPart = {
    op: string,
    any?: boolean,
    major?: number,
    minor?: number,
    version?: VersionPart,
}
type PlannerDeps = {
    registry: unknown?,
    catalog: unknown?,
}
type PlannerInstance = {
    registry: unknown,
    catalog: unknown,
    version_cache: {[string]: {VersionItem}},
    plan_install: (PlannerInstance, unknown) -> (unknown, unknown?),
}

local M = {}

local Planner = {}
Planner.__index = Planner

M.DEFAULT_DEP_NAMESPACE = "app.deps"
M.DEFAULT_VERSION = ">=v0.0.0"
M.DEFAULT_PLAN_MAX_DEPTH = 10
M.DEFAULT_PLAN_MAX_MODULES = 200

local function trim(value: unknown): string
    return string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
end

local function shallow_copy(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

local ERROR_KIND_BY_CODE = {
    BAD_REQUEST = errors.INVALID,
    NOT_FOUND = errors.NOT_FOUND,
    CONFLICT = errors.CONFLICT,
}

local function err(code: string, message: string, details: unknown?): unknown
    local d = {}
    if type(details) == "table" then
        for k, v in pairs(details) do d[k] = v end
    elseif details ~= nil then
        d.value = details
    end
    d.code = code
    return errors.new({
        kind = ERROR_KIND_BY_CODE[code] or errors.INTERNAL,
        message = tostring(message or "unknown error"),
        details = d,
    })
end

local function err_message(e, fallback)
    if not e then return fallback end
    local ok, method = pcall(function() return e.message end)
    if ok and type(method) == "function" then
        local called, message = pcall(method, e)
        if called then return message end
    end
    if type(e) == "table" then return e.message or e.error or fallback end
    return tostring(e)
end

local function err_details(e)
    if not e then return nil end
    local ok, method = pcall(function() return e.details end)
    if ok and type(method) == "function" then
        local called, details = pcall(method, e)
        if called then return details end
    end
    if type(e) == "table" then return e.details end
    return nil
end

local function starts_with(s: string, prefix: string): boolean
    return string.sub(tostring(s or ""), 1, #prefix) == prefix
end

local function is_array(t): boolean
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
        if k > n then n = k end
    end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true
end

function M.parse_component(component)
    component = tostring(trim(component))
    if component == "" then
        return nil, err("BAD_REQUEST", "component is required")
    end
    local org, name = string.match(component, "^([%w_.-]+)/([%w_.-]+)$")
    if not org or not name then
        return nil, err("BAD_REQUEST", "component must be in org/module form")
    end
    if org == "" or name == "" then
        return nil, err("BAD_REQUEST", "component must include both org and module")
    end
    return { org = org, module = name, component = org .. "/" .. name }, nil
end

function M.module_namespace(component: string): string?
    local parsed = M.parse_component(component)
    if not parsed then return nil end
    return parsed.org .. "." .. parsed.module
end

function M.sanitize_dependency_name(name)
    name = string.gsub(string.lower(trim(name)), "[^%w_.-]", "_")
    name = string.gsub(name, "^[_%.%-]+", "")
    name = string.gsub(name, "[_%.%-]+$", "")
    if name == "" then return nil end
    return name
end

function M.validate_namespace(namespace)
    namespace = trim(namespace)
    if namespace == "" then
        return nil, err("BAD_REQUEST", "namespace is required")
    end
    if string.find(namespace, "..", 1, true) or string.sub(namespace, 1, 1) == "." or string.sub(namespace, -1) == "." then
        return nil, err("BAD_REQUEST", "namespace must be dot-separated identifiers")
    end
    for part in string.gmatch(namespace, "[^.]+") do
        if not string.match(part, "^[A-Za-z][A-Za-z0-9_]*$") then
            return nil, err("BAD_REQUEST", "namespace must be dot-separated identifiers")
        end
    end
    if not string.match(namespace, "^[A-Za-z0-9_.]+$") then
        return nil, err("BAD_REQUEST", "namespace must be dot-separated identifiers")
    end
    return namespace, nil
end

function M.resolve_dependency_id(args)
    args = args or {}
    local explicit = tostring(trim(args.id))
    if explicit ~= "" then
        local ns, name = string.match(explicit, "^([^:]+):(.+)$")
        if not ns or not name or name == "" then
            return nil, err("BAD_REQUEST", "id must be namespace:name")
        end
        local ok_ns, ns_err = M.validate_namespace(ns)
        if not ok_ns then return nil, ns_err end
        return explicit, nil
    end

    local parsed, comp_err = M.parse_component(args.component)
    if not parsed then return nil, comp_err end

    local ns, ns_err = M.validate_namespace(args.namespace or M.DEFAULT_DEP_NAMESPACE)
    if not ns then return nil, ns_err end

    local name: string? = trim(args.name)
    if name == "" then
        name = M.sanitize_dependency_name(parsed.module)
    else
        name = M.sanitize_dependency_name(name)
    end
    if not name then
        return nil, err("BAD_REQUEST", "dependency name cannot be empty")
    end
    return ns .. ":" .. name, nil
end

function M.normalize_parameters(input): ({ Parameter }?, unknown?)
    if input == nil then return {}, nil end
    if type(input) ~= "table" then
        return nil, err("BAD_REQUEST", "parameters must be an array of {name,value} or an object map") :: unknown?
    end

    local out: { Parameter } = {}
    local seen = {}

    local function add(name, value)
        name = trim(name)
        if name == "" then
            return err("BAD_REQUEST", "parameter name is required")
        end
        if seen[name] then
            return err("BAD_REQUEST", "duplicate parameter: " .. name)
        end
        seen[name] = true
        if value == nil then value = "" end
        table.insert(out, { name = name, value = tostring(value) })
        return nil
    end

    if is_array(input) then
        for i, item in ipairs(input) do
            if type(item) ~= "table" then
                return nil, err("BAD_REQUEST", "parameters[" .. i .. "] must be an object") :: unknown?
            end
            local add_err = add(item.name, item.value)
            if add_err then return nil, add_err end
        end
    else
        local keys = {}
        for k in pairs(input) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            local add_err = add(k, input[k])
            if add_err then return nil, add_err end
        end
    end

    return out, nil
end

function M.build_dependency_entry(args)
    args = args or {}
    local parsed, comp_err = M.parse_component(args.component)
    if not parsed then return nil, comp_err end

    local id, id_err = M.resolve_dependency_id(args)
    if not id then return nil, id_err end

    local parameters, param_err = M.normalize_parameters(args.parameters)
    if not parameters then return nil, param_err end

    local data = {
        component = parsed.component,
        version = trim(args.version) ~= "" and trim(args.version) or M.DEFAULT_VERSION,
    }
    if #parameters > 0 then data.parameters = parameters end

    return {
        id = id,
        kind = "ns.dependency",
        meta = shallow_copy(args.meta or {}),
        data = data,
    }, nil
end

function M.dependency_summary(entry)
    local data = entry and entry.data or {}
    return {
        id = entry.id,
        namespace = (entry.id and string.match(tostring(entry.id), "^([^:]+):")) or nil,
        name = (entry.id and string.match(tostring(entry.id), "^[^:]+:(.+)$")) or nil,
        kind = entry.kind,
        component = data.component,
        version = data.version,
        parameters = data.parameters or {},
        meta = entry.meta or {},
    }
end

local function version_parts(version): VersionPart?
    version = tostring(trim(version)):gsub("^v", "")
    local maj, min, patch, pre = string.match(version, "^(%d+)%.(%d+)%.(%d+)%-(.+)$")
    if not maj then
        maj, min, patch = string.match(version, "^(%d+)%.(%d+)%.(%d+)$")
    end
    if not maj then return nil end
    return {
        major = tonumber(maj) or 0,
        minor = tonumber(min) or 0,
        patch = tonumber(patch) or 0,
        prerelease = pre or "",
        raw = version,
    }
end

local function compare_versions(a: unknown, b: unknown): number
    local left = type(a) == "table" and (a :: VersionPart) or version_parts(a)
    local right = type(b) == "table" and (b :: VersionPart) or version_parts(b)
    if not left and not right then return 0 end
    if not left then return -1 end
    if not right then return 1 end
    for _, k in ipairs({ "major", "minor", "patch" }) do
        if left[k] ~= right[k] then return left[k] < right[k] and -1 or 1 end
    end
    if left.prerelease == right.prerelease then return 0 end
    if left.prerelease == "" then return 1 end
    if right.prerelease == "" then return -1 end
    return left.prerelease < right.prerelease and -1 or 1
end

local function best_version(items)
    if type(items) ~= "table" then return nil end
    local arr = items :: {VersionItem}
    local best
    for _, item in ipairs(arr) do
        if not item.yanked and trim(item.version) ~= "" then
            if not best or compare_versions(item.version, best.version) > 0 then
                best = item
            end
        end
    end
    return best or arr[1] or nil
end

local function split_constraint(constraint): { string }
    constraint = tostring(trim(constraint)):gsub(",", " ")
    local parts: { string } = {}
    for p in string.gmatch(constraint, "%S+") do table.insert(parts, p) end
    return parts
end

local function parse_constraint_part(part): ConstraintPart?
    part = tostring(part or "")
    if part == "*" or part == "x" or part == "X" then
        return { op = "*", any = true }
    end
    local op = "="
    local ver = part
    for _, candidate in ipairs({ ">=", "<=", "!=", "^", "~", ">", "<", "=" }) do
        if string.sub(part, 1, #candidate) == candidate then
            op = candidate
            ver = string.sub(part, #candidate + 1)
            break
        end
    end
    ver = tostring(ver or "")
    local wildcard_major = string.match(ver, "^(%d+)%.([xX%*])$")
    if wildcard_major then
        return { op = "wildcard_minor", major = tonumber(wildcard_major) }
    end
    local major, minor, wildcard_patch = string.match(ver, "^(%d+)%.(%d+)%.([xX%*])$")
    if major and wildcard_patch then
        return { op = "wildcard_patch", major = tonumber(major), minor = tonumber(minor) }
    end
    local parsed = version_parts(ver)
    if not parsed then return nil end
    return { op = op, version = parsed }
end

local function satisfies_part(version: VersionPart, part: ConstraintPart): boolean
    if part.any then return true end
    if part.op == "wildcard_minor" then return version.major == part.major end
    if part.op == "wildcard_patch" then
        return version.major == part.major and version.minor == part.minor
    end

    local rhs = part.version
    if not rhs then return false end
    local cmp = compare_versions(version, rhs)
    if part.op == "=" then return cmp == 0 end
    if part.op == "!=" then return cmp ~= 0 end
    if part.op == ">" then return cmp > 0 end
    if part.op == ">=" then return cmp >= 0 end
    if part.op == "<" then return cmp < 0 end
    if part.op == "<=" then return cmp <= 0 end
    if part.op == "^" then
        if cmp < 0 then return false end
        local base = part.version
        if base.major > 0 then return version.major == base.major end
        if base.minor > 0 then return version.major == 0 and version.minor == base.minor end
        return version.major == 0 and version.minor == 0 and version.patch == base.patch
    end
    if part.op == "~" then
        return cmp >= 0 and version.major == part.version.major and version.minor == part.version.minor
    end
    return false
end

local function is_semver_constraint(constraint: string): boolean
    constraint = trim(constraint)
    if constraint == "" then return false end
    if starts_with(constraint, "@") then return false end
    if string.find(constraint, "[,<>=~%^!*xX%s]") then return true end
    return false
end

local function version_satisfies(version, constraint): boolean
    local parsed = version_parts(version)
    if not parsed then return false end
    local parts = split_constraint(constraint)
    if #parts == 0 then return true end
    for _, raw in ipairs(parts) do
        local part = parse_constraint_part(raw)
        if not part or not satisfies_part(parsed, part) then return false end
    end
    return true
end

local function module_ref_from_dep(dep: unknown): string?
    if type(dep) ~= "table" then return nil end
    local dep_map = dep :: {[string]: unknown}
    local org = trim(dep_map.org)
    local name = trim(dep_map.name)
    if org == "" or name == "" then return nil end
    return org .. "/" .. name
end

local function has_entry_kind(version, kind: string): boolean
    for _, entry_kind in ipairs((version and version.entry_kinds) or {}) do
        if tostring(entry_kind) == kind then return true end
    end
    return false
end

local function requirement_required(req): boolean
    return true
end

function M.new(deps: PlannerDeps?)
    deps = deps or {}
    return setmetatable({
        registry = deps.registry or registry,
        catalog = deps.catalog or hub_sdk,
        version_cache = {},
    }, Planner) :: PlannerInstance
end

function Planner:find_entries(criteria)
    local rows, find_err = self.registry.find(criteria or {})
    if find_err then
        return nil, err("INTERNAL", "registry.find failed: " .. tostring(find_err))
    end
    return rows or {}, nil
end

function Planner:dependency_entries()
    local rows, rows_err = self:find_entries({ [".kind"] = "ns.dependency" })
    if not rows then return nil, rows_err end
    table.sort(rows, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return rows, nil
end

function Planner:list_all_versions(component)
    component = trim(component)
    if component == "" then
        return nil, err("BAD_REQUEST", "component is required")
    end
    if self.version_cache[component] then
        return self.version_cache[component], nil
    end
    if not self.catalog or not self.catalog.versions or not self.catalog.versions.list then
        return nil, err("INTERNAL", "hub catalog versions API unavailable")
    end

    local out = {}
    local page = 1
    while true do
        local result, call_err = self.catalog.versions.list(component, { page = page, page_size = 100 })
        if not result then
            return nil, err("INTERNAL", "hub versions lookup failed for " .. component .. ": " .. tostring(call_err))
        end
        for _, item in ipairs(result.items or {}) do table.insert(out, item) end
        local total = tonumber(result.total or 0) or 0
        local page_size = tonumber(result.page_size or 100) or 100
        if #out >= total or #(result.items or {}) < page_size then break end
        page = page + 1
        if page > 50 then
            return nil, err("INTERNAL", "hub versions lookup exceeded pagination guard for " .. component)
        end
    end
    table.sort(out, function(a, b)
        return compare_versions(a.version, b.version) > 0
    end)
    self.version_cache[component] = out
    return out, nil
end

function Planner:version_details(component, selected)
    if not selected or not self.catalog or not self.catalog.versions or not self.catalog.versions.get then
        local with_deps, dep_err = self:manifest_dependency_details(component, selected)
        if not with_deps then return nil, dep_err end
        return self:artifact_requirement_details(component, with_deps)
    end

    local ref
    if trim(selected.id) ~= "" then
        ref = { id = selected.id }
    elseif trim(selected.version) ~= "" then
        ref = { version = selected.version }
    else
        return selected, nil
    end

    local detailed, detail_err = self.catalog.versions.get(component, ref)
    if detailed then
        local with_deps, dep_err = self:manifest_dependency_details(component, detailed)
        if not with_deps then return nil, dep_err end
        return self:artifact_requirement_details(component, with_deps)
    end

    -- Some Hub implementations return full records from list and do not support
    -- get-by-id/version. Planning must still work from the list payload.
    local with_deps, dep_err = self:manifest_dependency_details(component, selected)
    if not with_deps then return nil, dep_err end
    return self:artifact_requirement_details(component, with_deps)
end

function Planner:artifact_requirement_details(component, selected)
    if not selected then return selected, nil end
    local selected_item = selected :: VersionItem
    if #(selected_item.requirements or {}) > 0 then
        return selected, nil
    end
    if not has_entry_kind(selected_item, "ns.requirement") then
        return selected, nil
    end
    if not self.catalog or not self.catalog.versions or not self.catalog.versions.inspect then
        return nil, err("INTERNAL", "hub artifact inspection API unavailable for " .. component)
    end

    local ref
    if trim(selected_item.version) ~= "" then
        ref = { version = selected_item.version }
    elseif trim(selected_item.id) ~= "" then
        ref = { id = selected_item.id }
    else
        return nil, err("INTERNAL", "cannot inspect Hub artifact without version id or version")
    end

    local inspected, inspect_err = self.catalog.versions.inspect(component, ref)
    if not inspected then
        return nil, err("INTERNAL", "hub artifact inspection failed for " .. component .. ": " .. tostring(inspect_err))
    end

    local merged = shallow_copy(selected_item)
    merged.requirements = inspected.requirements or {}
    merged.entry_count = inspected.entry_count or merged.entry_count
    merged.entry_kinds = inspected.entry_kinds or merged.entry_kinds
    merged.size_bytes = inspected.size_bytes or merged.size_bytes
    merged.digest = inspected.digest or merged.digest
    merged.protected = inspected.protected == true or merged.protected == true
    return merged, nil
end

function Planner:manifest_dependency_details(component, selected)
    if not selected then return selected, nil end
    local selected_item = selected :: VersionItem
    if #(selected_item.dependencies or {}) > 0 or not has_entry_kind(selected_item, "ns.dependency") then
        return selected, nil
    end
    if not self.catalog or not self.catalog.manifest or not self.catalog.manifest.get then
        return nil, err("INTERNAL", "hub manifest API unavailable for " .. component)
    end

    local version = trim(selected_item.version)
    local manifest, manifest_err = self.catalog.manifest.get(component, version ~= "" and version or nil)
    if not manifest then
        return nil, err("INTERNAL", "hub manifest lookup failed for " .. component .. ": " .. tostring(manifest_err))
    end

    local merged = shallow_copy(selected_item)
    merged.dependencies = manifest.dependencies or {}
    return merged, nil
end

function Planner:select_version(component, constraint)
    constraint = trim(constraint)
    local versions, versions_err = self:list_all_versions(component)
    if not versions then return nil, versions_err end
    if #versions == 0 then
        return nil, err("NOT_FOUND", "no versions available for " .. component)
    end

    if constraint == "" then
        local selected = best_version(versions)
        return self:version_details(component, selected)
    end

    if starts_with(constraint, "@") then
        if self.catalog.versions.get then
            local label = string.sub(constraint, 2)
            local version, get_err = self.catalog.versions.get(component, { label = label })
            if version then return version, nil end
            return nil, err("NOT_FOUND", "label " .. constraint .. " not found for " .. component .. ": " .. tostring(get_err))
        end
        return nil, err("BAD_REQUEST", "hub catalog does not support label resolution")
    end

    if not is_semver_constraint(constraint) then
        for _, item in ipairs(versions) do
            if item.version == constraint or item.version == ("v" .. constraint) then
                return self:version_details(component, item)
            end
        end
        return nil, err("NOT_FOUND", "version " .. constraint .. " not found for " .. component)
    end

    local selected
    for _, item in ipairs(versions) do
        if not item.yanked and version_satisfies(item.version, constraint) then
            if not selected or compare_versions(item.version, selected.version) > 0 then
                selected = item
            end
        end
    end
    if not selected then
        return nil, err("NOT_FOUND", "no version of " .. component .. " satisfies " .. constraint)
    end
    return self:version_details(component, selected)
end

function Planner:resolve_install_graph(component, constraint, opts)
    opts = type(opts) == "table" and (opts :: {[string]: unknown}) or {}
    local parsed, comp_err = M.parse_component(component)
    if not parsed then return nil, comp_err end
    local max_depth = tonumber(opts.max_depth or M.DEFAULT_PLAN_MAX_DEPTH) or M.DEFAULT_PLAN_MAX_DEPTH
    local max_modules = tonumber(opts.max_modules or M.DEFAULT_PLAN_MAX_MODULES) or M.DEFAULT_PLAN_MAX_MODULES
    local nodes = {}
    local seen = {}
    local resolution_errors = {}

    local function visit(ref, version_constraint, depth, parent, path)
        if #nodes >= max_modules then
            table.insert(resolution_errors, { module = ref, constraint = version_constraint, message = "maximum module count exceeded" })
            return
        end
        if depth >= max_depth then
            table.insert(resolution_errors, { module = ref, constraint = version_constraint, message = "maximum dependency depth exceeded" })
            return
        end
        if seen[ref] then return end
        seen[ref] = true

        local selected, select_err = self:select_version(ref, version_constraint)
        if not selected then
            table.insert(resolution_errors, {
                module = ref,
                constraint = version_constraint,
                message = err_message(select_err, "version resolution failed"),
                details = err_details(select_err),
            })
            return
        end
        local selected_item = selected :: VersionItem

        local ref_parsed = M.parse_component(ref)
        local node = {
            module = ref,
            org = ref_parsed and ref_parsed.org or (string.match(ref, "^([^/]+)/") or ""),
            name = ref_parsed and ref_parsed.module or (string.match(ref, "/(.+)$") or ""),
            namespace = M.module_namespace(ref) or ref,
            version = selected_item.version or "",
            version_id = selected_item.id,
            constraint = version_constraint,
            depth = depth,
            path = path or ref,
            direct = depth == 0,
            dependencies = selected_item.dependencies or {},
            requirements = selected_item.requirements or {},
        }
        if parent then node.parent = parent end
        node.entry_count = selected_item.entry_count
        node.entry_kinds = selected_item.entry_kinds or {}
        node.lua_modules = selected_item.lua_modules or {}
        node.size_bytes = selected_item.size_bytes
        node.digest = selected_item.digest
        node.yanked = selected_item.yanked == true
        node.protected = selected_item.protected == true
        table.insert(nodes, node)

        for _, dep in ipairs(selected_item.dependencies or {}) do
            local child_ref = module_ref_from_dep(dep)
            if child_ref then
                visit(child_ref, dep.version_constraint or dep.version or "", depth + 1, ref, node.path .. " > " .. child_ref)
            end
        end
    end

    visit(parsed.component, constraint or M.DEFAULT_VERSION, 0, nil, parsed.component)

    if #resolution_errors > 0 then
        return nil, err("CONFLICT", "dependency resolution failed", { errors = resolution_errors })
    end
    return nodes, nil
end

function Planner:existing_parameter_values()
    local deps, deps_err = self:dependency_entries()
    if not deps then return nil, deps_err end
    local out = {}
    for _, dep in ipairs(deps) do
        local data = dep.data or {}
        for _, param in ipairs(data.parameters or {}) do
            local name = trim(param.name)
            if name ~= "" then
                table.insert(out, {
                    name = name,
                    value = tostring(param.value or ""),
                    dependency_id = tostring(dep.id),
                    component = data.component,
                })
            end
        end
    end
    return out, nil
end

function Planner:plan_requirements(graph, supplied_parameters)
    supplied_parameters = supplied_parameters or {}

    local function find_supplied(full_id, name, direct)
        for _, param in ipairs(supplied_parameters) do
            local param_name = trim(param.name)
            if param_name == full_id then
                return tostring(param.value or ""), "provided"
            end
            if direct and param_name == name then
                return tostring(param.value or ""), "provided_bare"
            end
        end
        return nil, nil
    end

    local existing, existing_err = self:existing_parameter_values()
    if not existing then return nil, existing_err end

    local function unique_existing_values(name, component)
        local out = {}
        local seen = {}
        for _, param in ipairs(existing or {}) do
            local value = trim(param.value)
            if value ~= "" and param.name == name and (component == nil or param.component == component) and not seen[value] then
                seen[value] = true
                table.insert(out, {
                    value = value,
                    dependency_id = param.dependency_id,
                    component = param.component,
                })
            end
        end
        return out
    end

    local function add_suggestion(suggestions, seen, value, label, source, dependency_id)
        value = trim(value)
        if value == "" or seen[value] then return end
        seen[value] = true
        table.insert(suggestions, {
            value = value,
            label = label or value,
            source = source,
            dependency_id = dependency_id,
        })
    end

    local out = {}
    local values = {}
    local missing = {}

    for _, node in ipairs(graph or {}) do
        for _, req in ipairs(node.requirements or {}) do
            local name = trim(req.name)
            if name ~= "" then
                local full_id = tostring(node.namespace or M.module_namespace(node.module) or node.module) .. ":" .. name
                local value, source = find_supplied(full_id, name, node.direct)
                local suggestions = {}
                local suggestion_seen = {}

                local exact_existing = unique_existing_values(full_id)
                for _, match in ipairs(exact_existing) do
                    add_suggestion(
                        suggestions,
                        suggestion_seen,
                        match.value,
                        match.value .. " from " .. tostring(match.dependency_id),
                        "existing",
                        match.dependency_id
                    )
                end

                local bare_existing = unique_existing_values(name, node.module)
                for _, match in ipairs(bare_existing) do
                    add_suggestion(
                        suggestions,
                        suggestion_seen,
                        match.value,
                        match.value .. " from " .. tostring(match.dependency_id),
                        "existing_bare",
                        match.dependency_id
                    )
                end

                if trim(req.default) ~= "" then
                    add_suggestion(suggestions, suggestion_seen, req.default, "package default: " .. req.default, "default")
                end

                if value == nil then
                    if #exact_existing == 1 then
                        value = exact_existing[1].value
                        source = "existing"
                    elseif #exact_existing > 1 then
                        source = "conflict"
                    end
                end
                if value == nil and source ~= "conflict" then
                    if #bare_existing == 1 then
                        value = bare_existing[1].value
                        source = "existing_bare"
                    elseif #bare_existing > 1 then
                        source = "conflict"
                    end
                end
                if value == nil and source ~= "conflict" and trim(req.default) ~= "" then
                    value = trim(req.default)
                    source = "default"
                end
                value = value or ""
                values[full_id] = value

                local row = {
                    name = name,
                    short_name = name,
                    parameter_name = full_id,
                    full_id = full_id,
                    module = node.module,
                    namespace = node.namespace,
                    version = node.version,
                    depth = node.depth,
                    dependency_path = node.path,
                    description = req.description,
                    default = req.default,
                    targets = req.targets or {},
                    required = requirement_required(req),
                    value = value,
                    value_source = source or "empty",
                    suggestions = suggestions,
                    transitive = node.depth > 0,
                }
                row.missing = row.required and trim(value) == ""
                table.insert(out, row)
            end
        end
    end

    table.sort(out, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        if a.module ~= b.module then return tostring(a.module) < tostring(b.module) end
        return tostring(a.name) < tostring(b.name)
    end)

    local parameters = {}
    for _, row in ipairs(out) do
        if row.missing then table.insert(missing, row.parameter_name) end
        if trim(row.value) ~= "" then
            table.insert(parameters, { name = row.parameter_name, value = row.value })
        end
    end

    return {
        requirements = out,
        values = values,
        parameters = parameters,
        missing = missing,
        count = #out,
    }, nil
end

function Planner:plan_install(args)
    args = args or {}
    local entry, entry_err = M.build_dependency_entry(args)
    if not entry then return nil, entry_err end
    local data = entry.data :: DependencyEntryData

    local graph, graph_err = self:resolve_install_graph(data.component, data.version, {
        max_depth = args.max_depth,
        max_modules = args.max_modules,
    })
    if not graph then return nil, graph_err end

    local req_plan, req_err = self:plan_requirements(graph, data.parameters or {})
    if not req_plan then return nil, req_err end

    return {
        dependency = M.dependency_summary(entry),
        graph = graph,
        module_count = #graph,
        requirements = req_plan.requirements,
        requirement_count = req_plan.count,
        missing_requirements = req_plan.missing,
        parameter_values = req_plan.values,
        recommended_parameters = req_plan.parameters,
        migration_policy = args.migration_policy or (args.run_migrations == true and "up" or "none"),
        install_payload = {
            id = entry.id,
            component = data.component,
            version = data.version,
            parameters = req_plan.parameters,
            migration_policy = args.migration_policy or (args.run_migrations == true and "up" or "none"),
        },
    }, nil
end

function M.plan_install(args)
    return M.new():plan_install(args)
end

return M
