<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import Badge from 'primevue/badge'
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
const phaseFilter = ref<'' | 'build' | 'prompt' | 'step'>('')
const selectedId = ref<string | null>(null)

function toolsCount(e: RegistryEntry): number {
  const tools = e.data?.tools
  return Array.isArray(tools) ? tools.length : 0
}

function promptText(e: RegistryEntry): string {
  return e.data?.prompt || e.data?.system_prompt || ''
}

function contextKeys(e: RegistryEntry): string[] {
  const ctx = e.data?.context
  if (!ctx || typeof ctx !== 'object' || Array.isArray(ctx)) return []
  return Object.keys(ctx)
}

function classes(e: RegistryEntry): string[] {
  const cls = e.data?.class
  if (!Array.isArray(cls)) return []
  return cls
}

function dependsOn(e: RegistryEntry): string[] {
  const d = e.meta?.depends_on
  return Array.isArray(d) ? d : []
}

interface Phases { build: boolean; prompt: boolean; step: boolean }
function phases(e: RegistryEntry): Phases {
  const d = e.data || {}
  return {
    build: !!d.build_func_id,
    prompt: !!d.prompt_func_id || !!(d.prompt || d.system_prompt),
    step: !!d.step_func_id,
  }
}

function phaseList(e: RegistryEntry): string[] {
  const p = phases(e)
  const out: string[] = []
  if (p.build) out.push('build')
  if (p.prompt) out.push('prompt')
  if (p.step) out.push('step')
  return out
}

const PHASE_COLOR: Record<string, string> = {
  build: 'var(--p-info-500)',
  prompt: 'var(--p-warn-500)',
  step: 'var(--p-success-500)',
}
const PHASE_ICON: Record<string, string> = {
  build: 'tabler:hammer',
  prompt: 'tabler:message',
  step: 'tabler:player-track-next',
}

