local security = require("security")
local hub = require("hub")
local audit = require("audit")
local helpers = require("helpers")

local M = {}
local TOOL_ID = "keeper.hub.tools:catalog"
local DEFAULT_PAGE_SIZE = 30

local function positive_integer(value, fallback, maximum)
    local number = tonumber(value)
    if not number or number < 1 then number = fallback end
    number = math.floor(number)
    if maximum and number > maximum then number = maximum end
    return number
end

type CatalogDeps = {
    hub: unknown?,
}

function M._handle(input: unknown?, deps: CatalogDeps?)
    local normalized, input_err = helpers.input_table(input)
    if not normalized then return nil, input_err end
    input = normalized
    deps = deps or {}
    local args = input :: any
    local sdk = (deps.hub or hub) :: any
    local action = args.action

    if action == "browse" then
        local page = positive_integer(args.page, 1)
        local page_size = positive_integer(args.page_size, DEFAULT_PAGE_SIZE, 100)
        local options = {
            page = page,
            page_size = page_size,
        }
        if args.visibility and args.visibility ~= "" then options.visibility = args.visibility end
        if args.type and args.type ~= "" then options.type = args.type end
        if args.sort and args.sort ~= "" then options.sort_order = args.sort end

        local result, err
        local query = args.query
        if query and query ~= "" then
            result, err = sdk.modules.search(query, options)
        else
            result, err = sdk.modules.list(options)
        end
        if not result then return nil, err end
        return {
            items = result.items or {},
            total = result.total or 0,
            page = result.page or page,
            page_size = result.page_size or page_size,
            query = query or "",
        }, nil
    end

    if action == "versions" then
        local component = args.component
        if not component or component == "" then return nil, "component is required" end
        local page = positive_integer(args.page, 1)
        local page_size = positive_integer(args.page_size, DEFAULT_PAGE_SIZE, 100)
        local result, err = sdk.versions.list(component, {
            page = page,
            page_size = page_size,
        })
        if not result then return nil, err end
        return {
            items = result.items or {},
            total = result.total or 0,
            page = result.page or page,
            page_size = result.page_size or page_size,
            component = component,
        }, nil
    end

    if action == "readme" then
        local component = args.component
        if not component or component == "" then return nil, "component is required" end
        local options = {}
        if args.version and args.version ~= "" then options.version = args.version end
        local result, err = sdk.modules.readme(component, options)
        if not result then return nil, err end
        return {
            content = result.content or "",
            filename = result.filename or "",
            version = result.version or args.version or "",
            component = component,
        }, nil
    end

    return nil, "unknown Hub catalog action: " .. tostring(action)
end

local function handler(input)
    local allowed, access_err = helpers.require_access(security, TOOL_ID)
    if not allowed then return nil, access_err end
    local normalized, input_err = helpers.input_table(input)
    if not normalized then return nil, input_err end
    input = normalized

    return audit.wrap({
        tool = "hub_catalog",
        discriminator = "hub_catalog." .. tostring(input.action or "unknown"),
        target = input.component or input.query,
        params = {
            action = input.action,
            component = input.component,
            version = input.version,
            query = input.query,
            page = input.page,
            page_size = input.page_size,
        },
        summarise = function(result, err)
            if err then return "Hub catalog operation failed" end
            if type(result) ~= "table" then return "Hub catalog operation" end
            if input.action == "browse" then
                return "found " .. tostring(result.total or 0) .. " Hub components"
            elseif input.action == "versions" then
                return "found " .. tostring(result.total or 0) .. " Hub component versions"
            elseif input.action == "readme" then
                return "read Hub component documentation"
            end
            return "Hub catalog operation"
        end,
    }, function()
        local result, err = M._handle(input)
        if not result then return nil, helpers.service_error(err, "Hub catalog operation failed") end
        return result, nil
    end)
end

return { handler = handler, _handle = M._handle }
