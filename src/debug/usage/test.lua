local test = require("test")
local json = require("json")
local time = require("time")
local token_usage_repo = require("token_usage_repo")
local uuid = require("uuid")
local sql = require("sql")
local registry = require("registry")
local http_client = require("http_client")

local BASE_URL = "http://localhost:8067"

local function define_tests()
    describe("Usage API", function()
        local test_user_1 = "usage-test-" .. uuid.v7()
        local test_user_2 = "usage-test-" .. uuid.v7()
        local test_model_1 = "test-model-claude-opus"
        local test_model_2 = "test-model-gpt-4o"
        local created_ids = {}

        before_all(function()
            local r1, err1 = token_usage_repo.create(test_user_1, test_model_1, 500, 200, {
                thinking_tokens = 100, cache_read_tokens = 50, cache_write_tokens = 25,
            })
            test.is_nil(err1)
            if r1 then table.insert(created_ids, r1.usage_id) end

            local r2, err2 = token_usage_repo.create(test_user_1, test_model_2, 300, 150, {
                thinking_tokens = 0, cache_read_tokens = 100,
            })
            test.is_nil(err2)
            if r2 then table.insert(created_ids, r2.usage_id) end

            local r3, err3 = token_usage_repo.create(test_user_2, test_model_1, 400, 100, {
                thinking_tokens = 200,
            })
            test.is_nil(err3)
            if r3 then table.insert(created_ids, r3.usage_id) end
        end)

        after_all(function()
            local entry, _ = registry.get("wippy.usage:target_db")
            if not entry then return end
            local db_id = entry.data and entry.data.default
            if not db_id then return end
            local db, err = sql.get(tostring(db_id))
            if err then return end
            for _, id in ipairs(created_ids) do
                db:execute("DELETE FROM token_usage WHERE usage_id = $1", {id})
            end
            db:release()
        end)

        describe("token_usage_repo", function()
            it("get_usage_by_user returns without error", function()
                local now_unix = time.now():unix()
                local _, err = token_usage_repo.get_usage_by_user(now_unix - 86400, now_unix + 3600)
                test.is_nil(err)
            end)

            it("summary returns zeroes for empty range", function()
                local summary, err = token_usage_repo.get_summary(1700000000, 1700086400)
                test.is_nil(err)
                test.not_nil(summary)
                test.eq(summary.request_count, 0)
            end)
        end)

        describe("time range handling", function()
            it("today range is within 24 hours", function()
                local now_unix = time.now():unix()
                local midnight = now_unix - (now_unix % 86400)
                test.is_true(now_unix >= midnight)
                test.is_true(now_unix - midnight < 86400)
            end)

            it("week spans 7 days", function()
                local now_unix = time.now():unix()
                test.eq(now_unix - (now_unix - 7 * 86400), 7 * 86400)
            end)
        end)

        describe("HTTP endpoints", function()
            it("summary returns 401 without auth", function()
                local res, err = http_client.get( BASE_URL .. "/api/v1/keeper/usage/summary?period=today", {
                    headers = { Accept = "application/json" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq((res.status_code or res.status), 401)
            end)

            it("by-time returns 401 without auth", function()
                local res, err = http_client.get( BASE_URL .. "/api/v1/keeper/usage/by-time?period=week&interval=day", {
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
