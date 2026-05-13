<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import { kindColor, kindIcon } from '../api/registry'
import { timeAgo } from '../api/sessions'

const router = useRouter()
const route = useRoute()
const api = useApi()
const host = useHost()
const instance = useWippy()

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

interface NavItem { path: string; name: string; label: string; icon: string }

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

const pluginItems = ref<NavItem[]>([])

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
      } as NavItem & { group: string }))
  } catch { /* plugin discovery is opportunistic — empty nav on failure is acceptable */ }
}

const observeItems = computed<NavItem[]>(() => [
  ...observeItemsStatic,
  ...pluginItems.value.filter((p: any) => p.group === 'observe'),
])
const structureItems = computed<NavItem[]>(() => [
  ...structureItemsStatic,
  ...pluginItems.value.filter((p: any) => p.group === 'structure'),
])
const developItems = computed<NavItem[]>(() => [
  ...developItemsStatic,
  ...pluginItems.value.filter((p: any) => p.group === 'develop' || !(p as any).group),
])
const statusItems = computed<NavItem[]>(() => [
  ...statusItemsStatic,
  ...pluginItems.value.filter((p: any) => p.group === 'status'),
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

async function fetchMe() {
  try {
    const { data } = await api.get('/api/v1/user/me')
    if (data.success && data.user) {
      currentUser.value = { email: data.user.email, full_name: data.user.full_name }
    }
  } catch { /* user header is cosmetic — anonymous fallback is fine */ }
}

interface AgentInfo {
  id: string
  title: string
  icon: string
  comment: string
  model: string
  class: string[]
  public?: boolean
  start_token: string
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
}

interface SearchResult {
  id: string
  kind: string
  snippet?: string
  icon?: string
  color?: string
  route?: string
}

const showSearch = ref(false)
const searchQuery = ref('')
const searchResults = ref<SearchResult[]>([])
const searchLoading = ref(false)
let searchDebounce: number | null = null

const searchHints = [
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
  // Allow prefix-only queries like "session:" to show recent items

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
      <button class="flex items-center gap-1.5 shrink-0 cursor-pointer" style="color: var(--p-primary-color); background: none; border: none;" @click="navigate('/')">
        <Icon icon="tabler:shield-code" class="w-4 h-4" />
        <span class="text-xs font-bold tracking-wider font-mono">KEEPER</span>
      </button>

      <nav class="flex items-center gap-0.5 flex-1">
        <button
          v-for="item in navItems"
          :key="item.name"
          class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
          :class="{ active: currentName === item.name }"
          @click="navigate(item.path)"
        >
          <Icon :icon="item.icon" class="w-3.5 h-3.5" />
          {{ item.label }}
        </button>

        <!-- Observe dropdown -->
        <div class="relative observe-dropdown-wrap">
          <button
            class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
            :class="{ active: isObserveActive }"
            @click="observeOpen = !observeOpen"
          >
            <Icon icon="tabler:eye" class="w-3.5 h-3.5" />
            Observe
            <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.5" />
          </button>
          <div v-if="observeOpen" class="status-dropdown">
            <button
              v-for="item in observeItems" :key="item.name"
              class="status-item"
              :class="{ 'status-item--active': currentName === item.name }"
              @click="navigate(item.path); observeOpen = false"
            >
              <Icon :icon="item.icon" class="w-3.5 h-3.5" />
              {{ item.label }}
              <span v-if="item.name.startsWith('plugin:')" class="plugin-tag" title="Provided by a registered plugin">plugin</span>
            </button>
          </div>
        </div>

        <!-- Structure dropdown -->
        <div class="relative structure-dropdown-wrap">
          <button
            class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
            :class="{ active: isStructureActive }"
            @click="structureOpen = !structureOpen"
          >
            <Icon icon="tabler:binary-tree" class="w-3.5 h-3.5" />
            Structure
            <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.5" />
          </button>
          <div v-if="structureOpen" class="status-dropdown">
            <button
              v-for="item in structureItems" :key="item.name"
              class="status-item"
              :class="{ 'status-item--active': currentName === item.name }"
              @click="navigate(item.path); structureOpen = false"
            >
              <Icon :icon="item.icon" class="w-3.5 h-3.5" />
              {{ item.label }}
              <span v-if="item.name.startsWith('plugin:')" class="plugin-tag" title="Provided by a registered plugin">plugin</span>
            </button>
          </div>
        </div>

        <!-- Develop dropdown -->
        <div class="relative develop-dropdown-wrap">
          <button
            class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
            :class="{ active: isDevelopActive }"
            @click="developOpen = !developOpen"
          >
            <Icon icon="tabler:code" class="w-3.5 h-3.5" />
            Develop
            <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.5" />
          </button>
          <div v-if="developOpen" class="status-dropdown">
            <button
              v-for="item in developItems" :key="item.name"
              class="status-item"
              :class="{ 'status-item--active': currentName === item.name }"
              @click="navigate(item.path); developOpen = false"
            >
              <Icon :icon="item.icon" class="w-3.5 h-3.5" />
              {{ item.label }}
              <span v-if="item.name.startsWith('plugin:')" class="plugin-tag" title="Provided by a registered plugin">plugin</span>
            </button>
          </div>
        </div>

        <!-- Status dropdown — only render when there's items in it -->
        <div v-if="statusItems.length" class="relative status-dropdown-wrap">
          <button
            class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
            :class="{ active: isStatusActive }"
            @click="statusOpen = !statusOpen"
          >
            <Icon icon="tabler:heart-rate-monitor" class="w-3.5 h-3.5" />
            Status
            <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.5" />
          </button>
          <div v-if="statusOpen" class="status-dropdown">
            <button
              v-for="item in statusItems" :key="item.name"
              class="status-item"
              :class="{ 'status-item--active': currentName === item.name }"
              @click="navigate(item.path); statusOpen = false"
            >
              <Icon :icon="item.icon" class="w-3.5 h-3.5" />
              {{ item.label }}
              <span v-if="item.name.startsWith('plugin:')" class="plugin-tag" title="Provided by a registered plugin">plugin</span>
            </button>
          </div>
        </div>

        <div class="relative settings-dropdown-wrap">
          <button
            class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
            :class="{ active: isSettingsActive }"
            @click="settingsOpen = !settingsOpen"
          >
            <Icon icon="tabler:settings" class="w-3.5 h-3.5" />
            Settings
            <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.5" />
          </button>
          <div v-if="settingsOpen" class="status-dropdown">
            <button
              v-for="item in settingsItems" :key="item.name"
              class="status-item"
              :class="{ 'status-item--active': currentName === item.name }"
              @click="navigate(item.path); settingsOpen = false"
            >
              <Icon :icon="item.icon" class="w-3.5 h-3.5" />
              {{ item.label }}
            </button>
          </div>
        </div>
      </nav>

      <div class="flex items-center gap-1.5 shrink-0">
        <template v-if="publicAgents.length === 1">
          <button class="ask-btn" @click="startAgent(publicAgents[0].start_token)">
            <Icon :icon="publicAgents[0].icon || 'tabler:message-bolt'" class="w-3.5 h-3.5" />
            <span class="truncate" style="max-width: 80px">{{ publicAgents[0].title || 'Ask' }}</span>
          </button>
        </template>
        <div v-else-if="publicAgents.length > 1" class="relative agent-dropdown-wrap">
          <button class="ask-btn" @click="agentDropOpen = !agentDropOpen">
            <Icon icon="tabler:message-bolt" class="w-3.5 h-3.5" />
            Ask
            <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.6" />
          </button>
          <div v-if="agentDropOpen" class="agent-dropdown">
            <button v-for="a in publicAgents" :key="a.id" class="agent-item" @click="startAgent(a.start_token); agentDropOpen = false">
              <Icon :icon="a.icon || 'tabler:robot'" class="agent-item-icon" />
              <span class="agent-item-copy">
                <span class="agent-item-title">{{ a.title || a.id }}</span>
                <span v-if="a.comment" class="agent-item-comment">{{ a.comment }}</span>
              </span>
            </button>
          </div>
        </div>
        <div v-if="currentUser" class="flex items-center gap-1.5 text-xs pl-2" style="color: var(--p-text-muted-color); border-left: 1px solid var(--p-content-border-color)">
          <span class="truncate max-w-[100px]">{{ currentUser.full_name || currentUser.email }}</span>
          <button
            class="w-6 h-6 inline-flex items-center justify-center rounded-full border-none bg-transparent cursor-pointer transition-colors hover:bg-surface-100 dark:hover:bg-surface-700"
            style="color: var(--p-text-muted-color)"
            title="Logout"
            @click="logout"
          >
            <Icon icon="tabler:logout" class="w-3 h-3" />
          </button>
        </div>
      </div>
    </header>

    <main class="flex-1 overflow-y-auto" style="background: color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)">
      <router-view />
    </main>

    <!-- Global Search -->
    <Teleport to="body">
      <div v-if="showSearch" class="search-overlay" @click.self="showSearch = false">
        <div class="search-modal">
          <div class="search-header">
            <Icon icon="tabler:search" class="w-4 h-4 shrink-0" style="color: var(--p-text-muted-color)" />
            <input v-model="searchQuery" @input="onSearchInput" @keydown.escape="showSearch = false"
              @keydown.enter="searchResults.length > 0 && selectResult(searchResults[0])"
              class="global-search-input" placeholder="Search entries, functions, configs..." autofocus />
            <Icon v-if="searchLoading" icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin" style="color: var(--p-primary-color)" />
            <kbd class="search-kbd">Esc</kbd>
          </div>
          <div v-if="searchResults.length > 0" class="search-results">
            <div v-for="r in searchResults" :key="r.id" class="search-item" @click="selectResult(r)">
              <Icon :icon="r.icon || kindIcon(r.kind)" class="w-3 h-3 shrink-0" :style="{ color: r.color || kindColor(r.kind) }" />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] font-mono truncate" style="color: var(--p-text-color)">{{ r.id }}</div>
                <div v-if="r.snippet" class="text-[9px] truncate" style="color: var(--p-text-muted-color)">{{ r.snippet }}</div>
              </div>
              <span class="text-[8px] px-1 rounded" :style="{ color: r.color || kindColor(r.kind), background: `color-mix(in srgb, ${r.color || kindColor(r.kind)} 12%, transparent)` }">{{ r.kind }}</span>
            </div>
          </div>
          <div v-else-if="searchQuery && !searchLoading" class="search-empty">No results</div>
          <div v-else-if="!searchQuery" class="search-hints">
            <div v-for="h in searchHints" :key="h.prefix" class="search-hint" @click="applyHint(h.prefix)">
              <Icon :icon="h.icon" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
              <span class="text-[10px] font-mono" style="color: var(--p-primary-color)">{{ h.prefix || '*' }}</span>
              <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ h.desc }}</span>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.keeper-nav-btn {
  color: var(--p-text-color);
  font-weight: 500;
  background: transparent;
  border: 1px solid transparent;
}
.keeper-nav-btn:hover {
  background: var(--p-surface-100);
}
.keeper-nav-btn.active {
  background: var(--p-surface-100);
  color: var(--p-primary-color);
}

