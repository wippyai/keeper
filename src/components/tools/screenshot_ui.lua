local audit = require("audit")
local ui = require("ui")
local scanner = require("scanner")
local helpers = require("comp_helpers")

local function slug_for(desc, component_id, explicit_name)
    if explicit_name and explicit_name ~= "" then
        return explicit_name:gsub("[^%w%-_]", "_")
    end
    if desc and desc.path then
        local tail = desc.path:match("[^/]+$")
        if tail and tail ~= "" then return tail end
    end
    return (component_id or "shot"):gsub("[^%w]", "_")
end

local function mint_token()
    return helpers.mint_token("screenshot_ui")
end

local function do_handler(params)
    params = params or {}
    local component_id = params.component_id
    if type(component_id) ~= "string" or component_id == "" then
        return nil, "component_id is required"
    end

    local desc, derr = scanner.get(component_id)
    if not desc then
        return nil, "component not found: " .. tostring(derr or component_id)
    end

    local token, terr = mint_token()
    if terr then return nil, terr end

    local open_res = ui.open({
        component_id = component_id,
        route        = params.route,
        auth_token   = token,
    })
    if not open_res or not open_res.success then
        return nil, "ui open failed: " .. ((open_res and open_res.error) or "unknown")
    end

    if params.wait_for and params.wait_for ~= "" then
        local w = ui.wait_for(params.wait_for, { timeout = tonumber(params.wait_timeout_ms) or 10000 })
        if not w or not w.success then
            return nil, "wait_for failed: " .. ((w and w.error) or "unknown")
        end
    end

    local slug = slug_for(desc, component_id, params.name)
    local shot = ui.screenshot({
        name     = slug,
        full     = params.full == true,
        selector = params.selector,
    })
    if not shot or not shot.success then
        return nil, "screenshot failed: " .. ((shot and shot.error) or "unknown")
    end

    return {
        component_id   = component_id,
        route          = params.route,
        screenshot_url = shot.url,
        captured_at    = os.time(),
    }
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "screenshot_ui",
        discriminator = "screenshot_ui",
        target        = params.component_id,
        params        = { component_id = params.component_id, route = params.route, name = params.name },
        summarise = function(result, err)
            if err then return "screenshot failed: " .. tostring(err) end
            if type(result) == "table" and result.screenshot_url then
                return "captured " .. tostring(result.screenshot_url)
            end
            return "captured " .. (params.component_id or "?")
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
