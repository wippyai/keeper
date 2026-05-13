<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import { useGit, type Decision, type RecState } from '../composables/useGit'
import { errorMessage } from '../tones'
import GitHeader from '../components/GitHeader.vue'
import GitClusterList, { type Filter } from '../components/GitClusterList.vue'
import GitClusterDetail from '../components/GitClusterDetail.vue'
import GitPushConfirmModal from '../components/GitPushConfirmModal.vue'
import GitSplitModal from '../components/GitSplitModal.vue'
import GitDiffModal from '../components/GitDiffModal.vue'
import type { SelectedCluster } from '../components/GitClusterDetail.vue'

const api = useApi()
const host = useHost()
const instance = useWippy()
const git = useGit(api, instance)

const filter = ref<Filter>('all')
const selectedId = ref<string | null>(null)
const expandedRecs = ref(true)
const confirmPushOpen = ref(false)
const syncFirst = ref(false)

function showToast(msg: string, severity: 'info' | 'success' | 'error' = 'info') {
  host.toast({ severity, summary: msg, life: 4000 })
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

const visibleClusters = computed(() => {
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
const selectedChanges = computed(() => selectedCluster.value?.changes || [])

const counts = computed(() => git.snapshot.value?.counts || {
  all: 0, pending: 0, ready: 0, hidden: 0, suspect: 0, pushable_ready: 0, blocked_ready: 0,
})

const hasAnyClusters = computed(() => (git.snapshot.value?.clusters || []).length > 0)

const pushableClusters = computed(() =>
  (git.snapshot.value?.clusters || []).filter(c => c.decision === 'approved' && c.pushable))

const indexAgeText = computed(() => {
  const at = git.snapshot.value?.built_at
  if (!at) return 'never'
  const diff = Math.max(0, Math.floor((Date.now() - new Date(at).getTime()) / 60_000))
  if (diff < 1) return 'just now'
  if (diff === 1) return '1 min ago'
  if (diff < 60) return diff + ' min ago'
  return Math.floor(diff / 60) + ' h ago'
})

const blocking = computed(() => {
  const recs = selectedCluster.value?.recommendations
  if (!recs) return false
  return recs.some(r => r.severity === 'block' && r.state === 'open')
})

async function decide(id: string, decision: Decision) {
  try { await git.setDecision(id, decision) }
  catch (e: unknown) { showToast(errorMessage(e) || 'failed', 'error') }
}

async function ackRec(rid: string, state: RecState) {
  if (!selectedCluster.value) return
  try { await git.updateRecommendation(selectedCluster.value.id, rid, state) }
  catch (e: unknown) { showToast(errorMessage(e) || 'failed', 'error') }
}

async function rebuild(mode: 'manual' | 'ai') {
  try { await git.rebuild({ mode, sync_first: syncFirst.value }) }
  catch (e: unknown) { showToast(errorMessage(e) || 'rebuild failed', 'error') }
}

async function bulkPush() {
  const ids = pushableClusters.value.map(c => c.id)
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

// ── diff viewer ────────────────────────────────────────────────────────────
const diffPath = ref<string | null>(null)
const diffData = ref<import('../composables/useGit').FileDiff | null>(null)
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
const splitGroups = ref<import('../composables/useGit').SplitGroup[]>([])
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
function setSplitMode(m: 'ai' | 'by_prefix' | 'by_kind') {
  splitMode.value = m
  loadSplitProposal()
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
    <GitHeader
      :stale="git.stale.value"
      :rebuilding="git.rebuilding.value"
      :index-age-text="indexAgeText"
      :journal-size="git.snapshot.value?.journal_size_at_build ?? null"
      :counts="counts"
      :sync-first="syncFirst"
      @rebuild="rebuild"
      @push-confirm="confirmPushOpen = true"
      @update:sync-first="syncFirst = $event"
    />

    <main class="flex-1 grid grid-cols-[400px_1fr] overflow-hidden">
      <GitClusterList
        :clusters="visibleClusters"
        :counts="counts"
        :filter="filter"
        :selected-id="selectedCluster?.id ?? null"
        :loading="git.loading.value"
        :error="git.error.value"
        :has-any-clusters="hasAnyClusters"
        @update:filter="(v) => { filter = v; selectedId = null }"
        @select="(id) => selectedId = id"
      />

      <div v-if="!selectedCluster" class="overflow-y-auto" style="background: var(--p-surface-0)">
        <div class="p-12 text-center text-[12px] opacity-60">
          Pick a cluster on the left.
        </div>
      </div>
      <GitClusterDetail v-else
        :cluster="selectedCluster"
        :changes="selectedChanges"
        :blocking="blocking"
        :pushable-ready="counts.pushable_ready || 0"
        :expanded-recs="expandedRecs"
        :explaining="explaining"
        :explanations="explanations"
        @decide="decide"
        @ack-rec="ackRec"
        @explain-rec="explainRec"
        @open-split="openSplit"
        @open-diff="openDiff"
        @push-confirm="confirmPushOpen = true"
        @update:expanded-recs="expandedRecs = $event"
      />
    </main>

    <GitPushConfirmModal
      :open="confirmPushOpen"
      :count="counts.pushable_ready || 0"
      :pushing="git.pushing.value"
      :clusters="pushableClusters"
      @push="bulkPush"
      @close="confirmPushOpen = false"
    />

    <GitSplitModal
      :open="splitOpen && selectedCluster !== null"
      :title="selectedCluster?.title ?? ''"
      :change-count="selectedCluster?.change_count ?? 0"
      :changes="selectedCluster?.changes ?? null"
      :mode="splitMode"
      :groups="splitGroups"
      :loading="splitLoading"
      :applying="splitApplying"
      @update:mode="setSplitMode"
      @apply="applySplit"
      @close="closeSplit"
    />

    <GitDiffModal
      :path="diffPath"
      :data="diffData"
      :loading="diffLoading"
      @close="closeDiff"
    />
  </div>
</template>
