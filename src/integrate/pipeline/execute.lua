local json = require("json")
local flow = require("flow")
local discovery = require("discovery")
local registry = require("registry")

local function handler(params)
    local entry_ids = params.entry_ids or {}
    local operation = params.operation or "up"

    if #entry_ids == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = {
                handlers = {}
            }
        }
    end

    local entries = {}
    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, "Failed to load entry: " .. entry_id .. " - " .. err
        end
        table.insert(entries, entry)
    end

    local sorted_handlers = discovery.match_handlers(entries, operation)
    if not sorted_handlers or #sorted_handlers == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = {
                handlers = {}
            }
        }
    end

    for _, handler_node in ipairs(sorted_handlers) do
        local handler_entry, err = registry.get(handler_node.handler_id)
        if err then
            return nil, "Failed to load handler " .. handler_node.handler_id .. ": " .. err
        end
    end

    local f = flow.create():with_title("Execute Integration Pipeline")

    f = f:with_input({ _trigger = true }):to("handler_1", "_trigger")

    for i, handler_node in ipairs(sorted_handlers) do
        local node_name = "handler_" .. tostring(i)
        local is_last = (i == #sorted_handlers)

        f = f:func("keeper.integrate.pipeline:execute_handler", {
                args = {
                    handler_id = handler_node.handler_id,
                    entry_ids = handler_node.entries,
                    operation = operation
                },
                input_transform = { _trigger = "inputs._trigger" },
                metadata = {
                    title = handler_node.meta.title or handler_node.handler_id,
                    icon = handler_node.meta.icon or "tabler:plugin"
                }
            })
            :as(node_name)

        f = f:to("collect", node_name)

        if is_last then
            f = f:to("collect", "_trigger")
            f = f:error_to("collect", "_trigger")
        else
            local next_node_name = "handler_" .. tostring(i + 1)
            f = f:to(next_node_name, "_trigger", '{"_trigger": true}'):when('"result" in output')
            f = f:to("collect", "_trigger"):when('"error" in output')
            f = f:error_to("collect", "_trigger")
        end

        f = f:error_to("collect", "__error__", "error")
    end

    f = f:join({
            inputs = { required = { "_trigger" } },
            output_mode = "array",
            ignored_keys = { "_trigger" },
            metadata = {
                title = "Collect Results",
                icon = "tabler:checklist"
            }
        })
        :as("collect")
        :to("@success", nil, [[{
            "success": !any(output, {"error" in #}),
            "execution": output
        }]])

    return f:run()
end

return { handler = handler }