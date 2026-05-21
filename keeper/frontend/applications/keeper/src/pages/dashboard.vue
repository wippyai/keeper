<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Badge from 'primevue/badge'
import { useApi } from '../composables/useWippy'
import { listNamespaces, listEntries, getSyncState, type RegistryEntry, type Namespace } from '../api/registry'
import { fetchPmStats, type HostStats, type ServiceState } from '../api/pm'
import { listDataflows, statusColor as dfStatusColor, statusIcon as dfStatusIcon, type Dataflow } from '../api/dataflows'
import { listTasks, phaseColors, phaseIcons, type Task } from '../api/tasks'
import { listSessions, timeAgo, formatTokens, type Session } from '../api/sessions'
import { listChangesets, stateColors, stateIcons, type Changeset } from '../api/changesets'
import { listChangelog, opColor, opIcon, type ChangelogEntry } from '../api/changelog'
import { getLogStats, getLogs, type LogStats } from '../api/logger'
import { getUsageSummary, type TokenTotals } from '../api/usage'
import { listKBs } from '../api/knowledge'
import { entryName } from '../utils'

const api = useApi()
const router = useRouter()

const loading = ref(true)
const lastLoaded = ref<Date | null>(null)
const refreshHandle = ref<number | null>(null)

// --- registry counts ---
const agents = ref<RegistryEntry[]>([])
const models = ref<RegistryEntry[]>([])
const tools = ref<RegistryEntry[]>([])
const totalEntries = ref(0)
const testCount = ref(0)
const endpointCount = ref(0)
const traitCount = ref(0)
const policyCount = ref(0)
const componentCount = ref(0)
const namespaces = ref<Namespace[]>([])

// --- runtime ---
const hosts = ref<HostStats[]>([])
const services = ref<ServiceState[]>([])

// --- workflow ---
const dataflows = ref<Dataflow[]>([])
const recentFlows = ref<Dataflow[]>([])
const tasks = ref<Task[]>([])
const sessions = ref<Session[]>([])

// --- governance ---
const changesets = ref<Changeset[]>([])
const changelog = ref<ChangelogEntry[]>([])

// --- knowledge / observability / usage ---
const kbs = ref<{ id: string; name: string; node_count: number }[]>([])
const logStats = ref<LogStats | null>(null)
const recentLogs = ref<{ message: string; timestamp: number; logger_name?: string; level: number }[]>([])
const usageToday = ref<TokenTotals | null>(null)
const registryVersion = ref<number | null>(null)

// --- derived counts ---
const processCount = computed(() => hosts.value.reduce((s, h) => s + (h.process_count || 0), 0))
const queueDepth = computed(() => hosts.value.reduce((s, h) => s + (h.queue_depth || 0), 0))
const totalExecuted = computed(() => hosts.value.reduce((s, h) => s + (h.executed || 0), 0))

const runningServices = computed(() => services.value.filter(s => s.status === 'running').length)
const failedServices = computed(() => services.value.filter(s => s.status === 'failed' || (s.status !== 'running' && (s.retry_count || 0) > 0)).length)

const runningFlows = computed(() => dataflows.value.filter(d => d.status === 'running').length)
const failedFlows = computed(() => dataflows.value.filter(d => d.status === 'failed' || d.status === 'terminated').length)
const completedFlows = computed(() => dataflows.value.filter(d => d.status === 'completed').length)
const pendingFlows = computed(() => dataflows.value.filter(d => d.status === 'pending' || d.status === 'ready').length)

const activeTasks = computed(() => tasks.value.filter(t => t.status === 'active').length)
const blockedTasks = computed(() => tasks.value.filter(t => t.status === 'waiting_for_user').length)
const completedTasks = computed(() => tasks.value.filter(t => t.status === 'completed').length)

const openChangesets = computed(() => changesets.value.filter(c => c.state === 'open' || c.state === 'editing').length)
const reviewChangesets = computed(() => changesets.value.filter(c => c.state === 'review').length)

const flowStatusBreakdown = computed(() => {
  const buckets: Record<string, number> = {}
  for (const f of dataflows.value) buckets[f.status] = (buckets[f.status] || 0) + 1
  return Object.entries(buckets).sort((a, b) => b[1] - a[1])
})

const tasksByPhase = computed(() => {
  const buckets: Record<string, number> = {}
  for (const t of tasks.value) {
    if (t.status !== 'active') continue
    const phase = t.phase || 'unknown'
    buckets[phase] = (buckets[phase] || 0) + 1
  }
  return Object.entries(buckets).sort((a, b) => b[1] - a[1])
})

const modelsByProvider = computed(() => {
  const groups: Record<string, RegistryEntry[]> = {}
  for (const m of models.value) {
    const provider = (m.data?.provider || m.meta?.provider || m.id.split(':')[0].split('.').pop() || 'other').toString()
    if (!groups[provider]) groups[provider] = []
    groups[provider].push(m)
  }
  return Object.entries(groups).sort((a, b) => b[1].length - a[1].length).slice(0, 6)
})

const topNamespaces = computed(() =>
  [...namespaces.value].sort((a, b) => b.count - a.count).slice(0, 30)
)

const recentActiveTasks = computed(() =>
  [...tasks.value]
    .filter(t => t.status === 'active' || t.status === 'waiting_for_user')
    .sort((a, b) => (b.updated_at || '').localeCompare(a.updated_at || ''))
    .slice(0, 8)
)

const totalKbNodes = computed(() => kbs.value.reduce((s, k) => s + (k.node_count || 0), 0))

