-- keeper.components.api:start_screenshot
--
-- One-shot screenshot endpoint for the frontend thumbnails. Internally:
-- one ui.open + one ui.screenshot through the persistent Playwright
-- session.
--
-- Request body:  { component_id, route?, full?, wait? }
-- Response:      { success, screenshot_url, captured_at, error? }

local http = require("http")

local ui = require("ui")
local scanner = require("scanner")
local security = require("security")
-- Derive a stable slug from the component descriptor so the PNG lands
-- at the same filesystem location the scanner already knows about (e.g.
-- previews/keeper.png). This preserves the thumbnail-by-slug contract.
local function slug_for(desc, component_id)
    if desc and desc.path then
        local tail = desc.path:match("[^/]+$")
        if tail and tail ~= "" then return tail end
    end
    return (component_id or "shot"):gsub("[^%w]", "_")
end

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local body = req:body_json() or {}
    local component_id = body.component_id
    if not component_id or component_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "component_id required" })
        return
    end

    local desc, derr = scanner.get(component_id)
    if not desc then
        res:set_status(http.STATUS.NOT_FOUND)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = derr or "component not found" })
        return
    end

    local open_res = ui.open({
        component_id = component_id,
        route = body.route,
        auth_token = (function()
        local _auth = req:header("Authorization")
        if not _auth then return nil end
        local _tok = _auth:match("[Bb]earer%s+(.+)")
        if _tok and _tok ~= "" then return _tok end
        return nil
    end)(),
    })
    if not open_res or not open_res.success then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = (open_res and open_res.error) or "ui open failed" })
        return
    end

    if body.wait and body.wait ~= "" then
        local w = ui.wait_for(body.wait, { timeout = 10000 })
        if not w or not w.success then
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({ success = false, error = "wait_for failed: " .. ((w and w.error) or "unknown") })
            return
        end
    end

    local slug = slug_for(desc, component_id)
    -- raw_root writes to previews/<slug>.png directly so the scanner's
    -- thumbnail_url() helper keeps finding component PNGs at the slug
    -- location it expects.
    local shot = ui.screenshot({
        name = slug,
        full = body.full == true,
        raw_root = true,
    })
    if not shot or not shot.success then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = (shot and shot.error) or "screenshot failed" })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, screenshot_url = shot.url,
        captured_at = os.time(), })
end

return { handler = handler }
