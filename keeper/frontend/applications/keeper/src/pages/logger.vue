<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi, useWippy } from '../composables/useWippy'
import { getLogs, getLogStats, clearLogs, LEVEL_NAMES, LEVEL_COLORS, type LogEntry, type LogStats, type LogCounters } from '../api/logger'
import PageHeader from '../components/shared/PageHeader.vue'

const api = useApi()
const instance = useWippy()

const logs = ref<LogEntry[]>([])
const stats = ref<LogStats | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const filter = ref('')
const activeFilter = ref('')
const levelFilter = ref<number | null>(null)
const streaming = ref(true)
const expandedIdx = ref<number | null>(null)
const logCount = ref(300)
const maxLogs = 1000
const paused = ref(false)

const filteredLogs = computed(() => {
  let result = logs.value
  if (levelFilter.value !== null) {
    if (levelFilter.value >= 2) {
      result = result.filter(l => l.level >= 2)
    } else {
      result = result.filter(l => l.level === levelFilter.value)
    }
  }
  return result
})

function levelName(level: number): string {
  return LEVEL_NAMES[level] || 'UNKNOWN'
}

function levelColor(level: number): string {
  return LEVEL_COLORS[level] || 'var(--p-text-muted-color)'
}

function formatTs(ns: number): string {
  if (!ns) return ''
  const d = new Date(ns / 1000000)
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  const ss = String(d.getSeconds()).padStart(2, '0')
  return `${hh}:${mm}:${ss}`
}

function shortPath(path: string): string {
  if (!path) return ''
  const parts = path.split('.')
  if (parts.length <= 2) return path
  return parts.slice(-2).join('.')
}

function hasFields(entry: LogEntry): boolean {
  return entry.fields && Object.keys(entry.fields).length > 0
}

function toggleExpand(idx: number) {
  expandedIdx.value = expandedIdx.value === idx ? null : idx
}

function buildFilterExpr(): string {
  const parts: string[] = []
  if (activeFilter.value) parts.push(activeFilter.value)
  if (levelFilter.value !== null) {
    if (levelFilter.value >= 2) parts.push('level >= 2')
    else parts.push(`level == ${levelFilter.value}`)
  }
  if (parts.length === 0) return ''
  if (parts.length === 1) return parts[0]
  return parts.map(p => `(${p})`).join(' and ')
}

async function loadLogs() {
  try {
    const expr = buildFilterExpr()
    const result = await getLogs(api, logCount.value, expr || undefined, true)
    logs.value = result.logs || []
    error.value = null
  } catch (e: any) {
    error.value = e.response?.data?.error || e.message
  } finally {
    loading.value = false
  }
}

async function loadStats() {
  try {
    const result = await getLogStats(api)
    stats.value = result.stats
  } catch {
    // non-critical
  }
}

async function load() {
  loading.value = true
  await Promise.all([loadLogs(), loadStats()])
}

function applyFilter() {
  activeFilter.value = filter.value
  loadLogs()
}

function clearFilter() {
  filter.value = ''
  activeFilter.value = ''
  levelFilter.value = null
  loadLogs()
}

function setLevelFilter(level: number | null) {
  levelFilter.value = levelFilter.value === level ? null : level
  loadLogs()
}

async function doClear() {
  try {
    await clearLogs(api)
    logs.value = []
    await loadStats()
  } catch (e: any) {
    error.value = e.message
  }
}

// Stream new entries via websocket
let unsubLogs: (() => void) | null = null

function setupStream() {
  unsubLogs = instance.on('keeper.logs', (evt: any) => {
    const data = evt?.data || evt
    const entry = data.entry
    const counters = data.counters
    return onLogEvent(entry, counters)
  })
}

function onLogEvent(entry?: LogEntry, counters?: LogCounters) {
  if (paused.value) return
  if (entry) {
    logs.value = [entry, ...logs.value].slice(0, maxLogs)
  }
  if (counters && stats.value) {
    stats.value = { ...stats.value, counters }
  }
}

// Counters update in real-time via relay (keeper.logs events carry counters).
// Full stats (buffer size, composition) loaded on mount only.

onMounted(() => {
  load()
  setupStream()
})

onUnmounted(() => {
  unsubLogs?.()
})

