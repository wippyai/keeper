local pattern_registry = require("pattern_registry")

local function define_tests()
    describe("Pattern Registry", function()
        local mock_registry

        -- Sample pattern data
        local sample_patterns = {
            {
                id = "patterns:api_pattern",
                kind = "registry.entry",
                meta = {
                    type = "pattern",
                    title = "API Implementation Pattern",
                    comment = "Guidelines for REST API implementation",
                    class = {"development", "backend", "api"},
                    tags = {"rest", "http"}
                },
                data = {
                    content = "API implementation guidelines..."
                }
            },
            {
                id = "patterns:security_pattern",
                kind = "registry.entry",
                meta = {
                    type = "pattern",
                    title = "Security Best Practices",
                    comment = "Security guidelines for development",
                    class = {"development", "security"},
                    tags = {"auth", "encryption"}
                },
                data = {
                    content = "Security best practices..."
                }
            },
            {
                id = "patterns:frontend_pattern",
                kind = "registry.entry",
                meta = {
                    type = "pattern",
                    title = "Frontend Development Pattern",
                    comment = "UI/UX implementation guidelines",
                    class = "frontend",  -- Single string class
                    tags = {"ui", "ux"}
                },
                data = {
                    content = "Frontend guidelines..."
                }
            }
        }

        before_each(function()
            mock_registry = {
                get = function(id)
                    for _, pattern in ipairs(sample_patterns) do
                        if pattern.id == id then
                            return pattern
                        end
                    end
                    return nil, "Not found"
                end,

                find = function(query)
                    if query["meta.type"] == "pattern" then
                        return sample_patterns
                    end
                    return {}
                end
            }

            pattern_registry._registry = mock_registry
        end)

        after_each(function()
            pattern_registry._registry = nil
        end)

        describe("get_by_id", function()
            it("should retrieve pattern by ID", function()
                local pattern, err = pattern_registry.get_by_id("patterns:api_pattern")

                expect(err).to_be_nil()
                expect(pattern).not_to_be_nil()
                expect(pattern.id).to_equal("patterns:api_pattern")
                expect(pattern.title).to_equal("API Implementation Pattern")
                expect(pattern.comment).to_equal("Guidelines for REST API implementation")
                expect(#pattern.class).to_equal(3)
                expect(pattern.content).to_equal("API implementation guidelines...")
            end)

            it("should error on missing ID", function()
                local pattern, err = pattern_registry.get_by_id(nil)

                expect(pattern).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Pattern ID is required")
            end)

            it("should error on non-existent pattern", function()
                local pattern, err = pattern_registry.get_by_id("patterns:nonexistent")

                expect(pattern).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("No pattern found")
            end)
        end)

        describe("list_by_classes", function()
            it("should find patterns matching single class", function()
                local patterns = pattern_registry.list_by_classes({"development"})

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(2)  -- api_pattern and security_pattern
            end)

            it("should find patterns matching multiple classes", function()
                local patterns = pattern_registry.list_by_classes({"backend", "frontend"})

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(2)  -- api_pattern and frontend_pattern
            end)

            it("should find patterns with string class", function()
                local patterns = pattern_registry.list_by_classes({"frontend"})

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(1)
                expect(patterns[1].id).to_equal("patterns:frontend_pattern")
            end)

            it("should return empty array for non-matching classes", function()
                local patterns = pattern_registry.list_by_classes({"nonexistent"})

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(0)
            end)

            it("should handle empty classes array", function()
                local patterns = pattern_registry.list_by_classes({})

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(3)  -- Returns all patterns
            end)

            it("should handle nil classes", function()
                local patterns = pattern_registry.list_by_classes(nil)

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(3)  -- Returns all patterns
            end)
        end)

        describe("list_all", function()
            it("should return all patterns", function()
                local patterns = pattern_registry.list_all()

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(3)
            end)

            it("should return raw entries when requested", function()
                local patterns = pattern_registry.list_all({raw_entries = true})

                expect(patterns).not_to_be_nil()
                expect(#patterns).to_equal(3)
                expect(patterns[1].kind).to_equal("registry.entry")
            end)
        end)

        describe("Pattern Spec Conversion", function()
            it("should convert pattern with all fields", function()
                local pattern, err = pattern_registry.get_by_id("patterns:api_pattern")

                expect(err).to_be_nil()
                expect(pattern.id).not_to_be_nil()
                expect(pattern.title).not_to_be_nil()
                expect(pattern.comment).not_to_be_nil()
                expect(pattern.class).not_to_be_nil()
                expect(pattern.tags).not_to_be_nil()
                expect(pattern.content).not_to_be_nil()
            end)

            it("should handle missing optional fields", function()
                mock_registry.get = function(id)
                    if id == "patterns:minimal" then
                        return {
                            id = "patterns:minimal",
                            kind = "registry.entry",
                            meta = {
                                type = "pattern"
                            },
                            data = {}
                        }
                    end
                    return nil
                end

                local pattern, err = pattern_registry.get_by_id("patterns:minimal")

                expect(err).to_be_nil()
                expect(pattern).not_to_be_nil()
                expect(pattern.title).to_equal("")
                expect(pattern.comment).to_equal("")
                expect(type(pattern.class)).to_equal("table")
                expect(type(pattern.tags)).to_equal("table")
                expect(pattern.content).to_equal("")
            end)
        end)

        describe("Class Matching", function()
            it("should match when pattern has multiple classes", function()
                local patterns = pattern_registry.list_by_classes({"api"})

                expect(#patterns).to_equal(1)
                expect(patterns[1].id).to_equal("patterns:api_pattern")
            end)

            it("should match ANY class (not ALL)", function()
                local patterns = pattern_registry.list_by_classes({"security", "nonexistent"})

                expect(#patterns).to_equal(1)
                expect(patterns[1].id).to_equal("patterns:security_pattern")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)