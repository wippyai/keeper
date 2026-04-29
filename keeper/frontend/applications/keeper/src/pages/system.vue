<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import { fetchPmStats, fetchSystemInfo, terminateProcess, type HostStats, type ProcessStats, type ServiceState } from '../api/pm'
import PageHeader from '../components/shared/PageHeader.vue'
import LineChart, { type ChartSeries } from '../components/shared/LineChart.vue'

type AnnotatedProcess = ProcessStats & { hostId: string }

interface TreeNode {
  process: AnnotatedProcess
  depth: number
  children: TreeNode[]
}

const HOST_COLORS = [
  { bg: 'var(--p-info-500)',    light: 'color-mix(in srgb, var(--p-info-500) 15%, transparent)' },
  { bg: 'var(--p-success-500)', light: 'color-mix(in srgb, var(--p-success-500) 15%, transparent)' },
  { bg: 'var(--p-accent-500)',  light: 'color-mix(in srgb, var(--p-accent-500) 15%, transparent)' },
  { bg: 'var(--p-warn-500)',    light: 'color-mix(in srgb, var(--p-warn-500) 15%, transparent)' },
  { bg: 'var(--p-danger-500)',  light: 'color-mix(in srgb, var(--p-danger-500) 15%, transparent)' },
  { bg: 'var(--p-info-500)',    light: 'color-mix(in srgb, var(--p-info-500) 15%, transparent)' },
]

const CHART_POINTS = 60

const api = useApi()
const sampleRate = ref(3000)
const activeTab = ref<'processes' | 'services'>('processes')
const collapsed = ref<Set<string>>(new Set())
const loading = ref(true)
const error = ref<string | null>(null)
const terminating = ref<Set<string>>(new Set())

const hosts = ref<HostStats[]>([])
const services = ref<ServiceState[]>([])
const hiddenHosts = ref<Set<string>>(new Set())

const prevStepCounts = ref<Map<string, number>>(new Map())
const stepDeltas = ref<Map<string, number>>(new Map())
const stepHistory = ref<Record<string, number[]>>({})
const globalHistory = ref<number[]>([])

const confirmPid = ref<string | null>(null)
const systemInfo = ref<any>(null)

const hostColorMap = computed(() => {
  const m = new Map<string, typeof HOST_COLORS[0]>()
  hosts.value.forEach((h, i) => { m.set(h.host_id, HOST_COLORS[i % HOST_COLORS.length]) })
  return m
})

const allProcesses = computed<AnnotatedProcess[]>(() =>
  hosts.value.flatMap(h => (h.processes || []).map(p => ({ ...p, hostId: h.host_id })))
)

const filteredProcesses = computed(() =>
  allProcesses.value.filter(p => !hiddenHosts.value.has(p.hostId))
)

const visibleHosts = computed(() =>
  hosts.value.filter(h => !hiddenHosts.value.has(h.host_id))
)

function shortPid(pid: string): string {
  const m = pid.match(/\|0x([0-9a-f]+)\}$/)
  return m ? '#' + m[1].replace(/^0+/, '') : pid
}

function shortSource(source: string): string {
  const parts = source.split(':')
  return parts.length > 1 ? parts[1] : source
}

function sourceNamespace(source: string): string {
  const parts = source.split(':')
  return parts.length > 1 ? parts[0] : ''
}

function buildTree(procs: AnnotatedProcess[]): TreeNode[] {
  const byPid = new Map<string, AnnotatedProcess>()
  for (const p of procs) byPid.set(p.pid, p)

  const childrenMap = new Map<string | null, AnnotatedProcess[]>()
  for (const p of procs) {
    const parentKey = p.parent && byPid.has(p.parent) ? p.parent : null
    if (!childrenMap.has(parentKey)) childrenMap.set(parentKey, [])
    childrenMap.get(parentKey)!.push(p)
  }

  function build(parentPid: string | null, depth: number): TreeNode[] {
    const kids = childrenMap.get(parentPid) || []
    return kids.map(p => ({ process: p, depth, children: build(p.pid, depth + 1) }))
  }
  return build(null, 0)
}

function flattenTree(nodes: TreeNode[]): TreeNode[] {
  const result: TreeNode[] = []
  for (const n of nodes) {
    result.push(n)
    if (!collapsed.value.has(n.process.pid)) result.push(...flattenTree(n.children))
  }
  return result
}

