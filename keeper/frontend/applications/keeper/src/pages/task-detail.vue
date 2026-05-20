<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import {
  getTask, listTaskNodes, startCycle, syncResearch,
  type Task, type TaskStats, type TaskNode,
} from '../api/tasks'
import MarkdownContent from '../components/shared/MarkdownContent.vue'

const route = useRoute()
const router = useRouter()
const api = useApi()
const host = useHost()
const instance = useWippy()

const taskId = computed(() => route.params.id as string)
const task = ref<Task | null>(null)
const stats = ref<TaskStats | null>(null)
const nodes = ref<TaskNode[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const startingCycle = ref(false)
const cancelling = ref(false)
const showDebug = ref(false)
const tab = ref<'timeline' | 'plan' | 'spec' | 'findings' | 'integrations' | 'data'>('timeline')
const expanded = ref<Record<string, boolean>>({})
const userResponse = ref('')
const responding = ref(false)

// -- sidebar resize ---------------------------------------------------------
const SIDEBAR_MIN = 240
const SIDEBAR_MAX = 640
const sidebarWidth = ref<number>(Number(localStorage.getItem('keeper.task.sidebar') || 280))
if (isNaN(sidebarWidth.value) || sidebarWidth.value < SIDEBAR_MIN) sidebarWidth.value = 280
const isResizing = ref(false)
function goBack() {
  if (window.history.length > 1) router.back()
  else router.push('/tasks')
}

function copyText(value?: string | null) {
  if (!value) return
  void window.navigator.clipboard?.writeText(value)
}

function startResize(e: MouseEvent) {
  e.preventDefault()
  isResizing.value = true
  const startX = e.clientX
  const startW = sidebarWidth.value
  const onMove = (ev: MouseEvent) => {
    const next = Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, startW + (ev.clientX - startX)))
    sidebarWidth.value = next
  }
  const onUp = () => {
    isResizing.value = false
    document.removeEventListener('mousemove', onMove)
    document.removeEventListener('mouseup', onUp)
    localStorage.setItem('keeper.task.sidebar', String(sidebarWidth.value))
  }
  document.addEventListener('mousemove', onMove)
  document.addEventListener('mouseup', onUp)
}