const currentUser = ref<{ email: string; full_name: string } | null>(null)
const greeting = computed(() => {
  const h = new Date().getHours()
  if (h < 5)  return 'Working late'
  if (h < 12) return 'Good morning'
  if (h < 18) return 'Good afternoon'
  return 'Good evening'
})
const welcomeName = computed(() => {
  const fn = currentUser.value?.full_name || currentUser.value?.email?.split('@')[0] || ''
  return fn ? fn.split(/[\s.@_-]+/)[0] : ''
})

const WELCOME_KEY = '@keeper/dashboard-welcome-collapsed'
const welcomeCollapsed = ref<boolean>(false)
try { welcomeCollapsed.value = localStorage.getItem(WELCOME_KEY) === '1' } catch {}
function toggleWelcome() {
  welcomeCollapsed.value = !welcomeCollapsed.value
  try { localStorage.setItem(WELCOME_KEY, welcomeCollapsed.value ? '1' : '0') } catch {}
}

async function fetchMe() {
  try {
    const { data } = await api.get('/api/v1/user/me')
    if (data?.success && data.user) {
      currentUser.value = { email: data.user.email, full_name: data.user.full_name }
    }
  } catch { /* greeting falls back to anonymous on failure */ }
}

const systemHealth = computed<'good' | 'warn' | 'bad'>(() => {
  if (failedServices.value > 0 || failedFlows.value > 3) return 'bad'
  if (queueDepth.value > 50 || (logStats.value?.counters.error || 0) > 20 || blockedTasks.value > 0) return 'warn'
  return 'good'
})

function goStructure(ns?: string) {
  router.push({ path: '/structure', query: ns ? { ns } : undefined })
}
function goEntry(id: string) {
  const ns = id.split(':')[0]
  router.push({ path: '/structure', query: { ns, entry: id } })
}

async function load() {
  if (lastLoaded.value === null) loading.value = true
  const results = await Promise.allSettled([
    listEntries(api, { metaType: 'agent.gen1', limit: 100 }),
    listEntries(api, { metaType: 'llm.model', limit: 200 }),
    listEntries(api, { metaType: 'tool', limit: 200 }),
    listEntries(api, { metaType: 'test', limit: 1 }),
    listEntries(api, { kind: 'http.endpoint', limit: 1 }),
    listEntries(api, { metaType: 'agent.trait', limit: 1 }),
    listEntries(api, { kind: 'security.policy', limit: 1 }),
    listEntries(api, { kind: 'view.component', limit: 1 }),
    listNamespaces(api),
    listEntries(api, { limit: 1 }),
    fetchPmStats(api),
    listDataflows(api, 100, 0),
    listTasks(api, { limit: '60' }),
    listSessions(api, 6),
    listChangesets(api, { limit: '40' }),
    listChangelog(api, { limit: 12 }),
    getLogStats(api),
    getLogs(api, 25, '', true),
    getUsageSummary(api, 'today'),
    listKBs(api),
    getSyncState(api),
  ])

  const r = (i: number) => results[i].status === 'fulfilled' ? (results[i] as any).value : null
  const v = r(0); if (v) agents.value = v.entries || []
  if (r(1)) models.value = r(1).entries || []
  if (r(2)) tools.value = r(2).entries || []
  if (r(3)) testCount.value = r(3).total || 0
  if (r(4)) endpointCount.value = r(4).total || 0
  if (r(5)) traitCount.value = r(5).total || 0
  if (r(6)) policyCount.value = r(6).total || 0
  if (r(7)) componentCount.value = r(7).total || 0
  if (r(8)) namespaces.value = r(8).namespaces || []
  if (r(9)) totalEntries.value = r(9).total || 0
  if (r(10)) {
    hosts.value = r(10).processes || []
    services.value = r(10).services || []
  }
  if (r(11)) {
    dataflows.value = r(11).dataflows || []
    recentFlows.value = dataflows.value.slice(0, 8)
  }
  if (r(12)) tasks.value = r(12).tasks || []
  if (r(13)) sessions.value = r(13).sessions || []
  if (r(14)) changesets.value = r(14).changesets || r(14).items || []
  if (r(15)) changelog.value = r(15).changes || r(15).items || []
  if (r(16)) logStats.value = r(16).stats || null
  if (r(17)) recentLogs.value = ((r(17).logs || []) as any[])
    .slice(0, 25)
    .map(l => ({ message: l.message, timestamp: l.timestamp, logger_name: l.logger_name, level: l.level }))
  if (r(18)) usageToday.value = r(18).summary || null
  if (r(19)) kbs.value = r(19).kbs || r(19).items || []
  if (r(20)) {
    registryVersion.value = r(20).registry?.current_version ?? null
  }

  loading.value = false
  lastLoaded.value = new Date()
}

onMounted(() => {
  load()
  fetchMe()
  refreshHandle.value = window.setInterval(load, 30000) as unknown as number
})
onUnmounted(() => {
  if (refreshHandle.value) window.clearInterval(refreshHandle.value)
})

