local hub = require("hub")
local registry = require("registry")

local function trim(s)
    return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1"))
end

local function handler(args)
    args = args or {}
    local module = trim(args.module)
    local version = trim(args.version)
    if module == "" then return nil, "module is required (org/name)" end
    if version == "" then return nil, "version is required" end

    local pkg, err = hub.versions.open(module, version)
    if not pkg then
        return nil, "failed to open " .. module .. "@" .. version .. ": " .. tostring(err)
    end
    local resolved_version = pkg.version or version
    local digest = pkg.digest
    local entries, eerr = pkg:entries({ include_data = false })
    pkg:close()
    if not entries then
        return nil, "failed to list entries for " .. module .. "@" .. version .. ": " .. tostring(eerr)
    end

    local by_ns = {}
    local order = {}
    for _, item in ipairs(entries) do
        local id = registry.parse_id(item.id)
        local g = by_ns[id.ns]
        if not g then
            g = { namespace = id.ns, entries = {} }
            by_ns[id.ns] = g
            order[#order + 1] = id.ns
        end
        g.entries[#g.entries + 1] = {
            id = item.id,
            name = id.name,
            kind = item.kind,
            comment = item.meta and item.meta.comment or nil,
        }
    end
    table.sort(order)
    local namespaces = {}
    for _, ns in ipairs(order) do namespaces[#namespaces + 1] = by_ns[ns] end

    return {
        module = module,
        version = resolved_version,
        digest = digest,
        total = #entries,
        namespaces = namespaces,
    }
end

return { handler = handler }