// -- load -------------------------------------------------------------------
async function load() {
  loading.value = true; error.value = null
  try {
    await syncResearch(api, taskId.value).catch(() => {})
    const [det, nd] = await Promise.all([
      getTask(api, taskId.value),
      listTaskNodes(api, taskId.value, {
        visibility: showDebug.value ? 'user,debug' : 'user',
        limit: 2000,
      }),
    ])
    task.value = det.task
    stats.value = det.stats
    nodes.value = nd.nodes || []
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { loading.value = false }
}

async function handleStartCycle(autoApprove = false) {
  if (!task.value) return
  startingCycle.value = true; error.value = null
  try {
    await startCycle(api, task.value.task_id, { auto_approve: autoApprove })
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { startingCycle.value = false }
}

async function handleCancel() {
  if (!task.value) return
  if (!await host.confirm({
    header: 'Cancel task',
    message: 'Active dataflows will be terminated and the changeset dropped.',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
  })) return
  cancelling.value = true; error.value = null
  try {
    await api.put(`/api/v1/keeper/tasks/${task.value.task_id}`, { status: 'abandoned' })
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { cancelling.value = false }
}

async function handleRespond() {
  if (!task.value || !userResponse.value.trim()) return
  responding.value = true; error.value = null
  try {
    await api.post(`/api/v1/keeper/tasks/${task.value.task_id}/respond`,
      { response: userResponse.value })
    userResponse.value = ''
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { responding.value = false }
}

// -- helpers ----------------------------------------------------------------
function fmtMs(ms?: number | null) {
  if (ms == null) return ''
  if (ms < 1000) return ms + 'ms'
  if (ms < 60_000) return (ms / 1000).toFixed(1) + 's'
  return Math.floor(ms / 60_000) + 'm' + Math.floor((ms / 1000) % 60) + 's'
}
function fmtTime(tsMs: number) {
  if (!tsMs) return ''
  const d = new Date(tsMs)
  return d.toLocaleTimeString('en-US', { hour12: false })
}
function fmtDuration(fromMs: number, toMs?: number) {
  if (!fromMs) return ''
  const end = toMs || Date.now()
  const s = Math.round((end - fromMs) / 1000)
  if (s < 60) return s + 's'
  if (s < 3600) return Math.floor(s / 60) + 'm ' + (s % 60) + 's'
  return Math.floor(s / 3600) + 'h ' + Math.floor((s / 60) % 60) + 'm'
}
function toggle(id: string) { expanded.value[id] = !expanded.value[id] }

const PHASE_META: Record<string, { color: string; icon: string; label: string }> = {
  setup:     { color: 'var(--p-text-muted-color)', icon: 'tabler:player-play',   label: 'Setup' },
  research:  { color: 'var(--p-info-500)', icon: 'tabler:search',        label: 'Research' },
  design:    { color: 'var(--p-text-muted-color)', icon: 'tabler:layout-grid',   label: 'Design' },
  plan:      { color: 'var(--p-accent-500)', icon: 'tabler:list-tree',     label: 'Plan' },
  implement: { color: 'var(--p-warn-500)', icon: 'tabler:code',          label: 'Implement' },
  review:    { color: 'var(--p-warn-500)', icon: 'tabler:eye-check',     label: 'Review' },
  integrate: { color: 'var(--p-info-500)', icon: 'tabler:rocket',        label: 'Integrate' },
  test:      { color: 'var(--p-success-500)', icon: 'tabler:test-pipe',     label: 'Test' },
  rollback:  { color: 'var(--p-danger-500)', icon: 'tabler:arrow-back-up', label: 'Rollback' },
  finish:    { color: 'var(--p-success-500)', icon: 'tabler:circle-check',  label: 'Finish' },
  abandoned: { color: 'var(--p-danger-500)', icon: 'tabler:ban',           label: 'Abandoned' },
}
function phaseMeta(p: string) {
  return PHASE_META[p] || { color: 'var(--p-text-muted-color)', icon: 'tabler:circle-dot', label: p }
}

const AGENT_META: Record<string, { color: string; icon: string; label: string }> = {
  research_orchestrator:  { color: 'var(--p-info-500)', icon: 'tabler:search',       label: 'research' },
  design_orchestrator:    { color: 'var(--p-accent-500)', icon: 'tabler:layout-grid',  label: 'design' },
  implement_orchestrator: { color: 'var(--p-warn-500)', icon: 'tabler:code',         label: 'implement' },
  review_orchestrator:    { color: 'var(--p-warn-500)', icon: 'tabler:eye-check',    label: 'review' },
  test_orchestrator:      { color: 'var(--p-success-500)', icon: 'tabler:test-pipe',    label: 'test' },
  researcher:             { color: 'var(--p-info-500)', icon: 'tabler:book-2',       label: 'researcher' },
  developer:              { color: 'var(--p-warn-500)', icon: 'tabler:terminal-2',   label: 'developer' },
  fe_developer:           { color: 'var(--p-accent-500)', icon: 'tabler:brand-vue',    label: 'fe_developer' },
  reviewer:               { color: 'var(--p-warn-400)', icon: 'tabler:eye',          label: 'reviewer' },
}
function shortAgentId(id: string): string {
  return id
    .replace(/^keeper\.develop\.context\.agents:/, 'ctx:')
    .replace(/^keeper\.agents(?:\.[a-z_.]+)?:/, '')
}
function agentMeta(id?: string | null) {
  if (!id) return null
  const base = shortAgentId(id)
  const meta = AGENT_META[base]
  if (meta) return meta
  if (base.startsWith('ctx:')) {
    return { color: 'var(--p-info-400)', icon: 'tabler:file-search', label: base }
  }
  return { color: 'var(--p-text-muted-color)', icon: 'tabler:user', label: base }
}

const NODE_META: Record<string, { color: string; icon: string; label: string }> = {
  tool_call:         { color: 'var(--p-text-muted-color)', icon: 'tabler:terminal',          label: 'tool' },
  finding:           { color: 'var(--p-success-500)', icon: 'tabler:bookmark',          label: 'finding' },
  spec:              { color: 'var(--p-accent-500)', icon: 'tabler:file-text',         label: 'spec' },
  plan:              { color: 'var(--p-accent-500)', icon: 'tabler:list-tree',         label: 'plan' },
  step:              { color: 'var(--p-warn-500)', icon: 'tabler:list-check',        label: 'step' },
  phase_event:       { color: 'var(--p-info-500)', icon: 'tabler:flag',              label: 'event' },
  phase_spawn_failed:{ color: 'var(--p-danger-500)', icon: 'tabler:alert-circle',      label: 'spawn_failed' },
  integrate_stage:   { color: 'var(--p-info-500)', icon: 'tabler:rocket',            label: 'stage' },
  ask_user:          { color: 'var(--p-warn-400)', icon: 'tabler:help-circle',       label: 'ask_user' },
  user_response:     { color: 'var(--p-warn-400)', icon: 'tabler:user',              label: 'user' },
  override:          { color: 'var(--p-warn-500)', icon: 'tabler:switch-horizontal', label: 'override' },
  error:             { color: 'var(--p-danger-500)', icon: 'tabler:alert-circle',      label: 'error' },
  decision:          { color: 'var(--p-accent-400)', icon: 'tabler:brain',             label: 'decision' },
  phase_transition:  { color: 'var(--p-text-muted-color)', icon: 'tabler:arrow-right',       label: 'transition' },
}
function nodeMeta(t: string) {
  return NODE_META[t] || { color: 'var(--p-text-muted-color)', icon: 'tabler:circle-dot', label: t }
}

function nodeLabel(n: TaskNode): string {
  const md = (n.metadata || {}) as Record<string, any>
  if (n.type === 'tool_call') {
    const tool = md.tool || n.discriminator?.split('.')[0] || 'tool'
    const target = md.target
    return target ? `${tool}(${target})` : String(tool)
  }
  if (n.type === 'finding') return n.title || (n.discriminator || 'finding')
  if (n.type === 'spec') return n.title || `spec #${n.discriminator || ''}`
  if (n.type === 'integrate_stage') return n.discriminator || n.title
  if (n.type === 'phase_event') return n.discriminator || n.title
  return n.title || n.type
}

// Per-tool icons. The fs/edit tools route through a single registry id but
// represent different operations (view / create / str_replace / delete) —
// distinguishing them visually keeps a column of fs.* rows scannable.
const TOOL_ICON_OVERRIDES: Record<string, string> = {
  'fs.view':           'tabler:eye',
  'fs.create':         'tabler:file-plus',
  'fs.str_replace':    'tabler:edit',
  'fs.rewrite':        'tabler:refresh',
  'fs.delete':         'tabler:trash',
  'fs.search':         'tabler:search',
  'edit.create':       'tabler:file-plus',
  'edit.str_replace':  'tabler:edit',
  'edit.delete':       'tabler:trash',
  'compare.tree':      'tabler:git-compare',
  'compare.entries':   'tabler:git-compare',
  'get_entries.full':  'tabler:database',
  'get_entries.meta':  'tabler:database',
  'explore.tree':      'tabler:hierarchy-2',
  'save_context':      'tabler:bookmark-plus',
  'read_context':      'tabler:bookmarks',
  'write_spec':        'tabler:file-text',
  'write_plan':        'tabler:list-tree',
  'step_done':         'tabler:circle-check',
  'step_block':        'tabler:circle-x',
  'implement_task':    'tabler:rocket',
  'search_knowledge':  'tabler:book',
  'kb_read':           'tabler:book',
  'fetch_docs':        'tabler:book-2',
  'run_test':          'tabler:test-pipe',
  'lint_branch':       'tabler:checks',
  'push':              'tabler:upload',
  'set_branch':        'tabler:git-branch',
}
function toolIcon(n: TaskNode): string {
  if (n.type !== 'tool_call') return nodeMeta(n.type).icon
  const md = (n.metadata || {}) as Record<string, any>
  const tool = String(md.tool || '')
  const disc = String(n.discriminator || '')
  if (TOOL_ICON_OVERRIDES[disc]) return TOOL_ICON_OVERRIDES[disc]
  if (TOOL_ICON_OVERRIDES[tool]) return TOOL_ICON_OVERRIDES[tool]
  // Catch-all by tool family.
  if (disc.startsWith('fs.') || tool === 'fs') return 'tabler:file'
  if (disc.startsWith('edit.') || tool === 'edit') return 'tabler:edit'
  if (disc.startsWith('compare.') || tool === 'compare_state_branches') return 'tabler:git-compare'
  if (disc.startsWith('explore') || tool === 'explore_state') return 'tabler:hierarchy-2'
  if (disc.startsWith('get_entries')) return 'tabler:database'
  return nodeMeta(n.type).icon
}

// Edits shipped via fs/edit tools carry their input as JSON content. For
// str_replace and create commands we want a quick before/after preview
// when expanding an edit row, not raw JSON.
type EditPreview =
  | { kind: 'str_replace'; path: string; old: string; new: string }
  | { kind: 'create';      path: string; content: string }
  | { kind: 'view';        path: string }
  | { kind: 'delete';      path: string }
  | null

function parseEditPreview(n: TaskNode): EditPreview {
  if (n.type !== 'tool_call') return null
  if (!n.content || typeof n.content !== 'string') return null
  if (n.content_type !== 'application/json') return null
  let parsed: any
  try { parsed = JSON.parse(n.content) } catch { return null }
  if (!parsed || typeof parsed !== 'object') return null
  const cmd = parsed.command
  const path = parsed.path || parsed.target || ''
  if (cmd === 'str_replace') {
    return {
      kind: 'str_replace',
      path,
      old: String(parsed.old_str ?? ''),
      new: String(parsed.new_str ?? ''),
    }
  }
  if (cmd === 'create' || cmd === 'rewrite') {
    return {
      kind: 'create',
      path,
      content: String(parsed.file_text ?? parsed.content ?? ''),
    }
  }
  if (cmd === 'view') return { kind: 'view', path }
  if (cmd === 'delete') return { kind: 'delete', path }
  return null
}

// -- node grouping by phase -------------------------------------------------
type PhaseBlock = {
  phase: string
  startedAt: number
  endedAt: number | null
  exitSignal: string | null
  startNode: TaskNode | null
  entries: TaskNode[]
}

const timelineBlocks = computed<PhaseBlock[]>(() => {
  const blocks: PhaseBlock[] = []
  let current: PhaseBlock | null = null
  for (const n of nodes.value) {
    if (n.type === 'phase_started' && n.discriminator) {
      if (current) { current.endedAt = n.created_at }
      current = {
        phase: n.discriminator,
        startedAt: n.created_at,
        endedAt: null,
        exitSignal: null,
        startNode: n,
        entries: [],
      }
      blocks.push(current)
      continue
    }
    if (n.type === 'phase_exited' && current && current.phase === n.discriminator) {
      current.endedAt = n.created_at
      current.exitSignal = (n.metadata && (n.metadata.signal as string)) || n.title || null
      continue
    }
    if (n.type === 'phase_transition') {
      continue
    }
    if (current) { current.entries.push(n); continue }
    // Pre-first-phase rows (cycle_start, initial baseline). Bucket them into
    // a "setup" block so they don't stay pinned as an open-ended "unknown"
    // block for the whole task lifetime.
    if (!blocks.length || blocks[0].phase !== 'setup') {
      blocks.unshift({
        phase: 'setup',
        startedAt: n.created_at,
        endedAt: n.created_at,
        exitSignal: null,
        startNode: null,
        entries: [n],
      })
    } else {
      const setup = blocks[0]
      setup.entries.push(n)
      setup.endedAt = n.created_at
    }
  }
  return blocks
})

// -- timeline: fold all keeper agents' tool_calls into per-agent buckets ---
// Every keeper agent (orchestrators, specialists, researcher, context-chain
// agents) emits multiple tool calls per phase. Folding them per-agent within
// a phase block keeps the phase scannable: one foldable row per agent, with
// expanded view showing the actual calls.
function isGroupableAgent(id: string | null | undefined): boolean {
  if (!id) return false
  if (id.startsWith('keeper.agents:')) return true
  if (id.startsWith('keeper.develop.context.agents:')) return true
  return false
}

type GroupEntry =
  | { kind: 'single'; node: TaskNode }
  | { kind: 'burst'; agentId: string; nodes: TaskNode[]; startedAt: number; endedAt: number; errors: number }

function groupedEntries(entries: TaskNode[]): GroupEntry[] {
  // Within a phase block, fold every tool_call from a groupable agent into
  // a single burst — even if the agent's calls interleave with another
  // agent's. The bucket "appears" at the first call's position so non-tool
  // rows (findings, specs, plan steps) keep their relative order.
  const buckets = new Map<string, { firstIdx: number; nodes: TaskNode[] }>()
  for (let i = 0; i < entries.length; i++) {
    const n = entries[i]
    if (n.type !== 'tool_call' || !isGroupableAgent(n.agent_id)) continue
    const id = n.agent_id!
    const b = buckets.get(id)
    if (b) b.nodes.push(n)
    else buckets.set(id, { firstIdx: i, nodes: [n] })
  }

  const out: GroupEntry[] = []
  const emittedBucket = new Set<string>()
  for (let i = 0; i < entries.length; i++) {
    const n = entries[i]
    if (n.type === 'tool_call' && isGroupableAgent(n.agent_id)) {
      const id = n.agent_id!
      const b = buckets.get(id)!
      if (b.firstIdx !== i) continue            // skip — already emitted at firstIdx
      if (b.nodes.length === 1) {
        out.push({ kind: 'single', node: b.nodes[0] })
      } else {
        const sorted = [...b.nodes].sort((a, c) => a.created_at - c.created_at)
        out.push({
          kind: 'burst',
          agentId: id,
          nodes: sorted,
          startedAt: sorted[0].created_at,
          endedAt: sorted[sorted.length - 1].created_at,
          errors: sorted.filter(c => c.status === 'failed' || c.error_message).length,
        })
      }
      emittedBucket.add(id)
      continue
    }
    out.push({ kind: 'single', node: n })
  }
  return out
}

// -- tab: spec --------------------------------------------------------------
const specs = computed(() => nodes.value.filter(n => n.type === 'spec')
  .sort((a, b) => b.seq - a.seq))
const currentSpec = computed(() => specs.value.find(s => s.status === 'active') || specs.value[0])

// -- tab: plan --------------------------------------------------------------
const activePlan = computed(() => {
  const plans = nodes.value.filter(n => n.type === 'plan')
    .sort((a, b) => b.seq - a.seq)
  return plans.find(p => p.status === 'active') || plans[0] || null
})
const planSteps = computed(() => {
  const plan = activePlan.value
  if (!plan) return []
  return nodes.value.filter(n => n.type === 'step' && n.parent_node_id === plan.node_id)
    .sort((a, b) => a.position - b.position)
})
const planDone = computed(() => planSteps.value.filter(s =>
  s.status === 'completed' || s.status === 'superseded').length)
const planBlocked = computed(() => planSteps.value.filter(s => s.status === 'blocked').length)

const STEP_KIND_META: Record<string, { icon: string; color: string }> = {
  impl:            { icon: 'tabler:code',          color: 'var(--p-warn-500)' },
  migration:       { icon: 'tabler:database',      color: 'var(--p-accent-500)' },
  fs_write:        { icon: 'tabler:file-code',     color: 'var(--p-accent-500)' },
  test_create:     { icon: 'tabler:test-pipe',     color: 'var(--p-success-500)' },
  test_run:        { icon: 'tabler:check',         color: 'var(--p-success-500)' },
  endpoint_probe:  { icon: 'tabler:plug',          color: 'var(--p-info-500)' },
  view_probe:      { icon: 'tabler:eye',           color: 'var(--p-accent-400)' },
  verify:          { icon: 'tabler:shield-check', color: 'var(--p-info-500)' },
  research:        { icon: 'tabler:search',        color: 'var(--p-info-500)' },
}
function stepKindMeta(k?: string) {
  return (k && STEP_KIND_META[k]) || { icon: 'tabler:circle-dot', color: 'var(--p-text-muted-color)' }
}
const STEP_STATUS_META: Record<string, { color: string; label: string }> = {
  pending:    { color: 'var(--p-text-muted-color)', label: 'pending' },
  active:     { color: 'var(--p-warn-500)', label: 'active' },
  blocked:    { color: 'var(--p-danger-500)', label: 'blocked' },
  completed:  { color: 'var(--p-success-500)', label: 'done' },
  superseded: { color: 'var(--p-text-muted-color)', label: 'superseded' },
  failed:     { color: 'var(--p-danger-500)', label: 'failed' },
}
function stepStatusMeta(s?: string | null) {
  return (s && STEP_STATUS_META[s]) || { color: 'var(--p-text-muted-color)', label: s || '?' }
}

// -- tab: findings ----------------------------------------------------------
const findings = computed(() => {
  // dedup on discriminator; latest seq wins
  const map = new Map<string, TaskNode>()
  for (const n of nodes.value) {
    if (n.type !== 'finding') continue
    const key = n.discriminator || n.node_id
    const prev = map.get(key)
    if (!prev || n.seq > prev.seq) map.set(key, n)
  }
  return [...map.values()].sort((a, b) => a.seq - b.seq)
})

// -- tab: integrations ------------------------------------------------------
// Top-level integrate_stage rows (those with no parent_node_id, or whose parent isn't in the list).
const integrateRuns = computed(() => {
  const all = nodes.value.filter(n => n.type === 'integrate_stage' || n.type === 'rollback_stage')
  const ids = new Set(all.map(n => n.node_id))
  return all.filter(n => !n.parent_node_id || !ids.has(n.parent_node_id))
    .sort((a, b) => b.seq - a.seq)
})
function childrenOf(parentId: string) {
  return nodes.value.filter(n => n.parent_node_id === parentId)
    .sort((a, b) => a.position - b.position)
}

// -- bounce counts ----------------------------------------------------------
const bounces = computed(() => {
  const counts: Record<string, number> = {}
  for (const n of nodes.value) {
    if (n.type !== 'phase_transition' || !n.discriminator) continue
    counts[n.discriminator] = (counts[n.discriminator] || 0) + 1
  }
  return counts
})

// -- integrate summary for top bar -----------------------------------------
const lastIntegrate = computed(() => {
  const runs = nodes.value.filter(n => n.type === 'integrate_stage' && !n.parent_node_id)
    .sort((a, b) => b.seq - a.seq)
  return runs[0] || null
})

// -- isWaitingForUser + question --------------------------------------------
const isWaitingForUser = computed(() => task.value?.status === 'waiting_for_user')
const lastQuestion = computed(() => {
  for (let i = nodes.value.length - 1; i >= 0; i--) {
    const n = nodes.value[i]
    if (n.type === 'ask_user' && n.status === 'active') {
      return n.content
    }
  }
  return null
})

onMounted(load)

// re-fetch on visibility change
function onVisible() { if (document.visibilityState === 'visible') load() }
onMounted(() => { document.addEventListener('visibilitychange', onVisible) })
onUnmounted(() => { document.removeEventListener('visibilitychange', onVisible) })

// Real-time: subscribe to keeper.task topic (nodes_writer + task writer publish here)
// plus a short-interval poll as a safety net in case relay hiccups.
let pollTimer: number | null = null
let relayOff: (() => void) | null = null
function isLive() {
  const s = task.value?.status
  return s === 'active' || s === 'waiting_for_user'
}
let pendingLoad: number | null = null
function scheduleLoad() {
  if (pendingLoad != null) return
  pendingLoad = window.setTimeout(() => {
    pendingLoad = null
    if (document.visibilityState === 'visible') load()
  }, 250) // coalesce bursts
}
function startPolling() {
  if (pollTimer) return
  pollTimer = window.setInterval(() => {
    if (isLive() && document.visibilityState === 'visible') load()
  }, 6000)
}
function stopPolling() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
  if (pendingLoad != null) { clearTimeout(pendingLoad); pendingLoad = null }
  if (relayOff) { relayOff(); relayOff = null }
}
onMounted(() => {
  startPolling()
  // keeper.task carries task.created/updated + node.created/updated per task_consts.EVENTS
  const handler = (evt: any) => {
    const data = evt?.data
    if (!data) return
    if (data.task_id && data.task_id !== taskId.value) return
    scheduleLoad()
  }
  relayOff = instance.on('keeper.task', handler)
})
onUnmounted(stopPolling)

const changesetId = computed(() => {
  for (const n of nodes.value) if (n.changeset_id) return n.changeset_id
  return null
})
const dataflowId = computed(() => {
  for (const n of nodes.value) if (n.dataflow_id) return n.dataflow_id
  return null
})
</script>

<template>
  <div class="h-full flex">
    <!-- LEFT SIDEBAR (task meta + phase rails mini-nav) -->
    <aside :style="{ width: sidebarWidth + 'px' }"
      class="shrink-0 flex flex-col border-r overflow-hidden"
      style="background: var(--p-surface-50); border-color: var(--p-content-border-color)">
      <div class="px-4 py-3 border-b" style="border-color: var(--p-content-border-color)">
        <button @click="goBack" class="text-[10px] opacity-60 hover:opacity-100 flex items-center gap-1">
          <Icon icon="tabler:arrow-left" class="w-3 h-3" /> Back
        </button>
        <h2 v-if="task" class="mt-1 text-[13px] font-semibold" :title="task.title">{{ task.title }}</h2>
        <div v-if="task" class="mt-2 flex items-center gap-2 text-[10px]">
          <span class="px-1.5 py-0.5 rounded"
            :style="{ background: phaseMeta(task.phase).color + '20', color: phaseMeta(task.phase).color }">
            <Icon :icon="phaseMeta(task.phase).icon" class="w-3 h-3 inline mr-0.5" />
            {{ phaseMeta(task.phase).label }}
          </span>
          <span class="px-1.5 py-0.5 rounded" style="background: var(--p-surface-200)">{{ task.status }}</span>
        </div>

        <!-- integrate status -->
        <div v-if="lastIntegrate" class="mt-2 text-[10px] flex items-center gap-1">
          <Icon icon="tabler:rocket" class="w-3 h-3" :style="{ color: phaseMeta('integrate').color }" />
          <span :class="{
            'text-success-500': lastIntegrate.status === 'passed',
            'text-danger-500':  lastIntegrate.status === 'failed',
            'text-warn-500':    lastIntegrate.status !== 'passed' && lastIntegrate.status !== 'failed',
          }">
            last integrate: {{ lastIntegrate.status || 'running' }}
          </span>
        </div>

        <!-- bounce badges -->
        <div v-if="Object.keys(bounces).length" class="mt-2 flex flex-wrap gap-1">
          <span v-for="(count, edge) in bounces" :key="edge"
            class="text-[9px] px-1.5 py-0.5 rounded flex items-center gap-0.5 bg-warn-500/15 text-warn-500">
            <Icon icon="tabler:refresh" class="w-2.5 h-2.5" />
            {{ edge }} ×{{ count }}
          </span>
        </div>

        <!-- dataflow link -->
        <button v-if="dataflowId" @click="router.push(`/dataflow/${dataflowId}`)"
          class="mt-2 text-[10px] flex items-center gap-1 underline hover:opacity-80"
          :style="{ color: 'var(--p-primary-color)' }">
          <Icon icon="tabler:circuit-diode" class="w-3 h-3" />
          open latest dataflow
        </button>
        <div v-if="changesetId" class="mt-1 text-[9px] font-mono opacity-60" :title="changesetId">
          cs: {{ changesetId.slice(0, 8) }}…
        </div>
      </div>

      <!-- Tab nav -->
      <nav class="flex-1 overflow-y-auto py-2">
        <button v-for="t in ['timeline', 'plan', 'spec', 'findings', 'integrations', 'data'] as const"
          :key="t" @click="tab = t"
          class="w-full text-left px-4 py-1.5 text-[11px] flex items-center gap-2"
          :class="tab === t ? 'font-semibold' : 'opacity-70 hover:opacity-100'"
          :style="tab === t ? { background: 'var(--p-surface-100)', color: 'var(--p-primary-color)' } : {}">
          <Icon :icon="{
            timeline: 'tabler:timeline',
            plan: 'tabler:list-tree',
            spec: 'tabler:file-text',
            findings: 'tabler:bookmark',
            integrations: 'tabler:rocket',
            data: 'tabler:database',
          }[t]" class="w-3.5 h-3.5" />
          {{ { timeline: 'Timeline', plan: 'Plan', spec: 'Spec', findings: 'Findings', integrations: 'Integrate runs', data: 'Data (debug)' }[t] }}
          <span v-if="t === 'plan' && planSteps.length"
            class="ml-auto text-[9px] opacity-60">{{ planDone }}/{{ planSteps.length }}</span>
          <span v-else-if="t === 'spec' && specs.length"
            class="ml-auto text-[9px] opacity-60">{{ specs.length }}</span>
          <span v-else-if="t === 'findings' && findings.length"
            class="ml-auto text-[9px] opacity-60">{{ findings.length }}</span>
          <span v-else-if="t === 'integrations' && integrateRuns.length"
            class="ml-auto text-[9px] opacity-60">{{ integrateRuns.length }}</span>
        </button>

        <div class="mt-4 px-4 text-[10px] opacity-60 flex items-center gap-2">
          <label class="flex items-center gap-1 cursor-pointer">
            <input type="checkbox" v-model="showDebug" @change="load" class="scale-75" />
            Show debug rows
          </label>
        </div>
      </nav>

      <!-- Actions -->
      <div v-if="task" class="px-4 py-3 border-t flex flex-col gap-2" style="border-color: var(--p-content-border-color)">
        <button v-if="task.status === 'open'" @click="handleStartCycle()" :disabled="startingCycle"
          class="w-full text-[11px] py-1.5 rounded font-medium"
          style="background: var(--p-primary-color); color: var(--p-primary-contrast-color)">
          {{ startingCycle ? 'Starting…' : 'Start cycle' }}
        </button>
        <Button v-if="task.status !== 'completed' && task.status !== 'abandoned' && task.status !== 'open'"
          severity="danger"
          @click="handleCancel" :disabled="cancelling"
          class="!w-full !text-[11px] !py-1.5 !font-medium !justify-center !gap-1">
          <Icon icon="tabler:ban" class="w-3.5 h-3.5" />
          {{ cancelling ? 'Cancelling…' : 'Cancel task' }}
        </Button>
      </div>
    </aside>

    <!-- RESIZE HANDLE -->
    <div @mousedown="startResize" class="w-1 cursor-col-resize hover:bg-primary-500/40"
      :class="{ 'bg-primary-500/40': isResizing }" />

    <!-- MAIN -->
    <main class="flex-1 overflow-y-auto">
      <div v-if="loading && !task" class="p-8 text-center opacity-60">Loading…</div>
      <div v-else-if="error" class="p-6 text-sm text-danger-500 bg-danger-500/5">{{ error }}</div>
      <div v-else class="p-6">

        <!-- ask_user banner -->
        <div v-if="isWaitingForUser && lastQuestion"
          class="mb-4 rounded p-3 bg-warn-500/10 border border-warn-500/25">
          <div class="flex items-center gap-2 text-[11px] font-semibold mb-2 text-warn-500">
            <Icon icon="tabler:message-question" class="w-4 h-4" />
            The orchestrator is waiting for your reply
          </div>
          <MarkdownContent :content="lastQuestion" />
          <div class="mt-3 flex gap-2">
            <textarea v-model="userResponse" rows="2"
              placeholder="Your response…"
              class="flex-1 text-[12px] px-2 py-1 rounded bg-transparent"
              style="border: 1px solid var(--p-content-border-color)"></textarea>
            <button @click="handleRespond" :disabled="responding || !userResponse.trim()"
              class="px-3 text-[11px] rounded font-medium"
              style="background: var(--p-primary-color); color: var(--p-primary-contrast-color)">
              {{ responding ? '…' : 'Send' }}
            </button>
          </div>
        </div>

        <!-- TIMELINE -->
        <section v-if="tab === 'timeline'">
          <div v-if="!timelineBlocks.length" class="text-sm opacity-60 py-10 text-center">
            No activity yet.
          </div>
          <div v-for="(block, bi) in timelineBlocks" :key="bi"
            class="phase-block"
            :style="{ '--phase-color': phaseMeta(block.phase).color }">
            <!-- phase header -->
            <header class="phase-header"
              :style="{ color: phaseMeta(block.phase).color }">
              <Icon :icon="phaseMeta(block.phase).icon" class="w-4 h-4" />
              <span class="text-[12px] font-semibold">{{ phaseMeta(block.phase).label }}</span>
              <span class="text-[10px] opacity-70">
                {{ fmtTime(block.startedAt) }}
                <template v-if="block.endedAt"> → {{ fmtTime(block.endedAt) }}</template>
                <template v-if="block.endedAt"> ({{ fmtDuration(block.startedAt, block.endedAt) }})</template>
                <template v-else> · still running…</template>
              </span>
              <span v-if="block.exitSignal"
                class="ml-auto text-[10px] px-1.5 py-0.5 rounded"
                :style="{ background: phaseMeta(block.phase).color + '20' }">
                {{ block.exitSignal }}
              </span>
              <button v-if="block.startNode?.dataflow_id"
                @click="router.push(`/dataflow/${block.startNode.dataflow_id}`)"
                class="text-[10px] underline hover:opacity-80 ml-2">
                dataflow
              </button>
            </header>

            <!-- phase body: events -->
            <ul class="py-1">
              <!-- empty-and-running placeholder so a just-spawned phase shows
                   activity instead of a blank block. The window before the
                   first trail event is usually context gathering (prepare_context
                   + context-chain agents) — surface that rather than going
                   silent. -->
              <li v-if="block.entries.length === 0 && !block.endedAt"
                class="flex items-center gap-2 text-[11px] px-3 py-1 opacity-70">
                <Icon icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin shrink-0"
                  :style="{ color: phaseMeta(block.phase).color }" />
                <span>Gathering context…</span>
                <span class="text-[10px] opacity-60">
                  prepare_context + specialist priors
                </span>
              </li>
              <!-- grouped render: consecutive same-agent tool_calls roll up -->
              <template v-for="(g, gi) in groupedEntries(block.entries)" :key="'g'+gi">
                <!-- burst: many tool_calls from one research/context agent -->
                <li v-if="g.kind === 'burst'"
                  class="group flex items-start gap-2 text-[11px] px-3 py-1 hover:bg-[var(--kp-hover-bg)] cursor-pointer border-l-2"
                  :style="{ borderColor: `color-mix(in srgb, ${agentMeta(g.agentId)?.color || 'var(--p-text-muted-color)'} 25%, transparent)` }"
                  @click="toggle('burst:'+gi+':'+g.nodes[0].node_id)">
                  <Icon :icon="agentMeta(g.agentId)?.icon || 'tabler:stack-2'"
                    class="w-3.5 h-3.5 mt-0.5 shrink-0"
                    :style="{ color: agentMeta(g.agentId)?.color || 'var(--p-text-muted-color)' }" />
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-1.5">
                      <span v-if="agentMeta(g.agentId)"
                        class="flex items-center gap-0.5 px-1 py-0 rounded text-[9px] font-mono shrink-0"
                        :style="{ background: agentMeta(g.agentId)!.color + '25', color: agentMeta(g.agentId)!.color }">
                        <Icon :icon="agentMeta(g.agentId)!.icon" class="w-2.5 h-2.5" />
                        {{ agentMeta(g.agentId)!.label }}
                      </span>
                      <span class="font-medium">{{ g.nodes.length }} calls</span>
                      <span v-if="g.errors" class="text-[10px] px-1 rounded bg-danger-950/25 text-danger-300">{{ g.errors }} errs</span>
                      <span class="ml-auto shrink-0 text-[9px] opacity-50 tabular-nums">
                        {{ fmtTime(g.startedAt) }} → {{ fmtTime(g.endedAt) }}
                      </span>
                      <Icon
                        :icon="expanded['burst:'+gi+':'+g.nodes[0].node_id] ? 'tabler:chevron-up' : 'tabler:chevron-down'"
                        class="w-3 h-3 opacity-60 shrink-0"
                        :title="expanded['burst:'+gi+':'+g.nodes[0].node_id] ? 'Collapse calls' : 'Expand calls'" />
                    </div>
                    <!-- individual tool calls (collapsed by default; click header to expand) -->
                    <ul v-if="expanded['burst:'+gi+':'+g.nodes[0].node_id]"
                      class="mt-1 space-y-1 pl-3 border-l border-[var(--kp-border)]">
                      <li v-for="n in g.nodes" :key="n.node_id"
                        class="flex flex-col gap-0.5 text-[10px] burst-row"
                        :class="{ 'burst-row--open': expanded[n.node_id] }">
                        <div class="flex items-center gap-1.5 cursor-pointer hover:bg-[var(--kp-hover-bg)] rounded px-1"
                          @click.stop="toggle(n.node_id)">
                          <Icon :icon="n.status === 'failed' ? 'tabler:alert-circle' : (n.status === 'running' ? 'tabler:loader-2' : nodeMeta(n.type).icon)"
                            class="w-3 h-3 shrink-0"
                            :class="{ 'text-danger-500': n.status === 'failed', 'animate-spin': n.status === 'running' }"
                            :style="n.status === 'failed' || n.status === 'running' ? {} : { color: nodeMeta(n.type).color }" />
                          <span class="font-mono truncate flex-1" :title="n.title">
                            {{ nodeLabel(n) }}
                          </span>
                          <Icon v-if="(n.result_summary && n.result_summary.length > 80) || n.error_message"
                            :icon="expanded[n.node_id] ? 'tabler:chevron-up' : 'tabler:chevron-down'"
                            class="w-3 h-3 opacity-50 shrink-0" />
                          <span class="opacity-50 tabular-nums shrink-0">
                            <template v-if="n.execution_ms != null">{{ fmtMs(n.execution_ms) }} · </template>
                            {{ fmtTime(n.created_at) }}
                          </span>
                        </div>
                        <template v-if="!expanded[n.node_id]">
                          <div v-if="n.result_summary"
                            class="pl-4 opacity-70 truncate"
                            :title="n.result_summary">→ {{ n.result_summary }}</div>
                          <div v-if="n.error_message"
                            class="pl-4 truncate text-danger-500"
                            :title="n.error_message">✗ {{ n.error_message }}</div>
                        </template>
                        <template v-else>
                          <div v-if="n.content" class="audit-block">
                            <div class="audit-block-head">
                              <span>input</span>
                              <button class="audit-copy" @click.stop="copyText(n.content)">copy</button>
                            </div>
                            <pre class="audit-pre">{{ n.content }}</pre>
                          </div>
                          <div v-if="n.result_summary" class="audit-block">
                            <div class="audit-block-head">
                              <span>output</span>
                              <button class="audit-copy" @click.stop="copyText(n.result_summary)">copy</button>
                            </div>
                            <pre class="audit-pre">{{ n.result_summary }}</pre>
                          </div>
                          <div v-if="n.error_message" class="audit-block audit-block--err">
                            <div class="audit-block-head">
                              <span>error</span>
                            </div>
                            <pre class="audit-pre audit-pre--err">{{ n.error_message }}</pre>
                          </div>
                        </template>
                      </li>
                    </ul>
                  </div>
                </li>
                <!-- single: regular one-row render -->
                <li v-else :key="g.node.node_id"
                  class="group flex items-start gap-2 text-[11px] px-3 py-1 hover:bg-[var(--kp-hover-bg)] cursor-pointer border-l-2"
                  :style="{ borderColor: (nodeMeta(g.node.type).color) + (g.node.status === 'failed' ? 'ff' : '40') }"
                  @click="toggle(g.node.node_id)">
                  <Icon
                    :icon="g.node.status === 'failed' ? 'tabler:alert-circle'
                         : g.node.status === 'running' ? 'tabler:loader-2'
                         : nodeMeta(g.node.type).icon"
                    class="w-3.5 h-3.5 mt-0.5 shrink-0"
                    :class="{
                      'animate-spin': g.node.status === 'running',
                      'text-danger-500': g.node.status === 'failed',
                      'text-warn-500':   g.node.status === 'running',
                    }"
                    :style="g.node.status === 'failed' || g.node.status === 'running' ? {} : { color: nodeMeta(g.node.type).color }" />
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-1.5">
                      <span v-if="agentMeta(g.node.agent_id)"
                        class="flex items-center gap-0.5 px-1 py-0 rounded text-[9px] font-mono shrink-0"
                        :style="{ background: agentMeta(g.node.agent_id)!.color + '25', color: agentMeta(g.node.agent_id)!.color }">
                        <Icon :icon="agentMeta(g.node.agent_id)!.icon" class="w-2.5 h-2.5" />
                        {{ agentMeta(g.node.agent_id)!.label }}
                      </span>
                      <span v-if="g.node.type !== 'tool_call'"
                        class="uppercase tracking-wide text-[9px] font-semibold opacity-70 shrink-0"
                        :style="{ color: nodeMeta(g.node.type).color }">
                        {{ nodeMeta(g.node.type).label }}
                      </span>
                      <span v-if="g.node.type === 'tool_call'"
                        class="font-mono text-[10.5px] opacity-90 truncate"
                        :title="g.node.title">{{ nodeLabel(g.node) }}</span>
                      <span v-else
                        class="font-medium truncate"
                        :title="g.node.title">{{ nodeLabel(g.node) }}</span>
                      <span class="ml-auto shrink-0 text-[9px] opacity-50 tabular-nums">
                        <template v-if="g.node.execution_ms != null">{{ fmtMs(g.node.execution_ms) }} · </template>
                        {{ fmtTime(g.node.created_at) }}
                      </span>
                    </div>
                    <div v-if="g.node.result_summary" class="text-[10px] opacity-60 truncate pl-0.5">
                      → {{ g.node.result_summary }}
                    </div>
                    <div v-if="g.node.error_message" class="text-[10px] mt-0.5 pl-0.5 text-danger-500">✗ {{ g.node.error_message }}</div>
                    <div v-if="expanded[g.node.node_id]" class="mt-2 space-y-1.5">
                      <div v-if="g.node.content"
                        class="rounded px-2 py-1.5 text-[10px]"
                        style="background: var(--p-surface-100); max-height: 280px; overflow-y: auto">
                        <div v-if="g.node.type === 'tool_call'"
                          class="text-[9px] uppercase tracking-wide opacity-60 mb-1">input</div>
                        <MarkdownContent v-if="g.node.content_type === 'text/markdown'" :content="g.node.content" />
                        <pre v-else class="font-mono whitespace-pre-wrap">{{ g.node.content }}</pre>
                      </div>
                      <div v-if="g.node.result_summary"
                        class="rounded px-2 py-1.5 text-[10px]"
                        style="background: var(--p-surface-100); max-height: 280px; overflow-y: auto">
                        <div class="text-[9px] uppercase tracking-wide opacity-60 mb-1">output</div>
                        <pre class="font-mono whitespace-pre-wrap">{{ g.node.result_summary }}</pre>
                      </div>
                      <div v-if="g.node.error_message"
                        class="rounded px-2 py-1.5 text-[10px] bg-danger-950/15 text-danger-300"
                        style="max-height: 280px; overflow-y: auto">
                        <div class="text-[9px] uppercase tracking-wide opacity-80 mb-1">error</div>
                        <pre class="font-mono whitespace-pre-wrap">{{ g.node.error_message }}</pre>
                      </div>
                    </div>
                  </div>
                </li>
              </template>
            </ul>
          </div>
        </section>

        <!-- PLAN -->
        <section v-else-if="tab === 'plan'">
          <div v-if="!activePlan" class="text-sm opacity-60 py-10 text-center">
            No plan persisted yet. The planner runs after design approval.
          </div>
          <div v-else>
            <header class="flex items-center gap-2 mb-3 text-[12px]">
              <Icon icon="tabler:list-tree" class="w-4 h-4" />
              <span class="font-semibold">{{ activePlan.title }}</span>
              <span class="text-[10px] opacity-60">
                rev {{ activePlan.discriminator }} · {{ fmtTime(activePlan.created_at) }}
              </span>
              <span class="ml-auto text-[10px] px-1.5 py-0.5 rounded tabular-nums"
                :style="{ background: 'var(--p-surface-100)' }">
                {{ planDone }} / {{ planSteps.length }} done
                <template v-if="planBlocked > 0"> · {{ planBlocked }} blocked</template>
              </span>
            </header>

            <div v-if="activePlan.content"
              class="mb-3 rounded px-3 py-2 text-[11px] opacity-80"
              style="background: var(--p-surface-100)">
              {{ activePlan.content }}
            </div>

            <ul class="space-y-2">
              <li v-for="s in planSteps" :key="s.node_id"
                class="rounded px-3 py-2"
                :style="{ border: '1px solid ' + stepStatusMeta(s.status).color + '40' }">
                <div class="flex items-center gap-2 text-[11px]">
                  <Icon :icon="stepKindMeta((s.metadata as any)?.kind).icon"
                    class="w-4 h-4 shrink-0"
                    :style="{ color: stepKindMeta((s.metadata as any)?.kind).color }" />
                  <span class="font-mono opacity-60 shrink-0">{{ s.discriminator }}</span>
                  <span class="uppercase tracking-wide text-[9px] opacity-70 shrink-0">
                    {{ (s.metadata as any)?.kind }}
                  </span>
                  <span class="font-medium truncate">{{ s.title }}</span>
                  <span class="ml-auto text-[9px] px-1.5 py-0.5 rounded tabular-nums shrink-0"
                    :style="{ background: stepStatusMeta(s.status).color + '25',
                              color:      stepStatusMeta(s.status).color }">
                    {{ stepStatusMeta(s.status).label }}
                  </span>
                </div>
                <div v-if="(s.metadata as any)?.target"
                  class="mt-1 text-[10px] opacity-70 font-mono">
                  target: {{ (s.metadata as any)?.target }}
                </div>
                <div v-if="(s.metadata as any)?.needs?.length"
                  class="mt-1 text-[10px] opacity-60">
                  needs: {{ ((s.metadata as any)?.needs || []).join(', ') }}
                </div>
                <div v-if="(s.metadata as any)?.acceptance"
                  class="mt-1 text-[10px] opacity-70">
                  <span class="opacity-60">acceptance:</span> {{ (s.metadata as any)?.acceptance }}
                </div>
                <div v-if="s.result_summary" class="mt-1 text-[10px] opacity-80">
                  <span class="opacity-60">result:</span> {{ s.result_summary }}
                </div>
                <div v-if="s.error_message" class="mt-1 text-[10px] text-danger-500">
                  {{ s.error_message }}
                </div>
                <div v-if="s.agent_id" class="mt-1 text-[9px] opacity-50 font-mono">
                  by {{ s.agent_id.replace(/^keeper\.agents(?:\.[a-z_.]+)?:/, '') }}
                </div>
              </li>
            </ul>
          </div>
        </section>

        <!-- SPEC -->
        <section v-else-if="tab === 'spec'">
          <div v-if="!currentSpec" class="text-sm opacity-60 py-10 text-center">
            No spec written yet.
          </div>
          <div v-else>
            <header class="flex items-center gap-2 mb-3 text-[12px]">
              <Icon icon="tabler:file-text" class="w-4 h-4" />
              <span class="font-semibold">{{ currentSpec.title }}</span>
              <span class="text-[10px] opacity-60">rev {{ currentSpec.discriminator }} · {{ fmtTime(currentSpec.created_at) }}</span>
              <span class="ml-auto text-[10px] px-1.5 py-0.5 rounded"
                :class="currentSpec.status === 'active'
                  ? 'bg-success-500/15 text-success-500'
                  : 'bg-surface-400/15 text-surface-400'">
                {{ currentSpec.status }}
              </span>
            </header>
            <div class="rounded px-4 py-3" style="border: 1px solid var(--p-content-border-color)">
              <MarkdownContent :content="currentSpec.content || '(empty)'" />
            </div>
            <!-- revision history -->
            <div v-if="specs.length > 1" class="mt-4">
              <h3 class="text-[11px] font-semibold opacity-70 mb-2">Revisions</h3>
              <ul class="text-[11px] space-y-1">
                <li v-for="s in specs" :key="s.node_id"
                  class="flex items-center gap-2">
                  <span class="font-mono opacity-60">rev {{ s.discriminator }}</span>
                  <span class="opacity-60">{{ fmtTime(s.created_at) }}</span>
                  <span class="ml-auto opacity-60">{{ s.status }}</span>
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- FINDINGS -->
        <section v-else-if="tab === 'findings'">
          <div v-if="!findings.length" class="text-sm opacity-60 py-10 text-center">
            No findings saved yet.
          </div>
          <ul v-else class="space-y-3">
            <li v-for="f in findings" :key="f.node_id"
              class="rounded px-4 py-3 overflow-hidden"
              style="border: 1px solid var(--p-content-border-color); min-width: 0">
              <header class="flex items-center gap-2 text-[12px] mb-1 min-w-0">
                <Icon icon="tabler:bookmark" class="w-4 h-4 shrink-0" />
                <span class="font-semibold truncate" :title="f.title">{{ f.title }}</span>
                <span v-if="f.agent_id"
                  class="text-[9px] opacity-50 font-mono shrink-0">
                  {{ f.agent_id.replace(/^keeper\.agents(?:\.[a-z_.]+)?:/, '') }}
                </span>
                <span class="ml-auto text-[10px] opacity-60 shrink-0">{{ fmtTime(f.created_at) }}</span>
              </header>
              <div v-if="f.content" class="text-[12px]" style="min-width: 0">
                <MarkdownContent :content="f.content" maxHeight="320px" />
              </div>
              <div v-if="f.metadata?.comment" class="mt-1 text-[10px] opacity-70 truncate"
                :title="f.metadata.comment">
                {{ f.metadata.comment }}
              </div>
            </li>
          </ul>
        </section>

        <!-- INTEGRATIONS -->
        <section v-else-if="tab === 'integrations'">
          <div v-if="!integrateRuns.length" class="text-sm opacity-60 py-10 text-center">
            No integrate runs yet.
          </div>
          <div v-for="r in integrateRuns" :key="r.node_id"
            class="mb-4 rounded overflow-hidden" style="border: 1px solid var(--p-content-border-color)">
            <header class="flex items-center gap-2 px-3 py-2"
              :class="{
                'bg-success-500/10': r.status === 'passed',
                'bg-danger-500/10':  r.status === 'failed',
                'bg-warn-500/10':    r.status !== 'passed' && r.status !== 'failed',
              }">
              <Icon :icon="r.type === 'rollback_stage' ? 'tabler:arrow-back-up' : 'tabler:rocket'"
                class="w-4 h-4"
                :class="{
                  'text-success-500': r.status === 'passed',
                  'text-danger-500':  r.status === 'failed',
                  'text-warn-500':    r.status !== 'passed' && r.status !== 'failed',
                }" />
              <span class="text-[12px] font-semibold">{{ r.title }}</span>
              <span class="ml-auto text-[10px] opacity-60">
                <template v-if="r.execution_ms != null">{{ fmtMs(r.execution_ms) }} · </template>
                {{ fmtTime(r.created_at) }}
              </span>
            </header>
            <ul class="px-3 py-2 space-y-1">
              <li v-for="c in childrenOf(r.node_id)" :key="c.node_id"
                class="text-[11px] flex items-center gap-2 py-0.5">
                <Icon :icon="c.status === 'passed' ? 'tabler:check'
                           : c.status === 'failed' ? 'tabler:x'
                           : 'tabler:loader-2'"
                  class="w-3 h-3"
                  :class="{
                    'text-success-500': c.status === 'passed',
                    'text-danger-500':  c.status === 'failed',
                    'text-warn-500':    c.status !== 'passed' && c.status !== 'failed',
                  }" />
                <span class="font-medium">{{ c.title }}</span>
                <span v-if="c.result_summary" class="opacity-70 ml-2 truncate">{{ c.result_summary }}</span>
                <span v-if="c.execution_ms != null" class="ml-auto opacity-60">{{ fmtMs(c.execution_ms) }}</span>
              </li>
            </ul>
          </div>
        </section>

        <!-- DATA (debug view: raw nodes) -->
        <section v-else-if="tab === 'data'">
          <div class="text-[11px] opacity-70 mb-2">
            Raw <code>keeper_task_nodes</code> stream ({{ nodes.length }} rows)
          </div>
          <table class="w-full text-[10px] font-mono">
            <thead class="opacity-60">
              <tr>
                <th class="text-left py-1 pr-2">seq</th>
                <th class="text-left py-1 pr-2">type</th>
                <th class="text-left py-1 pr-2">disc</th>
                <th class="text-left py-1 pr-2">status</th>
                <th class="text-left py-1 pr-2">title</th>
                <th class="text-right py-1">ms</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="n in nodes" :key="n.node_id"
                class="hover:bg-[var(--kp-hover-bg)] cursor-pointer" @click="toggle(n.node_id)">
                <td class="py-0.5 pr-2">{{ n.seq }}</td>
                <td class="py-0.5 pr-2">{{ n.type }}</td>
                <td class="py-0.5 pr-2 opacity-70">{{ n.discriminator || '—' }}</td>
                <td class="py-0.5 pr-2" :class="{
                  'text-danger-500':  n.status === 'failed',
                  'text-success-500': n.status === 'passed' || n.status === 'active',
                  'text-warn-500':    n.status === 'running',
                }">{{ n.status || '—' }}</td>
                <td class="py-0.5 pr-2 truncate max-w-xs">{{ n.title }}</td>
                <td class="py-0.5 text-right opacity-60">{{ n.execution_ms != null ? fmtMs(n.execution_ms) : '' }}</td>
              </tr>
            </tbody>
          </table>
        </section>
      </div>
    </main>
  </div>
