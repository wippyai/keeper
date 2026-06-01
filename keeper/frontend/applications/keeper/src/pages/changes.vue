<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import DiffViewer from '../components/DiffViewer.vue'
import {
  listChangesets, getChangeset, createChangeset,
  listChanges, dropChangeset, getChangeDiff,
  stateColors, stateIcons, opColors,
  type Changeset, type ChangeEntry, type ChangesResponse, type DiffContent
} from '../api/changesets'
import { listChangelog, listVersions, opColor, opIcon, type ChangelogEntry, type VersionSummary } from '../api/changelog'
import { kindColor, kindIcon, syncUndo, syncRedo, getSyncState } from '../api/registry'
import { listPlugins, type KeeperPlugin } from '../api/plugins'
import {
  listGitClusters, pullRequest, pushGitClusters, rebuildGit, setGitClusterDecision,
  type GitClusterSummary, type GitSnapshot, type PullRequestResult, type PullRequestStatus,
} from '../api/git'
import PluginHost from '../components/PluginHost.vue'

const api = useApi()
const host = useHost()
const instance = useWippy()
const route = useRoute()
const router = useRouter()

// ============================================================================
// Top-level tab
// ============================================================================
const mainTab = ref<'pending' | 'history' | 'versions' | 'git'>('pending')

// ============================================================================
// PENDING tab state (from changesets page)
// ============================================================================
const changesets = ref<Changeset[]>([])
const selected = ref<Changeset | null>(null)
const changes = ref<ChangesResponse | null>(null)
const csLoading = ref(true)
const error = ref<string | null>(null)
const creating = ref(false)
const newTitle = ref('')
const showCreate = ref(false)
const selectedChange = ref<ChangeEntry | null>(null)
const diffData = ref<DiffContent | null>(null)
const diffLoading = ref(false)

