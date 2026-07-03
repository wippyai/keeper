local hub = require("hub")

type EntryId = { ns?: string, name?: string }
type EntryMeta = { comment?: string }
type EntryData = { source?: string }
type VersionEntry = {
    id?: EntryId,
    kind?: string,
    meta?: EntryMeta,
    data?: EntryData,
}
type VersionEntries = {
    items?: { VersionEntry },
    version?: string,
}

type EntriesOpts = { include_data?: boolean, kind?: string }
type HubVersionsExt = { entries: (string, string, EntriesOpts?) -> (VersionEntries?, unknown?) }
type HubExt = { versions: HubVersionsExt }

type ReadArgs = {
    module?: string,
    version?: string,
    namespace?: string,
    names?: { string },
}
type ReadEntry = {
    id: string,
    kind?: string,
    comment?: string,
    source: string,
}
type ReadResult = {
    module: string,
    version: string,
    namespace: string,
    entries: { ReadEntry },
}

local hub_ext = hub :: HubExt

local function trim(s: unknown): string
    return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1"))
end

local function handler(args: ReadArgs?): (ReadResult?, string?)
    args = args or {}
    local module = trim(args.module)
    local version = trim(args.version)
    if module == "" then return nil, "module is required (org/name)" end
    if version == "" then return nil, "version is required" end
    local namespace = trim(args.namespace)
    if namespace == "" then return nil, "namespace is required (use list_module_namespaces first)" end

    local name_set: {[string]: boolean}? = nil
    if type(args.names) == "table" and #args.names > 0 then
        name_set = {}
        for _, n in ipairs(args.names) do name_set[tostring(n)] = true end
    end

    local res, err = hub_ext.versions.entries(module, version, {
        include_data = true,
    })
    if not res then
        return nil, "failed to read source for " .. module .. "@" .. version .. ": " .. tostring(err)
    end

    local out: { ReadEntry } = {}
    for _, item in ipairs(res.items or {}) do
        local id = item.id or {}
        local name = tostring(id.name or "")
        if tostring(id.ns or "") == namespace and (not name_set or name_set[name]) then
            local data = item.data or {}
            out[#out + 1] = {
                id = namespace .. ":" .. name,
                kind = item.kind,
                comment = item.meta and item.meta.comment or nil,
                source = type(data.source) == "string" and data.source or "",
            }
        end
    end

    if #out == 0 then
        return nil, "no entries in namespace '" .. namespace .. "' for " .. module .. "@" .. version
    end

    return {
        module = module,
        version = res.version or version,
        namespace = namespace,
        entries = out,
    }
end

return { handler = handler }
