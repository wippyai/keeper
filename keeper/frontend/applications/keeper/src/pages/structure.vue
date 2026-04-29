<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import { listNamespaces, listEntries, getEntry, updateEntry, fetchGraph, kindColor, kindIcon, type Namespace, type RegistryEntry } from '../api/registry'
import { entryName, prettyJson } from '../utils'
import EditorWrapper from '../components/editors/EditorWrapper.vue'
import ForceGraph from '../components/shared/ForceGraph.vue'

const api = useApi()
const route = useRoute()

const namespaces = ref<Namespace[]>([])
const nsEntries = ref<Map<string, RegistryEntry[]>>(new Map())
const selectedEntry = ref<RegistryEntry | null>(null)
const entryDetail = ref<any>(null)
const loading = ref(true)
const loadingDetail = ref(false)
const error = ref<string | null>(null)
const searchTerm = ref('')
const detailTab = ref<'edit' | 'meta' | 'data' | 'raw'>('edit')
const editorRef = ref<InstanceType<typeof EditorWrapper> | null>(null)
const saving = ref(false)
const viewMode = ref<'tree' | 'graph'>('tree')
const graphNodes = ref<any[]>([])
const graphEdges = ref<any[]>([])
const loadingGraph = ref(false)
const graphNs = ref('')
const graphNsInput = ref('')
function onKeydown(e: KeyboardEvent) {
  if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault()
    ;(document.querySelector('.ed-save-btn--active') as HTMLButtonElement)?.click()
  }
  if (e.key === 'Escape' && selectedEntry.value) {
    selectedEntry.value = null; entryDetail.value = null
  }
}


async function loadGraph(ns?: string) {
  loadingGraph.value = true
  try {
    const r = await fetchGraph(api, ns || undefined)
    if (r.success === false) {
      graphNodes.value = []; graphEdges.value = []; return
    }
    graphNodes.value = (r.nodes || []).map((n: any) => ({
      id: n.id,
      label: entryName(n.id),
      kind: n.kind,
      type: n.kind === 'external' ? 'dependency' : 'entry',
    }))
    graphEdges.value = r.edges || []
  } catch {
    graphNodes.value = []; graphEdges.value = []
  } finally {
    loadingGraph.value = false
  }
}

function toggleView() {
  viewMode.value = viewMode.value === 'tree' ? 'graph' : 'tree'
  if (viewMode.value === 'graph' && graphNodes.value.length === 0) {
    loadGraph(graphNs.value)
  }
}

function applyGraphNs() {
  graphNs.value = graphNsInput.value.trim()
  graphNodes.value = []
  graphEdges.value = []
  loadGraph(graphNs.value)
}

function onGraphSelect(id: string) {
  navigateToEntry(id)
  viewMode.value = 'tree'
}

const STORAGE_KEY = 'keeper-structure-tree-w'
const treeWidth = ref<number>(parseInt(localStorage.getItem(STORAGE_KEY) || '240'))
function saveTreeWidth() { localStorage.setItem(STORAGE_KEY, String(treeWidth.value)) }

let resizing = false; let startX = 0; let startW = 0
function startResize(e: MouseEvent) {
  resizing = true; startX = e.clientX; startW = treeWidth.value
  document.addEventListener('mousemove', onResize); document.addEventListener('mouseup', stopResize)
  document.body.style.cursor = 'col-resize'; document.body.style.userSelect = 'none'
}
function onResize(e: MouseEvent) { if (!resizing) return; treeWidth.value = Math.max(180, Math.min(400, startW + (e.clientX - startX))) }
function stopResize() { resizing = false; document.removeEventListener('mousemove', onResize); document.removeEventListener('mouseup', stopResize); document.body.style.cursor = ''; document.body.style.userSelect = ''; saveTreeWidth() }

interface TreeNode {
  name: string
  fullPath: string
  count: number
  children: Map<string, TreeNode>
  isLeaf: boolean
}

