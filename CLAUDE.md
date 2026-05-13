# keeper-v5

Wippy module monorepo. Two publishable modules + one bundled plugin.

- `keeper/` → `keeper/keeper` — control plane (registry/agents/MCP/Hub/UI/etc.)
- `usage/` → `keeper/usage` — token-usage analytics plugin
- `keeper/plugins/git/` — bundled git push/PR plugin (built into keeper/static at publish time)

Each child has its own `wippy.yaml`, `wippy.lock`, `src/` (Lua), and `frontend/applications/<name>/` (Vue 3 web app).

## Known FE gotchas

When a `<wippy-monaco>` or other Wippy web component silently renders as an unknown element, or you see one of these errors in the host's console — read [`C:/Projects/app-template/frontend/docs/web-component-loading.md`](file:///C:/Projects/app-template/frontend/docs/web-component-loading.md) and `wippy-kb` topic `web-component-loading` (KB: `wippy.frontend`) before digging in. The doc covers the autoload chain end-to-end and the recurring failure modes:

- `Proxy globals not found` at `entry.web-component.ts:93` (source line range 92–105) — host did not write `window.__WIPPY_APP_API__` before the WC bundle imported `@wippy-fe/proxy`. The race was an architectural issue in the host shell: `App.vue` / `ManagedLayoutShell.vue` are `defineAsyncComponent`'d, so `<VueAppGlobalConnector />` (the globals writer) doesn't mount synchronously during `app.mount()`, and the autoload-injected WC scripts could evaluate `@wippy-fe/proxy.js` before the connector mounted. Fixed upstream by co-locating `registerAutoloadComponents(...)` with the globals write inside the connector — gen-2-chat commit `a3f55926`, released as web-host 1.0.29 / `wippy/facade` 1.0.29. **1.0.29 is the current supported floor as of 2026-05-13.** If you hit this error on a stack pinned below 1.0.29, override `wippy/facade`'s `fe_facade_url` (`-o wippy.facade:fe_facade_url:default=https://web-host.wippy.ai/webcomponents-1.0.29`) or update the `wippy/facade` module dep.
- `ReferenceError: process is not defined` at `pinia.mjs:26` (source-mapped) — WC `vite.config.ts` is missing `'pinia'` in `rollupOptions.external`. Match the markdown WC pattern: `external: ['vue', 'pinia', '@iconify/vue', '@wippy-fe/proxy']`.
- Tag renders as a bare unknown element with no shadow content, no console error — `meta.announced: false` on a `view.component` registration filters it out of `/api/public/components/list` server-side (`wippy/views/api/list_components.lua:39` requires `announced == true`), so the host never injects its `<script>` tag. Flip to `announced: true` even for "internal" WCs that participate in autoload.
- `define()` never runs even though the bundle loads — Rollup hoisted the `define(import.meta.url, …)` statement into a sub-chunk. Set `rollupOptions.preserveEntrySignatures: false` in the WC's `vite.config.ts` so it stays in the entry chunk.
- WC registers, mounts content, but the consumer sees an empty / tiny box (`getBoundingClientRect()` returns near-zero height even though the parent has 300 px) — `:host` is `display: inline` and/or WippyVueElement's mount wrapper between `:host` and your Vue root has `height: auto` and collapses to content. Add `:host { display: block; width: 100%; height: 100% }` and `:host > div { width: 100%; height: 100% }` to the WC's `inlineCss` (`styles.css`). Reference: `keeper/frontend/web-components/wippy-monaco/src/styles.css`.
- `Uncaught SyntaxError: Unexpected token '<'` at `/assets/<chunk>-<hash>.js:1:1` (or any 404 with an `/assets/...` path) — the WC bundles a Web Worker (`?worker` import, or anything monaco/comlink/mlc-ai spawns) and Vite emitted `new Worker("/assets/...")` with a **root-absolute** path. Inside the consumer iframe (e.g. `<wippy-monaco>` loaded under `/c/keeper:main`), `/assets/...` resolves to the consumer's origin root, not the WC's mount path, so the consumer's static-server 404 HTML lands as JS and parses with "Unexpected token '<'". Regular `import` resolution is already relative and unaffected. **Fix:** set `base: './'` in the WC's `vite.config.ts` — Vite then emits `new Worker(new URL("assets/...", import.meta.url).href)` which resolves to the WC's mount dir. Reference: `keeper/frontend/web-components/wippy-monaco/vite.config.ts`.

