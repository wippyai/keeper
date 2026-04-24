local test = require("test")
local run_test = require("run_test")

local function entry(id, suite)
    return { id = id, meta = { suite = suite } }
end

local function define_tests()
    describe("run_test.filter_entries", function()
        local catalog = {
            entry("a:t1", "core"),
            entry("a:t2", "core"),
            entry("b:t1", "branch"),
            entry("c:t1"),
        }

        it("returns entries matching entry_ids", function()
            local out, err = run_test.filter_entries(catalog, { entry_ids = { "a:t1", "b:t1" } })
            test.is_nil(err)
            test.eq(#out, 2)
        end)

        it("accepts entry_ids as a single string", function()
            local out, err = run_test.filter_entries(catalog, { entry_ids = "a:t1" })
            test.is_nil(err)
            test.eq(#out, 1)
            test.eq(out[1].id, "a:t1")
        end)

        it("merges entry_id into entry_ids", function()
            local out, err = run_test.filter_entries(catalog, {
                entry_ids = { "a:t1" },
                entry_id  = "b:t1",
            })
            test.is_nil(err)
            test.eq(#out, 2)
        end)

        it("reports missing ids alongside matches", function()
            local out, err, missing = run_test.filter_entries(catalog, {
                entry_ids = { "a:t1", "nope:x" },
            })
            test.is_nil(err)
            test.eq(#out, 1)
            test.not_nil(missing)
            test.eq(#missing, 1)
            test.eq(missing[1], "nope:x")
        end)

        it("errors when none of the entry_ids exist", function()
            local out, err = run_test.filter_entries(catalog, { entry_ids = { "nope:x" } })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("not found") ~= nil)
        end)

        it("filters by suite when entry_ids is absent", function()
            local out, err = run_test.filter_entries(catalog, { suite = "core" })
            test.is_nil(err)
            test.eq(#out, 2)
            for _, e in ipairs(out) do
                test.eq(e.meta.suite, "core")
            end
        end)

        it("errors when suite matches nothing", function()
            local out, err = run_test.filter_entries(catalog, { suite = "missing" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("no tests in suite") ~= nil)
        end)

        it("refuses to run without a scope", function()
            local out, err = run_test.filter_entries(catalog, {})
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("refusing to run") ~= nil)
        end)

        it("handles nil input catalog", function()
            local out, err = run_test.filter_entries(nil, { suite = "core" })
            test.is_nil(out)
            test.not_nil(err)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
