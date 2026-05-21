<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'
import { useApi } from '../composables/useWippy'
import { listEntries, getEntry, type RegistryEntry } from '../api/registry'
import { entryName } from '../utils'
import EntryDetailPanel from '../components/shared/EntryDetailPanel.vue'
import PageHeader from '../components/shared/PageHeader.vue'

const api = useApi()

const entries = ref<RegistryEntry[]>([])
const loading = ref(true)
const search = ref('')
const sortBy = ref<'namespace' | 'name'>('namespace')
const selectedId = ref<string | null>(null)

interface Param { name: string; type: string; required: boolean; description?: string }

function parseSchema(raw: any): Param[] {
  if (!raw) return []
  try {
    const schema = typeof raw === 'string' ? JSON.parse(raw) : raw
    if (!schema?.properties) return []
    const required: string[] = Array.isArray(schema.required) ? schema.required : []
    return Object.entries(schema.properties).map(([name, def]: [string, any]) => ({
      name,
      type: def.type || (def.enum ? 'enum' : 'any'),
      required: required.includes(name),
      description: def.description,
    }))
  } catch { return [] }
}

function inputParams(e: RegistryEntry): Param[] {
  return parseSchema(e.meta?.input_schema ?? e.data?.input_schema)
}
function outputParams(e: RegistryEntry): Param[] {
  return parseSchema(e.meta?.output_schema ?? e.data?.output_schema)
}
function llmAlias(e: RegistryEntry): string | undefined {
  return e.meta?.llm_alias ?? e.data?.llm_alias
}
function llmDescription(e: RegistryEntry): string | undefined {
  return e.meta?.llm_description ?? e.data?.llm_description
}

function dependsOn(e: RegistryEntry): string[] {
  const d = e.meta?.depends_on
  if (Array.isArray(d)) return d
  return []
}

const TYPE_COLOR: Record<string, string> = {
  string: 'var(--p-info-500)',
  number: 'var(--p-accent-500)',
  integer: 'var(--p-accent-500)',
  boolean: 'var(--p-warn-500)',
  array: 'var(--p-success-500)',
  object: 'var(--p-primary-color)',
  enum: 'var(--p-warn-500)',
  any: 'var(--p-text-muted-color)',
}
function typeColor(t: string): string {
  return TYPE_COLOR[t] || 'var(--p-text-muted-color)'
}

const filtered = computed(() => {
  let list = entries.value
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(e => {
      const fields = [
        e.meta?.title, e.id, e.meta?.comment,
        llmAlias(e), llmDescription(e), e.data?.handler, e.data?.method,
      ].filter(Boolean).map(String)
      const props = inputParams(e).map(p => p.name).join(' ')
      return fields.some(f => f.toLowerCase().includes(q)) || props.toLowerCase().includes(q)
    })
  }
  return [...list].sort((a, b) => {
    if (sortBy.value === 'name') return (a.meta?.title || a.id).localeCompare(b.meta?.title || b.id)
    return a.id.localeCompare(b.id)
  })
})

