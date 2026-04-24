local test = require("test")
local json = require("json")
local http_client = require("http_client")

local BASE_URL = "http://localhost:8067"

local function define_tests()
    describe("Changelog API", function()
        describe("GET /keeper/changelog/list", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(BASE_URL .. "/api/v1/keeper/changelog/list", {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("GET /keeper/changelog/versions", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(BASE_URL .. "/api/v1/keeper/changelog/versions", {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
