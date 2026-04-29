-- keeper.components.api:start_screenshot
--
-- One-shot screenshot endpoint for the frontend thumbnails. Internally:
-- one ui.open + one ui.screenshot through the persistent Playwright
-- session.
--
-- Request body:  { component_id, route?, full?, wait?/wait_for?, name?, thumbnail? }
-- Response:      { success, screenshot_url, captured_at, error? }

local http = require("http")

local ui = require("ui")
local scanner = require("scanner")
local filenames = require("filenames")
local security = require("security")

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

    local wait_for = body.wait_for or body.wait
    if wait_for and wait_for ~= "" then
        local w = ui.wait_for(wait_for, { timeout = 10000 })
        if not w or not w.success then
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({ success = false, error = "wait_for failed: " .. ((w and w.error) or "unknown") })
            return
        end
    end

    local component_slug = filenames.component_slug(desc, component_id)
    local requested_name = body.name or body.filename
    if requested_name == "" then requested_name = nil end
    local thumbnail = body.thumbnail == true or requested_name == nil
    local slug = thumbnail and component_slug or filenames.with_random_seed(requested_name, { fallback = component_slug })
    -- raw_root writes to previews/<slug>.png directly so the scanner's
    -- thumbnail_url() helper keeps finding component PNGs at the slug
    -- location it expects. Named ad-hoc screenshots use the normal ui/current
    -- directory, which avoids overwriting component thumbnails.
    local shot = ui.screenshot({
        name = slug,
        full = body.full == true,
        request_id = thumbnail and nil or "screenshots",
        raw_root = thumbnail,
    })
    if not shot or not shot.success then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = (shot and shot.error) or "screenshot failed" })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, screenshot_url = shot.url, filename = slug, thumbnail = thumbnail,
        captured_at = os.time(), })
end

return { handler = handler }