const grouped = computed(() => {
  if (sortBy.value !== 'namespace') return [['', filtered.value] as [string, RegistryEntry[]]]
  const groups: Record<string, RegistryEntry[]> = {}
  for (const e of filtered.value) {
    const ns = e.id.split(':')[0] || 'other'
    if (!groups[ns]) groups[ns] = []
    groups[ns].push(e)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

const stats = computed(() => {
  const list = entries.value
  const totalParams = list.reduce((s, e) => s + inputParams(e).length, 0)
  const withOutput = list.filter(e => outputParams(e).length).length
  const withAlias = list.filter(e => llmAlias(e)).length
  const totalDeps = list.reduce((s, e) => s + dependsOn(e).length, 0)
  return { total: list.length, totalParams, withOutput, withAlias, totalDeps }
})

function selectEntry(id: string) {
  selectedId.value = selectedId.value === id ? null : id
}

async function load() {
  loading.value = true
  try {
    const res = await listEntries(api, { metaType: 'tool', limit: 500 })
    const list = res.entries || []
    const details = await Promise.allSettled(list.map(e => getEntry(api, e.id)))
    entries.value = list.map((e, i) => {
      const d = details[i]
      return d.status === 'fulfilled' ? d.value.entry : e
    })
  } catch {
    entries.value = []
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader
      icon="tabler:tool"
      title="Tools"
      :count="filtered.length === entries.length ? entries.length : `${filtered.length} / ${entries.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search tools, params…" class="search-input" />
      </div>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="namespace">By namespace</option>
        <option value="name">By name</option>
      </select>
    </PageHeader>

    <!-- Stats strip -->
    <div v-if="!loading && entries.length" class="stats-row">
      <Tag class="k-tag-metric">
        <span class="k-tag-num">{{ stats.total }}</span>
        <span class="k-tag-lbl">tools</span>
      </Tag>
      <Tag severity="info" class="k-tag-metric">
        <Icon icon="tabler:variable" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.totalParams }}</span>
        <span class="k-tag-lbl">parameters</span>
      </Tag>
      <Tag class="k-tag-metric k-tag-tone-accent">
        <Icon icon="tabler:tag" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withAlias }}</span>
        <span class="k-tag-lbl">with llm_alias</span>
      </Tag>
      <Tag severity="success" class="k-tag-metric">
        <Icon icon="tabler:braces" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withOutput }}</span>
        <span class="k-tag-lbl">typed output</span>
      </Tag>
      <Tag v-if="stats.totalDeps" severity="warn" class="k-tag-metric">
        <Icon icon="tabler:link" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.totalDeps }}</span>
        <span class="k-tag-lbl">deps</span>
      </Tag>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <div class="flex-1 overflow-y-auto p-4 min-w-0">
        <div v-if="!loading && entries.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:tool" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
            <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No tools found</p>
          </div>
        </div>

        <template v-else>
          <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
            <div v-if="ns" class="ns-head">
              <Icon icon="tabler:folder" class="w-3 h-3" />
              <span>{{ ns }}</span>
              <span class="ns-count">{{ items.length }}</span>
            </div>
            <div class="tool-list">
              <div
                v-for="entry in items" :key="entry.id"
                class="tool-row"
                :class="{ 'tool-row--selected': selectedId === entry.id }"
                :title="llmDescription(entry) || entry.meta?.comment || ''"
                @click="selectEntry(entry.id)"
              >
                <div class="tool-icon">
                  <Icon icon="tabler:tool" class="w-3.5 h-3.5" />
                </div>
                <div class="tool-main">
                  <span class="tool-title">{{ entry.meta?.title || entryName(entry.id) }}</span>
                  <span v-if="llmAlias(entry)" class="alias-badge font-mono">{{ llmAlias(entry) }}</span>
                  <span v-if="llmDescription(entry)" class="tool-desc">{{ llmDescription(entry) }}</span>
                </div>
                <div class="tool-spec">
                  <span v-if="inputParams(entry).length" class="param-summary" :title="inputParams(entry).map(p => (p.required ? '*' : '') + p.name + ':' + p.type).join(', ')">
                    <Icon icon="tabler:arrow-down-right" class="w-3 h-3" />
                    <span class="ps-val">{{ inputParams(entry).length }}</span>
                    <span class="ps-types">
                      <span v-for="p in inputParams(entry).slice(0, 4)" :key="p.name"
                        class="ps-name"
                        :class="{ 'ps-name--req': p.required }"
                        :style="{ '--type-color': typeColor(p.type) }">{{ p.name }}</span>
                      <span v-if="inputParams(entry).length > 4" class="ps-more">+{{ inputParams(entry).length - 4 }}</span>
                    </span>
                  </span>
                  <span v-if="outputParams(entry).length" class="param-summary param-summary--out" :title="outputParams(entry).map(p => p.name + ':' + p.type).join(', ')">
                    <Icon icon="tabler:arrow-up-right" class="w-3 h-3" />
                    <span class="ps-val">{{ outputParams(entry).length }}</span>
                  </span>
                  <span v-if="entry.data?.pool?.size" class="meta-pill" :title="`Pool workers: ${entry.data.pool.size}`">
                    <Icon icon="tabler:cpu" class="w-3 h-3" />
                    <span class="meta-val">×{{ entry.data.pool.size }}</span>
                  </span>
                  <span v-if="dependsOn(entry).length" class="meta-pill meta-pill--warn" :title="`${dependsOn(entry).length} deps`">
                    <Icon icon="tabler:link" class="w-3 h-3" />
                    <span class="meta-val">{{ dependsOn(entry).length }}</span>
                  </span>
                </div>
                <span class="tool-id">{{ entry.id }}</span>
              </div>
            </div>
          </div>
        </template>
      </div>

      <div v-if="selectedId" class="shrink-0 detail-pane">
        <EntryDetailPanel
          :entry-id="selectedId"
          icon="tabler:tool"
          @close="selectedId = null"
        >
          <template #overview="{ entry }">
            <div v-if="entry?.data" class="space-y-3">
              <div v-if="llmAlias(entry)" class="kv">
                <div class="k">LLM alias</div>
                <div class="v font-mono">{{ llmAlias(entry) }}</div>
              </div>
              <div v-if="entry.data?.handler" class="kv">
                <div class="k">Handler</div>
                <div class="v font-mono text-[11px]">{{ entry.data.handler }}</div>
              </div>
              <div v-if="entry.data?.method" class="kv">
                <div class="k">Method</div>
                <div class="v font-mono text-[11px]">{{ entry.data.method }}</div>
              </div>
              <div v-if="entry.data?.pool?.size" class="kv">
                <div class="k">Pool size</div>
                <div class="v">{{ entry.data.pool.size }}</div>
              </div>
              <div v-if="llmDescription(entry)">
                <div class="k mb-1">Description</div>
                <div class="v leading-relaxed text-[11px]" style="color: var(--p-text-muted-color)">{{ llmDescription(entry) }}</div>
              </div>
              <div v-if="inputParams(entry).length">
                <div class="k mb-1">Input ({{ inputParams(entry).length }})</div>
                <div class="param-detail">
                  <div v-for="p in inputParams(entry)" :key="p.name" class="param-detail-row">
                    <span class="param-detail-name font-mono">{{ p.name }}<span v-if="p.required" class="param-req">*</span></span>
                    <span class="param-detail-type" :style="{ color: typeColor(p.type) }">{{ p.type }}</span>
                    <span v-if="p.description" class="param-detail-desc">{{ p.description }}</span>
                  </div>
                </div>
              </div>
              <div v-if="outputParams(entry).length">
                <div class="k mb-1">Output ({{ outputParams(entry).length }})</div>
                <div class="param-detail">
                  <div v-for="p in outputParams(entry)" :key="p.name" class="param-detail-row">
                    <span class="param-detail-name font-mono">{{ p.name }}</span>
                    <span class="param-detail-type" :style="{ color: typeColor(p.type) }">{{ p.type }}</span>
                  </div>
                </div>
              </div>
              <div v-if="dependsOn(entry).length">
                <div class="k mb-1">Dependencies</div>
                <div class="flex flex-col gap-0.5">
                  <span v-for="d in dependsOn(entry)" :key="d" class="text-[11px] font-mono">{{ d }}</span>
                </div>
              </div>
              <div v-if="entry.meta?.input_schema || entry.data?.input_schema">
                <div class="k mb-1">Input schema</div>
                <pre class="schema-block">{{ (() => { const s = entry.meta?.input_schema ?? entry.data?.input_schema; return typeof s === 'string' ? s : JSON.stringify(s, null, 2) })() }}</pre>
              </div>
            </div>
          </template>
        </EntryDetailPanel>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
