local floor_catalog = require("floor_catalog")

local M = {}

-- Preflight runtime floor and certified hash verification.
--
-- Authority: CONTRACTS.md §19 line 538, FINAL-DESIGN-v4.md §12.1, §16,
-- and ACCEPTANCE-IDS.md (MIG-09, CMP-01, CMP-02, CMP-03).
--
-- Contract signature:
-- preflight({installed_artifacts, candidate_closure, binary_version, certified_catalog})
--   → (result: {accepted: boolean, blocker?: table}, err?: string)
--
-- Rules:
-- 1. Full closure runtime floors checked before migrations or publication.
-- 2. Unknown hash refused; never assigned a fallback floor.
-- 3. Absent or unparseable floor refused.
-- 4. Incompatible floor (required > binary_version) refused.
-- 5. No pcall; return (value, err).

local function trim(val)
    return string.match(tostring(val or ""), "^%s*(.-)%s*$") or ""
end

function M.parse_version(raw)
    local s = trim(raw)
    if s == "" then
        return nil, "empty version string"
    end
    s = string.gsub(s, "^[vV]", "")
    local maj, min, patch, suffix = string.match(s, "^(%d+)%.(%d+)%.(%d+)(.*)$")
    if not maj then
        maj, min, suffix = string.match(s, "^(%d+)%.(%d+)(.*)$")
        patch = 0
    end
    if not maj then
        return nil, "unparseable version: " .. tostring(raw)
    end
    return {
        major = tonumber(maj) or 0,
        minor = tonumber(min) or 0,
        patch = tonumber(patch) or 0,
        suffix = trim(suffix or ""),
        raw = tostring(raw),
    }, nil
end

local function compare_suffixes(s1, s2)
    if s1 == s2 then return 0 end
    if s1 == "" then
        if string.sub(s2, 1, 1) == "-" then return 1 else return -1 end
    end
    if s2 == "" then
        if string.sub(s1, 1, 1) == "-" then return -1 else return 1 end
    end
    return s1 < s2 and -1 or 1
end

function M.compare_versions(v1, v2)
    local p1, err1 = type(v1) == "table" and v1 or M.parse_version(v1)
    if not p1 then return nil, err1 end
    local p2, err2 = type(v2) == "table" and v2 or M.parse_version(v2)
    if not p2 then return nil, err2 end

    if p1.major ~= p2.major then
        return p1.major < p2.major and -1 or 1
    end
    if p1.minor ~= p2.minor then
        return p1.minor < p2.minor and -1 or 1
    end
    if p1.patch ~= p2.patch then
        return p1.patch < p2.patch and -1 or 1
    end
    return compare_suffixes(p1.suffix, p2.suffix)
end

local function normalize_artifacts_list(input)
    if type(input) ~= "table" then return {} end
    local list = {}
    -- Array of objects or map of key -> object/hash
    local is_array = #input > 0
    if is_array then
        for _, item in ipairs(input) do
            if type(item) == "table" then
                table.insert(list, item)
            elseif type(item) == "string" then
                table.insert(list, { hash = item })
            end
        end
    else
        for k, v in pairs(input) do
            if type(v) == "table" then
                local item = { name = v.name or k, hash = v.hash, version = v.version, min_runtime = v.min_runtime }
                table.insert(list, item)
            elseif type(v) == "string" then
                -- Could be id -> hash or hash -> min_runtime
                if #v == 64 and not string.find(v, "[^0-9a-fA-F]") then
                    table.insert(list, { name = k, hash = v })
                else
                    table.insert(list, { name = k, hash = k, min_runtime = v })
                end
            end
        end
    end
    return list
end

