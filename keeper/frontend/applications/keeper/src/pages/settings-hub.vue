<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import {
  listHubDependencies, installHubDependency, uninstallHubDependency,
  listHubMigrations, runHubMigrations,
  browseHubModules, listHubVersions, getHubReadme, planHubInstall,
  type HubDependency, type HubMigration, type HubModule, type HubPlanRequirement, type HubVersion,
  type HubInstallPlanResponse,
} from '../api/hub'
import PageHeader from '../components/shared/PageHeader.vue'
import RequirementValueInput from '../components/hub/RequirementValueInput.vue'

const api = useApi()
const router = useRouter()

const HUB_URL = 'https://hub.wippy.ai/'

function navigateToModule(m: HubModule) {
  const ref = m.full_name || `${m.org}/${m.name}`
  const [org, name] = ref.split('/')
  if (!org || !name) return
  router.push(`/settings/hub/${encodeURIComponent(org)}/${encodeURIComponent(name)}`)
}

const tab = ref<'discover' | 'installed'>('discover')
const installedSearch = ref('')
const expandedDep = ref<string | null>(null)

// Installed
const loading = ref(true)
const error = ref<string | null>(null)
const successMsg = ref<string | null>(null)
const deps = ref<HubDependency[]>([])
const migrations = ref<HubMigration[]>([])

// Browse
const browseQuery = ref('')
const browseLoading = ref(false)
const browseError = ref<string | null>(null)
const browseItems = ref<HubModule[]>([])
const browseTotal = ref(0)
const browsePage = ref(1)
const browsePageSize = 30
const sortBy = ref<'downloads' | 'name' | 'recent'>('downloads')

// Detail drawer
const detail = ref<HubModule | null>(null)
const detailTab = ref<'overview' | 'readme' | 'versions'>('overview')
const expandedVersion = ref<string | null>(null)
const detailVersions = ref<HubVersion[]>([])
const detailVersionsLoading = ref(false)

// Install / uninstall dialogs
const installOpen = ref(false)
const installComp = ref('')
const installVersion = ref('')
const installRunMigrations = ref(true)
const installBusy = ref(false)
const installError = ref<string | null>(null)
const installPlan = ref<HubInstallPlanResponse | null>(null)
const installPlanLoading = ref(false)
const installPlanError = ref<string | null>(null)
const installRequirements = ref<HubPlanRequirement[]>([])
const installParameterValues = ref<Record<string, string>>({})
const installDependencyNamespace = ref('')
const installDependencyNamespaceTouched = ref(false)

const uninstallTarget = ref<HubDependency | null>(null)
const uninstallPolicy = ref<'down' | 'leave' | 'block'>('down')
const uninstallBusy = ref(false)

let browseTimer: number | null = null

// ---------- helpers ----------

function fmtNum(n: number | undefined): string {
  if (!n) return '0'
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1_000) return (n / 1_000).toFixed(1) + 'k'
  return String(n)
}

function timeAgo(s: string | undefined): string {
  if (!s) return ''
  const ms = new Date(s).getTime()
  if (!Number.isFinite(ms)) return ''
  const sec = Math.floor((Date.now() - ms) / 1000)
  if (sec < 60) return 'just now'
  if (sec < 3600) return `${Math.floor(sec / 60)}m ago`
  if (sec < 86400) return `${Math.floor(sec / 3600)}h ago`
  if (sec < 30 * 86400) return `${Math.floor(sec / 86400)}d ago`
  if (sec < 365 * 86400) return `${Math.floor(sec / (30 * 86400))}mo ago`
  return `${Math.floor(sec / (365 * 86400))}y ago`
}

function looksSecret() { return false }

function moduleAccent(m: HubModule): string {
  // Pick a stable hue per org+name so cards in the same family share a tint.
  const s = (m.full_name || m.name || m.id) as string
  let hash = 0
  for (let i = 0; i < s.length; i++) hash = (hash * 31 + s.charCodeAt(i)) | 0
  const hues = [261, 200, 24, 142, 330, 174, 12, 220, 280, 50]
  const h = hues[Math.abs(hash) % hues.length]
  return `hsl(${h} 70% 56%)`
}

const TYPE_ICONS: Record<string, string> = {
  library: 'tabler:book-2',
  service: 'tabler:server',
  app: 'tabler:apps',
  page: 'tabler:browser',
  agent: 'tabler:robot',
}
function moduleIcon(m: HubModule): string {
  return TYPE_ICONS[(m.type || '').toLowerCase()] || 'tabler:package'
}

function moduleRef(m: HubModule): string {
  return m.full_name || `${m.org}/${m.name}`
}

function requirementKey(req: { parameter_name?: string; full_id?: string; name?: string }): string {
  return (req.parameter_name || req.full_id || req.name || '').trim()
}

function setInstallParameter(req: HubPlanRequirement, value: string) {
  const key = requirementKey(req)
  if (!key) return
  installParameterValues.value[key] = value
}

function requirementPlaceholder(req: HubPlanRequirement): string {
  if (req.expected_kind) return `Enter ${req.expected_kind} id or contract value`
  return 'Enter registry id or contract value'
}

function installNamespacePayload(): string | undefined {
  if (!installDependencyNamespaceTouched.value) return undefined
  const namespace = installDependencyNamespace.value.trim()
  return namespace || undefined
}

function markInstallNamespaceTouched() {
  installDependencyNamespaceTouched.value = true
}

function plannedDependencyId(): string {
  return installPlan.value?.dependency?.id || ''
}

function applyInstallPlan(plan: HubInstallPlanResponse, previousValues: Record<string, string> = installParameterValues.value) {
  installPlan.value = plan
  installRequirements.value = plan.requirements || []
  const values: Record<string, string> = {}
  for (const req of installRequirements.value) {
    const key = requirementKey(req)
    if (!key) continue
    values[key] = previousValues[key] ?? req.value ?? ''
  }
  installParameterValues.value = values
}

async function loadInstallPlan() {
  if (!installComp.value.trim()) return
  installPlanLoading.value = true
  installPlanError.value = null
  const previousValues = { ...installParameterValues.value }
  const existingParams = Object.entries(previousValues)
    .filter(([, value]) => value.trim() !== '')
    .map(([name, value]) => ({ name, value }))
  try {
    const plan = await planHubInstall(api, {
      component: installComp.value.trim(),
      version: installVersion.value.trim() || undefined,
      namespace: installNamespacePayload(),
      run_migrations: installRunMigrations.value,
      migration_policy: installRunMigrations.value ? 'up' : 'none',
      parameters: existingParams.length ? existingParams : undefined,
    })
    applyInstallPlan(plan, previousValues)
  } catch (e: any) {
    installPlan.value = null
    installRequirements.value = []
    installParameterValues.value = {}
    installPlanError.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    installPlanLoading.value = false
  }
}

function configureInstallRequirements(m: HubModule, version?: string) {
  const selected = version
    ? detailVersions.value.find(v => v.version === version)
    : latestVersion.value
  const reqs = (selected?.requirements || [])
    .filter(r => (r.name || '').trim())
    .map(r => ({
      ...r,
      parameter_name: (r.name || '').trim(),
      full_id: (r.name || '').trim(),
      required: true,
      missing: true,
      value: '',
      value_source: 'empty',
      suggestions: [],
    } as HubPlanRequirement))
  const values: Record<string, string> = {}
  for (const req of reqs) {
    const key = requirementKey(req)
    if (key) values[key] = ''
  }
  installRequirements.value = reqs
  installParameterValues.value = values
}

function installParametersPayload(): Array<{ name: string; value: string }> | undefined {
  const out: Array<{ name: string; value: string }> = []
  for (const req of installRequirements.value) {
    const name = requirementKey(req)
    if (!name) continue
    const value = (installParameterValues.value[name] || '').trim()
    if (value !== '' && !req.invalid) out.push({ name, value })
  }
  return out.length ? out : undefined
}

function missingInstallRequirements(): string[] {
  const missing: string[] = []
  for (const req of installRequirements.value) {
    const name = requirementKey(req)
    if (!name || (!req.required && !req.missing)) continue
    const value = (installParameterValues.value[name] || '').trim()
    if (req.invalid || value === '') missing.push(name)
  }
  return missing
}

const installedSet = computed(() => new Set(deps.value.map(d => d.component || '').filter(Boolean)))
function isInstalled(m: HubModule): boolean {
  return installedSet.value.has(moduleRef(m))
}

// Featured: top 6 by downloads on page 1, only when no search
const featured = computed(() => {
  if (browseQuery.value || browsePage.value > 1) return []
  return [...browseItems.value].sort((a, b) => (b.total_downloads || 0) - (a.total_downloads || 0)).slice(0, 6)
})
const featuredIds = computed(() => new Set(featured.value.map(m => m.id)))
const remaining = computed(() => browseItems.value.filter(m => !featuredIds.value.has(m.id)))

