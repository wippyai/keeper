<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import { entryName } from '../utils'

const api = useApi()

interface TestEntry {
  id: string
  name: string
  group?: string
  meta?: Record<string, any>
}

interface TestCase {
  suite: string
  test: string
  status: 'pending' | 'running' | 'pass' | 'fail' | 'skip'
  duration?: number
  error?: string
}

const tests = ref<TestEntry[]>([])
const suites = ref<string[]>([])
const cases = ref<TestCase[]>([])
const loading = ref(false)
const discovering = ref(false)
const running = ref(false)
const runningId = ref<string | null>(null)
const suiteFilter = ref('')
const expandedSuites = ref<Set<string>>(new Set())
const summary = ref<{ total: number; passed: number; failed: number; skipped: number; duration: number } | null>(null)

function testSuite(t: TestEntry): string {
  if (t.meta?.suite) return t.meta.suite
  if (t.group) return t.group
  const ns = t.id.split(':')[0] || ''
  const parts = ns.split('.')
  return parts.length > 1 ? parts.slice(0, 2).join('.') : ns || 'tests'
}

const groupedTests = computed(() => {
  const groups: Record<string, TestEntry[]> = {}
  for (const t of tests.value) {
    const g = testSuite(t)
    if (suiteFilter.value && g !== suiteFilter.value) continue
    if (!groups[g]) groups[g] = []
    groups[g].push(t)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

const suiteCases = computed(() => {
  const map: Record<string, TestCase[]> = {}
  for (const c of cases.value) {
    if (!map[c.suite]) map[c.suite] = []
    map[c.suite].push(c)
  }
  return map
})

const totalStats = computed(() => {
  const all = cases.value
  return {
    total: all.length,
    pass: all.filter(c => c.status === 'pass').length,
    fail: all.filter(c => c.status === 'fail').length,
    skip: all.filter(c => c.status === 'skip').length,
    running: all.filter(c => c.status === 'running').length,
  }
})

function suiteStatus(group: string): string {
  const sc = suiteCases.value[group] || []
  if (sc.length === 0) return 'pending'
  if (sc.some(c => c.status === 'fail')) return 'fail'
  if (sc.some(c => c.status === 'running')) return 'running'
  if (sc.every(c => c.status === 'pass' || c.status === 'skip')) return 'pass'
  return 'pending'
}

const statusIcon: Record<string, string> = {
  pending: 'tabler:circle',
  running: 'tabler:loader-2',
  pass: 'tabler:circle-check',
  fail: 'tabler:circle-x',
  skip: 'tabler:circle-minus',
}

const statusColor: Record<string, string> = {
  pending: 'var(--p-text-muted-color)',
  running: 'var(--p-warn-500)',
  pass: 'var(--p-success-500)',
  fail: 'var(--p-danger-500)',
  skip: 'var(--p-text-muted-color)',
}

async function discover() {
  discovering.value = true
  try {
    const { data } = await api.get('/api/v1/keeper/tests/discover')
    tests.value = data.tests || []
    suites.value = data.suites || []
  } catch (e: any) {
    tests.value = []
    suites.value = []
  } finally {
    discovering.value = false
  }
}

let abortController: AbortController | null = null

async function runTests(testId?: string, group?: string) {
  running.value = true
  runningId.value = testId || group || 'all'
  cases.value = []
  summary.value = null

  const params = new URLSearchParams()
  if (testId) params.set('test_id', testId)
  else if (group) params.set('group', group)

  abortController = new AbortController()

  try {
    const { data } = await api.get('/api/v1/keeper/tests/run', {
      params: Object.fromEntries(params),
      responseType: 'text',
      transformResponse: [(d: string) => d],
      signal: abortController.signal,
      timeout: 300000,
    })

    const lines = String(data).split('\n').filter(Boolean)
    for (const line of lines) {
      try { handleEvent(JSON.parse(line)) } catch {}
    }
  } catch (e: any) {
    if (e?.name === 'AbortError') { /* expected */ }
  } finally {
    running.value = false
    runningId.value = null
    abortController = null
  }
}

function cancelTests() {
  if (abortController) {
    abortController.abort()
    for (const c of cases.value) {
      if (c.status === 'running' || c.status === 'pending') c.status = 'skip'
    }
  }
}

function handleEvent(evt: { type: string; data: any }) {
  const d = evt.data || {}

  switch (evt.type) {
    case 'test:suite:start':
      expandedSuites.value.add(d.id || d.name)
      break

    case 'test:case:start':
      cases.value.push({ suite: d.ref_id || d.suite || '', test: d.test || d.name || '', status: 'running' })
      break

    case 'test:case:pass': {
      const c = findCase(d.ref_id || d.suite, d.test || d.name)
      if (c) { c.status = 'pass'; c.duration = d.duration }
      break
    }

    case 'test:case:fail': {
      const c = findCase(d.ref_id || d.suite, d.test || d.name)
      if (c) { c.status = 'fail'; c.error = d.error || d.message; c.duration = d.duration }
      break
    }

    case 'test:case:skip': {
      const c = findCase(d.ref_id || d.suite, d.test || d.name)
      if (c) { c.status = 'skip' }
      break
    }

    case 'test:plan':
      if (d.suites) {
        for (const s of d.suites) {
          expandedSuites.value.add(s.id || s.name)
          for (const tc of (s.cases || [])) {
            cases.value.push({ suite: s.id || s.name || '', test: tc.name || tc, status: 'pending' })
          }
        }
      }
      break

    case 'test:complete':
      break

    case 'test:summary':
      summary.value = { total: d.total || 0, passed: d.completed - (d.failed || 0), failed: d.failed || 0, skipped: 0, duration: 0 }
      break
  }
}

function findCase(suite: string, test: string): TestCase | undefined {
  return cases.value.find(c => c.suite === suite && c.test === test)
    || cases.value.find(c => c.test === test && c.status === 'running')
}

function fmtDuration(ms?: number): string {
  if (!ms) return ''
  if (ms < 1) return '<1ms'
  if (ms < 1000) return Math.round(ms) + 'ms'
  return (ms / 1000).toFixed(1) + 's'
}

onMounted(discover)
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- Header -->
    <div class="shrink-0 px-4 py-2.5 flex items-center justify-between" style="border-bottom: 1px solid var(--p-content-border-color)">
      <div class="flex items-center gap-2">
        <Icon icon="tabler:test-pipe" class="w-4 h-4 keeper-accent" />
        <span class="text-xs font-medium" style="color: var(--p-text-color)">Tests</span>
        <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ tests.length }} test files</span>
        <Icon v-if="discovering" icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin keeper-accent" />
      </div>
      <div class="flex items-center gap-2">
        <select v-if="suites.length > 1" v-model="suiteFilter" class="text-[11px] px-2 py-1 rounded" style="background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color); outline: none; height: 28px">
          <option value="">All suites</option>
          <option v-for="s in suites" :key="s" :value="s">{{ s }}</option>
        </select>
        <button v-if="running" class="cancel-btn" @click="cancelTests">
          <Icon icon="tabler:player-stop" class="w-3.5 h-3.5" />
          Cancel
        </button>
        <button v-else class="run-btn" :disabled="tests.length === 0" @click="runTests()">
          <Icon icon="tabler:player-play" class="w-3.5 h-3.5" />
          Run All
        </button>
        <button class="p-1 rounded" style="color: var(--p-text-muted-color)" @click="discover">
          <Icon icon="tabler:refresh" class="w-3.5 h-3.5" />
        </button>
      </div>
    </div>

    <!-- Live stats bar -->
    <div v-if="cases.length > 0" class="shrink-0 px-4 py-1.5 flex items-center gap-3 text-[10px]" style="border-bottom: 1px solid var(--p-content-border-color); background: var(--p-surface-50)">
      <span style="color: var(--p-text-muted-color)">{{ totalStats.total }} cases</span>
      <span v-if="totalStats.pass" class="text-success-500"><Icon icon="tabler:circle-check" class="w-2.5 h-2.5 inline" /> {{ totalStats.pass }}</span>
      <span v-if="totalStats.fail" class="text-danger-500"><Icon icon="tabler:circle-x" class="w-2.5 h-2.5 inline" /> {{ totalStats.fail }}</span>
      <span v-if="totalStats.skip" class="text-[var(--kp-text-secondary)]"><Icon icon="tabler:circle-minus" class="w-2.5 h-2.5 inline" /> {{ totalStats.skip }}</span>
      <span v-if="totalStats.running" class="text-warn-500"><Icon icon="tabler:loader-2" class="w-2.5 h-2.5 inline animate-spin" /> {{ totalStats.running }}</span>
      <!-- Progress bar -->
      <div class="flex-1 h-1 rounded overflow-hidden" style="background: var(--p-surface-200)">
        <div class="h-full flex">
          <div class="bg-success-500" :style="{ width: (totalStats.pass / Math.max(totalStats.total, 1)) * 100 + '%' }"></div>
          <div class="bg-danger-500" :style="{ width: (totalStats.fail / Math.max(totalStats.total, 1)) * 100 + '%' }"></div>
          <div class="bg-warn-500" :style="{ width: (totalStats.running / Math.max(totalStats.total, 1)) * 100 + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="!discovering && tests.length === 0" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <Icon icon="tabler:test-pipe" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
        <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No tests found</p>
        <p class="mt-1 text-[10px]" style="color: var(--p-text-muted-color); opacity: 0.6">Tests are registry entries with meta.type = "test"</p>
      </div>
    </div>

    <!-- Test list -->
    <div v-else class="flex-1 overflow-y-auto">
      <div v-for="[group, entries] in groupedTests" :key="group" class="suite">
        <!-- Suite header -->
        <div class="suite-head" @click="expandedSuites.has(group) ? expandedSuites.delete(group) : expandedSuites.add(group)">
          <Icon :icon="expandedSuites.has(group) ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
          <Icon :icon="statusIcon[suiteStatus(group)] || 'tabler:circle'" class="w-3.5 h-3.5 shrink-0" :class="{ 'animate-spin': suiteStatus(group) === 'running' }" :style="{ color: statusColor[suiteStatus(group)] }" />
          <span class="flex-1 text-[11px] font-medium" style="color: var(--p-text-color)">{{ group }}</span>
          <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ entries.length }} files</span>
          <button class="run-sm" :disabled="running" @click.stop="runTests(undefined, group)">
            <Icon icon="tabler:player-play" class="w-3 h-3" />
          </button>
        </div>

        <!-- Test files -->
        <div v-if="expandedSuites.has(group)">
          <div v-for="t in entries" :key="t.id" class="test-file">
            <div class="test-file-head">
              <Icon icon="tabler:file-code" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] font-mono truncate" style="color: var(--p-text-color)">{{ entryName(t.id) }}</div>
                <div v-if="t.meta?.comment" class="text-[9px] truncate" style="color: var(--p-text-muted-color)">{{ t.meta.comment }}</div>
              </div>
              <span v-if="t.meta?.order" class="text-[8px] px-1 rounded" style="background: var(--p-surface-200); color: var(--p-text-muted-color)">#{{ t.meta.order }}</span>
              <button class="run-sm run-sm--visible" :disabled="running" @click.stop="runTests(t.id)">
                <Icon icon="tabler:player-play" class="w-3 h-3" />
              </button>
            </div>

            <!-- Test cases for this file -->
            <div v-if="(suiteCases[t.id] || []).length > 0" class="test-cases">
              <div v-for="(c, ci) in (suiteCases[t.id] || [])" :key="ci" class="test-case">
                <Icon :icon="statusIcon[c.status]" class="w-3 h-3 shrink-0" :class="{ 'animate-spin': c.status === 'running', 'animate-pulse': c.status === 'running' }" :style="{ color: statusColor[c.status] }" />
                <span class="flex-1 text-[10px] truncate" :class="{ 'text-danger-500': c.status === 'fail' }" :style="c.status !== 'fail' ? { color: 'var(--p-text-color)' } : {}">{{ c.test }}</span>
                <span v-if="c.duration" class="text-[9px] font-mono" style="color: var(--p-text-muted-color)">{{ fmtDuration(c.duration) }}</span>
              </div>
              <!-- Error details -->
              <div v-for="(c, ci) in (suiteCases[t.id] || []).filter(x => x.status === 'fail' && x.error)" :key="'err-' + ci" class="test-error">
                <Icon icon="tabler:alert-circle" class="w-3 h-3 shrink-0 text-danger-500" />
                <pre class="flex-1 text-[9px] font-mono text-danger-500" style="white-space: pre-wrap; word-break: break-word">{{ c.error }}</pre>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary -->
    <div v-if="summary" class="shrink-0 px-4 py-2 flex items-center gap-3 text-[11px]" :class="{ 'bg-danger-500/5': summary.failed > 0, 'bg-success-500/5': summary.failed === 0 }" style="border-top: 1px solid var(--p-content-border-color)">
      <Icon :icon="summary.failed > 0 ? 'tabler:circle-x' : 'tabler:circle-check'" class="w-4 h-4" :class="{ 'text-danger-500': summary.failed > 0, 'text-success-500': summary.failed === 0 }" />
      <span class="font-semibold" :class="{ 'text-danger-500': summary.failed > 0, 'text-success-500': summary.failed === 0 }">
        {{ summary.failed > 0 ? 'FAILED' : 'PASSED' }}
      </span>
      <span style="color: var(--p-text-muted-color)">{{ summary.passed }} passed, {{ summary.failed }} failed</span>
    </div>
  </div>