function toggleCollapse(pid: string) {
  const s = new Set(collapsed.value)
  if (s.has(pid)) s.delete(pid); else s.add(pid)
  collapsed.value = s
}

const treeRows = computed(() => flattenTree(buildTree(filteredProcesses.value)))

const hostCount = computed(() => visibleHosts.value.length)
const processCount = computed(() => filteredProcesses.value.length)
const serviceCount = computed(() => services.value.length)
const runningServices = computed(() => services.value.filter(s => s.status === 'running').length)

const currentStepsPerSec = ref(0)
const globalAvgStepsPerSec = computed(() => {
  if (!globalHistory.value.length) return 0
  return Math.round(globalHistory.value.reduce((a, b) => a + b, 0) / globalHistory.value.length)
})
const peakStepsPerSec = computed(() => {
  if (!globalHistory.value.length) return 0
  return Math.round(Math.max(...globalHistory.value))
})

const activityChartLabels = computed(() => {
  const maxLen = Math.max(...hosts.value.map(h => (stepHistory.value[h.host_id] || []).length), 0)
  return Array.from({ length: maxLen }, (_, i) => '')
})

const activityChartSeries = computed<ChartSeries[]>(() => {
  return hosts.value.map((h, i) => ({
    label: shortHostId(h.host_id),
    color: HOST_COLORS[i % HOST_COLORS.length].bg,
    data: stepHistory.value[h.host_id] || [],
  }))
})

const hasChartData = computed(() => {
  return hosts.value.some(h => (stepHistory.value[h.host_id] || []).length >= 2)
})

function toggleHost(hostId: string) {
  const s = new Set(hiddenHosts.value)
  if (s.has(hostId)) s.delete(hostId); else s.add(hostId)
  hiddenHosts.value = s
}

function formatUptime(startedAtNanos: number): string {
  if (!startedAtNanos || startedAtNanos <= 0) return '-'
  const diff = Date.now() - startedAtNanos / 1000000
  const sec = Math.floor(diff / 1000)
  if (sec < 0) return '-'
  if (sec < 60) return `${sec}s`
  if (sec < 3600) return `${Math.floor(sec / 60)}m ${sec % 60}s`
  const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60)
  if (h < 24) return `${h}h ${m}m`
  return `${Math.floor(h / 24)}d ${h % 24}h`
}

function stateColor(state: string): string {
  switch (state) {
    case 'running': case 'busy': return 'var(--p-success-500)'
    case 'idle': return 'var(--p-accent-500)'
    case 'failed': return 'var(--p-danger-500)'
    case 'exited': case 'stopped': return 'var(--p-text-muted-color)'
    case 'starting': case 'stopping': return 'var(--p-warn-500)'
    default: return 'var(--p-text-muted-color)'
  }
}

function activityLevel(pid: string): number {
  const delta = stepDeltas.value.get(pid) || 0
  if (delta > 20) return 3
  if (delta > 5) return 2
  if (delta > 0) return 1
  return 0
}

function calculateStepRates() {
  const intervalSec = sampleRate.value / 1000
  let totalDelta = 0
  const newDeltas = new Map<string, number>()
  const newHistory: Record<string, number[]> = { ...stepHistory.value }

  for (const host of hosts.value) {
    let hostDelta = 0
    for (const p of (host.processes || [])) {
      const prev = prevStepCounts.value.get(p.pid) || p.steps
      const delta = p.steps - prev
      hostDelta += delta
      totalDelta += delta
      prevStepCounts.value.set(p.pid, p.steps)
      newDeltas.set(p.pid, Math.round(delta / intervalSec))
    }
    const hist = stepHistory.value[host.host_id] || []
    hist.push(hostDelta / intervalSec)
    if (hist.length > CHART_POINTS) hist.shift()
    newHistory[host.host_id] = hist
  }

  const gh = [...globalHistory.value, totalDelta / intervalSec]
  if (gh.length > CHART_POINTS) gh.shift()

  stepHistory.value = newHistory
  globalHistory.value = gh
  stepDeltas.value = newDeltas
  currentStepsPerSec.value = Math.round(totalDelta / intervalSec)
}

async function loadStats() {
  try {
    const [res, sysRes] = await Promise.all([
      fetchPmStats(api),
      fetchSystemInfo(api).catch(() => null),
    ])
    hosts.value = res.processes || []
    services.value = res.services || []
    if (sysRes?.info) systemInfo.value = sysRes.info
    calculateStepRates()
    error.value = null
  } catch (e: any) {
    error.value = e.response?.data?.error || e.message
  } finally {
    loading.value = false
  }
}

