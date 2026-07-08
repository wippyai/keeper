local M = {}

M.LOCK_PATH = "wippy.lock"

type LockModule = {
    name: string,
    version: string?,
    hash: string?,
    digest: string?,
}

type GraphModule = {
    module: string?,
    name: string?,
    version: string?,
    hash: string?,
    digest: string?,
}

local function trim(value: unknown): string
    return string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
end

local function err(code, message, details)
    local d = {}
    if type(details) == "table" then
        for k, v in pairs(details) do d[k] = v end
    elseif details ~= nil then
        d.value = details
    end
    d.code = code
    return errors.new({
        kind = errors.INTERNAL,
        message = tostring(message or "unknown error"),
        details = d,
    })
end

local function module_digest(row)
    local value = row and (row.digest or row.hash)
    if value == nil then return "" end
    value = tostring(value)
    value = string.gsub(value, "^sha256:", "")
    return value
end

local function replacement_set(lock_doc)
    local out = {}
    for _, row in ipairs(lock_doc.replacements or {}) do
        if type(row) == "table" and row.from and row.from ~= "" then
            out[tostring(row.from)] = true
        end
    end
    return out
end

local function sort_modules(lock_doc)
    table.sort(lock_doc.modules or {}, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)
end

local function module_index(lock_doc)
    local by_name: { [string]: LockModule } = {}
    for _, row in ipairs(lock_doc.modules or {}) do
        if type(row) == "table" and row.name then
            by_name[tostring(row.name)] = row :: LockModule
        end
    end
    return by_name
end

local function graph_modules(graph)
    local out: { LockModule } = {}
    local seen: { [string]: LockModule } = {}
    for _, node in ipairs(graph or {}) do
        local item_node = node :: GraphModule
        local name = trim(item_node.module or item_node.name)
        if name ~= "" then
            local version = trim(item_node.version)
            local hash = module_digest(node)
            local prior = seen[name]
            if prior then
                if prior.version ~= version or prior.hash ~= hash then
                    return nil, err("INTERNAL", "resolved module graph contains conflicting entries for " .. name)
                end
            else
                local item = { name = name, version = version, hash = hash }
                seen[name] = item
                table.insert(out, item)
            end
        end
    end
    return out, nil
end

local function fs_readfile(vol, path)
    if type(vol.readfile) == "function" then return vol:readfile(path) end
    if type(vol.read_file) == "function" then return vol:read_file(path) end
    return nil, "filesystem does not support readfile"
end

local function fs_writefile(vol, path, content)
    if type(vol.writefile) == "function" then return vol:writefile(path, content) end
    if type(vol.write_file) == "function" then return vol:write_file(path, content) end
    return nil, "filesystem does not support writefile"
end

function M.preview_install(lock_doc, graph)
    lock_doc.modules = lock_doc.modules or {}
    local modules, modules_err = graph_modules(graph)
    if not modules then return nil, modules_err end

    local replacements = replacement_set(lock_doc)
    local by_name = module_index(lock_doc)
    local changes = { upserted = {}, skipped_replacements = {}, unchanged = {} }

    for _, item in ipairs(modules) do
        if replacements[item.name] then
            table.insert(changes.skipped_replacements, { name = item.name })
        else
            if item.version == "" or item.hash == "" then
                return nil, err("INTERNAL", "resolved module graph is missing version or digest for " .. item.name)
            end

            local existing = by_name[item.name]
            if existing and tostring(existing.version or "") == item.version and module_digest(existing) == item.hash then
                table.insert(changes.unchanged, { name = item.name, version = item.version, hash = item.hash })
            else
                table.insert(changes.upserted, { name = item.name, version = item.version, hash = item.hash })
            end
        end
    end

    return changes, nil
end

function M.apply_install(lock_doc, graph)
    local changes, changes_err = M.preview_install(lock_doc, graph)
    if not changes then return nil, changes_err end

    local modules, modules_err = graph_modules(graph)
    if not modules then return nil, modules_err end

    lock_doc.modules = lock_doc.modules or {}
    local replacements = replacement_set(lock_doc)
    local by_name = module_index(lock_doc)

    for _, item in ipairs(modules) do
        if not replacements[item.name] then
            local existing = by_name[item.name]
            if existing then
                existing.version = item.version
                existing.hash = item.hash
            else
                local row = { name = item.name, version = item.version, hash = item.hash }
                table.insert(lock_doc.modules, row)
                by_name[item.name] = row
            end
        end
    end
    sort_modules(lock_doc)
    return changes, nil
end

