local M = {}

local Index = {}
Index.__index = Index

local function trim(value: unknown): string
    return type(value) == "string" and (value :: string):match("^%s*(.-)%s*$") or ""
end

-- Ownership is read from one registry snapshot, so a dynamic install or
-- uninstall cannot produce a mixed inventory. Current runtimes attach
-- registry-owned metadata to each state entry. During rollout, released
-- runtimes may instead return the same ownership in the snapshot's atomic
-- provenance map. Author metadata is never an ownership source.
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
        return nil, "registry snapshot does not serve atomic ownership state; " ..
            "this runtime predates snapshot:state()"
    end
    local state, state_err = state_reader(snapshot)
    if state_err then return nil, "registry snapshot state failed: " .. tostring(state_err) end
    if type(state) ~= "table" or type(state.entries) ~= "table" then
        return nil, "registry snapshot returned malformed ownership state"
    end
    self.snapshot = {
        entries = state.entries,
        provenance = state.provenance,
        resolution = state.resolution,
    }
    return self.snapshot, nil
end

local function resolved_versions(resolution)
    local versions = {}
    if type(resolution) ~= "table" or type(resolution.modules) ~= "table" then
        return versions
    end
    for _, module in ipairs(resolution.modules) do
        local name = trim(module and module.name)
        if name ~= "" then versions[name] = trim(module.version) end
    end
    return versions
end

local function entry_ownership(snapshot, row)
    if type(row.registry) == "table" then
        return trim(row.registry.owner), row.registry.root == true, ""
    end
    if type(snapshot.provenance) == "table" then
        local record = snapshot.provenance[tostring(row.id)]
        if type(record) ~= "table" then
            return nil, nil, "registry snapshot has no ownership for " .. tostring(row.id)
        end
        return trim(record.module), record.root == true, trim(record.version)
    end
    return nil, nil, "registry snapshot entry has no registry ownership for " .. tostring(row.id)
end

-- Group every entry in the captured snapshot under its owning module.
function Index:load()
    if self.by_module then return self.by_module, self.by_id, nil end

    local snapshot, capture_err = self:capture()
    if not snapshot then return nil, nil, capture_err end

    local by_module = {}
    local by_id = {}
    local versions = resolved_versions(snapshot.resolution)
    for _, row in ipairs(snapshot.entries) do
        local id = tostring(row.id)
        local name, root, map_version = entry_ownership(snapshot, row)
        if name == nil then return nil, nil, map_version end
        local version = versions[name] or map_version
        by_id[id] = {
            module = name,
            version = version,
            root = root,
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

-- Resolved version of an installed module, or "" when the snapshot carries none.
function Index:version_of(component)
    local by_module, _, load_err = self:load()
    if not by_module then return nil, load_err end
    local bucket = by_module[trim(component)]
    return bucket and bucket.version or "", nil
end

-- True when ownership attributes at least one resident entry to the module.
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
