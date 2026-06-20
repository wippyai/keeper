<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import { useEvents } from '../composables/useEvents'
import { kindColor, kindIcon } from '../api/registry'
import { timeAgo } from '../api/sessions'
import AppNavDropdown, { type NavItem } from './AppNavDropdown.vue'
import AppAgentLauncher, { type AgentInfo } from './AppAgentLauncher.vue'
import AppUserChip from './AppUserChip.vue'
import AppGlobalSearch, { type SearchResult, type SearchHint } from './AppGlobalSearch.vue'

const router = useRouter()
const route = useRoute()
const api = useApi()
const host = useHost()
const instance = useWippy()
const events = useEvents()

const errorCount = ref(0)
const warnCount = ref(0)

let unsubNavigate: (() => void) | null = null
let unsubLogs: (() => void) | null = null

// Log counters update via relay subscription (keeper.logs) — no polling needed
async function fetchLogCounters() {
  try {
    const { data } = await api.get('/api/v1/keeper/logger/stats')
    if (data.success && data.stats?.counters) {
      errorCount.value = data.stats.counters.error || 0
      warnCount.value = data.stats.counters.warn || 0
    }
  } catch { /* counter badge is best-effort; leave the last-known value */ }
}

const navItems: NavItem[] = [
  { path: '/', name: 'dashboard', label: 'Home', icon: 'tabler:layout-dashboard' },
]

const settingsItems: NavItem[] = [
  { path: '/settings/environment', name: 'settings-environment', label: 'Environment', icon: 'tabler:variable' },
  { path: '/settings/registry', name: 'settings-registry', label: 'Registry', icon: 'tabler:database' },
  { path: '/settings/hub', name: 'settings-hub', label: 'Wippy Hub', icon: 'tabler:cloud' },
  { path: '/mcp', name: 'mcp', label: 'MCP', icon: 'tabler:plug-connected' },
]

const observeItemsStatic: NavItem[] = [
  { path: '/sessions', name: 'sessions', label: 'Sessions', icon: 'tabler:list' },
  { path: '/dataflows', name: 'workflow', label: 'Dataflows', icon: 'tabler:git-merge' },
  { path: '/system', name: 'system', label: 'System', icon: 'tabler:activity' },
  { path: '/logs', name: 'logs', label: 'Logs', icon: 'tabler:file-text' },
  { path: '/activity', name: 'activity', label: 'Activity', icon: 'tabler:broadcast' },
]

const statusItemsStatic: NavItem[] = []

const structureItemsStatic: NavItem[] = [
  { path: '/structure', name: 'structure', label: 'Registry', icon: 'tabler:binary-tree' },
  { path: '/agents', name: 'agents', label: 'Agents', icon: 'tabler:robot' },
  { path: '/models', name: 'models', label: 'Models', icon: 'tabler:brain' },
  { path: '/tools', name: 'tools', label: 'Tools', icon: 'tabler:tool' },
  { path: '/traits', name: 'traits', label: 'Traits', icon: 'tabler:sparkles' },
  { path: '/endpoints', name: 'endpoints', label: 'Endpoints', icon: 'tabler:api' },
  { path: '/policies', name: 'policies', label: 'Policies', icon: 'tabler:shield-check' },
]

const developItemsStatic: NavItem[] = [
  { path: '/tasks', name: 'tasks', label: 'Pipeline', icon: 'tabler:git-merge' },
  { path: '/changes', name: 'changes', label: 'Changes', icon: 'tabler:git-branch' },
  { path: '/components', name: 'components', label: 'Components', icon: 'tabler:puzzle' },
  { path: '/knowledge', name: 'knowledge', label: 'Knowledge', icon: 'tabler:brain' },
  { path: '/tests', name: 'tests', label: 'Tests', icon: 'tabler:test-pipe' },
]

interface PageInfo { id: string; name: string; title: string; icon: string; order: number; group: string; announced: boolean }

const pluginItems = ref<Array<NavItem & { group: string }>>([])