.stat-pill--info    { color: var(--p-info-500); }
.stat-pill--accent  { color: var(--p-accent-500); }
.stat-pill--success { color: var(--p-success-500); }
.stat-pill--warn    { color: var(--p-warn-500); }

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

.tool-list {
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  overflow: hidden;
  background: var(--p-surface-50);
}
.tool-row {
  display: flex; align-items: center; gap: 10px;
  padding: 4px 10px;
  border-bottom: 1px solid var(--p-content-border-color);
  cursor: pointer;
  font-size: 11px;
  min-width: 0;
  transition: background 0.08s;
}
.tool-row:last-child { border-bottom: none; }
.tool-row:hover { background: var(--p-surface-100); }
.tool-row--selected {
  background: color-mix(in srgb, var(--p-info-500) 8%, transparent);
  box-shadow: inset 2px 0 0 var(--p-info-500);
}
.tool-icon {
  width: 22px; height: 22px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 4px; flex-shrink: 0;
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  color: var(--p-info-500);
}

.tool-main {
  display: flex; align-items: center; gap: 6px;
  flex: 1 1 auto;
  min-width: 0;
}
.tool-title { font-size: 12px; font-weight: 600; color: var(--p-text-color); flex-shrink: 0; }
.tool-desc {
  font-size: 10px;
  color: var(--p-text-muted-color);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  min-width: 0;
}
.tool-id {
  font-size: 9px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  color: var(--p-text-muted-color);
  flex-shrink: 0;
  opacity: 0.7;
  max-width: 280px;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.alias-badge {
  background: color-mix(in srgb, var(--p-accent-500) 14%, transparent);
  color: var(--p-accent-500);
  font-size: 9px; font-weight: 600;
  padding: 0 5px;
  border-radius: 3px;
  border: 1px solid color-mix(in srgb, var(--p-accent-500) 30%, transparent);
  flex-shrink: 0;
}

.tool-spec {
  display: flex; align-items: center; gap: 4px;
  flex-shrink: 0;
}

.param-summary {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 0 6px;
  height: 18px;
  border-radius: 3px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-info-500) 8%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-info-500) 25%, transparent);
  color: var(--p-info-500);
  font-variant-numeric: tabular-nums;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  max-width: 360px;
  overflow: hidden;
}
.param-summary--out {
  background: color-mix(in srgb, var(--p-accent-500) 8%, transparent);
  border-color: color-mix(in srgb, var(--p-accent-500) 25%, transparent);
  color: var(--p-accent-500);
}
.param-summary .ps-val { font-weight: 700; color: inherit; }
.param-summary .ps-types {
  display: inline-flex; gap: 4px;
  color: var(--p-text-muted-color);
  font-weight: 400;
  overflow: hidden;
}
.param-summary .ps-name { color: var(--p-text-color); white-space: nowrap; }
.param-summary .ps-name--req { color: var(--type-color, var(--p-text-color)); font-weight: 600; }
.param-summary .ps-more { color: var(--p-text-muted-color); font-weight: 600; }

.meta-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 0 5px;
  height: 18px;
  border-radius: 3px;
  font-size: 10px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-muted-color);
  font-variant-numeric: tabular-nums;
}
.meta-pill .meta-val { color: var(--p-text-color); font-weight: 600; }
.meta-pill--warn { color: var(--p-warn-500); border-color: color-mix(in srgb, var(--p-warn-500) 25%, transparent); }
.meta-pill--warn .meta-val { color: var(--p-warn-500); }

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
.k { color: var(--p-text-muted-color); }
.v { color: var(--p-text-color); word-break: break-word; }

.param-detail {
  display: flex; flex-direction: column; gap: 4px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  padding: 6px 8px;
  font-size: 11px;
}
.param-detail-row {
  display: grid;
  grid-template-columns: minmax(0, auto) auto 1fr;
  gap: 8px;
  align-items: baseline;
}
.param-detail-name { color: var(--p-text-color); font-weight: 500; }
.param-req { color: var(--p-danger-500); margin-left: 2px; }
.param-detail-type { font-size: 10px; font-weight: 600; }
.param-detail-desc {
  font-size: 10px;
  color: var(--p-text-muted-color);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.schema-block {
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
