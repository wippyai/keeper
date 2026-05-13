<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi, useHost, useWippy } from '../composables/useWippy'
import {
  listKBs, createKB, deleteKB,
  listNodes, createNode, updateNode, deleteNode,
  searchNodes, semanticSearch,
  startResearch, startBatchResearch, learnProject,
  getStats,
  NODE_TYPES, nodeTypeInfo,
  type KB, type KBNode, type KBStats,
} from '../api/knowledge'
import MarkdownContent from '../components/shared/MarkdownContent.vue'

const router = useRouter()
const api = useApi()
const host = useHost()
const instance = useWippy()

const kbs = ref<KB[]>([])
const selectedKB = ref<string>('')
const showKBManager = ref(false)
const newKBName = ref('')
const newKBDescription = ref('')
const nodes = ref<KBNode[]>([])
const selectedNode = ref<KBNode | null>(null)
const stats = ref<KBStats | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)
const learning = ref(false)
const researching = ref(false)
const showResearch = ref(false)
const researchPrompt = ref('')
const activeResearch = ref<{ id: string; prompt: string; status: string; target_kb?: string } | null>(null)

function kbNameFromId(kbId?: string): string {
  if (!kbId) return ''
  const kb = kbs.value.find(k => k.id === kbId)
  return kb ? kb.name : ''
}

const SEED_TOPICS = [
  { label: 'HTTP Endpoints', prompt: 'Explore HTTP endpoint patterns: entry structure, handler functions, routing, middleware, auth. Read actual entries and Wippy http docs.' },
  { label: 'Lua Functions', prompt: 'Explore function.lua patterns: module imports, method field, pool config, return patterns. Read actual function entries.' },
  { label: 'Lua Libraries', prompt: 'Explore library.lua patterns: module table pattern, imports vs modules, how libraries get DB access. Read actual library entries.' },
  { label: 'Agents & Tools', prompt: 'Explore agent.gen1 and tool patterns: prompt structure, traits, tools, model config, tool input_schema format. Read actual agent entries.' },
  { label: 'Contracts', prompt: 'Explore contract.definition and contract.binding patterns: how interfaces decouple from implementation. Read actual contract entries.' },
  { label: 'Migrations', prompt: 'Explore migration patterns: meta.target_db, up/down functions, table creation, index patterns. Read actual migration entries.' },
  { label: 'Process Services', prompt: 'Explore process.lua and process.service patterns: auto_start, lifecycle, process.receive, process.send. Read actual process entries.' },
  { label: 'State System', prompt: 'Explore keeper state system: state reader API, branch management, overlay tables, reconciliation. Read actual state entries.' },
  { label: 'Security', prompt: 'Explore security patterns: security.actor(), security.policy entries, token stores, auth middleware. Read actual security entries.' },
  { label: 'Dataflows', prompt: 'Explore dataflow patterns: flow.create, agent nodes, parallel, cycle. Read Wippy dataflow docs and actual usage.' },
]

const selectedTopics = ref<Set<number>>(new Set())
const customTopics = ref<string[]>([])
const searchMode = ref<'text' | 'semantic'>('text')
const saving = ref(false)
const filterType = ref('')
const searchQuery = ref('')
const editMode = ref(false)
const showCreate = ref(false)

const newNode = ref({ kb: '', title: '', summary: '', content: '', node_type: 'pattern', source: 'human', confidence: 1.0, scope_kind: '', scope_namespace: '', refs: [] as string[] })

const filteredNodes = computed(() => {
  let list = nodes.value
  if (filterType.value) list = list.filter(n => n.node_type === filterType.value)
  return list
})

const totalResearchTopics = computed(() =>
  selectedTopics.value.size + (researchPrompt.value.trim() ? 1 : 0) + customTopics.value.filter(t => t.trim()).length
)

async function fetchKBs() {
  try {
    const data = await listKBs(api)
    kbs.value = data.kbs || []
  } catch { kbs.value = [] }
}

async function fetchNodes() {
  loading.value = true
  try {
    const data = await listNodes(api, { kb: selectedKB.value || undefined, limit: 500 })
    nodes.value = data.nodes || []
  } catch { nodes.value = [] }
  loading.value = false
}

async function fetchStats() {
  try {
    const data = await getStats(api, selectedKB.value || undefined)
    stats.value = data.stats || null
  } catch { stats.value = null }
}

async function doSearch() {
  if (!searchQuery.value.trim()) { fetchNodes(); return }
  loading.value = true
  try {
    const kb = selectedKB.value || undefined
    if (searchMode.value === 'semantic') {
      const data = await semanticSearch(api, searchQuery.value, { kb })
      nodes.value = data.nodes || []
      if (nodes.value.length === 0) {
        const fallback = await searchNodes(api, searchQuery.value, { kb })
        nodes.value = fallback.nodes || []
      }
    } else {
      const data = await searchNodes(api, searchQuery.value, { kb })
      nodes.value = data.nodes || []
    }
  } catch { nodes.value = [] }
  loading.value = false
}

