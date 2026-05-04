local test = require("test")
local models = require("models")

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
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
