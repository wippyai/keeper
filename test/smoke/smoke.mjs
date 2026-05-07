#!/usr/bin/env node
// Smoke test for keeper-v5.
//
// Two phases:
//   1. Build verification — confirm `dist/app.html` exists for all 3 FE apps
//      (keeper-main, keeper-git, usage). Fails fast with a clear message if
//      a build is missing — run `make build` first.
//
//   2. Live-boot verification — drive a headless browser through the
//      keeper-test harness (default http://localhost:8085) for the two apps
//      that keeper-test actually serves: keeper-main + keeper-git. Usage is
//      built but not mounted in keeper-test (its `wippy.lock` carries
//      `wippy/usage` upstream, not `keeper/usage`), so we only build-verify
//      it. For each app: log in, navigate, wait for boot, capture dark + light
//      screenshots, assert no console errors / page errors during boot.
//
// Env knobs:
//   BASE_URL          (default http://localhost:8085)
//   SMOKE_USER        (default admin@wippy.local)
//   SMOKE_PASS        (default admin123)
//   SCREENSHOT_DIR    (default <repo>/.local/smoke-screenshots)
//   HEADLESS          (default true; set HEADLESS=false to watch)
//   TIMEOUT_MS        (default 30000 — per-page boot wait)
//
// Exit codes:
//   0 — all phases passed.
//   1 — build verification failed.
//   2 — live boot failed (boot timeout, console errors, or nav errors).
//   3 — keeper-test not reachable at BASE_URL.

