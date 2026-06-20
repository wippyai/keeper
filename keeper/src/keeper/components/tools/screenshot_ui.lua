local audit = require("audit")
local security = require("security")
local ui_default = require("ui")
local scanner_default = require("scanner")
local keeper_config = require("keeper_config")
local filenames = require("filenames")
local json = require("json")

local M = {}

local function mint_auth_token(source: string): (string?, string?)
    local actor = security.actor()
    local scope = security.scope()
    if not actor or not scope then
        return nil, "No security context available"
    end
    local token_store_id = keeper_config.auth_token_store()
    local store, err = security.token_store(token_store_id)
    if not store then return nil, "Token store failed: " .. tostring(err) end
    local token, terr = store:create(actor, scope, {
        expiration = "5m",
        meta = { source = source },
    })
    store:close()
    if not token then return nil, "Token creation failed: " .. tostring(terr) end
    return token
end

-- Probe each selector in ONE eval call. Cheap, deterministic, runs in the
-- same Playwright session as the screenshot so it sees the exact DOM the
-- caller is going to be looking at. Returns a map keyed by selector.
local function probe_selectors(ui: unknown, selectors: unknown)
    if type(selectors) ~= "table" or #selectors == 0 then return nil end
    local list_json, jerr = json.encode(selectors)
    if jerr then return nil end
    local js = string.format([[
        (function() {
          var sels = %s;
          function visibleIn(win, el) {
            var r = el.getBoundingClientRect();
            var cs = win.getComputedStyle(el);
            return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' && parseFloat(cs.opacity || '1') > 0;
          }
          var scopes = [{ name: 'top', doc: document, win: window }];
          var frames = document.querySelectorAll('iframe');
          for (var f = 0; f < frames.length; f++) {
            try {
              if (frames[f].contentDocument && frames[f].contentWindow) {
                scopes.push({ name: 'iframe[' + f + ']', doc: frames[f].contentDocument, win: frames[f].contentWindow });
              }
            } catch (_) {}
          }
          var out = {};
          for (var i = 0; i < sels.length; i++) {
            var s = sels[i];
            var el = null;
            var scope = null;
            var queryError = null;
            for (var j = 0; j < scopes.length; j++) {
              try {
                el = scopes[j].doc.querySelector(s);
              } catch (e) {
                queryError = String(e);
                break;
              }
              if (el) { scope = scopes[j]; break; }
            }
            if (queryError) { out[s] = { present:false, visible:false, error:queryError }; continue; }
            if (!el) { out[s] = { present:false, visible:false }; continue; }
            var isVisible = visibleIn(scope.win, el);
            var text = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 200);
            out[s] = { present:true, visible:isVisible, text_preview:text, scope:scope.name };
          }
          return out;
        })()
    ]], list_json)
    local res = ui.eval(js)
    if not res or not res.success then return nil end
    return res.value or res.result or nil
end

local function selector_visible(probe, selector)
    local row = probe and probe[selector]
    return row and row.present == true and row.visible == true
end

local function wait_for_selector(ui, selector, timeout_ms)
    -- Components are rendered inside the Wippy host iframe. ui.wait_for probes
    -- the outer host document only, so first and last try the same
    -- frame-aware selector probe used for assert_selectors.
    local probe = probe_selectors(ui, { selector })
    if selector_visible(probe, selector) then
        return { success = true, source = "probe", selectors = probe }
    end

    local w = ui.wait_for(selector, { timeout = timeout_ms })
    if w and w.success == true then
        return w
    end

    probe = probe_selectors(ui, { selector })
    if selector_visible(probe, selector) then
        return { success = true, source = "probe", selectors = probe }
    end

    return w or { success = false, error = "timeout" }
end

-- Pure logic. Takes its dependencies explicitly so the unit tests can
-- substitute fakes without touching package.loaded (the wippy registry
-- loader doesn't honor Lua's package table for require()d names declared
-- in the entry's imports block).
function M.run(deps, params)
    deps = deps or {}
    params = params or {}
    local ui      = deps.ui      or ui_default
    local scanner = deps.scanner or scanner_default
    local mint_token = deps.mint_token or mint_auth_token

    local component_id = params.component_id
    if type(component_id) ~= "string" or component_id == "" then
        return nil, "component_id is required"
    end

    local desc, derr = scanner.get(component_id)
    if not desc then
        return nil, "component not found: " .. tostring(derr or component_id)
    end

    local token, terr = mint_token("screenshot_ui")
    if terr then return nil, terr end

    local open_res = ui.open({
        component_id = component_id,
        route        = params.route,
        auth_token   = token,
    })
    if not open_res or not open_res.success then
        -- Genuine "no page reachable" — nothing to capture, return error.
        return nil, "ui open failed: " .. ((open_res and open_res.error) or "unknown")
    end

    -- wait_for is a TIMING HINT, not a success criterion. If it resolves we
    -- shoot earlier; if it times out we shoot anyway and report the outcome
    -- so the caller can reconcile "selector wasn't there yet" against the
    -- visible image and DOM probe. Old behaviour treated timeout as a tool
    -- error and dropped the image — that bit us on v17 where the page was
    -- fine but the verifier never saw the screenshot to confirm it.
    local wait_outcome = nil
    if params.wait_for and params.wait_for ~= "" then
        local timeout_ms = tonumber(params.wait_timeout_ms) or 10000
        local started = os.time()
        local w = wait_for_selector(ui, params.wait_for, timeout_ms)
        local observed = w ~= nil and w.success == true
        wait_outcome = {
            selector   = params.wait_for,
            observed   = observed,
            source     = observed and w.source or nil,
            timeout_ms = timeout_ms,
            error      = (not observed) and (w and w.error or "timeout") or nil,
            elapsed_s  = os.time() - started,
        }
    end

    local component_slug = filenames.component_slug(desc, component_id)
    local slug = filenames.with_random_seed(params.name, { fallback = component_slug })
    local shot = ui.screenshot({
        name       = slug,
        full       = params.full == true,
        selector   = params.selector,
        request_id = "screenshots",
    })
    if not shot or not shot.success then
        return nil, "screenshot failed: " .. ((shot and shot.error) or "unknown")
    end

    -- Deterministic DOM facts for the assert_selectors list. Opt-in: agents
    -- that don't pass assert_selectors get the slim response shape plus
    -- wait_outcome. Agents that pass it get hard truth-table entries they
    -- can verdict on without trusting LLM-vision of the image alone.
    local selectors_probe = probe_selectors(ui, params.assert_selectors)

    return {
        component_id   = component_id,
        route          = params.route,
        filename       = slug,
        screenshot_url = shot.url,
        captured_at    = os.time(),
        wait_for       = wait_outcome,
        selectors      = selectors_probe,
    }
end

-- Production wrapper used at runtime. Tests should call M.run directly.
local function do_handler(params)
    return M.run(nil, params)
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

M.handler = handler
return M
