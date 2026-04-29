local fs = require("fs")

local FE_VOLUME = "keeper.components:fe_fs"
local ROUTER_PATH = "applications/keeper/src/router/index.ts"
local PAGES_DIR = "applications/keeper/src/pages"
local COMPONENTS_DIR = "applications/keeper/src/components"

local function open_fe()
    local vol, err = fs.get(FE_VOLUME)
    if err then return nil, err end
    return vol, nil
end

local function parse_routes(source)
    local entries = {}
    local block_pattern =
        "path:%s*['\"]([^'\"]*)['\"]" ..
        ".-name:%s*['\"]([^'\"]*)['\"]" ..
        ".-import%(%s*['\"]%.%./pages/([^'\"]+)['\"]"
    for path, name, page in source:gmatch(block_pattern) do
        table.insert(entries, { path = path, name = name, page = page })
    end
    return entries
end

local function list_dir(vol, rel_path)
    if not vol:exists(rel_path) then return nil end
    local entries, err = vol:readdir(rel_path)
    if err or type(entries) ~= "table" then return nil end
    local files, dirs = {}, {}
    for _, entry in ipairs(entries) do
        local name = entry.name or entry
        local is_dir = entry.is_dir
        if is_dir == nil and type(entry) == "string" then
            is_dir = vol:isdir(rel_path .. "/" .. name)
        end
        if is_dir then
            table.insert(dirs, name)
        else
            table.insert(files, name)
        end
    end
    table.sort(files)
    table.sort(dirs)
    return { files = files, dirs = dirs }
end

local function handler()
    local vol, err = open_fe()
    if err then
        return "Error: fe_fs open failed: " .. tostring(err)
    end

    local lines = { "# FRONTEND TREE (keeper SPA)", "" }
    lines[#lines + 1] = "Component id: `@wippy/app-keeper` (built to `static/keeper/`)"
    lines[#lines + 1] = "Base path: `frontend/applications/keeper/src/`"
    lines[#lines + 1] = ""

    lines[#lines + 1] = "## Routes (from router/index.ts)"
    lines[#lines + 1] = ""
    local router_src, r_err = vol:readfile(ROUTER_PATH)
    if r_err or not router_src then
        lines[#lines + 1] = "_router file unreadable: " .. tostring(r_err) .. "_"
    else
        local routes = parse_routes(router_src)
        if #routes == 0 then
            lines[#lines + 1] = "_no routes matched_"
        else
            for _, r in ipairs(routes) do
                lines[#lines + 1] = string.format("- `%s` → `pages/%s` (name=%s)", r.path, r.page, r.name)
            end
        end
    end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "## Pages (pages/*.vue)"
    lines[#lines + 1] = ""
    local pages = list_dir(vol, PAGES_DIR)
    if not pages then
        lines[#lines + 1] = "_pages dir not found_"
    else
        for _, f in ipairs(pages.files) do
            lines[#lines + 1] = "- " .. f
        end
    end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "## Components (components/ top level)"
    lines[#lines + 1] = ""
    local comps = list_dir(vol, COMPONENTS_DIR)
    if not comps then
        lines[#lines + 1] = "_components dir not found_"
    else
        for _, d in ipairs(comps.dirs) do
            lines[#lines + 1] = "- " .. d .. "/"
        end
        for _, f in ipairs(comps.files) do
            lines[#lines + 1] = "- " .. f
        end
    end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "## Conventions"
    lines[#lines + 1] = "- Edits flow through `fs` tool (staged in changeset); path MUST start with `frontend/`."
    lines[#lines + 1] = "- New route = new page file under `pages/` + a block in `router/index.ts`."
    lines[#lines + 1] = "- Preserve filename case exactly (`mix2.vue` != `Mix2.vue`)."
    lines[#lines + 1] = "- Push auto-rebuilds every touched editable component after flush; screenshot after push."

    return table.concat(lines, "\n")
end

return { handler = handler }
