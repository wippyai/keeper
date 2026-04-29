local audit = require("audit")
local engine = require("engine")

local function build_patch(params)
    local cmd = params.command
    if cmd == "view" then
        return {
            target     = "entry",
            id         = params.path,
            op         = "view",
            view_range = params.view_range,
            raw        = params.raw,
        }
    elseif cmd == "create" then
        return {
            target    = "entry",
            id        = params.path,
            op        = "create",
            file_text = params.file_text,
        }
    elseif cmd == "str_replace" then
        return {
            target  = "entry",
            id      = params.path,
            op      = "str_replace",
            replace = { { old = params.old_str, new = params.new_str } },
        }
    elseif cmd == "delete" then
        return {
            target = "entry",
            id     = params.path,
            op     = "delete",
        }
    end
end

local function shim_message(e)
    if not e then return nil end
    if type(e) == "string" then return e end
    return e.message or e.code or "edit failed"
end

local function shape_result(cmd, result)
    if cmd == "view" then return result.content end
    if cmd == "create" then return "Created " .. result.id end
    if cmd == "str_replace" then return "Replaced text" end
    if cmd == "delete" then
        if result.already_deleted then
            return "Already deleted on branch: " .. result.id
        end
        return "Deleted " .. result.id
    end
    return result
end

local function do_handler(params)
    if not params.command or params.command == "" then
        return nil, "Missing command (view, str_replace, create, delete)"
    end
    if not params.path or params.path == "" then
        return nil, "Missing path (entry ID)"
    end

    local patch = build_patch(params)
    if not patch then
        return nil, "Invalid command: " .. tostring(params.command)
    end

    local result, e = engine.apply_one(patch)
    if not result then
        return nil, shim_message(e)
    end
    return shape_result(params.command, result), nil
end

local function summarise_edit(params, result, err)
    if err then return "edit failed: " .. tostring(err) end
    local cmd = params.command or "?"
    local path = params.path or "?"
    if cmd == "view" then return "viewed " .. path end
    if cmd == "create" then
        local _, lines = (params.file_text or ""):gsub("\n", "\n")
        return "created " .. path .. " (" .. lines .. " lines)"
    end
    if cmd == "str_replace" then return "str_replace on " .. path end
    if cmd == "delete" then return "deleted " .. path end
    return cmd .. " on " .. path
end

local function handler(params)
    params = params or {}
    local cmd = params.command or "?"
    local path = params.path or "?"
    return audit.wrap({
        tool          = "edit",
        discriminator = "edit." .. cmd,
        target        = path,
        title         = cmd:sub(1, 1):upper() .. cmd:sub(2) .. " " .. path,
        params        = {
            command   = params.command,
            path      = params.path,
            file_text = params.file_text,
            old_str   = params.old_str,
            new_str   = params.new_str,
        },
        summarise = function(result, err) return summarise_edit(params, result, err) end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
