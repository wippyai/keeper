import { ref, computed, onUnmounted } from 'vue'
import type { Ref } from 'vue'

export type Importance = 'critical' | 'high' | 'normal' | 'cleanup' | 'suspect'
export type Verdict = 'ready' | 'closer_look' | 'do_not_push'
export type Decision = 'pending' | 'approved' | 'skipped' | 'split' | 'orphan' | 'pushed'
export type Severity = 'info' | 'warn' | 'block'
export type RecState = 'open' | 'acknowledged' | 'fixed' | 'split'

export interface Recommendation {
  id: string
  severity: Severity
  text: string
  fix_hint?: string | null
  change_id?: string | null
  state: RecState
  detail?: string
  detail_model?: string
}

export interface ClusterStats {
  files: number
  added: number
  removed: number
  namespaces: string[]
}

export interface ClusterSummary {
  id: string
  title: string
  plain_summary: string
  importance: Importance
  verdict: Verdict
  verdict_text: string
  decision: Decision
  change_count: number
  rec_open: number
  stats?: ClusterStats
  source?: string
  pushable?: boolean
  push_blockers?: string[]
}

export interface ClusterChange {
  change_id: string
  changeset_id?: string
  path: string
  op: 'create' | 'update' | 'delete' | 'write'
  category: 'registry' | 'filesystem'
  ns_root: string
  namespace?: string
  managed_namespace?: boolean
  source?: string
  added: number
  removed: number
}

export interface ClusterFull extends ClusterSummary {
  change_ids: string[]
  changes?: ClusterChange[]
  changeset_ids?: string[]
  primary_changeset_id?: string | null
  is_suspect?: boolean
  recommendations: Recommendation[]
}

export interface DiffHunkLine {
  kind: '+' | '-' | ' '
  text: string
  old_no?: number
  new_no?: number
}
export interface DiffHunk {
  header: string
  lines: DiffHunkLine[]
}
export interface FileDiff {
  path: string
  diff_text: string
  hunks: DiffHunk[]
  exit_code: number
}

export interface SnapshotCounts {
  all: number
  pending: number
  ready: number
  hidden: number
  suspect: number
  pushable_ready?: number
  blocked_ready?: number
}

export interface Snapshot {
  run_id: string | null
  built_at: string | null
  journal_size_at_build: number
  ai_model: string | null
  clusters: ClusterSummary[]
  counts: SnapshotCounts
  stale: boolean
  in_progress?: boolean
}

export interface PushResult {
  cluster_id: string
  ok: boolean
  version?: string
  added?: number
  modified?: number
  deleted?: number
  error?: string
}

export interface PushResponse {
  ok: boolean
  results: PushResult[]
  pushed: number
  failed: number
}

export interface SplitGroup {
  title: string
  plain_summary?: string
  change_ids: string[]
}

interface ApiClient {
  get<T = unknown>(path: string, opts?: unknown): Promise<{ data: T }>
  post<T = unknown>(path: string, body?: unknown): Promise<{ data: T }>
  patch<T = unknown>(path: string, body?: unknown): Promise<{ data: T }>
}

interface RelaySource {
  on(topic: string, cb: (evt: unknown) => void): () => void
}

type ApiFailure = { success: false; error?: string }
type ApiResponse<T> = ApiFailure | ({ success: true } & T)

