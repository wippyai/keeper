local json = require("json")
local selector = require("selector")

local function define_tests()
    describe("Pattern Selector Unit", function()
        local sample_patterns = {
            {
                id = "patterns:api_implementation",
                title = "REST API Implementation",
                comment = "Guidelines for building RESTful APIs",
                class = {"development", "backend", "api"},
                tags = {"rest", "http"},
                content = "When implementing REST APIs:\n1. Use proper HTTP verbs\n2. Structure endpoints hierarchically"
            },
            {
                id = "patterns:error_handling",
                title = "Error Handling Pattern",
                comment = "Best practices for error handling",
                class = {"development", "backend"},
                tags = {"errors", "exceptions"},
                content = "Error handling guidelines:\n1. Always return meaningful errors\n2. Use appropriate status codes"
            },
            {
                id = "patterns:security_auth",
                title = "Authentication Security",
                comment = "Security patterns for authentication",
                class = {"development", "security"},
                tags = {"auth", "security"},
                content = "Security best practices:\n1. Use strong password hashing\n2. Implement rate limiting"
            }
        }

        before_each(function()
            selector._deps = {
                pattern_registry = {
                    list_by_classes = function(classes)
                        if not classes or #classes == 0 then
                            return table.create(0, 0)
                        end
                        local results = table.create(#sample_patterns, 0)
                        local count = 0
                        for _, pattern in ipairs(sample_patterns) do
                            for _, requested_class in ipairs(classes) do
                                for _, pattern_class in ipairs(pattern.class) do
                                    if pattern_class == requested_class then
                                        count = count + 1
                                        results[count] = pattern
                                        goto continue
                                    end
                                end
                            end
                            ::continue::
                        end
                        return results
                    end
                },
                llm = {
                    structured_output = function(schema, prompt, options)
                        print("LLM called with prompt:\n" .. prompt)
                        local user_prompt = prompt:match('User Request: "([^"]*)"') or ""
                        local p = user_prompt:lower()

                        if p:match("llm[_%-]?error") then
                            return nil, "Simulated LLM error"
                        elseif p:match("unrelated") then
                            return {result = {selected_pattern_ids = {}, reasoning = "No relevant"}}, nil
                        elseif p:match("security") or p:match("authentication") then
                            return {result = {selected_pattern_ids = {"patterns:security_auth"}, reasoning = "Security"}}, nil
                        elseif p:match("rest") and p:match("api") then
                            return {result = {selected_pattern_ids = {"patterns:api_implementation", "patterns:error_handling"}, reasoning = "API"}}, nil
                        elseif p:match("build") or p:match("api") then
                            return {result = {selected_pattern_ids = {"patterns:api_implementation"}, reasoning = "Default"}}, nil
                        else
                            return {result = {selected_pattern_ids = {}, reasoning = "No match"}}, nil
                        end
                    end
                }
            }
        end)

        after_each(function()
            selector._deps = {
                pattern_registry = require("pattern_registry"),
                llm = require("llm")
            }
        end)

        it("should return XML string", function()
            local result, err = selector.select_patterns("I need to build a REST API endpoint", {"development", "backend"}, nil, "xml")
            expect(err).to_be_nil()
            expect(type(result)).to_equal("string")
            expect(result).to_contain("<patterns>")
            expect(result).to_contain("patterns:api_implementation")
        end)

        it("should return empty XML", function()
            local result, err = selector.select_patterns("Something completely unrelated", {"development"}, nil, "xml")
            expect(err).to_be_nil()
            expect(result).to_equal("<patterns></patterns>")
        end)

        it("should return JSON table", function()
            local result, err = selector.select_patterns("I need to build a REST API endpoint", {"development", "backend"}, nil, "json")
            expect(err).to_be_nil()
            expect(type(result)).to_equal("table")
            expect(result.patterns).not_to_be_nil()
            expect(#result.patterns).to_equal(2)
        end)

        it("should default to json", function()
            local result, err = selector.select_patterns("Build API", {"development"})
            expect(err).to_be_nil()
            expect(type(result)).to_equal("table")
        end)

        it("should return empty patterns", function()
            local result, err = selector.select_patterns("Something completely unrelated", {"development"}, nil, "json")
            expect(err).to_be_nil()
            expect(#result.patterns).to_equal(0)
        end)

        it("should error on empty prompt", function()
            local result, err = selector.select_patterns("", {"development"})
            expect(result).to_be_nil()
            expect(err).to_contain("User prompt is required")
        end)

        it("should error on nil prompt", function()
            local result, err = selector.select_patterns(nil, {"development"})
            expect(result).to_be_nil()
            expect(err).to_contain("User prompt is required")
        end)

        it("should error on empty classes", function()
            local result, err = selector.select_patterns("Test", {})
            expect(result).to_be_nil()
            expect(err).to_contain("Classes array is required")
        end)

        it("should error on LLM failure", function()
            local result, err = selector.select_patterns("LLM_ERROR trigger", {"development"})
            expect(result).to_be_nil()
            expect(err).to_contain("Failed to select patterns")
        end)

        it("should pass correct parameters", function()
            local captured_schema, captured_prompt, captured_options = nil, nil, nil
            selector._deps.llm.structured_output = function(schema, prompt, options)
                captured_schema = schema
                captured_prompt = prompt
                captured_options = options
                return {result = {selected_pattern_ids = {}, reasoning = "Test"}}, nil
            end

            selector.select_patterns("Test", {"development"})

            expect(captured_schema).not_to_be_nil()
            expect(captured_schema.type).to_equal("object")
            expect(captured_prompt).to_contain("Test")
            expect(captured_options.model).to_equal("gpt-5-nano")
            expect(captured_options.temperature).to_equal(0)
        end)

        it("should use system guidance", function()
            local captured_prompt = nil
            selector._deps.llm.structured_output = function(schema, prompt, options)
                captured_prompt = prompt
                return {result = {selected_pattern_ids = {"patterns:api_implementation"}, reasoning = "Test"}}, nil
            end

            selector.select_patterns("Build API", {"development"}, "High priority")

            expect(captured_prompt).to_contain("Additional Context:")
            expect(captured_prompt).to_contain("High priority")
        end)

        it("should work with execute", function()
            local result, err = selector.execute({
                user_prompt = "Build REST API",
                classes = {"development", "backend"}
            })

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(type(result)).to_equal("table")
        end)

        it("should work with xml format", function()
            local result, err = selector.execute({
                user_prompt = "Build REST API",
                classes = {"development", "backend"},
                output_format = "xml"
            })

            expect(err).to_be_nil()
            expect(type(result)).to_equal("string")
            expect(result).to_contain("<patterns>")
        end)

        it("should handle nil input", function()
            local result, err = selector.execute(nil)
            expect(result).to_be_nil()
            expect(err).to_contain("Input is required")
        end)
    end)

    describe("Pattern Selector Integration", function()
        local sample_patterns = {
            {
                id = "patterns:api_implementation",
                title = "REST API Implementation",
                comment = "Guidelines for building RESTful APIs",
                class = {"development", "backend", "api"},
                tags = {"rest", "http"},
                content = "When implementing REST APIs:\n1. Use proper HTTP verbs\n2. Structure endpoints hierarchically"
            },
            {
                id = "patterns:error_handling",
                title = "Error Handling Pattern",
                comment = "Best practices for error handling",
                class = {"development", "backend"},
                tags = {"errors", "exceptions"},
                content = "Error handling guidelines:\n1. Always return meaningful errors\n2. Use appropriate status codes"
            },
            {
                id = "patterns:security_auth",
                title = "Authentication Security",
                comment = "Security patterns for authentication",
                class = {"development", "security"},
                tags = {"auth", "security"},
                content = "Security best practices:\n1. Use strong password hashing\n2. Implement rate limiting"
            }
        }

        before_each(function()
            selector._deps.pattern_registry = {
                list_by_classes = function(classes)
                    if not classes or #classes == 0 then
                        return table.create(0, 0)
                    end
                    local results = table.create(#sample_patterns, 0)
                    local count = 0
                    for _, pattern in ipairs(sample_patterns) do
                        for _, requested_class in ipairs(classes) do
                            for _, pattern_class in ipairs(pattern.class) do
                                if pattern_class == requested_class then
                                    count = count + 1
                                    results[count] = pattern
                                    goto continue
                                end
                            end
                        end
                        ::continue::
                    end
                    return results
                end
            }
        end)

        after_each(function()
            selector._deps.pattern_registry = require("pattern_registry")
        end)

        it("should call real LLM for JSON", function()
            local result, err = selector.execute({
                user_prompt = "Help me implement proper error handling in my REST API",
                classes = {"development"},
                output_format = "json"
            })

            expect(err).to_be_nil()
            expect(type(result)).to_equal("table")
            expect(result.patterns).not_to_be_nil()
            expect(result.reasoning).not_to_be_nil()
            expect(type(result.reasoning)).to_equal("string")
        end)

        it("should call real LLM for XML", function()
            local result, err = selector.execute({
                user_prompt = "Show me security best practices",
                classes = {"security", "development"},
                output_format = "xml"
            })

            expect(err).to_be_nil()
            expect(type(result)).to_equal("string")
            expect(result).to_contain("<patterns>")
        end)

        it("should handle empty results", function()
            local result, err = selector.execute({
                user_prompt = "Test",
                classes = {"nonexistent_class_12345"}
            })

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
        end)
    end)
end

return require("test").run_cases(define_tests)