async function doCreateKB() {
  if (!newKBName.value.trim()) return
  try {
    await createKB(api, { name: newKBName.value.trim(), description: newKBDescription.value.trim() })
    newKBName.value = ''
    newKBDescription.value = ''
    await fetchKBs()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

async function doDeleteKB(kb: KB) {
  if (!await host.confirm({
    header: 'Delete knowledge base',
    message: `Delete "${kb.name}" and ALL its ${kb.node_count} nodes?`,
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
  })) return
  try {
    await deleteKB(api, kb.id)
    if (selectedKB.value === kb.name) selectedKB.value = ''
    await fetchKBs()
    await fetchNodes()
    await fetchStats()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

watch(selectedKB, () => {
  if (selectedNode.value && selectedKB.value) {
    const kb = kbs.value.find(k => k.name === selectedKB.value)
    if (kb && selectedNode.value.kb_id && selectedNode.value.kb_id !== kb.id) {
      selectedNode.value = null
      editMode.value = false
    }
  }
  fetchNodes()
  fetchStats()
})

async function doLearn() {
  learning.value = true
  try {
    const data = await learnProject(api, selectedKB.value || undefined)
    if (data.dataflow_id) {
      activeResearch.value = {
        id: data.dataflow_id,
        prompt: `Learning project (${data.topics} topics)`,
        status: 'running',
        target_kb: data.target_kb,
      }
      watchResearchStatus()
    }
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  learning.value = false
}

async function doResearch() {
  const prompts: string[] = []
  for (const idx of selectedTopics.value) prompts.push(SEED_TOPICS[idx].prompt)
  for (const t of customTopics.value) if (t.trim()) prompts.push(t.trim())
  if (researchPrompt.value.trim()) prompts.push(researchPrompt.value.trim())

  if (prompts.length === 0) return
  researching.value = true

  const kb = selectedKB.value || undefined
  try {
    let data: any
    if (prompts.length === 1) data = await startResearch(api, prompts[0], { kb })
    else data = await startBatchResearch(api, prompts, { kb })
    if (data.dataflow_id) {
      const label = prompts.length === 1 ? prompts[0].slice(0, 60) : `${prompts.length} topics`
      activeResearch.value = {
        id: data.dataflow_id,
        prompt: label,
        status: 'running',
        target_kb: data.target_kb,
      }
      showResearch.value = false
      researchPrompt.value = ''
      selectedTopics.value = new Set()
      customTopics.value = []
      watchResearchStatus()
    }
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  researching.value = false
}

async function refreshNode() {
  if (!selectedNode.value) return
  const prompt = `Review and update this knowledge node if outdated: "${selectedNode.value.title}". Current content: ${selectedNode.value.content.slice(0, 200)}`
  researching.value = true
  const kb = kbNameFromId(selectedNode.value.kb_id)
  try {
    const data = await startResearch(api, prompt, { kb: kb || undefined })
    if (data.dataflow_id) {
      activeResearch.value = {
        id: data.dataflow_id,
        prompt: 'Refresh: ' + selectedNode.value.title,
        status: 'running',
        target_kb: data.target_kb,
      }
      watchResearchStatus()
    }
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  researching.value = false
}

function watchResearchStatus() {
  if (!activeResearch.value) return
  const id = activeResearch.value.id
  const inst = useWippy()
  inst.on(`dataflow:${id}`, async (evt: any) => {
    const data = evt?.data || evt
    const status = data?.status || data?.dataflow?.status
    if (activeResearch.value && activeResearch.value.id === id && status) {
      activeResearch.value.status = status
      if (status === 'completed_success' || status === 'completed_failure' || status === 'failed' || status === 'cancelled' || status === 'terminated') {
        await fetchNodes()
        await fetchStats()
        setTimeout(() => { if (activeResearch.value?.id === id) activeResearch.value = null }, 5000)
      }
    }
  })
}

async function doCreate() {
  if (!newNode.value.title.trim()) return
  try {
    const payload = { ...newNode.value, kb: newNode.value.kb || selectedKB.value || undefined }
    await createNode(api, payload as any)
    newNode.value = { kb: '', title: '', summary: '', content: '', node_type: 'pattern', source: 'human', confidence: 1.0, scope_kind: '', scope_namespace: '', refs: [] }
    showCreate.value = false
    await fetchNodes()
    await fetchStats()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

async function doSave() {
  if (!selectedNode.value) return
  saving.value = true
  try {
    await updateNode(api, selectedNode.value.id, {
      title: selectedNode.value.title,
      content: selectedNode.value.content,
      node_type: selectedNode.value.node_type,
      confidence: selectedNode.value.confidence,
      refs: selectedNode.value.refs,
    })
    editMode.value = false
    await fetchNodes()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  saving.value = false
}

async function doDelete() {
  if (!selectedNode.value) return
  if (!await host.confirm({
    header: 'Delete node',
    message: `Delete "${selectedNode.value.title}"?`,
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
  })) return
  try {
    await deleteNode(api, selectedNode.value.id)
    selectedNode.value = null
    await fetchNodes()
    await fetchStats()
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

function selectNode(node: KBNode) {
  selectedNode.value = { ...node }
  editMode.value = false
}

let debounce: ReturnType<typeof setTimeout> | null = null
watch(searchQuery, () => {
  if (debounce) clearTimeout(debounce)
  debounce = setTimeout(doSearch, 300)
})

let unsub: (() => void) | null = null

onMounted(() => {
  fetchKBs()
  fetchNodes()
  fetchStats()
  unsub = instance.on('keeper.knowledge', () => {
    fetchKBs()
    fetchNodes()
    fetchStats()
  })
})

onUnmounted(() => {
  if (unsub) unsub()
})
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- Header -->
    <div class="shrink-0 px-4 py-3 flex items-center gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
      <Icon icon="tabler:brain" class="w-5 h-5" style="color: var(--p-primary-color)" />
      <h1 class="text-sm font-semibold" style="color: var(--p-text-color)">Knowledge Base</h1>

      <!-- KB selector -->
      <div class="flex items-center gap-1.5 ml-3">
        <Icon icon="tabler:database" class="w-3.5 h-3.5" style="color: var(--p-text-muted-color)" />
        <select v-model="selectedKB" class="kb-select">
          <option value="">All KBs</option>
          <option v-for="kb in kbs" :key="kb.id" :value="kb.name">{{ kb.name }} ({{ kb.node_count }})</option>
        </select>
        <button class="action-btn ghost" @click="showKBManager = true" title="Manage knowledge bases">
          <Icon icon="tabler:settings" class="w-3 h-3" />
        </button>
      </div>

      <div class="flex items-center gap-2 ml-auto">
        <span v-if="stats" class="stat-chip">{{ stats.total }} nodes</span>

        <button class="action-btn" @click="doLearn" :disabled="learning"
          :title="stats && stats.total > 0 ? 'Re-scan project for new patterns' : 'Analyze registry and generate knowledge'">
          <Icon :icon="learning ? 'tabler:loader-2' : 'tabler:school'" class="w-3.5 h-3.5" :class="{ 'animate-spin': learning }" />
          {{ !stats || stats.total === 0 ? 'Learn Project' : 'Re-scan' }}
        </button>
        <button class="action-btn" @click="showResearch = true">
          <Icon icon="tabler:brain" class="w-3.5 h-3.5" />
          Research
        </button>
        <button class="action-btn primary" @click="showCreate = true">
          <Icon icon="tabler:plus" class="w-3.5 h-3.5" />
        </button>
      </div>
    </div>

    <!-- Active research banner -->
    <div v-if="activeResearch" class="shrink-0 px-4 py-2 flex items-center gap-3 bg-accent-500/10"
      style="border-bottom: 1px solid color-mix(in srgb, var(--p-accent-500) 20%, transparent)">
      <Icon v-if="activeResearch.status === 'running'" icon="tabler:loader-2" class="w-4 h-4 animate-spin text-accent-500" />
      <Icon v-else-if="activeResearch.status === 'completed_success'" icon="tabler:check" class="w-4 h-4 text-success-500" />
      <Icon v-else icon="tabler:alert-circle" class="w-4 h-4 text-danger-500" />
      <span class="text-xs" style="color: var(--p-text-color)">
        <span class="font-medium">Research{{ activeResearch.status === 'running' ? ' in progress' : activeResearch.status === 'completed_success' ? ' complete' : ' ' + activeResearch.status }}</span>
        <span v-if="activeResearch.target_kb" class="ml-1.5" style="color: var(--p-primary-color)">→ {{ activeResearch.target_kb }}</span>
        <span class="ml-1.5" style="color: var(--p-text-muted-color)">{{ activeResearch.prompt.slice(0, 80) }}{{ activeResearch.prompt.length > 80 ? '...' : '' }}</span>
      </span>
      <button class="text-[10px] px-2 py-0.5 rounded cursor-pointer ml-auto bg-accent-500/15 text-accent-500"
        style="border: none"
        @click="router.push('/dataflow/' + activeResearch.id)">
        View Dataflow
      </button>
      <button v-if="activeResearch.status !== 'running'" class="text-[10px] px-1.5 py-0.5 rounded cursor-pointer"
        style="background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background)); color: var(--p-text-muted-color); border: none"
        @click="activeResearch = null">
        Dismiss
      </button>
    </div>

    <div class="flex-1 flex min-h-0">
      <!-- Left: Node list -->
      <div class="w-80 shrink-0 flex flex-col" style="border-right: 1px solid var(--p-content-border-color)">
        <!-- Search + Filter -->
        <div class="shrink-0" style="border-bottom: 1px solid var(--p-content-border-color)">
          <div class="flex items-center gap-2 px-2.5 py-2" style="background: color-mix(in srgb, var(--p-text-color) 4%, var(--p-content-background))">
            <Icon :icon="searchMode === 'semantic' ? 'tabler:vector' : 'tabler:search'"
              class="w-3.5 h-3.5 shrink-0 cursor-pointer"
              :class="{ 'text-accent-500': searchMode === 'semantic' }"
              :style="searchMode === 'semantic' ? {} : { color: 'var(--p-text-muted-color)' }"
              :title="searchMode === 'semantic' ? 'Semantic search (click for text)' : 'Text search (click for semantic)'"
              @click="searchMode = searchMode === 'text' ? 'semantic' : 'text'" />
            <input v-model="searchQuery"
              class="flex-1 bg-transparent border-none outline-none text-xs min-w-0"
              style="color: var(--p-text-color)"
              :placeholder="searchMode === 'semantic' ? 'Semantic search...' : 'Search knowledge...'" />
          </div>
          <div class="flex items-center px-2 py-1.5 gap-0.5" style="border-top: 1px solid var(--p-content-border-color)">
            <button class="type-icon-btn" :class="{ active: !filterType }" @click="filterType = ''" title="All">
              <Icon icon="tabler:asterisk" class="w-3 h-3" />
            </button>
            <button v-for="t in NODE_TYPES" :key="t.value"
              class="type-icon-btn" :class="{ active: filterType === t.value }"
              :title="t.label"
              @click="filterType = filterType === t.value ? '' : t.value">
              <Icon :icon="t.icon" class="w-3 h-3" />
            </button>
            <span v-if="filterType" class="text-[9px] ml-1" style="color: var(--p-text-muted-color)">{{ NODE_TYPES.find(t => t.value === filterType)?.label }}</span>
          </div>
        </div>

        <!-- Node list -->
        <div class="flex-1 overflow-y-auto">
          <div v-if="loading && nodes.length === 0" class="p-4 text-center text-xs" style="color: var(--p-text-muted-color)">Loading...</div>
          <div v-else-if="filteredNodes.length === 0" class="p-4 text-center text-xs" style="color: var(--p-text-muted-color)">
            {{ searchQuery ? 'No results' : 'No knowledge nodes yet.' }}
          </div>
          <div
            v-for="node in filteredNodes" :key="node.id"
            class="node-item"
            :class="{ active: selectedNode?.id === node.id }"
            @click="selectNode(node)">
            <div class="flex items-center gap-2">
              <Icon :icon="nodeTypeInfo(node.node_type).icon" class="w-3.5 h-3.5 shrink-0" :class="nodeTypeInfo(node.node_type).text" />
              <span class="text-xs font-medium truncate" style="color: var(--p-text-color)">{{ node.title }}</span>
            </div>
            <div v-if="node.summary" class="text-[10px] mt-0.5 ml-5.5 truncate" style="color: var(--p-text-muted-color)">{{ node.summary }}</div>
            <div class="flex items-center gap-1.5 mt-0.5 ml-5.5 flex-wrap">
              <span class="badge" :class="[nodeTypeInfo(node.node_type).text, nodeTypeInfo(node.node_type).bg]">
                {{ node.node_type }}
              </span>
              <span v-if="!selectedKB && kbNameFromId(node.kb_id)" class="kb-tag">
                <Icon icon="tabler:database" class="w-2.5 h-2.5" /> {{ kbNameFromId(node.kb_id) }}
              </span>
              <span v-if="node.scope_kind" class="scope-tag">{{ node.scope_kind }}</span>
              <span v-if="node.scope_namespace" class="scope-tag ns">{{ node.scope_namespace }}</span>
              <span v-if="node.scope_meta_type && node.scope_meta_type !== node.scope_kind" class="scope-tag mt">{{ node.scope_meta_type }}</span>
              <span v-if="node.distance != null" class="text-[9px] font-mono text-accent-500">{{ (Math.max(0, 100 - node.distance * 30)).toFixed(0) }}%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Detail / Editor -->
      <div class="flex-1 flex flex-col min-w-0">
        <template v-if="selectedNode">
          <!-- Detail header -->
          <div class="shrink-0 px-4 py-2.5 flex items-center gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
            <Icon :icon="nodeTypeInfo(selectedNode.node_type).icon" class="w-4 h-4" :class="nodeTypeInfo(selectedNode.node_type).text" />
            <template v-if="editMode">
              <input v-model="selectedNode.title" class="flex-1 bg-transparent border-none outline-none text-sm font-medium" style="color: var(--p-text-color)" />
            </template>
            <template v-else>
              <span class="text-sm font-medium" style="color: var(--p-text-color)">{{ selectedNode.title }}</span>
            </template>
            <div class="ml-auto flex items-center gap-1.5">
              <template v-if="editMode">
                <button class="action-btn primary" @click="doSave" :disabled="saving">
                  <Icon :icon="saving ? 'tabler:loader-2' : 'tabler:check'" class="w-3.5 h-3.5" :class="{ 'animate-spin': saving }" />
                  Save
                </button>
                <button class="action-btn" @click="editMode = false">Cancel</button>
              </template>
              <template v-else>
                <button class="action-btn" @click="refreshNode" :disabled="researching" title="Re-research this topic">
                  <Icon :icon="researching ? 'tabler:loader-2' : 'tabler:refresh'" class="w-3.5 h-3.5" :class="{ 'animate-spin': researching }" />
                </button>
                <button class="action-btn" @click="editMode = true">
                  <Icon icon="tabler:pencil" class="w-3.5 h-3.5" />
                  Edit
                </button>
                <button class="action-btn danger" @click="doDelete">
                  <Icon icon="tabler:trash" class="w-3.5 h-3.5" />
                </button>
              </template>
            </div>
          </div>

          <!-- Detail body -->
          <div class="flex-1 overflow-y-auto p-4 flex flex-col gap-4">
            <!-- Metadata row -->
            <div class="flex items-center gap-3 flex-wrap">
              <template v-if="editMode">
                <select v-model="selectedNode.node_type" class="field-select">
                  <option v-for="t in NODE_TYPES" :key="t.value" :value="t.value">{{ t.label }}</option>
                </select>
                <div class="flex items-center gap-1.5">
                  <span class="text-[10px]" style="color: var(--p-text-muted-color)">Confidence</span>
                  <input type="range" v-model.number="selectedNode.confidence" min="0" max="1" step="0.1" class="w-20" />
                  <span class="text-[10px] font-mono" style="color: var(--p-text-color)">{{ Math.round(selectedNode.confidence * 100) }}%</span>
                </div>
              </template>
              <template v-else>
                <span class="meta-badge" :class="[nodeTypeInfo(selectedNode.node_type).text, nodeTypeInfo(selectedNode.node_type).bg]">
                  <Icon :icon="nodeTypeInfo(selectedNode.node_type).icon" class="w-3 h-3" />
                  {{ nodeTypeInfo(selectedNode.node_type).label }}
                </span>
                <span v-if="kbNameFromId(selectedNode.kb_id)" class="meta-badge primary">
                  <Icon icon="tabler:database" class="w-3 h-3" />
                  {{ kbNameFromId(selectedNode.kb_id) }}
                </span>
                <span class="meta-badge">
                  <Icon icon="tabler:source-code" class="w-3 h-3" />
                  {{ selectedNode.source }}
                </span>
                <span class="meta-badge">
                  {{ Math.round(selectedNode.confidence * 100) }}% confidence
                </span>
              </template>
            </div>

            <!-- Scope -->
            <div v-if="!editMode && (selectedNode.scope_namespace || selectedNode.scope_kind || selectedNode.scope_meta_type || (selectedNode.refs && selectedNode.refs.length > 0))"
              class="flex items-center gap-1.5 flex-wrap">
              <span class="text-[9px] font-semibold" style="color: var(--p-text-muted-color)">APPLIES TO</span>
              <span v-if="selectedNode.scope_kind" class="scope-detail kind">
                <Icon icon="tabler:file-code" class="w-3 h-3" /> {{ selectedNode.scope_kind }}
              </span>
              <span v-if="selectedNode.scope_meta_type" class="scope-detail mt">
                <Icon icon="tabler:tag" class="w-3 h-3" /> {{ selectedNode.scope_meta_type }}
              </span>
              <span v-if="selectedNode.scope_namespace" class="scope-detail ns">
                <Icon icon="tabler:folder" class="w-3 h-3" /> {{ selectedNode.scope_namespace }}
              </span>
              <template v-if="selectedNode.refs && selectedNode.refs.length > 0">
                <span class="text-[9px] font-semibold ml-2" style="color: var(--p-text-muted-color)">REFS</span>
                <span v-for="r in selectedNode.refs" :key="r" class="ref-badge">{{ r }}</span>
              </template>
            </div>

            <!-- Content -->
            <div class="flex-1">
              <template v-if="editMode">
                <textarea v-model="selectedNode.content"
                  class="w-full h-full min-h-[300px] p-3 rounded text-xs font-mono resize-none"
                  style="background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background)); color: var(--p-text-color); border: 1px solid var(--p-content-border-color); outline: none" />
              </template>
              <template v-else>
                <div class="content-display">
                  <MarkdownContent :content="selectedNode.content" />
                </div>
              </template>
            </div>

            <!-- Timestamps -->
            <div class="flex items-center gap-4 text-[9px]" style="color: var(--p-text-muted-color)">
              <span>Created: {{ selectedNode.created_at }}</span>
              <span>Updated: {{ selectedNode.updated_at }}</span>
              <span class="font-mono opacity-50">{{ selectedNode.id.slice(0, 8) }}</span>
            </div>
          </div>
        </template>

        <!-- Empty state -->
        <div v-else class="flex-1 flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:brain" class="w-12 h-12 mx-auto mb-3" style="color: var(--p-text-muted-color); opacity: 0.4" />
            <template v-if="!stats || stats.total === 0">
              <div class="text-sm mb-2" style="color: var(--p-text-muted-color)">Knowledge base is empty</div>
              <button class="action-btn primary mx-auto" @click="doLearn" :disabled="learning">
                <Icon :icon="learning ? 'tabler:loader-2' : 'tabler:school'" class="w-3.5 h-3.5" :class="{ 'animate-spin': learning }" />
                Learn Project
              </button>
              <div class="text-[10px] mt-2" style="color: var(--p-text-muted-color)">Analyzes registry structure and generates knowledge automatically</div>
            </template>
            <template v-else>
              <div class="text-sm" style="color: var(--p-text-muted-color)">Select a knowledge node</div>
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- Research modal -->
    <Teleport to="body">
      <div v-if="showResearch" class="modal-overlay" @click.self="showResearch = false">
        <div class="modal-panel" style="width: 560px; max-height: 80vh; display: flex; flex-direction: column;">
          <div class="flex items-center gap-2 mb-2">
            <Icon icon="tabler:brain" class="w-4 h-4" style="color: var(--p-primary-color)" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Research Knowledge</span>
            <span class="text-[9px] ml-auto" style="color: var(--p-text-muted-color)">Topics run in parallel</span>
          </div>

          <div class="flex-1 overflow-y-auto flex flex-col gap-3">
            <div>
              <label class="field-label">Topics</label>
              <div class="topic-grid">
                <label v-for="(topic, i) in SEED_TOPICS" :key="i" class="topic-item" :class="{ checked: selectedTopics.has(i) }">
                  <input type="checkbox" :checked="selectedTopics.has(i)"
                    @change="selectedTopics.has(i) ? selectedTopics.delete(i) : selectedTopics.add(i); selectedTopics = new Set(selectedTopics)" />
                  <span>{{ topic.label }}</span>
                </label>
              </div>
              <div class="flex gap-1.5 mt-1.5">
                <button class="research-preset" @click="selectedTopics = new Set(SEED_TOPICS.map((_, i) => i))">Select all</button>
                <button class="research-preset" @click="selectedTopics = new Set()">Clear</button>
              </div>
            </div>

            <div>
              <label class="field-label">Custom prompt (optional)</label>
              <textarea v-model="researchPrompt" class="field-input resize-y" rows="2"
                placeholder="Additional research topic..." />
            </div>
          </div>

          <div class="flex items-center justify-between mt-3 pt-2" style="border-top: 1px solid var(--p-content-border-color)">
            <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ totalResearchTopics }} topic(s) selected</span>
            <div class="flex gap-2">
              <button class="action-btn" @click="showResearch = false">Cancel</button>
              <button class="action-btn primary" @click="doResearch"
                :disabled="totalResearchTopics === 0 || researching">
                <Icon :icon="researching ? 'tabler:loader-2' : 'tabler:player-play'" class="w-3.5 h-3.5" :class="{ 'animate-spin': researching }" />
                {{ researching ? 'Starting...' : 'Start' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Create modal -->
    <Teleport to="body">
      <div v-if="showCreate" class="modal-overlay" @click.self="showCreate = false">
        <div class="modal-panel">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:plus" class="w-4 h-4" style="color: var(--p-primary-color)" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Add Knowledge</span>
          </div>

          <div class="flex flex-col gap-3">
            <div>
              <label class="field-label">Knowledge Base</label>
              <select v-model="newNode.kb" class="field-input">
                <option value="">{{ selectedKB || 'General' }} (current)</option>
                <option v-for="kb in kbs" :key="kb.id" :value="kb.name">{{ kb.name }}</option>
              </select>
            </div>
            <div>
              <label class="field-label">Type</label>
              <div class="flex gap-1.5 flex-wrap">
                <button v-for="t in NODE_TYPES" :key="t.value"
                  class="type-chip" :class="{ active: newNode.node_type === t.value }"
                  @click="newNode.node_type = t.value">
                  <Icon :icon="t.icon" class="w-2.5 h-2.5" />
                  {{ t.label }}
                </button>
              </div>
            </div>
            <div>
              <label class="field-label">Title</label>
              <input v-model="newNode.title" class="field-input" placeholder="e.g. HTTP Endpoint with Auth" />
            </div>
            <div>
              <label class="field-label">Summary</label>
              <input v-model="newNode.summary" class="field-input" placeholder="One sentence for quick scanning..." />
            </div>
            <div>
              <label class="field-label">Content</label>
              <textarea v-model="newNode.content" class="field-input min-h-[100px] resize-y" placeholder="YAML snippets, Lua code, step-by-step recipe..." />
            </div>
            <div class="flex gap-2">
              <div class="flex-1">
                <label class="field-label">Scope: Kind</label>
                <input v-model="newNode.scope_kind" class="field-input" placeholder="e.g. http.endpoint" />
              </div>
              <div class="flex-1">
                <label class="field-label">Scope: Namespace</label>
                <input v-model="newNode.scope_namespace" class="field-input" placeholder="e.g. keeper.state.api" />
              </div>
            </div>
            <div class="flex justify-end gap-2 mt-1">
              <button class="action-btn" @click="showCreate = false">Cancel</button>
              <button class="action-btn primary" @click="doCreate" :disabled="!newNode.title.trim()">Create</button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- KB Manager modal -->
    <Teleport to="body">
      <div v-if="showKBManager" class="modal-overlay" @click.self="showKBManager = false">
        <div class="modal-panel">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:database" class="w-4 h-4" style="color: var(--p-primary-color)" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Knowledge Bases</span>
          </div>

          <div class="flex flex-col gap-3">
            <div v-if="kbs.length > 0" class="flex flex-col gap-1.5">
              <div v-for="kb in kbs" :key="kb.id" class="kb-card">
                <Icon icon="tabler:database" class="w-3.5 h-3.5" style="color: var(--p-primary-color)" />
                <div class="flex-1 min-w-0">
                  <div class="text-xs font-medium" style="color: var(--p-text-color)">{{ kb.name }}</div>
                  <div v-if="kb.description" class="text-[10px]" style="color: var(--p-text-muted-color)">{{ kb.description }}</div>
                </div>
                <span class="text-[10px] font-mono" style="color: var(--p-text-muted-color)">{{ kb.node_count }}</span>
                <button class="action-btn ghost danger" @click="doDeleteKB(kb)" :title="`Delete ${kb.name}`">
                  <Icon icon="tabler:trash" class="w-3 h-3" />
                </button>
              </div>
            </div>
            <div v-else class="text-xs text-center py-4" style="color: var(--p-text-muted-color)">No knowledge bases yet.</div>

            <div class="pt-3" style="border-top: 1px solid var(--p-content-border-color)">
              <label class="field-label">Create new KB</label>
              <input v-model="newKBName" class="field-input" placeholder="Name (e.g. 'Wippy Patterns')" />
              <input v-model="newKBDescription" class="field-input mt-2" placeholder="Description (optional)" />
              <div class="flex justify-end gap-2 mt-2">
                <button class="action-btn" @click="showKBManager = false">Close</button>
                <button class="action-btn primary" @click="doCreateKB" :disabled="!newKBName.trim()">Create KB</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
/* Theme-aware colors using only semantic PrimeVue variables that flip in dark mode:
     --p-content-background      page background (white → dark)
     --p-text-color               text (dark → light)
     --p-text-muted-color         muted text (medium → lighter)
     --p-content-border-color     borders (light → dark)
     --p-content-hover-background hover bg (light → dark)
   Surface tints/elevated cards are derived via color-mix() of the above so they
   automatically flip with the theme — never use --p-surface-50/100 directly. */

/* Local subtle/elevated background helpers (auto-flip via color-mix) */
.bg-tint { background: color-mix(in srgb, var(--p-text-color) 4%, var(--p-content-background)); }
.bg-elev { background: color-mix(in srgb, var(--p-text-color) 6%, var(--p-content-background)); }

.node-item {
  padding: 8px 12px;
  cursor: pointer;
  border-bottom: 1px solid var(--p-content-border-color);
}
.node-item:hover { background: var(--p-content-hover-background); }
.node-item.active { background: color-mix(in srgb, var(--p-primary-color) 12%, transparent); }

.badge {
  display: inline-flex; align-items: center;
  text-transform: capitalize;
  font-size: 9px;
  padding: 1px 6px;
  border-radius: 3px;
}

.kb-tag {
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 9px; font-weight: 500;
  padding: 1px 5px; border-radius: 3px;
  color: var(--p-primary-color);
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-primary-color) 25%, transparent);
}

.scope-tag {
  padding: 1px 5px; border-radius: 3px;
  font-size: 8px; font-family: monospace;
  color: var(--p-info-500);
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-info-500) 22%, transparent);
}
.scope-tag.ns { color: var(--p-accent-500); background: color-mix(in srgb, var(--p-accent-500) 12%, transparent); border-color: color-mix(in srgb, var(--p-accent-500) 22%, transparent); }
.scope-tag.mt { color: var(--p-warn-500); background: color-mix(in srgb, var(--p-warn-500) 12%, transparent); border-color: color-mix(in srgb, var(--p-warn-500) 22%, transparent); }

.scope-detail {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px; font-family: monospace;
}
.scope-detail.kind { color: var(--p-info-500); background: color-mix(in srgb, var(--p-info-500) 12%, transparent); }
.scope-detail.mt { color: var(--p-warn-500); background: color-mix(in srgb, var(--p-warn-500) 12%, transparent); }
.scope-detail.ns { color: var(--p-accent-500); background: color-mix(in srgb, var(--p-accent-500) 12%, transparent); }

.ref-badge {
  padding: 2px 6px; border-radius: 3px;
  font-size: 9px; font-family: monospace;
  background: color-mix(in srgb, var(--p-primary-color) 10%, transparent);
  color: var(--p-primary-color);
}

.content-display {
  font-size: 12px; line-height: 1.6;
  color: var(--p-text-color);
  padding: 12px; border-radius: 6px;
  background: color-mix(in srgb, var(--p-text-color) 4%, var(--p-content-background));
  border: 1px solid var(--p-content-border-color);
}

.stat-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 10px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
  color: var(--p-text-muted-color);
}

.meta-badge {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
  color: var(--p-text-muted-color);
}
.meta-badge.primary {
  color: var(--p-primary-color);
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
}

.action-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 4px;
  font-size: 11px; font-weight: 500;
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background 0.12s, border-color 0.12s;
}
.action-btn:hover:not(:disabled) {
  background: color-mix(in srgb, var(--p-text-color) 14%, var(--p-content-background));
}
.action-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.action-btn.primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
}
.action-btn.primary:hover:not(:disabled) { opacity: 0.9; }
.action-btn.danger { color: var(--p-danger-500); }
.action-btn.danger:hover:not(:disabled) { background: color-mix(in srgb, var(--p-danger-500) 12%, transparent); border-color: color-mix(in srgb, var(--p-danger-500) 40%, transparent); }
.action-btn.ghost {
  background: transparent;
  border-color: transparent;
  padding: 4px 6px;
}
.action-btn.ghost:hover:not(:disabled) {
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
}
.action-btn.ghost.danger:hover:not(:disabled) { background: color-mix(in srgb, var(--p-danger-500) 12%, transparent); }

.kb-select {
  padding: 4px 8px; border-radius: 4px;
  font-size: 11px; font-weight: 500;
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  cursor: pointer;
  min-width: 140px;
  transition: background 0.12s;
}
.kb-select:hover { background: color-mix(in srgb, var(--p-text-color) 14%, var(--p-content-background)); }
.kb-select:focus { border-color: var(--p-primary-color); }

.field-label {
  display: block; font-size: 10px; font-weight: 600;
  color: var(--p-text-muted-color);
  margin-bottom: 4px;
}
.field-input {
  width: 100%; padding: 6px 10px; border-radius: 4px;
  font-size: 12px;
  background: color-mix(in srgb, var(--p-text-color) 6%, var(--p-content-background));
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  transition: border-color 0.12s;
}
.field-input:focus { border-color: var(--p-primary-color); }
.field-input::placeholder { color: var(--p-text-muted-color); }

.field-select {
  padding: 3px 8px; border-radius: 4px;
  font-size: 11px;
  background: color-mix(in srgb, var(--p-text-color) 6%, var(--p-content-background));
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
}

.type-icon-btn {
  width: 26px; height: 26px; border-radius: 5px;
  display: inline-flex; align-items: center; justify-content: center;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid transparent;
  cursor: pointer;
  transition: background 0.12s, color 0.12s;
}
.type-icon-btn:hover {
  background: color-mix(in srgb, var(--p-text-color) 10%, var(--p-content-background));
  color: var(--p-text-color);
}
.type-icon-btn.active {
  color: var(--p-primary-color);
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  border-color: color-mix(in srgb, var(--p-primary-color) 28%, transparent);
}

.type-chip {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 3px 10px; border-radius: 10px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
  color: var(--p-text-muted-color);
  border: 1px solid transparent;
  cursor: pointer;
  transition: background 0.12s;
}
.type-chip:hover { background: color-mix(in srgb, var(--p-text-color) 14%, var(--p-content-background)); }
.type-chip.active {
  color: var(--p-primary-color);
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  border-color: var(--p-primary-color);
}

.topic-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4px;
}
.topic-item {
  display: flex; align-items: center; gap: 6px;
  padding: 5px 8px; border-radius: 4px;
  font-size: 11px;
  background: color-mix(in srgb, var(--p-text-color) 4%, var(--p-content-background));
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  color: var(--p-text-color);
  transition: background 0.12s, border-color 0.12s;
}
.topic-item:hover { background: color-mix(in srgb, var(--p-text-color) 10%, var(--p-content-background)); }
.topic-item.checked {
  border-color: var(--p-primary-color);
  background: color-mix(in srgb, var(--p-primary-color) 10%, transparent);
}
.topic-item input { width: 13px; height: 13px; accent-color: var(--p-primary-color); }

.research-preset {
  padding: 3px 8px; border-radius: 10px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-text-color) 8%, var(--p-content-background));
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background 0.12s, color 0.12s;
}
.research-preset:hover {
  background: color-mix(in srgb, var(--p-text-color) 14%, var(--p-content-background));
  color: var(--p-text-color);
}

.kb-card {
  display: flex; align-items: center; gap: 8px;
  padding: 6px 10px; border-radius: 4px;
  background: color-mix(in srgb, var(--p-text-color) 4%, var(--p-content-background));
  border: 1px solid var(--p-content-border-color);
}

.modal-overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: color-mix(in srgb, black 60%, transparent);
  backdrop-filter: blur(2px);
  display: flex; align-items: center; justify-content: center;
}
.modal-panel {
  width: 480px; padding: 20px; border-radius: 8px;
  background: var(--p-content-background);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
}
</style>