-- Prunes wippy.lock to the closure of the remaining deployment roots.
--
-- target_module is the component being explicitly uninstalled (R). Its own lock
-- row is always removed, regardless of uncertainty: an explicit uninstall of R
-- deletes R's registry root, so leaving R in the lock would be a silent
-- registry/lock divergence. This mirrors standard package managers, where
-- uninstalling R removes R even if something else might still want it.
--
-- keep_modules is the set of modules provably still reachable from a RESOLVED
-- remaining root. unresolved_modules is the set of remaining roots reached during
-- closure resolution that have no local installed edges, so their dependency set
-- is unknowable. When such a root is present in the lock it is "uncertain": its
-- potential dependencies span the whole lock and cannot be ruled out. Under that
-- uncertainty only the transitive pruning is withheld -- a non-keep transitive
-- that an uncertain root could need is kept (over-keep, never over-prune) and
-- reported in kept_under_uncertainty. R itself is still removed. With no
-- uncertain root, a non-keep transitive is provably exclusive to R and removed.
-- Replacement modules are always protected and reported as skipped.
--
-- Soundness contract (offline closure): the closure is correct because governance
-- install writes each module's complete edge set (its ns.definition plus every
-- module-owned ns.dependency row, meta.module == it) in ONE atomic changeset. A
-- partial edge set (some edges present, one missing) therefore implies registry
-- corruption, which is out of scope; where such corruption surfaces as a
-- lock-present, edgeless remaining root it is handled conservatively here
-- (withhold the transitive prune + report loudly). The belt-and-suspenders
-- alternative -- storing each module's resolved edge set in the lock so the prune
-- never depends on registry edges -- is intentionally not implemented while the
-- atomicity invariant holds.
function M.preview_uninstall(lock_doc, keep_modules, unresolved_modules, target_module, target_modules)
    lock_doc.modules = lock_doc.modules or {}
    keep_modules = keep_modules or {}
    unresolved_modules = unresolved_modules or {}
    target_modules = target_modules or nil
    target_module = trim(target_module)
    local replacements = replacement_set(lock_doc)

    local uncertain_seen = {}
    local uncertain_modules = {}
    for _, row in ipairs(lock_doc.modules or {}) do
        local name = trim(row.name)
        if name ~= "" and name ~= target_module and unresolved_modules[name] and not uncertain_seen[name] then
            uncertain_seen[name] = true
            table.insert(uncertain_modules, name)
        end
    end
    local uncertain_root_present = #uncertain_modules > 0
    table.sort(uncertain_modules)

    local unmanaged_baseline_present = false
    if target_modules ~= nil then
        for _, row in ipairs(lock_doc.modules or {}) do
            local name = trim(row.name)
            if name ~= "" and name ~= target_module and not target_modules[name] and not keep_modules[name] then
                unmanaged_baseline_present = true
                break
            end
        end
    end
    local withhold_transitive_prune = uncertain_root_present or unmanaged_baseline_present

    local removed = {}
    local skipped_replacements = {}
    local kept_under_uncertainty = {}
    for _, row in ipairs(lock_doc.modules or {}) do
        local name = trim(row.name)
        if name ~= "" then
            if name == target_module and not replacements[name] then
                table.insert(removed, { name = name, version = row.version, hash = row.hash })
            elseif (target_modules == nil or target_modules[name]) and not keep_modules[name] then
                if replacements[name] then
                    table.insert(skipped_replacements, { name = name })
                elseif withhold_transitive_prune then
                    table.insert(kept_under_uncertainty, { name = name, version = row.version, hash = row.hash })
                else
                    table.insert(removed, { name = name, version = row.version, hash = row.hash })
                end
            end
        end
    end

    -- The uncertain/warning surface is keyed to an ACTUAL withheld prune, not
    -- to the mere presence of an uncertain root: an uncertain root whose
    -- transitives are all otherwise exclusive to target_module withholds
    -- nothing, so there is nothing to report.
    local changes = { removed = removed, skipped_replacements = skipped_replacements }
    if #kept_under_uncertainty > 0 then
        changes.uncertain = true
        changes.uncertain_modules = uncertain_modules
        changes.kept_under_uncertainty = kept_under_uncertainty
    end
    return changes, nil
end

function M.apply_uninstall(lock_doc, keep_modules, unresolved_modules, target_module, target_modules)
    local changes, changes_err = M.preview_uninstall(lock_doc, keep_modules, unresolved_modules, target_module, target_modules)
    if not changes then return nil, changes_err end

    local remove = {}
    for _, row in ipairs(changes.removed or {}) do remove[row.name] = true end

    local kept = {}
    for _, row in ipairs(lock_doc.modules or {}) do
        if not remove[trim(row.name)] then table.insert(kept, row) end
    end
    lock_doc.modules = kept
    sort_modules(lock_doc)
    return changes, nil
end

function M.summary(path, update)
    if not update then return nil end
    return {
        changed = update.changed == true,
        operation = update.operation,
        reason = update.reason,
        uncertain = update.uncertain == true or (update.changes and update.changes.uncertain == true) or nil,
        path = path or M.LOCK_PATH,
        changes = update.changes,
    }
end

