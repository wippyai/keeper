local pg = require("pg")
local consts = require("events_consts")

local log = require("logger"):named("keeper.events.relay")

-- The events relay owns the admin bus. It is the single process permitted to
-- pg.open the bus and broadcast on it; the publisher SDK only sends messages to
-- it (via process.registry), so any keeper code may publish regardless of its
-- own security scope. Each inbox message is rebroadcast to the admin group under
-- its original topic, which the subscribed user hubs fan to admin browser tabs.
local function run(args: any): any
    local scope, err = pg.open(consts.BUS)
    if err or not scope then
        error("events relay pg.open failed: " .. tostring(err))
    end

    process.registry.register(consts.RELAY)

    local inbox = process.inbox()
    local events = process.events()

    log:info("events relay started", { group = consts.GROUP })

    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive()
        })

        if not result.ok then
            break
        end

        if result.channel == inbox then
            local msg: any = result.value
            local topic = string(msg:topic())
            local payload: any = msg:payload()
            local ok, berr = scope:broadcast(consts.GROUP, topic, payload:data())
            if not ok then
                log:debug("broadcast dropped", { topic = topic, error = tostring(berr) })
            end
        elseif result.channel == events then
            local event: any = result.value
            if event.kind == process.event.CANCEL then
                break
            end
        end
    end

    scope:release()
    return { status = "stopped" }
end

return { run = run }