import { existsSync, mkdirSync, statSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { chromium } from 'playwright'

const __dirname = dirname(fileURLToPath(import.meta.url))
const REPO_ROOT = resolve(__dirname, '..', '..')

const BASE_URL = (process.env.BASE_URL || 'http://localhost:8085').replace(/\/$/, '')
// Default matches keeper-test's seeded admin (USERSPACE_USER_DEFAULT_ADMIN_EMAIL).
// Override via env if your harness seeds a different user.
const USER = process.env.SMOKE_USER || 'admin@navi.local'
const PASS = process.env.SMOKE_PASS || 'admin123'
const SCREENSHOT_DIR = process.env.SCREENSHOT_DIR
  || resolve(REPO_ROOT, '.local', 'smoke-screenshots')
const HEADLESS = process.env.HEADLESS !== 'false'
const TIMEOUT_MS = Number(process.env.TIMEOUT_MS) || 30000

// (id, dist path relative to repo, runtime URL relative to BASE_URL)
// keeper-test loads keeper/keeper but NOT keeper/usage — usage builds, but
// won't have a runtime mount in this harness. Add it to LIVE_APPS only when
// keeper-test (or your harness) gets a `keeper/usage` dependency.
const BUILD_APPS = [
  { id: 'keeper-main', dist: 'keeper/frontend/applications/keeper/dist/app.html' },
  { id: 'keeper-git',  dist: 'keeper/plugins/git/frontend/applications/git/dist/app.html' },
  { id: 'usage',       dist: 'usage/frontend/applications/usage/dist/app.html' },
]
// Facade route `/c/<namespace>:<name>` — the canonical, auth-wrapped path.
// Visiting /app/<bundle>/ directly skips the host context (auth + config
// injection) and the iframe boot stalls.
const LIVE_APPS = [
  { id: 'keeper-main', path: '/c/keeper:main' },
  { id: 'keeper-git',  path: '/c/keeper.git:main' },
]

const COLOR = {
  reset: '\x1b[0m', dim: '\x1b[2m', red: '\x1b[31m',
  green: '\x1b[32m', yellow: '\x1b[33m', cyan: '\x1b[36m',
}
const log = {
  info: (m) => console.log(`${COLOR.cyan}>${COLOR.reset} ${m}`),
  ok: (m)   => console.log(`${COLOR.green}✓${COLOR.reset} ${m}`),
  warn: (m) => console.log(`${COLOR.yellow}!${COLOR.reset} ${m}`),
  fail: (m) => console.log(`${COLOR.red}✗${COLOR.reset} ${m}`),
  dim: (m)  => console.log(`${COLOR.dim}  ${m}${COLOR.reset}`),
}

// ------------------------------------------------------------------- Build

function verifyBuilds() {
  log.info('Phase 1 — build verification')
  const missing = []
  for (const app of BUILD_APPS) {
    const abs = resolve(REPO_ROOT, app.dist)
    if (!existsSync(abs)) {
      missing.push({ id: app.id, abs })
      log.fail(`${app.id}: dist/app.html NOT FOUND at ${app.dist}`)
      continue
    }
    const size = statSync(abs).size
    log.ok(`${app.id}: dist/app.html OK (${size} bytes)`)
  }
  if (missing.length > 0) {
    log.fail(`Missing builds for ${missing.length} app(s). Run \`make build\` first.`)
    process.exit(1)
  }
}

// ------------------------------------------------------------ Live smoke

async function isReachable(url) {
  try {
    const res = await fetch(url, { method: 'GET' })
    return res.ok || res.status === 401 || res.status === 403  // login redirect is OK
  }
  catch {
    return false
  }
}

async function login(page) {
  // Hit the auth API directly and seed localStorage the same way login.html
  // does. This sidesteps form-handler timing flakiness while still exercising
  // the real auth path.
  log.info(`Login as ${USER}`)
  const res = await fetch(`${BASE_URL}/api/public/user/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: USER, password: PASS }),
  })
  if (!res.ok) {
    log.fail(`Auth POST ${res.status} ${res.statusText} — wrong SMOKE_USER/SMOKE_PASS?`)
    process.exit(2)
  }
  const data = await res.json()
  if (!data.success || !data.token) {
    log.fail(`Auth response missing token: ${JSON.stringify(data).slice(0, 200)}`)
    process.exit(2)
  }
  // Visit any page on the origin so localStorage.setItem reaches the right
  // origin scope, then seed the token before any app boot.
  await page.goto(`${BASE_URL}/app/login.html`, { waitUntil: 'domcontentloaded' })
  await page.evaluate((token) => {
    localStorage.setItem('@wippy_token_info', JSON.stringify({ token }))
  }, data.token)
  log.ok(`Token seeded for ${data.user?.email || USER}`)
}

async function smokeApp(page, app, scheme) {
  // Known boot-time transient noise. These errors fire while the proxy is
  // still wiring `window.$W.*` and resolve once the host injects globals.
  // The smoke test cares about steady-state errors AFTER boot, not the
  // probe-too-early races during boot. Override via SMOKE_IGNORE_ERRORS_RE.
  const IGNORE_RE = new RegExp(
    process.env.SMOKE_IGNORE_ERRORS_RE
    || [
      'Proxy globals not found', // @wippy-fe/proxy boot-time probe
      'Failed to load resource.*favicon',
    ].join('|'),
    'i',
  )

  const errors = []
  const onPageError = (err) => {
    if (IGNORE_RE.test(err.message)) return
    errors.push(`pageerror: ${err.message}`)
  }
  const onConsole = (msg) => {
    if (msg.type() !== 'error') return
    const t = msg.text()
    if (IGNORE_RE.test(t)) return
    errors.push(`console.error: ${t}`)
  }

  const url = `${BASE_URL}${app.path}`
  log.info(`${app.id} (${scheme}) — ${url}`)
  await page.emulateMedia({ colorScheme: scheme })
  await page.goto(url, { waitUntil: 'domcontentloaded' })

  // Boot signal: the host facade renders an iframe; inside it, Vue mounts
  // into #app and removes <wippy-loading>. Same-origin so contentDocument
  // is reachable.
  try {
    await page.waitForFunction(
      () => {
        const iframes = document.querySelectorAll('iframe')
        for (const f of iframes) {
          try {
            const doc = f.contentDocument
            if (!doc) continue
            const loading = doc.querySelector('wippy-loading')
            const root = doc.querySelector('#app')
            if (!loading && root && root.children.length > 0) return true
          }
          catch {
            // cross-origin: skip
          }
        }
        return false
      },
      undefined,
      { timeout: TIMEOUT_MS },
    )
  }
  catch {
    return { ok: false, reason: `Boot timeout after ${TIMEOUT_MS}ms (iframe never mounted)`, errors: [] }
  }

  // Now subscribe to errors — boot-time probe-too-early noise has already
  // happened and is uninteresting. We're testing steady-state.
  page.on('pageerror', onPageError)
  page.on('console', onConsole)

  // Settle window — capture any errors that fire after Vue mounts (effects,
  // watchers, post-mount fetches). 1.5s is enough for keeper's post-mount
  // /api/v1/keeper/* calls to either resolve or fail loudly.
  await page.waitForTimeout(1500)

  page.off('pageerror', onPageError)
  page.off('console', onConsole)

  if (!existsSync(SCREENSHOT_DIR)) mkdirSync(SCREENSHOT_DIR, { recursive: true })
  const shot = resolve(SCREENSHOT_DIR, `${app.id}-${scheme}.png`)
  await page.screenshot({ path: shot, fullPage: true })
  log.dim(`screenshot: ${shot}`)

  return { ok: errors.length === 0, errors, screenshot: shot }
}

async function liveSmoke() {
  log.info(`Phase 2 — live boot smoke against ${BASE_URL}`)
  if (!await isReachable(BASE_URL)) {
    log.fail(`keeper-test not reachable at ${BASE_URL}.`)
    log.dim(`Start it via: cd C:/Projects/keeper-test && ./wippy.exe run -c`)
    log.dim(`Override BASE_URL env if it runs on a different port.`)
    process.exit(3)
  }

  const browser = await chromium.launch({ headless: HEADLESS })
  const ctx = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1440, height: 900 } })
  const page = await ctx.newPage()

  let failures = 0
  try {
    await login(page)
    for (const app of LIVE_APPS) {
      for (const scheme of ['dark', 'light']) {
        const r = await smokeApp(page, app, scheme)
        if (r.ok) {
          log.ok(`${app.id} (${scheme}) booted clean`)
        }
        else {
          failures += 1
          log.fail(`${app.id} (${scheme}) FAILED — ${r.reason || `${r.errors.length} error(s)`}`)
          for (const e of r.errors.slice(0, 5)) log.dim(e)
          if (r.errors.length > 5) log.dim(`... and ${r.errors.length - 5} more`)
        }
      }
    }
  }
  finally {
    await ctx.close()
    await browser.close()
  }

  if (failures > 0) {
    log.fail(`${failures} live-smoke check(s) failed.`)
    process.exit(2)
  }
  log.ok(`All live-smoke checks passed (${LIVE_APPS.length} apps × 2 schemes).`)
}

// --------------------------------------------------------------- main

;(async () => {
  verifyBuilds()
  await liveSmoke()
  log.ok('Smoke complete.')
})().catch((err) => {
  log.fail(`Unhandled: ${err?.stack || err}`)
  process.exit(2)
})
