local branch_ctx = require("branch_ctx")
local entry_lib = require("entry_lib")
local state_reader = require("state_reader")
local yaml = require("yaml")

local extract_namespace = entry_lib.extract_namespace
local extract_name = entry_lib.extract_name

local function handler()
    local branches = branch_ctx.get_active_branch_chain()

    local routers_reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return "Error: " .. err
    end

    routers_reader = routers_reader:with_kinds("http.router"):include_chunks()
    local routers, err = routers_reader:all()
    if err then
        return "Error: " .. err
    end

    local endpoints_reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return "Error: " .. err
    end

    endpoints_reader = endpoints_reader:with_kinds("http.endpoint"):include_chunks()
    local endpoints, err = endpoints_reader:all()
    if err then
        return "Error: " .. err
    end

    local router_map = {}

    for _, router in ipairs(routers) do
        if router.chunks then
            for _, chunk in ipairs(router.chunks) do
                if chunk.type == "definition" then
                    local parsed = yaml.decode(chunk.content)
                    if parsed and parsed.entries then
                        local router_name = extract_name(router.id)
                        for _, entry_def in ipairs(parsed.entries) do
                            if entry_def.name == router_name then
                                local middleware = {}
                                if entry_def.middleware and type(entry_def.middleware) == "table" then
                                    middleware = entry_def.middleware
                                end

                                router_map[router.id] = {
                                    id = router.id,
                                    prefix = entry_def.prefix or "",
                                    server = entry_def.meta and entry_def.meta.server or "",
                                    middleware = middleware,
                                    endpoints = {}
                                }
                                break
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    for _, endpoint in ipairs(endpoints) do
        if endpoint.chunks then
            for _, chunk in ipairs(endpoint.chunks) do
                if chunk.type == "definition" then
                    local parsed = yaml.decode(chunk.content)
                    if parsed and parsed.entries then
                        local endpoint_name = extract_name(endpoint.id)
                        for _, entry_def in ipairs(parsed.entries) do
                            if entry_def.name == endpoint_name then
                                local router_id = entry_def.meta and entry_def.meta.router

                                if router_id and router_map[router_id] then
                                    local func_id = entry_def.func or ""
                                    if func_id ~= "" and not func_id:find(":") then
                                        local endpoint_ns = extract_namespace(endpoint.id)
                                        if endpoint_ns then
                                            func_id = endpoint_ns .. ":" .. func_id
                                        end
                                    end

                                    table.insert(router_map[router_id].endpoints, {
                                        id = endpoint.id,
                                        method = entry_def.method or "",
                                        path = entry_def.path or "",
                                        func_id = func_id,
                                        comment = entry_def.meta and entry_def.meta.comment or ""
                                    })
                                end
                                break
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    local sorted_routers = {}
    for _, router in pairs(router_map) do
        table.sort(router.endpoints, function(a, b)
            return a.id < b.id
        end)
        table.insert(sorted_routers, router)
    end
    table.sort(sorted_routers, function(a, b)
        return a.id < b.id
    end)

    local lines = {}
    table.insert(lines, "HTTP ENDPOINTS")
    table.insert(lines, "")

    for _, router in ipairs(sorted_routers) do
        local header = router.id .. " [" .. router.prefix .. "]"
        if router.server ~= "" then
            header = header .. " -> " .. router.server
        end
        table.insert(lines, header)

        if #router.middleware > 0 then
            table.insert(lines, "  Middleware: " .. table.concat(router.middleware, ", "))
        end

        if #router.endpoints > 0 then
            table.insert(lines, "")
            for _, endpoint in ipairs(router.endpoints) do
                local full_path = router.prefix .. endpoint.path
                full_path = full_path:gsub("//+", "/")

                table.insert(lines, "  " .. endpoint.id)
                table.insert(lines, "    " .. endpoint.method .. " " .. full_path)
                if endpoint.comment and endpoint.comment ~= "" then
                    table.insert(lines, "    comment: " .. endpoint.comment)
                end
                if endpoint.func_id ~= "" then
                    table.insert(lines, "    func_id: " .. endpoint.func_id)
                end
            end
        end

        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