async function doTerminate(pid: string) {
  confirmPid.value = null
  const s = new Set(terminating.value); s.add(pid); terminating.value = s
  try {
    await terminateProcess(api, pid)
  } catch (e: any) {
    error.value = e?.response?.data?.error || 'Failed to terminate process'
  } finally {
    const s2 = new Set(terminating.value); s2.delete(pid); terminating.value = s2
  }
}

function shortHostId(id: string): string {
  return id.replace(/^app:/, '')
}

function fmtBytes(b: number | undefined): string {
  if (!b) return '0'
  if (b < 1024) return b + 'B'
  if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
  if (b < 1024 * 1024 * 1024) return (b / (1024 * 1024)).toFixed(1) + 'MB'
  return (b / (1024 * 1024 * 1024)).toFixed(2) + 'GB'
}

let pollTimer: ReturnType<typeof setInterval> | null = null

function startPolling() {
  if (pollTimer) clearInterval(pollTimer)
  prevStepCounts.value.clear()
  stepHistory.value = {}
  globalHistory.value = []
  loadStats()
  pollTimer = setInterval(loadStats, sampleRate.value)
}

watch(sampleRate, startPolling)
onMounted(startPolling)
onUnmounted(() => { if (pollTimer) clearInterval(pollTimer) })
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader title="System Monitor" :loading="loading" @refresh="loadStats">
      <select v-model.number="sampleRate" class="poll-select">
        <option :value="1000">1s</option>
        <option :value="3000">3s</option>
        <option :value="5000">5s</option>
        <option :value="10000">10s</option>
      </select>
    </PageHeader>

    <div v-if="error && hosts.length === 0" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <Icon icon="tabler:alert-circle" class="w-8 h-8 mx-auto mb-2 text-danger-500" />
        <div class="text-xs text-danger-500">{{ error }}</div>
      </div>
    </div>

    <template v-else-if="!loading">
      <!-- Stats strip -->
      <div class="stats-strip">
        <div class="stat-item">
          <Icon icon="tabler:server" class="w-3.5 h-3.5 text-info-500" />
          <span class="stat-label">Hosts</span>
          <span class="stat-num">{{ hostCount }}</span>
        </div>
        <div class="stat-item">
          <Icon icon="tabler:activity" class="w-3.5 h-3.5 text-success-500" />
          <span class="stat-label">Processes</span>
          <span class="stat-num">{{ processCount }}</span>
        </div>
        <div class="stat-item">
          <Icon icon="tabler:cube" class="w-3.5 h-3.5 text-info-500" />
          <span class="stat-label">Services</span>
          <span class="stat-num">{{ serviceCount }}</span>
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">({{ runningServices }} up)</span>
        </div>
        <div class="stat-item">
          <Icon icon="tabler:chart-line" class="w-3.5 h-3.5 text-accent-500" />
          <span class="stat-label">Steps/s</span>
          <span class="stat-num tabular-nums w-14 text-right">{{ currentStepsPerSec }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">avg</span>
          <span class="stat-num tabular-nums w-14 text-right">{{ globalAvgStepsPerSec }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">peak</span>
          <span class="stat-num tabular-nums w-14 text-right">{{ peakStepsPerSec }}</span>
        </div>
      </div>

      <!-- System info -->
      <div v-if="systemInfo" class="sys-info-strip">
        <template v-if="systemInfo.memory">
          <div class="sys-item">
            <Icon icon="tabler:cpu" class="w-3 h-3 text-warn-500" />
            <span class="sys-label">Alloc</span>
            <span class="sys-val">{{ fmtBytes(systemInfo.memory.alloc || systemInfo.memory.Alloc) }}</span>
          </div>
          <div class="sys-item">
            <span class="sys-label">Sys</span>
            <span class="sys-val">{{ fmtBytes(systemInfo.memory.sys || systemInfo.memory.Sys) }}</span>
          </div>
          <div class="sys-item">
            <span class="sys-label">Heap</span>
            <span class="sys-val">{{ fmtBytes(systemInfo.memory.heap_alloc || systemInfo.memory.HeapAlloc) }}</span>
          </div>
          <div class="sys-item">
            <span class="sys-label">GC</span>
            <span class="sys-val">{{ systemInfo.memory.num_gc || systemInfo.memory.NumGC || 0 }}</span>
          </div>
          <div class="sys-item">
            <span class="sys-label">Goroutines</span>
            <span class="sys-val">{{ systemInfo.memory.goroutines || systemInfo.memory.num_goroutine || systemInfo.runtime?.goroutines || '-' }}</span>
          </div>
        </template>
        <template v-if="systemInfo.runtime">
          <div class="sys-item">
            <Icon icon="tabler:brand-golang" class="w-3 h-3 text-info-500" />
            <span class="sys-label">Go</span>
            <span class="sys-val">{{ systemInfo.runtime.go_version || systemInfo.runtime.version || '-' }}</span>
          </div>
          <div class="sys-item">
            <span class="sys-label">CPUs</span>
            <span class="sys-val">{{ systemInfo.runtime.num_cpu || systemInfo.runtime.cpus || '-' }}</span>
          </div>
        </template>
        <template v-if="systemInfo.cpu">
          <div class="sys-item">
            <Icon icon="tabler:cpu-2" class="w-3 h-3 text-info-500" />
            <span class="sys-label">Cores</span>
            <span class="sys-val">{{ systemInfo.cpu.cores || systemInfo.cpu.num_cpu || '-' }}</span>
          </div>
        </template>
      </div>

      <!-- Host filter -->
      <div v-if="hosts.length > 1" class="host-filter">
        <span class="text-[10px]" style="color: var(--p-text-muted-color)">Hosts:</span>
        <button
          v-for="h in hosts" :key="h.host_id"
          class="host-btn" :class="{ dimmed: hiddenHosts.has(h.host_id) }"
          @click="toggleHost(h.host_id)"
        >
          <span class="w-2 h-2 rounded-full shrink-0" :style="{ background: hostColorMap.get(h.host_id)?.bg }" />
          {{ shortHostId(h.host_id) }}
          <span style="opacity: 0.5">{{ (h.processes || []).length }}</span>
        </button>
      </div>

      <!-- Activity chart -->
      <div v-if="hasChartData" class="chart-area">
        <LineChart
          :labels="activityChartLabels"
          :series="activityChartSeries"
          :height="80"
          :stacked="true"
          :fill="true"
          :format-value="(v: number) => Math.round(v) + '/s'"
        />
      </div>

      <!-- Tabs -->
      <div class="tab-bar">
        <button class="tab-btn" :class="{ active: activeTab === 'processes' }" @click="activeTab = 'processes'">
          Processes <span class="count">({{ processCount }})</span>
        </button>
        <button class="tab-btn" :class="{ active: activeTab === 'services' }" @click="activeTab = 'services'">
          Services <span class="count">({{ serviceCount }})</span>
        </button>
      </div>

      <!-- Confirm dialog -->
      <Teleport to="body">
        <div v-if="confirmPid" class="confirm-overlay" @click.self="confirmPid = null">
          <div class="confirm-dialog">
            <div class="flex items-center gap-2 mb-3">
              <Icon icon="tabler:alert-triangle" class="w-5 h-5 text-danger-500" />
              <span class="text-sm font-semibold" style="color: var(--p-text-color)">Terminate Process</span>
            </div>
            <p class="text-[11px] mb-4" style="color: var(--p-text-muted-color)">
              Terminate process <span class="font-mono font-bold" style="color: var(--p-text-color)">{{ shortPid(confirmPid) }}</span>? This will immediately stop the process.
            </p>
            <div class="flex justify-end gap-2">
              <button class="cfm-btn cancel" @click="confirmPid = null">Cancel</button>
              <button class="cfm-btn danger" @click="doTerminate(confirmPid!)">Terminate</button>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Process tree -->
      <div v-if="activeTab === 'processes'" class="flex-1 overflow-y-auto">
        <table class="w-full text-[11px]">
          <thead class="sticky top-0 z-10" style="background: var(--p-surface-100)">
            <tr style="color: var(--p-text-muted-color)">
              <th class="px-4 py-1.5 text-left font-medium">Source</th>
              <th class="px-3 py-1.5 text-left font-medium w-16">PID</th>
              <th class="px-3 py-1.5 text-left font-medium w-24">Actor</th>
              <th class="px-3 py-1.5 text-right font-medium w-16">Steps</th>
              <th class="px-3 py-1.5 text-right font-medium w-20">Uptime</th>
              <th class="px-3 py-1.5 text-center font-medium w-16">State</th>
              <th class="px-3 py-1.5 w-8"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in treeRows" :key="row.process.pid" class="proc-row group">
              <td class="px-4 py-1">
                <div class="flex items-center" :style="{ paddingLeft: row.depth * 18 + 'px' }">
                  <button
                    v-if="row.children.length > 0"
                    class="w-4 h-4 shrink-0 flex items-center justify-center rounded mr-1"
                    style="color: var(--p-text-muted-color)"
                    @click.stop="toggleCollapse(row.process.pid)"
                  >
                    <Icon :icon="collapsed.has(row.process.pid) ? 'tabler:chevron-right' : 'tabler:chevron-down'" class="w-3 h-3" />
                  </button>
                  <span v-else class="w-4 h-4 shrink-0 mr-1" />
                  <span
                    class="w-2 h-2 rounded-full shrink-0 mr-2"
                    :style="{ background: hostColorMap.get(row.process.hostId)?.bg }"
                    :class="{ 'animate-pulse': activityLevel(row.process.pid) >= 2 }"
                  />
                  <span class="font-medium truncate" style="color: var(--p-text-color)">{{ shortSource(row.process.source) }}</span>
                  <span class="text-[9px] ml-2 truncate" style="color: var(--p-text-muted-color); opacity: 0.6">{{ sourceNamespace(row.process.source) }}</span>
                </div>
              </td>
              <td class="px-3 py-1 font-mono tabular-nums" style="color: var(--p-text-muted-color)">{{ shortPid(row.process.pid) }}</td>
              <td class="px-3 py-1 text-[10px] truncate max-w-[120px]" style="color: var(--p-text-muted-color)" :title="row.process.actor_id">{{ row.process.actor_id || '-' }}</td>
              <td class="px-3 py-1 text-right font-mono tabular-nums" style="color: var(--p-text-color)">{{ row.process.steps.toLocaleString() }}</td>
              <td class="px-3 py-1 text-right tabular-nums whitespace-nowrap" style="color: var(--p-text-muted-color)">{{ formatUptime(row.process.started_at) }}</td>
              <td class="px-3 py-1 text-center">
                <span class="state-badge" :style="{ color: stateColor(row.process.state), background: stateColor(row.process.state) + '20' }">
                  {{ row.process.state }}
                </span>
              </td>
              <td class="px-3 py-1 text-center">
                <button
                  class="term-btn opacity-0 group-hover:opacity-100"
                  :class="{ '!opacity-100': terminating.has(row.process.pid) }"
                  :disabled="terminating.has(row.process.pid)"
                  @click="confirmPid = row.process.pid"
                >
                  <Icon
                    :icon="terminating.has(row.process.pid) ? 'tabler:loader-2' : 'tabler:x'"
                    class="w-3 h-3"
                    :class="{ 'animate-spin': terminating.has(row.process.pid) }"
                  />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-if="treeRows.length === 0" class="flex flex-col items-center justify-center py-16" style="color: var(--p-text-muted-color)">
          <Icon icon="tabler:binary-tree" class="w-8 h-8 mb-2" style="opacity: 0.3" />
          <span class="text-xs">No processes</span>
        </div>
      </div>

      <!-- Services -->
      <div v-if="activeTab === 'services'" class="flex-1 overflow-y-auto">
        <table class="w-full text-[11px]">
          <thead class="sticky top-0 z-10" style="background: var(--p-surface-100)">
            <tr style="color: var(--p-text-muted-color)">
              <th class="px-4 py-1.5 text-left font-medium">Service</th>
              <th class="px-3 py-1.5 text-center font-medium w-16">Status</th>
              <th class="px-3 py-1.5 text-center font-medium w-16">Desired</th>
              <th class="px-3 py-1.5 text-right font-medium w-16">Uptime</th>
              <th class="px-3 py-1.5 text-right font-medium w-12">Retries</th>
              <th class="px-4 py-1.5 text-left font-medium">Details</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="svc in services" :key="svc.id" class="proc-row">
              <td class="px-4 py-1.5 font-medium" style="color: var(--p-text-color)">{{ svc.id }}</td>
              <td class="px-3 py-1.5 text-center">
                <span class="state-badge" :style="{ color: stateColor(svc.status), background: stateColor(svc.status) + '20' }">
                  {{ svc.status }}
                </span>
              </td>
              <td class="px-3 py-1.5 text-center" style="color: var(--p-text-muted-color)">{{ svc.desired }}</td>
              <td class="px-3 py-1.5 text-right tabular-nums whitespace-nowrap" style="color: var(--p-text-muted-color)">{{ formatUptime(svc.started_at) }}</td>
              <td class="px-3 py-1.5 text-right font-mono tabular-nums" :class="{ 'text-warn-500': svc.retry_count > 0 }" :style="svc.retry_count <= 0 ? { color: 'var(--p-text-muted-color)' } : {}">
                {{ svc.retry_count }}
              </td>
              <td class="px-4 py-1.5 truncate max-w-[200px]" style="color: var(--p-text-muted-color)" :title="svc.details">{{ svc.details || '-' }}</td>
            </tr>
          </tbody>
        </table>
        <div v-if="services.length === 0" class="flex flex-col items-center justify-center py-16" style="color: var(--p-text-muted-color)">
          <Icon icon="tabler:cube" class="w-8 h-8 mb-2" style="opacity: 0.3" />
          <span class="text-xs">No services</span>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.stats-strip {
  display: flex; align-items: center; gap: 16px; padding: 8px 16px;
  border-bottom: 1px solid var(--p-content-border-color); font-size: 11px;
}
.stat-item { display: flex; align-items: center; gap: 4px; }
.stat-label { color: var(--p-text-muted-color); }
.sys-info-strip {
  display: flex; align-items: center; gap: 14px; padding: 5px 16px;
  border-bottom: 1px solid var(--p-surface-100); font-size: 10px;
  background: var(--p-surface-50);
}
.sys-item { display: flex; align-items: center; gap: 3px; }
.sys-label { color: var(--p-text-muted-color); }
.sys-val { font-family: monospace; color: var(--p-text-color); font-weight: 500; }
.stat-num { font-weight: 700; color: var(--p-text-color); font-size: 12px; }

.host-filter {
  display: flex; align-items: center; gap: 6px; padding: 6px 16px;
  border-bottom: 1px solid var(--p-content-border-color);
}
.host-btn {
  display: flex; align-items: center; gap: 4px; padding: 2px 8px;
  border-radius: 4px; font-size: 10px; font-weight: 500;
  background: var(--p-surface-100); color: var(--p-text-color);
}
.host-btn.dimmed { opacity: 0.35; }
.host-btn:hover { background: var(--p-surface-200); }

.chart-area {
  flex-shrink: 0; padding: 0 12px;
  border-bottom: 1px solid var(--p-content-border-color);
}

.tab-bar {
  display: flex; border-bottom: 1px solid var(--p-content-border-color); flex-shrink: 0;
}
.tab-btn {
  padding: 6px 16px; font-size: 11px; font-weight: 500;
  color: var(--p-text-muted-color); border-bottom: 2px solid transparent;
}
.tab-btn:hover { color: var(--p-text-color); }
.tab-btn.active { color: var(--p-primary, var(--p-warn-500)); border-color: var(--p-primary, var(--p-warn-500)); }
.tab-btn .count { font-size: 10px; opacity: 0.6; }

.proc-row { border-bottom: 1px solid var(--p-surface-100); }
.proc-row:hover { background: var(--p-surface-50, var(--p-surface-100)); }

.state-badge {
  display: inline-block; padding: 1px 6px; border-radius: 3px;
  font-size: 10px; font-weight: 500;
}

.term-btn {
  padding: 2px; border-radius: 3px; color: var(--p-danger-500); transition: opacity 0.15s;
}
.term-btn:hover { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent); }

.poll-select {
  padding: 2px 6px; border-radius: 4px; font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}

.confirm-overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0,0,0,0.6);
  display: flex; align-items: center; justify-content: center;
}
.confirm-dialog {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color); border-radius: 8px;
  padding: 20px; width: 360px; max-width: 90vw;
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
}
.cfm-btn {
  padding: 6px 16px; border-radius: 4px; font-size: 11px; cursor: pointer; border: none;
}
.cfm-btn.cancel {
  background: var(--p-surface-100); color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
}
.cfm-btn.cancel:hover { background: var(--p-surface-200); }
.cfm-btn.danger { background: var(--p-danger-500); color: #fff; font-weight: 600; }
.cfm-btn.danger:hover { opacity: 0.9; }
</style>