function M.check(args)
    if type(args) ~= "table" then
        return nil, "BAD_REQUEST: preflight args must be a table"
    end

    local catalog = args.certified_catalog or floor_catalog
    local binary_version = trim(args.binary_version)
    local parsed_bin, bin_err
    if binary_version ~= "" then
        parsed_bin, bin_err = M.parse_version(binary_version)
    end

    -- 1. Check installed artifacts closure
    local installed = normalize_artifacts_list(args.installed_artifacts)
    for _, art in ipairs(installed) do
        local id_label = tostring(art.name or art.id or art.module or "artifact")
        local hash = trim(art.hash)

        -- Must have certified floor
        local required_floor, floor_err
        if catalog and catalog.get_floor then
            required_floor, floor_err = catalog.get_floor(art)
        elseif catalog and catalog.lookup and hash ~= "" then
            local entry, lookup_err = catalog.lookup(hash)
            if entry then
                required_floor = entry.min_runtime
            else
                floor_err = lookup_err
            end
        else
            floor_err = "catalog unavailable"
        end

        if not required_floor or required_floor == "" then
            return {
                accepted = false,
                blocker = {
                    code = "UNKNOWN_HASH",
                    reason = "installed artifact '" .. id_label .. "' hash '" .. hash
                        .. "' is not certified in floor catalog; boot refused",
                    artifact = id_label,
                    hash = hash,
                    error = floor_err,
                },
            }, nil
        end

        local parsed_floor, parse_err = M.parse_version(required_floor)
        if not parsed_floor then
            return {
                accepted = false,
                blocker = {
                    code = "UNPARSEABLE_FLOOR",
                    reason = "installed artifact '" .. id_label .. "' requires unparseable floor: "
                        .. tostring(required_floor),
                    artifact = id_label,
                    required_floor = required_floor,
                    error = parse_err,
                },
            }, nil
        end

        if not parsed_bin then
            return {
                accepted = false,
                blocker = {
                    code = "UNKNOWN_BINARY_VERSION",
                    reason = "running binary version is missing or unparseable: " .. tostring(binary_version),
                    artifact = id_label,
                    required_floor = required_floor,
                    binary_version = binary_version,
                    error = bin_err,
                },
            }, nil
        end

        local cmp = M.compare_versions(parsed_bin, parsed_floor)
        if cmp < 0 then
            return {
                accepted = false,
                blocker = {
                    code = "INCOMPATIBLE_RUNTIME_FLOOR",
                    reason = "installed artifact '" .. id_label .. "' requires runtime floor "
                        .. tostring(required_floor) .. ", but running binary is " .. binary_version,
                    artifact = id_label,
                    version = art.version,
                    required_floor = required_floor,
                    binary_version = binary_version,
                },
            }, nil
        end
    end

    -- 2. Check candidate closure
    local candidates = normalize_artifacts_list(args.candidate_closure)
    for _, cand in ipairs(candidates) do
        local mod_label = tostring(cand.module or cand.name or cand.id or "module")
        local required_floor = trim(cand.min_runtime or cand.min_version)

        -- If not declared in manifest, check certified catalog by hash
        if required_floor == "" and trim(cand.hash) ~= "" and catalog and catalog.lookup then
            local entry = catalog.lookup(cand.hash)
            if entry then
                required_floor = trim(entry.min_runtime)
            end
        end

        if required_floor == "" then
            return {
                accepted = false,
                blocker = {
                    code = "ABSENT_FLOOR",
                    reason = "candidate module '" .. mod_label .. "' has absent runtime floor and is not in certified catalog",
                    module = mod_label,
                    version = cand.version,
                    hash = cand.hash,
                },
            }, nil
        end

        local parsed_floor, parse_err = M.parse_version(required_floor)
        if not parsed_floor then
            return {
                accepted = false,
                blocker = {
                    code = "UNPARSEABLE_FLOOR",
                    reason = "candidate module '" .. mod_label .. "' declares unparseable floor: "
                        .. tostring(required_floor),
                    module = mod_label,
                    version = cand.version,
                    required_floor = required_floor,
                    error = parse_err,
                },
            }, nil
        end

        if not parsed_bin then
            return {
                accepted = false,
                blocker = {
                    code = "UNKNOWN_BINARY_VERSION",
                    reason = "running binary version is missing or unparseable: " .. tostring(binary_version),
                    module = mod_label,
                    required_floor = required_floor,
                    binary_version = binary_version,
                    error = bin_err,
                },
            }, nil
        end

        local cmp = M.compare_versions(parsed_bin, parsed_floor)
        if cmp < 0 then
            return {
                accepted = false,
                blocker = {
                    code = "INCOMPATIBLE_RUNTIME_FLOOR",
                    reason = "candidate module '" .. mod_label .. "' requires runtime floor "
                        .. tostring(required_floor) .. ", but running binary is " .. binary_version,
                    module = mod_label,
                    version = cand.version,
                    required_floor = required_floor,
                    binary_version = binary_version,
                },
            }, nil
        end
    end

    return { accepted = true }, nil
end

return M
