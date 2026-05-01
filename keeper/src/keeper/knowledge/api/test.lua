local test = require("test")
local json = require("json")
local http_client = require("http_client")
local env = require("env")

local function endpoint(path)
    local base = env.get("PUBLIC_API_URL")
    test.not_nil(base)
    test.is_true(tostring(base) ~= "")
    return tostring(base):gsub("/+$", "") .. path
end

local function define_tests()
    describe("Knowledge API", function()
        describe("GET /keeper/knowledge/kbs", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(endpoint("/api/v1/keeper/knowledge/kbs"), {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("POST /keeper/knowledge/kbs", function()
            it("returns 401 without auth", function()
                local res, err = http_client.post(endpoint("/api/v1/keeper/knowledge/kbs"), {
                    headers = {
                        Accept = "application/json",
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({ name = "test-kb" }),
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("GET /keeper/knowledge/nodes", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(endpoint("/api/v1/keeper/knowledge/nodes"), {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("GET /keeper/knowledge/nodes/:id", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(endpoint("/api/v1/keeper/knowledge/nodes/test-id"), {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("POST /keeper/knowledge/nodes", function()
            it("returns 401 without auth", function()
                local res, err = http_client.post(endpoint("/api/v1/keeper/knowledge/nodes"), {
                    headers = {
                        Accept = "application/json",
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({ title = "test", content = "test" }),
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("GET /keeper/knowledge/search", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(endpoint("/api/v1/keeper/knowledge/search?q=test"), {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("GET /keeper/knowledge/stats", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(endpoint("/api/v1/keeper/knowledge/stats"), {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("POST /keeper/knowledge/seed", function()
            it("returns 401 without auth", function()
                local res, err = http_client.post(endpoint("/api/v1/keeper/knowledge/seed"), {
                    headers = {
                        Accept = "application/json",
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({}),
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)
        end)

        describe("GET /keeper/knowledge/semantic-search", function()
            it("returns 401 without auth", function()
                local res, err = http_client.get(endpoint("/api/v1/keeper/knowledge/semantic-search?q=test"), {
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
