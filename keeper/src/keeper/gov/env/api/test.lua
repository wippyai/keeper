local test = require("test")
local json = require("json")
local http_client = require("http_client")
local api_test = require("api_test")

local function define_tests()
    describe("Env API", function()
        describe("GET /keeper/env/list", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(api_test.endpoint("/api/keeper/env/list"), {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("POST /keeper/env/set", function()
            it("returns 401 without auth", function()
                local res, err = http_client.post(api_test.endpoint("/api/keeper/env/set"), {
                    headers = {
                        Accept = "application/json",
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({ name = "TEST_VAR", value = "test" }),
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
