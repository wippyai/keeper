<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import { useApi, useWippy } from '../composables/useWippy'
import { getDataflow, cancelDataflow, terminateDataflow, statusColor, statusIcon, nodeTypeShort, type Dataflow, type DataflowNode, type DataflowData } from '../api/dataflows'
import { formatDate, timeAgo } from '../api/sessions'
import DataTimeline from '../components/dataflow/DataTimeline.vue'
import NodesList from '../components/dataflow/NodesList.vue'

const route = useRoute()
const router = useRouter()
const api = useApi()
const instance = useWippy()

const dataflow = ref<Dataflow | null>(null)
const nodes = ref<DataflowNode[]>([])
const data = ref<DataflowData[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

const lastEventAt = ref<number | null>(null)
const tickNow = ref(Date.now())
let tickTimer: number | null = null

const newIds = ref<Set<string>>(new Set())
const newItemTimers = new Map<string, number>()
const NEW_ITEM_TTL_MS = 3000

const exportToast = ref<string | null>(null)

const activeTab = ref<'timeline' | 'nodes'>('timeline')
const showInternal = ref(false)
const groupTurns = ref(true)
const timelineNodeFilter = ref<string>('all')
const nodeTypeFilter = ref<string>('')
const selectedNodeId = ref<string | null>(null)

const STORAGE_KEY = 'keeper-dataflow-panels'
const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')
const leftW = ref(saved.left || 240)
function saveW() { localStorage.setItem(STORAGE_KEY, JSON.stringify({ left: leftW.value })) }

function goBack() {
  if (window.history.length > 1) router.back()
  else router.push('/dataflows')
}

let resizing = false; let sx = 0; let sw = 0
function startResize(e: MouseEvent) { resizing = true; sx = e.clientX; sw = leftW.value; document.addEventListener('mousemove', onResize); document.addEventListener('mouseup', stopResize); document.body.style.cursor = 'col-resize'; document.body.style.userSelect = 'none' }
function onResize(e: MouseEvent) { if (!resizing) return; const dx = e.clientX - sx; leftW.value = Math.max(180, Math.min(400, sw + dx)) }
function stopResize() { resizing = false; document.removeEventListener('mousemove', onResize); document.removeEventListener('mouseup', stopResize); document.body.style.cursor = ''; document.body.style.userSelect = ''; saveW() }

const dataflowId = computed(() => route.params.id as string)
const isImported = computed(() => dataflowId.value === 'imported')

const lastEventLabel = computed(() => {
  if (!lastEventAt.value) return null
  const sec = Math.max(0, Math.round((tickNow.value - lastEventAt.value) / 1000))
  if (sec < 5) return 'just now'
  if (sec < 60) return `${sec}s ago`
  if (sec < 3600) return `${Math.floor(sec / 60)}m ago`
  return `${Math.floor(sec / 3600)}h ago`
})

const nodeStats = computed(() => {
  const s: Record<string, number> = {}
  for (const n of nodes.value) if (n.status !== 'template') s[n.status] = (s[n.status] || 0) + 1
  return s
})

const nodeTypes = computed(() => {
  const c: Record<string, number> = {}
  for (const n of nodes.value) if (n.status !== 'template') {
    const t = nodeTypeShort(n.type)
    c[t] = (c[t] || 0) + 1
  }
  return Object.entries(c).sort((a, b) => a[0].localeCompare(b[0]))
})

const timelineNodeOptions = computed(() => {
  const used = new Set<string>()
  for (const d of data.value) if (d.node_id) used.add(d.node_id)
  const candidates = nodes.value
    .filter(n => used.has(n.node_id) && n.status !== 'template')
    .sort((a, b) => {
      const at = typeof a.created_at === 'number' ? a.created_at : new Date(a.created_at).getTime()
      const bt = typeof b.created_at === 'number' ? b.created_at : new Date(b.created_at).getTime()
      return at - bt
    })
  const baseName = (n: DataflowNode) =>
    (n.metadata as any)?.title || n.type.split(':').pop() || n.type
  const iterOf = (n: DataflowNode) => (n.metadata as any)?.iteration || (n.metadata as any)?.created_in_iteration
  const shortId = (id: string) => id.split('-').pop() || id.slice(-6)
  return candidates.map(n => {
    const name = baseName(n)
    const iter = iterOf(n)
    const suffix = iter ? ` · iter ${iter}` : ''
    return { id: n.node_id, label: `${name}${suffix} (${shortId(n.node_id)})` }
  })
})

const dataStats = computed(() => {
  const total = data.value.length
  const internal = data.value.filter(d => d.type.startsWith('node.yield') || d.type === 'node.result' || d.type === 'node.input').length
  return { total, visible: total - internal, internal }
})

function loadFromImport() {
  const raw = localStorage.getItem('@keeper/imported-dataflow')
  if (!raw) {
    error.value = 'No imported dataflow found in storage. Open the dataflows list and import again.'
    loading.value = false
    return
  }
  try {
    const dump = JSON.parse(raw)
    dataflow.value = dump.dataflow || null
    nodes.value = dump.nodes || []
    data.value = dump.data || []
    if (!dataflow.value) {
      error.value = 'Imported payload missing `dataflow` field.'
    }
  } catch (e: any) {
    error.value = 'Could not parse imported dataflow: ' + (e.message || 'invalid JSON')
  } finally {
    loading.value = false
  }
}

async function load() {
  if (isImported.value) return loadFromImport()
  loading.value = true; error.value = null
  try {
    const r = await getDataflow(api, dataflowId.value)
    dataflow.value = r.dataflow
    nodes.value = r.nodes || []
    data.value = r.data || []
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function markNew(id: string) {
  newIds.value.add(id)
  newIds.value = new Set(newIds.value)
  const prev = newItemTimers.get(id)
  if (prev) window.clearTimeout(prev)
  const tid = window.setTimeout(() => {
    newIds.value.delete(id)
    newIds.value = new Set(newIds.value)
    newItemTimers.delete(id)
  }, NEW_ITEM_TTL_MS)
  newItemTimers.set(id, tid)
}

function mergeUpdate(r: any) {
  let changed = false
  if (r.dataflow) { dataflow.value = r.dataflow; changed = true }
  if (r.nodes) {
    const existing = new Map(nodes.value.map(n => [n.node_id, n]))
    for (const n of r.nodes) {
      if (!existing.has(n.node_id)) markNew(n.node_id)
      existing.set(n.node_id, n)
    }
    nodes.value = Array.from(existing.values())
    changed = true
  }
  if (r.data) {
    const existing = new Map(data.value.map(d => [d.data_id, d]))
    for (const d of r.data) {
      if (!existing.has(d.data_id)) markNew(d.data_id)
      existing.set(d.data_id, d)
    }
    data.value = Array.from(existing.values())
    changed = true
  }
  if (changed) lastEventAt.value = Date.now()
}

function exportDataflow() {
  if (!dataflow.value) return
  const dump = {
    exported_at: new Date().toISOString(),
    dataflow: dataflow.value,
    nodes: nodes.value,
    data: data.value,
  }
  const dataStr = JSON.stringify(dump, null, 2)
  navigator.clipboard?.writeText(dataStr).catch(() => {})
  const blob = new Blob([dataStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `dataflow-${dataflowId.value || 'export'}.json`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
  exportToast.value = 'Exported + copied to clipboard'
  setTimeout(() => { exportToast.value = null }, 2500)
}

function jumpToTimeline(nodeId: string) {
  activeTab.value = 'timeline'
  timelineNodeFilter.value = nodeId
}

function selectNode(nodeId: string) {
  selectedNodeId.value = nodeId
  activeTab.value = 'nodes'
  nextTick(() => {
    const el = document.querySelector(`[data-node-id="${nodeId}"]`)
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' })
  })
}

function selectData(_dataId: string) {
  // Placeholder — data rows already expand in place in the timeline.
}

let unsub: (() => void) | null = null

onMounted(() => {
  load()
  if (!isImported.value) {
    unsub = instance.on(`dataflow:${dataflowId.value}`, () => {
      getDataflow(api, dataflowId.value).then(mergeUpdate).catch(() => {})
    })
  }
  tickTimer = window.setInterval(() => { tickNow.value = Date.now() }, 1000)
})
onUnmounted(() => {
  if (unsub) unsub()
  if (tickTimer) window.clearInterval(tickTimer)
  for (const tid of newItemTimers.values()) window.clearTimeout(tid)
  newItemTimers.clear()
})

async function handleCancel() { if (!dataflowId.value) return; await cancelDataflow(api, dataflowId.value); await load() }
async function handleTerminate() { if (!dataflowId.value) return; await terminateDataflow(api, dataflowId.value); await load() }
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="shrink-0 px-4 py-2 flex items-center gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
      <Button class="k-btn-icon !rounded" @click="goBack" title="Back">
        <Icon icon="tabler:arrow-left" class="w-4 h-4" />
      </Button>
      <Icon :icon="statusIcon(dataflow?.status || 'pending')" class="w-4 h-4"
        :class="{ 'animate-pulse': dataflow?.status === 'running' }"
        :style="{ color: statusColor(dataflow?.status || 'pending') }" />
      <div class="flex-1 min-w-0">
        <div class="text-sm font-medium" style="color: var(--p-text-color)">
          {{ (dataflow?.metadata as any)?.title || dataflow?.type || '...' }}
        </div>
        <div class="flex items-center gap-3 text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">
          <span class="font-mono">{{ dataflowId.slice(0, 20) }}</span>
          <span :style="{ color: statusColor(dataflow?.status || '') }">{{ dataflow?.status }}</span>
          <span>{{ nodes.length }} nodes · {{ dataStats.total }} data items</span>
          <span v-if="lastEventLabel" class="flex items-center gap-1" :title="lastEventAt ? new Date(lastEventAt).toLocaleString() : ''">
            <span class="w-1.5 h-1.5 rounded-full bg-success-500 animate-pulse"></span>
            last event {{ lastEventLabel }}
          </span>
        </div>
      </div>
      <Tag v-if="isImported" severity="info" title="Read-only — loaded from a JSON dump">
        <Icon icon="tabler:download" class="w-3 h-3" />Imported
      </Tag>
      <template v-if="!isImported && dataflow?.status === 'running'">
        <Button class="!py-1 k-btn-tinted k-btn-tinted-warn" @click="handleCancel">Cancel</Button>
        <Button class="!py-1 k-btn-tinted k-btn-tinted-danger" @click="handleTerminate">Kill</Button>
      </template>
      <Button v-if="dataflow" class="k-btn-icon !rounded" @click="exportDataflow" title="Export JSON (download + clipboard)">
        <Icon icon="tabler:download" class="w-4 h-4" />
      </Button>
      <Button v-if="!isImported" class="k-btn-icon !rounded" @click="load">
        <Icon icon="tabler:refresh" class="w-4 h-4" :class="{ 'animate-spin': loading }" />
      </Button>
    </div>
    <div v-if="exportToast" class="export-toast">{{ exportToast }}</div>

    <div v-if="loading" class="flex-1 flex items-center justify-center">
      <Icon icon="tabler:loader-2" class="w-6 h-6 animate-spin keeper-accent" />
    </div>
    <div v-else-if="error" class="flex-1 flex items-center justify-center text-xs text-danger-500">
      <p>{{ error }}</p>
    </div>

    <div v-else class="flex-1 flex overflow-hidden">
      <!-- Left sidebar -->
      <aside class="shrink-0 overflow-y-auto px-3 py-3 space-y-4" :style="{ width: leftW + 'px' }">
        <div>
          <div class="lbl">Info</div>
          <div class="space-y-1 text-[11px]">
            <div class="srow"><span>Status</span><span :style="{ color: statusColor(dataflow!.status) }">{{ dataflow!.status }}</span></div>
            <div class="srow"><span>Type</span><span>{{ dataflow!.type }}</span></div>
            <div class="srow"><span>Actor</span><span class="font-mono text-[10px]">{{ dataflow!.actor_id }}</span></div>
            <div class="srow"><span>Created</span><span>{{ formatDate(dataflow!.created_at) }}</span></div>
            <div class="srow"><span>Updated</span><span>{{ timeAgo(dataflow!.updated_at) }}</span></div>
            <div v-if="dataflow!.parent_dataflow_id" class="srow">
              <span>Parent</span>
              <button class="font-mono text-[10px]" style="color: var(--p-primary-color)" @click="router.push('/dataflow/' + dataflow!.parent_dataflow_id)">
                {{ dataflow!.parent_dataflow_id.slice(0, 12) }}…
              </button>
            </div>
          </div>
        </div>

        <div>
          <div class="lbl">Node Stats</div>
          <div class="space-y-0.5 text-[11px]">
            <div v-for="(count, status) in nodeStats" :key="status" class="flex justify-between">
              <span class="flex items-center gap-1" :style="{ color: statusColor(String(status)) }">
                <Icon :icon="statusIcon(String(status))" class="w-3 h-3" /> {{ status }}
              </span>
              <span style="color: var(--p-text-muted-color)">{{ count }}</span>
            </div>
          </div>
        </div>

        <div>
          <div class="lbl">Data Stats</div>
          <div class="space-y-0.5 text-[11px]">
            <div class="flex justify-between"><span>Total</span><span style="color: var(--p-text-muted-color)">{{ dataStats.total }}</span></div>
            <div class="flex justify-between"><span>Visible</span><span style="color: var(--p-text-muted-color)">{{ dataStats.visible }}</span></div>
            <div class="flex justify-between"><span>Internal</span><span style="color: var(--p-text-muted-color)">{{ dataStats.internal }}</span></div>
          </div>
        </div>

        <div v-if="activeTab === 'timeline'">
          <div class="lbl">Timeline Filters</div>
          <label class="ctl">
            <input type="checkbox" v-model="groupTurns" />
            <span>Group agent turns</span>
          </label>
          <label class="ctl mt-1">
            <input type="checkbox" v-model="showInternal" />
            <span>Show internal events</span>
          </label>
          <div class="mt-2">
            <div class="sub-lbl">Node</div>
            <select v-model="timelineNodeFilter" class="sel">
              <option value="all">All nodes</option>
              <option v-for="opt in timelineNodeOptions" :key="opt.id" :value="opt.id">{{ opt.label }}</option>
            </select>
          </div>
        </div>

        <div v-else>
          <div class="lbl">Node Type Filter</div>
          <button class="fbtn" :class="{ act: !nodeTypeFilter }" @click="nodeTypeFilter = ''"><span>All</span></button>
          <button v-for="[t, c] in nodeTypes" :key="t" class="fbtn" :class="{ act: nodeTypeFilter === t }" @click="nodeTypeFilter = nodeTypeFilter === t ? '' : t">
            <span>{{ t }}</span><span class="cnt">{{ c }}</span>
          </button>
        </div>

        <div v-if="dataflow?.metadata && Object.keys(dataflow.metadata).length">
          <div class="lbl">Details</div>
          <div class="space-y-1 text-[11px]">
            <div v-if="(dataflow.metadata as any)?.title" class="srow"><span>Title</span><span>{{ (dataflow.metadata as any).title }}</span></div>
            <div v-if="(dataflow.metadata as any)?.target_agent" class="srow"><span>Agent</span><span class="font-mono text-[10px]">{{ (dataflow.metadata as any).target_agent }}</span></div>
            <div v-if="(dataflow.metadata as any)?.topic_count" class="srow"><span>Topics</span><span>{{ (dataflow.metadata as any).topic_count }}</span></div>
            <div v-if="(dataflow.metadata as any)?.source" class="srow"><span>Source</span><span>{{ (dataflow.metadata as any).source }}</span></div>
          </div>
        </div>
      </aside>

      <div class="rh" @mousedown="startResize"></div>

      <!-- Main area -->
      <div class="flex-1 overflow-hidden flex flex-col min-w-0">
        <div class="tabs">
          <button class="tab" :class="{ active: activeTab === 'timeline' }" @click="activeTab = 'timeline'">
            <Icon icon="tabler:list-details" class="w-3.5 h-3.5" />
            Timeline
            <span class="tab-count">{{ dataStats.visible }}</span>
          </button>
          <button class="tab" :class="{ active: activeTab === 'nodes' }" @click="activeTab = 'nodes'">
            <Icon icon="tabler:sitemap" class="w-3.5 h-3.5" />
            Nodes
            <span class="tab-count">{{ nodes.filter(n => n.status !== 'template').length }}</span>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto">
          <DataTimeline v-if="activeTab === 'timeline'"
            :nodes="nodes" :data="data"
            :show-internal="showInternal" :node-filter="timelineNodeFilter"
            :group-turns="groupTurns"
            :new-ids="newIds"
            @select-node="selectNode" />
          <NodesList v-else
            :nodes="nodes" :data="data"
            :type-filter="nodeTypeFilter" :selected-node-id="selectedNodeId"
            :new-ids="newIds"
            @select-node="selectNode"
            @select-data="selectData"
            @jump-to-timeline="jumpToTimeline" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.lbl { font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600; color: var(--p-text-muted-color); margin-bottom: 6px; }
.sub-lbl { font-size: 9px; text-transform: uppercase; font-weight: 600; color: var(--p-text-muted-color); margin-bottom: 3px; }
.srow { display: flex; justify-content: space-between; gap: 4px; color: var(--p-text-muted-color); }
.srow > span:last-child { color: var(--p-text-color); }
.fbtn { width: 100%; display: flex; justify-content: space-between; padding: 3px 8px; border-radius: 4px; font-size: 11px; color: var(--p-text-color); background: transparent; border: 0; cursor: pointer; text-align: left; }
.fbtn:hover { background: var(--p-surface-100); }
.fbtn.act { background: var(--p-surface-100); }
.fbtn .cnt { color: var(--p-text-muted-color); }
.rh { width: 4px; cursor: col-resize; flex-shrink: 0; border-left: 1px solid var(--p-content-border-color); }
.rh:hover { background: var(--p-primary-color); opacity: 0.25; }

.ctl { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--p-text-color); cursor: pointer; }
.ctl input { margin: 0; }

.sel {
  width: 100%; padding: 4px 6px; border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-color);
}

.tabs {
  display: flex; gap: 2px;
  padding: 0 12px;
  background: var(--p-content-background);
  border-bottom: 1px solid var(--p-content-border-color);
  flex-shrink: 0;
}
.tab {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 12px;
  background: transparent;
  border: 0;
  border-bottom: 2px solid transparent;
  color: var(--p-text-muted-color);
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
}
.tab:hover { color: var(--p-text-color); }
.tab.active {
  color: var(--p-primary-color);
  border-bottom-color: var(--p-primary-color);
}
.tab-count {
  font-size: 9px; font-weight: 700;
  padding: 1px 5px;
  border-radius: 3px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.tab.active .tab-count {
  background: color-mix(in srgb, var(--p-primary-color) 15%, transparent);
  color: var(--p-primary-color);
}
.export-toast {
  position: fixed; top: 60px; right: 16px; z-index: 100;
  background: var(--p-content-background); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  padding: 8px 14px; border-radius: 6px; font-size: 11px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  display: flex; align-items: center; gap: 8px;
}
</style>