interface RelayPayload {
  event?: string
  request_id?: string
  snapshot?: Snapshot
  cluster_id?: string
  decision?: Decision
  error?: string
  text?: string
  groups?: SplitGroup[]
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function errorMessage(value: unknown): string {
  return value instanceof Error ? value.message : String(value)
}

function payloadError(value: unknown): string {
  if (isRecord(value) && typeof value.error === 'string') return value.error
  return 'task failed'
}

function relayPayload(raw: unknown): RelayPayload {
  if (!isRecord(raw)) return {}
  return isRecord(raw.data) ? raw.data as RelayPayload : raw as RelayPayload
}

function genRequestId(): string {
  return 'req-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8)
}

function recomputeCounts(list: ClusterSummary[]): SnapshotCounts {
  const counts: SnapshotCounts = {
    all: list.length,
    pending: 0,
    ready: 0,
    hidden: 0,
    suspect: 0,
    pushable_ready: 0,
    blocked_ready: 0,
  }
  for (const c of list) {
    if (c.decision === 'pending') counts.pending += 1
    else if (c.decision === 'approved') {
      counts.ready += 1
      if (c.pushable) counts.pushable_ready = (counts.pushable_ready || 0) + 1
      else counts.blocked_ready = (counts.blocked_ready || 0) + 1
    } else if (c.decision === 'skipped' || c.decision === 'split' || c.decision === 'pushed') {
      counts.hidden += 1
    }
    if (c.importance === 'suspect' || c.decision === 'orphan') counts.suspect += 1
  }
  return counts
}

interface Pending {
  resolve: (value: unknown) => void
  reject: (err: Error) => void
  timer: ReturnType<typeof setTimeout>
}

export function useGit(api: ApiClient, relay?: RelaySource) {
  const snapshot: Ref<Snapshot | null> = ref(null)
  const loading = ref(false)
  const rebuilding = ref(false)
  const pushing = ref(false)
  const error = ref<string | null>(null)
  const detail: Ref<ClusterFull | null> = ref(null)

  // request_id -> resolver. The keeper.git relay broadcasts every async task's
  // completion event; we look up the matching pending entry and settle it.
  // 180s ceiling so a missed event eventually rejects instead of hanging.
  const TASK_TIMEOUT_MS = 180_000
  const pendingTasks = new Map<string, Pending>()

  function trackTask<T>(request_id: string): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const timer = setTimeout(() => {
        pendingTasks.delete(request_id)
        reject(new Error('event timeout — request_id ' + request_id + ' never arrived'))
      }, TASK_TIMEOUT_MS)
      pendingTasks.set(request_id, { resolve: value => resolve(value as T), reject, timer })
    })
  }
  function settleTask(request_id: string, ok: boolean, payload: unknown) {
    const p = pendingTasks.get(request_id)
    if (!p) return
    clearTimeout(p.timer)
    pendingTasks.delete(request_id)
    if (ok) p.resolve(payload); else p.reject(new Error(payloadError(payload)))
  }

  let unsubRelay: (() => void) | null = null

  if (relay) {
    unsubRelay = relay.on('keeper.git', (raw: unknown) => {
      const data = relayPayload(raw)
      const ev = data.event
      if (typeof ev !== 'string') return

      if (ev === 'git.rebuild.finished' && data.snapshot) {
        snapshot.value = { ...data.snapshot, in_progress: false }
      } else if (ev === 'git.cluster.decision_changed' && snapshot.value) {
        const c = snapshot.value.clusters.find(x => x.id === data.cluster_id)
        if (c && data.decision) c.decision = data.decision
        snapshot.value.counts = recomputeCounts(snapshot.value.clusters)
      } else if (ev === 'git.index.stale' && snapshot.value) {
        snapshot.value.stale = true
      }

      const rid = data.request_id
      if (rid && (ev.endsWith('.finished') || ev.endsWith('.failed'))) {
        settleTask(rid, ev.endsWith('.finished'), data)
      }
    })
  }

  onUnmounted(() => {
    unsubRelay?.()
  })

  async function refresh() {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get<ApiResponse<{ snapshot: Snapshot }>>('/api/v1/keeper/git/clusters')
      if (!data.success) { error.value = data.error || 'failed'; return }
      snapshot.value = data.snapshot
    } catch (e: unknown) {
      error.value = errorMessage(e)
    } finally {
      loading.value = false
    }
  }

  async function rebuild(opts: {
    mode?: 'manual' | 'ai'
    model?: string
    max_changes?: number
    sync_first?: boolean
    tracked_dirs?: string[]
    diff_base?: string
  } = {}) {
    rebuilding.value = true
    error.value = null
    try {
      const request_id = genRequestId()
      const body = { ...opts, request_id }
      const { data } = await api.post<ApiResponse<{ snapshot: Snapshot }>>('/api/v1/keeper/git/rebuild', body)
      if (!data.success) { error.value = data.error || 'rebuild failed'; return }
      snapshot.value = data.snapshot

      // AI mode is async; await the rebuild.finished relay event by request_id.
      // Without a relay we just leave the in-progress snapshot up — caller has refresh().
      if (data.snapshot?.in_progress && relay) {
        const final = await trackTask<RelayPayload>(request_id)
        if (final?.snapshot) snapshot.value = { ...final.snapshot, in_progress: false }
      }
    } catch (e: unknown) {
      error.value = errorMessage(e)
    } finally {
      rebuilding.value = false
    }
  }

  async function loadCluster(id: string) {
    const { data } = await api.get<ApiResponse<{ cluster: ClusterFull }>>(`/api/v1/keeper/git/clusters/${id}`)
    if (!data.success) throw new Error(data.error || 'cluster not found')
    detail.value = data.cluster
    return data.cluster
  }

  async function setDecision(id: string, decision: Decision) {
    const { data } = await api.patch<ApiResponse<Record<string, never>>>(`/api/v1/keeper/git/clusters/${id}/decision`, { decision })
    if (!data.success) throw new Error(data.error || 'set_decision failed')
    if (snapshot.value) {
      const c = snapshot.value.clusters.find(x => x.id === id)
      if (c) c.decision = decision
      snapshot.value.counts = recomputeCounts(snapshot.value.clusters)
    }
    if (detail.value && detail.value.id === id) detail.value.decision = decision
  }

  async function updateRecommendation(cid: string, rid: string, state: RecState) {
    const { data } = await api.patch<ApiResponse<Record<string, never>>>(
      `/api/v1/keeper/git/clusters/${cid}/recommendations/${rid}`,
      { state },
    )
    if (!data.success) throw new Error(data.error || 'update_recommendation failed')
    if (detail.value && detail.value.id === cid) {
      const r = detail.value.recommendations.find(x => x.id === rid)
      if (r) r.state = state
    }
    await refresh()
  }

  async function suggestSplit(cluster_id: string, opts: { mode?: 'ai' | 'by_prefix' | 'by_kind'; depth?: number; model?: string } = {}) {
    const request_id = genRequestId()
    const { data } = await api.post<ApiResponse<{ mode?: string; groups?: SplitGroup[]; model?: string; duration_ms?: number }>>(
      `/api/v1/keeper/git/clusters/${cluster_id}/suggest-split`,
      { ...opts, request_id },
    )
    if (!data.success) throw new Error(data.error || 'suggest_split failed')

    // Deterministic modes return groups inline.
    if (data.mode !== 'ai' || data.groups) return data

    if (!relay) throw new Error('AI suggest requires a relay subscriber')
    const final = await trackTask<RelayPayload>(request_id)
    return { ...data, ...final }
  }

  async function splitCluster(cluster_id: string, groups: SplitGroup[]) {
    const { data } = await api.post<ApiResponse<{ snapshot: Snapshot }>>(
      `/api/v1/keeper/git/clusters/${cluster_id}/split`,
      { groups },
    )
    if (!data.success) throw new Error(data.error || 'split failed')
    snapshot.value = data.snapshot
    return data.snapshot
  }

  async function explainRecommendation(cluster_id: string, rec_id: string, force = false) {
    const request_id = genRequestId()
    const { data } = await api.post<ApiResponse<{ cluster_id?: string; recommendation_id?: string; text?: string; model?: string; cached?: boolean }>>(
      `/api/v1/keeper/git/clusters/${cluster_id}/recommendations/${rec_id}/explain`,
      { force, request_id },
    )
    if (!data.success) throw new Error(data.error || 'explain failed')

    // Cached path returns the text inline.
    if (data.cached || data.text) {
      if (detail.value && detail.value.id === cluster_id) {
        const r = detail.value.recommendations.find(x => x.id === rec_id)
        if (r) r.detail = data.text
      }
      return data
    }

    if (!relay) throw new Error('Explain requires a relay subscriber')
    const final = await trackTask<RelayPayload>(request_id)
    if (detail.value && detail.value.id === cluster_id) {
      const r = detail.value.recommendations.find(x => x.id === rec_id)
      if (r) r.detail = final.text
    }
    return final
  }

  async function fetchDiff(path: string): Promise<FileDiff> {
    const { data } = await api.get<ApiResponse<FileDiff>>('/api/v1/keeper/git/diff', { params: { path } })
    if (!data.success) throw new Error(data.error || 'diff failed')
    return {
      path: data.path,
      diff_text: data.diff_text || '',
      hunks: data.hunks || [],
      exit_code: data.exit_code,
    }
  }

  async function pushApproved(cluster_ids: string[], message?: string): Promise<PushResponse> {
    pushing.value = true
    try {
      const { data } = await api.post<ApiResponse<PushResponse>>('/api/v1/keeper/git/push', { cluster_ids, message })
      if (!data.success) throw new Error(data.error || 'push failed')
      await refresh()
      return data
    } finally {
      pushing.value = false
    }
  }

  const readyCount = computed(() => snapshot.value?.counts.ready || 0)
  const stale = computed(() => snapshot.value?.stale || false)

  onUnmounted(() => {
    pendingTasks.forEach(p => clearTimeout(p.timer))
    pendingTasks.clear()
  })

  return {
    snapshot, loading, rebuilding, pushing, error, detail,
    readyCount, stale,
    refresh, rebuild, loadCluster, setDecision, updateRecommendation,
    explainRecommendation, fetchDiff, suggestSplit, splitCluster, pushApproved,
  }
}
