<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi, useWippy } from '../composables/useWippy'
import { listDataflows, cancelDataflow, terminateDataflow, statusColor, statusIcon, type Dataflow } from '../api/dataflows'
import { timeAgo } from '../api/sessions'

const api = useApi()
const router = useRouter()
const instance = useWippy()

const dataflows = ref<Dataflow[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const statusFilter = ref<string>('')
const searchTerm = ref('')
const currentPage = ref(0)
const pageSize = 20
const totalCount = ref(0)

const totalPages = computed(() => Math.ceil(totalCount.value / pageSize))

const displayed = computed(() => {
  if (!searchTerm.value) return dataflows.value
  const term = searchTerm.value.toLowerCase()
  return dataflows.value.filter(d =>
    d.dataflow_id.toLowerCase().includes(term) ||
    (d.metadata?.title || '').toLowerCase().includes(term),
  )
})

function dfTitle(d: Dataflow): string {
  return d.metadata?.title || 'Untitled Workflow'
}

function viewDataflow(id: string) {
  router.push(`/dataflow/${id}`)
}

async function load() {
  loading.value = true; error.value = null
  try {
    const params: any = { limit: pageSize, offset: currentPage.value * pageSize }
    if (statusFilter.value) params.status = statusFilter.value
    const r = await listDataflows(api, params.limit, params.offset, statusFilter.value || undefined)
    dataflows.value = r.dataflows || []
    totalCount.value = r.count || 0
  } catch (e: any) { error.value = e.message }
  finally { loading.value = false }
}

async function doCancel(id: string) {
  try { await cancelDataflow(api, id); load() } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

async function doTerminate(id: string) {
  try { await terminateDataflow(api, id); load() } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

function applyFilter() {
  currentPage.value = 0
  load()
}

function prevPage() { if (currentPage.value > 0) { currentPage.value--; load() } }
function nextPage() { if (currentPage.value < totalPages.value - 1) { currentPage.value++; load() } }

const importOpen = ref(false)
const importJson = ref('')
const importError = ref<string | null>(null)

function openImport() {
  importJson.value = ''
  importError.value = null
  importOpen.value = true
}

async function pasteFromClipboard() {
  try { importJson.value = await navigator.clipboard.readText() } catch {}
}

function importFromFile(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => { importJson.value = String(reader.result || '') }
  reader.readAsText(file)
}

function submitImport() {
  importError.value = null
  const raw = importJson.value.trim()
  if (!raw) { importError.value = 'Paste a JSON dump first.'; return }
  try {
    const dump = JSON.parse(raw)
    if (!dump.dataflow && !dump.nodes && !dump.data) {
      importError.value = 'Expected an object with `dataflow`, `nodes`, and/or `data` fields.'
      return
    }
    localStorage.setItem('@keeper/imported-dataflow', raw)
    importOpen.value = false
    router.push('/dataflow/imported')
  } catch (e: any) {
    importError.value = 'Invalid JSON: ' + (e.message || 'parse error')
  }
}

// Subscribe to relay events for each running dataflow to get real-time status updates.
// When any dataflow status changes, refresh the list.
let unsubs: Array<() => void> = []

function subscribeToRunning() {
  unsubs.forEach(u => u())
  unsubs = []
  for (const df of dataflows.value) {
    if (df.status === 'running' || df.status === 'pending') {
      unsubs.push(instance.on(`dataflow:${df.dataflow_id}`, () => { load() }))
    }
  }
}

onMounted(() => { load().then(subscribeToRunning) })

onUnmounted(() => {
  unsubs.forEach(u => u())
  unsubs = []
})
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- Header -->
    <div class="shrink-0 px-4 py-2.5 flex items-center justify-between gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
      <div class="flex items-center gap-2">
        <span class="text-xs font-medium" style="color: var(--p-text-color)">Dataflows</span>
        <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ totalCount }} total</span>
        <Icon v-if="loading" icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin keeper-accent" />
      </div>
      <div class="flex items-center gap-2">
        <div class="search-wrap">
          <Icon icon="tabler:search" class="search-icon" />
          <input v-model="searchTerm" type="text" placeholder="Search dataflows..." class="search-input" />
        </div>
        <select v-model="statusFilter" @change="applyFilter" class="text-[11px] px-2 py-1 rounded" style="background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color); outline: none">
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="ready">Ready</option>
          <option value="running">Running</option>
          <option value="completed">Completed</option>
          <option value="failed">Failed</option>
          <option value="cancelled">Cancelled</option>
          <option value="terminated">Terminated</option>
        </select>
        <button class="header-btn" @click="openImport" title="Import a dataflow JSON dump">
          <Icon icon="tabler:upload" class="w-3.5 h-3.5" />
          Import
        </button>
        <button class="p-1 rounded" style="color: var(--p-text-muted-color)" @click="load"><Icon icon="tabler:refresh" class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" /></button>
      </div>
    </div>

    <!-- Error -->
    <div v-if="error" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" /><span class="flex-1">{{ error }}</span><button @click="load" class="underline">Retry</button>
    </div>

    <!-- Empty -->
    <div v-if="!loading && displayed.length === 0" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <Icon icon="tabler:git-merge" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
        <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">{{ searchTerm || statusFilter ? 'No matching dataflows' : 'No dataflows' }}</p>
      </div>
    </div>

    <!-- Table -->
    <div v-else class="flex-1 overflow-y-auto">
      <table class="w-full text-xs">
        <thead class="sticky top-0" style="background: var(--p-surface-50)">
          <tr style="border-bottom: 1px solid var(--p-content-border-color)">
            <th class="text-left px-4 py-2 font-medium" style="color: var(--p-text-muted-color)">Workflow</th>
            <th class="text-left px-4 py-2 font-medium w-24" style="color: var(--p-text-muted-color)">Type</th>
            <th class="text-left px-4 py-2 font-medium w-24" style="color: var(--p-text-muted-color)">Status</th>
            <th class="text-left px-4 py-2 font-medium w-20" style="color: var(--p-text-muted-color)">Age</th>
            <th class="text-right px-4 py-2 font-medium w-28" style="color: var(--p-text-muted-color)">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="df in displayed" :key="df.dataflow_id"
            class="df-row cursor-pointer"
            @click="viewDataflow(df.dataflow_id)"
          >
            <td class="px-4 py-2.5">
              <div class="font-medium" style="color: var(--p-text-color)">{{ dfTitle(df) }}</div>
              <div class="text-[10px] font-mono mt-0.5 truncate" style="color: var(--p-text-muted-color)">{{ df.dataflow_id }}</div>
              <div v-if="df.parent_dataflow_id" class="text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">
                parent: <span class="font-mono">{{ df.parent_dataflow_id.slice(0, 12) }}...</span>
              </div>
            </td>
            <td class="px-4 py-2.5">
              <span class="px-1.5 py-0.5 rounded text-[10px]" style="background: var(--p-surface-100); color: var(--p-text-color)">{{ df.type || 'workflow' }}</span>
            </td>
            <td class="px-4 py-2.5">
              <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px]" :style="{ background: statusColor(df.status) + '15', color: statusColor(df.status) }">
                <Icon :icon="statusIcon(df.status)" class="w-3 h-3" :class="{ 'animate-pulse': df.status === 'running' }" />
                {{ df.status }}
              </span>
            </td>
            <td class="px-4 py-2.5 whitespace-nowrap" style="color: var(--p-text-muted-color)">{{ timeAgo(df.created_at) }}</td>
            <td class="px-4 py-2.5 text-right" @click.stop>
              <div class="flex items-center justify-end gap-1">
                <button class="text-[10px] px-2 py-0.5 rounded" style="background: var(--p-surface-100); color: var(--p-text-color)" @click="viewDataflow(df.dataflow_id)">View</button>
                <button v-if="df.status === 'running'" class="text-[10px] px-2 py-0.5 rounded bg-warn-500/15 text-warn-500" @click="doCancel(df.dataflow_id)">Cancel</button>
                <button v-if="df.status === 'running'" class="text-[10px] px-2 py-0.5 rounded bg-danger-500/15 text-danger-500" @click="doTerminate(df.dataflow_id)">Kill</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div v-if="totalPages > 1" class="shrink-0 px-4 py-2 flex items-center justify-between text-[11px]" style="border-top: 1px solid var(--p-content-border-color)">
      <span style="color: var(--p-text-muted-color)">
        {{ currentPage * pageSize + 1 }}-{{ Math.min((currentPage + 1) * pageSize, totalCount) }} of {{ totalCount }}
      </span>
      <div class="flex gap-1">
        <button :disabled="currentPage === 0" @click="prevPage" class="px-3 py-1 rounded" :style="{ opacity: currentPage > 0 ? 1 : 0.3, background: 'var(--p-surface-100)', color: 'var(--p-text-color)' }">Previous</button>
        <button :disabled="currentPage >= totalPages - 1" @click="nextPage" class="px-3 py-1 rounded" :style="{ opacity: currentPage < totalPages - 1 ? 1 : 0.3, background: 'var(--p-surface-100)', color: 'var(--p-text-color)' }">Next</button>
      </div>
    </div>

    <!-- Import dialog -->
    <Teleport to="body">
      <div v-if="importOpen" class="import-overlay" @click.self="importOpen = false">
        <div class="import-dialog">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:upload" class="w-5 h-5 keeper-accent" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Import dataflow</span>
          </div>
          <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
            Paste a dataflow JSON dump to render it locally — no live backend required.
            The dump should look like
            <code class="font-mono">{ dataflow, nodes, data }</code>.
          </p>

          <textarea
            v-model="importJson"
            class="import-textarea"
            placeholder='{ "dataflow": { "dataflow_id": "..." }, "nodes": [...], "data": [...] }'
            spellcheck="false"
          />

          <div v-if="importError" class="mt-2 px-2 py-1.5 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
            <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
            <span>{{ importError }}</span>
          </div>

          <div class="flex items-center gap-2 mt-3">
            <button class="header-btn" @click="pasteFromClipboard">
              <Icon icon="tabler:clipboard" class="w-3.5 h-3.5" /> Paste
            </button>
            <label class="header-btn cursor-pointer">
              <Icon icon="tabler:file-upload" class="w-3.5 h-3.5" /> Open file…
              <input type="file" accept=".json,application/json" class="hidden" @change="importFromFile" />
            </label>
            <span class="flex-1"></span>
            <button class="header-btn" @click="importOpen = false">Cancel</button>
            <button class="primary-btn" :disabled="!importJson.trim()" @click="submitImport">
              Render
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.df-row { border-bottom: 1px solid var(--p-content-border-color); }
.df-row:hover { background: var(--p-surface-100); }

.header-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 10px; border-radius: 4px;
  font-size: 11px; font-weight: 500;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background 0.1s, border-color 0.1s;
}
.header-btn:hover { background: var(--p-surface-200); border-color: var(--p-primary-color); }
.primary-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 12px; border-radius: 4px;
  font-size: 11px; font-weight: 600;
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border: 1px solid var(--p-primary-color);
  cursor: pointer;
}
.primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.primary-btn:not(:disabled):hover { opacity: 0.9; }

.import-overlay {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(0,0,0,0.6);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}
.import-dialog {
  width: 600px; max-width: 100%;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}
.import-textarea {
  width: 100%;
  height: 220px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  padding: 8px 10px;
  background: var(--p-surface-50);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  outline: none;
  resize: vertical;
}
.import-textarea:focus { border-color: var(--p-primary-color); }
.hidden { display: none; }
</style>
