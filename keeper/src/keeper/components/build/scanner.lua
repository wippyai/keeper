-- keeper.components.build:scanner
--
-- Walks the project filesystem looking for FE components (package.json with
-- `specification: wippy-component-1.0`) and returns structured descriptors.
-- Also surfaces shared frontend/docs/*.md as kit documentation and
-- static/app/* + static/wc/* as vendored read-only components.

local fs = require("fs")
local json = require("json")
local yaml = require("yaml")

local consts = require("consts")

local M = {}

local MODULE_OWNED_APP_SLUGS = {
    ["keeper/keeper"] = { keeper = true },
}

local function get_fs()
    local vol, err = fs.get(consts.FS.PROJECT_FS_ID)
    if not vol then return nil, "Failed to get project filesystem: " .. (err or "unknown") end
    return vol
end

local function read_json(vol, path)
    local content, err = vol:readfile(path)
    if not content then return nil, err end
    local decoded, jerr = json.decode(content)
    if not decoded then return nil, "json decode failed: " .. (jerr or "unknown") end
    return decoded
end

local function module_owned_app_slugs_from_lock(lock_content)
    local out = {}
    if type(lock_content) ~= "string" or lock_content == "" then return out end

    local ok, decoded = pcall(yaml.decode, lock_content)
    if not ok or type(decoded) ~= "table" or type(decoded.modules) ~= "table" then
        return out
    end

    for _, mod in ipairs(decoded.modules) do
        local name = type(mod) == "table" and mod.name or nil
        local slugs = type(name) == "string" and MODULE_OWNED_APP_SLUGS[name] or nil
        if slugs then
            for slug, blocked in pairs(slugs) do
                if blocked == true then out[slug] = true end
            end
        end
    end

    return out
end

local function module_owned_app_slugs(vol)
    if not vol:exists("wippy.lock") then return {} end

    local content = vol:readfile("wippy.lock")
    return module_owned_app_slugs_from_lock(content)
end

local function is_component_dir_name(name)
    return type(name) == "string"
        and name ~= ""
        and name:find("%s") == nil
        and name:match("^[%w._-]+$") ~= nil
end

local function list_dirs(vol, path)
    if not vol:exists(path) or not vol:isdir(path) then return {} end
    local out = {}
    for entry in vol:readdir(path) do
        if entry.type == "directory" and is_component_dir_name(entry.name) then
            table.insert(out, entry.name)
        end
    end
    table.sort(out)
    return out
end

local function list_md_files_in(vol, dir)
    if not vol:exists(dir) or not vol:isdir(dir) then return {} end
    local out = {}
    for entry in vol:readdir(dir) do
        if entry.type == "file" and entry.name:match("%.md$") then
            table.insert(out, dir .. "/" .. entry.name)
        end
    end
    table.sort(out)
    return out
end

local function normalize_skip_dirs(skip_dirs: unknown): {[string]: boolean}
    local out: {[string]: boolean} = {}
    if type(skip_dirs) ~= "table" then return out end
    for k, v in pairs(skip_dirs) do
        if type(k) == "string" and v == true then out[k] = true end
    end
    return out
end

local function count_dir_bytes(vol, path: string, skip_dirs: unknown)
    if not vol:exists(path) then return 0, nil end
    if not vol:isdir(path) then
        local info = vol:stat(path)
        return (info and info.size) or 0, nil
    end
    local skips = normalize_skip_dirs(skip_dirs)
    local total = 0
    for entry in vol:readdir(path) do
        local child = path .. "/" .. entry.name
        if entry.type == "file" then
            local info = vol:stat(child)
            if info and info.size then total = total + info.size end
        elseif entry.type == "directory" and not skips[entry.name] then
            local sub = count_dir_bytes(vol, child, skips)
            total = total + sub
        end
    end
    return total
end

local function newest_mtime(vol, path: string, skip_dirs: unknown)
    if not vol:exists(path) then return 0 end
    if not vol:isdir(path) then
        local info = vol:stat(path)
        if not info then return 0 end
        local mod = info.modified
        if type(mod) == "number" then return mod end
        return 0
    end
    local skips = normalize_skip_dirs(skip_dirs)
    local best = 0
    for entry in vol:readdir(path) do
        local child = path .. "/" .. entry.name
        if entry.type == "file" then
            local info = vol:stat(child)
            if info and info.modified and type(info.modified) == "number" and info.modified > best then
                best = info.modified
            end
        elseif entry.type == "directory" and not skips[entry.name] then
            local sub = newest_mtime(vol, child, skips)
            if sub > best then best = sub end
        end
    end
    return best
end

-- Thumbnail URL helper. Returns the public path the keeper HTTP server
-- serves the preview PNG at, OR empty string if no preview exists.
local function thumbnail_url(vol, component_slug)
    if not component_slug or component_slug == "" then return "" end
    local rel = consts.PATHS.PREVIEWS_REL .. "/" .. component_slug .. ".png"
    if vol:exists(rel) then
        return consts.URLS.PREVIEWS_PUBLIC .. "/" .. component_slug .. ".png"
    end
    return ""
end

-- Build a prebuilt component descriptor from a built artifact directory
-- inside static/. No package.json is required; we infer what we can.
-- If a .wippy-origin.json manifest exists next to the bundle, use it to
-- populate source linkage (where the bundle was built from).
local function describe_prebuilt(vol, rel_dir, kind_hint)
    if not vol:exists(rel_dir) or not vol:isdir(rel_dir) then return nil end

    local slug = rel_dir:match("[^/]+$") or rel_dir

    -- Package metadata (optional — some bundles ship the package.json).
    local meta_title, meta_desc, meta_version, tag_name, pkg_name = nil, nil, nil, nil, nil
    local pkg_path = rel_dir .. "/package.json"
    if vol:exists(pkg_path) then
        local pkg = read_json(vol, pkg_path)
        if pkg then
            meta_title = (pkg.wippy and pkg.wippy.title) or pkg.title or pkg.name
            meta_desc = pkg.description or (pkg.wippy and pkg.wippy.description)
            meta_version = pkg.version
            tag_name = pkg.wippy and pkg.wippy.tagName
            pkg_name = pkg.name
        end
    end

    -- Origin manifest (optional — links the bundle to its source repo).
    local origin = nil
    local is_main_app = false
    local origin_path = rel_dir .. "/" .. consts.ORIGIN_MANIFEST
    if vol:exists(origin_path) then
        local om = read_json(vol, origin_path)
        if om then
            origin = {
                name = om.name,
                source_path = om.source_path,
                source_repo = om.source_repo,
                upstream_name = om.upstream_name,
                built_at = om.built_at,
                built_from_sha = om.built_from_sha,
            }
            if om.title and not meta_title then meta_title = om.title end
            if om.description and not meta_desc then meta_desc = om.description end
            if om.name and not pkg_name then pkg_name = om.name end
            is_main_app = om.main_app == true
        end
    end
    -- Path-based fallback: static/app/main is the conventional main app.
    if not is_main_app and rel_dir == consts.PATHS.VENDORED_APP_ROOT .. "/main" then
        is_main_app = true
    end

    -- link_kind summarises what we know about this bundle's source:
    --   "manifest" — .wippy-origin.json present, source path known
    --   "none"     — bundle in this repo, no source linkage
    local link_kind = origin and "manifest" or "none"

    -- If the manifest points at a source path that resolves on disk and
    -- contains a wippy-component package.json, we upgrade this bundle to
    -- editable: the build runs against the linked source tree.
    -- Linked sources live under sibling repos (../app-template/...), so
    -- we use the dedicated siblings_fs volume rooted at the parent dir.
    local source_available = false
    local linked_scripts = {}
    local linked_toolchain = ""
    local linked_rel_from_siblings = nil
    if origin and origin.source_path and origin.source_path ~= "" then
        local rel = origin.source_path
        -- Only ../ prefixed paths are valid linked sources.
        if rel:sub(1, 3) == "../" then
            rel = rel:sub(4)
        end
        if rel and rel ~= "" and not rel:find("%.%.") then
            local siblings, serr = fs.get(consts.FS.SIBLINGS_FS_ID)
            if siblings then
                local pkg_rel = rel .. "/package.json"
                if siblings:exists(pkg_rel) then
                    local content, _ = siblings:readfile(pkg_rel)
                    if content then
                        local ok, lp = pcall(json.decode, content)
                        if ok and lp and lp.specification == consts.COMPONENT_SPEC then
                            source_available = true
                            linked_rel_from_siblings = rel
                            local w = lp.wippy or {}
                            local s = w.scripts or {}
                            linked_scripts = {
                                build = s.build,
                                test = s.test,
                                dev = s.dev,
                            }
                            linked_toolchain = w.toolchain or "fe_node"
                            if w.title and not meta_title then meta_title = w.title end
                        end
                    end
                end
            end
        end
    end

    local desc = {
        id = pkg_name or slug,
        kind = kind_hint,
        path = source_available and origin.source_path or rel_dir,
        title = meta_title or slug,
        description = meta_desc or "",
        version = meta_version,
        tag_name = tag_name,
        toolchain = source_available and linked_toolchain or (origin and origin.toolchain or ""),
        scripts = source_available and linked_scripts or {},
        out_dir = rel_dir,
        peer_deps = {},
        dependencies = {},
        editable = source_available,
        link_kind = link_kind,
        is_main_app = is_main_app,
        built = true,
        size_bytes = count_dir_bytes(vol, rel_dir, {}),
        last_built = newest_mtime(vol, rel_dir, {}),
        source_bytes = 0,
        source_mtime = 0,
        docs = {},
        readme_path = nil,
        thumbnail_url = thumbnail_url(vol, slug),
        origin = origin,
        linked_source_rel = linked_rel_from_siblings,
    }

    -- If linked source is usable, compute source stats via the siblings FS.
    if source_available and type(linked_rel_from_siblings) == "string" then
        local siblings = fs.get(consts.FS.SIBLINGS_FS_ID)
        if siblings then
            desc.source_bytes = count_dir_bytes(siblings, linked_rel_from_siblings, consts.SOURCE_SKIP_DIRS)
            desc.source_mtime = newest_mtime(siblings, linked_rel_from_siblings, consts.SOURCE_SKIP_DIRS)
        end
    end

    -- README may ship inside a prebuilt bundle.
    for _, name in ipairs({ "README.md", "readme.md", "Readme.md" }) do
        local p = rel_dir .. "/" .. name
        if vol:exists(p) then
            desc.readme_path = p
            break
        end
    end

    return desc
end

-- Given a component directory, read its package.json and return a descriptor
-- if it's a wippy component; otherwise return nil.
local function describe_component(vol, rel_dir, kind_hint)
    local pkg_path = rel_dir .. "/package.json"
    if not vol:exists(pkg_path) then return nil end

    local pkg, err = read_json(vol, pkg_path)
    if not pkg then return nil end
    if pkg.specification ~= consts.COMPONENT_SPEC then return nil end

    local wippy = pkg.wippy or {}
    local scripts = wippy.scripts or {}

    local slug = rel_dir:match("[^/]+$") or pkg.name

    local desc = {
        id = pkg.name,
        kind = kind_hint,
        path = rel_dir,
        title = wippy.title or pkg.title or pkg.name,
        description = pkg.description or wippy.description or "",
        version = pkg.version,
        tag_name = wippy.tagName,
        props_schema = wippy.props,
        toolchain = wippy.toolchain or "fe_node",
        scripts = {
            build = scripts.build,
            test = scripts.test,
            dev = scripts.dev,
        },
        out_dir = wippy.outDir,
        peer_deps = pkg.peerDependencies or {},
        dependencies = pkg.dependencies or {},
        editable = true,
        link_kind = "local",
        is_main_app = false,
        thumbnail_url = thumbnail_url(vol, slug),
        origin = nil,
    }

    -- Infer output directory if not declared. Try multiple conventions,
    -- pick the first that exists on disk; otherwise fall back to the
    -- canonical default so the UI at least shows where it *should* build to.
    local canonical = kind_hint == "app" and ("static/app/" .. slug) or ("static/wc/" .. slug)
    if not desc.out_dir then
        local candidates = {}
        if kind_hint == "app" then
            table.insert(candidates, "static/app/" .. slug)
            table.insert(candidates, "static/" .. slug)  -- e.g. static/keeper
        else
            table.insert(candidates, "static/wc/" .. slug)
            table.insert(candidates, "static/" .. slug)
        end
        for _, p in ipairs(candidates) do
            if vol:exists(p) and vol:isdir(p) then
                desc.out_dir = p
                break
            end
        end
        if not desc.out_dir then desc.out_dir = canonical end
    end

    -- Build stats from the out_dir (if the build has run once).
    desc.built = vol:exists(desc.out_dir) and vol:isdir(desc.out_dir)
    desc.size_bytes = 0
    desc.last_built = 0
    if desc.built then
        desc.size_bytes = count_dir_bytes(vol, desc.out_dir, {})
        desc.last_built = newest_mtime(vol, desc.out_dir, {})
    end

    -- Source stats (excluding node_modules / dist / caches).
    desc.source_bytes = count_dir_bytes(vol, rel_dir, consts.SOURCE_SKIP_DIRS)
    desc.source_mtime = newest_mtime(vol, rel_dir, consts.SOURCE_SKIP_DIRS)

    -- Per-component markdown docs.
    desc.docs = list_md_files_in(vol, rel_dir)

    -- README at the top level (case-insensitive match on common variants).
    for _, name in ipairs({ "README.md", "readme.md", "Readme.md" }) do
        local p = rel_dir .. "/" .. name
        if vol:exists(p) then
            desc.readme_path = p
            break
        end
    end

    return desc
end

-- Scan all components and kit docs. Returns a structured result.
function M.scan()
    local vol, err = get_fs()
    if not vol then return nil, err end
    local blocked_local_apps = module_owned_app_slugs(vol)

    local result = {
        applications = {},
        widgets = {},
        kit_docs = {},
        scan_root = "./",
        scanned_at = os.time(),
    }

    local seen_editable_slugs = {}

    -- Editable applications (source in frontend/applications)
    for _, name in ipairs(list_dirs(vol, consts.PATHS.APP_ROOT)) do
        if not blocked_local_apps[name] then
            local desc = describe_component(vol, consts.PATHS.APP_ROOT .. "/" .. name, "app")
            if desc then
                table.insert(result.applications, desc)
                seen_editable_slugs[name] = true
            end
        end
    end

    -- Editable widgets (source in frontend/web-components)
    for _, name in ipairs(list_dirs(vol, consts.PATHS.WC_ROOT)) do
        local desc = describe_component(vol, consts.PATHS.WC_ROOT .. "/" .. name, "widget")
        if desc then
            table.insert(result.widgets, desc)
            seen_editable_slugs[name] = true
        end
    end

    -- Editable components owned by local modules. A module keeps the same
    -- frontend layout as the host app, rooted at plugins/<module>/frontend.
    for _, plugin in ipairs(list_dirs(vol, consts.PATHS.PLUGIN_ROOT)) do
        local plugin_app_root = consts.PATHS.PLUGIN_ROOT .. "/" .. plugin .. "/frontend/applications"
        for _, name in ipairs(list_dirs(vol, plugin_app_root)) do
            local rel = plugin_app_root .. "/" .. name
            local desc = describe_component(vol, rel, "app")
            if desc then
                table.insert(result.applications, desc)
                seen_editable_slugs[name] = true
            end
        end

        local plugin_wc_root = consts.PATHS.PLUGIN_ROOT .. "/" .. plugin .. "/frontend/web-components"
        for _, name in ipairs(list_dirs(vol, plugin_wc_root)) do
            local rel = plugin_wc_root .. "/" .. name
            local desc = describe_component(vol, rel, "widget")
            if desc then
                table.insert(result.widgets, desc)
                seen_editable_slugs[name] = true
            end
        end
    end

    -- Vendored applications in static/app/* (read-only bundles)
    for _, name in ipairs(list_dirs(vol, consts.PATHS.VENDORED_APP_ROOT)) do
        if not seen_editable_slugs[name] and not blocked_local_apps[name] then
            local desc = describe_prebuilt(vol, consts.PATHS.VENDORED_APP_ROOT .. "/" .. name, "app")
            if desc then table.insert(result.applications, desc) end
        end
    end

    -- Vendored widgets in static/wc/* (read-only bundles)
    for _, name in ipairs(list_dirs(vol, consts.PATHS.VENDORED_WC_ROOT)) do
        if not seen_editable_slugs[name] then
            local desc = describe_prebuilt(vol, consts.PATHS.VENDORED_WC_ROOT .. "/" .. name, "widget")
            if desc then table.insert(result.widgets, desc) end
        end
    end

    local function rank(c)
        if c.is_main_app then return 0 end
        if c.editable then return 1 end
        return 2
    end
    local function cmp(a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        return (a.title or a.id) < (b.title or b.id)
    end
    table.sort(result.applications, cmp)
    table.sort(result.widgets, cmp)

    -- Kit docs at frontend/docs/*.md
    result.kit_docs = list_md_files_in(vol, consts.PATHS.DOCS_ROOT)

    return result
end

-- Find a single component descriptor by its package name or slug.
function M.get(component_id)
    local result, err = M.scan()
    if not result then return nil, err end
    for _, c in ipairs(result.applications) do
        if c.id == component_id then return c end
    end
    for _, c in ipairs(result.widgets) do
        if c.id == component_id then return c end
    end
    return nil, "component not found: " .. tostring(component_id)
end

-- Read a markdown file from the project filesystem. Guards against path
-- traversal and restricts reads to the frontend tree.
function M.read_doc(rel_path)
    if type(rel_path) ~= "string" or rel_path == "" then
        return nil, "rel_path required"
    end
    if rel_path:find("%.%.") then return nil, "invalid path" end
    if not rel_path:match("^frontend/") then return nil, "only frontend docs are readable" end
    if not rel_path:match("%.md$") then return nil, "only markdown files are readable" end

    local vol, err = get_fs()
    if not vol then return nil, err end

    if not vol:exists(rel_path) then return nil, "file not found: " .. rel_path end
    return vol:readfile(rel_path)
end

M._test = {
    module_owned_app_slugs_from_lock = module_owned_app_slugs_from_lock,
    is_component_dir_name = is_component_dir_name,
}

return M
