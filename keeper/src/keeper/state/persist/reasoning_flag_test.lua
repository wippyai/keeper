local test = require("test")
local models = require("models")
local openai_mapper = require("openai_mapper")

local function define_tests()
    describe("nano-class reasoning flag (declarative)", function()
        it("nano-class model exposes reasoning_model_request on its provider", function()
            local cards, err = models.get_by_class("nano")
            test.is_nil(err)
            test.not_nil(cards)
            test.eq(#cards > 0, true)
            local card = cards[1]
            test.not_nil(card.providers)
            local provider = card.providers[1]
            test.not_nil(provider)
            -- Entry name + provider_model both pin to the actual upstream
            -- model id so token_usage rows surface the real model. Earlier
            -- the entry was named "gpt-5-nano" while provider_model said
            -- "gpt-5.4-nano" — the test even asserted the older name.
            test.eq(provider.provider_model, "gpt-5.4-nano")
            test.not_nil(provider.options)
            test.eq(provider.options.reasoning_model_request, true)
        end)

        it("map_options routes max_tokens -> max_completion_tokens when flag is set", function()
            local mapped = openai_mapper.map_options({
                max_tokens = 1024,
                reasoning_model_request = true,
            })
            test.eq(mapped.max_completion_tokens, 1024)
            test.is_nil(mapped.max_tokens)
        end)

        it("map_options leaves max_tokens alone when flag is absent", function()
            local mapped = openai_mapper.map_options({
                max_tokens = 1024,
            })
            test.eq(mapped.max_tokens, 1024)
            test.is_nil(mapped.max_completion_tokens)
        end)

        it("map_options suppresses temperature when reasoning flag set", function()
            local mapped = openai_mapper.map_options({
                temperature = 0.5,
                reasoning_model_request = true,
            })
            test.is_nil(mapped.temperature)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