function fmt(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1_000) return (n / 1_000).toFixed(1) + 'k'
  return String(n)
}
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- Header bar -->
    <div class="shrink-0 px-4 py-2.5 flex items-center justify-between border-b border-[var(--p-content-border-color)]">
      <div class="flex items-center gap-2">
        <Icon icon="tabler:layout-dashboard" class="w-4 h-4 keeper-accent" />
        <span class="text-xs font-medium text-[var(--p-text-color)]">Dashboard</span>
        <span v-if="registryVersion !== null" class="text-[10px] px-1.5 py-0.5 rounded font-mono bg-[var(--p-surface-100)] text-[var(--p-text-muted-color)]" title="Current registry version">
          v{{ registryVersion }}
        </span>
        <span v-if="loading" class="text-[10px] text-[var(--p-text-muted-color)] flex items-center gap-1">
          <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" /> loading
        </span>
        <span v-else-if="lastLoaded" class="text-[10px] text-[var(--p-text-muted-color)]">
          updated {{ timeAgo(lastLoaded.toISOString()) }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <span class="health-dot" :class="`health-${systemHealth}`" :title="`System health: ${systemHealth}`"></span>
        <span class="text-[10px] uppercase tracking-wide" :class="`health-text-${systemHealth}`">
          {{ systemHealth === 'good' ? 'healthy' : systemHealth === 'warn' ? 'attention' : 'critical' }}
        </span>
        <Button class="k-btn-icon !rounded" @click="load" aria-label="Refresh">
          <Icon icon="tabler:refresh" class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
        </Button>
      </div>
    </div>

    <div class="flex-1 overflow-y-auto p-4 space-y-4">
      <!-- WELCOME -->
      <section class="welcome" :class="{ 'welcome--collapsed': welcomeCollapsed }">
        <div class="welcome-glow"></div>
        <div class="welcome-body">
          <div class="welcome-text">
            <div class="welcome-title">
              <span class="welcome-greet">{{ greeting }}<template v-if="welcomeName">, {{ welcomeName }}</template>.</span>
              <span class="welcome-brand">Welcome to <span class="welcome-brand-accent">Keeper</span>.</span>
            </div>
            <p v-if="!welcomeCollapsed" class="welcome-sub">
              Your control plane for the Wippy registry — design tasks, run the multi-agent pipeline,
              and ship validated changes to <span class="font-mono text-[var(--p-text-color)]">{{ totalEntries.toLocaleString() }}</span>
              entries across <span class="font-mono text-[var(--p-text-color)]">{{ namespaces.length }}</span> namespaces.
            </p>
          </div>
          <div class="welcome-actions" v-if="!welcomeCollapsed">
            <button class="welcome-btn welcome-btn--primary" @click="router.push('/tasks')">
              <Icon icon="tabler:plus" class="w-3.5 h-3.5" />
              New task
            </button>
            <button class="welcome-btn" @click="goStructure()">
              <Icon icon="tabler:database" class="w-3.5 h-3.5" />
              Browse registry
            </button>
            <button class="welcome-btn" @click="router.push('/agents')">
              <Icon icon="tabler:robot" class="w-3.5 h-3.5" />
              Agents
            </button>
            <button class="welcome-btn" @click="router.push('/sessions')">
              <Icon icon="tabler:messages" class="w-3.5 h-3.5" />
              Sessions
            </button>
          </div>
          <button class="welcome-collapse" :title="welcomeCollapsed ? 'Expand' : 'Collapse'" @click="toggleWelcome">
            <Icon :icon="welcomeCollapsed ? 'tabler:chevron-down' : 'tabler:chevron-up'" class="w-3.5 h-3.5" />
          </button>
        </div>
      </section>

      <!-- HERO ROW: 4 big tinted cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
        <!-- Pipeline -->
        <button class="hero-card hero-warn" @click="router.push('/tasks')">
          <div class="hero-head">
            <Icon icon="tabler:list-check" class="w-4 h-4" />
            <span class="hero-label">Pipeline</span>
            <Icon icon="tabler:chevron-right" class="w-3 h-3 opacity-60 ml-auto" />
          </div>
          <div class="hero-num">{{ activeTasks }}</div>
          <div class="hero-sub">
            <span>{{ tasks.length }} total</span>
            <Tag v-if="blockedTasks" severity="warn" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">
              <Icon icon="tabler:message-question" class="w-3 h-3" />{{ blockedTasks }} waiting
            </Tag>
            <Tag v-if="completedTasks" severity="success" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">
              ✓ {{ completedTasks }}
            </Tag>
          </div>
        </button>

        <!-- Dataflows -->
        <button class="hero-card hero-info" @click="router.push('/dataflows')">
          <div class="hero-head">
            <Icon icon="tabler:git-merge" class="w-4 h-4" :class="{ 'animate-pulse': runningFlows > 0 }" />
            <span class="hero-label">Dataflows</span>
            <Icon icon="tabler:chevron-right" class="w-3 h-3 opacity-60 ml-auto" />
          </div>
          <div class="hero-num">{{ runningFlows }}</div>
          <div class="hero-sub">
            <span>running now</span>
            <Tag v-if="completedFlows" severity="success" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">{{ completedFlows }} ✓</Tag>
            <Tag v-if="failedFlows" severity="danger" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">{{ failedFlows }} ✗</Tag>
            <Tag v-if="pendingFlows" severity="warn" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">{{ pendingFlows }} queued</Tag>
          </div>
        </button>

        <!-- Token usage -->
        <button class="hero-card hero-accent" @click="router.push('/plugin/keeper.usage:main')">
          <div class="hero-head">
            <Icon icon="tabler:coin" class="w-4 h-4" />
            <span class="hero-label">Tokens today</span>
            <Icon icon="tabler:chevron-right" class="w-3 h-3 opacity-60 ml-auto" />
          </div>
          <div class="hero-num">{{ usageToday ? formatTokens(usageToday.total_tokens) : '—' }}</div>
          <div class="hero-sub" v-if="usageToday">
            <span>{{ usageToday.request_count }} req</span>
            <Tag severity="info" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">→ {{ formatTokens(usageToday.prompt_tokens) }}</Tag>
            <Tag class="k-tag-tone-accent !text-[11px] !px-[9px] !py-[3px] !font-medium">← {{ formatTokens(usageToday.completion_tokens) }}</Tag>
          </div>
          <div class="hero-sub" v-else>
            <span class="opacity-60">no calls yet</span>
          </div>
        </button>

        <!-- System health -->
        <button class="hero-card" :class="systemHealth === 'good' ? 'hero-success' : systemHealth === 'warn' ? 'hero-warn' : 'hero-danger'" @click="router.push('/system')">
          <div class="hero-head">
            <Icon icon="tabler:cpu" class="w-4 h-4" />
            <span class="hero-label">System</span>
            <Icon icon="tabler:chevron-right" class="w-3 h-3 opacity-60 ml-auto" />
          </div>
          <div class="hero-num">{{ runningServices }}<span class="hero-num-sub">/{{ services.length }}</span></div>
          <div class="hero-sub">
            <span>{{ processCount }} processes · {{ hosts.length }} host{{ hosts.length === 1 ? '' : 's' }}</span>
            <Tag v-if="queueDepth > 0" severity="warn" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">queue {{ queueDepth }}</Tag>
            <Tag v-if="failedServices" severity="danger" class="!text-[11px] !px-[9px] !py-[3px] !font-medium">{{ failedServices }} fail</Tag>
          </div>
        </button>
      </div>

      <!-- Health alerts strip — only critical action items, error count lives in the Logs panel below. -->
      <div v-if="failedServices || failedFlows || blockedTasks" class="alerts">
        <div v-if="failedServices" class="alert" @click="router.push('/system')">
          <Icon icon="tabler:alert-triangle" class="w-3.5 h-3.5 text-danger-500" />
          <span>{{ failedServices }} service{{ failedServices === 1 ? '' : 's' }} failing</span>
        </div>
        <div v-if="failedFlows" class="alert" @click="router.push('/dataflows')">
          <Icon icon="tabler:flame" class="w-3.5 h-3.5 text-danger-500" />
          <span>{{ failedFlows }} dataflow{{ failedFlows === 1 ? '' : 's' }} failed</span>
        </div>
        <div v-if="blockedTasks" class="alert" @click="router.push('/tasks')">
          <Icon icon="tabler:message-question" class="w-3.5 h-3.5 text-warn-500" />
          <span>{{ blockedTasks }} task{{ blockedTasks === 1 ? '' : 's' }} waiting on user</span>
        </div>
      </div>

      <!-- Pipeline + Dataflow + Sessions row -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-3">
        <!-- Pipeline phases -->
        <div class="card">
          <div class="card-head accent-warn">
            <Icon icon="tabler:list-check" class="w-3.5 h-3.5 text-warn-500" />
            <span class="card-title">Active phases</span>
            <span class="card-cnt">{{ activeTasks }}</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/tasks')">all tasks</button>
          </div>
          <div class="card-list">
            <div v-if="!tasksByPhase.length" class="card-empty">No active tasks</div>
            <div v-for="[phase, count] in tasksByPhase" :key="phase" class="card-item phase-row" @click="router.push('/tasks')">
              <Icon :icon="phaseIcons[phase] || 'tabler:point'" class="w-3.5 h-3.5 shrink-0" :style="{ color: phaseColors[phase] || 'var(--p-text-muted-color)' }" />
              <span class="text-[11px] text-[var(--p-text-color)] capitalize">{{ phase }}</span>
              <span class="phase-bar" :style="{ background: `color-mix(in srgb, ${phaseColors[phase] || 'var(--p-text-muted-color)'} 25%, transparent)`, width: Math.min(100, count * 12) + '%' }"></span>
              <span class="text-[10px] text-[var(--p-text-muted-color)] ml-auto">{{ count }}</span>
            </div>
            <div v-if="recentActiveTasks.length" class="card-section-head">Recent</div>
            <div v-for="t in recentActiveTasks.slice(0, 5)" :key="t.task_id" class="card-item" @click="router.push('/tasks/' + t.task_id)">
              <Icon :icon="phaseIcons[t.phase] || 'tabler:point'" class="w-3 h-3 shrink-0" :style="{ color: phaseColors[t.phase] || 'var(--p-text-muted-color)' }" />
              <span class="text-[11px] truncate text-[var(--p-text-color)]">{{ t.title }}</span>
              <span class="ml-auto text-[9px] text-[var(--p-text-muted-color)]">#{{ t.iteration }}</span>
            </div>
          </div>
        </div>

        <!-- Dataflows -->
        <div class="card">
          <div class="card-head accent-info">
            <Icon icon="tabler:git-merge" class="w-3.5 h-3.5 text-info-500" />
            <span class="card-title">Dataflows</span>
            <span class="card-cnt">{{ dataflows.length }}</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/dataflows')">all</button>
          </div>
          <div class="card-list">
            <div v-if="!flowStatusBreakdown.length" class="card-empty">No dataflows</div>
            <div v-for="[status, count] in flowStatusBreakdown" :key="status" class="card-item phase-row" @click="router.push('/dataflows')">
              <Icon :icon="dfStatusIcon(status)" class="w-3.5 h-3.5 shrink-0" :style="{ color: dfStatusColor(status) }" :class="{ 'animate-pulse': status === 'running' }" />
              <span class="text-[11px] text-[var(--p-text-color)] capitalize">{{ status }}</span>
              <span class="phase-bar" :style="{ background: `color-mix(in srgb, ${dfStatusColor(status)} 25%, transparent)`, width: Math.min(100, count * 4) + '%' }"></span>
              <span class="text-[10px] text-[var(--p-text-muted-color)] ml-auto">{{ count }}</span>
            </div>
            <div v-if="recentFlows.length" class="card-section-head">Recent</div>
            <div v-for="df in recentFlows.slice(0, 5)" :key="df.dataflow_id" class="card-item" @click="router.push('/dataflow/' + df.dataflow_id)">
              <Icon :icon="dfStatusIcon(df.status)" class="w-3 h-3 shrink-0" :style="{ color: dfStatusColor(df.status) }" :class="{ 'animate-pulse': df.status === 'running' }" />
              <span class="text-[11px] truncate text-[var(--p-text-color)]">{{ df.metadata?.title || df.type || 'Untitled' }}</span>
              <span class="ml-auto text-[9px] text-[var(--p-text-muted-color)]">{{ timeAgo(df.created_at) }}</span>
            </div>
          </div>
        </div>

        <!-- Sessions / activity -->
        <div class="card">
          <div class="card-head accent-accent">
            <Icon icon="tabler:messages" class="w-3.5 h-3.5 text-accent-500" />
            <span class="card-title">Sessions</span>
            <span class="card-cnt">{{ sessions.length }}</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/sessions')">all</button>
          </div>
          <div class="card-list">
            <div v-if="!sessions.length" class="card-empty">No sessions</div>
            <div v-for="s in sessions.slice(0, 8)" :key="s.session_id" class="card-item" @click="router.push('/session/' + s.session_id)">
              <Icon icon="tabler:message" class="w-3 h-3 shrink-0 text-[var(--p-text-muted-color)]" />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] truncate text-[var(--p-text-color)]">{{ s.title || 'Untitled' }}</div>
                <div v-if="s.meta?.tokens" class="text-[9px] text-[var(--p-text-muted-color)] truncate">
                  {{ formatTokens(s.meta.tokens.total_tokens) }} tokens · {{ s.config?.model || s.current_model || '?' }}
                </div>
              </div>
              <span class="text-[9px] text-[var(--p-text-muted-color)]">{{ timeAgo(s.last_message_date || s.start_date) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Registry: 4 columns of typed counters -->
      <div class="card">
        <div class="card-head">
          <Icon icon="tabler:database" class="w-3.5 h-3.5 text-info-500" />
          <span class="card-title">Registry</span>
          <span class="card-cnt">{{ totalEntries }} entries · {{ namespaces.length }} namespaces</span>
          <span class="flex-1"></span>
          <button class="card-link" @click="goStructure()">browse</button>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-2 p-2.5">
          <button class="kind-tile" @click="router.push('/agents')">
            <Icon icon="tabler:robot" class="w-3.5 h-3.5 text-warn-500" />
            <span class="kind-num">{{ agents.length }}</span>
            <span class="kind-lbl">Agents</span>
          </button>
          <button class="kind-tile" @click="router.push('/models')">
            <Icon icon="tabler:brain" class="w-3.5 h-3.5 text-accent-500" />
            <span class="kind-num">{{ models.length }}</span>
            <span class="kind-lbl">Models</span>
          </button>
          <button class="kind-tile" @click="router.push('/tools')">
            <Icon icon="tabler:tool" class="w-3.5 h-3.5 text-info-500" />
            <span class="kind-num">{{ tools.length }}</span>
            <span class="kind-lbl">Tools</span>
          </button>
          <button class="kind-tile" @click="router.push('/traits')">
            <Icon icon="tabler:tag" class="w-3.5 h-3.5 text-accent-500" />
            <span class="kind-num">{{ traitCount }}</span>
            <span class="kind-lbl">Traits</span>
          </button>
          <button class="kind-tile" @click="router.push('/endpoints')">
            <Icon icon="tabler:plug" class="w-3.5 h-3.5 text-success-500" />
            <span class="kind-num">{{ endpointCount }}</span>
            <span class="kind-lbl">Endpoints</span>
          </button>
          <button class="kind-tile" @click="router.push('/tests')">
            <Icon icon="tabler:test-pipe" class="w-3.5 h-3.5 text-info-500" />
            <span class="kind-num">{{ testCount }}</span>
            <span class="kind-lbl">Tests</span>
          </button>
          <button class="kind-tile" @click="router.push('/policies')">
            <Icon icon="tabler:shield-lock" class="w-3.5 h-3.5 text-danger-500" />
            <span class="kind-num">{{ policyCount }}</span>
            <span class="kind-lbl">Policies</span>
          </button>
          <button class="kind-tile" @click="router.push('/components')">
            <Icon icon="tabler:browser" class="w-3.5 h-3.5 text-info-500" />
            <span class="kind-num">{{ componentCount }}</span>
            <span class="kind-lbl">Components</span>
          </button>
        </div>
      </div>

      <!-- Agents + Models row -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <div class="card">
          <div class="card-head accent-warn">
            <Icon icon="tabler:robot" class="w-3.5 h-3.5 text-warn-500" />
            <span class="card-title">Agents</span>
            <span class="card-cnt">{{ agents.length }}</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/agents')">all</button>
          </div>
          <div class="card-list">
            <div v-if="!agents.length" class="card-empty">No agents</div>
            <div v-for="a in agents.slice(0, 14)" :key="a.id" class="card-item" @click="goEntry(a.id)">
              <div class="flex-1 min-w-0">
                <div class="text-[11px] font-medium truncate text-[var(--p-text-color)]">{{ a.meta?.title || entryName(a.id) }}</div>
                <div v-if="a.meta?.model || a.data?.model" class="text-[9px] font-mono mt-0.5 text-[var(--p-text-muted-color)] truncate">
                  {{ a.meta?.model || a.data?.model }}
                </div>
              </div>
              <div class="flex items-center gap-1">
                <span v-if="a.data?.delegates?.length" class="badge bg-info-500/15 text-info-500" :title="`${a.data.delegates.length} delegates`">
                  <Icon icon="tabler:users" class="w-2.5 h-2.5" />{{ a.data.delegates.length }}
                </span>
                <span v-if="a.data?.tools?.length" class="badge bg-info-500/15 text-info-500" :title="`${a.data.tools.length} tools`">
                  <Icon icon="tabler:tool" class="w-2.5 h-2.5" />{{ a.data.tools.length }}
                </span>
                <span v-if="a.data?.traits?.length" class="badge bg-accent-500/15 text-accent-500" :title="`${a.data.traits.length} traits`">
                  <Icon icon="tabler:tag" class="w-2.5 h-2.5" />{{ a.data.traits.length }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-head accent-accent">
            <Icon icon="tabler:brain" class="w-3.5 h-3.5 text-accent-500" />
            <span class="card-title">Models by provider</span>
            <span class="card-cnt">{{ models.length }}</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/models')">all</button>
          </div>
          <div class="card-list">
            <div v-if="!models.length" class="card-empty">No models</div>
            <template v-for="[provider, items] in modelsByProvider" :key="provider">
              <div class="card-section-head">{{ provider }} <span class="opacity-60">({{ items.length }})</span></div>
              <div v-for="m in items" :key="m.id" class="card-item" @click="goEntry(m.id)">
                <div class="flex-1 min-w-0">
                  <div class="text-[11px] truncate text-[var(--p-text-color)]">{{ m.meta?.title || entryName(m.id) }}</div>
                </div>
                <div class="flex items-center gap-0.5 text-[var(--p-text-muted-color)]">
                  <Icon v-if="m.meta?.capabilities?.includes('tool_use')" icon="tabler:tool" class="w-2.5 h-2.5" title="tool_use" />
                  <Icon v-if="m.meta?.capabilities?.includes('vision')" icon="tabler:eye" class="w-2.5 h-2.5" title="vision" />
                  <Icon v-if="m.meta?.capabilities?.includes('thinking')" icon="tabler:brain" class="w-2.5 h-2.5" title="thinking" />
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>


      <!-- Logs panel + Changesets row -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-3">
        <!-- Logs (full panel) -->
        <div class="card lg:col-span-2">
          <div class="card-head accent-warn">
            <Icon icon="tabler:report" class="w-3.5 h-3.5 text-warn-500" />
            <span class="card-title">Logs</span>
            <span class="card-cnt">{{ logStats ? fmt(logStats.total_received) + ' total' : '—' }}</span>
            <span v-if="logStats" class="text-[9px] text-[var(--p-text-muted-color)] ml-1">· buffer {{ fmt(logStats.stored_count) }}</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/logs')">view all</button>
          </div>
          <div v-if="!logStats" class="card-empty">No log stats</div>
          <template v-else>
            <div class="log-bar">
              <span class="log-pill" :class="logStats.counters.error > 0 ? 'log-pill--err' : ''" @click="router.push('/logs')" title="Errors">
                <Icon icon="tabler:alert-circle" class="w-2.5 h-2.5 text-danger-500" />
                <span class="log-num">{{ fmt(logStats.counters.error) }}</span>
              </span>
              <span class="log-pill" :class="logStats.counters.warn > 0 ? 'log-pill--warn' : ''" @click="router.push('/logs')" title="Warnings">
                <Icon icon="tabler:alert-triangle" class="w-2.5 h-2.5 text-warn-500" />
                <span class="log-num">{{ fmt(logStats.counters.warn) }}</span>
              </span>
              <span class="log-pill" @click="router.push('/logs')" title="Info">
                <Icon icon="tabler:info-circle" class="w-2.5 h-2.5 text-info-500" />
                <span class="log-num">{{ fmt(logStats.counters.info) }}</span>
              </span>
              <span class="log-pill" @click="router.push('/logs')" title="Debug">
                <Icon icon="tabler:terminal" class="w-2.5 h-2.5 text-[var(--p-text-muted-color)]" />
                <span class="log-num">{{ fmt(logStats.counters.debug) }}</span>
              </span>
            </div>
            <div v-if="recentLogs.length" class="card-section-head">Recent</div>
            <div v-else class="card-empty">No recent logs</div>
            <div v-for="(e, i) in recentLogs" :key="i" class="card-item log-row" @click="router.push('/logs')">
              <Icon
                :icon="e.level >= 3 ? 'tabler:alert-circle' : e.level === 2 ? 'tabler:alert-triangle' : e.level === 1 ? 'tabler:info-circle' : 'tabler:terminal'"
                class="w-3 h-3 shrink-0 mt-0.5"
                :class="e.level >= 3 ? 'text-danger-500' : e.level === 2 ? 'text-warn-500' : e.level === 1 ? 'text-info-500' : 'text-[var(--p-text-muted-color)]'"
              />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] truncate text-[var(--p-text-color)]">{{ e.message }}</div>
                <div class="text-[9px] text-[var(--p-text-muted-color)] truncate">{{ e.logger_name || '?' }}<span v-if="e.timestamp"> · {{ timeAgo(e.timestamp) }}</span></div>
              </div>
            </div>
          </template>
        </div>

        <!-- Changesets -->
        <div class="card">
          <div class="card-head accent-info">
            <Icon icon="tabler:git-pull-request" class="w-3.5 h-3.5 text-info-500" />
            <span class="card-title">Changesets</span>
            <span class="card-cnt">{{ openChangesets }} open · {{ reviewChangesets }} review</span>
            <span class="flex-1"></span>
            <button class="card-link" @click="router.push('/changes')">all</button>
          </div>
          <div class="card-list">
            <div v-if="!changesets.length" class="card-empty">No changesets</div>
            <div v-for="c in changesets.slice(0, 10)" :key="c.changeset_id" class="card-item" @click="router.push('/changes/' + c.changeset_id)">
              <Icon :icon="stateIcons[c.state] || 'tabler:circle-dot'" class="w-3 h-3 shrink-0" :style="{ color: stateColors[c.state] || 'var(--p-text-muted-color)' }" />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] truncate text-[var(--p-text-color)]">{{ c.title }}</div>
                <div class="text-[9px] text-[var(--p-text-muted-color)]">{{ c.kind }} · {{ c.state }}</div>
              </div>
              <span class="text-[9px] text-[var(--p-text-muted-color)]">{{ timeAgo(c.updated_at) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Top namespaces -->
      <div class="card">
        <div class="card-head accent-accent">
          <Icon icon="tabler:package" class="w-3.5 h-3.5 text-accent-500" />
          <span class="card-title">Top namespaces</span>
          <span class="card-cnt">{{ namespaces.length }}</span>
          <span class="flex-1"></span>
          <button class="card-link" @click="goStructure()">browse</button>
        </div>
        <div class="ns-cloud-wrap">
          <div class="ns-cloud">
            <button v-for="ns in topNamespaces" :key="ns.name" class="ns-chip" @click="goStructure(ns.name)">
              {{ ns.name }} <Badge severity="secondary" :value="ns.count" />
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Welcome banner */
.welcome {
  position: relative;
  border: 1px solid color-mix(in srgb, var(--p-primary-color) 25%, var(--p-content-border-color));
  border-radius: 10px;
  background:
    linear-gradient(135deg,
      color-mix(in srgb, var(--p-primary-color) 8%, transparent) 0%,
      color-mix(in srgb, var(--p-accent-500) 6%, transparent) 100%);
  overflow: hidden;
}
.welcome-glow {
  position: absolute;
  inset: -40% -10% auto auto;
  width: 360px; height: 360px;
  background: radial-gradient(circle, color-mix(in srgb, var(--p-primary-color) 22%, transparent) 0%, transparent 60%);
  pointer-events: none;
}
.welcome-body {
  position: relative;
  display: flex; align-items: center; gap: 16px;
  padding: 14px 40px 14px 18px;
}
.welcome--collapsed .welcome-body {
  padding: 8px 40px 8px 18px;
}
.welcome-text {
  flex: 1; min-width: 0;
}
.welcome-title {
  display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 10px;
  font-size: 16px; font-weight: 600;
  color: var(--p-text-color);
}
.welcome-greet {
  color: var(--p-text-muted-color);
  font-weight: 500;
}
.welcome-brand {
  font-weight: 600;
}
.welcome-brand-accent {
  color: var(--p-primary-color);
  font-weight: 700;
}
.welcome--collapsed .welcome-title { font-size: 13px; }
.welcome-sub {
  margin-top: 4px;
  font-size: 11px;
  line-height: 1.55;
  color: var(--p-text-muted-color);
}
.welcome-actions {
  display: flex; flex-wrap: wrap; gap: 6px;
  flex-shrink: 0;
}
.welcome-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 5px 10px;
  font-size: 11px; font-weight: 500;
  background: color-mix(in srgb, var(--p-content-background) 80%, transparent);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  cursor: pointer;
  transition: background 0.12s, border-color 0.12s;
}
.welcome-btn:hover {
  background: var(--p-surface-100);
  border-color: color-mix(in srgb, var(--p-primary-color) 35%, var(--p-content-border-color));
}
.welcome-btn--primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
  font-weight: 600;
}
.welcome-btn--primary:hover {
  background: var(--p-primary-color);
  opacity: 0.92;
}
.welcome-collapse {
  position: absolute;
  top: 6px; right: 8px;
  width: 22px; height: 22px;
  display: flex; align-items: center; justify-content: center;
  border: none;
  background: transparent;
  color: var(--p-text-muted-color);
  border-radius: 4px;
  cursor: pointer;
}
.welcome-collapse:hover {
  background: var(--p-surface-100);
  color: var(--p-text-color);
}

/* Hero cards */
.hero-card {
  display: flex; flex-direction: column; gap: 6px;
  padding: 12px 14px; border-radius: 8px;
  border: 1px solid var(--p-content-border-color);
  background: var(--p-surface-50);
  cursor: pointer; transition: transform 0.15s, border-color 0.15s, background 0.15s;
  position: relative; overflow: hidden;
  text-align: left;
}
.hero-card::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 3px;
}
.hero-card:hover { transform: translateY(-1px); border-color: currentColor; }
.hero-warn::before { background: var(--p-warn-500); }
.hero-info::before { background: var(--p-info-500); }
.hero-accent::before { background: var(--p-accent-500); }
.hero-success::before { background: var(--p-success-500); }
.hero-danger::before { background: var(--p-danger-500); }
.hero-warn { color: var(--p-warn-500); }
.hero-info { color: var(--p-info-500); }
.hero-accent { color: var(--p-accent-500); }
.hero-success { color: var(--p-success-500); }
.hero-danger { color: var(--p-danger-500); }