const nsTree = computed(() => {
  const root = new Map<string, TreeNode>()
  for (const ns of namespaces.value) {
    const parts = ns.name.split('.')
    let level = root
    let path = ''
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i]
      path = path ? path + '.' + part : part
      if (!level.has(part)) {
        level.set(part, { name: part, fullPath: path, count: 0, children: new Map(), isLeaf: false })
      }
      const node = level.get(part)!
      if (i === parts.length - 1) {
        node.count = ns.count
        node.isLeaf = true
      }
      level = node.children
    }
  }
  return root
})

const expandedNs = ref<Set<string>>(new Set())

function toggleExpand(path: string) {
  if (expandedNs.value.has(path)) {
    expandedNs.value.delete(path)
  } else {
    expandedNs.value.add(path)
    const node = findNode(path)
    if (node && node.count > 0) {
      loadNsEntries(path)
    }
  }
}

function findNode(path: string): TreeNode | null {
  const parts = path.split('.')
  let level = nsTree.value
  let node: TreeNode | null = null
  for (const part of parts) {
    node = level.get(part) || null
    if (!node) return null
    level = node.children
  }
  return node
}

function isExpanded(path: string) { return expandedNs.value.has(path) }

type FlatNsItem = { type: 'ns'; node: TreeNode; depth: number }
type FlatEntryItem = { type: 'entry'; entry: RegistryEntry; depth: number; ns: string }
type FlatItem = FlatNsItem | FlatEntryItem

function flattenTree(nodes: Map<string, TreeNode>, depth: number = 0): FlatItem[] {
  const result: FlatItem[] = []
  const sorted = [...nodes.entries()].sort((a, b) => a[0].localeCompare(b[0]))
  for (const [, node] of sorted) {
    result.push({ type: 'ns', node, depth })
    if (isExpanded(node.fullPath)) {
      if (node.children.size > 0) {
        result.push(...flattenTree(node.children, depth + 1))
      }
      const entries = filteredNsEntries(node.fullPath)
      for (const entry of entries) {
        result.push({ type: 'entry', entry, depth: depth + 1, ns: node.fullPath })
      }
    }
  }
  return result
}

const flatTree = computed(() => flattenTree(nsTree.value))

function filteredNsEntries(ns: string): RegistryEntry[] {
  const list = nsEntries.value.get(ns) || []
  if (!searchTerm.value) return list
  const term = searchTerm.value.toLowerCase()
  return list.filter(e => e.id.toLowerCase().includes(term) || (e.meta?.title || '').toLowerCase().includes(term))
}

async function loadNsEntries(ns: string) {
  if (nsEntries.value.has(ns)) return
  try {
    const r = await listEntries(api, { namespace: ns, limit: 500 })
    nsEntries.value.set(ns, r.entries || [])
  } catch {
    nsEntries.value.set(ns, [])
  }
}

async function selectEntry(entry: RegistryEntry) {
  if (selectedEntry.value?.id === entry.id) { selectedEntry.value = null; entryDetail.value = null; return }
  selectedEntry.value = entry; detailTab.value = 'edit'
  loadingDetail.value = true
  try {
    const r = await getEntry(api, entry.id)
    entryDetail.value = r
  } catch { entryDetail.value = null }
  finally { loadingDetail.value = false }
}

async function loadAll() {
  loading.value = true; error.value = null
  try {
    const r = await listNamespaces(api)
    namespaces.value = r.namespaces || []
  } catch (e: any) { error.value = e.message }
  finally { loading.value = false }
}

async function handleSave(updates: { kind?: string; meta?: Record<string, any>; data?: Record<string, any> }) {
  if (!selectedEntry.value) return
  saving.value = true
  try {
    await updateEntry(api, selectedEntry.value.id, { ...updates, merge: true })
    const r = await getEntry(api, selectedEntry.value.id)
    entryDetail.value = r
    editorRef.value?.onSaveResult(true)
  } catch (e: any) {
    const msg = e.response?.data?.message || e.response?.data?.error || e.message
    editorRef.value?.onSaveResult(false, msg)
  } finally {
    saving.value = false
  }
}

