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
    local namespace = trim(args.namespace)
    if namespace == "" then return nil, "namespace is required (use list_module_namespaces first)" end

    local name_set = nil
    if type(args.names) == "table" and #args.names > 0 then
        name_set = {}
        for _, n in ipairs(args.names) do name_set[tostring(n)] = true end
    end

    local pkg, err = hub.versions.open(module, version)
    if not pkg then
        return nil, "failed to open " .. module .. "@" .. version .. ": " .. tostring(err)
    end
    local resolved_version = pkg.version or version
    local entries, eerr = pkg:entries({ include_data = true })
    pkg:close()
    if not entries then
        return nil, "failed to read entries for " .. module .. "@" .. version .. ": " .. tostring(eerr)
    end

    local out = {}
    for _, item in ipairs(entries) do
        local id = registry.parse_id(item.id)
        if id.ns == namespace and (not name_set or name_set[id.name]) then
            local data = item.data or {}
            out[#out + 1] = {
                id = item.id,
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
        version = resolved_version,
        namespace = namespace,
        entries = out,
    }
end

return { handler = handler }
