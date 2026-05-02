-- Drop legacy screenshots tables AND wipe the PNG files that the old
-- screenshots.lua wrote as root-in-container. Without this, the new
-- --user 1000 container can't overwrite them and every legacy call
-- fails with EACCES. Also clears stale .auth-*.json files.
--
-- The FS cleanup runs once and is idempotent. Running it outside a
-- migration (e.g. from the supervisor) is possible but would re-run
-- on every boot. A migration runs it exactly once per database.

return require("migration").define(function()
    migration("Drop legacy screenshots tables and wipe stale root-owned PNGs", function()
        database("sqlite", function()
            up(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_fe_capture_locks")
                db:execute("DROP TABLE IF EXISTS keeper_fe_screenshots")

                -- Best-effort filesystem cleanup. Migration runs in the
                -- wippy process (as host user) so it can remove files that
                -- the old container wrote as root.
                local ok_fs, fs = pcall(require, "fs")
                if not ok_fs or not fs then return true end
                local vol = fs.get("keeper.components:previews_fs")
                if not vol then return true end

                local stale = {}
                local ok_iter, it = pcall(function() return vol:readdir("") end)
                if ok_iter and it then
                    for entry in it do
                        local name = (type(entry) == "table" and (entry.name or entry[1])) or tostring(entry)
                        if name and name ~= "" and name ~= "." and name ~= ".." then
                            if name:match("^%.auth%-") or name:match("^%.script%-") or name:match("^%.capture%.") then
                                table.insert(stale, name)
                            elseif name:match("%.png$") then
                                table.insert(stale, name)
                            end
                        end
                    end
                end
                for _, name in ipairs(stale) do
                    pcall(function() vol:remove(name) end)
                end
                return true
            end)

            down(function(db)
                return true
            end)
        end)

        database("postgres", function()
            up(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_fe_capture_locks")
                db:execute("DROP TABLE IF EXISTS keeper_fe_screenshots")
                return true
            end)

            down(function(db)
                return true
            end)
        end)
    end)
end)