async function navigateToEntry(entryId: string) {
  const ns = entryId.split(':')[0]
  if (!ns) return
  const parts = ns.split('.')
  let path = ''
  for (const part of parts) {
    path = path ? path + '.' + part : part
    expandedNs.value.add(path)
  }
  await loadNsEntries(ns)
  const entry = (nsEntries.value.get(ns) || []).find(e => e.id === entryId)
  if (entry) await selectEntry(entry)
}

async function handleRouteQuery() {
  const entryParam = route.query.entry as string | undefined
  const nsParam = route.query.ns as string | undefined
  if (entryParam) {
    viewMode.value = 'tree'
    await navigateToEntry(entryParam)
  } else if (nsParam) {
    viewMode.value = 'tree'
    const parts = nsParam.split('.')
    let path = ''
    for (const part of parts) {
      path = path ? path + '.' + part : part
      expandedNs.value.add(path)
    }
    await loadNsEntries(nsParam)
  }
}

watch(() => route.query, handleRouteQuery)

onMounted(async () => {
  document.addEventListener('keydown', onKeydown)
  await loadAll()
  await handleRouteQuery()
})

onUnmounted(() => {
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="shrink-0 px-3 py-2 flex items-center justify-between gap-2" style="border-bottom: 1px solid var(--p-content-border-color)">
      <div class="flex items-center gap-2">
        <span class="text-xs font-medium" style="color: var(--p-text-color)">Structure</span>
        <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ namespaces.length }} namespaces</span>
        <Icon v-if="loading" icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin keeper-accent" />
      </div>
      <div class="flex items-center gap-2">
        <div class="search-wrap">
          <Icon icon="tabler:search" class="search-icon" />
          <input v-model="searchTerm" type="text" placeholder="Search namespaces..." class="search-input" />
        </div>
        <button
          class="p-1 rounded flex items-center gap-1 text-[10px]"
          :style="{ color: viewMode === 'graph' ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)', background: viewMode === 'graph' ? 'var(--p-surface-100)' : 'transparent' }"
          @click="toggleView"
        >
          <Icon :icon="viewMode === 'graph' ? 'tabler:list-tree' : 'tabler:chart-dots-3'" class="w-3.5 h-3.5" />
        </button>
        <button class="p-1 rounded" style="color: var(--p-text-muted-color)" @click="loadAll"><Icon icon="tabler:refresh" class="w-3.5 h-3.5" /></button>
      </div>
    </div>

    <div v-if="error" class="mx-3 mt-2 px-2 py-1.5 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <span class="flex-1">{{ error }}</span><button @click="loadAll" class="underline">Retry</button>
    </div>

    <!-- Graph view -->
    <div v-show="viewMode === 'graph' && !error" class="flex-1 overflow-hidden relative flex flex-col">
      <!-- Graph namespace filter -->
      <div class="shrink-0 px-3 py-1.5 flex items-center gap-2" style="border-bottom: 1px solid var(--p-content-border-color); background: var(--p-surface-50)">
        <Icon icon="tabler:chart-dots-3" class="w-3.5 h-3.5 keeper-accent" />
        <span class="text-[10px]" style="color: var(--p-text-muted-color)">Namespace</span>
        <div class="flex items-center gap-1">
          <select v-model="graphNsInput" @change="applyGraphNs" class="text-[10px] px-2 py-0.5 rounded" style="background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color); outline: none">
            <option value="">All namespaces</option>
            <option v-for="ns in namespaces" :key="ns.name" :value="ns.name">{{ ns.name }} ({{ ns.count }})</option>
          </select>
        </div>
        <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ graphNodes.length }} nodes / {{ graphEdges.length }} edges</span>
        <Icon v-if="loadingGraph" icon="tabler:loader-2" class="w-3 h-3 animate-spin keeper-accent" />
      </div>
      <div class="flex-1 relative overflow-hidden">
        <ForceGraph
          :nodes="graphNodes"
          :edges="graphEdges"
          :selected-id="selectedEntry?.id"
          @select="onGraphSelect"
        />
      </div>
    </div>

    <div v-show="viewMode === 'tree'" class="flex-1 flex overflow-hidden">
      <!-- Tree: namespaces + entries -->
      <aside class="shrink-0 overflow-y-auto" :style="{ width: treeWidth + 'px' }">
        <template v-for="item in flatTree" :key="item.type === 'ns' ? 'ns:' + item.node.fullPath : 'e:' + item.entry.id">
          <!-- Namespace row -->
          <div
            v-if="item.type === 'ns'"
            class="tree-row flex items-center gap-1 py-1 cursor-pointer text-[11px]"
            :style="{ paddingLeft: (6 + item.depth * 14) + 'px', paddingRight: '6px' }"
            @click="toggleExpand(item.node.fullPath)"
          >
            <button class="w-3 h-3 flex items-center justify-center shrink-0" style="color: var(--p-text-muted-color)">
              <Icon :icon="isExpanded(item.node.fullPath) ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-2.5 h-2.5" />
            </button>
            <Icon :icon="item.node.isLeaf ? 'tabler:package' : 'tabler:folder'" class="w-3 h-3 shrink-0" :class="{ 'text-info-500': item.node.isLeaf }" :style="item.node.isLeaf ? {} : { color: 'var(--p-text-muted-color)' }" />
            <span class="flex-1 truncate" style="color: var(--p-text-color)">{{ item.node.name }}</span>
            <span v-if="item.node.count > 0" class="shrink-0 text-[9px]" style="color: var(--p-text-muted-color)">{{ item.node.count }}</span>
          </div>
          <!-- Entry row -->
          <div
            v-else
            class="tree-row tree-entry flex items-center gap-1.5 py-0.5 cursor-pointer text-[10px]"
            :class="{ 'tree-entry--selected': selectedEntry?.id === item.entry.id }"
            :style="{ paddingLeft: (6 + item.depth * 14 + 16) + 'px', paddingRight: '6px' }"
            @click="selectEntry(item.entry)"
          >
            <Icon :icon="kindIcon(item.entry.kind, item.entry.meta?.type)" class="w-2.5 h-2.5 shrink-0" :style="{ color: kindColor(item.entry.kind, item.entry.meta?.type) }" />
            <span class="flex-1 truncate" style="color: var(--p-text-color)">{{ entryName(item.entry.id) }}</span>
          </div>
        </template>
      </aside>

      <div class="resize-handle" @mousedown="startResize($event)"></div>

      <!-- Right: editor / detail -->
      <div class="flex-1 flex flex-col overflow-hidden min-w-0">
        <template v-if="selectedEntry">
          <div class="shrink-0 px-4 py-2 flex items-center gap-2" style="border-bottom: 1px solid var(--p-content-border-color)">
            <Icon :icon="kindIcon(selectedEntry.kind, selectedEntry.meta?.type)" class="w-4 h-4" :style="{ color: kindColor(selectedEntry.kind, selectedEntry.meta?.type) }" />
            <div class="flex-1 min-w-0">
              <div class="text-xs font-medium truncate" style="color: var(--p-text-color)">{{ entryName(selectedEntry.id) }}</div>
              <div class="text-[10px] font-mono" style="color: var(--p-text-muted-color)">{{ selectedEntry.id }}</div>
            </div>
            <div class="flex gap-1">
              <button v-for="t in (['edit', 'meta', 'data', 'raw'] as const)" :key="t" class="text-[10px] px-2 py-0.5 rounded" :class="{ 'tab-active': detailTab === t }" @click="detailTab = t">{{ t }}</button>
            </div>
            <button class="p-0.5 rounded hover-bg" style="color: var(--p-text-muted-color)" @click="selectedEntry = null; entryDetail = null"><Icon icon="tabler:x" class="w-3.5 h-3.5" /></button>
          </div>

          <div v-if="loadingDetail" class="flex-1 flex items-center justify-center"><Icon icon="tabler:loader-2" class="w-5 h-5 animate-spin keeper-accent" /></div>

          <div v-else-if="detailTab === 'edit'" class="flex-1 overflow-hidden">
            <EditorWrapper
              ref="editorRef"
              :entry="selectedEntry"
              :detail="entryDetail"
              @save="handleSave"
              @navigate="navigateToEntry"
            />
          </div>

          <div v-else class="flex-1 overflow-y-auto p-4">
            <template v-if="detailTab === 'meta'">
              <div class="space-y-2 text-[11px]">
                <div class="info-row"><span class="info-k">ID</span><span class="info-v font-mono">{{ selectedEntry.id }}</span></div>
                <div class="info-row"><span class="info-k">Kind</span><span class="info-v">{{ selectedEntry.kind }}</span></div>
                <template v-for="[key, val] in Object.entries(entryDetail?.entry?.meta || selectedEntry.meta || {})" :key="key">
                  <div class="info-row">
                    <span class="info-k">{{ key }}</span>
                    <span v-if="typeof val === 'string' || typeof val === 'number' || typeof val === 'boolean'" class="info-v">{{ val }}</span>
                    <span v-else class="info-v font-mono text-[10px]">{{ JSON.stringify(val) }}</span>
                  </div>
                </template>
              </div>
              <div v-if="entryDetail?.version" class="mt-3 pt-3" style="border-top: 1px solid var(--p-content-border-color)">
                <div class="text-[10px] uppercase tracking-wider font-medium mb-1" style="color: var(--p-text-muted-color)">Version</div>
                <div class="text-[11px] font-mono" style="color: var(--p-text-muted-color)">{{ entryDetail.version.string }}</div>
              </div>
              <div class="mt-3 pt-3" style="border-top: 1px solid var(--p-content-border-color)">
                <div class="text-[10px] uppercase tracking-wider font-medium mb-1" style="color: var(--p-text-muted-color)">Raw Meta</div>
                <pre class="json-block text-[10px]">{{ prettyJson(entryDetail?.entry?.meta || selectedEntry.meta) }}</pre>
              </div>
            </template>
            <template v-else-if="detailTab === 'data'">
              <pre v-if="entryDetail?.entry?.data && Object.keys(entryDetail.entry.data).length > 0" class="json-block">{{ prettyJson(entryDetail.entry.data) }}</pre>
              <div v-else class="text-xs italic" style="color: var(--p-text-muted-color)">No data</div>
            </template>
            <template v-else>
              <pre class="json-block text-[10px]">{{ prettyJson(entryDetail?.entry || selectedEntry) }}</pre>
            </template>
          </div>
        </template>
        <div v-else class="flex-1 flex items-center justify-center text-xs" style="color: var(--p-text-muted-color)">Select an entry from the tree</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.info-row { display: flex; justify-content: space-between; gap: 8px; }
.info-k { color: var(--p-text-muted-color); flex-shrink: 0; }
.info-v { color: var(--p-text-color); text-align: right; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 60%; }
.json-block { background: var(--p-surface-100); color: var(--p-text-color); border-radius: 6px; padding: 10px 12px; font-size: 11px; font-family: monospace; overflow: auto; white-space: pre-wrap; word-break: break-word; max-height: 500px; }
.tab-active { background: var(--p-surface-100) !important; color: var(--p-text-color) !important; }
.hover-bg:hover { background: var(--p-surface-100); }
.resize-handle { width: 4px; cursor: col-resize; flex-shrink: 0; border-left: 1px solid var(--p-content-border-color); }
.resize-handle:hover { background: var(--p-primary-color); opacity: 0.3; }
.tree-row:hover { background: var(--p-surface-100); }
.tree-entry { opacity: 0.85; }
.tree-entry:hover { opacity: 1; }
.tree-entry--selected { background: var(--p-surface-100) !important; opacity: 1; }
.tree-entry--selected span { color: var(--p-primary-color) !important; }

</style>
