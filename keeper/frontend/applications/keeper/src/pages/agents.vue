<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi, useHost } from '../composables/useWippy'
import { entryName } from '../utils'
import EntryDetailPanel from '../components/shared/EntryDetailPanel.vue'
import PageHeader from '../components/shared/PageHeader.vue'

interface Agent {
  id: string
  title: string
  comment: string
  icon: string
  model: string
  class: string[]
  start_token: string
  max_tokens?: number
  temperature?: number
  thinking_effort?: string
  traits_count?: number
  tools_count?: number
  delegates_count?: number
  memory_contract?: string
  has_prompt?: boolean
  prompt_preview?: string
}

const api = useApi()
const host = useHost()

const agents = ref<Agent[]>([])
const loading = ref(true)
const search = ref('')
const sortBy = ref<'name' | 'namespace' | 'model'>('namespace')
const classFilter = ref<string>('')
const selectedId = ref<string | null>(null)

const allClasses = computed(() => {
  const set = new Set<string>()
  for (const a of agents.value) for (const c of (a.class || [])) set.add(c)
  return Array.from(set).sort()
})

const filtered = computed(() => {
  let list = agents.value
  if (classFilter.value) {
    list = list.filter(a => (a.class || []).includes(classFilter.value))
  }
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(a =>
      a.title?.toLowerCase().includes(q) ||
      a.id.toLowerCase().includes(q) ||
      (a.comment || '').toLowerCase().includes(q) ||
      (a.model || '').toLowerCase().includes(q) ||
      (a.class || []).some(c => c.toLowerCase().includes(q)),
    )
  }
  return [...list].sort((a, b) => {
    if (sortBy.value === 'name') return (a.title || a.id).localeCompare(b.title || b.id)
    if (sortBy.value === 'model') return (a.model || '').localeCompare(b.model || '') || a.id.localeCompare(b.id)
    return a.id.localeCompare(b.id)
  })
})