.hero-head { display: flex; align-items: center; gap: 6px; font-size: 10px; }
.hero-label { font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--p-text-muted-color); }
.hero-num { font-size: 28px; font-weight: 700; line-height: 1; color: var(--p-text-color); }
.hero-num-sub { font-size: 14px; font-weight: 500; color: var(--p-text-muted-color); }
.hero-sub { display: flex; align-items: center; gap: 6px; font-size: 10px; color: var(--p-text-muted-color); flex-wrap: wrap; }
.hero-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px; border-radius: 3px; font-size: 9px; font-weight: 600;
}

/* Health dot */
.health-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.health-good { background: var(--p-success-500); box-shadow: 0 0 6px color-mix(in srgb, var(--p-success-500) 60%, transparent); }
.health-warn { background: var(--p-warn-500); box-shadow: 0 0 6px color-mix(in srgb, var(--p-warn-500) 60%, transparent); }
.health-bad { background: var(--p-danger-500); box-shadow: 0 0 6px color-mix(in srgb, var(--p-danger-500) 60%, transparent); animation: pulse 2s infinite; }
.health-text-good { color: var(--p-success-500); }
.health-text-warn { color: var(--p-warn-500); }
.health-text-bad { color: var(--p-danger-500); }
@keyframes pulse { 50% { opacity: 0.5; } }

