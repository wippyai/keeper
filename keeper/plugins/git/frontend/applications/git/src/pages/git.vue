<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import { useGit, type ClusterSummary, type ClusterFull, type ClusterChange, type Decision, type Importance, type Verdict, type Severity, type RecState, type FileDiff, type SplitGroup } from '../composables/useGit'

const api = useApi()
const host = useHost()
const instance = useWippy()
const git = useGit(api, instance)

type Filter = 'all' | 'pending' | 'ready' | 'hidden' | 'suspect'
const filter = ref<Filter>('all')
const selectedId = ref<string | null>(null)
const expandedRecs = ref(true)
const confirmPushOpen = ref(false)

type SelectedCluster = ClusterSummary & Partial<Pick<ClusterFull, 'change_ids' | 'changes' | 'changeset_ids' | 'primary_changeset_id' | 'is_suspect' | 'recommendations'>>

function errorMessage(value: unknown): string {
  return value instanceof Error ? value.message : String(value)
}

onMounted(async () => {
  await git.refresh()
  if (!git.snapshot.value || (git.snapshot.value.clusters || []).length === 0) {
    showToast('No cluster index yet — click Rebuild to build one.')
  }
})

watch(() => git.snapshot.value?.clusters?.length, () => {
  if (selectedId.value && !git.snapshot.value?.clusters.find(c => c.id === selectedId.value)) {
    selectedId.value = null
  }
  // auto-select the first visible cluster so the detail pane (incl. changes list) loads
  if (!selectedId.value && visibleClusters.value.length > 0) {
    selectedId.value = visibleClusters.value[0].id
  }
})

watch(selectedId, async (id) => {
  if (!id) { git.detail.value = null; return }
  try { await git.loadCluster(id) } catch (e: unknown) { showToast(errorMessage(e) || 'failed to load cluster', 'error') }
})

const visibleClusters = computed<ClusterSummary[]>(() => {
  const list = git.snapshot.value?.clusters || []
  let out = list.slice()
  if (filter.value === 'suspect') out = out.filter(c => c.decision === 'orphan' || c.importance === 'suspect')
  else if (filter.value === 'pending') out = out.filter(c => c.decision === 'pending')
  else if (filter.value === 'ready') out = out.filter(c => c.decision === 'approved')
  else if (filter.value === 'hidden') out = out.filter(c => c.decision === 'skipped' || c.decision === 'split')
  const rank = (d: Decision) => d === 'pending' ? 0 : d === 'approved' ? 1 : 2
  return out.sort((a, b) => rank(a.decision) - rank(b.decision))
})

const selectedCluster = computed<SelectedCluster | null>(() =>
  git.detail.value || visibleClusters.value[0] || null)
const selectedChanges = computed<ClusterChange[]>(() => selectedCluster.value?.changes || [])

const counts = computed(() => git.snapshot.value?.counts || {
  all: 0, pending: 0, ready: 0, hidden: 0, suspect: 0, pushable_ready: 0, blocked_ready: 0,
})

const indexAgeText = computed(() => {
  const at = git.snapshot.value?.built_at
  if (!at) return 'never'
  const diff = Math.max(0, Math.floor((Date.now() - new Date(at).getTime()) / 60_000))
  if (diff < 1) return 'just now'
  if (diff === 1) return '1 min ago'
  if (diff < 60) return diff + ' min ago'
  return Math.floor(diff / 60) + ' h ago'
})

const importanceTone: Record<Importance, { dot: string; word: string }> = {
  critical: { dot: 'var(--p-danger-500)', word: 'Important' },
  high:     { dot: 'var(--p-warn-500)', word: 'Worth attention' },
  normal:   { dot: 'var(--p-info-500)', word: 'Routine' },
  cleanup:  { dot: 'var(--p-text-muted-color)', word: 'Cleanup' },
  suspect:  { dot: 'var(--p-text-muted-color)', word: 'Suspect' },
}
const verdictTone: Record<Verdict, { color: string; icon: string; phrase: string }> = {
  ready:        { color: 'var(--p-success-500)', icon: 'tabler:circle-check',  phrase: 'Looks ready' },
  closer_look:  { color: 'var(--p-warn-500)', icon: 'tabler:zoom-question', phrase: 'Closer look' },
  do_not_push:  { color: 'var(--p-danger-500)', icon: 'tabler:hand-stop',     phrase: "Don't push yet" },
}
const sevTone: Record<Severity, { color: string; icon: string; bg: string; label: string }> = {
  info:  { color: 'var(--p-text-muted-color)', icon: 'tabler:info-circle',     bg: 'transparent', label: 'fyi' },
  warn:  { color: 'var(--p-warn-500)',         icon: 'tabler:alert-triangle', bg: 'color-mix(in srgb, var(--p-warn-500) 10%, transparent)',   label: 'warn' },
  block: { color: 'var(--p-danger-500)',       icon: 'tabler:hand-stop',      bg: 'color-mix(in srgb, var(--p-danger-500) 10%, transparent)', label: 'block' },
}
const recStateTone: Record<RecState, { color: string; label: string; icon: string }> = {
  open:         { color: 'var(--p-warn-500)', label: 'open',         icon: 'tabler:alert-circle' },
  acknowledged: { color: 'var(--p-info-500)', label: 'acknowledged', icon: 'tabler:eye-check' },
  fixed:        { color: 'var(--p-success-500)', label: 'fixed',        icon: 'tabler:check' },
  split:        { color: 'var(--p-text-muted-color)', label: 'split off',    icon: 'tabler:arrow-split' },
}

