#!/usr/bin/env node
// Smoke test for keeper-v5.
//
// Two phases:
//
//   1. Build verification — confirm `dist/app.html` exists for all 3 FE apps
//      (keeper-main, keeper-git, usage). Fails fast with a clear message if
//      a build is missing — run `make build` first.
//
//   2. Live-boot smoke — drive a headless browser through the keeper-test
//      harness (default http://localhost:8085) the same way a user would:
//      visit /app/login.html, fill the form, click submit, then navigate
//      via the facade route /c/<namespace>:<name>.
//
//      For each app: capture EVERY request to /api/* and EVERY console error
//      and pageerror. The smoke FAILS if:
//        - any /api/* response is 4xx or 5xx
//        - any console.error or pageerror fires (no boot-noise filtering —
//          if the proxy logs a real boot-time error, that's a real signal)
//        - boot times out (Vue never mounts in the iframe)
//
//      Boot-time errors used to be filtered as "transient noise" (the
//      'Proxy globals not found' probes from @wippy-fe/proxy). They're
//      not filtered any more — they correlate with real 401s on the
//      /api/v1/keeper/* requests fired during keeper's onMounted, and
//      papering them over hides regressions.
//
// Env:
//   BASE_URL          (default http://localhost:8085)
//   SMOKE_USER        (default admin@navi.local — keeper-test seeded admin)
//   SMOKE_PASS        (default admin123)
//   SCREENSHOT_DIR    (default <repo>/.local/smoke-screenshots)
//   HEADLESS          (default true; set false to watch)
//   TIMEOUT_MS        (default 30000 — per-page boot wait)
//   POST_BOOT_MS      (default 2000 — settle window for post-mount API calls)
//
// Exit codes:
//   0 — all phases passed.
//   1 — build verification failed.
//   2 — live boot failed.
//   3 — keeper-test not reachable at BASE_URL.

import { existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { chromium } from 'playwright'

const __dirname = dirname(fileURLToPath(import.meta.url))
const REPO_ROOT = resolve(__dirname, '..', '..')

const BASE_URL = (process.env.BASE_URL || 'http://localhost:8085').replace(/\/$/, '')
const USER = process.env.SMOKE_USER || 'admin@navi.local'
const PASS = process.env.SMOKE_PASS || 'admin123'
const SCREENSHOT_DIR = process.env.SCREENSHOT_DIR
  || resolve(REPO_ROOT, '.local', 'smoke-screenshots')
const HEADLESS = process.env.HEADLESS !== 'false'
const TIMEOUT_MS = Number(process.env.TIMEOUT_MS) || 30000
const POST_BOOT_MS = Number(process.env.POST_BOOT_MS) || 2000

const BUILD_APPS = [
  { id: 'keeper-main', dist: 'keeper/frontend/applications/keeper/dist/app.html' },
  { id: 'keeper-git',  dist: 'keeper/plugins/git/frontend/applications/git/dist/app.html' },
  { id: 'usage',       dist: 'usage/frontend/applications/usage/dist/app.html' },
]
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

// ------------------------------------------------------------- Build

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

// ----------------------------------------------------------- Live smoke

async function isReachable(url) {
  try {
    const res = await fetch(url, { method: 'GET' })
    return res.ok || res.status === 401 || res.status === 403
  }
  catch {
    return false
  }
}

// Real form-based login — exercises the same path a human takes.
async function login(page) {
  log.info(`Login as ${USER} (form-based)`)
  await page.goto(`${BASE_URL}/app/login.html`, { waitUntil: 'domcontentloaded' })
  await page.fill('#email', USER)
  await page.fill('#password', PASS)
  await page.click('#submit-btn')
  // login.html does `window.location.href = '/'` on success.
  await page.waitForURL((url) => !url.toString().includes('login.html'), { timeout: 15000 })
  log.ok(`Logged in; landed on ${page.url()}`)
}

function newRecorder(page) {
  // Track API responses and console/page errors. Recorded across the page
  // AND every iframe — keeper renders inside an iframe and that's where the
  // real API calls fire.
  const apiResponses = []
  const consoleErrors = []
  const pageErrors = []

  const onResponse = async (res) => {
    const u = res.url()
    if (!u.includes('/api/')) return
    apiResponses.push({
      method: res.request().method(),
      url: u.replace(BASE_URL, ''),
      status: res.status(),
      // resourceType helps disambiguate (xhr/fetch vs document)
      type: res.request().resourceType(),
    })
  }
  const onConsole = (msg) => {
    if (msg.type() !== 'error') return
    consoleErrors.push(msg.text())
  }
  const onPageError = (err) => {
    pageErrors.push(err.message)
  }

  page.on('response', onResponse)
  page.on('console', onConsole)
  page.on('pageerror', onPageError)

  return {
    apiResponses, consoleErrors, pageErrors,
    detach() {
      page.off('response', onResponse)
      page.off('console', onConsole)
      page.off('pageerror', onPageError)
    },
  }
}

async function smokeApp(page, app, scheme) {
  const url = `${BASE_URL}${app.path}`
  log.info(`${app.id} (${scheme}) — ${url}`)

  await page.emulateMedia({ colorScheme: scheme })
  const rec = newRecorder(page)

  let bootOk = true
  let bootReason = ''
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded' })
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
          catch { /* cross-origin: skip */ }
        }
        return false
      },
      undefined,
      { timeout: TIMEOUT_MS },
    )
  }
  catch {
    bootOk = false
    bootReason = `Boot timeout after ${TIMEOUT_MS}ms (iframe never mounted)`
  }

  // Settle for any post-mount API calls (keeper.onMounted fires several).
  await page.waitForTimeout(POST_BOOT_MS)
  rec.detach()

  // If the app redirected back to login during the settle window, that's
  // the host responding to host.handleError('auth-expired') — a real,
  // user-visible smoke failure separate from the 4xx response itself.
  const redirectedToLogin = page.url().includes('/login.html')

  // Screenshot for the visual record even if there were errors — helps
  // diagnose what state the page reached.
  if (!existsSync(SCREENSHOT_DIR)) mkdirSync(SCREENSHOT_DIR, { recursive: true })
  const shot = resolve(SCREENSHOT_DIR, `${app.id}-${scheme}.png`)
  await page.screenshot({ path: shot, fullPage: true })

  const failedApi = rec.apiResponses.filter(r => r.status >= 400)
  const ok = bootOk
    && failedApi.length === 0
    && rec.consoleErrors.length === 0
    && rec.pageErrors.length === 0
    && !redirectedToLogin

  return {
    ok,
    bootOk, bootReason,
    apiCount: rec.apiResponses.length,
    failedApi,
    consoleErrors: rec.consoleErrors,
    pageErrors: rec.pageErrors,
    redirectedToLogin,
    screenshot: shot,
  }
}