</template>

<style scoped>
pre { white-space: pre-wrap; word-break: break-word; }

/* Phase block: top-level section per phase (Setup, Design, Plan, ...) */
.phase-block {
  margin-bottom: 14px;
  border: 1px solid color-mix(in srgb, var(--phase-color) 35%, var(--p-content-border-color));
  border-left: 3px solid var(--phase-color);
  border-radius: 6px;
  background: color-mix(in srgb, var(--phase-color) 4%, transparent);
  overflow: hidden;
}
.phase-header {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 12px;
  background: color-mix(in srgb, var(--phase-color) 14%, transparent);
  border-bottom: 1px solid color-mix(in srgb, var(--phase-color) 25%, var(--p-content-border-color));
  font-weight: 600;
}

.burst-row { padding: 1px 0; }
.burst-row--open {
  background: color-mix(in srgb, var(--p-surface-100) 60%, transparent);
  border-radius: 4px;
}

.audit-block {
  margin: 4px 0 6px 16px;
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  background: var(--p-surface-50);
  overflow: hidden;
}
.audit-block--err {
  border-color: color-mix(in srgb, var(--p-danger-500) 35%, var(--p-content-border-color));
}
.audit-block-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 3px 8px;
  font-size: 9px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-weight: 700;
  color: var(--p-text-muted-color);
  background: var(--p-surface-100);
  border-bottom: 1px solid var(--p-content-border-color);
}
.audit-copy {
  padding: 1px 6px;
  font-size: 9px;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 3px;
  cursor: pointer;
  text-transform: none;
  letter-spacing: 0;
}
.audit-copy:hover {
  background: var(--p-surface-200);
  color: var(--p-text-color);
}
.audit-pre {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  line-height: 1.5;
  color: var(--p-text-color);
  padding: 6px 8px;
  margin: 0;
  max-height: 280px;
  overflow: auto;
}
.audit-pre--err { color: var(--p-danger-500); }
</style>
