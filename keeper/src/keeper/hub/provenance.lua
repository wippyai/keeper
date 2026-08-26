local M = {}

local Index = {}
Index.__index = Index

local function trim(value: unknown): string
    return type(value) == "string" and (value :: string):match("^%s*(.-)%s*$") or ""
end

-- Registry-owned provenance is the sole authority for which module owns an
-- entry. Ownership is read from ONE registry snapshot: the snapshot captures
-- entries and their provenance in a single consistent read, so a dynamic
-- install or uninstall landing mid-scan can never produce a mixed inventory.
-- Entry metadata is never consulted -- the runtime does not carry ownership
-- there, and a fallback would silently resurrect the stale model.
function M.new(registry_module)
    return setmetatable({
        registry = registry_module,
        snapshot = nil,
        by_module = nil,
        by_id = nil,
    }, Index)
end

-- Capture one atomic state and hold it for the caller's lifetime, so one
-- inventory, planning, or uninstall operation cannot mix registry versions.
function Index:capture()
    if self.snapshot then return self.snapshot, nil end
    local reader = self.registry.snapshot
    if type(reader) ~= "function" then
        return nil, "registry does not serve snapshots"
    end
    local snapshot, snap_err = reader()
    if snap_err then return nil, "registry.snapshot failed: " .. tostring(snap_err) end
    if not snapshot then return nil, "registry.snapshot returned no snapshot" end
    local state_reader = snapshot.state
    if type(state_reader) ~= "function" then
        return nil, "registry snapshot does not serve atomic provenance state; " ..
            "this runtime predates snapshot:state()"
    end
    local state, state_err = state_reader(snapshot)
    if state_err then return nil, "registry snapshot state failed: " .. tostring(state_err) end
    if type(state) ~= "table" or type(state.entries) ~= "table" or type(state.provenance) ~= "table" then
        return nil, "registry snapshot returned malformed provenance state"
    end
    self.snapshot = {
        entries = state.entries,
        provenance = state.provenance,
    }
    return self.snapshot, nil
end

-- Group every entry in the captured snapshot under its provenance module.
function Index:load()
    if self.by_module then return self.by_module, self.by_id, nil end

    local snapshot, capture_err = self:capture()
    if not snapshot then return nil, nil, capture_err end

    local by_module = {}
    local by_id = {}
    for _, row in ipairs(snapshot.entries) do
        local id = tostring(row.id)
        local p = snapshot.provenance[id]
        if type(p) ~= "table" then
            return nil, nil, "registry snapshot has no provenance for " .. id
        end
        local name = trim(p.module)
        local version = trim(p.version)
        by_id[id] = {
            module = name,
            version = version,
            digest = trim(p.digest),
            root = p.root == true,
        }
        if name ~= "" then
            local bucket = by_module[name]
            if not bucket then
                bucket = { entries = {}, version = "" }
                by_module[name] = bucket
            end
            table.insert(bucket.entries, row)
            if version ~= "" and bucket.version == "" then bucket.version = version end
        end
    end

    for _, bucket in pairs(by_module) do
        table.sort(bucket.entries, function(a, b) return tostring(a.id) < tostring(b.id) end)
    end

    self.by_module = by_module
    self.by_id = by_id
    return by_module, by_id, nil
end

-- Every entry the module owns, ordered by id. The returned list is a fresh
-- table: the snapshot's own slices are never handed out or reordered.
function Index:entries_for(component)
    local by_module, _, load_err = self:load()
    if not by_module then return nil, load_err end
    local bucket = by_module[trim(component)]
    if not bucket then return {}, nil end
    local out = {}
    for _, entry in ipairs(bucket.entries) do table.insert(out, entry) end
    return out, nil
end

-- Resolved version of an installed module, or "" when provenance carries none.
function Index:version_of(component)
    local by_module, _, load_err = self:load()
    if not by_module then return nil, load_err end
    local bucket = by_module[trim(component)]
    return bucket and bucket.version or "", nil
end

-- True when provenance attributes at least one resident entry to the module.
function Index:is_installed(component)
    local entries, entries_err = self:entries_for(component)
    if not entries then return nil, entries_err end
    return #entries > 0, nil
end

-- Owning module and version of a single entry.
function Index:owner_of(id)
    local _, by_id, load_err = self:load()
    if not by_id then return nil, nil, load_err end
    local p = by_id[tostring(id)]
    if not p then return "", "", nil end
    return p.module, p.version, nil
end

-- True only when the registry marked this exact dependency entry as a
-- deployment root. Namespace placement is an authorization concern, not root
-- evidence.
function Index:root_of(id)
    local _, by_id, load_err = self:load()
    if not by_id then return nil, load_err end
    local p = by_id[tostring(id)]
    return p ~= nil and p.root == true, nil
end

-- Installed module name -> resolved version, for inventory listings.
function Index:module_versions()
    local by_module, _, load_err = self:load()
    if not by_module then return nil, load_err end
    local out = {}
    for name, bucket in pairs(by_module) do out[name] = bucket.version end
    return out, nil
end

-- Entries the module owns, narrowed to one registry kind.
function Index:entries_of_kind(component, kind)
    local entries, entries_err = self:entries_for(component)
    if not entries then return nil, entries_err end
    local out = {}
    for _, entry in ipairs(entries) do
        if entry.kind == kind then table.insert(out, entry) end
    end
    return out, nil
end

return M