async function discoverPlugins() {
  try {
    const { data } = await api.get<{ success: boolean; pages: PageInfo[] }>('/api/public/pages/list')
    if (!data?.success || !Array.isArray(data.pages)) return
    pluginItems.value = data.pages
      .filter(p => p.announced && p.id.startsWith('keeper.') && p.id !== 'keeper:main')
      .sort((a, b) => (a.order || 9999) - (b.order || 9999) || a.title.localeCompare(b.title))
      .map(p => ({
        path: `/plugin/${p.id}`,
        name: `plugin:${p.id}`,
        label: p.title || p.name,
        icon: p.icon || 'tabler:puzzle',
        group: p.group || 'develop',
      }))
  } catch { /* plugin discovery is opportunistic — empty nav on failure is acceptable */ }
}

const observeItems = computed<NavItem[]>(() => [
  ...observeItemsStatic,
  ...pluginItems.value.filter(p => p.group === 'observe'),
])
const structureItems = computed<NavItem[]>(() => [
  ...structureItemsStatic,
  ...pluginItems.value.filter(p => p.group === 'structure'),
])
const developItems = computed<NavItem[]>(() => [
  ...developItemsStatic,
  ...pluginItems.value.filter(p => p.group === 'develop' || !p.group),
])
const statusItems = computed<NavItem[]>(() => [
  ...statusItemsStatic,
  ...pluginItems.value.filter(p => p.group === 'status'),
])

const statusOpen = ref(false)
const structureOpen = ref(false)
const developOpen = ref(false)
const observeOpen = ref(false)
const settingsOpen = ref(false)
const agentDropOpen = ref(false)
const statusNames = computed(() => new Set(statusItems.value.map(i => i.name)))
const structureNames = computed(() => new Set(structureItems.value.map(i => i.name)))
const developNames = computed(() => new Set(developItems.value.map(i => i.name)))
const observeNames = computed(() => new Set(observeItems.value.map(i => i.name)))
const settingsNames = computed(() => new Set(settingsItems.map(i => i.name)))

const currentName = computed(() => route.name)
const isStatusActive = computed(() => statusNames.value.has(String(currentName.value)))
const isStructureActive = computed(() => structureNames.value.has(String(currentName.value)))
const isDevelopActive = computed(() => developNames.value.has(String(currentName.value)))
const isObserveActive = computed(() => observeNames.value.has(String(currentName.value)) || currentName.value === 'session-detail' || currentName.value === 'dataflow-detail')
const isSettingsActive = computed(() => settingsNames.value.has(String(currentName.value)) || currentName.value === 'settings')
const currentUser = ref<{ email: string; full_name: string } | null>(null)

function navigate(path: string) {
  router.push(path)
}

function closeAllDropdowns() {
  statusOpen.value = false
  structureOpen.value = false
  developOpen.value = false
  observeOpen.value = false
  settingsOpen.value = false
  agentDropOpen.value = false
}

function navigateAndClose(path: string) {
  navigate(path)
  closeAllDropdowns()
}

async function fetchMe() {
  try {
    const { data } = await api.get('/api/v1/user/me')
    if (data.success && data.user) {
      currentUser.value = { email: data.user.email, full_name: data.user.full_name }
    }
  } catch { /* user header is cosmetic — anonymous fallback is fine */ }
}

const publicAgents = ref<AgentInfo[]>([])

async function fetchAgents() {
  try {
    const { data } = await api.get('/api/v1/keeper/agents/list', { params: { public_only: true } })
    publicAgents.value = data.agents || []
  } catch { /* public-agents quick-launch is optional — empty menu on failure */ }
}

function startAgent(token: string) {
  host.startChat(token, { sidebar: true })
  agentDropOpen.value = false
}

const showSearch = ref(false)
const searchQuery = ref('')
const searchResults = ref<SearchResult[]>([])
const searchLoading = ref(false)
let searchDebounce: number | null = null

