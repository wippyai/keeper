return require("migration").define(function()
    migration("Keeper test host identity table", function()
        local function create(db)
            local _, err = db:execute("CREATE TABLE app_users (user_id TEXT PRIMARY KEY, status TEXT NOT NULL)")
            if err then error(err) end
        end
        database("sqlite", function() up(create) end)
        database("postgres", function() up(create) end)
    end)
end)
