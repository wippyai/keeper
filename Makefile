.PHONY: lint lint-keeper lint-usage build-keeper-frontend publish-dry-run publish-keeper-dry-run publish-usage-dry-run publish publish-keeper publish-usage

WIPPY ?= wippy

KEEPER_VERSION ?= 0.5.8
USAGE_VERSION ?= 0.1.1

lint: lint-keeper lint-usage

lint-keeper:
	cd keeper && $(WIPPY) lint --ns 'keeper.config,keeper.config.*,keeper.mcp.*,keeper.knowledge,keeper.components,keeper.internal.flow,keeper.internal.session' --summary --limit 200 --no-color

lint-usage:
	cd usage && $(WIPPY) lint --summary --limit 200 --no-color

build-keeper-frontend:
	cd keeper/frontend/applications/keeper && npm install --no-audit --no-fund --prefer-offline && npm run build
	rm -rf keeper/static/keeper
	mkdir -p keeper/static/keeper
	cp -a keeper/frontend/applications/keeper/dist/. keeper/static/keeper/

publish-dry-run: publish-keeper-dry-run publish-usage-dry-run

publish-keeper-dry-run: build-keeper-frontend
	cd keeper && $(WIPPY) publish --dry-run --version $(KEEPER_VERSION)

publish-usage-dry-run:
	cd usage && $(WIPPY) publish --dry-run --version $(USAGE_VERSION)

publish: publish-keeper publish-usage

publish-keeper: build-keeper-frontend
	cd keeper && $(WIPPY) publish --version $(KEEPER_VERSION)

publish-usage:
	cd usage && $(WIPPY) publish --version $(USAGE_VERSION)