async function loadChangesets() {
  csLoading.value = true; error.value = null
  try {
    const res = await listChangesets(api)
    changesets.value = res.changesets || []
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { csLoading.value = false }
}

async function selectChangeset(cs: Changeset) {
  selected.value = cs; changes.value = null; selectedChange.value = null; diffData.value = null
  try {
    const res = await listChanges(api, cs.changeset_id)
    changes.value = res
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

async function refreshSelected() {
  if (!selected.value) return
  try {
    const res = await getChangeset(api, selected.value.changeset_id)
    selected.value = res.changeset
    const ch = await listChanges(api, selected.value!.changeset_id)
    changes.value = ch
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

async function selectChange(ch: ChangeEntry) {
  if (!selected.value) return
  selectedChange.value = ch; diffData.value = null; diffLoading.value = true
  try {
    const res = await getChangeDiff(api, selected.value.changeset_id, ch.target, ch.category, ch.part ?? null)
    diffData.value = res
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { diffLoading.value = false }
}

function partLabel(part?: string | null): string {
  if (part === 'definition') return 'meta'
  if (part === 'content') return 'source'
  return ''
}

function partColor(part?: string | null): string {
  if (part === 'definition') return 'var(--p-accent-500)'
  if (part === 'content') return 'var(--p-success-500)'
  return 'var(--p-text-muted-color)'
}

function changeKey(ch: ChangeEntry, i: number): string {
  return `${i}-${ch.category}-${ch.target}-${ch.part ?? ''}-${ch.op}`
}

async function handleCreate() {
  if (!newTitle.value.trim()) return
  creating.value = true; error.value = null
  try {
    const res = await createChangeset(api, { title: newTitle.value.trim(), kind: 'manual' })
    newTitle.value = ''; showCreate.value = false
    await loadChangesets()
    if (res.changeset) await selectChangeset(res.changeset)
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { creating.value = false }
}

async function handleDrop() {
  if (!selected.value) return
  try {
    await dropChangeset(api, selected.value.changeset_id, 'dropped via UI')
    selected.value = null; changes.value = null; selectedChange.value = null; diffData.value = null
    await loadChangesets()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

const registryChanges = computed<ChangeEntry[]>(() => changes.value?.computed?.registry || [])
const filesystemChanges = computed<ChangeEntry[]>(() => changes.value?.computed?.filesystem || [])
const regCount = computed(() => registryChanges.value.length)
const fsCount = computed(() => filesystemChanges.value.length)
const allChanges = computed<ChangeEntry[]>(() => [...registryChanges.value, ...filesystemChanges.value])

const showRegistry = ref(true)
const showFilesystem = ref(true)

function splitTarget(ch: ChangeEntry): { leaf: string; parent: string } {
  if (ch.category === 'registry') {
    const idx = ch.target.indexOf(':')
    if (idx < 0) return { leaf: ch.target, parent: '' }
    return { leaf: ch.target.slice(idx + 1), parent: ch.target.slice(0, idx) }
  }
  const idx = ch.target.lastIndexOf('/')
  if (idx < 0) return { leaf: ch.target, parent: '' }
  return { leaf: ch.target.slice(idx + 1), parent: ch.target.slice(0, idx) }
}
// Plugin discovery
const plugins = ref<KeeperPlugin[]>([])
const activePlugin = ref<KeeperPlugin | null>(null)

async function loadPlugins() {
  plugins.value = (await listPlugins(api)).filter(p => p.slot === 'changes.detail')
}

const liveStates = new Set(['open', 'editing', 'review', 'accepted', 'rejected'])
const liveChangesets = computed(() => changesets.value.filter(w => liveStates.has(w.state)))
const closedChangesets = computed(() => changesets.value.filter(w => !liveStates.has(w.state)))
const showClosed = ref(false)
const listSearch = ref('')

const stateCounts = computed(() => {
  const counts: Record<string, number> = { open: 0, editing: 0, review: 0, accepted: 0, merged: 0, dropped: 0, rejected: 0 }
  for (const cs of changesets.value) {
    counts[cs.state] = (counts[cs.state] || 0) + 1
  }
  return counts
})

const filteredLive = computed(() => {
  const term = listSearch.value.toLowerCase().trim()
  if (!term) return liveChangesets.value
  return liveChangesets.value.filter(c => (c.title || '').toLowerCase().includes(term) || c.changeset_id.includes(term))
})
const filteredClosed = computed(() => {
  const term = listSearch.value.toLowerCase().trim()
  if (!term) return closedChangesets.value
  return closedChangesets.value.filter(c => (c.title || '').toLowerCase().includes(term) || c.changeset_id.includes(term))
})

async function selectById(id: string) {
  if (!id) return
  const existing = changesets.value.find(c => c.changeset_id === id)
  if (existing) { await selectChangeset(existing); return }
  try {
    const res = await getChangeset(api, id)
    if (res.changeset) { await selectChangeset(res.changeset) }
  } catch (e: unknown) {
    host.toast({
      severity: 'error',
      summary: 'Changeset not found',
      detail: e instanceof Error ? e.message : `Could not load changeset ${id}`,
      life: 4000,
    })
  }
}

watch(() => route.query.id, (id) => {
  if (typeof id === 'string' && id && (!selected.value || selected.value.changeset_id !== id)) {
    selectById(id)
  }
})

// ============================================================================
// HISTORY tab state (from changelog page)
// ============================================================================
// History shows timeline + versions table together (no sub-tabs)
const entries = ref<ChangelogEntry[]>([])
const versions = ref<VersionSummary[]>([])
const histLoading = ref(false)
const filterNs = ref('')
const filterOp = ref('')
const syncState = ref<{ current_version?: number } | null>(null)
const stats = ref<{ total: number; versions: number; namespaces: number } | null>(null)
const undoing = ref(false)
const redoing = ref(false)

const namespaces = computed(() => {
  const ns = new Set<string>()
  entries.value.forEach(e => { if (e.namespace) ns.add(e.namespace) })
  return Array.from(ns).sort()
})

const groupedEntries = computed(() => {
  const groups: { version: number; timestamp: string; user_id: string; entries: ChangelogEntry[] }[] = []
  const map = new Map<string, ChangelogEntry[]>()
  const filtered = entries.value.filter(e => {
    if (filterNs.value && e.namespace !== filterNs.value) return false
    if (filterOp.value && e.op_type !== filterOp.value) return false
    return true
  })
  for (const e of filtered) {
    const key = `${e.version}-${e.request_id}`
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(e)
  }
  for (const [, list] of map) {
    groups.push({ version: list[0].version, timestamp: list[0].timestamp, user_id: list[0].user_id, entries: list })
  }
  groups.sort((a, b) => b.version - a.version)
  return groups
})

async function fetchHistory() {
  histLoading.value = true
  try {
    const [clData, vData, stateData] = await Promise.all([
      listChangelog(api, { limit: 500 }), listVersions(api), getSyncState(api),
    ])
    entries.value = clData.entries || []; versions.value = vData.versions || []
    stats.value = vData.stats || null; syncState.value = stateData.registry || null
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  histLoading.value = false
}

async function doUndo() { undoing.value = true; try { await syncUndo(api); await fetchHistory() } catch (e: any) { error.value = e?.response?.data?.error || 'Undo failed' } undoing.value = false }
async function doRedo() { redoing.value = true; try { await syncRedo(api); await fetchHistory() } catch (e: any) { error.value = e?.response?.data?.error || 'Redo failed' } redoing.value = false }

// ============================================================================
// GIT / PR tab state
// ============================================================================
const gitLoading = ref(false)
const gitSnapshot = ref<GitSnapshot | null>(null)
const prStatus = ref<PullRequestStatus | null>(null)
const prResult = ref<PullRequestResult | null>(null)
const prRunning = ref(false)
const prForm = ref({
  base_branch: 'main',
  head_branch: '',
  title: '',
  body: '',
  draft: true,
  commit_message: '',
  paths_text: '',
})

const gitClusters = computed<GitClusterSummary[]>(() => gitSnapshot.value?.clusters || [])
const approvedPushableClusters = computed(() => gitClusters.value.filter(c => c.decision === 'approved' && c.pushable === true))

async function loadGitClusters() {
  gitLoading.value = true
  try {
    gitSnapshot.value = await listGitClusters(api)
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  } finally {
    gitLoading.value = false
  }
}

async function rebuildGitClusters() {
  gitLoading.value = true
  try {
    await rebuildGit(api, { mode: 'manual', change_source: 'mixed' })
    await loadGitClusters()
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  } finally {
    gitLoading.value = false
  }
}

async function setClusterDecision(cluster: GitClusterSummary, decision: string) {
  try {
    await setGitClusterDecision(api, cluster.cluster_id, decision)
    await loadGitClusters()
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  }
}

async function dryRunPushApproved() {
  const ids = approvedPushableClusters.value.map(c => c.cluster_id)
  if (ids.length === 0) return
  try {
    const res = await pushGitClusters(api, ids, 'Keeper git dry-run', true)
    prResult.value = {
      dry_run: true,
      commands: [{ label: 'keeper governance push dry-run', command: JSON.stringify(res.results || res), mutates: false }],
    }
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  }
}

function prPaths(): string[] {
  return prForm.value.paths_text
    .split('\n')
    .map(s => s.trim())
    .filter(Boolean)
}

async function inspectPrStatus() {
  prRunning.value = true
  try {
    const res = await pullRequest(api, { action: 'status' })
    prStatus.value = res.result as unknown as PullRequestStatus
    if (!prForm.value.head_branch && prStatus.value?.current_branch) {
      prForm.value.head_branch = prStatus.value.current_branch
    }
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  } finally {
    prRunning.value = false
  }
}

async function planPr() {
  prRunning.value = true
  try {
    const res = await pullRequest(api, {
      action: 'plan',
      dry_run: true,
      base_branch: prForm.value.base_branch,
      head_branch: prForm.value.head_branch || undefined,
      title: prForm.value.title,
      body: prForm.value.body,
      draft: prForm.value.draft,
      commit_message: prForm.value.commit_message || undefined,
      paths: prPaths(),
    })
    prResult.value = res.result
    prStatus.value = res.result.status || prStatus.value
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  } finally {
    prRunning.value = false
  }
}

async function createPr() {
  prRunning.value = true
  try {
    const res = await pullRequest(api, {
      action: prForm.value.commit_message ? 'full' : 'create',
      dry_run: false,
      confirm: true,
      base_branch: prForm.value.base_branch,
      head_branch: prForm.value.head_branch || undefined,
      title: prForm.value.title,
      body: prForm.value.body,
      draft: prForm.value.draft,
      commit_message: prForm.value.commit_message || undefined,
      paths: prPaths(),
    })
    prResult.value = res.result
  } catch (e: any) {
    error.value = e?.response?.data?.error || e.message
  } finally {
    prRunning.value = false
  }
}

// ============================================================================
// Shared
// ============================================================================
function timeAgo(ts: string) {
  if (!ts) return ''
  try {
    const d = new Date(ts)
    const secs = Math.floor((Date.now() - d.getTime()) / 1000)
    if (secs < 60) return 'just now'
    if (secs < 3600) return Math.floor(secs / 60) + 'm ago'
    if (secs < 86400) return Math.floor(secs / 3600) + 'h ago'
    return Math.floor(secs / 86400) + 'd ago'
  } catch { return '' }
}

let unsubChangeset: (() => void) | null = null

onMounted(async () => {
  await loadChangesets()
  fetchHistory()
  loadPlugins()
  const pid = route.params.id
  const qid = route.query.id
  const rid = typeof pid === 'string' && pid ? pid : (typeof qid === 'string' ? qid : '')
  if (rid) selectById(rid)
  unsubChangeset = instance.on('keeper.changeset', (evt: any) => {
    const data = evt?.data || evt
    if (!data?.event) return
    loadChangesets()
    if (selected.value && data.changeset_id === selected.value.changeset_id) refreshSelected()
  })
})

onUnmounted(() => {
  unsubChangeset?.()
})

function onSelect(cs: Changeset) {
  selectChangeset(cs)
  if (route.params.id !== cs.changeset_id) {
    router.replace({ path: `/changes/${cs.changeset_id}` })
  }
}
</script>

<template>
  <div class="flex flex-col h-full overflow-hidden" style="color: var(--p-text-color)">
    <!-- Header -->
    <div class="flex items-center justify-between px-5 py-2.5 flex-shrink-0" style="border-bottom: 1px solid var(--p-content-border-color)">
      <div class="flex items-center gap-2.5">
        <Icon icon="tabler:git-branch" class="w-4.5 h-4.5" style="color: var(--p-primary-color)" />
        <span class="text-sm font-semibold">Changes</span>

        <!-- Version + stats always visible -->
        <span v-if="syncState" class="text-[11px] font-mono font-bold px-2 py-0.5 rounded"
          style="background: var(--p-primary-color)18; color: var(--p-primary-color)">
          v{{ syncState.current_version }}
        </span>
        <span v-if="stats" class="text-[10px]" style="color: var(--p-text-muted-color)">
          {{ stats.total }} changes &middot; {{ stats.versions }} versions
        </span>
      </div>

      <div class="flex items-center gap-1.5">
        <button @click="mainTab = 'pending'"
          class="px-2.5 py-1 rounded text-[11px] font-medium transition-colors"
          :style="{ background: mainTab === 'pending' ? 'var(--p-primary-color)' + '18' : 'transparent', color: mainTab === 'pending' ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)' }">
          Pending
        </button>
        <button @click="mainTab = 'history'"
          class="px-2.5 py-1 rounded text-[11px] font-medium transition-colors"
          :style="{ background: mainTab === 'history' ? 'var(--p-primary-color)' + '18' : 'transparent', color: mainTab === 'history' ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)' }">
          History
        </button>
        <button @click="mainTab = 'versions'"
          class="px-2.5 py-1 rounded text-[11px] font-medium transition-colors"
          :style="{ background: mainTab === 'versions' ? 'var(--p-primary-color)' + '18' : 'transparent', color: mainTab === 'versions' ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)' }">
          Versions
        </button>
        <button @click="mainTab = 'git'; if (!gitSnapshot) loadGitClusters(); if (!prStatus) inspectPrStatus()"
          class="px-2.5 py-1 rounded text-[11px] font-medium transition-colors"
          :style="{ background: mainTab === 'git' ? 'var(--p-primary-color)' + '18' : 'transparent', color: mainTab === 'git' ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)' }">
          Git / PR
        </button>
        <div class="w-px h-4 mx-1" style="background: var(--p-content-border-color)" />
        <button @click="doUndo" :disabled="undoing" class="flex items-center gap-1 px-2 py-1 rounded text-[10px] hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)">
          <Icon :icon="undoing ? 'tabler:loader-2' : 'tabler:arrow-back-up'" class="w-3 h-3" :class="{ 'animate-spin': undoing }" /> Undo
        </button>
        <button @click="doRedo" :disabled="redoing" class="flex items-center gap-1 px-2 py-1 rounded text-[10px] hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)">
          <Icon :icon="redoing ? 'tabler:loader-2' : 'tabler:arrow-forward-up'" class="w-3 h-3" :class="{ 'animate-spin': redoing }" /> Redo
        </button>
        <Button @click="fetchHistory" :disabled="histLoading" class="k-btn-icon !rounded">
          <Icon icon="tabler:refresh" class="w-3 h-3" />
        </Button>
      </div>
    </div>

    <!-- Create bar -->
    <div v-if="showCreate && mainTab === 'pending'" class="flex items-center gap-2 px-5 py-2 flex-shrink-0" style="background: var(--p-surface-50); border-bottom: 1px solid var(--p-content-border-color)">
      <input v-model="newTitle" @keydown.enter="handleCreate" placeholder="Changeset title..."
        class="flex-1 px-2.5 py-1.5 rounded text-xs"
        style="background: var(--p-surface-100); border: 1px solid var(--p-surface-300); color: var(--p-text-color)" autofocus />
      <button @click="handleCreate" :disabled="creating || !newTitle.trim()"
        class="px-3 py-1.5 rounded text-xs font-medium"
        :style="{ background: 'var(--p-primary-color)', color: 'white', opacity: !newTitle.trim() ? 0.4 : 1 }">Create</button>
      <button @click="showCreate = false" class="px-2 py-1.5 rounded text-xs" style="color: var(--p-text-muted-color)">Cancel</button>
    </div>

    <!-- Error -->
    <div v-if="error" class="mx-5 mt-2 px-3 py-1.5 rounded text-[11px] flex items-center justify-between bg-danger-500/10 text-danger-500 border border-danger-500/10">
      <span>{{ error }}</span>
      <button @click="error = null" class="ml-2 opacity-60 hover:opacity-100">&times;</button>
    </div>

    <!-- ======================== PENDING TAB ======================== -->
    <div v-if="mainTab === 'pending'" class="flex flex-1 min-h-0">
      <!-- Sidebar -->
      <div class="w-64 flex-shrink-0 overflow-y-auto flex flex-col" style="border-right: 1px solid var(--p-content-border-color)">
        <div class="px-3 pt-2 pb-2 space-y-1.5 flex-shrink-0" style="background: var(--p-surface-50); position: sticky; top: 0; z-index: 1; border-bottom: 1px solid var(--p-surface-100)">
          <button @click="showCreate = !showCreate"
            class="w-full flex items-center justify-center gap-1 px-2 py-1.5 rounded text-[11px] font-medium"
            style="background: var(--p-primary-color); color: var(--p-primary-contrast-color)">
            <Icon icon="tabler:plus" class="w-3 h-3" /> New Changeset
          </button>
          <div class="search-wrap w-full">
            <Icon icon="tabler:search" class="search-icon" />
            <input v-model="listSearch" placeholder="Filter changesets..." class="search-input w-full" />
          </div>
          <div class="flex items-center gap-1 flex-wrap">
            <span v-if="stateCounts.open" class="text-[9px] px-1.5 py-0.5 rounded font-medium"
              :style="{ background: stateColors.open + '22', color: stateColors.open }">
              {{ stateCounts.open }} open
            </span>
            <span v-if="stateCounts.editing" class="text-[9px] px-1.5 py-0.5 rounded font-medium"
              :style="{ background: stateColors.editing + '22', color: stateColors.editing }">
              {{ stateCounts.editing }} editing
            </span>
            <span v-if="stateCounts.review" class="text-[9px] px-1.5 py-0.5 rounded font-medium"
              :style="{ background: stateColors.review + '22', color: stateColors.review }">
              {{ stateCounts.review }} review
            </span>
            <span v-if="stateCounts.merged" class="text-[9px] px-1.5 py-0.5 rounded"
              style="background: var(--p-surface-100); color: var(--p-text-muted-color)">
              {{ stateCounts.merged }} merged
            </span>
            <span v-if="stateCounts.dropped" class="text-[9px] px-1.5 py-0.5 rounded"
              style="background: var(--p-surface-100); color: var(--p-text-muted-color)">
              {{ stateCounts.dropped }} dropped
            </span>
          </div>
        </div>
        <div class="flex-1 overflow-y-auto">
          <div v-if="csLoading" class="p-3 text-[11px]" style="color: var(--p-text-muted-color)">Loading...</div>
          <template v-if="filteredLive.length > 0">
            <div class="px-3 pt-2 pb-1 text-[10px] font-medium uppercase tracking-wider" style="color: var(--p-text-muted-color)">
              Active <span class="ml-1 opacity-60">{{ filteredLive.length }}</span>
            </div>
            <div v-for="cs in filteredLive" :key="cs.changeset_id" @click="onSelect(cs)"
              class="flex items-center gap-2 px-3 py-2 cursor-pointer transition-colors"
              :style="{ background: selected?.changeset_id === cs.changeset_id ? 'var(--p-surface-100)' : 'transparent', borderLeft: selected?.changeset_id === cs.changeset_id ? '2px solid var(--p-primary-color)' : '2px solid transparent' }">
              <Icon :icon="stateIcons[cs.state] || 'tabler:circle'" class="w-3 h-3 flex-shrink-0" :style="{ color: stateColors[cs.state] }" />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] font-medium truncate" style="color: var(--p-text-color)" :title="cs.title">{{ cs.title }}</div>
                <div class="text-[10px] flex items-center gap-1.5" style="color: var(--p-text-muted-color)">
                  <span :style="{ color: stateColors[cs.state] }">{{ cs.state }}</span>
                  <span>&middot;</span>
                  <span>{{ timeAgo(cs.updated_at) }}</span>
                  <span v-if="cs.kind === 'session'" class="ml-auto text-[9px] opacity-70">task</span>
                </div>
              </div>
            </div>
          </template>
          <template v-if="filteredClosed.length > 0">
            <button @click="showClosed = !showClosed"
              class="w-full flex items-center gap-1.5 px-3 pt-3 pb-1 text-[10px] font-medium uppercase tracking-wider hover:brightness-125"
              style="color: var(--p-text-muted-color)">
              <Icon :icon="showClosed ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3" />
              <span>Closed <span class="ml-1 opacity-60">{{ filteredClosed.length }}</span></span>
            </button>
            <template v-if="showClosed">
              <div v-for="cs in filteredClosed" :key="cs.changeset_id" @click="onSelect(cs)"
                class="flex items-center gap-2 px-3 py-1.5 cursor-pointer transition-colors opacity-60"
                :style="{ background: selected?.changeset_id === cs.changeset_id ? 'var(--p-surface-100)' : 'transparent', borderLeft: selected?.changeset_id === cs.changeset_id ? '2px solid var(--p-primary-color)' : '2px solid transparent', opacity: selected?.changeset_id === cs.changeset_id ? 1 : 0.6 }">
                <Icon :icon="stateIcons[cs.state] || 'tabler:circle'" class="w-3 h-3 flex-shrink-0" :style="{ color: stateColors[cs.state] }" />
                <div class="flex-1 min-w-0">
                  <div class="text-[11px] truncate" style="color: var(--p-text-color)" :title="cs.title">{{ cs.title }}</div>
                  <div class="text-[10px]" style="color: var(--p-text-muted-color)">
                    <span :style="{ color: stateColors[cs.state] }">{{ cs.state }}</span>
                    <span class="mx-1">&middot;</span>
                    <span>{{ timeAgo(cs.updated_at) }}</span>
                  </div>
                </div>
              </div>
            </template>
          </template>
          <div v-if="!csLoading && changesets.length === 0" class="p-4 text-[11px] text-center" style="color: var(--p-text-muted-color)">No changesets yet</div>
          <div v-else-if="!csLoading && filteredLive.length === 0 && filteredClosed.length === 0" class="p-4 text-[11px] text-center" style="color: var(--p-text-muted-color)">No matches</div>
        </div>
      </div>

      <!-- Detail -->
      <div v-if="!selected" class="flex-1 flex items-center justify-center" style="color: var(--p-text-muted-color)">
        <div class="text-center">
          <Icon icon="tabler:git-branch" class="w-8 h-8 mx-auto mb-1 opacity-15" />
          <div class="text-[11px]">Select a changeset</div>
        </div>
      </div>
      <div v-else class="flex-1 flex flex-col min-h-0 overflow-hidden">
        <div class="flex items-center justify-between px-4 py-2 flex-shrink-0" style="border-bottom: 1px solid var(--p-surface-100)">
          <div class="flex items-center gap-2.5">
            <span class="text-[13px] font-semibold" style="color: var(--p-text-color)">{{ selected.title }}</span>
            <span class="text-[10px] px-1.5 py-0.5 rounded font-medium" :style="{ background: stateColors[selected.state] + '18', color: stateColors[selected.state] }">{{ selected.state }}</span>
          </div>
          <div class="flex items-center gap-1.5">
            <Button @click="refreshSelected" class="k-btn-icon !rounded" title="Refresh">
              <Icon icon="tabler:refresh" class="w-3.5 h-3.5" />
            </Button>
            <button v-if="selected.state !== 'dropped' && selected.state !== 'merged'" @click="handleDrop"
              class="px-2 py-1 rounded text-[10px] font-medium hover:bg-danger-500/20 text-danger-500">
              Drop
            </button>
          </div>
        </div>
        <div class="flex items-center gap-3 px-4 py-1.5 flex-shrink-0 text-[10px]" style="border-bottom: 1px solid var(--p-surface-100); color: var(--p-text-muted-color)">
          <span v-if="selected.actor_id" class="flex items-center gap-1"><Icon icon="tabler:user" class="w-2.5 h-2.5" /> {{ selected.actor_id }}</span>
          <span class="flex items-center gap-1"><Icon icon="tabler:clock" class="w-2.5 h-2.5" /> {{ timeAgo(selected.created_at) }}</span>
        </div>
        <div class="flex items-center gap-2 px-4 py-2 flex-shrink-0" style="border-bottom: 1px solid var(--p-surface-100)">
          <div class="flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-100)">
            <Icon icon="tabler:database" class="w-2.5 h-2.5 text-accent-500" /> <span>{{ regCount }} registry</span>
          </div>
          <div class="flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-100)">
            <Icon icon="tabler:file-code" class="w-2.5 h-2.5 text-info-500" /> <span>{{ fsCount }} filesystem</span>
          </div>
        </div>
        <div class="flex flex-1 min-h-0 overflow-hidden">
          <div class="w-72 flex-shrink-0 overflow-y-auto" style="border-right: 1px solid var(--p-surface-100)">
            <div v-if="regCount === 0 && fsCount === 0" class="p-3 text-[10px]" style="color: var(--p-text-muted-color)">No pending changes</div>

            <template v-if="regCount > 0">
              <button @click="showRegistry = !showRegistry"
                class="w-full flex items-center gap-1.5 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wider hover:bg-[var(--kp-hover-bg)]"
                style="background: var(--p-surface-50); border-bottom: 1px solid var(--p-surface-100); color: var(--p-text-muted-color); position: sticky; top: 0; z-index: 1">
                <Icon :icon="showRegistry ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3" />
                <Icon icon="tabler:database" class="w-3 h-3 text-accent-500" />
                <span>Registry entries</span>
                <span class="ml-auto opacity-70">{{ regCount }}</span>
              </button>
              <template v-if="showRegistry">
                <div v-for="(ch, i) in registryChanges" :key="changeKey(ch, i)" @click="selectChange(ch)"
                  class="flex items-start gap-2 px-3 py-1.5 cursor-pointer transition-colors"
                  :title="ch.part ? `${ch.target} (${partLabel(ch.part)})` : ch.target"
                  :style="{ background: selectedChange === ch ? 'var(--p-surface-100)' : 'transparent', borderLeft: selectedChange === ch ? '2px solid var(--p-primary-color)' : '2px solid transparent' }">
                  <div class="flex flex-col items-center gap-0.5 pt-0.5 flex-shrink-0">
                    <Icon icon="tabler:database" class="w-3 h-3 text-accent-500" />
                    <span class="text-[8px] font-bold uppercase leading-none" :style="{ color: opColors[ch.op] }">
                      {{ ch.op === 'create' ? 'A' : ch.op === 'delete' ? 'D' : 'M' }}
                    </span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-1 min-w-0">
                      <span class="font-mono text-[10px] truncate flex-1" style="color: var(--p-text-color)">
                        {{ splitTarget(ch).leaf }}
                      </span>
                      <span v-if="ch.part" class="text-[8px] font-semibold uppercase px-1 py-px rounded flex-shrink-0 leading-none"
                        :style="{ background: partColor(ch.part) + '22', color: partColor(ch.part) }">
                        {{ partLabel(ch.part) }}
                      </span>
                    </div>
                    <div v-if="splitTarget(ch).parent" class="font-mono text-[9px] truncate" style="color: var(--p-text-muted-color)">
                      {{ splitTarget(ch).parent }}:
                    </div>
                  </div>
                </div>
              </template>
            </template>

            <template v-if="fsCount > 0">
              <button @click="showFilesystem = !showFilesystem"
                class="w-full flex items-center gap-1.5 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wider hover:bg-[var(--kp-hover-bg)]"
                style="background: var(--p-surface-50); border-top: 1px solid var(--p-surface-100); border-bottom: 1px solid var(--p-surface-100); color: var(--p-text-muted-color); position: sticky; top: 0; z-index: 1">
                <Icon :icon="showFilesystem ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3" />
                <Icon icon="tabler:file-code" class="w-3 h-3 text-info-500" />
                <span>Filesystem files</span>
                <span class="ml-auto opacity-70">{{ fsCount }}</span>
              </button>
              <template v-if="showFilesystem">
                <div v-for="(ch, i) in filesystemChanges" :key="changeKey(ch, i)" @click="selectChange(ch)"
                  class="flex items-start gap-2 px-3 py-1.5 cursor-pointer transition-colors"
                  :title="ch.target"
                  :style="{ background: selectedChange === ch ? 'var(--p-surface-100)' : 'transparent', borderLeft: selectedChange === ch ? '2px solid var(--p-primary-color)' : '2px solid transparent' }">
                  <div class="flex flex-col items-center gap-0.5 pt-0.5 flex-shrink-0">
                    <Icon icon="tabler:file-code" class="w-3 h-3 text-info-500" />
                    <span class="text-[8px] font-bold uppercase leading-none" :style="{ color: opColors[ch.op] }">
                      {{ ch.op === 'create' ? 'A' : ch.op === 'delete' ? 'D' : 'M' }}
                    </span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="font-mono text-[10px] truncate" dir="rtl" style="color: var(--p-text-color)">
                      {{ splitTarget(ch).leaf }}
                    </div>
                    <div v-if="splitTarget(ch).parent" class="font-mono text-[9px] truncate" dir="rtl" style="color: var(--p-text-muted-color)">
                      {{ splitTarget(ch).parent }}/
                    </div>
                  </div>
                </div>
              </template>
            </template>
          </div>
          <div class="flex-1 flex flex-col min-h-0 overflow-hidden">
            <!-- Plugin tabs (if any registered for this slot) -->
            <div v-if="plugins.length > 0" class="flex items-center gap-1 px-3 py-1 flex-shrink-0" style="border-bottom: 1px solid var(--p-surface-100)">
              <button @click="activePlugin = null"
                class="px-2 py-0.5 rounded text-[10px] transition-colors"
                :style="{ color: !activePlugin ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)', background: !activePlugin ? 'var(--p-primary-color)18' : 'transparent' }">
                Diff
              </button>
              <button v-for="p in plugins" :key="p.id" @click="activePlugin = p"
                class="flex items-center gap-1 px-2 py-0.5 rounded text-[10px] transition-colors"
                :style="{ color: activePlugin?.id === p.id ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)', background: activePlugin?.id === p.id ? 'var(--p-primary-color)18' : 'transparent' }">
                <Icon v-if="p.icon" :icon="p.icon" class="w-2.5 h-2.5" />
                {{ p.title }}
              </button>
            </div>

            <!-- Plugin panel -->
            <PluginHost v-if="activePlugin" :page-id="activePlugin.id" :title="activePlugin.title" class="flex-1" />

            <!-- Diff panel (default) -->
            <template v-else>
            <div v-if="!selectedChange" class="flex-1 flex items-center justify-center" style="color: var(--p-text-muted-color)">
              <div class="text-center text-[11px]">
                <Icon icon="tabler:arrows-diff" class="w-6 h-6 mx-auto mb-1 opacity-15" />
                <div>Select a change to view diff</div>
              </div>
            </div>
            <template v-else>
              <div class="flex items-center justify-between px-3 py-1.5 flex-shrink-0" style="background: var(--p-surface-50); border-bottom: 1px solid var(--p-surface-100)">
                <div class="flex items-center gap-2 text-[11px] min-w-0">
                  <span class="px-1 py-0.5 rounded text-[9px] font-semibold uppercase" :style="{ background: opColors[selectedChange.op] + '20', color: opColors[selectedChange.op] }">{{ selectedChange.op }}</span>
                  <span class="font-mono truncate" style="color: var(--p-text-color)">{{ selectedChange.target }}</span>
                  <span v-if="selectedChange.part" class="text-[9px] font-semibold uppercase px-1.5 py-0.5 rounded flex-shrink-0"
                    :style="{ background: partColor(selectedChange.part) + '22', color: partColor(selectedChange.part) }">
                    {{ partLabel(selectedChange.part) }}
                  </span>
                </div>
                <span v-if="diffData" class="text-[9px] px-1.5 py-0.5 rounded" style="background: var(--p-content-border-color); color: var(--p-text-muted-color)">{{ diffData.language }}</span>
              </div>
              <div v-if="diffLoading" class="flex-1 flex items-center justify-center"><span class="text-[11px]" style="color: var(--p-text-muted-color)">Loading...</span></div>
              <DiffViewer v-else-if="diffData" :baseline="diffData.baseline" :current="diffData.current" :language="diffData.language" class="flex-1" />
            </template>
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- ======================== GIT / PR TAB ======================== -->
    <div v-if="mainTab === 'git'" class="flex flex-1 min-h-0 overflow-hidden">
      <div class="w-[380px] flex-shrink-0 overflow-y-auto" style="border-right: 1px solid var(--p-content-border-color)">
        <div class="sticky top-0 z-10 px-3 py-2 flex items-center gap-2" style="background: var(--p-content-background); border-bottom: 1px solid var(--p-surface-100)">
          <button @click="rebuildGitClusters" :disabled="gitLoading" class="flex items-center gap-1 px-2 py-1 rounded text-[10px] font-medium" style="background: var(--p-primary-color); color: var(--p-primary-contrast-color)">
            <Icon :icon="gitLoading ? 'tabler:loader-2' : 'tabler:refresh'" class="w-3 h-3" :class="{ 'animate-spin': gitLoading }" />
            Rebuild
          </button>
          <button @click="loadGitClusters" :disabled="gitLoading" class="px-2 py-1 rounded text-[10px] hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)">Refresh</button>
          <button @click="dryRunPushApproved" :disabled="approvedPushableClusters.length === 0" class="ml-auto px-2 py-1 rounded text-[10px] hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-primary-color)">
            Dry-run push {{ approvedPushableClusters.length || '' }}
          </button>
        </div>

        <div v-if="gitLoading && gitClusters.length === 0" class="p-4 text-[11px]" style="color: var(--p-text-muted-color)">Loading git clusters...</div>
        <div v-else-if="gitClusters.length === 0" class="p-5 text-center text-[11px]" style="color: var(--p-text-muted-color)">
          <Icon icon="tabler:git-pull-request" class="w-7 h-7 mx-auto mb-1 opacity-15" />
          <div>No git review snapshot. Rebuild to scan changes.</div>
        </div>
        <div v-else class="divide-y" style="border-color: var(--p-surface-100)">
          <div v-for="cluster in gitClusters" :key="cluster.cluster_id" class="px-3 py-2">
            <div class="flex items-start gap-2">
              <Icon :icon="cluster.pushable ? 'tabler:circle-check' : 'tabler:circle-dashed'" class="w-3.5 h-3.5 mt-0.5" :style="{ color: cluster.pushable ? 'var(--p-success-500)' : 'var(--p-text-muted-color)' }" />
              <div class="flex-1 min-w-0">
                <div class="text-[11px] font-medium truncate" style="color: var(--p-text-color)" :title="cluster.title">{{ cluster.title }}</div>
                <div class="flex items-center gap-1.5 text-[9px] mt-0.5" style="color: var(--p-text-muted-color)">
                  <span>{{ cluster.change_count || cluster.stats?.total || 0 }} changes</span>
                  <span>&middot;</span>
                  <span>{{ cluster.source || 'mixed' }}</span>
                  <span v-if="cluster.verdict">&middot; {{ cluster.verdict }}</span>
                  <span v-if="cluster.rec_open"> &middot; {{ cluster.rec_open }} open recs</span>
                </div>
              </div>
              <select :value="cluster.decision" @change="setClusterDecision(cluster, ($event.target as HTMLSelectElement).value)"
                class="px-1.5 py-0.5 rounded text-[10px]" style="background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color)">
                <option value="pending">pending</option>
                <option value="approved">approved</option>
                <option value="skipped">skipped</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div class="flex-1 min-w-0 overflow-y-auto">
        <div class="px-5 py-3" style="border-bottom: 1px solid var(--p-surface-100)">
          <div class="flex items-center gap-2 mb-2">
            <Icon icon="tabler:git-pull-request" class="w-4 h-4" style="color: var(--p-primary-color)" />
            <span class="text-[13px] font-semibold">Pull request</span>
            <button @click="inspectPrStatus" :disabled="prRunning" class="ml-auto px-2 py-1 rounded text-[10px] hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)">Inspect</button>
          </div>
          <div v-if="prStatus" class="grid grid-cols-2 lg:grid-cols-4 gap-2 text-[10px]">
            <div class="px-2 py-1 rounded" style="background: var(--p-surface-50)"><span style="color: var(--p-text-muted-color)">Branch</span><div class="font-mono truncate">{{ prStatus.current_branch }}</div></div>
            <div class="px-2 py-1 rounded" style="background: var(--p-surface-50)"><span style="color: var(--p-text-muted-color)">Worktree</span><div :class="prStatus.dirty ? 'text-warn-500' : 'text-success-500'">{{ prStatus.dirty ? 'dirty' : 'clean' }}</div></div>
            <div class="px-2 py-1 rounded" style="background: var(--p-surface-50)"><span style="color: var(--p-text-muted-color)">GH CLI</span><div :class="prStatus.gh_authenticated ? 'text-success-500' : 'text-warn-500'">{{ prStatus.gh_authenticated ? 'authenticated' : 'not authenticated' }}</div></div>
            <div class="px-2 py-1 rounded" style="background: var(--p-surface-50)"><span style="color: var(--p-text-muted-color)">Protected</span><div :class="prStatus.protected_branch ? 'text-danger-500' : 'text-success-500'">{{ prStatus.protected_branch ? 'yes' : 'no' }}</div></div>
          </div>
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-2 gap-4 p-5">
          <div class="space-y-3">
            <div class="grid grid-cols-2 gap-2">
              <label class="text-[10px]" style="color: var(--p-text-muted-color)">Base branch
                <input v-model="prForm.base_branch" class="mt-1 w-full px-2 py-1.5 rounded text-[11px]" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); color: var(--p-text-color)" />
              </label>
              <label class="text-[10px]" style="color: var(--p-text-muted-color)">Head branch
                <input v-model="prForm.head_branch" class="mt-1 w-full px-2 py-1.5 rounded text-[11px]" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); color: var(--p-text-color)" />
              </label>
            </div>
            <label class="block text-[10px]" style="color: var(--p-text-muted-color)">Title
              <input v-model="prForm.title" class="mt-1 w-full px-2 py-1.5 rounded text-[11px]" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); color: var(--p-text-color)" />
            </label>
            <label class="block text-[10px]" style="color: var(--p-text-muted-color)">Body
              <textarea v-model="prForm.body" rows="5" class="mt-1 w-full px-2 py-1.5 rounded text-[11px] font-mono" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); color: var(--p-text-color)" />
            </label>
            <label class="flex items-center gap-2 text-[11px]" style="color: var(--p-text-color)">
              <input v-model="prForm.draft" type="checkbox" />
              Create as draft
            </label>
            <label class="block text-[10px]" style="color: var(--p-text-muted-color)">Optional commit message
              <input v-model="prForm.commit_message" class="mt-1 w-full px-2 py-1.5 rounded text-[11px]" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); color: var(--p-text-color)" />
            </label>
            <label class="block text-[10px]" style="color: var(--p-text-muted-color)">Paths to stage when committing
              <textarea v-model="prForm.paths_text" rows="4" placeholder="src/app/file.lua" class="mt-1 w-full px-2 py-1.5 rounded text-[11px] font-mono" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); color: var(--p-text-color)" />
            </label>
            <div class="flex items-center gap-2">
              <Button @click="planPr" :disabled="prRunning || !prForm.title.trim()" class="!px-3 !py-1.5 !text-[11px] !font-medium">Dry-run PR</Button>
              <Button @click="createPr" :disabled="prRunning || !prForm.title.trim()" class="!px-3 !py-1.5 !text-[11px] !font-medium k-btn-tinted k-btn-tinted-danger">Execute PR</Button>
            </div>
          </div>

          <div class="min-w-0">
            <div class="text-[10px] font-semibold uppercase tracking-wider mb-2" style="color: var(--p-text-muted-color)">Plan / result</div>
            <div v-if="!prResult" class="p-4 rounded text-[11px]" style="background: var(--p-surface-50); color: var(--p-text-muted-color)">Run a dry-run first to see exact commands.</div>
            <div v-else class="space-y-2">
              <a v-if="prResult.pr_url" :href="prResult.pr_url" target="_blank" class="inline-flex items-center gap-1 text-[11px]" style="color: var(--p-primary-color)">
                <Icon icon="tabler:external-link" class="w-3 h-3" /> {{ prResult.pr_url }}
              </a>
              <div v-for="(cmd, i) in prResult.commands || []" :key="i" class="rounded p-2" style="background: var(--p-surface-50); border: 1px solid var(--p-surface-100)">
                <div class="flex items-center gap-2 text-[10px] mb-1">
                  <span class="font-semibold" style="color: var(--p-text-color)">{{ cmd.label }}</span>
                  <Tag v-if="cmd.mutates" severity="warn" class="!text-[9px] !px-1 !py-px">mutates</Tag>
                </div>
                <pre class="text-[10px] whitespace-pre-wrap break-all" style="color: var(--p-text-muted-color)">{{ cmd.command }}</pre>
              </div>
              <div v-for="(res, i) in prResult.results || []" :key="`r-${i}`" class="rounded p-2" style="background: var(--p-surface-50); border: 1px solid var(--p-surface-100)">
                <div class="text-[10px] font-semibold" style="color: var(--p-text-color)">{{ res.label }} · exit {{ res.exit_code }}</div>
                <pre class="text-[10px] whitespace-pre-wrap break-all" style="color: var(--p-text-muted-color)">{{ res.stdout || res.stderr }}</pre>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ======================== HISTORY TAB ======================== -->
    <div v-if="mainTab === 'history'" class="flex-1 overflow-y-auto">
      <!-- Filters -->
      <div class="sticky top-0 z-10 px-5 py-2 flex items-center gap-2 flex-shrink-0" style="background: var(--p-content-background); border-bottom: 1px solid var(--p-surface-100)">
        <select v-model="filterNs" class="px-2 py-1 rounded text-[10px]" style="background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color)">
          <option value="">All namespaces</option>
          <option v-for="ns in namespaces" :key="ns" :value="ns">{{ ns }}</option>
        </select>
        <select v-model="filterOp" class="px-2 py-1 rounded text-[10px]" style="background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color)">
          <option value="">All ops</option>
          <option value="create">Create</option>
          <option value="update">Update</option>
          <option value="delete">Delete</option>
        </select>
        <span class="text-[10px] ml-1" style="color: var(--p-text-muted-color)">{{ entries.length }} changes</span>
      </div>

      <!-- Timeline -->
      <div v-if="histLoading && entries.length === 0" class="p-8 text-center text-[11px]" style="color: var(--p-text-muted-color)">Loading...</div>
      <div v-else-if="groupedEntries.length === 0" class="flex items-center justify-center p-8">
        <div class="text-center"><Icon icon="tabler:history" class="w-8 h-8 mx-auto mb-1 opacity-15" /><div class="text-[11px]" style="color: var(--p-text-muted-color)">No changes recorded yet</div></div>
      </div>
      <div v-else class="px-5 py-3">
        <div v-for="(group, gi) in groupedEntries" :key="`${group.version}-${gi}`" class="flex gap-3 mb-0">
          <div class="flex flex-col items-center flex-shrink-0 w-4">
            <div class="w-2 h-2 rounded-full flex-shrink-0 mt-1" style="background: var(--p-primary-color)" />
            <div class="w-px flex-1 -mt-px" style="background: var(--p-content-border-color)" />
          </div>
          <div class="flex-1 pb-4 min-w-0">
            <div class="flex items-center gap-2 mb-1.5">
              <span class="text-[10px] font-mono font-bold" style="color: var(--p-primary-color)">v{{ group.version }}</span>
              <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ timeAgo(group.timestamp) }}</span>
              <span v-if="group.user_id" class="text-[9px] px-1.5 py-0.5 rounded" style="background: var(--p-surface-100); color: var(--p-text-muted-color)">{{ group.user_id }}</span>
              <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ group.entries.length }} change{{ group.entries.length !== 1 ? 's' : '' }}</span>
            </div>
            <div class="flex flex-col gap-px">
              <div v-for="entry in group.entries" :key="entry.id" class="flex items-center gap-1.5 px-2 py-1 rounded transition-colors hover:bg-[var(--kp-hover-bg)]">
                <Icon :icon="opIcon(entry.op_type)" class="w-2.5 h-2.5 flex-shrink-0" :style="{ color: opColor(entry.op_type) }" />
                <span class="text-[10px] font-mono truncate" style="color: var(--p-text-color)">{{ entry.entry_id || 'unknown' }}</span>
                <span v-if="entry.entry_kind" class="text-[9px] px-1 py-0.5 rounded flex-shrink-0" :style="{ color: kindColor(entry.entry_kind, entry.entry_meta_type), background: kindColor(entry.entry_kind, entry.entry_meta_type) + '15' }">{{ entry.entry_meta_type || entry.entry_kind }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ======================== VERSIONS TAB ======================== -->
    <div v-if="mainTab === 'versions'" class="flex-1 overflow-y-auto">
      <div v-if="versions.length === 0" class="flex items-center justify-center p-8">
        <div class="text-[11px]" style="color: var(--p-text-muted-color)">No version history</div>
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-[11px]">
          <thead><tr style="border-bottom: 1px solid var(--p-content-border-color)">
            <th class="text-left py-2 px-4 font-medium" style="color: var(--p-text-muted-color)">Version</th>
            <th class="text-left py-2 px-4 font-medium" style="color: var(--p-text-muted-color)">Time</th>
            <th class="text-left py-2 px-4 font-medium" style="color: var(--p-text-muted-color)">User</th>
            <th class="text-center py-2 px-3 font-medium" style="color: var(--p-text-muted-color)">Total</th>
            <th class="text-center py-2 px-3 font-medium text-success-500">+</th>
            <th class="text-center py-2 px-3 font-medium text-info-500">~</th>
            <th class="text-center py-2 px-3 font-medium text-danger-500">-</th>
            <th class="text-left py-2 px-4 font-medium" style="color: var(--p-text-muted-color)">Namespaces</th>
          </tr></thead>
          <tbody>
            <tr v-for="v in versions" :key="v.version" style="border-bottom: 1px solid var(--p-surface-100)" class="transition-colors hover:bg-[var(--kp-hover-bg)]">
              <td class="py-2 px-4 font-mono font-bold" style="color: var(--p-primary-color)">v{{ v.version }}</td>
              <td class="py-2 px-4" style="color: var(--p-text-muted-color)">{{ timeAgo(v.timestamp) }}</td>
              <td class="py-2 px-4" style="color: var(--p-text-muted-color)">{{ v.user_id || '-' }}</td>
              <td class="py-2 px-3 text-center" style="color: var(--p-text-color)">{{ v.change_count }}</td>
              <td class="py-2 px-3 text-center text-success-500">{{ v.creates || 0 }}</td>
              <td class="py-2 px-3 text-center text-info-500">{{ v.updates || 0 }}</td>
              <td class="py-2 px-3 text-center text-danger-500">{{ v.deletes || 0 }}</td>
              <td class="py-2 px-4"><div class="flex gap-1 flex-wrap"><span v-for="ns in v.namespaces" :key="ns" class="text-[9px] font-mono px-1 py-0.5 rounded" style="background: var(--p-surface-100); color: var(--p-text-muted-color)">{{ ns }}</span></div></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