.ask-btn {
  height: 28px;
  min-width: 0;
  max-width: 160px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 0 10px;
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  font-size: 12px;
  line-height: 1;
  cursor: pointer;
  white-space: nowrap;
}
.ask-btn:hover {
  background: var(--p-surface-200);
  color: var(--p-primary-color);
}

/* shared dropdown panel + items used by Observe / Structure / Develop / Status */
.status-dropdown,
.agent-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  min-width: 200px;
  max-width: 320px;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  padding: 4px;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.agent-dropdown {
  left: auto;
  right: 0;
  width: min(360px, calc(100vw - 24px));
  max-height: min(420px, calc(100vh - 80px));
  overflow-y: auto;
}
.status-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 6px 10px;
  font-size: 12px;
  text-align: left;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-color);
  border: none;
  cursor: pointer;
  white-space: nowrap;
}
.status-item:hover {
  background: var(--p-surface-100);
}
.status-item--active {
  background: var(--p-surface-100);
  color: var(--p-primary-color);
  font-weight: 500;
}
.plugin-tag {
  margin-left: auto;
  padding: 0 5px;
  font-size: 8px;
  font-weight: 500;
  letter-spacing: 0.02em;
  border-radius: 2px;
  color: var(--p-text-muted-color);
  opacity: 0.55;
}
.status-item .iconify {
  flex-shrink: 0;
  opacity: 0.75;
}
.agent-item {
  display: grid;
  grid-template-columns: 18px minmax(0, 1fr);
  align-items: start;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  text-align: left;
  border: none;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-color);
  cursor: pointer;
}
.agent-item:hover {
  background: var(--p-surface-100);
}
.agent-item-icon {
  width: 15px;
  height: 15px;
  margin-top: 1px;
  color: var(--p-text-muted-color);
}
.agent-item-copy {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.agent-item-title {
  font-size: 12px;
  font-weight: 600;
  line-height: 1.2;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.agent-item-comment {
  font-size: 10px;
  line-height: 1.25;
  color: var(--p-text-muted-color);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* status badge inside the Status nav button (e.g. "99+") */
.status-badge {
  background: var(--p-danger-500);
  color: var(--p-primary-contrast-color);
  font-size: 9px;
  font-weight: 600;
  padding: 1px 5px;
  border-radius: 8px;
  line-height: 1.2;
  margin-left: 2px;
}
</style>