const grouped = computed(() => {
  if (sortBy.value !== 'namespace') return [['', filtered.value] as [string, Agent[]]]
  const groups: Record<string, Agent[]> = {}
  for (const a of filtered.value) {
    const ns = a.id.split(':')[0] || 'other'
    if (!groups[ns]) groups[ns] = []
    groups[ns].push(a)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

const stats = computed(() => {
  const list = agents.value
  const withPrompt = list.filter(a => a.has_prompt).length
  const withMemory = list.filter(a => a.memory_contract).length
  const totalTraits = list.reduce((s, a) => s + (a.traits_count || 0), 0)
  const totalTools = list.reduce((s, a) => s + (a.tools_count || 0), 0)
  return { total: list.length, withPrompt, withMemory, totalTraits, totalTools }
})

function startChat(token: string, e: Event) {
  e.stopPropagation()
  host.startChat(token, { sidebar: true })
}

function selectAgent(id: string) {
  selectedId.value = selectedId.value === id ? null : id
}

function shortModel(m?: string): string {
  if (!m) return ''
  return m.replace(/^class:/, '').replace(/^[a-z.]+:/, '')
}

function classColor(c: string): string {
  if (c === 'public') return 'var(--p-success-500)'
  if (c === 'orchestrator' || c === 'developer') return 'var(--p-warn-500)'
  if (c === 'researcher' || c === 'reviewer') return 'var(--p-info-500)'
  if (c === 'system' || c === 'internal') return 'var(--p-text-muted-color)'
  return 'var(--p-accent-500)'
}

async function load() {
  loading.value = true
  try {
    const { data } = await api.get('/api/v1/keeper/agents/list')
    agents.value = data.agents || []
  } catch {
    agents.value = []
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader
      icon="tabler:robot"
      title="Agents"
      :count="filtered.length === agents.length ? agents.length : `${filtered.length} / ${agents.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search agents…" class="search-input" />
      </div>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="namespace">By namespace</option>
        <option value="name">By name</option>
        <option value="model">By model</option>
      </select>
    </PageHeader>

    <!-- Stats strip -->
    <div v-if="!loading && agents.length" class="stats-row">
      <div class="stat-pill">
        <span class="stat-num">{{ stats.total }}</span>
        <span class="stat-lbl">agents</span>
      </div>
      <div class="stat-pill stat-pill--accent">
        <Icon icon="tabler:message-bolt" class="w-3 h-3" />
        <span class="stat-num">{{ stats.withPrompt }}</span>
        <span class="stat-lbl">with prompt</span>
      </div>
      <div class="stat-pill stat-pill--info">
        <Icon icon="tabler:sparkles" class="w-3 h-3" />
        <span class="stat-num">{{ stats.totalTraits }}</span>
        <span class="stat-lbl">trait bindings</span>
      </div>
      <div class="stat-pill stat-pill--warn">
        <Icon icon="tabler:tool" class="w-3 h-3" />
        <span class="stat-num">{{ stats.totalTools }}</span>
        <span class="stat-lbl">tool bindings</span>
      </div>
      <div v-if="stats.withMemory" class="stat-pill stat-pill--success">
        <Icon icon="tabler:database" class="w-3 h-3" />
        <span class="stat-num">{{ stats.withMemory }}</span>
        <span class="stat-lbl">with memory</span>
      </div>

      <div v-if="allClasses.length" class="class-filter">
        <button
          class="class-chip"
          :class="{ 'class-chip--active': !classFilter }"
          @click="classFilter = ''"
        >all</button>
        <button
          v-for="c in allClasses" :key="c"
          class="class-chip"
          :class="{ 'class-chip--active': classFilter === c }"
          :style="{ '--cc': classColor(c) }"
          @click="classFilter = classFilter === c ? '' : c"
        >{{ c }}</button>
      </div>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <div class="flex-1 overflow-y-auto p-4 min-w-0">
        <div v-if="!loading && agents.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:robot" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
            <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No agents configured</p>
          </div>
        </div>

        <template v-else>
          <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
            <div v-if="ns" class="ns-head">
              <Icon icon="tabler:folder" class="w-3 h-3" />
              <span>{{ ns }}</span>
              <span class="ns-count">{{ items.length }}</span>
            </div>
            <div class="agent-list">
              <div
                v-for="agent in items" :key="agent.id"
                class="agent-row"
                :class="{ 'agent-row--selected': selectedId === agent.id }"
                :title="agent.comment || ''"
                @click="selectAgent(agent.id)"
              >
                <div class="agent-icon">
                  <Icon :icon="agent.icon || 'tabler:robot'" class="w-3.5 h-3.5" />
                </div>
                <div class="agent-main">
                  <span class="agent-title">{{ agent.title || entryName(agent.id) }}</span>
                  <span
                    v-for="c in (agent.class || []).slice(0, 2)" :key="c"
                    class="class-badge"
                    :style="{ '--cc': classColor(c) }"
                  >{{ c }}</span>
                  <span v-if="(agent.class || []).length > 2" class="class-badge more" :title="(agent.class || []).slice(2).join(', ')">+{{ (agent.class || []).length - 2 }}</span>
                  <span class="agent-id">{{ agent.id }}</span>
                </div>
                <div class="agent-spec">
                  <span v-if="agent.model" class="spec-pill spec-model" :title="agent.model">
                    <Icon icon="tabler:brain" class="w-3 h-3" />
                    <span class="spec-val">{{ shortModel(agent.model) }}</span>
                  </span>
                  <span v-if="agent.max_tokens" class="spec-pill" :title="`max_tokens=${agent.max_tokens}`">
                    <Icon icon="tabler:arrows-maximize" class="w-3 h-3" />
                    <span class="spec-val">{{ agent.max_tokens >= 1000 ? (agent.max_tokens/1000).toFixed(0) + 'k' : agent.max_tokens }}</span>
                  </span>
                  <span v-if="agent.temperature != null" class="spec-pill" :title="`temp=${agent.temperature}`">
                    <Icon icon="tabler:temperature" class="w-3 h-3" />
                    <span class="spec-val">{{ agent.temperature }}</span>
                  </span>
                  <span v-if="agent.thinking_effort" class="spec-pill spec-think" :title="`effort=${agent.thinking_effort}`">
                    <Icon icon="tabler:bulb" class="w-3 h-3" />
                  </span>
                  <span v-if="agent.traits_count" class="spec-pill spec-info" :title="`${agent.traits_count} traits`">
                    <Icon icon="tabler:sparkles" class="w-3 h-3" />
                    <span class="spec-val">{{ agent.traits_count }}</span>
                  </span>
                  <span v-if="agent.tools_count" class="spec-pill spec-warn" :title="`${agent.tools_count} tools`">
                    <Icon icon="tabler:tool" class="w-3 h-3" />
                    <span class="spec-val">{{ agent.tools_count }}</span>
                  </span>
                  <span v-if="agent.delegates_count" class="spec-pill spec-accent" :title="`${agent.delegates_count} delegates`">
                    <Icon icon="tabler:share" class="w-3 h-3" />
                    <span class="spec-val">{{ agent.delegates_count }}</span>
                  </span>
                  <span v-if="agent.memory_contract" class="spec-pill spec-success" :title="`memory: ${agent.memory_contract}`">
                    <Icon icon="tabler:database" class="w-3 h-3" />
                  </span>
                </div>
                <button v-if="agent.start_token" class="chat-btn" @click.stop="startChat(agent.start_token, $event)" title="Open chat">
                  <Icon icon="tabler:message-bolt" class="w-3 h-3" />
                </button>
              </div>
            </div>
          </div>
        </template>
      </div>

      <div v-if="selectedId" class="shrink-0 detail-pane">
        <EntryDetailPanel
          :entry-id="selectedId"
          icon="tabler:robot"
          @close="selectedId = null"
        >
          <template #overview="{ entry }">
            <div v-if="entry?.data" class="space-y-3">
              <div v-if="entry.data.model" class="kv">
                <div class="k">Model</div>
                <div class="v font-mono">{{ entry.data.model }}</div>
              </div>
              <div v-if="entry.data.max_tokens || entry.data.temperature || entry.data.thinking_effort" class="kv">
                <div class="k">Generation</div>
                <div class="v">
                  <span v-if="entry.data.max_tokens" class="mr-2">max_tokens={{ entry.data.max_tokens }}</span>
                  <span v-if="entry.data.temperature != null" class="mr-2">temp={{ entry.data.temperature }}</span>
                  <span v-if="entry.data.thinking_effort">effort={{ entry.data.thinking_effort }}</span>
                </div>
              </div>
              <div v-if="entry.data.class && entry.data.class.length" class="kv">
                <div class="k">Class</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="c in entry.data.class" :key="c" class="chip">{{ c }}</span>
                </div>
              </div>
              <div v-if="entry.data.traits && entry.data.traits.length" class="kv">
                <div class="k">Traits</div>
                <div class="v">
                  <div v-for="t in entry.data.traits" :key="t.id || t" class="text-[11px] font-mono">{{ t.id || t }}</div>
                </div>
              </div>
              <div v-if="entry.data.tools && entry.data.tools.length" class="kv">
                <div class="k">Tools</div>
                <div class="v">
                  <div v-for="t in entry.data.tools" :key="t" class="text-[11px] font-mono">{{ t }}</div>
                </div>
              </div>
              <div v-if="entry.data.delegates && entry.data.delegates.length" class="kv">
                <div class="k">Delegates</div>
                <div class="v">
                  <div v-for="d in entry.data.delegates" :key="d.id || d.name" class="text-[11px] font-mono">
                    <span class="font-semibold">{{ d.name }}</span>
                    <span v-if="d.id" class="opacity-70"> → {{ d.id }}</span>
                  </div>
                </div>
              </div>
              <div v-if="entry.data.memory && entry.data.memory.contract" class="kv">
                <div class="k">Memory</div>
                <div class="v font-mono text-[11px]">{{ entry.data.memory.contract }}</div>
              </div>
              <div v-if="entry.data.start_token" class="kv">
                <div class="k">Start token</div>
                <div class="v font-mono text-[10px]">{{ entry.data.start_token }}</div>
              </div>
              <div v-if="entry.data.prompt || entry.data.system_prompt">
                <div class="k mb-1">Prompt</div>
                <pre class="prompt-block">{{ entry.data.prompt || entry.data.system_prompt }}</pre>
              </div>
            </div>
          </template>
        </EntryDetailPanel>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Stats strip */
.stats-row {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 16px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: color-mix(in srgb, var(--p-surface-50) 70%, transparent);
  flex-wrap: wrap;
}
.stat-pill {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 3px 9px;
  border-radius: 4px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  font-size: 11px;
  color: var(--p-text-color);
}
.stat-pill .stat-num { font-weight: 700; font-variant-numeric: tabular-nums; }
.stat-pill .stat-lbl { font-size: 10px; color: var(--p-text-muted-color); }
.stat-pill--accent  { color: var(--p-accent-500); }
.stat-pill--info    { color: var(--p-info-500); }
.stat-pill--warn    { color: var(--p-warn-500); }
.stat-pill--success { color: var(--p-success-500); }

.class-filter {
  display: flex; gap: 4px; flex-wrap: wrap;
  margin-left: auto;
}
.class-chip {
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px; font-weight: 500;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.class-chip:hover { color: var(--p-text-color); border-color: var(--p-surface-300); }
.class-chip--active {
  background: color-mix(in srgb, var(--cc, var(--p-primary-color)) 15%, transparent);
  color: var(--cc, var(--p-primary-color));
  border-color: color-mix(in srgb, var(--cc, var(--p-primary-color)) 40%, transparent);
}

.ns-head {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--p-text-muted-color);
  margin-bottom: 6px;
  padding: 0 4px;
}
.ns-count {
  padding: 0 5px;
  border-radius: 8px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
}

.agent-list {
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  overflow: hidden;
  background: var(--p-surface-50);
}
.agent-row {
  display: flex; align-items: center; gap: 10px;
  padding: 4px 10px;
  border-bottom: 1px solid var(--p-content-border-color);
  cursor: pointer;
  font-size: 11px;
  transition: background 0.08s;
  min-width: 0;
}
.agent-row:last-child { border-bottom: none; }
.agent-row:hover { background: var(--p-surface-100); }
.agent-row--selected {
  background: color-mix(in srgb, var(--p-primary-color) 10%, transparent);
  box-shadow: inset 2px 0 0 var(--p-primary-color);
}

.agent-icon {
  width: 22px; height: 22px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 4px; flex-shrink: 0;
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  color: var(--p-primary-color);
}

.agent-main {
  display: flex; align-items: center; gap: 6px;
  min-width: 0;
  flex: 1 1 auto;
}
.agent-title { font-size: 12px; font-weight: 600; color: var(--p-text-color); flex-shrink: 0; }
.agent-id {
  font-size: 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  color: var(--p-text-muted-color);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  min-width: 0;
}

.agent-spec {
  display: flex; align-items: center; gap: 4px;
  flex-shrink: 0;
}

.class-badge {
  display: inline-flex; align-items: center;
  font-size: 9px; font-weight: 700;
  padding: 0 5px;
  border-radius: 3px;
  text-transform: uppercase; letter-spacing: 0.04em;
  background: color-mix(in srgb, var(--cc, var(--p-text-muted-color)) 14%, transparent);
  color: var(--cc, var(--p-text-muted-color));
  border: 1px solid color-mix(in srgb, var(--cc, var(--p-text-muted-color)) 30%, transparent);
  flex-shrink: 0;
}
.class-badge.more {
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  border-color: var(--p-content-border-color);
}

/* Spec pills */
.spec-pill {
  display: inline-flex; align-items: center; gap: 2px;
  padding: 0 5px;
  height: 17px;
  border-radius: 3px;
  font-size: 9px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-muted-color);
  font-variant-numeric: tabular-nums;
}
.spec-pill .spec-val { color: var(--p-text-color); font-weight: 600; }
.spec-pill .spec-lbl { color: var(--p-text-muted-color); }
.spec-model    { color: var(--p-primary-color); }
.spec-model .spec-val { color: var(--p-primary-color); }
.spec-think    { color: var(--p-warn-500); border-color: color-mix(in srgb, var(--p-warn-500) 30%, transparent); }
.spec-info     { color: var(--p-info-500); border-color: color-mix(in srgb, var(--p-info-500) 25%, transparent); }
.spec-info .spec-val { color: var(--p-info-500); }
.spec-warn     { color: var(--p-warn-500); border-color: color-mix(in srgb, var(--p-warn-500) 25%, transparent); }
.spec-warn .spec-val { color: var(--p-warn-500); }
.spec-accent   { color: var(--p-accent-500); border-color: color-mix(in srgb, var(--p-accent-500) 25%, transparent); }
.spec-accent .spec-val { color: var(--p-accent-500); }
.spec-success  { color: var(--p-success-500); border-color: color-mix(in srgb, var(--p-success-500) 25%, transparent); }

.chat-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 22px; height: 22px;
  border-radius: 4px;
  background: var(--p-primary-color); color: var(--p-primary-contrast-color);
  border: none; cursor: pointer;
  flex-shrink: 0;
}
.chat-btn:hover { opacity: 0.9; }

.sort-select {
  height: 26px;
  padding: 0 22px 0 10px;
  font-size: 11px;
  line-height: 1.4;
  border-radius: 4px;
  background-color: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  cursor: pointer;
  appearance: none;
  -webkit-appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='4,6 8,10 12,6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 6px center;
  background-size: 12px 12px;
}
.sort-select:focus { border-color: var(--p-primary-color); }
.detail-pane {
  width: 420px;
  border-left: 1px solid var(--p-content-border-color);
}
.kv { display: grid; grid-template-columns: 100px 1fr; gap: 12px; font-size: 11px; }
.k { color: var(--p-text-muted-color); font-size: 11px; }
.v { color: var(--p-text-color); word-break: break-all; }
.chip {
  display: inline-block;
  background: var(--p-surface-200); color: var(--p-text-color);
  font-size: 9px; padding: 1px 6px; border-radius: 3px;
}
.prompt-block {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  background: var(--p-surface-50);
  color: var(--p-text-color);
  padding: 8px 10px; border-radius: 4px;
  border: 1px solid var(--p-content-border-color);
  white-space: pre-wrap; word-break: break-word;
  max-height: 280px; overflow-y: auto;
}
</style>