const filtered = computed(() => {
  let list = entries.value
  if (phaseFilter.value) {
    list = list.filter(e => phaseList(e).includes(phaseFilter.value))
  }
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(e => {
      const fields = [e.meta?.title, e.id, e.meta?.comment, e.data?.prompt, e.data?.system_prompt]
        .filter(Boolean).map(String)
      const tools = (e.data?.tools || []).join(' ')
      return fields.some(f => f.toLowerCase().includes(q)) || tools.toLowerCase().includes(q)
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
  const totalTools = list.reduce((s, e) => s + toolsCount(e), 0)
  const withPrompt = list.filter(e => promptText(e)).length
  const withBuild = list.filter(e => phases(e).build).length
  const withStep = list.filter(e => phases(e).step).length
  return { total: list.length, totalTools, withPrompt, withBuild, withStep }
})

function selectEntry(id: string) {
  selectedId.value = selectedId.value === id ? null : id
}

async function load() {
  loading.value = true
  try {
    const res = await listEntries(api, { metaType: 'agent.trait', limit: 500 })
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
      icon="tabler:sparkles"
      title="Traits"
      :count="filtered.length === entries.length ? entries.length : `${filtered.length} / ${entries.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search traits, tools…" class="search-input" />
      </div>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="namespace">By namespace</option>
        <option value="name">By name</option>
      </select>
    </PageHeader>

    <!-- Stats strip -->
    <div v-if="!loading && entries.length" class="stats-row">
      <div class="stat-pill">
        <span class="stat-num">{{ stats.total }}</span>
        <span class="stat-lbl">traits</span>
      </div>
      <div class="stat-pill stat-pill--warn">
        <Icon icon="tabler:tool" class="w-3 h-3" />
        <span class="stat-num">{{ stats.totalTools }}</span>
        <span class="stat-lbl">tool refs</span>
      </div>
      <div class="stat-pill stat-pill--accent">
        <Icon icon="tabler:message" class="w-3 h-3" />
        <span class="stat-num">{{ stats.withPrompt }}</span>
        <span class="stat-lbl">with prompt</span>
      </div>
      <div class="stat-pill stat-pill--info">
        <Icon icon="tabler:hammer" class="w-3 h-3" />
        <span class="stat-num">{{ stats.withBuild }}</span>
        <span class="stat-lbl">build hook</span>
      </div>
      <div class="stat-pill stat-pill--success">
        <Icon icon="tabler:player-track-next" class="w-3 h-3" />
        <span class="stat-num">{{ stats.withStep }}</span>
        <span class="stat-lbl">step hook</span>
      </div>

      <div class="phase-filter">
        <button class="phase-chip" :class="{ 'phase-chip--active': !phaseFilter }" @click="phaseFilter = ''">all phases</button>
        <button
          v-for="p in (['build','prompt','step'] as const)" :key="p"
          class="phase-chip"
          :class="{ 'phase-chip--active': phaseFilter === p }"
          :style="{ '--pc': PHASE_COLOR[p] }"
          @click="phaseFilter = phaseFilter === p ? '' : p"
        >
          <Icon :icon="PHASE_ICON[p]" class="w-3 h-3" />
          {{ p }}
        </button>
      </div>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <div class="flex-1 overflow-y-auto p-4 min-w-0">
        <div v-if="!loading && entries.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:sparkles" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
            <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No traits found</p>
          </div>
        </div>

        <template v-else>
          <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
            <div v-if="ns" class="ns-head">
              <Icon icon="tabler:folder" class="w-3 h-3" />
              <span>{{ ns }}</span>
              <Badge severity="secondary" :value="items.length" />
            </div>
            <div class="grid grid-cols-1 gap-2">
              <div
                v-for="entry in items" :key="entry.id"
                class="trait-card"
                :class="{ 'trait-card--selected': selectedId === entry.id }"
                @click="selectEntry(entry.id)"
              >
                <div class="flex items-start gap-3">
                  <div class="trait-icon">
                    <Icon icon="tabler:sparkles" class="w-5 h-5" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <!-- Title row -->
                    <div class="flex items-baseline gap-2 flex-wrap">
                      <span class="trait-title">{{ entry.meta?.title || entryName(entry.id) }}</span>
                      <span v-for="ph in phaseList(entry)" :key="ph"
                        class="phase-badge"
                        :style="{ '--pc': PHASE_COLOR[ph] }"
                        :title="`${ph} phase`"
                      >
                        <Icon :icon="PHASE_ICON[ph]" class="w-2.5 h-2.5" />
                        {{ ph }}
                      </span>
                      <span v-for="c in classes(entry)" :key="c" class="class-badge">{{ c }}</span>
                      <span class="trait-id">{{ entry.id }}</span>
                    </div>

                    <!-- Comment -->
                    <div v-if="entry.meta?.comment" class="trait-comment">{{ entry.meta.comment }}</div>

                    <!-- Meta row -->
                    <div class="meta-row">
                      <span v-if="toolsCount(entry)" class="meta-pill meta-pill--warn" title="Bound tools">
                        <Icon icon="tabler:tool" class="w-3 h-3" />
                        <span class="meta-val">{{ toolsCount(entry) }}</span>
                        <span class="meta-lbl">tools</span>
                      </span>
                      <span v-if="contextKeys(entry).length" class="meta-pill meta-pill--info" title="Context defaults">
                        <Icon icon="tabler:variable" class="w-3 h-3" />
                        <span class="meta-val">{{ contextKeys(entry).length }}</span>
                        <span class="meta-lbl">ctx keys</span>
                      </span>
                      <span v-if="dependsOn(entry).length" class="meta-pill" title="Dependencies">
                        <Icon icon="tabler:link" class="w-3 h-3" />
                        <span class="meta-val">{{ dependsOn(entry).length }}</span>
                        <span class="meta-lbl">deps</span>
                      </span>
                    </div>

                    <!-- Prompt preview -->
                    <pre v-if="promptText(entry)" class="prompt-preview">{{ promptText(entry).slice(0, 200) }}<template v-if="promptText(entry).length > 200">…</template></pre>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>

      <div v-if="selectedId" class="shrink-0 detail-pane">
        <EntryDetailPanel
          :entry-id="selectedId"
          icon="tabler:sparkles"
          @close="selectedId = null"
        >
          <template #overview="{ entry }">
            <div v-if="entry?.data" class="space-y-3">
              <div v-if="phaseList(entry).length" class="kv">
                <div class="k">Phases</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="ph in phaseList(entry)" :key="ph" class="chip" :style="{ background: 'color-mix(in srgb, ' + PHASE_COLOR[ph] + ' 18%, transparent)', color: PHASE_COLOR[ph] }">{{ ph }}</span>
                </div>
              </div>
              <div v-if="entry.data.build_func_id" class="kv">
                <div class="k">Build fn</div>
                <div class="v font-mono text-[11px]">{{ entry.data.build_func_id }}</div>
              </div>
              <div v-if="entry.data.prompt_func_id" class="kv">
                <div class="k">Prompt fn</div>
                <div class="v font-mono text-[11px]">{{ entry.data.prompt_func_id }}</div>
              </div>
              <div v-if="entry.data.step_func_id" class="kv">
                <div class="k">Step fn</div>
                <div class="v font-mono text-[11px]">{{ entry.data.step_func_id }}</div>
              </div>
              <div v-if="classes(entry).length" class="kv">
                <div class="k">Classes</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="c in classes(entry)" :key="c" class="chip">{{ c }}</span>
                </div>
              </div>
              <div v-if="entry.data.tools && entry.data.tools.length" class="kv">
                <div class="k">Tools ({{ entry.data.tools.length }})</div>
                <div class="v">
                  <div v-for="t in entry.data.tools" :key="t" class="text-[11px] font-mono">{{ t }}</div>
                </div>
              </div>
              <div v-if="contextKeys(entry).length" class="kv">
                <div class="k">Context</div>
                <div class="v">
                  <div v-for="k in contextKeys(entry)" :key="k" class="text-[11px] font-mono">
                    {{ k }} = {{ JSON.stringify(entry.data.context[k]) }}
                  </div>
                </div>
              </div>
              <div v-if="dependsOn(entry).length" class="kv">
                <div class="k">Dependencies</div>
                <div class="v">
                  <div v-for="d in dependsOn(entry)" :key="d" class="text-[11px] font-mono">{{ d }}</div>
                </div>
              </div>
              <div v-if="entry.data.prompt || entry.data.system_prompt">
                <div class="k mb-1">{{ entry.data.system_prompt ? 'System prompt' : 'Prompt' }}</div>
                <pre class="prompt-block">{{ entry.data.system_prompt || entry.data.prompt }}</pre>
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
}
.stat-pill .stat-num { font-weight: 700; font-variant-numeric: tabular-nums; color: var(--p-text-color); }
.stat-pill .stat-lbl { font-size: 10px; color: var(--p-text-muted-color); }
.stat-pill--warn    { color: var(--p-warn-500); }
.stat-pill--accent  { color: var(--p-accent-500); }
.stat-pill--info    { color: var(--p-info-500); }
.stat-pill--success { color: var(--p-success-500); }

.phase-filter {
  display: flex; gap: 4px; flex-wrap: wrap;
  margin-left: auto;
}
.phase-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px; font-weight: 500;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.phase-chip:hover { color: var(--p-text-color); border-color: var(--p-surface-300); }
.phase-chip--active {
  background: color-mix(in srgb, var(--pc, var(--p-primary-color)) 14%, transparent);
  color: var(--pc, var(--p-primary-color));
  border-color: color-mix(in srgb, var(--pc, var(--p-primary-color)) 40%, transparent);
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

.trait-card {
  padding: 12px;
  border-radius: 6px;
  border: 1px solid var(--p-content-border-color);
  background: var(--p-surface-50);
  cursor: pointer;
  transition: border-color 0.1s, background 0.1s, box-shadow 0.1s;
}
.trait-card:hover { border-color: var(--p-surface-300); background: var(--p-surface-100); }
.trait-card--selected {
  border-color: var(--p-warn-500);
  background: color-mix(in srgb, var(--p-warn-500) 7%, transparent);
  box-shadow: inset 2px 0 0 var(--p-warn-500);
}
.trait-icon {
  width: 36px; height: 36px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 8px; flex-shrink: 0;
  background: color-mix(in srgb, var(--p-warn-500) 12%, transparent);
  color: var(--p-warn-500);
  border: 1px solid color-mix(in srgb, var(--p-warn-500) 25%, transparent);
}
.trait-title { font-size: 13px; font-weight: 600; color: var(--p-text-color); }
.trait-id {
  font-size: 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  color: var(--p-text-muted-color);
  margin-left: auto;
}
.trait-comment {
  font-size: 11px; line-height: 1.5;
  color: var(--p-text-muted-color);
  margin-top: 4px;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden;
}

.phase-badge {
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 9px; font-weight: 700;
  padding: 1px 5px;
  border-radius: 3px;
  text-transform: uppercase; letter-spacing: 0.04em;
  background: color-mix(in srgb, var(--pc) 14%, transparent);
  color: var(--pc);
  border: 1px solid color-mix(in srgb, var(--pc) 30%, transparent);
}
.class-badge {
  display: inline-flex; align-items: center;
  font-size: 9px; font-weight: 600;
  padding: 1px 5px;
  border-radius: 3px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  text-transform: uppercase; letter-spacing: 0.04em;
}

.meta-row {
  display: flex; flex-wrap: wrap; gap: 5px;
  margin-top: 8px;
}
.meta-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-muted-color);
  font-variant-numeric: tabular-nums;
}
.meta-pill .meta-val { color: var(--p-text-color); font-weight: 600; }
.meta-pill .meta-lbl { color: var(--p-text-muted-color); }
.meta-pill--warn { color: var(--p-warn-500); border-color: color-mix(in srgb, var(--p-warn-500) 25%, transparent); }
.meta-pill--warn .meta-val { color: var(--p-warn-500); }
.meta-pill--info { color: var(--p-info-500); border-color: color-mix(in srgb, var(--p-info-500) 25%, transparent); }
.meta-pill--info .meta-val { color: var(--p-info-500); }

.prompt-preview {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 10px; line-height: 1.5;
  color: var(--p-text-muted-color);
  background: var(--p-surface-100);
  border-left: 2px solid color-mix(in srgb, var(--p-warn-500) 35%, transparent);
  padding: 6px 9px;
  margin-top: 8px;
  border-radius: 0 3px 3px 0;
  white-space: pre-wrap; word-break: break-word;
  max-height: 4.5em;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

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
  max-height: 320px; overflow-y: auto;
}
</style>