function fmt(n: number): string {
  return n.toLocaleString()
}
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader title="Logs" :loading="loading" @refresh="load">
      <label class="flex items-center gap-1 text-[10px]" style="color: var(--p-text-muted-color)" title="Pause streaming">
        <input type="checkbox" v-model="paused" class="w-3 h-3" />
        Pause
      </label>
    </PageHeader>

    <!-- Counters bar -->
    <div v-if="stats" class="counter-bar">
      <button class="counter-pill" :class="{ active: levelFilter === null }" @click="setLevelFilter(null)">
        <span style="color: var(--p-text-color)">All</span>
        <span class="counter-num" style="color: var(--p-text-muted-color)">{{ fmt(stats.stored_count) }}</span>
      </button>
      <button class="counter-pill" :class="{ active: levelFilter === 2 }" @click="setLevelFilter(2)">
        <span class="counter-dot bg-danger-500" />
        <span :class="{ 'text-danger-500': stats.counters.error > 0, 'text-[var(--p-text-muted-color)]': stats.counters.error === 0 }">Errors</span>
        <span class="counter-num" :class="{ 'text-danger-500 font-bold': stats.counters.error > 0, 'text-[var(--p-text-muted-color)]': stats.counters.error === 0 }">
          {{ fmt(stats.counters.error) }}
        </span>
      </button>
      <button class="counter-pill" :class="{ active: levelFilter === 1 }" @click="setLevelFilter(1)">
        <span class="counter-dot bg-warn-500" />
        <span :class="{ 'text-warn-500': stats.counters.warn > 0, 'text-[var(--p-text-muted-color)]': stats.counters.warn === 0 }">Warns</span>
        <span class="counter-num">{{ fmt(stats.counters.warn) }}</span>
      </button>
      <button class="counter-pill" :class="{ active: levelFilter === 0 }" @click="setLevelFilter(0)">
        <span class="counter-dot bg-success-500" />
        <span style="color: var(--p-text-muted-color)">Info</span>
        <span class="counter-num">{{ fmt(stats.counters.info) }}</span>
      </button>
      <button class="counter-pill" :class="{ active: levelFilter === -1 }" @click="setLevelFilter(-1)">
        <span class="counter-dot bg-surface-400" />
        <span style="color: var(--p-text-muted-color)">Debug</span>
        <span class="counter-num">{{ fmt(stats.counters.debug) }}</span>
      </button>

      <div class="ml-auto flex items-center gap-2">
        <span class="text-[9px]" style="color: var(--p-text-muted-color)">buf: {{ fmt(stats.stored_count) }}/{{ fmt(stats.buffer_size) }}</span>
        <button class="clear-btn" @click="doClear" title="Clear buffer">
          <Icon icon="tabler:trash" class="w-3 h-3" />
        </button>
      </div>
    </div>

    <!-- Filter bar -->
    <div class="filter-bar">
      <Icon icon="tabler:filter" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
      <input
        v-model="filter"
        placeholder='Filter: level >= 1, path contains "gov", message contains "error"'
        class="filter-input"
        @keydown.enter="applyFilter"
      />
      <button v-if="filter && filter !== activeFilter" class="text-[10px] px-2 py-0.5 rounded text-white" style="background: var(--p-primary-color)" @click="applyFilter">Apply</button>
      <button v-if="activeFilter" class="text-[10px] px-1" style="color: var(--p-text-muted-color)" @click="clearFilter">
        <Icon icon="tabler:x" class="w-3 h-3" />
      </button>
    </div>

    <div v-if="error" class="mx-4 mt-1 px-3 py-1.5 rounded text-[10px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3 h-3 shrink-0" />
      <span class="flex-1">{{ error }}</span>
    </div>

    <!-- Log entries (newest first) -->
    <div class="flex-1 overflow-y-auto font-mono text-[10px]">
      <div
        v-for="(entry, idx) in filteredLogs" :key="entry.timestamp + '-' + idx"
        class="log-row"
        :class="{ 'log-error': entry.level >= 2, 'log-warn': entry.level === 1 }"
        @click="toggleExpand(idx)"
      >
        <div class="log-line">
          <span class="log-ts">{{ formatTs(entry.timestamp) }}</span>
          <span class="log-level" :style="{ color: levelColor(entry.level) }">{{ levelName(entry.level) }}</span>
          <span class="log-path" :title="entry.path">{{ shortPath(entry.path) }}</span>
          <span class="log-msg">{{ entry.message }}</span>
          <Icon v-if="hasFields(entry)" icon="tabler:dots" class="w-3 h-3 shrink-0 ml-auto" style="color: var(--p-text-muted-color); opacity: 0.4" />
        </div>
        <div v-if="expandedIdx === idx" class="log-detail">
          <div class="detail-row"><span class="detail-key">path</span><span class="detail-val">{{ entry.path }}</span></div>
          <div class="detail-row"><span class="detail-key">logger</span><span class="detail-val">{{ entry.logger_name }}</span></div>
          <div v-if="entry.caller" class="detail-row"><span class="detail-key">caller</span><span class="detail-val">{{ entry.caller }}</span></div>
          <template v-if="hasFields(entry)">
            <div v-for="(v, k) in entry.fields" :key="String(k)" class="detail-row">
              <span class="detail-key">{{ k }}</span>
              <span class="detail-val">{{ typeof v === 'object' ? JSON.stringify(v) : v }}</span>
            </div>
          </template>
        </div>
      </div>
      <div v-if="!loading && filteredLogs.length === 0" class="flex flex-col items-center justify-center py-16" style="color: var(--p-text-muted-color)">
        <Icon icon="tabler:file-off" class="w-8 h-8 mb-2" style="opacity: 0.3" />
        <span class="text-xs">No log entries</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.counter-bar {
  display: flex; align-items: center; gap: 4px; padding: 6px 12px;
  border-bottom: 1px solid var(--p-content-border-color); flex-shrink: 0;
}
.counter-pill {
  display: flex; align-items: center; gap: 4px; padding: 2px 8px;
  border-radius: 4px; font-size: 10px;
  background: transparent; border: 1px solid transparent;
}
.counter-pill:hover { background: var(--p-surface-100); }
.counter-pill.active { background: var(--p-surface-100); border-color: var(--p-content-border-color); }
.counter-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.counter-num { font-variant-numeric: tabular-nums; font-size: 10px; color: var(--p-text-muted-color); }