const sortedItems = computed(() => {
  const list = [...remaining.value]
  if (sortBy.value === 'name') return list.sort((a, b) => (a.display_name || a.name).localeCompare(b.display_name || b.name))
  if (sortBy.value === 'recent') return list.sort((a, b) => (b.update_time || '').localeCompare(a.update_time || ''))
  return list.sort((a, b) => (b.total_downloads || 0) - (a.total_downloads || 0))
})

const filteredDeps = computed(() => {
  if (!installedSearch.value) return deps.value
  const q = installedSearch.value.toLowerCase()
  return deps.value.filter(d =>
    (d.component || '').toLowerCase().includes(q) ||
    d.id.toLowerCase().includes(q) ||
    (d.version || '').toLowerCase().includes(q),
  )
})

const stats = computed(() => {
  const installed = deps.value.length
  const totalEntries = deps.value.reduce((s, d) => s + (d.installed_entries_count || 0), 0)
  const applied = migrations.value.filter(m => m.status === 'applied').length
  const pending = migrations.value.filter(m => m.status === 'pending').length
  return { installed, totalEntries, applied, pending }
})

const browseMaxPage = computed(() => Math.max(1, Math.ceil(browseTotal.value / browsePageSize)))

const latestVersion = computed<HubVersion | null>(() => {
  if (!detail.value || !detailVersions.value.length) return null
  const latest = detail.value.latest_version
  return detailVersions.value.find(v => v.is_latest || v.version === latest) || detailVersions.value[0]
})

const readmeContent = ref<string>('')
const readmeFilename = ref<string>('')
const readmeVersion = ref<string>('')
const readmeLoading = ref(false)
const readmeText = computed(() => readmeContent.value || latestVersion.value?.readme || '')

function fmtBytes(n: number | undefined): string {
  if (!n) return ''
  if (n >= 1_048_576) return (n / 1_048_576).toFixed(1) + ' MB'
  if (n >= 1024) return (n / 1024).toFixed(1) + ' KB'
  return n + ' B'
}

function toggleVersion(id: string) {
  expandedVersion.value = expandedVersion.value === id ? null : id
}

