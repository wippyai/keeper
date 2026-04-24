local json = require("json")
local discovery = require("discovery")
local registry = require("registry")
local flow = require("flow")

local function handler(params)
    local execution = params.execution or {}

    if not execution or #execution == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = {
                handlers = {}
            }
        }
    end

    local all_entry_ids = {}
    for _, handler_result in ipairs(execution) do
        for _, entry_id in ipairs(handler_result.entry_ids) do
            table.insert(all_entry_ids, entry_id)
        end
    end

    local entries = {}
    for _, entry_id in ipairs(all_entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, "Failed to load entry for rollback: " .. entry_id .. " - " .. err
        end
        table.insert(entries, entry)
    end

    local sorted_handlers = discovery.match_handlers(entries, "down")
    if not sorted_handlers or #sorted_handlers == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = {
                handlers = {}
            }
        }
    end

    local reversed_handlers = {}
    for i = #sorted_handlers, 1, -1 do
        table.insert(reversed_handlers, sorted_handlers[i])
    end

    local f = flow.create():with_title("Rollback Integration Pipeline")

    f = f:with_input({ _trigger = true }):to("handler_1", "_trigger")

    for i, handler_node in ipairs(reversed_handlers) do
        local node_name = "handler_" .. tostring(i)
        local is_last = (i == #reversed_handlers)

        local original_index = #sorted_handlers - i + 1
        local original_result = execution[original_index]

        f = f:func("keeper.develop.integrate.pipeline:execute_handler", {
                args = {
                    handler_id = handler_node.handler_id,
                    entry_ids = handler_node.entries,
                    operation = "down",
                    execute_result = original_result.result
                },
                input_transform = { _trigger = "inputs._trigger" },
                metadata = {
                    title = "Undo: " .. (handler_node.meta.title or handler_node.handler_id),
                    icon = handler_node.meta.icon or "tabler:arrow-back"
                }
            })
            :as(node_name)

        f = f:to("collect", node_name)
        f = f:error_to("collect", "__error__", "error")

        if is_last then
            f = f:to("collect", "_trigger")
                :error_to("collect", "_trigger")
        else
            local next_node_name = "handler_" .. tostring(i + 1)
            f = f:to(next_node_name, "_trigger", '{"_trigger": true}')
                :error_to(next_node_name, "_trigger", '{"_trigger": true}')
        end
    end

    f = f:join({
            inputs = { required = { "_trigger" } },
            output_mode = "array",
            ignored_keys = { "_trigger" },
            metadata = {
                title = "Verify Rollback",
                icon = "tabler:checklist"
            }
        })
        :as("collect")
        :to("@success", nil, [[{
            "success": !any(output, {"error" in #}),
            "applied_ids": flatten(map(filter(output, {"error" not in #}), {#.entry_ids})),
            "execution": {
                "handlers": output
            }
        }]])

    return f:run()
end

return { handler = handler }