function M.read(fs_mod, yaml_mod, fs_id, path)
    path = path or M.LOCK_PATH
    if not fs_mod or not fs_mod.get then
        return nil, err("INTERNAL", "filesystem module unavailable")
    end
    if not yaml_mod or not yaml_mod.decode or not yaml_mod.encode then
        return nil, err("INTERNAL", "yaml module unavailable")
    end

    local vol, fs_err = fs_mod.get(fs_id)
    if not vol then
        return nil, err("INTERNAL", "failed to open project filesystem: " .. tostring(fs_err or "nil filesystem"))
    end

    local content, read_err = fs_readfile(vol, path)
    if not content then
        return nil, err("INTERNAL", "failed to read " .. path .. ": " .. tostring(read_err or "nil content"))
    end

    local ok, decoded, decode_err = pcall(function()
        return yaml_mod.decode(content)
    end)
    if not ok then
        return nil, err("INTERNAL", "failed to decode " .. path .. ": " .. tostring(decoded))
    end
    if type(decoded) ~= "table" then
        return nil, err("INTERNAL", "failed to decode " .. path .. ": " .. tostring(decode_err or "not a YAML map"))
    end

    decoded.modules = decoded.modules or {}
    decoded.replacements = decoded.replacements or {}
    return { vol = vol, original = content, doc = decoded }, nil
end

function M.encode(yaml_mod, lock_doc, path)
    path = path or M.LOCK_PATH
    local doc = {}
    for k, v in pairs(lock_doc or {}) do doc[k] = v end
    if type(doc.modules) == "table" and #doc.modules == 0 then doc.modules = nil end
    if type(doc.replacements) == "table" and #doc.replacements == 0 then doc.replacements = nil end

    local encoded, encode_err = yaml_mod.encode(doc, {
        field_order = { "directories", "modules", "replacements", "name", "version", "hash", "from", "to" },
        sort_unordered = true,
    })
    if not encoded then
        return nil, err("INTERNAL", "failed to encode " .. path .. ": " .. tostring(encode_err or "nil content"))
    end
    return encoded, nil
end

function M.write(lock_state, path, content)
    path = path or M.LOCK_PATH
    local ok, result, write_err = pcall(function()
        return fs_writefile(lock_state.vol, path, content)
    end)
    if not ok then
        return nil, err("INTERNAL", "failed to write " .. path .. ": " .. tostring(result))
    end
    if result ~= true then
        return nil, err("INTERNAL", "failed to write " .. path .. ": " .. tostring(write_err or result or "nil result"))
    end
    return { path = path }, nil
end

function M.prepare_install(fs_mod, yaml_mod, fs_id, path, plan)
    path = path or M.LOCK_PATH
    if not plan or #(plan.graph or {}) == 0 then
        return { changed = false, reason = "empty_graph" }, nil
    end

    local state, read_err = M.read(fs_mod, yaml_mod, fs_id, path)
    if not state then return nil, read_err end

    local changes, changes_err = M.apply_install(state.doc, plan.graph)
    if not changes then return nil, changes_err end

    local changed = #(changes.upserted or {}) > 0
    if not changed then
        return {
            changed = false,
            reason = "already_current",
            changes = changes,
        }, nil
    end

    local next_content, encode_err = M.encode(yaml_mod, state.doc, path)
    if not next_content then return nil, encode_err end

    return {
        changed = true,
        operation = "install",
        state = state,
        content = next_content,
        changes = changes,
    }, nil
end

function M.prepare_uninstall(fs_mod, yaml_mod, fs_id, path, plan)
    path = path or M.LOCK_PATH
    local state, read_err = M.read(fs_mod, yaml_mod, fs_id, path)
    if not state then return nil, read_err end

    local changes, changes_err = M.apply_uninstall(
        state.doc,
        plan and plan.keep_modules or {},
        plan and plan.unresolved_modules or {},
        plan and plan.target_module or nil,
        plan and plan.target_modules or nil
    )
    if not changes then return nil, changes_err end

    local changed = #(changes.removed or {}) > 0
    if not changed then
        -- Withheld transitive pruning under uncertainty is not "already absent":
        -- report it honestly so a skipped prune is never mistaken for a no-op.
        if changes.uncertain then
            return {
                changed = false,
                reason = "withheld_uncertain",
                uncertain = true,
                changes = changes,
            }, nil
        end
        return {
            changed = false,
            reason = "already_absent",
            changes = changes,
        }, nil
    end

    local next_content, encode_err = M.encode(yaml_mod, state.doc, path)
    if not next_content then return nil, encode_err end

    return {
        changed = true,
        operation = "uninstall",
        state = state,
        content = next_content,
        uncertain = changes.uncertain == true,
        changes = changes,
    }, nil
end

function M.commit(path, update)
    if not update or update.changed ~= true then
        return update or { changed = false }, nil
    end
    local write_result, write_err = M.write(update.state, path, update.content)
    if not write_result then return nil, write_err end
    return {
        changed = true,
        operation = update.operation,
        path = write_result.path,
        uncertain = update.uncertain == true or (update.changes and update.changes.uncertain == true) or nil,
        changes = update.changes,
    }, nil
end

function M.restore(path, update)
    if not update or not update.state then
        return { changed = false }, nil
    end
    local write_result, write_err = M.write(update.state, path, update.state.original)
    if not write_result then return nil, write_err end
    return { changed = true, path = write_result.path }, nil
end

return M