// Permissive markdown renderer for trusted hub READMEs.
// Allows raw HTML (hub.wippy.ai content is curated; we strip script/style/iframe
// + on* attributes), and applies common markdown features.
function renderHubMarkdown(src: string): string {
  if (!src) return ''
  let html = src
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<iframe\b[^>]*>[\s\S]*?<\/iframe>/gi, '')
    .replace(/\son[a-z]+\s*=\s*"[^"]*"/gi, '')
    .replace(/\son[a-z]+\s*=\s*'[^']*'/gi, '')
    .replace(/javascript:/gi, '')
  const fences: string[] = []
  html = html.replace(/```([a-z0-9_-]*)\n([\s\S]*?)```/g, (_, _lang, code) => {
    const escaped = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    fences.push(`<pre class="rm-pre"><code>${escaped}</code></pre>`)
    return ` FENCE${fences.length - 1} `
  })
  html = html.replace(/`([^`\n]+)`/g, (_, code) => {
    const escaped = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return `<code class="rm-code">${escaped}</code>`
  })
  html = html.replace(/^######\s+(.+)$/gm, '<h6 class="rm-h">$1</h6>')
  html = html.replace(/^#####\s+(.+)$/gm, '<h5 class="rm-h">$1</h5>')
  html = html.replace(/^####\s+(.+)$/gm, '<h4 class="rm-h">$1</h4>')
  html = html.replace(/^###\s+(.+)$/gm, '<h3 class="rm-h">$1</h3>')
  html = html.replace(/^##\s+(.+)$/gm, '<h2 class="rm-h">$1</h2>')
  html = html.replace(/^#\s+(.+)$/gm, '<h1 class="rm-h">$1</h1>')
  html = html.replace(/^-{3,}$/gm, '<hr class="rm-hr" />')
  html = html.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/(^|\W)\*([^*\n]+)\*(?!\*)/g, '$1<em>$2</em>')
  html = html.replace(/!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g, '<img class="rm-img" src="$2" alt="$1" loading="lazy" />')
  html = html.replace(/\[([^\]]+)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g, '<a class="rm-link" href="$2" target="_blank" rel="noopener">$1</a>')
  html = html.replace(/^(\s*)[-*]\s+(.+)$/gm, '$1<li class="rm-uli">$2</li>')
  html = html.replace(/^(\s*)\d+\.\s+(.+)$/gm, '$1<li class="rm-oli">$2</li>')
  html = html.replace(/((?:<li class="rm-uli">.*<\/li>\n?)+)/g, '<ul class="rm-ul">$1</ul>')
  html = html.replace(/((?:<li class="rm-oli">.*<\/li>\n?)+)/g, '<ol class="rm-ol">$1</ol>')
  html = html.replace(/ FENCE(\d+) /g, (_, i) => fences[Number(i)])
  const BLOCK_RE = /^\s*<\/?(?:[a-z][a-z0-9]*)\b/i
  const paras = html.split(/\n{2,}/)
  html = paras.map(p => {
    p = p.trim()
    if (!p) return ''
    if (BLOCK_RE.test(p)) return p
    return '<p class="rm-p">' + p.replace(/\n/g, '<br />') + '</p>'
  }).join('\n')
  return html
}

const renderedReadme = computed(() => renderHubMarkdown(readmeText.value))

// ---------- io ----------

function flash(msg: string, ttl = 3000) {
  successMsg.value = msg
  setTimeout(() => { if (successMsg.value === msg) successMsg.value = null }, ttl)
}

async function loadInstalled() {
  loading.value = true
  error.value = null
  try {
    const [d, m] = await Promise.allSettled([listHubDependencies(api), listHubMigrations(api)])
    if (d.status === 'fulfilled' && d.value?.success) deps.value = d.value.dependencies || []
    if (m.status === 'fulfilled' && m.value?.success) migrations.value = m.value.migrations || []
  } catch (e: any) {
    error.value = e?.message || 'Failed to load installed dependencies'
  } finally {
    loading.value = false
  }
}

async function browse(reset = true) {
  browseLoading.value = true
  browseError.value = null
  if (reset) browsePage.value = 1
  try {
    const r = await browseHubModules(api, {
      query: browseQuery.value.trim() || undefined,
      page: browsePage.value,
      page_size: browsePageSize,
    })
    if (r?.success) {
      browseItems.value = r.items || []
      browseTotal.value = r.total || 0
    } else {
      browseError.value = (r as any)?.error || 'Browse failed'
      browseItems.value = []
    }
  } catch (e: any) {
    browseError.value = e.response?.data?.error || e.message
    browseItems.value = []
  } finally {
    browseLoading.value = false
  }
}

function debouncedBrowse() {
  if (browseTimer) window.clearTimeout(browseTimer)
  browseTimer = window.setTimeout(() => browse(true), 250)
}

function nextPage() { if (browsePage.value < browseMaxPage.value) { browsePage.value++; browse(false) } }
function prevPage() { if (browsePage.value > 1) { browsePage.value--; browse(false) } }

async function openDetail(m: HubModule) {
  detail.value = m
  detailTab.value = 'overview'
  detailVersions.value = []
  readmeContent.value = ''
  readmeFilename.value = ''
  readmeVersion.value = ''
  detailVersionsLoading.value = true
  readmeLoading.value = true
  const ref = m.full_name || `${m.org}/${m.name}`
  const [verResp, readmeResp] = await Promise.allSettled([
    listHubVersions(api, ref, { page_size: 50 }),
    getHubReadme(api, ref),
  ])
  if (verResp.status === 'fulfilled' && verResp.value?.success) detailVersions.value = verResp.value.items || []
  if (readmeResp.status === 'fulfilled' && readmeResp.value?.success) {
    readmeContent.value = readmeResp.value.content || ''
    readmeFilename.value = readmeResp.value.filename || ''
    readmeVersion.value = readmeResp.value.version || ''
  }
  detailVersionsLoading.value = false
  readmeLoading.value = false
}

function closeDetail() {
  detail.value = null
}

function installModule(m: HubModule, version?: string) {
  installComp.value = moduleRef(m)
  installVersion.value = version || m.latest_version || ''
  installRunMigrations.value = true
  installError.value = null
  installPlan.value = null
  installPlanError.value = null
  installDependencyNamespace.value = ''
  installDependencyNamespaceTouched.value = false
  configureInstallRequirements(m, version)
  installOpen.value = true
  void loadInstallPlan()
}

async function submitInstall() {
  if (!installComp.value.trim()) {
    installError.value = 'Component required'
    return
  }
  const missing = missingInstallRequirements()
  if (missing.length) {
    installError.value = `Configure required parameter${missing.length === 1 ? '' : 's'}: ${missing.join(', ')}`
    return
  }
  installBusy.value = true
  installError.value = null
  try {
    const parameters = installParametersPayload()
    await installHubDependency(api, {
      component: installComp.value.trim(),
      version: installVersion.value.trim() || undefined,
      namespace: installNamespacePayload(),
      run_migrations: installRunMigrations.value,
      migration_policy: installRunMigrations.value ? 'up' : 'none',
      parameters,
    })
    installOpen.value = false
    flash(`Installed ${installComp.value}`)
    detail.value = null
    await loadInstalled()
  } catch (e: any) {
    const details = e.response?.data?.details
    if (details?.requirements && details?.install_payload) {
      applyInstallPlan(details)
    }
    installError.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    installBusy.value = false
  }
}

async function submitUninstall() {
  if (!uninstallTarget.value) return
  uninstallBusy.value = true
  try {
    await uninstallHubDependency(api, {
      id: uninstallTarget.value.id,
      component: uninstallTarget.value.component,
      migration_policy: uninstallPolicy.value,
    })
    flash(`Uninstalled ${uninstallTarget.value.component}`)
    uninstallTarget.value = null
    await loadInstalled()
  } catch (e: any) {
    error.value = e.response?.data?.error || e.message
  } finally {
    uninstallBusy.value = false
  }
}

async function applyAllPending() {
  try {
    const r = await runHubMigrations(api, { operation: 'up', only_pending: true })
    flash(`Applied ${r?.count ?? 0} migration${(r?.count ?? 0) === 1 ? '' : 's'}`)
    await loadInstalled()
  } catch (e: any) {
    error.value = e.response?.data?.error || e.message
  }
}

function openHub() {
  try { window.parent.open(HUB_URL, '_blank', 'noopener') } catch { window.open(HUB_URL, '_blank', 'noopener') }
}
function openLink(url?: string) {
  if (!url) return
  try { window.parent.open(url, '_blank', 'noopener') } catch { window.open(url, '_blank', 'noopener') }
}
function toggleDep(id: string) { expandedDep.value = expandedDep.value === id ? null : id }

onMounted(() => {
  loadInstalled()
  browse(true)
})
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader
      icon="tabler:cloud"
      title="Wippy Hub"
      :loading="(tab === 'installed' && loading) || (tab === 'discover' && browseLoading)"
      @refresh="tab === 'installed' ? loadInstalled() : browse(true)"
    >
      <button class="hub-link-btn" @click="openHub" title="Open hub.wippy.ai">
        <Icon icon="tabler:external-link" class="w-3.5 h-3.5" />
        hub.wippy.ai
      </button>
    </PageHeader>

    <!-- Tab strip -->
    <div class="tabs">
      <button class="tab-btn" :class="{ active: tab === 'discover' }" @click="tab = 'discover'">
        <Icon icon="tabler:sparkles" class="w-3.5 h-3.5" />
        Discover
        <span v-if="browseTotal" class="tab-count">{{ browseTotal }}</span>
      </button>
      <button class="tab-btn" :class="{ active: tab === 'installed' }" @click="tab = 'installed'">
        <Icon icon="tabler:package" class="w-3.5 h-3.5" />
        Installed
        <span class="tab-count">{{ deps.length }}</span>
      </button>
      <span class="flex-1"></span>
      <div v-if="tab === 'installed' && stats.pending > 0" class="pending-mini">
        <Icon icon="tabler:alert-triangle" class="w-3 h-3 text-warn-500" />
        {{ stats.pending }} pending
        <button class="apply-mini" @click="applyAllPending">Apply</button>
      </div>
    </div>

    <div v-if="successMsg" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-success-500/10 text-success-500">
      <Icon icon="tabler:check" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ successMsg }}</span>
    </div>
    <div v-if="error" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
      <button @click="error = null" style="color: var(--p-text-muted-color)"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>

    <!-- DISCOVER -->
    <div v-if="tab === 'discover'" class="flex-1 overflow-y-auto">
      <!-- Hero search -->
      <div class="hero">
        <div class="hero-inner">
          <div class="hero-eyebrow">Wippy Hub</div>
          <h1 class="hero-title">Discover modules for your stack</h1>
          <p class="hero-sub">Search components published by the Wippy community and install them as registry dependencies.</p>
          <div class="hero-search">
            <Icon icon="tabler:search" class="hero-search-icon" />
            <input
              v-model="browseQuery"
              @input="debouncedBrowse"
              type="text"
              placeholder="Search modules, e.g. agent, llm, dataflow…"
              class="hero-search-input"
            />
            <select v-model="sortBy" class="hero-sort">
              <option value="downloads">Top downloads</option>
              <option value="name">Name A→Z</option>
              <option value="recent">Recently updated</option>
            </select>
          </div>
        </div>
      </div>

      <div class="px-5 pb-5 space-y-6">
        <div v-if="browseError" class="px-3 py-2 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ browseError }}</div>

        <div v-if="browseLoading && browseItems.length === 0" class="text-center py-16">
          <Icon icon="tabler:loader-2" class="w-7 h-7 mx-auto animate-spin keeper-accent" />
          <p class="mt-3 text-xs" style="color: var(--p-text-muted-color)">Searching hub…</p>
        </div>

        <div v-else-if="browseItems.length === 0" class="text-center py-16">
          <Icon icon="tabler:world-search" class="w-12 h-12 mx-auto opacity-30" style="color: var(--p-text-muted-color)" />
          <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">{{ browseQuery ? `No modules match "${browseQuery}"` : 'No modules available' }}</p>
        </div>

        <template v-else>
          <!-- Featured -->
          <section v-if="featured.length">
            <div class="section-head">
              <Icon icon="tabler:flame" class="w-4 h-4 text-accent-400" />
              <span class="section-title">Most popular</span>
              <span class="section-sub">handpicked by downloads</span>
            </div>
            <div class="featured-grid">
              <button
                v-for="m in featured" :key="m.id"
                class="feat-card"
                :style="{ '--accent': moduleAccent(m) }"
                @click="navigateToModule(m)"
              >
                <div class="feat-strip"></div>
                <div class="feat-icon"><Icon :icon="moduleIcon(m)" class="w-7 h-7" /></div>
                <div class="feat-body">
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <span class="feat-name">{{ m.display_name || m.name }}</span>
                    <span v-if="isInstalled(m)" class="installed-pill">installed</span>
                    <span v-if="m.deprecated" class="deprecated-pill">deprecated</span>
                  </div>
                  <div class="feat-org">{{ m.full_name || (m.org + '/' + m.name) }}</div>
                  <p v-if="m.description" class="feat-desc">{{ m.description }}</p>
                  <div class="feat-meta">
                    <span class="meta-pill"><Icon icon="tabler:tag" class="w-3 h-3" /> {{ m.latest_version || '?' }}</span>
                    <span class="meta-pill"><Icon icon="tabler:download" class="w-3 h-3" /> {{ fmtNum(m.total_downloads) }}</span>
                    <span v-if="m.license" class="meta-pill"><Icon icon="tabler:license" class="w-3 h-3" /> {{ m.license }}</span>
                  </div>
                </div>
              </button>
            </div>
          </section>

          <!-- All modules -->
          <section v-if="sortedItems.length">
            <div class="section-head">
              <Icon icon="tabler:apps" class="w-4 h-4 keeper-accent" />
              <span class="section-title">All modules</span>
              <span class="section-sub">{{ browseTotal.toLocaleString() }} on the hub</span>
            </div>
            <div class="mod-grid">
              <button
                v-for="m in sortedItems" :key="m.id"
                class="mod-card"
                :style="{ '--accent': moduleAccent(m) }"
                @click="navigateToModule(m)"
              >
                <div class="mod-icon"><Icon :icon="moduleIcon(m)" class="w-5 h-5" /></div>
                <div class="mod-body">
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <span class="mod-name">{{ m.display_name || m.name }}</span>
                    <span class="mod-version">{{ m.latest_version || '—' }}</span>
                    <span v-if="isInstalled(m)" class="installed-pill">installed</span>
                    <span v-if="m.deprecated" class="deprecated-pill">deprecated</span>
                  </div>
                  <div class="mod-org">{{ m.full_name || (m.org + '/' + m.name) }}</div>
                  <p v-if="m.description" class="mod-desc">{{ m.description }}</p>
                  <div class="mod-foot">
                    <span class="foot-stat"><Icon icon="tabler:download" class="w-3 h-3" /> {{ fmtNum(m.total_downloads) }}</span>
                    <span v-if="m.favorites_count" class="foot-stat"><Icon icon="tabler:star" class="w-3 h-3" /> {{ m.favorites_count }}</span>
                    <span v-if="m.license" class="foot-stat" style="opacity: 0.7">{{ m.license }}</span>
                    <span v-if="m.update_time" class="foot-stat ml-auto" style="opacity: 0.6">{{ timeAgo(m.update_time) }}</span>
                  </div>
                </div>
              </button>
            </div>
          </section>

          <div v-if="browseTotal > browsePageSize" class="pager">
            <span class="pager-info">Page {{ browsePage }} of {{ browseMaxPage }} · {{ browseTotal.toLocaleString() }} total</span>
            <div class="flex gap-1">
              <button :disabled="browsePage <= 1" @click="prevPage" class="page-btn">Prev</button>
              <button :disabled="browsePage >= browseMaxPage" @click="nextPage" class="page-btn">Next</button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- INSTALLED -->
    <div v-else class="flex-1 overflow-y-auto">
      <div class="installed-toolbar">
        <div class="search-wrap">
          <Icon icon="tabler:search" class="search-icon" />
          <input v-model="installedSearch" type="text" placeholder="Search installed…" class="search-input" />
        </div>
        <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ filteredDeps.length }}<template v-if="filteredDeps.length !== deps.length"> / {{ deps.length }}</template></span>
        <span class="flex-1"></span>
        <div class="stat-mini"><span class="stat-mini-label">Entries</span> <span>{{ stats.totalEntries }}</span></div>
        <div class="stat-mini"><span class="stat-mini-label">Migrations</span> <span class="text-success-500">{{ stats.applied }}</span> · <span :class="stats.pending > 0 ? 'text-warn-500' : ''">{{ stats.pending }}</span></div>
      </div>

      <div class="px-5 py-4">
        <div v-if="filteredDeps.length === 0" class="text-center py-16">
          <Icon icon="tabler:package-off" class="w-12 h-12 mx-auto opacity-30" style="color: var(--p-text-muted-color)" />
          <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">{{ installedSearch ? 'No installed components match' : 'No hub dependencies installed yet' }}</p>
          <button class="hero-btn mt-4" @click="tab = 'discover'">
            <Icon icon="tabler:sparkles" class="w-3.5 h-3.5" /> Discover modules
          </button>
        </div>
        <div v-else class="installed-list">
          <div v-for="d in filteredDeps" :key="d.id" class="inst-card">
            <div class="inst-head" @click="toggleDep(d.id)">
              <div class="inst-icon"><Icon icon="tabler:package" class="w-4 h-4" /></div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="inst-name">{{ d.component }}</span>
                  <span v-if="d.version" class="mod-version">{{ d.version }}</span>
                  <span v-if="d.installed_entries_count" class="meta-pill" style="background: var(--p-surface-200); color: var(--p-text-muted-color); border: none">
                    {{ d.installed_entries_count }} entries
                  </span>
                  <span v-if="d.migrations && d.migrations.filter(m => m.status === 'pending').length" class="warn-pill">
                    {{ d.migrations.filter(m => m.status === 'pending').length }} pending
                  </span>
                </div>
                <div class="mod-org" style="margin-top: 1px">{{ d.id }}</div>
              </div>
              <button class="row-btn" @click.stop="uninstallTarget = d; uninstallPolicy = 'down'" title="Uninstall">
                <Icon icon="tabler:trash" class="w-3.5 h-3.5 text-danger-500" />
              </button>
              <Icon :icon="expandedDep === d.id ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3.5 h-3.5" style="color: var(--p-text-muted-color)" />
            </div>
            <div v-if="expandedDep === d.id" class="inst-body">
              <div v-if="d.migrations && d.migrations.length" class="dep-section">
                <div class="dep-sub-label">Migrations</div>
                <div v-for="m in d.migrations" :key="m.id" class="mig-row">
                  <span class="font-mono text-[10px] flex-1 truncate" style="color: var(--p-text-color)">{{ m.id }}</span>
                  <span v-if="m.module_version" class="text-[9px] font-mono" style="color: var(--p-text-muted-color)">{{ m.module_version }}</span>
                  <span class="status-tag" :class="m.status === 'applied' ? 'applied' : m.status === 'pending' ? 'pending' : 'unknown'">{{ m.status || 'unknown' }}</span>
                </div>
              </div>
              <div v-if="d.entries && d.entries.length" class="dep-section">
                <div class="dep-sub-label">Entries ({{ d.entries.length }})</div>
                <div v-for="e in d.entries.slice(0, 50)" :key="e.id" class="entry-row">
                  <span class="kind-tag">{{ e.kind || e.type || '—' }}</span>
                  <span class="font-mono text-[10px] truncate" style="color: var(--p-text-color)">{{ e.id }}</span>
                </div>
                <div v-if="d.entries.length > 50" class="text-[10px] mt-1" style="color: var(--p-text-muted-color)">…and {{ d.entries.length - 50 }} more</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- DETAIL DRAWER -->
    <Teleport to="body">
      <div v-if="detail" class="drawer-overlay" @click.self="closeDetail">
        <div class="drawer" :style="{ '--accent': moduleAccent(detail) }">
          <div class="drawer-head">
            <div class="drawer-icon"><Icon :icon="moduleIcon(detail)" class="w-7 h-7" /></div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="drawer-name">{{ detail.display_name || detail.name }}</span>
                <span v-if="isInstalled(detail)" class="installed-pill">installed</span>
                <span v-if="detail.deprecated" class="deprecated-pill">deprecated</span>
              </div>
              <div class="drawer-org">{{ detail.full_name || (detail.org + '/' + detail.name) }}</div>
              <p v-if="detail.description" class="drawer-desc">{{ detail.description }}</p>
            </div>
            <button class="drawer-close" @click="closeDetail"><Icon icon="tabler:x" class="w-4 h-4" /></button>
          </div>
          <div class="drawer-cta">
            <button class="primary-cta" @click="installModule(detail)">
              <Icon icon="tabler:download" class="w-3.5 h-3.5" />
              {{ isInstalled(detail) ? 'Reinstall / update' : 'Install' }}
              <span class="cta-version">{{ detail.latest_version || '' }}</span>
            </button>
            <button v-if="detail.repository" class="ghost-btn" @click="openLink(detail.repository)" title="Repository">
              <Icon icon="tabler:brand-github" class="w-3.5 h-3.5" /> repo
            </button>
            <button v-if="detail.homepage" class="ghost-btn" @click="openLink(detail.homepage)" title="Homepage">
              <Icon icon="tabler:home" class="w-3.5 h-3.5" /> homepage
            </button>
          </div>

          <div class="drawer-tabs">
            <button class="drawer-tab" :class="{ active: detailTab === 'overview' }" @click="detailTab = 'overview'">Overview</button>
            <button class="drawer-tab" :class="{ active: detailTab === 'readme' }" @click="detailTab = 'readme'" :disabled="!readmeText && !detailVersionsLoading">Readme</button>
            <button class="drawer-tab" :class="{ active: detailTab === 'versions' }" @click="detailTab = 'versions'">Versions <span v-if="detailVersions.length" class="opacity-70">{{ detailVersions.length }}</span></button>
          </div>

          <div class="drawer-body">
            <template v-if="detailTab === 'overview'">
              <div v-if="detail.deprecated && detail.deprecation_message" class="deprecation-note">
                <Icon icon="tabler:alert-triangle" class="w-3.5 h-3.5 text-warn-500" />
                <span>{{ detail.deprecation_message }}</span>
              </div>
              <div class="kv-grid">
                <div class="kv-row"><div class="kv-key">Latest</div><div class="kv-val font-mono">{{ detail.latest_version || '—' }}</div></div>
                <div class="kv-row"><div class="kv-key">Type</div><div class="kv-val">{{ detail.type || '—' }}</div></div>
                <div class="kv-row"><div class="kv-key">License</div><div class="kv-val">{{ detail.license || '—' }}</div></div>
                <div class="kv-row"><div class="kv-key">Downloads</div><div class="kv-val">{{ (detail.total_downloads || 0).toLocaleString() }}</div></div>
                <div class="kv-row"><div class="kv-key">Favorites</div><div class="kv-val">{{ detail.favorites_count || 0 }}</div></div>
                <div v-if="detail.update_time" class="kv-row"><div class="kv-key">Updated</div><div class="kv-val">{{ timeAgo(detail.update_time) }}</div></div>
                <div v-if="detail.create_time" class="kv-row"><div class="kv-key">Created</div><div class="kv-val">{{ timeAgo(detail.create_time) }}</div></div>
                <div v-if="(detail.keywords || []).length" class="kv-row align-start">
                  <div class="kv-key">Keywords</div>
                  <div class="kv-val flex flex-wrap gap-1">
                    <span v-for="k in detail.keywords" :key="k" class="keyword-chip">{{ k }}</span>
                  </div>
                </div>
              </div>

              <!-- Latest version info -->
              <div v-if="latestVersion" class="ov-block">
                <div class="ov-block-head">
                  <Icon icon="tabler:tag" class="w-3.5 h-3.5" />
                  Latest version <span class="font-mono">{{ latestVersion.version }}</span>
                </div>
                <div class="kv-grid">
                  <div v-if="latestVersion.entry_count !== undefined" class="kv-row">
                    <div class="kv-key">Entries</div>
                    <div class="kv-val">{{ latestVersion.entry_count }}</div>
                  </div>
                  <div v-if="latestVersion.size_bytes" class="kv-row">
                    <div class="kv-key">Size</div>
                    <div class="kv-val">{{ fmtBytes(latestVersion.size_bytes) }}</div>
                  </div>
                  <div v-if="latestVersion.published_by" class="kv-row">
                    <div class="kv-key">Published by</div>
                    <div class="kv-val font-mono text-[11px]">{{ latestVersion.published_by }}</div>
                  </div>
                  <div v-if="latestVersion.digest" class="kv-row">
                    <div class="kv-key">Digest</div>
                    <div class="kv-val font-mono text-[10px] truncate" :title="latestVersion.digest">{{ latestVersion.digest.slice(0, 16) }}…</div>
                  </div>
                  <div v-if="(latestVersion.entry_kinds || []).length" class="kv-row align-start">
                    <div class="kv-key">Kinds</div>
                    <div class="kv-val flex flex-wrap gap-1">
                      <span v-for="k in latestVersion.entry_kinds" :key="k" class="kind-chip">{{ k }}</span>
                    </div>
                  </div>
                  <div v-if="(latestVersion.lua_modules || []).length" class="kv-row align-start">
                    <div class="kv-key">Modules</div>
                    <div class="kv-val flex flex-wrap gap-1">
                      <span v-for="m in latestVersion.lua_modules" :key="m" class="kind-chip mono">{{ m }}</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Dependencies -->
              <div v-if="latestVersion?.dependencies?.length" class="ov-block">
                <div class="ov-block-head">
                  <Icon icon="tabler:packages" class="w-3.5 h-3.5" />
                  Dependencies <span class="opacity-70">{{ latestVersion.dependencies.length }}</span>
                </div>
                <div class="dep-list">
                  <div v-for="(d, i) in latestVersion.dependencies" :key="i" class="dep-line">
                    <span class="font-mono text-[11px]" style="color: var(--p-text-color)">{{ d.org }}/{{ d.name }}</span>
                    <span class="font-mono text-[10px]" style="color: var(--p-text-muted-color)">{{ d.version_constraint }}</span>
                  </div>
                </div>
              </div>

              <!-- Requirements -->
              <div v-if="latestVersion?.requirements?.length" class="ov-block">
                <div class="ov-block-head">
                  <Icon icon="tabler:list-check" class="w-3.5 h-3.5" />
                  Requirements <span class="opacity-70">{{ latestVersion.requirements.length }}</span>
                </div>
                <div class="dep-list">
                  <div v-for="(r, i) in latestVersion.requirements" :key="i" class="dep-line">
                    <span class="font-mono text-[11px]" style="color: var(--p-text-color)">{{ r.name }}</span>
                    <span v-if="r.default" class="font-mono text-[10px]" style="color: var(--p-text-muted-color)">default {{ r.default }}</span>
                    <span v-else class="text-[9px]" style="color: var(--p-warn-500)">needs value</span>
                    <span v-if="r.description" class="text-[10px] truncate" style="color: var(--p-text-muted-color)">{{ r.description }}</span>
                  </div>
                </div>
              </div>
            </template>

            <template v-else-if="detailTab === 'readme'">
              <div v-if="detailVersionsLoading" class="text-center py-8">
                <Icon icon="tabler:loader-2" class="w-5 h-5 mx-auto animate-spin keeper-accent" />
              </div>
              <div v-else-if="!readmeText" class="text-[11px] py-4 italic" style="color: var(--p-text-muted-color)">
                No README provided for {{ latestVersion?.version || 'this module' }}.
              </div>
              <div v-else>
                <div class="readme-meta">
                  <Icon icon="tabler:tag" class="w-3 h-3" />
                  Showing readme for version <span class="font-mono ml-1">{{ latestVersion?.version }}</span>
                </div>
                <div class="readme-body" v-html="renderedReadme"></div>
              </div>
            </template>

            <template v-else-if="detailTab === 'versions'">
              <div v-if="detailVersionsLoading" class="text-center py-8">
                <Icon icon="tabler:loader-2" class="w-5 h-5 mx-auto animate-spin keeper-accent" />
              </div>
              <div v-else-if="detailVersions.length === 0" class="text-[11px] py-4 italic" style="color: var(--p-text-muted-color)">No versions returned.</div>
              <div v-else>
                <div v-for="v in detailVersions" :key="v.id" class="ver-block" :class="{ expanded: expandedVersion === v.id }">
                  <div class="ver-row" @click="toggleVersion(v.id)">
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2">
                        <span class="font-mono text-[12px] font-semibold" style="color: var(--p-text-color)">{{ v.version }}</span>
                        <span v-if="v.is_latest || v.version === detail.latest_version" class="latest-badge">latest</span>
                        <span v-if="v.yanked" class="yanked-badge">yanked</span>
                        <span v-if="v.protected" class="protected-badge" :title="v.protection_type">protected</span>
                      </div>
                      <div class="text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">
                        <span v-if="v.create_time">{{ timeAgo(v.create_time) }}</span>
                        <span v-if="v.download_count !== undefined" class="ml-2">· {{ fmtNum(v.download_count) }} downloads</span>
                        <span v-if="v.entry_count !== undefined" class="ml-2">· {{ v.entry_count }} entries</span>
                        <span v-if="v.size_bytes" class="ml-2">· {{ fmtBytes(v.size_bytes) }}</span>
                      </div>
                    </div>
                    <button class="ghost-btn" @click.stop="installModule(detail!, v.version)">
                      <Icon icon="tabler:download" class="w-3 h-3" /> Install
                    </button>
                    <Icon :icon="expandedVersion === v.id ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3 ml-1" style="color: var(--p-text-muted-color)" />
                  </div>

                  <div v-if="expandedVersion === v.id" class="ver-body">
                    <div v-if="v.release_notes" class="ver-section">
                      <div class="ver-section-title">Release notes</div>
                      <div class="release-notes">{{ v.release_notes }}</div>
                    </div>
                    <div v-if="(v.entry_kinds || []).length" class="ver-section">
                      <div class="ver-section-title">Entry kinds <span class="opacity-70">{{ v.entry_kinds!.length }}</span></div>
                      <div class="flex flex-wrap gap-1">
                        <span v-for="k in v.entry_kinds" :key="k" class="kind-chip">{{ k }}</span>
                      </div>
                    </div>
                    <div v-if="(v.lua_modules || []).length" class="ver-section">
                      <div class="ver-section-title">Lua modules <span class="opacity-70">{{ v.lua_modules!.length }}</span></div>
                      <div class="flex flex-wrap gap-1">
                        <span v-for="m in v.lua_modules" :key="m" class="kind-chip mono">{{ m }}</span>
                      </div>
                    </div>
                    <div v-if="(v.dependencies || []).length" class="ver-section">
                      <div class="ver-section-title">Dependencies <span class="opacity-70">{{ v.dependencies!.length }}</span></div>
                      <div class="dep-list">
                        <div v-for="(d, i) in v.dependencies" :key="i" class="dep-line">
                          <span class="font-mono text-[11px]" style="color: var(--p-text-color)">{{ d.org }}/{{ d.name }}</span>
                          <span class="font-mono text-[10px]" style="color: var(--p-text-muted-color)">{{ d.version_constraint }}</span>
                        </div>
                      </div>
                    </div>
                    <div v-if="(v.requirements || []).length" class="ver-section">
                      <div class="ver-section-title">Configuration <span class="opacity-70">{{ v.requirements!.length }}</span></div>
                      <div class="dep-list">
                        <div v-for="(r, i) in v.requirements" :key="i" class="dep-line">
                          <span class="font-mono text-[11px]" style="color: var(--p-text-color)">{{ r.name }}</span>
                          <span v-if="r.default" class="font-mono text-[10px]" style="color: var(--p-text-muted-color)">default {{ r.default }}</span>
                          <span v-else class="text-[9px]" style="color: var(--p-warn-500)">needs value</span>
                        </div>
                      </div>
                    </div>
                    <div v-if="v.published_by || v.digest" class="ver-section">
                      <div v-if="v.published_by" class="ver-meta-line">
                        <span class="ver-meta-key">Published by</span>
                        <span class="font-mono text-[10px]" style="color: var(--p-text-color)">{{ v.published_by }}</span>
                      </div>
                      <div v-if="v.digest" class="ver-meta-line">
                        <span class="ver-meta-key">Digest</span>
                        <span class="font-mono text-[10px] truncate" style="color: var(--p-text-color)" :title="v.digest">{{ v.digest.slice(0, 24) }}…</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- INSTALL DIALOG -->
    <Teleport to="body">
      <div v-if="installOpen" class="overlay" @click.self="installOpen = false">
        <div class="dialog">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:download" class="w-5 h-5 text-info-500" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Install {{ installComp }}</span>
          </div>
          <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
            Installs a component from the hub and applies its registry entries.
          </p>
          <label class="form-label">Version</label>
          <input v-model="installVersion" placeholder="latest" class="form-input font-mono" @change="loadInstallPlan" />
          <label class="form-label mt-3">Dependency namespace</label>
          <input
            v-model="installDependencyNamespace"
            placeholder="auto"
            class="form-input font-mono"
            @input="markInstallNamespaceTouched"
            @change="loadInstallPlan"
          />
          <div class="field-hint">
            Auto target uses an existing dependency entry or the strongest dependency namespace cluster.
            <span v-if="plannedDependencyId()" class="font-mono">{{ plannedDependencyId() }}</span>
          </div>
          <div class="mt-2 flex items-center justify-between gap-2 text-[10px]" style="color: var(--p-text-muted-color)">
            <span v-if="installPlanLoading">Resolving install plan…</span>
            <span v-else-if="installPlan">{{ installPlan.module_count }} module{{ installPlan.module_count === 1 ? '' : 's' }} · {{ installPlan.requirement_count }} setting{{ installPlan.requirement_count === 1 ? '' : 's' }}</span>
            <span v-else>Plan resolves transitive requirements before install.</span>
            <button class="ghost-btn" type="button" @click="loadInstallPlan" :disabled="installPlanLoading">Refresh</button>
          </div>
          <div v-if="installPlan?.graph?.length" class="mt-2 mb-2 max-h-24 overflow-auto rounded border p-2" style="border-color: var(--p-content-border-color)">
            <div v-for="node in installPlan.graph" :key="`${node.module}@${node.version}`" class="flex items-center justify-between gap-2 text-[10px]">
              <span class="font-mono truncate" style="color: var(--p-text-color)">{{ node.module }}</span>
              <span style="color: var(--p-text-muted-color)">{{ node.direct ? 'root' : 'transitive' }} · {{ node.version || node.constraint }}</span>
            </div>
          </div>
          <div v-if="installRequirements.length" class="mt-3 mb-3">
            <div class="form-label flex items-center gap-1.5">
              <Icon icon="tabler:list-check" class="w-3.5 h-3.5" />
              Configuration <span style="color: var(--p-text-muted-color)">({{ installRequirements.length }})</span>
            </div>
            <div class="space-y-2">
              <label v-for="(req, idx) in installRequirements" :key="req.parameter_name || req.name" class="block">
                <div class="flex items-center gap-2 mb-1">
                  <span class="font-mono text-[11px]" style="color: var(--p-text-color)">{{ req.parameter_name || req.name }}</span>
                  <span v-if="req.transitive" class="text-[9px]" style="color: var(--p-text-muted-color)">transitive</span>
                  <span v-if="req.required" class="text-[9px]" style="color: var(--p-warn-500)">required</span>
                  <span v-if="req.invalid" class="text-[9px]" style="color: var(--p-danger-500)">invalid</span>
                  <span v-if="req.value_source && req.value_source !== 'empty'" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.value_source }}</span>
                  <span v-if="req.expected_kind" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.expected_kind }}</span>
                  <span v-if="req.targets?.length" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.targets.length }} target{{ req.targets.length === 1 ? '' : 's' }}</span>
                </div>
                <RequirementValueInput
                  :model-value="installParameterValues[requirementKey(req)] || ''"
                  :requirement="req"
                  :placeholder="requirementPlaceholder(req)"
                  @update:model-value="setInstallParameter(req, $event)"
                  @commit="loadInstallPlan"
                />
                <div v-if="req.default && req.value_source !== 'default'" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">Package default: <span class="font-mono">{{ req.default }}</span></div>
                <div v-if="req.invalid_reason" class="mt-1 text-[10px]" style="color: var(--p-danger-500)">{{ req.invalid_reason }}</div>
                <div v-if="req.module" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.module }}{{ req.version ? '@' + req.version : '' }}</div>
                <div v-if="req.description" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.description }}</div>
              </label>
            </div>
          </div>
          <div v-else-if="installPlan && !installPlanLoading" class="mt-3 mb-3 text-[11px]" style="color: var(--p-text-muted-color)">
            No configuration required.
          </div>
          <label class="form-check">
            <input v-model="installRunMigrations" type="checkbox" />
            Run migrations after install
          </label>
          <div v-if="installPlanError" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ installPlanError }}</div>
          <div v-if="installError" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ installError }}</div>
          <div class="flex justify-end gap-2 mt-4">
            <button class="dialog-btn cancel" @click="installOpen = false" :disabled="installBusy">Cancel</button>
            <button class="dialog-btn proceed" @click="submitInstall" :disabled="installBusy || installPlanLoading || missingInstallRequirements().length > 0">
              <Icon v-if="installBusy" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
              Install
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- UNINSTALL DIALOG -->
    <Teleport to="body">
      <div v-if="uninstallTarget" class="overlay" @click.self="uninstallTarget = null">
        <div class="dialog">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:trash" class="w-5 h-5 text-danger-500" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Uninstall {{ uninstallTarget.component }}</span>
          </div>
          <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
            Removes <code class="font-mono">{{ uninstallTarget.component }}</code>{{ uninstallTarget.version ? '@' + uninstallTarget.version : '' }} from the registry.
          </p>
          <label class="radio-row" v-for="opt in [
            { value: 'down', label: 'Roll back', desc: 'Run down migrations before removing' },
            { value: 'leave', label: 'Leave applied', desc: 'Keep migrations (data remains)' },
            { value: 'block', label: 'Block', desc: 'Refuse if migrations are still applied' },
          ]" :key="opt.value">
            <input type="radio" :value="opt.value" v-model="uninstallPolicy" />
            <span>
              <span class="font-medium" style="color: var(--p-text-color)">{{ opt.label }}</span>
              <span class="block text-[10px]" style="color: var(--p-text-muted-color)">{{ opt.desc }}</span>
            </span>
          </label>
          <div class="flex justify-end gap-2 mt-4">
            <button class="dialog-btn cancel" @click="uninstallTarget = null" :disabled="uninstallBusy">Cancel</button>
            <button class="dialog-btn danger" @click="submitUninstall" :disabled="uninstallBusy">
              <Icon v-if="uninstallBusy" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
              Uninstall
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
/* ---------- Tabs ---------- */
.tabs {
  display: flex; align-items: center; gap: 4px;
  padding: 0 16px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: var(--p-content-background);
  flex-shrink: 0;
}
.tab-btn {
  display: flex; align-items: center; gap: 6px;
  padding: 9px 14px;
  background: transparent;
  border: 0; border-bottom: 2px solid transparent;
  color: var(--p-text-muted-color);
  font-size: 11px; font-weight: 600;
  cursor: pointer;
}
.tab-btn:hover { color: var(--p-text-color); }
.tab-btn.active {
  color: var(--p-info-500);
  border-bottom-color: var(--p-info-500);
}
.tab-count {
  font-size: 9px; font-weight: 700;
  padding: 1px 6px;
  border-radius: 8px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.tab-btn.active .tab-count {
  background: color-mix(in srgb, var(--p-info-500) 18%, transparent);
  color: var(--p-info-500);
}
.pending-mini {
  display: flex; align-items: center; gap: 6px;
  padding: 4px 10px; border-radius: 12px;
  background: color-mix(in srgb, var(--p-warn-500) 10%, transparent);
  color: var(--p-warn-500);
  font-size: 10px; font-weight: 600;
}
.apply-mini {
  margin-left: 4px;
  padding: 1px 8px; border-radius: 8px;
  background: var(--p-warn-500); color: white;
  border: 0; cursor: pointer; font-size: 9px; font-weight: 700;
}

/* ---------- Hub link ---------- */
.hub-link-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 10px; border-radius: 16px;
  font-size: 11px; font-weight: 500;
  background: color-mix(in srgb, var(--p-info-500) 10%, transparent);
  color: var(--p-info-500);
  border: 1px solid color-mix(in srgb, var(--p-info-500) 30%, transparent);
  cursor: pointer;
}
.hub-link-btn:hover { background: color-mix(in srgb, var(--p-info-500) 18%, transparent); }

/* ---------- Hero ---------- */
.hero {
  padding: 36px 20px 24px;
  background: radial-gradient(circle at 18% 30%, color-mix(in srgb, var(--p-info-500) 14%, transparent), transparent 55%),
              radial-gradient(circle at 82% 80%, color-mix(in srgb, var(--p-primary-color) 12%, transparent), transparent 50%),
              var(--p-surface-50);
  border-bottom: 1px solid var(--p-content-border-color);
}
.hero-inner { max-width: 920px; margin: 0 auto; text-align: center; }
.hero-eyebrow {
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.18em; font-weight: 700;
  color: var(--p-info-500);
  margin-bottom: 8px;
}
.hero-title {
  font-size: 22px; font-weight: 700; line-height: 1.2;
  color: var(--p-text-color);
  margin: 0 0 6px;
}
.hero-sub {
  font-size: 12px; line-height: 1.55;
  color: var(--p-text-muted-color);
  margin: 0 0 18px;
}
.hero-search {
  position: relative;
  display: flex; align-items: center;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 12px;
  padding: 4px 4px 4px 14px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.04), 0 1px 3px rgba(0,0,0,0.04);
  max-width: 720px;
  margin: 0 auto;
}
.hero-search-icon {
  width: 16px; height: 16px;
  color: var(--p-text-muted-color);
  flex-shrink: 0;
}
.hero-search-input {
  flex: 1;
  padding: 10px 12px;
  font-size: 13px;
  background: transparent;
  color: var(--p-text-color);
  border: 0; outline: 0;
}
.hero-search-input::placeholder { color: var(--p-text-muted-color); }
.hero-sort {
  flex-shrink: 0;
  padding: 6px 10px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  outline: 0;
}
.hero-btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 6px 14px; border-radius: 16px;
  background: var(--p-info-500); color: white;
  border: 0; font-size: 11px; font-weight: 600; cursor: pointer;
}
.hero-btn:hover { opacity: 0.9; }

/* ---------- Sections ---------- */
.section-head {
  display: flex; align-items: center; gap: 8px;
  padding: 16px 0 10px;
}
.section-title {
  font-size: 13px; font-weight: 600;
  color: var(--p-text-color);
}
.section-sub {
  font-size: 11px;
  color: var(--p-text-muted-color);
  margin-left: 4px;
}

/* ---------- Featured cards ---------- */
.featured-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 14px;
}
.feat-card {
  position: relative;
  display: flex; align-items: stretch; gap: 14px;
  text-align: left;
  padding: 16px 16px 14px 22px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 12px;
  cursor: pointer;
  overflow: hidden;
  transition: transform 0.12s ease, border-color 0.12s, box-shadow 0.12s;
}
.feat-card:hover {
  transform: translateY(-1px);
  border-color: var(--accent);
  box-shadow: 0 8px 24px rgba(0,0,0,0.05);
}
.feat-strip {
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 4px;
  background: var(--accent);
}
.feat-icon {
  flex-shrink: 0;
  width: 56px; height: 56px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 12px;
  background: color-mix(in srgb, var(--accent) 14%, transparent);
  color: var(--accent);
}
.feat-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.feat-name {
  font-size: 14px; font-weight: 700;
  color: var(--p-text-color);
}
.feat-org {
  font-size: 11px; font-family: 'JetBrains Mono', monospace;
  color: var(--p-text-muted-color);
}
.feat-desc {
  font-size: 11px; line-height: 1.5;
  color: var(--p-text-muted-color);
  margin: 4px 0 6px;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden;
}
.feat-meta {
  display: flex; flex-wrap: wrap; gap: 6px; margin-top: auto;
}

/* ---------- Module cards (grid) ---------- */
.mod-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
  gap: 12px;
}
.mod-card {
  display: flex; align-items: flex-start; gap: 12px;
  text-align: left;
  padding: 12px 14px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 10px;
  cursor: pointer;
  transition: border-color 0.12s, background 0.12s;
}
.mod-card:hover { border-color: var(--accent); background: var(--p-surface-100); }
.mod-icon {
  flex-shrink: 0;
  width: 38px; height: 38px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 10px;
  background: color-mix(in srgb, var(--accent) 14%, transparent);
  color: var(--accent);
}
.mod-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.mod-name {
  font-size: 12px; font-weight: 700;
  color: var(--p-text-color);
}
.mod-version {
  font-size: 10px;
  font-family: 'JetBrains Mono', monospace;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  padding: 1px 6px;
  border-radius: 8px;
}
.mod-org {
  font-size: 10px; font-family: 'JetBrains Mono', monospace;
  color: var(--p-text-muted-color);
}
.mod-desc {
  font-size: 11px; line-height: 1.45;
  color: var(--p-text-muted-color);
  margin: 4px 0 6px;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden;
}
.mod-foot {
  display: flex; align-items: center; gap: 10px;
  font-size: 10px;
  color: var(--p-text-muted-color);
  margin-top: 2px;
}
.foot-stat { display: inline-flex; align-items: center; gap: 3px; }

/* ---------- Pills ---------- */
.meta-pill {
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 10px; font-weight: 500;
  padding: 1px 7px;
  border-radius: 8px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
}
.installed-pill {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-success-500) 15%, transparent);
  color: var(--p-success-500);
}
.deprecated-pill {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-warn-500) 18%, transparent);
  color: var(--p-warn-500);
}
.warn-pill {
  font-size: 9px; font-weight: 600;
  padding: 1px 6px; border-radius: 8px;
  background: color-mix(in srgb, var(--p-warn-500) 16%, transparent);
  color: var(--p-warn-500);
}

/* ---------- Pager ---------- */
.pager {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 0;
}
.pager-info {
  font-size: 11px;
  color: var(--p-text-muted-color);
}
.page-btn {
  padding: 4px 14px;
  border-radius: 8px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.page-btn:hover:not(:disabled) { background: var(--p-surface-200); }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }

/* ---------- Installed view ---------- */
.installed-toolbar {
  display: flex; align-items: center; gap: 12px;
  padding: 10px 16px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: var(--p-surface-50);
}
.stat-mini {
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 10px;
  color: var(--p-text-muted-color);
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  padding: 3px 10px;
}
.stat-mini-label {
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 600;
  margin-right: 2px;
}

.installed-list { display: flex; flex-direction: column; gap: 8px; }
.inst-card {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  overflow: hidden;
}
.inst-head {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 14px;
  cursor: pointer;
}
.inst-head:hover { background: var(--p-surface-100); }
.inst-icon {
  width: 32px; height: 32px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 8px;
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  color: var(--p-info-500);
  flex-shrink: 0;
}
.inst-name {
  font-size: 12px; font-weight: 700;
  color: var(--p-text-color);
}
.inst-body {
  padding: 0 14px 12px 58px;
  background: var(--p-surface-100);
}
.dep-section { margin-top: 8px; }
.dep-sub-label {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600;
  color: var(--p-text-muted-color);
  margin-bottom: 4px;
}
.mig-row, .entry-row {
  display: flex; align-items: center; gap: 8px;
  padding: 3px 0;
}
.kind-tag {
  font-family: 'JetBrains Mono', monospace; font-size: 9px;
  background: var(--p-surface-200); color: var(--p-text-color);
  padding: 1px 5px; border-radius: 3px;
  min-width: 80px; text-align: center;
}
.status-tag {
  font-size: 9px; font-weight: 600;
  padding: 1px 5px; border-radius: 3px;
}
.status-tag.applied { background: color-mix(in srgb, var(--p-success-500) 15%, transparent); color: var(--p-success-500); }
.status-tag.pending { background: color-mix(in srgb, var(--p-warn-500) 18%, transparent); color: var(--p-warn-500); }
.status-tag.unknown { background: var(--p-surface-200); color: var(--p-text-muted-color); }

.row-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 26px; height: 26px;
  border-radius: 6px;
  background: transparent;
  border: 0; cursor: pointer;
}
.row-btn:hover { background: var(--p-surface-200); }

/* ---------- Drawer ---------- */
.drawer-overlay {
  position: fixed; inset: 0; z-index: 9000;
  background: rgba(0,0,0,0.4);
  display: flex; justify-content: flex-end;
  animation: drawer-fade 0.15s ease-out;
}
.drawer {
  width: 520px;
  max-width: 100vw;
  height: 100%;
  background: var(--p-content-background);
  display: flex; flex-direction: column;
  border-left: 1px solid var(--p-content-border-color);
  box-shadow: -10px 0 40px rgba(0,0,0,0.18);
  animation: drawer-slide 0.18s ease-out;
}
@keyframes drawer-fade { from { opacity: 0; } to { opacity: 1; } }
@keyframes drawer-slide { from { transform: translateX(40px); opacity: 0.5; } to { transform: translateX(0); opacity: 1; } }
.drawer-head {
  display: flex; align-items: flex-start; gap: 14px;
  padding: 18px 18px 12px;
  position: relative;
}
.drawer-icon {
  width: 64px; height: 64px;
  border-radius: 14px;
  display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--accent) 14%, transparent);
  color: var(--accent);
  flex-shrink: 0;
}
.drawer-name {
  font-size: 16px; font-weight: 700;
  color: var(--p-text-color);
}
.drawer-org {
  font-size: 11px; font-family: 'JetBrains Mono', monospace;
  color: var(--p-text-muted-color);
  margin-top: 2px;
}
.drawer-desc {
  font-size: 12px; line-height: 1.5;
  color: var(--p-text-color);
  margin: 8px 0 0;
}
.drawer-close {
  position: absolute; top: 12px; right: 12px;
  width: 28px; height: 28px;
  border-radius: 6px;
  display: flex; align-items: center; justify-content: center;
  background: transparent; border: 0; cursor: pointer;
  color: var(--p-text-muted-color);
}
.drawer-close:hover { background: var(--p-surface-100); color: var(--p-text-color); }

.drawer-cta {
  display: flex; gap: 8px; padding: 4px 18px 16px;
  border-bottom: 1px solid var(--p-content-border-color);
}
.primary-cta {
  flex: 1;
  display: inline-flex; align-items: center; justify-content: center; gap: 6px;
  padding: 8px 16px;
  font-size: 12px; font-weight: 600;
  background: var(--accent); color: white;
  border: 0; border-radius: 8px; cursor: pointer;
}
.primary-cta:hover { opacity: 0.92; }
.cta-version {
  font-size: 10px; opacity: 0.85;
  font-family: 'JetBrains Mono', monospace;
  background: rgba(255,255,255,0.15);
  padding: 1px 6px; border-radius: 4px;
}
.ghost-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 6px 12px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  cursor: pointer;
}
.ghost-btn:hover { background: var(--p-surface-200); }

.drawer-tabs {
  display: flex; gap: 0;
  padding: 0 18px;
  border-bottom: 1px solid var(--p-content-border-color);
}
.drawer-tab {
  padding: 10px 14px;
  background: transparent;
  border: 0; border-bottom: 2px solid transparent;
  color: var(--p-text-muted-color);
  font-size: 11px; font-weight: 600;
  cursor: pointer;
}
.drawer-tab:hover { color: var(--p-text-color); }
.drawer-tab.active {
  color: var(--accent);
  border-bottom-color: var(--accent);
}

.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px 18px;
}

.kv-grid { display: flex; flex-direction: column; gap: 8px; }
.kv-row {
  display: grid; grid-template-columns: 90px 1fr;
  gap: 12px;
  font-size: 12px;
}
.kv-row.align-start { align-items: flex-start; }
.kv-key {
  color: var(--p-text-muted-color);
  font-size: 11px;
}
.kv-val { color: var(--p-text-color); word-break: break-word; }

.keyword-chip {
  display: inline-block;
  padding: 1px 8px;
  font-size: 10px;
  background: color-mix(in srgb, var(--accent) 12%, transparent);
  color: var(--accent);
  border-radius: 8px;
}

.deprecation-note {
  grid-column: 1 / -1;
  display: flex; gap: 6px;
  padding: 8px 10px;
  background: color-mix(in srgb, var(--p-warn-500) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-warn-500) 30%, transparent);
  border-radius: 6px;
  color: var(--p-warn-500);
  font-size: 11px;
}

.ver-block {
  border-top: 1px solid var(--p-content-border-color);
}
.ver-block:first-child { border-top: 0; }
.ver-row {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 0;
  cursor: pointer;
}
.ver-block.expanded { background: color-mix(in srgb, var(--p-surface-100) 60%, transparent); }
.ver-body {
  padding: 4px 4px 14px;
  display: flex; flex-direction: column; gap: 12px;
}
.ver-section { display: flex; flex-direction: column; gap: 6px; }
.ver-section-title {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600;
  color: var(--p-text-muted-color);
}
.release-notes {
  font-size: 11px; line-height: 1.5;
  color: var(--p-text-color);
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  padding: 8px 10px;
  white-space: pre-wrap;
  max-height: 220px; overflow-y: auto;
}
.ver-meta-line { display: flex; gap: 8px; align-items: baseline; font-size: 11px; }
.ver-meta-key { color: var(--p-text-muted-color); min-width: 90px; }
.protected-badge {
  font-size: 8px; font-weight: 700;
  padding: 1px 5px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-info-500) 15%, transparent);
  color: var(--p-info-500);
}

.ov-block {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid var(--p-content-border-color);
}
.ov-block-head {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; font-weight: 600;
  color: var(--p-text-color);
  margin-bottom: 8px;
}
.kind-chip {
  display: inline-block;
  padding: 1px 6px;
  font-size: 9px;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  border-radius: 3px;
}
.kind-chip.mono { font-family: 'JetBrains Mono', monospace; }

.dep-list { display: flex; flex-direction: column; gap: 2px; }
.dep-line {
  display: flex; align-items: center; gap: 10px;
  padding: 4px 0;
  font-size: 11px;
  border-top: 1px dashed var(--p-content-border-color);
}
.dep-line:first-child { border-top: 0; }

.readme-meta {
  display: flex; align-items: center; gap: 4px;
  padding: 4px 10px;
  margin-bottom: 12px;
  border-radius: 4px;
  background: var(--p-surface-100);
  font-size: 10px;
  color: var(--p-text-muted-color);
}
.readme-body {
  font-size: 12px;
  line-height: 1.6;
  color: var(--p-text-color);
  word-break: break-word;
}
.readme-body :deep(.rm-h),
.readme-body :deep(h1),
.readme-body :deep(h2),
.readme-body :deep(h3),
.readme-body :deep(h4),
.readme-body :deep(h5),
.readme-body :deep(h6) {
  font-weight: 700;
  color: var(--p-text-color);
  line-height: 1.3;
  margin: 16px 0 8px;
}
.readme-body :deep(h1) { font-size: 18px; border-bottom: 1px solid var(--p-content-border-color); padding-bottom: 6px; }
.readme-body :deep(h2) { font-size: 15px; border-bottom: 1px solid var(--p-content-border-color); padding-bottom: 4px; }
.readme-body :deep(h3) { font-size: 13px; }
.readme-body :deep(h4) { font-size: 12px; color: var(--p-text-muted-color); }
.readme-body :deep(.rm-p),
.readme-body :deep(p) { margin: 0 0 10px; }
.readme-body :deep(.rm-link),
.readme-body :deep(a) { color: var(--p-info-500); text-decoration: none; }
.readme-body :deep(.rm-link:hover),
.readme-body :deep(a:hover) { text-decoration: underline; }
.readme-body :deep(.rm-img),
.readme-body :deep(img) { max-width: 100%; height: auto; border-radius: 4px; margin: 6px 0; }
.readme-body :deep(.rm-pre),
.readme-body :deep(pre) {
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 10px 14px;
  overflow-x: auto;
  margin: 8px 0;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  line-height: 1.55;
}
.readme-body :deep(.rm-code),
.readme-body :deep(code) {
  background: var(--p-surface-100);
  padding: 1px 6px;
  border-radius: 3px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
}
.readme-body :deep(.rm-pre code),
.readme-body :deep(pre code) { background: none; padding: 0; }
.readme-body :deep(.rm-ul),
.readme-body :deep(.rm-ol),
.readme-body :deep(ul),
.readme-body :deep(ol) { margin: 6px 0 10px; padding-left: 22px; }
.readme-body :deep(li) { margin: 3px 0; }
.readme-body :deep(li.rm-uli) { list-style: disc; }
.readme-body :deep(li.rm-oli) { list-style: decimal; }
.readme-body :deep(.rm-hr),
.readme-body :deep(hr) { border: 0; border-top: 1px solid var(--p-content-border-color); margin: 16px 0; }
.readme-body :deep(blockquote) {
  border-left: 3px solid var(--p-info-500);
  padding: 4px 12px;
  margin: 8px 0;
  background: color-mix(in srgb, var(--p-info-500) 6%, transparent);
  color: var(--p-text-muted-color);
}
.readme-body :deep(table) { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 11px; }
.readme-body :deep(th), .readme-body :deep(td) {
  text-align: left; padding: 6px 10px; border: 1px solid var(--p-content-border-color);
}
.readme-body :deep(th) { background: var(--p-surface-100); font-weight: 600; }
.readme-body :deep(picture),
.readme-body :deep(picture img) { display: inline-block; max-width: 100%; }

.drawer-tab:disabled { opacity: 0.4; cursor: not-allowed; }
.latest-badge {
  font-size: 8px; font-weight: 700;
  padding: 1px 5px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-success-500) 15%, transparent);
  color: var(--p-success-500);
}
.yanked-badge {
  font-size: 8px; font-weight: 700;
  padding: 1px 5px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-danger-500) 15%, transparent);
  color: var(--p-danger-500);
}

/* ---------- Dialogs ---------- */
.overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0, 0, 0, 0.6);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
  overflow: auto;
}
.dialog {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 10px;
  padding: 18px;
  width: 420px; max-width: 90vw;
  max-height: calc(100dvh - 32px);
  overflow-y: auto;
  overscroll-behavior: contain;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}
.form-label {
  display: block;
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600;
  color: var(--p-text-muted-color);
  margin-bottom: 4px;
}
.form-input {
  width: 100%;
  padding: 6px 10px; font-size: 12px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px; outline: none;
}
.form-input:focus { border-color: var(--p-primary-color); }
.field-hint {
  margin-top: 5px;
  font-size: 10px;
  line-height: 1.35;
  color: var(--p-text-muted-color);
}
.form-check {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px;
  color: var(--p-text-color);
  margin-top: 12px;
  cursor: pointer;
}
.radio-row {
  display: flex; align-items: flex-start; gap: 8px;
  padding: 6px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 11px;
}
.radio-row:hover { background: var(--p-surface-100); }
.radio-row input { margin-top: 2px; }

.dialog-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 5px 14px;
  font-size: 11px;
  border-radius: 4px;
  cursor: pointer; border: 1px solid transparent;
}
.dialog-btn.cancel {
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border-color: var(--p-content-border-color);
}
.dialog-btn.cancel:hover { background: var(--p-surface-200); }
.dialog-btn.proceed {
  background: var(--p-info-500);
  color: white; font-weight: 600;
}
.dialog-btn.proceed:hover:not(:disabled) { opacity: 0.9; }
.dialog-btn.danger {
  background: var(--p-danger-500);
  color: white; font-weight: 600;
}
.dialog-btn.danger:hover:not(:disabled) { opacity: 0.9; }
.dialog-btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
