local json = require("json")

local kb_repo = require("kb_repo")

local SEED_DATA = {
    {
        node_type = "pattern",
        title = "HTTP Endpoint Pattern",
        content = "Every HTTP endpoint in Wippy requires two entries:\n- `function.lua` with `http` module and handler method\n- `http.endpoint` linking to the function with method (GET/POST) and path\n\nThe function handles request/response via `http.request()` and `http.response()`.\nAlways set content type and check authentication via `security.actor()`.",
        source = "seed",
        confidence = 1.0,
        refs = { "keeper.debug.usage:get_summary", "keeper.debug.usage:get_summary.endpoint" },
    },
    {
        node_type = "pattern",
        title = "Agent Definition Pattern",
        content = "Agents are `registry.entry` with `meta.type: agent.gen1`.\n\nRequired fields:\n- `prompt` - system prompt defining personality and capabilities\n- `model` - LLM model reference (e.g. `claude-4-5-haiku`)\n- `temperature`, `max_tokens`\n\nOptional:\n- `traits` - list of trait entry IDs for reusable behaviors\n- `tools` - list of tool entry IDs the agent can call\n- `delegates` - other agents this agent can delegate to\n- `class` - classification tags (e.g. `public`, `keeper`)",
        source = "seed",
        confidence = 1.0,
        refs = { "keeper.agents:keeper" },
    },
    {
        node_type = "pattern",
        title = "Lua Module Pattern",
        content = "Lua libraries use the module table pattern:\n```lua\nlocal M = {}\nfunction M.my_function(args)\n  -- implementation\nend\nreturn M\n```\n\nNever use global functions. Always return the module table.\nModules are declared with `kind: library.lua` and imported via `imports` in YAML.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "pattern",
        title = "Contract Binding Pattern",
        content = "Contracts decouple interface from implementation:\n1. `contract.definition` declares methods with input/output schemas\n2. `contract.binding` maps contract methods to actual `function.lua` entries\n3. Consumers import the contract, not the implementation\n\nThis allows swapping implementations without changing consumers.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "pattern",
        title = "Migration Pattern",
        content = "Database migrations use `kind: function.lua` with `meta.type: migration`.\n\nStructure:\n```lua\nreturn require('migration').define(function()\n  migration('Description', function()\n    database('sqlite', function()\n      up(function(db)\n        db:execute([[ CREATE TABLE ... ]])\n        return true\n      end)\n      down(function(db)\n        db:execute([[ DROP TABLE IF EXISTS ... ]])\n        return true\n      end)\n    end)\n  end)\nend)\n```\n\nMigrations must have both `up` and `down` functions. Use `meta.target_db` to specify the database.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "pattern",
        title = "Process Service Pattern",
        content = "Long-running services use `kind: process.lua` with auto_start and lifecycle hooks.\n\nThe service receives commands via `process.receive()` and can maintain state.\nDeclare `meta.requires` for dependencies that must start first.\nUse `pool` configuration for worker count.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "convention",
        title = "Namespace Hierarchy",
        content = "Namespaces use dot notation for hierarchy:\n- `app` - top-level application config\n- `app.api` - API layer\n- `app.api.<domain>` - domain-specific endpoints\n- `keeper` - keeper-specific functionality\n- `keeper.state` - state management system\n- `wippy.*` - framework modules (managed)\n- `userspace.*` - shared user modules (managed)\n\nEach namespace has an `_index.yaml` with `version: '1.0'` and `namespace:` declaration.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "convention",
        title = "Entry ID Format",
        content = "Entry IDs follow `namespace:name` format.\n- Namespace: dot-separated hierarchy (e.g. `keeper.debug.usage`)\n- Name: snake_case identifier\n- Endpoint entries append `.endpoint` suffix\n- Test entries use `test` as name\n\nExamples: `keeper.debug.usage:get_summary`, `keeper.debug.usage:get_summary.endpoint`",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "convention",
        title = "API Response Format",
        content = "All API responses follow:\n```json\n{\n  \"success\": true|false,\n  \"error\": \"message\" (on failure),\n  \"<data_key>\": ... (on success)\n}\n```\n\nAlways set `http.CONTENT.JSON` content type.\nUse `http.STATUS.OK`, `http.STATUS.BAD_REQUEST`, `http.STATUS.UNAUTHORIZED`, `http.STATUS.INTERNAL_ERROR`.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "convention",
        title = "Test Structure",
        content = "Tests use `wippy.test:test` library with `test.run_cases(fn)` pattern:\n```lua\nreturn { define_tests = test.run_cases(function(describe, it, expect)\n  describe('Group', function()\n    it('should do X', function()\n      expect(result).to_equal(expected)\n    end)\n  end)\nend) }\n```\n\nTest entries have `meta.type: test` and `method: define_tests`.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "decision",
        title = "SQLite for State Reflection",
        content = "The state system uses a dedicated SQLite database (`.wippy/state_reflect.db`) rather than sharing the app database.\n\nReasoning: State reflection is a read-heavy workload with frequent reconciliation. Isolating it prevents lock contention with app writes. The state DB can be recreated from registry at any time.",
        source = "seed",
        confidence = 0.9,
    },
    {
        node_type = "decision",
        title = "Passthrough Linter for Development",
        content = "The governance pipeline requires a linter contract binding. During development, a passthrough linter that returns `{success=true}` for all entries is used.\n\nThis unblocks saves through governance while real validation rules are developed incrementally.",
        source = "seed",
        confidence = 0.8,
    },
    {
        node_type = "decision",
        title = "Managed Namespaces",
        content = "Namespaces `app`, `keeper`, `userspace`, and `wippy` are managed by governance.\n\nManaged namespaces go through the linting pipeline and changeset observers on modification. Unmanaged namespaces can be modified freely.\n\nSet via `GOV_MANAGED_NAMESPACES` environment variable.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "learning",
        title = "SQL Parameter Passing",
        content = "In Wippy Lua, SQL queries use table params, not varargs:\n```lua\n-- Correct:\ndb:query(sql, { param1, param2 })\n\n-- Wrong:\ndb:query(sql, table.unpack(params))\n```\n\nThe `db:query` and `db:execute` functions expect a single table as the second argument.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "learning",
        title = "Context Propagation via ctx",
        content = "The `ctx` module propagates context through the entire call chain including agent calls and dataflows.\n\nUse `ctx.get('key')` to read and `ctx.set('key', value)` to write.\n\nThis is used for:\n- `context_id` - tracking usage/costs across call chains\n- Session correlation\n- User context propagation",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "learning",
        title = "FTS5 Availability",
        content = "FTS5 (full-text search) may not be available in all SQLite builds.\n\nAlways include a fallback that creates a regular table with LIKE-based search when FTS5 creation fails. Same applies to vec0 virtual tables.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "anti_pattern",
        title = "Global Functions in Lua",
        content = "Never define global functions in Lua modules:\n```lua\n-- Wrong:\nfunction handle(args)\n  ...\nend\n\n-- Correct:\nlocal M = {}\nfunction M.handle(args)\n  ...\nend\nreturn M\n```\n\nGlobal functions cause module isolation issues and unpredictable behavior.",
        source = "seed",
        confidence = 1.0,
    },
    {
        node_type = "anti_pattern",
        title = "Manual Lock File Editing",
        content = "Never edit `wippy.lock` directly. Changing a module version without updating the hash will break imports.\n\nUse `wippy add module@version` followed by `wippy install --refresh` to properly update dependencies.",
        source = "seed",
        confidence = 1.0,
    },
}

local function seed()
    -- Ensure default KB exists
    local kb = kb_repo.get_kb_by_name("Wippy Patterns")
    if not kb then
        local created, err = kb_repo.create_kb({
            name = "Wippy Patterns",
            description = "Standard Wippy platform patterns, conventions, and learnings",
        })
        if err then return nil, "Failed to create seed KB: " .. err end
        kb = created
    end

    -- Check if already seeded
    local existing = kb_repo.list({ source = "seed", kb_id = kb.id, limit = 1 })
    if existing and #existing > 0 then
        return { seeded = false, message = "Already seeded", count = #existing, kb = kb.name }
    end

    local count = 0
    local errors = {}

    for _, data in ipairs(SEED_DATA) do
        data.kb_id = kb.id
        local node, err = kb_repo.create(data)
        if node then
            count = count + 1
        elseif err then
            table.insert(errors, err)
        end
    end

    return { seeded = true, count = count, errors = errors, kb = kb.name }
end

return { seed = seed }