const searchHints: SearchHint[] = [
  { prefix: 'session:', desc: 'Search sessions by title or ID', icon: 'tabler:list' },
  { prefix: 'dataflow:', desc: 'Search dataflows', icon: 'tabler:git-merge' },
  { prefix: 'agent:', desc: 'Search agents', icon: 'tabler:robot' },
  { prefix: 'model:', desc: 'Search LLM models', icon: 'tabler:brain' },
  { prefix: 'tool:', desc: 'Search tools', icon: 'tabler:tool' },
  { prefix: 'endpoint:', desc: 'Search HTTP endpoints', icon: 'tabler:api' },
  { prefix: '', desc: 'Search all registry entries', icon: 'tabler:search' },
]

async function doSearch() {
  const raw = searchQuery.value.trim()
  if (!raw) { searchResults.value = []; return }

  searchLoading.value = true
  try {
    const colonIdx = raw.indexOf(':')
    const prefix = colonIdx > 0 ? raw.slice(0, colonIdx).toLowerCase() : ''
    const query = colonIdx > 0 ? raw.slice(colonIdx + 1).trim() : raw

    if (prefix === 'session') {
      const { data } = await api.get('/api/v1/sessions', { params: { limit: 20 } })
      const sessions = (data.sessions || []).filter((s: any) =>
        !query || s.title?.toLowerCase().includes(query.toLowerCase()) || s.session_id?.includes(query) || s.current_agent?.toLowerCase().includes(query.toLowerCase())
      )
      searchResults.value = sessions.slice(0, 15).map((s: any) => ({
        id: s.title || s.session_id?.slice(0, 12) + '...',
        kind: s.current_agent || 'session',
        snippet: [s.current_model, s.status, timeAgo(s.last_message_date || s.start_date)].filter(Boolean).join(' · '),
        icon: 'tabler:message',
        color: 'var(--p-info-500)',
        route: '/session/' + s.session_id,
      }))
    } else if (prefix === 'dataflow') {
      const { data } = await api.get('/api/v1/dataflows', { params: { limit: 20 } })
      const flows = (data.dataflows || []).filter((d: any) =>
        !query || d.metadata?.title?.toLowerCase().includes(query.toLowerCase()) || d.dataflow_id?.includes(query)
      )
      searchResults.value = flows.slice(0, 15).map((d: any) => ({
        id: d.metadata?.title || d.dataflow_id?.slice(0, 12) + '...',
        kind: d.status || 'dataflow',
        snippet: [d.type, timeAgo(d.created_at)].filter(Boolean).join(' · '),
        icon: 'tabler:git-merge',
        color: d.status === 'running' ? 'var(--p-success-500)' : d.status === 'failed' ? 'var(--p-danger-500)' : 'var(--p-info-500)',
        route: '/dataflow/' + d.dataflow_id,
      }))
    } else if (prefix === 'agent') {
      const { data } = await api.get('/api/v1/keeper/registry/entries', { params: { 'meta.type': 'agent.gen1', limit: 100 } })
      const agents = (data.entries || []).filter((e: any) =>
        !query || e.id.toLowerCase().includes(query.toLowerCase()) || e.meta?.title?.toLowerCase().includes(query.toLowerCase())
      )
      searchResults.value = agents.slice(0, 15).map((e: any) => ({
        id: e.id, kind: e.kind, snippet: e.meta?.title || '',
        icon: 'tabler:robot', color: 'var(--p-warn-500)',
        route: '/structure?entry=' + e.id,
      }))
    } else if (prefix === 'model') {
      const { data } = await api.get('/api/v1/keeper/registry/entries', { params: { 'meta.type': 'llm.model', limit: 100 } })
      const models = (data.entries || []).filter((e: any) =>
        !query || e.id.toLowerCase().includes(query.toLowerCase()) || e.meta?.title?.toLowerCase().includes(query.toLowerCase())
      )
      searchResults.value = models.slice(0, 15).map((e: any) => ({
        id: e.id, kind: e.kind, snippet: e.meta?.title || '',
        icon: 'tabler:brain', color: 'var(--p-accent-500)',
        route: '/structure?entry=' + e.id,
      }))
    } else if (prefix === 'tool') {
      const { data } = await api.get('/api/v1/keeper/registry/entries', { params: { 'meta.type': 'tool', limit: 100 } })
      const tools = (data.entries || []).filter((e: any) =>
        !query || e.id.toLowerCase().includes(query.toLowerCase()) || e.meta?.title?.toLowerCase().includes(query.toLowerCase())
      )
      searchResults.value = tools.slice(0, 15).map((e: any) => ({
        id: e.id, kind: e.kind, snippet: e.meta?.comment || e.meta?.llm_alias || '',
        icon: 'tabler:tool', color: 'var(--p-info-500)',
        route: '/structure?entry=' + e.id,
      }))
    } else if (prefix === 'endpoint') {
      const { data } = await api.get('/api/v1/keeper/registry/entries', { params: { kind: 'http.endpoint', limit: 200 } })
      const eps = (data.entries || []).filter((e: any) =>
        !query || e.id.toLowerCase().includes(query.toLowerCase())
      )
      searchResults.value = eps.slice(0, 15).map((e: any) => ({
        id: e.id, kind: e.kind, snippet: e.meta?.comment || '',
        icon: 'tabler:api', color: 'var(--p-info-500)',
        route: '/structure?entry=' + e.id,
      }))
    } else {
      const { data } = await api.get('/api/v1/keeper/state/search', { params: { q: raw, limit: 30 } })
      searchResults.value = (data.results || []).map((r: any) => ({
        id: r.id, kind: r.kind, snippet: r.snippet,
        icon: kindIcon(r.kind), color: kindColor(r.kind),
        route: '/structure?entry=' + r.id,
      }))
    }
  } catch { searchResults.value = [] }
  finally { searchLoading.value = false }
}