.clear-btn {
  padding: 3px; border-radius: 3px; color: var(--p-text-muted-color);
}
.clear-btn:hover { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent); color: var(--p-danger-500); }

.filter-bar {
  display: flex; align-items: center; gap: 6px; padding: 4px 12px;
  border-bottom: 1px solid var(--p-content-border-color); flex-shrink: 0;
}
.filter-input {
  flex: 1; padding: 3px 6px; font-size: 10px; font-family: monospace;
  background: transparent; color: var(--p-text-color);
  border: none; outline: none;
}
.filter-input::placeholder { color: var(--p-text-muted-color); opacity: 0.5; }

.log-row {
  border-bottom: 1px solid var(--p-surface-100); cursor: pointer;
}
.log-row:hover { background: var(--p-surface-50, var(--p-surface-100)); }
.log-error { background: color-mix(in srgb, var(--p-danger-500) 4%, transparent); }
.log-error:hover { background: color-mix(in srgb, var(--p-danger-500) 8%, transparent); }
.log-warn { background: color-mix(in srgb, var(--p-warn-500) 3%, transparent); }
.log-warn:hover { background: color-mix(in srgb, var(--p-warn-500) 6%, transparent); }

.log-line {
  display: flex; align-items: center; gap: 8px; padding: 2px 12px;
  min-height: 22px;
}
.log-ts { color: var(--p-text-muted-color); opacity: 0.6; width: 55px; flex-shrink: 0; white-space: nowrap; }
.log-level { width: 36px; flex-shrink: 0; font-weight: 600; }
.log-path { color: var(--p-text-muted-color); width: 120px; flex-shrink: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.log-msg { color: var(--p-text-color); flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.log-detail {
  padding: 4px 12px 6px 112px;
  background: var(--p-surface-100);
}
.detail-row { display: flex; gap: 8px; padding: 1px 0; }
.detail-key { color: var(--p-text-muted-color); width: 80px; flex-shrink: 0; text-align: right; }
.detail-val { color: var(--p-text-color); word-break: break-all; }
</style>
