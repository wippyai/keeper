# keeper-v5 smoke tests

Headless-browser smoke for the 3 keeper-v5 FE apps.

Two phases run in sequence:

1. **Build verification** — confirms `dist/app.html` exists for each app
   (keeper-main, keeper-git, usage). Fails fast with a clear message if any
   build is missing — run `make build` first.

2. **Live-boot verification** — drives Playwright + chromium against the
   keeper-test harness. For each app keeper-test actually mounts
   (keeper-main, keeper-git), the runner logs in, navigates, waits for boot,
   captures dark + light screenshots, and asserts no console errors / page
   errors during boot.

Usage analytics (`/app/keeper-usage/`) is built but NOT live-smoked because
keeper-test's `wippy.lock` doesn't depend on `keeper/usage`. Add it to
`LIVE_APPS` in `smoke.mjs` once your harness mounts the analytics module.

## Run

```bash
# from keeper-v5 repo root
make build       # populate dist/ for all 3 apps
make smoke       # build-verify + live-smoke (assumes keeper-test on :8085)
```

Or directly:

```bash
cd test/smoke
npm install
npm run smoke
```

Watch the browser:

```bash
HEADLESS=false npm run smoke
```

## Env

| Var | Default | Purpose |
|---|---|---|
| `BASE_URL` | `http://localhost:8085` | keeper-test gateway URL |
| `SMOKE_USER` | `admin@wippy.local` | login email |
| `SMOKE_PASS` | `admin123` | login password |
| `SCREENSHOT_DIR` | `<repo>/.local/smoke-screenshots` | output dir |
| `HEADLESS` | `true` | set `false` to watch live |
| `TIMEOUT_MS` | `30000` | per-page boot wait |

## Exit codes

| Code | Meaning |
|---|---|
| 0 | all phases passed |
| 1 | build verification failed (run `make build`) |
| 2 | live boot failed (boot timeout or console/page errors) |
| 3 | keeper-test not reachable at `BASE_URL` |

## What it does NOT cover

- Visual regression (no golden image comparison).
- Full E2E user flows beyond initial boot.
- API/business-logic tests (those live in each app's `__tests__/` vitest).
- Accessibility audit (axe-core scan is a planned follow-up; `<Icon>` /
  ARIA scoping is tracked in Phase 3E).
- Usage analytics live boot (built only — see note above).

## When to run

- After any FE change (each PR).
- Before publishing keeper or usage modules.
- As a CI gate once the keeper-test harness is wired into CI.
