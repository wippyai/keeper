local test = require("test")
local registry = require("registry")

-- Entries below are the persist/repo tier: the only layer where
-- require("sql") / require("fs") / require("registry") on keeper state or the
-- local fe_fs volume is allowed. Everything else must route through
-- orchestrators (changeset central, gov central) or persist libraries.
--
-- Scope: only library.lua / function.lua under keeper.* that declare the
-- restricted module. Tests and migrations are exempt (migrations must call
-- sql directly; tests may need raw access to set up fixtures).
local ALLOWED_SQL = {
    ["keeper.changeset.persist:repo"]              = true,
    ["keeper.changeset:fs_flush"]          = true,
    ["keeper.changeset:fs_view"]           = true,
    ["keeper.state.persist:reader"]        = true,
    ["keeper.state.persist:ops"]           = true,
    ["keeper.state.persist:materialize"]   = true,
    ["keeper.state.service:orchestrator"]  = true,
    ["keeper.state.service:reconcile"]     = true,
    ["keeper.state.service:sync_branch"]   = true,
    ["keeper.task.persist:reader"]         = true,
    ["keeper.task.persist:writer"]         = true,
    ["keeper.task.persist:ops"]            = true,
    ["keeper.task:embedder"]               = true,
    ["keeper.gov.service:central"]         = true,
    ["keeper.gov.service:registry_ops"]    = true,
    ["keeper.gov.service:changeset"]       = true,
    ["keeper.gov.service:sync"]            = true,
    ["keeper.gov.service:upload"]          = true,
    ["keeper.gov.service:download"]        = true,
    ["keeper.gov.observers:changeset_observer"] = true,
    ["keeper.gov.discovery:observers"]     = true,
    ["keeper.gov.env.api:list_variables"]  = true,
    ["keeper.gov.api:state"]               = true,
    ["keeper.gov.api:undo"]                = true,
    ["keeper.gov.api:redo"]                = true,
    ["keeper.gov.api:helpers"]             = true,
    ["keeper.agents.traits.context.migrations:get_migration_tree"] = true,
    ["keeper.components.build:builds"]     = true,
    ["keeper.components.build:scanner"]    = true,
    ["keeper.components.ui:supervisor"]    = true,
    ["keeper.components.tools:ui"]         = true,
    ["keeper.components.tools:fs"]         = true,
    ["keeper.knowledge:persist"]           = true,
    ["keeper.knowledge:kb_reader"]         = true,
    ["keeper.knowledge:kb_writer"]         = true,
    ["keeper.debug.persist:reader"]        = true,
    ["keeper.debug.persist:writer"]        = true,
    ["keeper.mcp.auth:tokens"]             = true,
    ["keeper.mcp.surface:meta"]            = true,
    ["keeper.mcp.auth:policy"]             = true,
    ["keeper.mcp.surface:traits"]          = true,
}

local ALLOWED_FS = {
    ["keeper.changeset:fs_hash"]           = true,
    ["keeper.changeset:fs_view"]           = true,
    ["keeper.changeset:fs_flush"]          = true,
    ["keeper.changeset.service:diff_render"] = true,
    ["keeper.changeset.service:open"]      = true,
    ["keeper.changeset:diff"]              = true,
    ["keeper.components.build:scanner"]    = true,
    ["keeper.components.build:builds"]     = true,
    ["keeper.components.ui:supervisor"]    = true,
    ["keeper.components.tools:fs"]         = true,
    ["keeper.components.tools:ui"]         = true,
    ["keeper.agents.traits.context.frontend:get_frontend_tree"] = true,
    ["keeper.gov.service:upload"]          = true,
    ["keeper.gov.service:download"]        = true,
    ["keeper.gov.service:sync"]            = true,
    ["keeper.gov.service:changeset"]       = true,
    ["keeper.gov.env.api:list_variables"]  = true,
}

local ALLOWED_REGISTRY = {
    ["keeper.gov.service:central"]         = true,
    ["keeper.gov.service:registry_ops"]    = true,
    ["keeper.gov.service:changeset"]       = true,
    ["keeper.gov.service:upload"]          = true,
    ["keeper.gov.service:download"]        = true,
    ["keeper.gov.service:sync"]            = true,
    ["keeper.gov.api:state"]               = true,
    ["keeper.gov.api:undo"]                = true,
    ["keeper.gov.api:redo"]                = true,
    ["keeper.gov.api:helpers"]             = true,
    ["keeper.gov.discovery:observers"]     = true,
    ["keeper.gov.observers:changeset_observer"] = true,
    ["keeper.mcp.surface:meta"]            = true,
    ["keeper.mcp.auth:policy"]             = true,
    ["keeper.mcp.surface:traits"]          = true,
    ["keeper.mcp.auth:tokens"]             = true,
    ["keeper.task:embedder"]               = true,
    ["keeper.components.build:scanner"]    = true,
}

local function is_keeper(id)
    return id and (id:sub(1, 7) == "keeper.")
end

local function has_module(entry, name)
    local data = entry and entry.data
    if not data or type(data.modules) ~= "table" then return false end
    for _, m in ipairs(data.modules) do
        if m == name then return true end
    end
    return false
end

local function kind_gated(entry)
    if not entry or not entry.kind then return false end
    if entry.kind ~= "library.lua" and entry.kind ~= "function.lua" then
        return false
    end
    if entry.meta and entry.meta.type == "test" then return false end
    if entry.meta and entry.meta.type == "migration" then return false end
    return true
end

local function check(module_name, allowlist)
    local entries = registry.snapshot():entries() or {}
    local violations = {}
    for _, entry in ipairs(entries) do
        if is_keeper(entry.id) and kind_gated(entry) and has_module(entry, module_name) then
            if not allowlist[entry.id] then
                table.insert(violations, entry.id)
            end
        end
    end
    return violations
end

local function define_tests()
    test.describe("canonical flow — layer allowlist", function()
        test.it("sql module is only imported by persist-tier entries", function()
            local violations = check("sql", ALLOWED_SQL)
            if #violations > 0 then
                test.fail("require('sql') used outside allowlist:\n  " ..
                    table.concat(violations, "\n  ") ..
                    "\nEither route through a persist/repo library, or add the entry to ALLOWED_SQL in layer_test.lua")
            end
        end)

        test.it("fs module is only imported by persist-tier or scanner entries", function()
            local violations = check("fs", ALLOWED_FS)
            if #violations > 0 then
                test.fail("require('fs') used outside allowlist:\n  " ..
                    table.concat(violations, "\n  ") ..
                    "\nEither route through a persist/repo library, or add the entry to ALLOWED_FS in layer_test.lua")
            end
        end)

        test.it("registry module is only imported by governance/read-state entries", function()
            local violations = check("registry", ALLOWED_REGISTRY)
            if #violations > 0 then
                test.fail("require('registry') used outside allowlist:\n  " ..
                    table.concat(violations, "\n  ") ..
                    "\nRoute registry reads through gov_client.get_state() or state_reader, or add to ALLOWED_REGISTRY")
            end
        end)
    end)
end

return { define_tests = define_tests }