</template>

<style scoped>
.run-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 12px; border-radius: 4px; font-size: 11px; font-weight: 600;
  background: var(--p-primary-color); color: var(--p-primary-contrast-color); border: none; cursor: pointer;
}
.run-btn:hover { opacity: 0.9; }
.run-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.cancel-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 12px; border-radius: 4px; font-size: 11px; font-weight: 600;
  background: var(--p-danger-500); color: #fff; border: none; cursor: pointer;
}
.cancel-btn:hover { opacity: 0.9; }
.run-sm {
  padding: 2px; border-radius: 3px; color: var(--p-text-muted-color);
  background: none; border: none; cursor: pointer; opacity: 0;
}
.suite-head:hover .run-sm, .test-file-head:hover .run-sm { opacity: 1; }
.run-sm--visible { opacity: 0.5 !important; }
.run-sm--visible:hover { opacity: 1 !important; }
.run-sm:hover { color: var(--p-primary-color); background: var(--p-surface-200); }
.run-sm:disabled { opacity: 0.3; cursor: not-allowed; }

.suite { border-bottom: 1px solid var(--p-content-border-color); }
.suite-head {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 12px; cursor: pointer;
}
.suite-head:hover { background: var(--p-surface-100); }

.test-file { border-top: 1px solid var(--p-content-border-color); }
.test-file-head {
  display: flex; align-items: center; gap: 6px;
  padding: 4px 12px 4px 28px;
}
.test-file-head:hover { background: var(--p-surface-50); }

.test-cases { padding-left: 44px; }
.test-case {
  display: flex; align-items: center; gap: 6px;
  padding: 2px 12px 2px 0;
}
.test-error {
  display: flex; align-items: flex-start; gap: 6px;
  padding: 4px 12px 4px 0; margin-top: 2px;
  background: color-mix(in srgb, var(--p-danger-500) 5%, transparent); border-radius: 4px;
}
</style>