function onSearchInput() {
  if (searchDebounce) clearTimeout(searchDebounce)
  searchDebounce = window.setTimeout(doSearch, 300)
}

function applyHint(prefix: string) {
  searchQuery.value = prefix
  doSearch()
  window.setTimeout(() => {
    const input = document.querySelector('.global-search-input') as HTMLInputElement
    if (input) { input.focus(); input.setSelectionRange(prefix.length, prefix.length) }
  }, 10)
}

function selectResult(r: SearchResult) {
  showSearch.value = false
  searchQuery.value = ''
  searchResults.value = []
  if (r.route) {
    if (r.route.includes('?')) {
      const [path, qs] = r.route.split('?')
      const params = Object.fromEntries(new URLSearchParams(qs))
      router.push({ path, query: params })
    } else {
      router.push(r.route)
    }
  }
}

function onGlobalKeydown(e: KeyboardEvent) {
  if ((e.ctrlKey || e.metaKey) && e.shiftKey && (e.key === 'F' || e.key === 'f')) {
    e.preventDefault()
    showSearch.value = true
    setTimeout(() => (document.querySelector('.global-search-input') as HTMLInputElement)?.focus(), 50)
  }
  if (e.key === 'Escape' && showSearch.value) {
    showSearch.value = false
  }
}

function logout() {
  host.logout()
}

watch(() => route.fullPath, () => {
  try {
    const ctx: Record<string, unknown> = {
      page: route.name,
      path: route.fullPath,
    }
    if (route.query.entry) ctx.selected_entry = route.query.entry
    if (route.query.ns) ctx.namespace = route.query.ns
    host.setContext(ctx)
  } catch { /* host.setContext is a best-effort hint to the parent shell */ }
})

function onClickOutside(e: MouseEvent) {
  const t = e.target as HTMLElement
  if (!t.closest('.status-dropdown-wrap')) statusOpen.value = false
  if (!t.closest('.structure-dropdown-wrap')) structureOpen.value = false
  if (!t.closest('.develop-dropdown-wrap')) developOpen.value = false
  if (!t.closest('.observe-dropdown-wrap')) observeOpen.value = false
  if (!t.closest('.settings-dropdown-wrap')) settingsOpen.value = false
  if (!t.closest('.agent-dropdown-wrap')) agentDropOpen.value = false
}