function showToast(msg: string, severity: 'info' | 'success' | 'error' = 'info') {
  host.toast({ severity, summary: msg, life: 4000 })
}

function fmtChanges(n: number) { return n + ' change' + (n === 1 ? '' : 's') }

async function decide(id: string, decision: Decision) {
  try { await git.setDecision(id, decision) }
  catch (e: unknown) { showToast(errorMessage(e) || 'failed', 'error') }
}

async function ackRec(rid: string, state: RecState) {
  if (!selectedCluster.value) return
  try { await git.updateRecommendation(selectedCluster.value.id, rid, state) }
  catch (e: unknown) { showToast(errorMessage(e) || 'failed', 'error') }
}

const syncFirst = ref(false)

async function rebuild(mode: 'manual' | 'ai' = 'ai') {
  try { await git.rebuild({ mode, sync_first: syncFirst.value }) }
  catch (e: unknown) { showToast(errorMessage(e) || 'rebuild failed', 'error') }
}

async function bulkPush() {
  const ids = (git.snapshot.value?.clusters || [])
    .filter(c => c.decision === 'approved' && c.pushable).map(c => c.id)
  if (ids.length === 0) { confirmPushOpen.value = false; return }
  try {
    const res = await git.pushApproved(ids)
    confirmPushOpen.value = false
    const total = res.pushed + res.failed
    const severity = res.failed > 0 ? 'error' : 'success'
    showToast(`Pushed ${res.pushed} of ${total} clusters`, severity)
  } catch (e: unknown) {
    showToast(errorMessage(e) || 'push failed', 'error')
  }
}

const blocking = computed(() => {
  const recs = selectedCluster.value?.recommendations
  if (!recs) return false
  return recs.some(r => r.severity === 'block' && r.state === 'open')
})

// ── diff viewer ────────────────────────────────────────────────────────────
const diffPath = ref<string | null>(null)
const diffData = ref<FileDiff | null>(null)
const diffLoading = ref(false)
async function openDiff(path: string) {
  diffPath.value = path
  diffData.value = null
  diffLoading.value = true
  try { diffData.value = await git.fetchDiff(path) }
  catch (e: unknown) { showToast(errorMessage(e) || 'diff failed', 'error') }
  finally { diffLoading.value = false }
}
function closeDiff() { diffPath.value = null; diffData.value = null }

// ── split modal ────────────────────────────────────────────────────────────
const splitOpen = ref(false)
const splitMode = ref<'ai' | 'by_prefix' | 'by_kind'>('by_prefix')
const splitGroups = ref<SplitGroup[]>([])
const splitLoading = ref(false)
const splitApplying = ref(false)

async function openSplit() {
  if (!selectedCluster.value) return
  splitOpen.value = true
  splitMode.value = 'by_prefix'
  await loadSplitProposal()
}
async function loadSplitProposal() {
  if (!selectedCluster.value) return
  splitLoading.value = true
  splitGroups.value = []
  try {
    const r = await git.suggestSplit(selectedCluster.value.id, { mode: splitMode.value })
    splitGroups.value = r.groups || []
  } catch (e: unknown) {
    showToast(errorMessage(e) || 'split suggestion failed', 'error')
  } finally {
    splitLoading.value = false
  }
}
async function applySplit() {
  if (!selectedCluster.value || splitGroups.value.length === 0) return
  splitApplying.value = true
  try {
    const groups = splitGroups.value.filter(g => g.change_ids.length > 0)
    if (groups.length < 2) throw new Error('need at least 2 non-empty groups to split')
    await git.splitCluster(selectedCluster.value.id, groups)
    splitOpen.value = false
    showToast(`Split into ${groups.length} clusters`, 'success')
  } catch (e: unknown) {
    showToast(errorMessage(e) || 'split apply failed', 'error')
  } finally {
    splitApplying.value = false
  }
}
function closeSplit() { splitOpen.value = false; splitGroups.value = [] }
function pathSamples(g: SplitGroup): string[] {
  // resolve change_ids to paths via the current cluster's compact changes
  const changes = selectedCluster.value?.changes
  if (!changes) return []
  const map: Record<string, string> = {}
  for (const c of changes) map[c.change_id] = c.path
  return g.change_ids.slice(0, 3).map(id => map[id] || id)
}

