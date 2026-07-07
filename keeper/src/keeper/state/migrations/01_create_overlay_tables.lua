return require("migration").define(function()
    local schema = require("state_schema")

    migration("Create overlay tables", function()
        database("sqlite", function()
            up(function(db)
                local ok, err = schema.ensure(db)
                if err then error(err) end
                return ok
            end)

            down(function(db)
                return schema.drop(db)
            end)
        end)
    end)
end)
