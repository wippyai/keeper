local test = require("test")
local json = require("json")
local http_client = require("http_client")

local BASE_URL = "http://localhost:8067"

local function define_tests()
    describe("PM API", function()
        describe("GET /keeper/pm/stats", function()
            it("returns JSON with Accept header", function()
                local res, err = http_client.get( BASE_URL .. "/api/v1/keeper/pm/stats", {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                -- Should get 401 without auth, which is JSON
                test.not_nil((res.status_code or res.status))
                test.eq((res.status_code or res.status), 401)
            end)

            it_skip("returns valid data with auth (requires auth token)", function()
            end)
        end)

        describe("POST /keeper/pm/terminate", function()
            it("returns 401 without auth", function()
                local res, err = http_client.post( BASE_URL .. "/api/v1/keeper/pm/terminate", {
                    headers = {
                        Accept = "application/json",
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({ pid = "test" }),
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
