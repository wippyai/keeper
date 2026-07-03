local hub = require("hub")

type EntryId = { ns?: string, name?: string }
type EntryMeta = { comment?: string }
type VersionEntry = {
    id?: EntryId,
    kind?: string,
    meta?: EntryMeta,
}
type VersionEntries = {
    items?: { VersionEntry },
    total?: number,
    version?: string,
    digest?: string,
    cache_path?: string,
}

type EntriesOpts = { include_data?: boolean, kind?: string }
type HubVersionsExt = { entries: (string, string, EntriesOpts?) -> (VersionEntries?, unknown?) }
type HubExt = { versions: HubVersionsExt }

type ListArgs = { module?: string, version?: string }
type EntrySummary = {
    id: string,
    name: string,
    kind?: string,
    comment?: string,
}
type NamespaceGroup = {
    namespace: string,
    entries: { EntrySummary },
}
type ListResult = {
    module: string,
    version: string,
    digest?: string,
    total?: number,
    namespaces: { NamespaceGroup },
}

local hub_ext = hub :: HubExt

local function trim(s: unknown): string
    return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1"))
end

local function handler(args: ListArgs?): (ListResult?, string?)
    args = args or {}
    local module = trim(args.module)
    local version = trim(args.version)
    if module == "" then return nil, "module is required (org/name)" end
    if version == "" then return nil, "version is required" end

    local res, err = hub_ext.versions.entries(module, version, {
        include_data = false,
    })
    if not res then
        return nil, "failed to list source for " .. module .. "@" .. version .. ": " .. tostring(err)
    end

    local by_ns: {[string]: NamespaceGroup} = {}
    local order: { string } = {}
    for _, item in ipairs(res.items or {}) do
        local id = item.id or {}
        local ns = tostring(id.ns or "")
        local g = by_ns[ns]
        if not g then
            g = { namespace = ns, entries = {} }
            by_ns[ns] = g
            order[#order + 1] = ns
        end
        g.entries[#g.entries + 1] = {
            id = ns .. ":" .. tostring(id.name or ""),
            name = tostring(id.name or ""),
            kind = item.kind,
            comment = item.meta and item.meta.comment or nil,
        }
    end
    table.sort(order)
    local namespaces: { NamespaceGroup } = {}
    for _, ns in ipairs(order) do
        local g = by_ns[ns]
        if g then namespaces[#namespaces + 1] = g end
    end

    return {
        module = module,
        version = res.version or version,
        digest = res.digest,
        total = res.total,
        namespaces = namespaces,
    }
end

return { handler = handler }
