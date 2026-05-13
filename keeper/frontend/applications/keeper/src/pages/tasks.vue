<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import {
  listTasks, createTask, startCycle, archiveTask,
  type Task,
} from '../api/tasks'

const router = useRouter()
const api = useApi()
const host = useHost()
const instance = useWippy()

const designs = ref<Task[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const showCreate = ref(false)
const newSpec = ref('')
const creating = ref(false)
const starting = ref<string | null>(null)
const archiving = ref<string | null>(null)
const abandoning = ref<string | null>(null)
const showArchived = ref(false)
const search = ref('')
const stats = ref<{
  total?: number
  open?: number
  in_progress?: number
  completed?: number
  cancelled?: number
  archived?: number
  by_phase?: Record<string, number>
} | null>(null)

const phaseFilter = ref<Set<string>>(new Set())
const sortBy = ref<'recent' | 'oldest' | 'iteration' | 'updated'>('recent')

const PHASE_ORDER = ['spec', 'research', 'design', 'review', 'implement', 'test', 'integrate', 'finish']

function togglePhaseFilter(phase: string) {
  const next = new Set(phaseFilter.value)
  if (next.has(phase)) next.delete(phase); else next.add(phase)
  phaseFilter.value = next
}
function clearPhaseFilter() { phaseFilter.value = new Set() }

const phaseDist = computed(() => {
  const by = stats.value?.by_phase || {}
  const entries = PHASE_ORDER.map(p => ({ phase: p, count: by[p] || 0 }))
    .filter(e => e.count > 0)
  // Catch any phases the server returns that aren't in our canonical order
  for (const [p, n] of Object.entries(by)) {
    if (!PHASE_ORDER.includes(p) && (n as number) > 0) entries.push({ phase: p, count: n as number })
  }
  const total = entries.reduce((s, e) => s + e.count, 0) || 1
  return entries.map(e => ({ ...e, pct: Math.max(2, Math.round((e.count / total) * 100)) }))
})

function phaseLifecycleIndex(p: string) { return PHASE_ORDER.indexOf(p) }

async function load() {
  loading.value = true; error.value = null
  try {
    const res = await listTasks(api, showArchived.value ? { archived: 'all' } : undefined)
    designs.value = res.tasks || []
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { loading.value = false }
}

async function handleArchive(d: Task, archived: boolean) {
  archiving.value = d.task_id; error.value = null
  try {
    await archiveTask(api, d.task_id, archived)
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { archiving.value = null }
}

async function handleCreate() {
  if (!newSpec.value.trim()) return
  creating.value = true; error.value = null
  try {
    const spec = newSpec.value.trim()
    const title = spec.length > 60 ? spec.slice(0, 57) + '...' : spec
    await createTask(api, { title, spec })
    newSpec.value = ''; showCreate.value = false
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { creating.value = false }
}

async function handleStart(d: Task) {
  starting.value = d.task_id; error.value = null
  try {
    await startCycle(api, d.task_id)
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { starting.value = null }
}

async function handleAbandon(d: Task) {
  if (!await host.confirm({
    header: 'Cancel task',
    message: `Cancel "${d.title}"? This abandons the task, drops its changeset, and stops all running phases.`,
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
  })) return
  abandoning.value = d.task_id; error.value = null
  try {
    await api.put(`/api/v1/keeper/tasks/${d.task_id}`, { status: 'abandoned' })
    await load()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  finally { abandoning.value = null }
}

function openTask(d: Task) {
  router.push(`/tasks/${d.task_id}`)
}

function timeAgo(ts: string) {
  if (!ts) return ''
  try {
    const d = new Date(ts); const s = Math.floor((Date.now() - d.getTime()) / 1000)
    if (s < 60) return 'now'; if (s < 3600) return Math.floor(s / 60) + 'm'
    if (s < 86400) return Math.floor(s / 3600) + 'h'; return Math.floor(s / 86400) + 'd'
  } catch { return '' }
}

const phaseColor: Record<string, string> = {
  spec: 'var(--p-text-muted-color)',
  research: 'var(--p-info-500)',
  design: 'var(--p-accent-500)',
  review: 'var(--p-warn-500)',
  implement: 'var(--p-warn-500)',
  test: 'var(--p-success-500)',
  integrate: 'var(--p-info-500)',
  done: 'var(--p-success-500)',
  finish: 'var(--p-success-500)',
  debug: 'var(--p-danger-500)',
  blocked: 'var(--p-danger-500)',
}

const phaseIcon: Record<string, string> = {
  spec: 'tabler:file-text', research: 'tabler:search', design: 'tabler:pencil',
  review: 'tabler:eye-check', implement: 'tabler:code', test: 'tabler:test-pipe',
  integrate: 'tabler:plug', done: 'tabler:check', finish: 'tabler:check',
  debug: 'tabler:bug', blocked: 'tabler:alert-circle', waiting_for_user: 'tabler:message-question',
  error: 'tabler:alert-triangle',
}

const statusIcon: Record<string, string> = {
  active: 'tabler:player-play', completed: 'tabler:check', abandoned: 'tabler:x',
  closed: 'tabler:lock', error: 'tabler:alert-triangle', waiting_for_user: 'tabler:message-question',
}

const statusTint: Record<string, { bg: string; border: string; fg: string }> = {
  completed:        { bg: 'color-mix(in srgb, var(--p-success-500) 12%, transparent)', border: 'color-mix(in srgb, var(--p-success-500) 33%, transparent)', fg: 'var(--p-success-500)' },
  abandoned:        { bg: 'color-mix(in srgb, var(--p-text-muted-color) 12%, transparent)', border: 'color-mix(in srgb, var(--p-text-muted-color) 27%, transparent)', fg: 'var(--p-text-muted-color)' },
  closed:           { bg: 'color-mix(in srgb, var(--p-info-500) 12%, transparent)', border: 'color-mix(in srgb, var(--p-info-500) 33%, transparent)', fg: 'var(--p-info-500)' },
  error:            { bg: 'color-mix(in srgb, var(--p-danger-500) 12%, transparent)', border: 'color-mix(in srgb, var(--p-danger-500) 40%, transparent)', fg: 'var(--p-danger-500)' },
  waiting_for_user: { bg: 'color-mix(in srgb, var(--p-warn-500) 10%, transparent)', border: 'color-mix(in srgb, var(--p-warn-500) 53%, transparent)', fg: 'var(--p-warn-500)' },
}
function tintFor(s: string) {
  return statusTint[s] || { bg: 'var(--p-surface-100)', border: 'var(--p-surface-200)', fg: 'var(--p-text-muted-color)' }
}

function matchesSearch(d: Task): boolean {
  const q = search.value.trim().toLowerCase()
  if (!q) return true
  const fields = [d.title, d.spec, d.description, d.task_id, d.phase, d.status, d.actor_id]
  return fields.some(f => f && String(f).toLowerCase().includes(q))
}

function matchesPhase(d: Task): boolean {
  if (phaseFilter.value.size === 0) return true
  return phaseFilter.value.has(d.phase || '')
}

function applySort(list: Task[]): Task[] {
  const arr = [...list]
  const k = sortBy.value
  arr.sort((a, b) => {
    if (k === 'oldest') return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    if (k === 'iteration') return (b.iteration || 0) - (a.iteration || 0) || new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
    if (k === 'updated') return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
  return arr
}

const filtered = computed(() => designs.value.filter(d => matchesSearch(d) && matchesPhase(d)))
const waitingDesigns = computed(() =>
  applySort(filtered.value.filter(d => d.status === 'waiting_for_user' && !d.archived))
)
const activeDesigns = computed(() =>
  applySort(filtered.value.filter(d => d.status === 'active' && !d.archived))
)
const completedDesigns = computed(() =>
  applySort(filtered.value.filter(d => d.status !== 'active' && d.status !== 'waiting_for_user' && !d.archived))
)
const archivedDesigns = computed(() => filtered.value.filter(d => d.archived))
const totalMatches = computed(() => filtered.value.length)

let unsub: (() => void) | null = null

onMounted(async () => {
  load()
  unsub = instance.on('keeper.task', () => load())
  try {
    const { data } = await api.get('/api/v1/keeper/tasks/stats')
    if (data && data.success !== false) stats.value = data
  } catch {}
})

onUnmounted(() => {
  unsub?.()
})
</script>

<template>
  <div class="flex flex-col h-full w-full overflow-hidden" style="color: var(--p-text-color)">
    <!-- Header -->
    <div class="flex items-center justify-between px-5 py-2.5 flex-shrink-0" style="border-bottom: 1px solid var(--p-content-border-color)">
      <div class="flex items-center gap-2.5">
        <Icon icon="tabler:git-merge" class="w-4.5 h-4.5" style="color: var(--p-primary-color)" />
        <span class="text-sm font-semibold">Pipeline</span>
        <span v-if="waitingDesigns.length" class="awaiting-pulse">{{ waitingDesigns.length }} awaiting</span>
        <span v-if="activeDesigns.length" class="hdr-count">{{ activeDesigns.length }} active</span>
      </div>
      <div class="flex items-center gap-1.5">
        <div class="search-wrap">
          <Icon icon="tabler:search" class="search-icon" />
          <input v-model="search" type="text" placeholder="Search tasks…" class="search-input pr-7" />
          <button v-if="search" @click="search = ''" class="absolute right-1.5 top-1/2 -translate-y-1/2 p-0.5 rounded"
            style="color: var(--p-text-muted-color); background: transparent" title="Clear">
            <Icon icon="tabler:x" class="w-3 h-3" />
          </button>
        </div>
        <select v-model="sortBy" class="hdr-select" title="Sort">
          <option value="recent">Newest</option>
          <option value="oldest">Oldest</option>
          <option value="updated">Recently updated</option>
          <option value="iteration">Most iterations</option>
        </select>
        <button @click="showArchived = !showArchived; load()" class="hdr-btn" :class="{ active: showArchived }">
          <Icon :icon="showArchived ? 'tabler:archive-off' : 'tabler:archive'" class="w-3 h-3" />
          {{ showArchived ? 'Archived' : 'Archive' }}
        </button>
        <button @click="showCreate = !showCreate" class="hdr-btn primary">
          <Icon icon="tabler:plus" class="w-3 h-3" /> New task
        </button>
        <button @click="load" class="hdr-btn icon-only" title="Refresh">
          <Icon icon="tabler:refresh" class="w-3.5 h-3.5" />
        </button>
      </div>
    </div>

    <!-- Stats strip + phase chart -->
    <div v-if="stats" class="stats-strip">
      <div class="stat-tiles">
        <div class="stat-tile">
          <span class="stat-tile-label">Total</span>
          <span class="stat-tile-value">{{ stats.total ?? 0 }}</span>
        </div>
        <div class="stat-tile">
          <span class="stat-tile-label">Open</span>
          <span class="stat-tile-value">{{ stats.open ?? 0 }}</span>
        </div>
        <div class="stat-tile">
          <span class="stat-tile-label">In progress</span>
          <span class="stat-tile-value">{{ stats.in_progress ?? ((stats.by_phase?.implement || 0) + (stats.by_phase?.review || 0)) }}</span>
        </div>
        <div v-if="waitingDesigns.length" class="stat-tile stat-tile--warn">
          <span class="stat-tile-label">Awaiting</span>
          <span class="stat-tile-value">{{ waitingDesigns.length }}</span>
        </div>
        <div class="stat-tile stat-tile--success">
          <span class="stat-tile-label">Completed</span>
          <span class="stat-tile-value">{{ stats.completed ?? 0 }}</span>
        </div>
        <div v-if="stats.cancelled" class="stat-tile">
          <span class="stat-tile-label">Cancelled</span>
          <span class="stat-tile-value" style="color: var(--p-text-muted-color)">{{ stats.cancelled }}</span>
        </div>
      </div>

      <!-- Phase distribution stacked bar -->
      <div v-if="phaseDist.length" class="phase-dist">
        <div class="phase-dist-head">
          <span class="phase-dist-title">By phase</span>
          <span v-if="phaseFilter.size" class="phase-dist-clear" @click="clearPhaseFilter">
            clear filter ({{ phaseFilter.size }})
          </span>
        </div>
        <div class="phase-dist-bar">
          <button
            v-for="seg in phaseDist" :key="seg.phase"
            class="phase-dist-seg"
            :class="{ active: phaseFilter.has(seg.phase), faded: phaseFilter.size && !phaseFilter.has(seg.phase) }"
            :style="{ width: seg.pct + '%', '--seg-color': phaseColor[seg.phase] || 'var(--p-text-muted-color)' }"
            :title="`${seg.phase}: ${seg.count}`"
            @click="togglePhaseFilter(seg.phase)"
          >
            <span class="phase-dist-seg-label">{{ seg.phase }}</span>
            <span class="phase-dist-seg-count">{{ seg.count }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Create -->
    <div v-if="showCreate" class="flex items-center gap-2 px-5 py-2 flex-shrink-0" style="background: var(--p-surface-50); border-bottom: 1px solid var(--p-content-border-color)">
      <textarea v-model="newSpec" @keydown.meta.enter="handleCreate" placeholder="Describe what you want to build..."
        rows="2" class="flex-1 px-2.5 py-1.5 rounded text-xs resize-none"
        style="background: var(--p-surface-100); border: 1px solid var(--p-surface-300); color: var(--p-text-color)" autofocus />
      <button @click="handleCreate" :disabled="creating || !newSpec.trim()"
        class="px-3 py-1.5 rounded text-xs font-medium self-end"
        :style="{ background: 'var(--p-primary-color)', color: 'white', opacity: !newSpec.trim() ? 0.4 : 1 }">Create</button>
      <button @click="showCreate = false" class="px-2 py-1.5 rounded text-xs self-end" style="color: var(--p-text-muted-color)">Cancel</button>
    </div>

    <!-- Error -->
    <div v-if="error" class="mx-5 mt-2 px-3 py-1.5 rounded text-[11px] flex items-center justify-between flex-shrink-0 bg-danger-500/10 text-danger-500 border border-danger-500/10">
      <span>{{ error }}</span>
      <button @click="error = null" class="ml-2 opacity-60 hover:opacity-100">&times;</button>
    </div>

    <!-- Awaiting user reply (sticky banner, OUTSIDE the scroll area so it's always visible) -->
    <div v-if="waitingDesigns.length" class="flex-shrink-0 px-5 pt-3 pb-1 bg-warn-500/5 border-b border-warn-500/20">
      <div class="flex items-center gap-2 mb-2">
        <Icon icon="tabler:bell-ringing" class="w-3.5 h-3.5 animate-pulse text-warn-500" />
        <span class="text-[10px] font-bold uppercase tracking-wider text-warn-500">{{ waitingDesigns.length }} task{{ waitingDesigns.length === 1 ? '' : 's' }} awaiting your reply</span>
      </div>
      <div v-for="d in waitingDesigns" :key="d.task_id"
        class="mb-2 rounded-lg overflow-hidden cursor-pointer transition-all hover:brightness-110 bg-warn-500/10 border-2 border-warn-500/50"
        @click="openTask(d)">
        <div class="px-4 py-3 flex items-center gap-3">
          <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-warn-500/20">
            <Icon icon="tabler:message-question" class="w-5 h-5 text-warn-500" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-[13px] font-semibold leading-snug" style="color: var(--p-text-color)">
              {{ d.title }}
            </div>
            <div class="text-[11px] mt-0.5 flex items-center gap-2 text-warn-500">
              <span>Paused at <strong>{{ d.phase }}</strong></span>
              <span style="color: var(--p-text-muted-color)">·</span>
              <span style="color: var(--p-text-muted-color)">{{ timeAgo(d.updated_at) }}</span>
            </div>
          </div>
          <span class="px-3 py-1.5 rounded text-[11px] font-bold flex-shrink-0 bg-warn-500 text-warn-950">Reply →</span>
        </div>
      </div>
    </div>

    <!-- Task List -->
    <div class="flex-1 overflow-y-auto">
      <!-- Active -->
      <div v-if="activeDesigns.length" class="px-5 pt-3">
        <div v-for="d in activeDesigns" :key="d.task_id"
          class="mb-2.5 rounded-lg overflow-hidden cursor-pointer transition-colors hover:brightness-110"
          style="background: var(--p-surface-50); border: 1px solid var(--p-surface-100)"
          @click="openTask(d)">
          <div class="px-4 py-3">
            <!-- Row 1: phase icon, title, actions -->
            <div class="flex items-start gap-3">
              <div class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5"
                :style="{ background: `color-mix(in srgb, ${phaseColor[d.phase] || 'var(--p-text-muted-color)'} 10%, transparent)` }">
                <Icon :icon="phaseIcon[d.phase] || 'tabler:point'" class="w-4.5 h-4.5"
                  :style="{ color: phaseColor[d.phase] || 'var(--p-text-muted-color)' }" />
              </div>
              <div class="flex-1 min-w-0">
                <div class="text-[13px] font-medium leading-snug" style="color: var(--p-text-color)">
                  {{ d.title }}
                </div>
                <div v-if="d.spec || d.description" class="text-[11px] mt-1 leading-relaxed line-clamp-2" style="color: var(--p-text-muted-color)">
                  {{ d.spec || d.description }}
                </div>
                <div v-else class="text-[11px] mt-1 italic opacity-60" style="color: var(--p-text-muted-color)">
                  {{ d.phase === 'design' ? 'Designing spec...' : d.phase === 'spec' ? 'Awaiting start' : '' }}
                </div>
              </div>
              <div class="flex items-center gap-1.5 flex-shrink-0">
                <button v-if="d.phase === 'spec'"
                  @click.stop="handleStart(d)"
                  :disabled="starting === d.task_id"
                  class="flex items-center gap-1 px-2.5 py-1.5 rounded text-[11px] font-medium"
                  style="background: var(--p-primary-color); color: white">
                  <Icon :icon="starting === d.task_id ? 'tabler:loader-2' : 'tabler:player-play'" class="w-3.5 h-3.5"
                    :class="{ 'animate-spin': starting === d.task_id }" />
                  Start
                </button>
                <button v-if="d.phase !== 'spec'"
                  @click.stop="handleAbandon(d)" :disabled="abandoning === d.task_id"
                  class="flex items-center gap-1 px-2 py-1.5 rounded text-[11px] font-medium bg-danger-500/15 text-danger-500 border border-danger-500/25"
                  title="Cancel — abandon this task and stop all running phases">
                  <Icon :icon="abandoning === d.task_id ? 'tabler:loader-2' : 'tabler:player-stop'" class="w-3 h-3"
                    :class="{ 'animate-spin': abandoning === d.task_id }" />
                  Cancel
                </button>
                <button @click.stop="handleArchive(d, true)" :disabled="archiving === d.task_id"
                  class="p-1.5 rounded hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)" title="Archive">
                  <Icon :icon="archiving === d.task_id ? 'tabler:loader-2' : 'tabler:archive'" class="w-3.5 h-3.5"
                    :class="{ 'animate-spin': archiving === d.task_id }" />
                </button>
              </div>
            </div>

            <!-- Row 2: badges/metadata -->
            <div class="flex items-center gap-2 mt-2.5 pl-12 text-[10px]">
              <span class="phase-pill"
                :style="{ background: `color-mix(in srgb, ${phaseColor[d.phase] || 'var(--p-text-muted-color)'} 12%, transparent)`, color: phaseColor[d.phase] || 'var(--p-text-muted-color)' }">
                {{ d.phase }}
              </span>
              <span v-if="d.iteration" class="meta-pill">
                <Icon icon="tabler:repeat" class="w-3 h-3" /> #{{ d.iteration }}
              </span>
              <span v-if="d.actor_id" class="meta-pill" :title="d.actor_id">
                <Icon icon="tabler:user" class="w-3 h-3" />
                <span class="truncate" style="max-width: 140px">{{ d.actor_id }}</span>
              </span>
              <span class="meta-pill">
                <Icon icon="tabler:clock" class="w-3 h-3" /> {{ timeAgo(d.updated_at) }}
              </span>
              <!-- Lifecycle progress dots -->
              <div class="lifecycle">
                <span v-for="(p, i) in PHASE_ORDER" :key="p"
                  class="lc-dot"
                  :class="{
                    done: phaseLifecycleIndex(d.phase) > i,
                    current: d.phase === p,
                    todo: phaseLifecycleIndex(d.phase) < i,
                  }"
                  :style="d.phase === p ? { background: phaseColor[p] || 'var(--p-primary-color)' } : null"
                  :title="p"
                ></span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-if="!loading && designs.length === 0" class="flex items-center justify-center py-16">
        <div class="text-center">
          <Icon icon="tabler:git-merge" class="w-10 h-10 mx-auto mb-2 opacity-10" style="color: var(--p-text-muted-color)" />
          <div class="text-xs" style="color: var(--p-text-muted-color)">No tasks yet</div>
          <div class="text-[10px] mt-1" style="color: var(--p-text-muted-color)">Click New to create one</div>
        </div>
      </div>
      <div v-else-if="!loading && search && totalMatches === 0" class="flex items-center justify-center py-16">
        <div class="text-center">
          <Icon icon="tabler:search-off" class="w-10 h-10 mx-auto mb-2 opacity-10" style="color: var(--p-text-muted-color)" />
          <div class="text-xs" style="color: var(--p-text-muted-color)">No matches for "{{ search }}"</div>
          <button @click="search = ''" class="text-[10px] mt-1 underline" style="color: var(--p-primary-color)">Clear search</button>
        </div>
      </div>

      <!-- Completed -->
      <div v-if="completedDesigns.length" class="px-5 pt-3 pb-4">
        <div class="text-[9px] font-medium uppercase tracking-wider mb-2" style="color: var(--p-text-muted-color)">History</div>
        <div v-for="d in completedDesigns" :key="d.task_id"
          class="mb-1 flex items-center gap-3 px-4 py-2 rounded cursor-pointer hover:brightness-110"
          :style="{ background: tintFor(d.status).bg, border: '1px solid ' + tintFor(d.status).border }"
          @click="openTask(d)">
          <Icon :icon="statusIcon[d.status] || 'tabler:point'" class="w-3 h-3" :style="{ color: tintFor(d.status).fg }" />
          <span class="text-[11px] truncate flex-1" style="color: var(--p-text-color); opacity: 0.85">{{ d.title }}</span>
          <span class="text-[9px] font-medium px-1.5 py-0.5 rounded"
            :style="{ background: tintFor(d.status).border, color: tintFor(d.status).fg }">{{ d.status }}</span>
          <button @click.stop="handleArchive(d, true)" :disabled="archiving === d.task_id"
            class="p-1 rounded hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)" title="Archive">
            <Icon :icon="archiving === d.task_id ? 'tabler:loader-2' : 'tabler:archive'" class="w-3 h-3"
              :class="{ 'animate-spin': archiving === d.task_id }" />
          </button>
        </div>
      </div>

      <!-- Archived -->
      <div v-if="showArchived && archivedDesigns.length" class="px-5 pt-3 pb-4">
        <div class="text-[9px] font-medium uppercase tracking-wider mb-2" style="color: var(--p-text-muted-color)">Archived</div>
        <div v-for="d in archivedDesigns" :key="d.task_id"
          class="mb-1 flex items-center gap-3 px-4 py-2 rounded cursor-pointer hover:brightness-110"
          style="background: var(--p-surface-50); border: 1px dashed var(--p-content-border-color); opacity: 0.5"
          @click="openTask(d)">
          <Icon icon="tabler:archive" class="w-3 h-3" style="color: var(--p-text-muted-color)" />
          <span class="text-[11px] truncate flex-1" style="color: var(--p-text-muted-color)">{{ d.title }}</span>
          <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ d.phase }}</span>
          <button @click.stop="handleArchive(d, false)" :disabled="archiving === d.task_id"
            class="p-1 rounded hover:bg-[var(--kp-hover-bg)]" style="color: var(--p-text-muted-color)" title="Restore">
            <Icon :icon="archiving === d.task_id ? 'tabler:loader-2' : 'tabler:archive-off'" class="w-3 h-3"
              :class="{ 'animate-spin': archiving === d.task_id }" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Header bits */
.awaiting-pulse {
  display: inline-flex; align-items: center;
  font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 2px 8px; border-radius: 12px;
  background: var(--p-warn-500); color: white;
  animation: awaiting-pulse 1.6s ease-in-out infinite;
}
@keyframes awaiting-pulse {
  0%, 100% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--p-warn-500) 45%, transparent); }
  50%      { box-shadow: 0 0 0 5px color-mix(in srgb, var(--p-warn-500) 0%, transparent); }
}
.hdr-count {
  font-size: 10px; font-weight: 500;
  padding: 2px 8px; border-radius: 12px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}

.hdr-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 6px;
  font-size: 11px; font-weight: 500;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background 0.1s, color 0.1s, border-color 0.1s;
}
.hdr-btn:hover { background: var(--p-surface-100); color: var(--p-text-color); }
.hdr-btn.active { background: var(--p-surface-200); color: var(--p-text-color); }
.hdr-btn.primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
  font-weight: 600;
}
.hdr-btn.primary:hover { opacity: 0.92; background: var(--p-primary-color); }
.hdr-btn.icon-only { padding: 4px 6px; }

.hdr-select {
  padding: 4px 8px; border-radius: 6px;
  font-size: 11px;
  background: transparent;
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  cursor: pointer;
}
.hdr-select:focus { border-color: var(--p-primary-color); }

/* Stats strip */
.stats-strip {
  display: flex; align-items: center; gap: 18px;
  padding: 10px 20px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: color-mix(in srgb, var(--p-surface-50) 60%, transparent);
  flex-shrink: 0;
}
.stat-tiles {
  display: flex; gap: 8px;
  flex-shrink: 0;
}
.stat-tile {
  display: flex; flex-direction: column; gap: 2px;
  padding: 6px 12px;
  border-radius: 6px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  min-width: 78px;
}
.stat-tile--success { border-color: color-mix(in srgb, var(--p-success-500) 30%, var(--p-content-border-color)); }
.stat-tile--success .stat-tile-value { color: var(--p-success-500); }
.stat-tile--warn { border-color: color-mix(in srgb, var(--p-warn-500) 38%, var(--p-content-border-color)); }
.stat-tile--warn .stat-tile-value { color: var(--p-warn-500); }
.stat-tile-label {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600;
  color: var(--p-text-muted-color);
}
.stat-tile-value {
  font-size: 14px; font-weight: 700;
  color: var(--p-text-color);
  font-variant-numeric: tabular-nums;
  line-height: 1.1;
}

/* Phase distribution bar */
.phase-dist {
  flex: 1;
  display: flex; flex-direction: column; gap: 4px;
  min-width: 0;
}
.phase-dist-head {
  display: flex; align-items: center; gap: 8px;
  font-size: 9px;
  color: var(--p-text-muted-color);
  text-transform: uppercase; letter-spacing: 0.05em; font-weight: 700;
}
.phase-dist-clear {
  cursor: pointer;
  color: var(--p-primary-color);
  text-transform: none; letter-spacing: 0;
  font-weight: 500;
  font-size: 10px;
}
.phase-dist-clear:hover { text-decoration: underline; }
.phase-dist-bar {
  display: flex; gap: 2px;
  height: 20px;
}
.phase-dist-seg {
  display: inline-flex; align-items: center; justify-content: center;
  gap: 4px;
  height: 100%;
  border-radius: 4px;
  background: color-mix(in srgb, var(--seg-color, var(--p-text-muted-color)) 22%, transparent);
  color: var(--seg-color, var(--p-text-color));
  border: 1px solid color-mix(in srgb, var(--seg-color) 40%, transparent);
  font-size: 9px; font-weight: 600;
  cursor: pointer;
  overflow: hidden;
  transition: filter 0.12s, opacity 0.12s, transform 0.08s;
  text-transform: uppercase; letter-spacing: 0.04em;
  padding: 0 4px;
  min-width: 0;
}
.phase-dist-seg:hover { filter: brightness(1.18); }
.phase-dist-seg.active {
  background: color-mix(in srgb, var(--seg-color) 38%, transparent);
  filter: brightness(1.1);
  outline: 1px solid var(--seg-color);
  outline-offset: -1px;
}
.phase-dist-seg.faded { opacity: 0.4; }
.phase-dist-seg-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}
.phase-dist-seg-count { opacity: 0.85; font-weight: 700; }

/* Active card row 2 — pills */
.phase-pill {
  font-size: 10px; font-weight: 600; text-transform: lowercase;
  padding: 1px 8px; border-radius: 4px;
}
.meta-pill {
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 10px;
  padding: 1px 7px; border-radius: 4px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
}

/* Lifecycle dot strip */
.lifecycle {
  display: inline-flex; align-items: center; gap: 3px;
  margin-left: auto;
  padding: 2px 4px;
  border-radius: 8px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
}
.lc-dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: var(--p-surface-300);
  transition: background 0.12s, transform 0.12s;
}
.lc-dot.done    { background: var(--p-success-500); opacity: 0.65; }
.lc-dot.current { width: 14px; height: 6px; border-radius: 4px; }
.lc-dot.todo    { background: var(--p-surface-200); }

/* Active card hover */
.flex-1.overflow-y-auto :deep(.cursor-pointer):hover {
  border-color: color-mix(in srgb, var(--p-primary-color) 35%, var(--p-content-border-color)) !important;
}
</style>