onMounted(() => {
  unsubNavigate = instance.on('action:navigate', (data: any) => {
    const path = data?.data?.path || data?.path
    if (path) router.push(path)
  })
  unsubLogs = instance.on('keeper.logs', (evt: any) => {
    const counters = evt?.data?.counters || evt?.counters
    if (counters) {
      errorCount.value = counters.error || 0
      warnCount.value = counters.warn || 0
    }
  })
  fetchMe()
  fetchLogCounters()
  fetchAgents()
  discoverPlugins()
  // Join the admin event bus on visit (no-op for non-admins, server-gated; skipped if muted).
  events.ensureSubscribed(api)
  document.addEventListener('click', onClickOutside)
  document.addEventListener('keydown', onGlobalKeydown)
})

onUnmounted(() => {
  unsubNavigate?.()
  unsubLogs?.()
  document.removeEventListener('click', onClickOutside)
  document.removeEventListener('keydown', onGlobalKeydown)
})
</script>

<template>
  <div class="h-full flex flex-col">
    <header class="shrink-0 h-10 flex items-center px-3 gap-3" style="background: var(--p-content-background); border-bottom: 1px solid var(--p-content-border-color)">
      <Button variant="text" class="shrink-0 !gap-1.5" @click="navigate('/')">
        <Icon icon="tabler:shield-code" class="w-4 h-4" />
        <span class="text-xs font-bold tracking-wider font-mono">KEEPER</span>
      </Button>

      <nav class="flex items-center gap-0.5 flex-1">
        <Button
          v-for="item in navItems"
          :key="item.name"
          variant="text"
          class="k-btn-nav relative !gap-1.5"
          :class="{ 'k-btn-active': currentName === item.name }"
          @click="navigate(item.path)"
        >
          <Icon :icon="item.icon" class="w-3.5 h-3.5" />
          {{ item.label }}
        </Button>

        <AppNavDropdown
          icon="tabler:eye" label="Observe" wrap-class="observe-dropdown-wrap"
          :items="observeItems" :open="observeOpen" :active="isObserveActive"
          :current-name="currentName as string | null | undefined"
          @toggle="observeOpen = !observeOpen"
          @navigate="navigateAndClose"
        />

        <AppNavDropdown
          icon="tabler:binary-tree" label="Structure" wrap-class="structure-dropdown-wrap"
          :items="structureItems" :open="structureOpen" :active="isStructureActive"
          :current-name="currentName as string | null | undefined"
          @toggle="structureOpen = !structureOpen"
          @navigate="navigateAndClose"
        />

        <AppNavDropdown
          icon="tabler:code" label="Develop" wrap-class="develop-dropdown-wrap"
          :items="developItems" :open="developOpen" :active="isDevelopActive"
          :current-name="currentName as string | null | undefined"
          @toggle="developOpen = !developOpen"
          @navigate="navigateAndClose"
        />

        <AppNavDropdown v-if="statusItems.length"
          icon="tabler:heart-rate-monitor" label="Status" wrap-class="status-dropdown-wrap"
          :items="statusItems" :open="statusOpen" :active="isStatusActive"
          :current-name="currentName as string | null | undefined"
          @toggle="statusOpen = !statusOpen"
          @navigate="navigateAndClose"
        />

        <AppNavDropdown
          icon="tabler:settings" label="Settings" wrap-class="settings-dropdown-wrap"
          :items="settingsItems" :open="settingsOpen" :active="isSettingsActive"
          :current-name="currentName as string | null | undefined"
          @toggle="settingsOpen = !settingsOpen"
          @navigate="navigateAndClose"
        />
      </nav>

      <div class="flex items-center gap-1.5 shrink-0">
        <AppAgentLauncher
          :agents="publicAgents"
          :open="agentDropOpen"
          @toggle="agentDropOpen = !agentDropOpen"
          @start="startAgent"
        />
        <AppUserChip :user="currentUser" @logout="logout" />
      </div>
    </header>

    <main class="flex-1 overflow-y-auto" style="background: color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)">
      <router-view />
    </main>

    <AppGlobalSearch
      :open="showSearch"
      :query="searchQuery"
      :results="searchResults"
      :loading="searchLoading"
      :hints="searchHints"
      @update:query="searchQuery = $event"
      @close="showSearch = false"
      @search-input="onSearchInput"
      @select="selectResult"
      @apply-hint="applyHint"
    />
  </div>
</template>
