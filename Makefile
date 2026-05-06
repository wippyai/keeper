.PHONY: lint lint-keeper lint-usage build-keeper-frontend build-keeper-git-frontend build-wippy-monaco-frontend build-usage-frontend publish-dry-run publish-keeper-dry-run publish-usage-dry-run publish publish-keeper publish-usage

WIPPY ?= wippy

KEEPER_VERSION ?= 0.5.16
USAGE_VERSION ?= 0.1.1

lint: lint-keeper lint-usage

lint-keeper:
	cd keeper && $(WIPPY) lint --ns 'keeper,keeper.*' --summary --limit 200 --no-color

lint-usage:
	cd usage && $(WIPPY) lint --summary --limit 200 --no-color

build-keeper-frontend:
	cd keeper/frontend/applications/keeper && npm install --no-audit --no-fund --prefer-offline && npm run build -- --outDir ../../../static/keeper --emptyOutDir

build-keeper-git-frontend:
	cd keeper/plugins/git/frontend/applications/git && npm install --no-audit --no-fund --prefer-offline && npm run build -- --outDir ../../../../../static/keeper-git --emptyOutDir

build-wippy-monaco-frontend:
	cd keeper/frontend/web-components/wippy-monaco && npm install --no-audit --no-fund --prefer-offline && npm run build -- --outDir ../../../static/wippy-monaco --emptyOutDir

build-usage-frontend:
	cd usage/frontend/applications/usage && npm install --no-audit --no-fund --prefer-offline && npm run build -- --outDir ../../../static/keeper-usage --emptyOutDir

publish-dry-run: publish-keeper-dry-run publish-usage-dry-run

publish-keeper-dry-run: build-keeper-frontend build-keeper-git-frontend build-wippy-monaco-frontend
	cd keeper && $(WIPPY) publish --dry-run --version $(KEEPER_VERSION)

publish-usage-dry-run: build-usage-frontend
	cd usage && $(WIPPY) publish --dry-run --version $(USAGE_VERSION)

publish: publish-keeper publish-usage

publish-keeper: build-keeper-frontend build-keeper-git-frontend build-wippy-monaco-frontend
	cd keeper && $(WIPPY) publish --version $(KEEPER_VERSION)

publish-usage: build-usage-frontend
	cd usage && $(WIPPY) publish --version $(USAGE_VERSION)