### wippy-monaco-specific (this repo)

`wippy-monaco` patches monaco-editor via `patch-package` (see `keeper/frontend/web-components/wippy-monaco/patches/monaco-editor+0.55.1.patch`) for two things vanilla monaco doesn't handle in shadow DOM: (a) `createStyleSheet`'s default container is overridable, so runtime monaco styles land in the shadow root via `bindShadowStylesheetContainer`; (b) `StandaloneThemeService` supports per-host themes via `setHostTheme(host, name)` and a `_themeByHost` `WeakMap`, so two `<wippy-monaco>` elements with different `theme=` attrs render with their own palettes (vanilla monaco's theme is a singleton). The patch is auto-applied via `"postinstall": "patch-package"` in the WC's `package.json`. If a monaco upgrade lands, re-run `npx patch-package monaco-editor` after fixing any conflicts to re-capture the patch.

## Intentional patterns (do NOT "fix" these)

### Warm-grey theme duplicated 4 ways

The keeper warm-grey identity palette (`--kp-*` aliases + `--p-surface-N` ramps + `--p-content-background`/`--p-text-color` + `@light`/`@dark` blocks) is intentionally duplicated across **four** locations:

1. `keeper/src/keeper/_index.yaml` → `keeper:main` `meta.config_overrides.customization.cssVariables` (lines ~559-652)
2. `keeper/src/keeper/git/_index.yaml` → `keeper.git:main` `meta.config_overrides.customization.cssVariables` (lines ~47-140)
3. `keeper/frontend/applications/keeper/package.json` → `wippy.configOverrides.customization.cssVariables` (lines ~40-138)
4. `keeper/plugins/git/frontend/applications/git/package.json` → `wippy.configOverrides.customization.cssVariables` (lines ~41-139)

This is **NOT a §5.1 facade-first violation** — rev-3 §2.3 explicitly endorses `config_overrides` for the "artifact viewer with a brand identity that should not change with the host theme" use case. Both keeper-main and keeper-git are sub-apps that MUST look like keeper regardless of which host facade is loading them; the YAML pair is the canonical runtime path (host reads it and merges into AppConfig before CSS injection); the package.json pair is the host-less mirror so the apps theme correctly under dev-proxy / standalone preview.

**Maintenance rule:** when one of the four blocks changes, update the other three. The 45 `@dark` keys + 28 `@light` keys + 16 top-level keys MUST stay identical across all four. The keeper-v5 `usage` analytics app deliberately omits `configOverrides` (it inherits from the host facade, per rev-3 §5.1) — do not add a fifth copy there.

The Phase 3B rev-3 audit recommendation to migrate to a single `wippy/facade` `ns.dependency` was reviewed and rejected: keeper-main and keeper-git are sub-apps that need to carry their own identity, not just inherit. Treat the duplication as load-bearing.

## Mission of this CLAUDE.md

This repo's top-level Claude job is **FE compliance auditing**: validate that the Vue applications under `keeper/`, `usage/`, and the `git` plugin match the patterns documented in:

- `C:/Projects/app-template/frontend/docs/` — canonical Wippy FE spec (component-guide, app-guide, app-checklist, best-practices, host-spec, proxy-api)
- `C:/Projects/app-template/frontend/applications/main/` — reference Wippy "page" app (the one we are supposed to look like)
- `C:/Projects/gen-2-chat/` — the host that loads our apps; defines the proxy API surface, AppConfig, w-page rendering chain, message protocol (see `C:/Projects/gen-2-chat/CLAUDE.md`)
- `wippy-kb` MCP — primary source for Wippy backend/runtime questions

The work is split into three phases. **Stop at the end of every phase and confirm with the user before moving on.**

---

## Phase 0 — Research the keeper-v5 codebase (this file)

Done once, captured below so future runs don't have to re-discover it.

### FE applications in this repo

There are exactly **three** Wippy "page" apps to validate:

| App | Path | Built to | wippy.type | Notes |
|---|---|---|---|---|
| Keeper main UI | `keeper/frontend/applications/keeper/` | `keeper/static/keeper/` | `page` | The big one — ~88 .vue files, 28+ pages, custom registry editors, MCP/Hub/Tasks/Agents UIs. **Embedded** in module via `keeper.components:ui_static_fs` |
| Git plugin UI | `keeper/plugins/git/frontend/applications/git/` | `keeper/static/keeper-git/` | `page` | Single-page, vue-router, tiny |
| Usage analytics | `usage/frontend/applications/usage/` | `usage/static/keeper-usage/` (per package.json `outDir`) | `page` | Single-page, chart.js, tiny |

There are **no web components** in this repo (no `frontend/web-components/`). All FE is page-app style (iframe / `wippy.type = "page"`). Component-guide rules for `WippyVueElement` do not apply directly, but the styling / theme / proxy patterns do.

### Build pipeline

`Makefile` (top-level):
- `build-keeper-frontend` → `cd keeper/frontend/applications/keeper && npm install && npm run build`, then copies `dist/` into `keeper/static/keeper/`
- `build-keeper-git-frontend` → same shape for the git plugin into `keeper/static/keeper-git/`
- `publish-keeper` runs both FE builds, then `wippy publish`
- Usage has no FE build target in the Makefile (its package.json has `outDir: static/keeper-usage` — verify in Phase 1)

`make` is not installed on Windows — read the Makefile and run the commands directly.

### Keeper FE — directory map (the area validators will spend most time in)

`keeper/frontend/applications/keeper/`
```
app.html              # iframe entry, has `<script data-role="@wippy/scripts">` placeholder
package.json          # specification: wippy-component-1.0, type: page
vite.config.ts        # base: '/app/keeper/', inlineCssPlugin (inlines all CSS into <style>)
tsconfig.json
tailwind.config.ts
postcss.config.js
src/
├── app.ts            # bootstrap: $W.config/host/api/instance, theme override, route resolution, addCollection, createApp, provide(), createAppRouter
├── app/app.vue       # root: header w/ dropdown nav, search overlay, <router-view />
├── constants.ts      # InjectionKey symbols: HOST_API, AXIOS_INSTANCE, WIPPY_INSTANCE, WIPPY_CONFIG, ON_SUBSCRIPTION
├── types.ts          # HostApi / ProxyApiInstance / WippyConfig from `Awaited<ReturnType<...>>`
├── router/index.ts   # @wippy-fe/router createAppRouter factory (handles createMemoryHistory + initial-path replace + host.onRouteChanged + @history listener with navId echo suppression) + a bespoke window 'message' cmd-navigate listener
├── composables/
│   ├── useWippy.ts   # useHost / useApi / useWippy / useOn / useConfig
│   └── useUserProvider.ts
├── api/              # 15 typed REST clients + __tests__/ (hub.test.ts, registry.test.ts)
│   ├── changelog.ts changesets.ts components.ts dataflows.ts git.ts hub.ts knowledge.ts logger.ts mcp.ts plugins.ts pm.ts registry.ts sessions.ts tasks.ts usage.ts
├── components/
│   ├── DiffViewer.vue DotBadge.vue PluginHost.vue StatusBadge.vue
│   ├── shared/       # DetailPanel EntryDetailPanel ForceGraph JsonBlock LineChart MarkdownContent PageHeader TokenBar
│   ├── editors/      # EditorRegistry.ts + EditorWrapper.vue + 16 kind-specific editors + 15 reusable field components
│   │   ├── kinds/    # AgentEditor ContractBindingEditor ContractEditor EnvVariableEditor GenericEditor HttpEndpointEditor HttpRouterEditor LlmModelEditor LuaEditor NamespaceEditor ProcessServiceEditor SecurityPolicyEditor StorageEditor ToolEditor TraitEditor ViewComponentEditor ViewPageEditor
│   │   ├── fields/   # ArrayField BoolField EditorSection EntryPicker FieldRow JsonField LinkBadge MapField ModelSelect MonacoEditor NumberField SelectField SliderField StringField TagsField TextField
│   │   └── __tests__/
│   ├── messages/     # Msg{Artifact,Delegation,Developer,Function,Header,Renderer,System,Text}.vue + msg-utils.ts
│   ├── dataflow/     # DataRenderer DataTimeline NodeMetrics NodesList + node-utils.ts
│   └── hub/          # RequirementValueInput.vue + __tests__/
├── pages/            # 28 top-level routes (dashboard, sessions, agents, models, tools, traits, endpoints, policies, structure, dataflow-detail, plugin-page, logger, system, tests, settings*, knowledge, mcp, components, tasks, task-detail, changes, audit, workflow, session-detail, tools-page) + __tests__/
├── styles.css
├── tailwind.css
└── utils.ts
```

### Git plugin FE map

`keeper/plugins/git/frontend/applications/git/`
- Same shape as keeper but tiny: `src/{app,app.ts,components,composables,constants.ts,pages/git.vue,router,styles.css,tailwind.css,tones.ts,types.ts}`
- `components/`: 6 split components (`GitHeader`, `GitClusterList`, `GitClusterDetail`, `GitPushConfirmModal`, `GitSplitModal`, `GitDiffModal`) extracted from `pages/git.vue` (702 → 279 LOC). `tones.ts` holds shared importance/verdict/sev/recState lookup tables consumed by list + detail.
- No `api/` directory (uses inline calls via composables/useGit).
- `vite.config.ts` `base: '/app/keeper-git/'`, externals: `vue`, `vue-router`, `@iconify/vue`, `@wippy-fe/proxy`, `axios` (note: **no `pinia`** in externals)
- `package.json` peerDependencies includes `vue-router` but not `pinia` — confirm the app doesn't use pinia
- `wippy.proxy.injections.css` is **missing `markdown: true`** vs keeper main (intentional or oversight — flag in Phase 1)

### Usage FE map

`usage/frontend/applications/usage/`
- One page (`pages/usage.vue`), `components/shared/`, `chart.js` dep
- `package.json` has `wippy.outDir: "static/keeper-usage"` (Makefile doesn't build it — needs verification)
- Same caveat re: missing `markdown: true` injection key

### Reference / spec sources (where validators read from)

| What | Where |
|---|---|
| Canonical FE app patterns (gold) | `C:/Projects/app-template/frontend/applications/main/` (esp. `package.json`, `src/app.ts`, `src/router`, `src/types.ts`, `src/constants.ts`) |
| Vue page-app guide | `C:/Projects/app-template/frontend/docs/app-guide.md` |
| Web component guide (informational here — we have none) | `C:/Projects/app-template/frontend/docs/component-guide.md` |
| Pre-submission checklist | `C:/Projects/app-template/frontend/docs/app-checklist.md` |
| Vue/Tailwind/PrimeVue best practices | `C:/Projects/app-template/frontend/docs/best-practices.md` |
| Host-side contract (package.json shape, lifecycle) | `C:/Projects/app-template/frontend/docs/host-spec.md` |
| Proxy API reference | `C:/Projects/app-template/frontend/docs/proxy-api.md` |
| Host architecture, message protocol, w-page rendering | `C:/Projects/gen-2-chat/CLAUDE.md` + `C:/Projects/gen-2-chat/README.md` |
| AppConfig / proxy injection definitions | `C:/Projects/gen-2-chat/src/shared/app-config/` and `src/shared/api/web-components/constants.ts` |
| `@wippy-fe/*` source | `C:/Projects/gen-2-chat/npm/@wippy-fe--proxy/`, `npm/@wippy-fe--theme/`, `npm/@wippy-fe--router/`, `npm/@wippy-fe--pinia-persist/` |
| Backend / runtime questions | `wippy-kb` MCP first, then `https://wippy.ai/llms.txt` |

### Key non-obvious things to remember

- **No web components in keeper-v5** — `WippyVueElement` rules don't apply, but theme variables, semantic colors, and proxy access patterns do.
- Keeper main app uses **dropdown-style nav in `app.vue`**, not a sidebar — diverges visually from the app-template main app, but that is by design (compact operator console). Don't "fix" this in compliance review.
- Keeper main app **does NOT** use:
  - PrimeVue (`PrimeVuePlugin` is not registered in `app.ts`) — it uses raw HTML buttons, custom CSS dropdowns, custom icons via `@iconify/vue`
  - `@wippy-fe/pinia-persist` (it does use pinia + custom localStorage for `@keeper/theme`)
  - TanStack Query
- Keeper FE **inlines all CSS into the built HTML** via a custom `inlineCssPlugin` in `vite.config.ts` (so the published static folder is a single self-contained app). The git plugin does the same trick.
- `vite.config.ts` `base` is `/app/keeper/` and `/app/keeper-git/` — these are served by the host's UI server requirement (`keeper:ui_server`). Empty-string base from app-guide does **not** apply here because keeper apps live at known fixed mount points.
- `app.ts` reads route from `config.context.route` only (gen-2-chat's `loadWebPageByPackageJson` reliably populates it from the URL sub-path including query string — verified live). No localStorage / parent-URL fallbacks.
- Theme override: keeper supports `?theme=light|dark` URL param + `@keeper/theme` localStorage. Custom and not in app-template.
- Hub flow: see `README.md` "Hub Flow". Install planning is required before install — UI must surface the requirement list.
- `keeper:*` namespace requirements (api_router, app_db, admin_scope, env_storage, public_gateway, mcp_route, ui_server, process_host) — read from `wippy.yaml`, not hardcoded.

### Build verification

To verify the FE builds work end-to-end:

```bash
# Keeper main
cd C:/Projects/keeper-v5/keeper/frontend/applications/keeper && npm install && npm run build
cd C:/Projects/keeper-v5/keeper/frontend/applications/keeper && npm run type-check

# Git plugin
cd C:/Projects/keeper-v5/keeper/plugins/git/frontend/applications/git && npm install && npm run build

# Usage
cd C:/Projects/keeper-v5/usage/frontend/applications/usage && npm install && npm run build
```

If running long-running watchers, use `bg_run` (see `~/.claude/CLAUDE.md`).

### Sandboxed scratch space

Phase 1 reports and Phase 2 fix logs go in `.local/` (gitignored). Use `YYYY-MM-DD-` prefix and a `[drafted|in-progress|completed]` status tag.

---

## Phase 1 — Multi-agent FE compliance audit

Goal: produce a structured set of findings (`.local/<date>-fe-compliance/`) covering every FE app, scored against the docs in `app-template/frontend/docs/` and the patterns in `app-template/frontend/applications/main/`.

**Run agents in parallel** (single message, multiple `Agent` tool calls). Each gets a focused scope so its context window stays useful.

### Scope per agent

1. **Bootstrap & build config** — `app.html`, `app.ts`, `vite.config.ts`, `tsconfig.json`, `package.json`, `postcss.config.js`, `tailwind.config.ts` for all 3 apps
   - Verify externals match host import map (`vue`, `pinia`, `vue-router`, `@iconify/vue`, `axios`, `@wippy-fe/proxy`, `nanoevents`, `luxon`, `primevue/*`)
   - `specification: "wippy-component-1.0"`, `wippy.type: "page"`, `wippy.path`, `wippy.proxy.injections.*` keys
   - peerDependencies vs dependencies vs devDependencies hygiene
   - `<script data-role="@wippy/scripts">` placeholder present in app.html
   - `base` is set deliberately (and matches the wippy mount point if not empty)

2. **Router & host integration** — `src/router/`, route registration, history setup
   - `createMemoryHistory()` (NOT `createWebHistory`)
   - `history.replace(initialPath)` set BEFORE `createRouter`
   - `router.afterEach(host.onRouteChanged)`
   - `on('@history', ...)` listener with null check
   - Catch-all `/:pathMatch(.*)*` route
   - Initial path resolution from `config.context?.route || config.path`

3. **Proxy API usage** — every Vue file that calls `api`, `host`, `instance`, `on`
   - Authenticated calls go through injected `useApi()` not raw `axios.create`
   - `host.toast` / `host.confirm` / `host.startChat` / `host.openSession` / `host.openArtifact` / `host.setContext` / `host.navigate` / `host.handleError` usage matches `proxy-api.md`
   - WebSocket subscriptions cleaned up in `onUnmounted`
   - `instance.on(pattern, cb)` returns are stored and invoked on cleanup
   - No raw `window.parent.postMessage` outside the established message bridge

4. **Styling & theming** — `*.vue <style>`, `styles.css`, `tailwind.css`, inline styles
   - Semantic CSS vars: `--p-text-color`, `--p-content-background`, `--p-content-border-color`, `--p-primary-color`, `--p-text-muted-color`, severity vars (`--p-danger-*`, `--p-success-*`, `--p-warn-*`, `--p-info-*`, `--p-help-*`, `--p-accent-*`)
   - Flag raw `--p-surface-N`, hardcoded colors (`#hex`, raw rgb), and raw Tailwind color names where they convey semantic meaning (`red-*`, `green-*`, `orange-*`, `sky-*`, `purple-*`)
   - Dark-mode parity (no light-only assumptions)
   - No root-level padding/margin in shared/web-component-style components

5. **Vue/Composition API quality** — every page + component
   - `<script setup lang="ts">`
   - `defineProps` with TS interfaces, `defineEmits` typed
   - `ref` over `reactive`, `computed` over methods
   - Async error handling (try/catch around `api.*`, surface via `host.toast` or `host.handleError`)
   - No `console.log` (warn/error allowed)
   - Avoid `any` — flag every `: any` and `as any`
   - `kebab-case` filenames

6. **Wippy package + injection config** — `package.json` `wippy.*` for each app
   - `injections.css.*` keys (fonts/themeConfig/iframe/primevue/markdown/customCss/customVariables) — flag drift between apps (e.g. usage + git missing `markdown`)
   - `tailwindConfig`, `resizeObserver`, `preventLinkClicks`, `iconifyIcons`, `errorCapture`, `refreshWhenVisible` set deliberately
   - `wippy.scripts.{build,debug}` mapped correctly
   - Versions pinned consistently (`@wippy-fe/theme`, `@wippy-fe/types-global-proxy`)

7. **Tests & TS hygiene** — existing `__tests__/` directories
   - Run `npm run type-check` and `npm test` per app, capture output
   - Verify Pinia stores (if any) and editors registry stay typed end-to-end

Each agent must:
- Read `app-template/frontend/docs/<relevant>.md` for its scope before reviewing
- Output a markdown report with `PASS / FAIL / WARN` per file with line numbers
- Save to `.local/<YYYY-MM-DD>-fe-compliance/<scope>.md`

After all agents return, **stop**. Summarize the combined findings to the user, propose fix priorities, and wait for the go-ahead before Phase 2.

---

## Phase 2 — Apply fixes

Drive from the Phase 1 findings. Group fixes by area, edit, type-check, build, then verify nothing regressed.

Rules:
- Don't refactor or "clean up" anything outside the flagged findings.
- For each visual change in `keeper-v5/keeper/frontend/applications/keeper/`, rebuild and (if possible) load it in the host to confirm rendering.
- Update `.local/<YYYY-MM-DD>-fe-compliance/<scope>.md` status from `[drafted]` → `[in-progress]` → `[completed]`.
- After each fix batch, run:
  - `npm run type-check` in the affected app
  - `npm run build`
  - `make lint` (top-level — runs `wippy lint` on both modules)
- Do not run `make publish-*` autonomously — publishing is a user-confirmed action.

Stop at the end of Phase 2 and confirm with the user before any release activity.

---

## Repo conventions

- **`.local/`** — scratch / plans / reports (gitignored). `YYYY-MM-DD-` prefix + `[drafted|in-progress|completed]` tag.
- **Memory** — keeper-v5 has its own per-project memory under `~/.claude/projects/C--Projects-keeper-v5/memory/`. Save findings worth carrying across sessions there (per `~/.claude/CLAUDE.md` "auto memory" guidance).
- **Wippy CLI** — invoke per-module: `cd keeper && wippy lint --ns 'keeper,keeper.*' --summary --limit 200 --no-color` and `cd usage && wippy lint --summary --limit 200 --no-color`.
- **Process management** — use `bg-manager` MCP, never bash `&`.
- **Git** — use `git-mcp-server` MCP tools with absolute paths (no `git_set_working_dir`).

## Useful one-shots

```bash
# Find every place in keeper FE that calls a host method or proxy import:
# (run via Grep tool, not bash):
#   pattern: "host\\.(toast|confirm|startChat|openSession|openArtifact|setContext|navigate|handleError|onRouteChanged|formatUrl|logout)"
#   pattern: "from '@wippy-fe/proxy'"

# Type-check a single app:
cd C:/Projects/keeper-v5/keeper/frontend/applications/keeper && npm run type-check

# Run keeper FE tests:
cd C:/Projects/keeper-v5/keeper/frontend/applications/keeper && npm test
```