// ── explain panel ─────────────────────────────────────────────────────────
const explaining = ref<string | null>(null)
const explanations = ref<Record<string, string>>({})
async function explainRec(recId: string) {
  if (!selectedCluster.value) return
  explaining.value = recId
  try {
    const r = await git.explainRecommendation(selectedCluster.value.id, recId)
    if (r.text) explanations.value[recId] = r.text
  } catch (e: unknown) {
    showToast(errorMessage(e) || 'explain failed', 'error')
  } finally {
    explaining.value = null
  }
}
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- header -->
    <header class="px-5 py-2.5 border-b flex items-center gap-3 text-[12px]"
      style="border-color: var(--p-content-border-color)">
      <Icon icon="tabler:git-pull-request" class="w-4 h-4" />
      <h1 class="text-[13px] font-semibold">Git</h1>

      <span class="opacity-50">·</span>

      <div class="flex items-center gap-2 px-2 py-1 rounded"
        :class="{ 'bg-warn-500/10': git.stale.value }"
        :style="!git.stale.value ? { background: 'var(--p-surface-100)' } : {}">
        <Icon :icon="git.stale.value ? 'tabler:alert-triangle' : 'tabler:database'"
          class="w-3.5 h-3.5"
          :class="{ 'text-warn-500': git.stale.value }" />
        <span class="text-[11px]" :class="{ 'text-warn-500': git.stale.value }">
          Index built {{ indexAgeText }}
          <template v-if="git.snapshot.value">
            · {{ git.snapshot.value.journal_size_at_build }} changes
          </template>
        </span>
        <button @click="rebuild('ai')" :disabled="git.rebuilding.value"
          class="text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1 text-white"
          :class="{ 'bg-warn-500': git.stale.value }"
          :style="!git.stale.value ? { background: 'var(--p-primary-color)' } : {}"
          title="AI-clustered rebuild — groups changes by topic via Sonnet (~30-90s)">
          <Icon :icon="git.rebuilding.value ? 'tabler:loader-2' : 'tabler:sparkles'"
            :class="git.rebuilding.value ? 'w-3 h-3 animate-spin' : 'w-3 h-3'" />
          {{ git.rebuilding.value ? 'Rebuilding…' : 'AI rebuild' }}
        </button>
        <button @click="rebuild('manual')" :disabled="git.rebuilding.value"
          class="text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1"
          style="background: var(--p-surface-200)"
          title="Manual rebuild — group by directory prefix (no LLM, instant)">
          <Icon icon="tabler:list" class="w-3 h-3" />
          Manual
        </button>
        <label class="flex items-center gap-1 cursor-pointer text-[10px] opacity-70 hover:opacity-100"
          title="Sync registry overlays to disk before scanning git">
          <input type="checkbox" v-model="syncFirst" class="w-3 h-3" />
          sync first
        </label>
      </div>

      <span class="opacity-50">·</span>
      <span class="opacity-70">{{ counts.all }} clusters · {{ counts.suspect }} suspect</span>

      <button v-if="(counts.pushable_ready || 0) > 0" @click="confirmPushOpen = true"
        class="ml-auto px-3 py-1 rounded text-[11px] font-semibold flex items-center gap-1.5 bg-success-500 text-white">
        <Icon icon="tabler:upload" class="w-3.5 h-3.5" />
        Push {{ counts.pushable_ready }} ready
      </button>
      <span v-else-if="(counts.blocked_ready || 0) > 0" class="ml-auto opacity-60 text-[11px]">
        {{ counts.blocked_ready }} ready for review only
      </span>
      <span v-else class="ml-auto opacity-50 text-[11px]">
        Mark clusters ready to enable push
      </span>
    </header>

    <!-- chip filters -->
    <div class="px-5 py-2 border-b flex items-center gap-1 text-[10px]"
      style="border-color: var(--p-content-border-color)">
      <button v-for="(f, key) in {
        all:     { label: 'All',           count: counts.all },
        pending: { label: 'Pending',       count: counts.pending },
        ready:   { label: 'Ready to push', count: counts.ready },
        hidden:  { label: 'Hidden',        count: counts.hidden },
        suspect: { label: 'Suspect',       count: counts.suspect },
      }" :key="key"
        @click="filter = key as Filter; selectedId = null"
        class="px-1.5 py-0.5 rounded font-medium flex items-center gap-1 transition"
        :style="{
          background: filter === key ? 'var(--p-primary-color)' : 'var(--p-surface-100)',
          color: filter === key ? 'white' : 'inherit',
        }">
        {{ f.label }}
        <span class="opacity-80">{{ f.count }}</span>
      </button>
    </div>

    <!-- 2-column main -->
    <main class="flex-1 grid grid-cols-[400px_1fr] overflow-hidden">
      <!-- list -->
      <section class="overflow-y-auto border-r" style="border-color: var(--p-content-border-color)">
        <div v-if="git.loading.value && !git.snapshot.value" class="p-8 text-center text-[12px] opacity-60">
          Loading…
        </div>
        <div v-else-if="git.error.value" class="p-6 text-[12px] text-danger-500">
          {{ git.error.value }}
        </div>
        <div v-else-if="visibleClusters.length === 0" class="p-12 text-center text-[12px] opacity-60">
          <span v-if="(git.snapshot.value?.clusters || []).length === 0">
            No cluster index yet. Click Rebuild above to build one.
          </span>
          <span v-else>Nothing matches.</span>
        </div>
        <article v-for="c in visibleClusters" :key="c.id"
          @click="selectedId = c.id"
          class="px-4 py-3 border-b cursor-pointer transition"
          :style="{
            borderColor: 'var(--p-surface-200)',
            background: selectedCluster?.id === c.id ? 'var(--p-surface-100)' : 'transparent',
            opacity: c.decision !== 'pending' ? 0.65 : 1,
          }">
          <div class="flex items-center gap-2 mb-1.5">
            <span class="w-2 h-2 rounded-full shrink-0"
              :style="{ background: importanceTone[c.importance].dot }" />
            <h3 class="text-[12px] font-semibold flex-1 truncate">{{ c.title }}</h3>
            <Icon v-if="c.decision === 'approved'" icon="tabler:circle-check" class="w-3.5 h-3.5 shrink-0 text-success-500" />
            <Icon v-else-if="c.decision === 'split'" icon="tabler:arrow-split" class="w-3.5 h-3.5 shrink-0 opacity-50" />
            <Icon v-else-if="c.decision === 'skipped'" icon="tabler:archive" class="w-3.5 h-3.5 shrink-0 opacity-50" />
          </div>
          <div class="flex items-center gap-2 text-[10px] opacity-70 mb-1">
            <span>{{ fmtChanges(c.change_count) }}</span>
            <span class="opacity-50">·</span>
            <span class="flex items-center gap-1"
              :style="{ color: verdictTone[c.verdict].color }">
              <Icon :icon="verdictTone[c.verdict].icon" class="w-3 h-3" />
              {{ verdictTone[c.verdict].phrase }}
            </span>
            <span v-if="c.rec_open > 0" class="ml-auto text-[9px] px-1 rounded bg-warn-500/10 text-warn-500">
              {{ c.rec_open }} open
            </span>
          </div>
          <p class="text-[10px] opacity-70 leading-snug truncate">{{ c.plain_summary }}</p>
        </article>
      </section>

      <!-- detail pane -->
      <section class="overflow-y-auto" style="background: var(--p-surface-0)">
        <div v-if="!selectedCluster" class="p-12 text-center text-[12px] opacity-60">
          Pick a cluster on the left.
        </div>
        <article v-else class="p-6">
          <div class="flex items-center gap-2 mb-2">
            <span class="w-2 h-2 rounded-full"
              :style="{ background: importanceTone[selectedCluster.importance as Importance].dot }" />
            <span class="text-[11px] opacity-70">{{ importanceTone[selectedCluster.importance as Importance].word }}</span>
            <span class="text-[11px] opacity-50">·</span>
            <span class="text-[11px] opacity-70">{{ fmtChanges(selectedCluster.change_count) }}</span>
            <span v-if="selectedCluster.stats" class="text-[11px] opacity-50">·</span>
            <span v-if="selectedCluster.stats" class="text-[11px] opacity-70">
              {{ selectedCluster.stats.namespaces?.length || 0 }} namespace{{ (selectedCluster.stats.namespaces?.length || 0) === 1 ? '' : 's' }}
            </span>
            <span class="ml-auto text-[10px] opacity-50 font-mono">{{ selectedCluster.id }}</span>
          </div>
          <h2 class="text-[20px] font-semibold mb-2">{{ selectedCluster.title }}</h2>
          <p class="text-[13px] opacity-85 leading-relaxed mb-4">{{ selectedCluster.plain_summary }}</p>

          <!-- verdict band -->
          <div class="rounded-lg p-3 mb-4 flex items-center gap-3"
            :style="{ background: verdictTone[selectedCluster.verdict as Verdict].color + '12',
                      border: '1px solid ' + verdictTone[selectedCluster.verdict as Verdict].color + '33' }">
            <Icon :icon="verdictTone[selectedCluster.verdict as Verdict].icon" class="w-5 h-5"
              :style="{ color: verdictTone[selectedCluster.verdict as Verdict].color }" />
            <div>
              <div class="text-[12px] font-semibold"
                :style="{ color: verdictTone[selectedCluster.verdict as Verdict].color }">
                {{ verdictTone[selectedCluster.verdict as Verdict].phrase }}
              </div>
              <div class="text-[11px] opacity-80">{{ selectedCluster.verdict_text }}</div>
            </div>
          </div>

          <!-- recommendations -->
          <div v-if="selectedCluster.recommendations" class="mb-5">
            <h3 class="text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5">
              <Icon icon="tabler:sparkles" class="w-3 h-3" />
              AI recommendations
              <button @click="expandedRecs = !expandedRecs"
                class="ml-auto text-[10px] opacity-60 hover:opacity-100">
                {{ expandedRecs ? 'Collapse' : 'Expand' }}
              </button>
            </h3>
            <ul v-if="expandedRecs" class="space-y-1.5">
              <li v-for="r in selectedCluster.recommendations" :key="r.id"
                class="rounded p-2.5 flex items-start gap-2"
                :style="{ background: sevTone[r.severity as Severity].bg,
                          border: '1px solid var(--p-surface-200)' }">
                <Icon :icon="sevTone[r.severity as Severity].icon" class="w-3.5 h-3.5 shrink-0 mt-0.5"
                  :style="{ color: sevTone[r.severity as Severity].color }" />
                <div class="flex-1 min-w-0">
                  <div class="text-[12px]">{{ r.text }}</div>
                  <div v-if="r.fix_hint" class="text-[11px] opacity-70 mt-0.5">↳ {{ r.fix_hint }}</div>
                  <div v-if="r.state === 'open'" class="flex gap-1 mt-2 flex-wrap">
                    <button @click="explainRec(r.id)" :disabled="explaining === r.id"
                      class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 disabled:opacity-60 bg-accent-500/10 text-accent-500">
                      <Icon :icon="explaining === r.id ? 'tabler:loader-2' : 'tabler:sparkles'"
                        :class="explaining === r.id ? 'w-3 h-3 animate-spin' : 'w-3 h-3'" />
                      {{ explaining === r.id ? 'Asking AI…' : 'Explain' }}
                    </button>
                    <button @click="ackRec(r.id, 'acknowledged')"
                      class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 bg-info-500/10 text-info-500">
                      <Icon icon="tabler:eye-check" class="w-3 h-3" /> Acknowledge
                    </button>
                    <button @click="ackRec(r.id, 'fixed')"
                      class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 bg-success-500/10 text-success-500">
                      <Icon icon="tabler:check" class="w-3 h-3" /> Mark fixed
                    </button>
                  </div>
                  <div v-if="r.detail || explanations[r.id]" class="mt-2 p-2.5 rounded text-[11px] leading-relaxed whitespace-pre-wrap border-l-[3px] border-accent-500"
                    style="background: var(--p-surface-100)">
                    <div class="text-[9px] uppercase tracking-wide opacity-60 mb-1 flex items-center gap-1">
                      <Icon icon="tabler:sparkles" class="w-3 h-3" /> AI explanation
                    </div>{{ r.detail || explanations[r.id] }}
                  </div>
                </div>
                <span class="text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0"
                  :style="{ background: recStateTone[r.state as RecState].color + '22',
                            color: recStateTone[r.state as RecState].color }">
                  {{ recStateTone[r.state as RecState].label }}
                </span>
              </li>
            </ul>
          </div>

          <!-- changes -->
          <div v-if="selectedChanges.length > 0" class="mb-5">
            <h3 class="text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5">
              <Icon icon="tabler:list" class="w-3 h-3" />
              Changes ({{ selectedChanges.length }})
              <span class="opacity-50 ml-auto text-[9px]">click a row for diff</span>
            </h3>
            <div class="rounded border" style="border-color: var(--p-content-border-color)">
              <div v-for="c in selectedChanges.slice(0, 100)" :key="c.change_id"
                @click="openDiff(c.path)"
                class="px-3 py-1.5 border-b last:border-0 flex items-center gap-2 cursor-pointer hover:bg-[var(--p-surface-100)]"
                style="border-color: var(--p-content-border-color)">
                <span class="text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0"
                  :class="{
                    'bg-success-500/10 text-success-500': c.op === 'create',
                    'bg-danger-500/10 text-danger-500': c.op === 'delete',
                    'bg-info-500/10 text-info-500': c.op !== 'create' && c.op !== 'delete',
                  }">
                  {{ c.op[0].toUpperCase() }}
                </span>
                <Icon :icon="c.category === 'registry' ? 'tabler:database' : 'tabler:file'"
                  class="w-3 h-3 opacity-50 shrink-0" />
                <span class="font-mono text-[11px] flex-1 truncate">{{ c.path }}</span>
                <span class="text-[10px] shrink-0 text-success-500" v-if="c.added">+{{ c.added }}</span>
                <span class="text-[10px] shrink-0 text-danger-500" v-if="c.removed">−{{ c.removed }}</span>
              </div>
              <div v-if="selectedChanges.length > 100"
                class="px-3 py-1.5 text-[10px] opacity-60">
                + {{ selectedChanges.length - 100 }} more
              </div>
            </div>
          </div>

          <!-- action bar -->
          <div class="sticky bottom-0 -mx-6 px-6 py-3 border-t flex items-center gap-2"
            style="border-color: var(--p-content-border-color); background: var(--p-surface-0)">
            <template v-if="selectedCluster.decision === 'pending'">
              <button @click="decide(selectedCluster.id, 'approved')" :disabled="blocking"
                class="px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed bg-success-500 text-white">
                <Icon icon="tabler:check" class="w-3.5 h-3.5" /> Mark ready
              </button>
              <button @click="openSplit()"
                class="px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5"
                style="background: var(--p-surface-200)">
                <Icon icon="tabler:arrow-split" class="w-3.5 h-3.5" /> Split…
              </button>
              <button @click="decide(selectedCluster.id, 'skipped')"
                class="px-4 py-2 rounded-lg text-[12px] flex items-center gap-1.5"
                style="background: var(--p-surface-200)">
                <Icon icon="tabler:archive" class="w-3.5 h-3.5" /> Hide
              </button>
              <span v-if="blocking" class="text-[11px] ml-2 text-danger-500">
                Resolve blocking issue first
              </span>
            </template>
            <template v-else-if="selectedCluster.decision === 'approved'">
              <span class="text-[11px] flex items-center gap-1.5 text-success-500">
                <Icon icon="tabler:circle-check" class="w-3.5 h-3.5" />
                Marked ready — push from header when ready to ship
              </span>
              <button v-if="selectedCluster.pushable" @click="confirmPushOpen = true"
                class="ml-auto px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5 bg-success-500 text-white">
                <Icon icon="tabler:upload" class="w-3.5 h-3.5" /> Push all {{ counts.pushable_ready || 0 }}
              </button>
              <span v-else class="ml-auto text-[11px] opacity-60">
                {{ selectedCluster.push_blockers?.[0] || 'Review-only cluster' }}
              </span>
              <button @click="decide(selectedCluster.id, 'pending')"
                class="px-4 py-2 rounded-lg text-[12px]" style="background: var(--p-surface-200)">
                Unmark
              </button>
            </template>
            <template v-else>
              <button @click="decide(selectedCluster.id, 'pending')"
                class="px-4 py-2 rounded-lg text-[12px]" style="background: var(--p-surface-200)">
                Move back to pending
              </button>
            </template>
          </div>
        </article>
      </section>
    </main>

    <!-- bulk push confirm -->
    <div v-if="confirmPushOpen" class="fixed inset-0 z-50 flex items-center justify-center"
      style="background: rgba(0,0,0,0.55)" @click.self="confirmPushOpen = false">
      <div class="rounded-lg w-full max-w-md mx-4 overflow-hidden"
        style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
        <div class="px-5 py-3 border-b flex items-center gap-2"
          style="border-color: var(--p-content-border-color)">
          <Icon icon="tabler:upload" class="w-4 h-4" />
          <h3 class="text-[13px] font-semibold flex-1">Push {{ counts.pushable_ready || 0 }} clusters to main</h3>
          <button @click="confirmPushOpen = false" class="opacity-60 hover:opacity-100">
            <Icon icon="tabler:x" class="w-4 h-4" />
          </button>
        </div>
        <div class="px-5 py-4">
          <p class="text-[11px] opacity-80 leading-relaxed">
            Each cluster runs through governance (lint → version → migrations → tests → registry → fs) and
            merges to main on success. Failed clusters stay in <b>Pending</b> with the failure attached.
          </p>
          <div class="rounded border mt-3" style="border-color: var(--p-content-border-color); max-height: 240px; overflow-y: auto">
            <div v-for="c in (git.snapshot.value?.clusters || []).filter(x => x.decision === 'approved' && x.pushable)" :key="c.id"
              class="px-3 py-2 border-b last:border-0 flex items-center gap-2"
              style="border-color: var(--p-content-border-color)">
              <span class="w-1.5 h-1.5 rounded-full shrink-0"
                :style="{ background: importanceTone[c.importance].dot }" />
              <span class="text-[11px] flex-1 truncate">{{ c.title }}</span>
              <span class="text-[10px] opacity-60 shrink-0">{{ fmtChanges(c.change_count) }}</span>
            </div>
          </div>
        </div>
        <div class="px-5 py-3 border-t flex items-center gap-2"
          style="border-color: var(--p-content-border-color)">
          <button @click="bulkPush" :disabled="git.pushing.value"
            class="px-4 py-1.5 rounded text-[12px] font-semibold flex items-center gap-1.5 disabled:opacity-60 bg-success-500 text-white">
            <Icon :icon="git.pushing.value ? 'tabler:loader-2' : 'tabler:upload'"
              :class="git.pushing.value ? 'w-3.5 h-3.5 animate-spin' : 'w-3.5 h-3.5'" />
            {{ git.pushing.value ? 'Pushing…' : 'Push all' }}
          </button>
          <button @click="confirmPushOpen = false" :disabled="git.pushing.value"
            class="px-4 py-1.5 rounded text-[12px]" style="background: var(--p-surface-200)">
            Cancel
          </button>
        </div>
      </div>
    </div>

    <!-- split modal -->
    <div v-if="splitOpen && selectedCluster" class="fixed inset-0 z-50 flex items-center justify-center"
      style="background: rgba(0,0,0,0.55)" @click.self="closeSplit()">
      <div class="rounded-lg w-full max-w-2xl mx-4 overflow-hidden flex flex-col"
        style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color); max-height: 80vh">
        <header class="px-5 py-3 border-b flex items-center gap-2"
          style="border-color: var(--p-content-border-color)">
          <Icon icon="tabler:arrow-split" class="w-4 h-4" />
          <h3 class="text-[13px] font-semibold flex-1">
            Split <span class="opacity-70">{{ selectedCluster.title }}</span>
          </h3>
          <button @click="closeSplit()" class="opacity-60 hover:opacity-100">
            <Icon icon="tabler:x" class="w-4 h-4" />
          </button>
        </header>

        <div class="px-5 py-2.5 border-b flex items-center gap-1 text-[11px]"
          style="border-color: var(--p-content-border-color)">
          <span class="opacity-70 mr-1">Strategy:</span>
          <button v-for="m in (['by_prefix','by_kind','ai'] as const)" :key="m"
            @click="splitMode = m; loadSplitProposal()"
            :disabled="splitLoading"
            class="px-2 py-1 rounded font-medium flex items-center gap-1"
            :style="{
              background: splitMode === m ? 'var(--p-primary-color)' : 'var(--p-surface-100)',
              color: splitMode === m ? 'white' : 'inherit',
            }">
            <Icon :icon="m === 'ai' ? 'tabler:sparkles' : m === 'by_kind' ? 'tabler:category' : 'tabler:folders'"
              class="w-3 h-3" />
            {{ m === 'by_prefix' ? 'By directory' : m === 'by_kind' ? 'By file kind' : 'AI suggest' }}
          </button>
          <span class="ml-auto opacity-60">
            {{ selectedCluster.change_count }} files in source cluster
          </span>
        </div>

        <div class="flex-1 overflow-y-auto p-4">
          <div v-if="splitLoading" class="p-12 text-center text-[12px] opacity-60">
            <Icon icon="tabler:loader-2" class="w-5 h-5 animate-spin mx-auto mb-2" />
            <span v-if="splitMode === 'ai'">Asking Sonnet to propose sub-clusters…</span>
            <span v-else>Computing groups…</span>
          </div>
          <div v-else-if="splitGroups.length === 0" class="p-12 text-center text-[12px] opacity-60">
            No groups proposed.
          </div>
          <div v-else>
            <p class="text-[11px] opacity-70 mb-3">
              Will create <b>{{ splitGroups.length }}</b> new clusters.
              Source cluster will be {{ splitGroups.reduce((a,g) => a + g.change_ids.length, 0) >= selectedCluster.change_count ? 'removed' : 'reduced' }}.
            </p>
            <ul class="space-y-2">
              <li v-for="(g, i) in splitGroups" :key="i"
                class="rounded p-3"
                style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color)">
                <div class="flex items-baseline gap-2 mb-1">
                  <span class="text-[12px] font-semibold flex-1 truncate">{{ g.title }}</span>
                  <span class="text-[10px] opacity-70">{{ g.change_ids.length }} files</span>
                </div>
                <p v-if="g.plain_summary" class="text-[11px] opacity-80 mb-1.5">{{ g.plain_summary }}</p>
                <div class="font-mono text-[10px] opacity-60 space-y-0.5">
                  <div v-for="p in pathSamples(g)" :key="p" class="truncate">{{ p }}</div>
                  <div v-if="g.change_ids.length > 3">+ {{ g.change_ids.length - 3 }} more</div>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <div class="px-5 py-3 border-t flex items-center gap-2"
          style="border-color: var(--p-content-border-color)">
          <button @click="applySplit()"
            :disabled="splitLoading || splitApplying || splitGroups.length < 2"
            class="px-4 py-1.5 rounded text-[12px] font-semibold flex items-center gap-1.5 disabled:opacity-50 bg-success-500 text-white">
            <Icon :icon="splitApplying ? 'tabler:loader-2' : 'tabler:arrow-split'"
              :class="splitApplying ? 'w-3.5 h-3.5 animate-spin' : 'w-3.5 h-3.5'" />
            {{ splitApplying ? 'Splitting…' : `Apply (creates ${splitGroups.length} clusters)` }}
          </button>
          <button @click="closeSplit()" class="px-4 py-1.5 rounded text-[12px] ml-auto"
            style="background: var(--p-surface-200)">Cancel</button>
        </div>
      </div>
    </div>

    <!-- diff viewer modal -->
    <div v-if="diffPath" class="fixed inset-0 z-50 flex"
      style="background: rgba(0,0,0,0.6)" @click.self="closeDiff()">
      <aside class="ml-auto w-[820px] h-full overflow-hidden flex flex-col"
        style="background: var(--p-surface-0); border-left: 1px solid var(--p-content-border-color)">
        <header class="px-4 py-2.5 border-b flex items-center gap-2"
          style="border-color: var(--p-content-border-color)">
          <Icon icon="tabler:diff" class="w-4 h-4" />
          <span class="text-[11px] font-mono flex-1 truncate">{{ diffPath }}</span>
          <button @click="closeDiff()" class="opacity-60 hover:opacity-100">
            <Icon icon="tabler:x" class="w-4 h-4" />
          </button>
        </header>

        <div v-if="diffLoading" class="p-12 text-center text-[12px] opacity-60">
          <Icon icon="tabler:loader-2" class="w-5 h-5 animate-spin mx-auto mb-2" />
          Loading diff…
        </div>

        <div v-else-if="!diffData || (diffData.hunks.length === 0 && !diffData.diff_text)"
          class="p-12 text-center text-[12px] opacity-60">
          No diff (file may be untracked or identical to base).
        </div>

        <div v-else class="flex-1 overflow-y-auto font-mono text-[11px] leading-snug">
          <div v-for="(h, hi) in diffData.hunks" :key="hi">
            <div class="px-3 py-1 sticky top-0 z-10 text-[10px] opacity-60"
              style="background: var(--p-surface-100); border-bottom: 1px solid var(--p-content-border-color)">
              {{ h.header }}
            </div>
            <pre v-for="(ln, li) in h.lines" :key="li"
              class="px-0 py-0.5 flex whitespace-pre"
              :class="{
                'bg-success-500/5 text-success-500': ln.kind === '+',
                'bg-danger-500/5 text-danger-500': ln.kind === '-',
              }">
              <span class="w-10 text-right pr-2 opacity-40 select-none shrink-0">{{ ln.old_no || '' }}</span>
              <span class="w-10 text-right pr-2 opacity-40 select-none shrink-0">{{ ln.new_no || '' }}</span>
              <span class="w-4 text-center opacity-60 select-none shrink-0">{{ ln.kind === ' ' ? '' : ln.kind }}</span>
              <span>{{ ln.text }}</span>
            </pre>
          </div>
        </div>
      </aside>
    </div>

  </div>
</template>
