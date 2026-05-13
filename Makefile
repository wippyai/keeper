.PHONY: lint lint-keeper lint-usage build build-keeper-frontend build-keeper-git-frontend build-wippy-monaco-frontend build-usage-frontend clean-static dev dev-keeper dev-keeper-git dev-wippy-monaco dev-usage smoke publish-dry-run publish-keeper-dry-run publish-usage-dry-run publish publish-keeper publish-usage

WIPPY ?= wippy

KEEPER_VERSION ?= 0.5.19
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

# Aggregator — builds every FE app + the monaco WC. `make smoke` depends on this.
build: build-keeper-frontend build-keeper-git-frontend build-wippy-monaco-frontend build-usage-frontend

# Nuke all built FE artifacts. Forces the next `make build` to rebuild from
# scratch — useful when a stale chunk hash or hoisted asset stops a fix from
# landing in the live bundle.
clean-static:
	rm -rf keeper/static/keeper keeper/static/keeper-git keeper/static/wippy-monaco usage/static/keeper-usage

# Watch-mode dev builds. Vite writes into the same static/ outDir as `build`,
# so the running wippy server picks up the freshly emitted files on every
# save. `make dev` aliases the most common entry — the main keeper FE.
dev: dev-keeper

dev-keeper:
	cd keeper/frontend/applications/keeper && npm install --no-audit --no-fund --prefer-offline && npm run dev -- --outDir ../../../static/keeper

dev-keeper-git:
	cd keeper/plugins/git/frontend/applications/git && npm install --no-audit --no-fund --prefer-offline && npm run dev -- --outDir ../../../../../static/keeper-git

dev-wippy-monaco:
	cd keeper/frontend/web-components/wippy-monaco && npm install --no-audit --no-fund --prefer-offline && npm run dev -- --outDir ../../../static/wippy-monaco

dev-usage:
	cd usage/frontend/applications/usage && npm install --no-audit --no-fund --prefer-offline && npm run dev -- --outDir ../../../static/keeper-usage

# Headless-browser smoke against the keeper-test harness on $(BASE_URL).
# Phase 1 verifies dist/app.html exists for each app; phase 2 logs into
# keeper-test and boots keeper-main + keeper-git in dark + light themes,
# asserting no console errors. See test/smoke/README.md.
smoke:
	cd test/smoke && npm install --no-audit --no-fund --prefer-offline && npm run smoke

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