/* Alert strip */
.alerts {
  display: flex; flex-wrap: wrap; gap: 6px;
}
.alert {
  display: flex; align-items: center; gap: 6px;
  padding: 5px 10px; border-radius: 4px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  font-size: 11px; color: var(--p-text-color);
  cursor: pointer;
}
.alert:hover { background: var(--p-surface-100); }

/* Standard card */
.card { border-radius: 6px; border: 1px solid var(--p-content-border-color); overflow: hidden; }
.card-head {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 10px; background: var(--p-surface-100);
  border-bottom: 1px solid var(--p-content-border-color);
  position: relative;
}
.card-head::after {
  content: ''; position: absolute; bottom: -1px; left: 0; height: 2px; width: 30px;
}
.accent-warn::after    { background: var(--p-warn-500); }
.accent-info::after    { background: var(--p-info-500); }
.accent-accent::after  { background: var(--p-accent-500); }
.accent-success::after { background: var(--p-success-500); }
.accent-danger::after  { background: var(--p-danger-500); }

.card-title { font-size: 11px; font-weight: 600; color: var(--p-text-color); }
.card-cnt { font-size: 10px; color: var(--p-text-muted-color); }
.card-link {
  font-size: 10px; color: var(--p-primary-color); cursor: pointer;
  background: none; border: none; padding: 0;
}
.card-link:hover { text-decoration: underline; }
.card-list { max-height: 320px; overflow-y: auto; }
.card-section-head {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600;
  color: var(--p-text-muted-color);
  padding: 6px 10px 2px;
  background: var(--p-surface-50);
  border-top: 1px solid var(--p-content-border-color);
}
.card-item {
  display: flex; align-items: center; gap: 8px;
  padding: 5px 10px; cursor: pointer;
  border-bottom: 1px solid var(--p-content-border-color);
}
.card-item:last-child { border-bottom: none; }
.card-item:hover { background: var(--p-surface-100); }
.card-empty { padding: 16px 10px; font-size: 11px; color: var(--p-text-muted-color); text-align: center; }

