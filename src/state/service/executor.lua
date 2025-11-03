local json = require("json")
local logger = require("logger")
local sql = require("sql")
local consts = require("consts")
local state_ops = require("state_ops")

local log = logger:named("state.executor")

local function run()
    log:info("State command executor starting")

    local inbox = process.inbox()
    local events = process.events()

    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive()
        })

        if result.channel == inbox then
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload():data()
            local from = msg:from()

            if topic == consts.TOPICS.COMMANDS then
                if payload.operation == consts.OPERATIONS.EXECUTE_COMMANDS then
                    log:debug("Handling execute_commands request", {
                        requester = from,
                        request_id = payload.id,
                        command_count = payload.commands and #payload.commands or 0
                    })

                    if not payload.commands or type(payload.commands) ~= "table" then
                        log:warn("Invalid commands payload")
                        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                            success = false,
                            error = consts.ERRORS.COMMANDS_REQUIRED,
                            request_id = payload.id
                        })
                        goto continue
                    end

                    if #payload.commands == 0 then
                        log:warn("Empty commands array")
                        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                            success = false,
                            error = consts.ERRORS.COMMANDS_EMPTY,
                            request_id = payload.id
                        })
                        goto continue
                    end

                    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
                    if err then
                        log:error("Failed to connect to database", { error = err })
                        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                            success = false,
                            error = consts.ERRORS.DB_CONNECTION_FAILED .. ": " .. err,
                            request_id = payload.id
                        })
                        goto continue
                    end

                    local tx, tx_err = db:begin()
                    if tx_err then
                        db:release()
                        log:error("Failed to begin transaction", { error = tx_err })
                        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                            success = false,
                            error = "Failed to begin transaction: " .. tx_err,
                            request_id = payload.id
                        })
                        goto continue
                    end

                    local exec_result, exec_err = state_ops.execute(tx, payload.commands)
                    if exec_err then
                        tx:rollback()
                        db:release()
                        log:error("Command execution failed", { error = exec_err })
                        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                            success = false,
                            error = exec_err,
                            request_id = payload.id
                        })
                        goto continue
                    end

                    local commit_success, commit_err = tx:commit()
                    if commit_err then
                        tx:rollback()
                        db:release()
                        log:error("Failed to commit transaction", { error = commit_err })
                        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                            success = false,
                            error = "Failed to commit transaction: " .. commit_err,
                            request_id = payload.id
                        })
                        goto continue
                    end

                    db:release()

                    log:info("Commands executed successfully", {
                        command_count = #payload.commands,
                        changes_made = exec_result.changes_made,
                        request_id = payload.id
                    })

                    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                        success = true,
                        results = exec_result.results,
                        changes_made = exec_result.changes_made,
                        request_id = payload.id
                    })
                else
                    log:warn("Unknown operation", {
                        operation = payload.operation,
                        from = from
                    })
                end
            end

            ::continue::

        elseif result.channel == events then
            local event = result.value

            if event.kind == process.event.CANCEL then
                log:info("Received cancellation request, shutting down executor")
                return { status = "cancelled" }
            end
        end
    end
end

return { run = run }