function reportApp(app, scheme, r) {
  if (r.ok) {
    log.ok(`${app.id} (${scheme}) — booted clean (${r.apiCount} api call${r.apiCount === 1 ? '' : 's'}, all 2xx/3xx)`)
    log.dim(`screenshot: ${r.screenshot}`)
    return
  }
  log.fail(`${app.id} (${scheme}) — FAILED`)
  log.dim(`screenshot: ${r.screenshot}`)
  if (!r.bootOk) log.dim(`boot: ${r.bootReason}`)
  if (r.redirectedToLogin) log.dim(`redirected to login.html (host.handleError('auth-expired') fired)`)
  if (r.failedApi.length > 0) {
    log.dim(`${r.failedApi.length} non-2xx /api/* response(s):`)
    for (const f of r.failedApi.slice(0, 8)) {
      log.dim(`  ${f.status}  ${f.method} ${f.url}`)
    }
    if (r.failedApi.length > 8) log.dim(`  ... and ${r.failedApi.length - 8} more`)
  }
  if (r.pageErrors.length > 0) {
    log.dim(`${r.pageErrors.length} pageerror(s):`)
    for (const e of r.pageErrors.slice(0, 5)) log.dim(`  ${e.slice(0, 200)}`)
  }
  if (r.consoleErrors.length > 0) {
    log.dim(`${r.consoleErrors.length} console.error(s):`)
    for (const e of r.consoleErrors.slice(0, 5)) log.dim(`  ${e.slice(0, 200)}`)
  }
}

async function liveSmoke() {
  log.info(`Phase 2 — live boot smoke against ${BASE_URL}`)
  if (!await isReachable(BASE_URL)) {
    log.fail(`keeper-test not reachable at ${BASE_URL}.`)
    log.dim(`Start it via: cd C:/Projects/keeper-test && ./wippy.exe run -c`)
    log.dim(`Or override BASE_URL=http://host:port`)
    process.exit(3)
  }

  const browser = await chromium.launch({ headless: HEADLESS })
  const ctx = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1440, height: 900 } })

  // Login once on a dedicated page; cookies + storage persist in the
  // browser context, so subsequent fresh pages inherit the session.
  const loginPage = await ctx.newPage()
  await login(loginPage)
  await loginPage.close()

  let failures = 0
  const results = []
  try {
    for (const app of LIVE_APPS) {
      for (const scheme of ['dark', 'light']) {
        // Fresh page per (app, scheme) — every iteration is a cold start
        // for the keeper iframe, surfacing real boot races. (Reusing the
        // same page across navigations papered over the proxy-globals
        // race because the iframe stayed warm.)
        const page = await ctx.newPage()
        try {
          const r = await smokeApp(page, app, scheme)
          results.push({ app, scheme, r })
          reportApp(app, scheme, r)
          if (!r.ok) failures += 1
        }
        finally {
          await page.close()
        }
      }
    }
  }
  finally {
    await ctx.close()
    await browser.close()
  }

  // Drop a JSON report next to screenshots so CI / humans can drill in.
  const reportPath = resolve(SCREENSHOT_DIR, 'smoke-report.json')
  writeFileSync(reportPath, JSON.stringify({ baseUrl: BASE_URL, results }, null, 2))
  log.dim(`report: ${reportPath}`)

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
