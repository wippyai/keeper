local registry = require("registry")
local yaml = require("yaml")
local engine = require("engine")

-- Build a single-entry YAML document for the clone.
-- We emit a top-level map with kind + meta + the agent fields, mirroring
-- how an entry is shaped inside an `_index.yaml` file. The engine's create
-- op accepts that document via `file_text`.
local function build_yaml(new_id, source_entry, mods)
    local _, name = new_id:match("^([^:]+):([^:]+)$")
    if not name then
        return nil, "new_agent_id must be in 'namespace:name' form"
    end

    local meta = {}
    for k, v in pairs(source_entry.meta or {}) do meta[k] = v end
    meta.type = "agent.gen1"

    if mods then
        if mods.title   then meta.title = mods.title end
        if mods.comment then meta.comment = mods.comment end
        if mods.icon    then meta.icon = mods.icon end
        if mods.class   then meta.class = mods.class end
    end

    local data = {}
    for k, v in pairs(source_entry.data or {}) do data[k] = v end

    if mods then
        if mods.model           then data.model = mods.model end
        if mods.max_tokens      then data.max_tokens = mods.max_tokens end
        if mods.temperature ~= nil then data.temperature = mods.temperature end
        if mods.thinking_effort then data.thinking_effort = mods.thinking_effort end
    end

    -- The entry doc shape used by `keeper.state.patch:engine` create op:
    -- `kind` + `meta` at top-level, plus the data fields flattened beside.
    local doc = {
        name = name,
        kind = source_entry.kind or "registry.entry",
        meta = meta,
    }
    for k, v in pairs(data) do
        -- avoid clobbering name/kind/meta accidentally
        if k ~= "name" and k ~= "kind" and k ~= "meta" then
            doc[k] = v
        end
    end

    local text, err = yaml.encode(doc)
    if err then return nil, "yaml.encode: " .. tostring(err) end
    return text
end

local function handler(params)
    if not params or type(params.source_agent_id) ~= "string" or params.source_agent_id == "" then
        return { success = false, error = "Missing source_agent_id" }
    end
    if type(params.new_agent_id) ~= "string" or params.new_agent_id == "" then
        return { success = false, error = "Missing new_agent_id" }
    end
    if not params.new_agent_id:match("^[^:]+:[^:]+$") then
        return { success = false, error = "new_agent_id must be 'namespace:name'" }
    end
    if params.source_agent_id == params.new_agent_id then
        return { success = false, error = "new_agent_id must differ from source_agent_id" }
    end

    local source = registry.get(params.source_agent_id)
    if not source then
        return { success = false, error = "Source agent not found: " .. params.source_agent_id }
    end
    if not source.meta or source.meta.type ~= "agent.gen1" then
        return { success = false, error = "Source is not an agent.gen1: " .. params.source_agent_id }
    end

    if registry.get(params.new_agent_id) then
        return { success = false, error = "Target id already exists: " .. params.new_agent_id }
    end

    local file_text, ye = build_yaml(params.new_agent_id, source, params.modifications)
    if not file_text then
        return { success = false, error = ye }
    end

    local result, err = engine.apply_one({
        target    = "entry",
        id        = params.new_agent_id,
        op        = "create",
        file_text = file_text,
    })
    if not result then
        return { success = false, error = "Stage failed: " .. tostring(err) }
    end

    return {
        success         = true,
        source_agent_id = params.source_agent_id,
        new_agent_id    = params.new_agent_id,
        staged          = true,
        message         = "Clone staged on active branch. Run `analyze` then `push` when ready.",
    }
end

return { handler = handler }