.phase-row { gap: 6px; }
.phase-bar { height: 4px; border-radius: 2px; max-width: 80px; min-width: 8px; }

/* Registry typed kind tiles */
.kind-tile {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 2px;
  padding: 8px 6px; border-radius: 4px;
  background: var(--p-surface-50); border: 1px solid var(--p-content-border-color);
  cursor: pointer; transition: background 0.1s, border-color 0.1s;
}
.kind-tile:hover { background: var(--p-surface-100); border-color: var(--p-primary-color); }
.kind-num { font-size: 16px; font-weight: 700; color: var(--p-text-color); line-height: 1.1; }
.kind-lbl { font-size: 9px; color: var(--p-text-muted-color); text-transform: uppercase; letter-spacing: 0.05em; }

/* Host tile */
.host-tile {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px; padding: 8px 10px;
}
.host-id {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px; color: var(--p-text-color); font-weight: 500; margin-bottom: 6px;
}
.host-stats {
  display: flex; flex-wrap: wrap; gap: 8px;
  font-size: 10px; color: var(--p-text-muted-color);
}

/* Logger */
.log-bar { display: flex; flex-wrap: wrap; gap: 4px; padding: 6px 8px; }
.log-pill {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 1px 6px; border-radius: 8px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  font-size: 10px; line-height: 1.4;
}
.log-pill:hover { background: var(--p-surface-200); }
.log-pill--err { border-color: color-mix(in srgb, var(--p-danger-500) 50%, transparent); }
.log-pill--warn { border-color: color-mix(in srgb, var(--p-warn-500) 50%, transparent); }
.log-num { font-weight: 600; color: var(--p-text-color); font-variant-numeric: tabular-nums; }

/* Badge */
.badge {
  display: inline-flex; align-items: center; gap: 2px;
  padding: 1px 5px; border-radius: 3px; font-size: 9px; font-weight: 600;
}

/* Namespace cloud */
.ns-cloud-wrap { padding: 8px; }
.ns-cloud { display: flex; flex-wrap: wrap; gap: 4px; }
.ns-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 3px 8px; border-radius: 4px; font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); cursor: pointer;
  transition: background 0.1s, border-color 0.1s;
}
.ns-chip:hover { background: var(--p-surface-200); border-color: var(--p-primary-color); }
.ns-count { font-size: 9px; color: var(--p-text-muted-color); }
</style>
