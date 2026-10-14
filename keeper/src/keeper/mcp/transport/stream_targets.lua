-- A session may have several GET streams; each notification goes to one.

local M = {}

function M.new()
    local streams = {}
    local target = {}

    function target:leave(pid)
        local key = tostring(pid)
        for i = #streams, 1, -1 do
            if tostring(streams[i]) == key then table.remove(streams, i) end
        end
    end

    function target:join(pid)
        self:leave(pid)
        streams[#streams + 1] = pid
    end

    function target:current()
        return streams[#streams]
    end

    return target
end

return M
