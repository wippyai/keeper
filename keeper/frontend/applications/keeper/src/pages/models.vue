<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'
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
const sortBy = ref<'provider' | 'namespace' | 'name' | 'price'>('provider')
const capFilter = ref<string>('')
const selectedId = ref<string | null>(null)

function provider(e: RegistryEntry): string {
  return e.data?.provider || e.meta?.provider || e.id.split(':')[0] || 'other'
}

const PROVIDER_COLOR: Record<string, string> = {
  openai: 'var(--p-success-500)',
  anthropic: 'var(--p-warn-500)',
  google: 'var(--p-info-500)',
  bedrock: 'var(--p-accent-500)',
  azure: 'var(--p-info-500)',
}
function providerColor(p: string): string {
  return PROVIDER_COLOR[p.toLowerCase()] || 'var(--p-primary-color)'
}

const PROVIDER_ICON: Record<string, string> = {
  openai: 'simple-icons:openai',
  anthropic: 'simple-icons:anthropic',
  google: 'tabler:brand-google',
  bedrock: 'tabler:cloud',
  azure: 'tabler:brand-azure',
}
function providerIcon(p: string): string {
  return PROVIDER_ICON[p.toLowerCase()] || 'tabler:brain'
}

function capabilities(e: RegistryEntry): string[] {
  const caps: string[] = []
  const d = e.data || {}
  if (d.tool_use || d.function_calling) caps.push('tools')
  if (d.vision) caps.push('vision')
  if (d.thinking || d.extended_thinking) caps.push('thinking')
  if (d.streaming) caps.push('streaming')
  if (d.json_output) caps.push('json')
  return caps
}

const CAP_ICON: Record<string, string> = {
  tools: 'tabler:tool',
  vision: 'tabler:eye',
  thinking: 'tabler:bulb',
  streaming: 'tabler:wave-sine',
  json: 'tabler:braces',
}

function inputPrice(e: RegistryEntry): number | null {
  const d = e.data || {}
  return Number(d.input_price ?? d.pricing?.input ?? d.pricing?.input_tokens) || null
}
function outputPrice(e: RegistryEntry): number | null {
  const d = e.data || {}
  return Number(d.output_price ?? d.pricing?.output ?? d.pricing?.output_tokens) || null
}
function cachedInputPrice(e: RegistryEntry): number | null {
  const d = e.data || {}
  return Number(d.cached_input_price ?? d.pricing?.cached_input) || null
}

function totalDailyCost(e: RegistryEntry): string | null {
  const ip = inputPrice(e); const op = outputPrice(e)
  if (!ip && !op) return null
  return ''
}

function hasPricing(e: RegistryEntry): boolean {
  return !!(inputPrice(e) || outputPrice(e))
}

function formatPrice(p?: number | null): string {
  if (p == null) return '—'
  if (p < 0.01) return p.toFixed(4)
  if (p < 1) return p.toFixed(3)
  return p.toFixed(2)
}

function formatTokens(n: any): string {
  if (!n) return ''
  const num = Number(n)
  if (num >= 1_000_000) return (num / 1_000_000).toFixed(num % 1_000_000 ? 1 : 0) + 'M'
  if (num >= 1_000) return (num / 1_000).toFixed(0) + 'K'
  return String(num)
}

function knowledgeCutoff(e: RegistryEntry): string | null {
  const d = e.data || {}
  return d.knowledge_cutoff || d.training_data_cutoff || null
}
function modelFamily(e: RegistryEntry): string | null {
  return e.data?.model_family || null
}

function priceBucket(e: RegistryEntry): 'free' | 'cheap' | 'mid' | 'premium' {
  const ip = inputPrice(e) || 0
  if (!ip) return 'free'
  if (ip < 1) return 'cheap'
  if (ip < 5) return 'mid'
  return 'premium'
}

const allCaps = computed(() => {
  const set = new Set<string>()
  for (const e of entries.value) for (const c of capabilities(e)) set.add(c)
  return Array.from(set).sort()
})

const filtered = computed(() => {
  let list = entries.value
  if (capFilter.value) list = list.filter(e => capabilities(e).includes(capFilter.value))
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(e => {
      const fields = [e.meta?.title, e.id, e.meta?.comment, e.data?.provider_model, provider(e), modelFamily(e)]
        .filter(Boolean).map(String)
      const caps = capabilities(e).join(' ')
      return fields.some(f => f.toLowerCase().includes(q)) || caps.includes(q)
    })
  }
  return [...list].sort((a, b) => {
    if (sortBy.value === 'name') return (a.meta?.title || a.id).localeCompare(b.meta?.title || b.id)
    if (sortBy.value === 'namespace') return a.id.localeCompare(b.id)
    if (sortBy.value === 'price') return (inputPrice(a) || 0) - (inputPrice(b) || 0)
    return provider(a).localeCompare(provider(b)) || (inputPrice(a) || 0) - (inputPrice(b) || 0)
  })
})

const grouped = computed(() => {
  if (sortBy.value === 'name' || sortBy.value === 'price') return [['', filtered.value] as [string, RegistryEntry[]]]
  const groups: Record<string, RegistryEntry[]> = {}
  for (const e of filtered.value) {
    const key = sortBy.value === 'namespace' ? (e.id.split(':')[0] || 'other') : provider(e)
    if (!groups[key]) groups[key] = []
    groups[key].push(e)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

const stats = computed(() => {
  const list = entries.value
  const providers = new Set(list.map(provider))
  const withTools = list.filter(e => capabilities(e).includes('tools')).length
  const withVision = list.filter(e => capabilities(e).includes('vision')).length
  const withThinking = list.filter(e => capabilities(e).includes('thinking')).length
  return {
    total: list.length,
    providers: providers.size,
    withTools, withVision, withThinking,
  }
})

function selectEntry(id: string) {
  selectedId.value = selectedId.value === id ? null : id
}

async function load() {
  loading.value = true
  try {
    const res = await listEntries(api, { metaType: 'llm.model', limit: 500 })
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
      icon="tabler:brain"
      title="Models"
      :count="filtered.length === entries.length ? entries.length : `${filtered.length} / ${entries.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search models…" class="search-input" />
      </div>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="provider">By provider</option>
        <option value="namespace">By namespace</option>
        <option value="name">By name</option>
        <option value="price">By price</option>
      </select>
    </PageHeader>

    <!-- Stats strip -->
    <div v-if="!loading && entries.length" class="stats-row">
      <Tag class="k-tag-metric">
        <span class="k-tag-num">{{ stats.total }}</span>
        <span class="k-tag-lbl">models</span>
      </Tag>
      <Tag class="k-tag-metric k-tag-tone-accent">
        <Icon icon="tabler:building" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.providers }}</span>
        <span class="k-tag-lbl">providers</span>
      </Tag>
      <Tag severity="warn" class="k-tag-metric">
        <Icon icon="tabler:tool" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withTools }}</span>
        <span class="k-tag-lbl">tools</span>
      </Tag>
      <Tag severity="info" class="k-tag-metric">
        <Icon icon="tabler:eye" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withVision }}</span>
        <span class="k-tag-lbl">vision</span>
      </Tag>
      <Tag severity="success" class="k-tag-metric">
        <Icon icon="tabler:bulb" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withThinking }}</span>
        <span class="k-tag-lbl">thinking</span>
      </Tag>

      <div class="cap-filter">
        <button class="cap-chip" :class="{ 'cap-chip--active': !capFilter }" @click="capFilter = ''">all caps</button>
        <button
          v-for="c in allCaps" :key="c"
          class="cap-chip"
          :class="{ 'cap-chip--active': capFilter === c }"
          @click="capFilter = capFilter === c ? '' : c"
        >
          <Icon :icon="CAP_ICON[c] || 'tabler:circle-dot'" class="w-3 h-3" />
          {{ c }}
        </button>
      </div>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <div class="flex-1 overflow-y-auto p-4 min-w-0">
        <div v-if="!loading && entries.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:brain" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
            <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No models found</p>
          </div>
        </div>

        <template v-else>
          <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
            <div v-if="ns" class="ns-head" :style="{ '--ns-color': providerColor(ns) }">
              <Icon :icon="providerIcon(ns)" class="w-3 h-3" />
              <span>{{ ns }}</span>
              <Badge severity="secondary" :value="items.length" />
            </div>
            <div class="grid grid-cols-1 gap-2">
              <div
                v-for="entry in items" :key="entry.id"
                class="model-card"
                :class="[`bucket--${priceBucket(entry)}`, { 'model-card--selected': selectedId === entry.id }]"
                :style="{ '--prov-color': providerColor(provider(entry)) }"
                @click="selectEntry(entry.id)"
              >
                <div class="flex items-start gap-3">
                  <div class="model-icon" :style="{ '--prov-color': providerColor(provider(entry)) }">
                    <Icon :icon="providerIcon(provider(entry))" class="w-5 h-5" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <!-- Title row -->
                    <div class="flex items-baseline gap-2 flex-wrap">
                      <span class="model-title">{{ entry.meta?.title || entryName(entry.id) }}</span>
                      <span v-if="entry.data?.provider_model" class="model-pmodel">{{ entry.data.provider_model }}</span>
                      <span v-if="modelFamily(entry)" class="family-badge">{{ modelFamily(entry) }}</span>
                    </div>

                    <!-- Capabilities + tokens row -->
                    <div class="meta-row">
                      <span v-for="cap in capabilities(entry)" :key="cap" class="cap-pill">
                        <Icon :icon="CAP_ICON[cap] || 'tabler:circle-dot'" class="w-3 h-3" />
                        {{ cap }}
                      </span>

                      <span v-if="entry.data?.max_tokens" class="meta-pill" title="Context window">
                        <Icon icon="tabler:layout" class="w-3 h-3" />
                        <span class="meta-val">{{ formatTokens(entry.data.max_tokens) }}</span>
                        <span class="meta-lbl">ctx</span>
                      </span>
                      <span v-if="entry.data?.output_tokens" class="meta-pill" title="Max output tokens">
                        <Icon icon="tabler:arrows-right" class="w-3 h-3" />
                        <span class="meta-val">{{ formatTokens(entry.data.output_tokens) }}</span>
                        <span class="meta-lbl">out</span>
                      </span>
                      <span v-if="knowledgeCutoff(entry)" class="meta-pill" title="Training cutoff">
                        <Icon icon="tabler:calendar" class="w-3 h-3" />
                        <span class="meta-val">{{ knowledgeCutoff(entry) }}</span>
                      </span>
                    </div>

                    <!-- Pricing row -->
                    <div v-if="hasPricing(entry)" class="price-row">
                      <span v-if="inputPrice(entry)" class="price-pill price-pill--in">
                        <Icon icon="tabler:arrow-down" class="w-3 h-3" />
                        <span class="price-val">${{ formatPrice(inputPrice(entry)) }}</span>
                        <span class="price-unit">/M in</span>
                      </span>
                      <span v-if="outputPrice(entry)" class="price-pill price-pill--out">
                        <Icon icon="tabler:arrow-up" class="w-3 h-3" />
                        <span class="price-val">${{ formatPrice(outputPrice(entry)) }}</span>
                        <span class="price-unit">/M out</span>
                      </span>
                      <span v-if="cachedInputPrice(entry)" class="price-pill price-pill--cache" title="Cached input">
                        <Icon icon="tabler:database" class="w-3 h-3" />
                        <span class="price-val">${{ formatPrice(cachedInputPrice(entry)) }}</span>
                        <span class="price-unit">/M cached</span>
                      </span>
                      <span class="price-bucket" :class="`bucket--${priceBucket(entry)}`">{{ priceBucket(entry) }}</span>
                    </div>
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
          icon="tabler:brain"
          @close="selectedId = null"
        >
          <template #overview="{ entry }">
            <div v-if="entry?.data" class="space-y-3">
              <div v-if="entry.data.provider" class="kv">
                <div class="k">Provider</div>
                <div class="v">{{ entry.data.provider }}</div>
              </div>
              <div v-if="entry.data.provider_model" class="kv">
                <div class="k">Provider model</div>
                <div class="v font-mono">{{ entry.data.provider_model }}</div>
              </div>
              <div v-if="entry.data.model_family" class="kv">
                <div class="k">Family</div>
                <div class="v">{{ entry.data.model_family }}</div>
              </div>
              <div v-if="capabilities(entry).length" class="kv">
                <div class="k">Capabilities</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="c in capabilities(entry)" :key="c" class="chip">{{ c }}</span>
                </div>
              </div>
              <div v-if="entry.data.max_tokens || entry.data.output_tokens" class="kv">
                <div class="k">Tokens</div>
                <div class="v">
                  <span v-if="entry.data.max_tokens" class="mr-3">ctx {{ formatTokens(entry.data.max_tokens) }}</span>
                  <span v-if="entry.data.output_tokens">out {{ formatTokens(entry.data.output_tokens) }}</span>
                </div>
              </div>
              <div v-if="hasPricing(entry)" class="kv">
                <div class="k">Pricing</div>
                <div class="v">
                  <div v-if="inputPrice(entry)">in: ${{ formatPrice(inputPrice(entry)) }}/M</div>
                  <div v-if="outputPrice(entry)">out: ${{ formatPrice(outputPrice(entry)) }}/M</div>
                  <div v-if="cachedInputPrice(entry)">cached: ${{ formatPrice(cachedInputPrice(entry)) }}/M</div>
                </div>
              </div>
              <div v-if="entry.data.knowledge_cutoff" class="kv">
                <div class="k">Knowledge cutoff</div>
                <div class="v">{{ entry.data.knowledge_cutoff }}</div>
              </div>
              <div v-if="entry.data.handlers && Object.keys(entry.data.handlers).length" class="kv">
                <div class="k">Handlers</div>
                <div class="v">
                  <div v-for="(val, key) in entry.data.handlers" :key="key" class="text-[11px] font-mono">
                    {{ key }} = {{ val }}
                  </div>
                </div>
              </div>
              <div v-if="entry.data.options && Object.keys(entry.data.options).length" class="kv">
                <div class="k">Options</div>
                <div class="v">
                  <div v-for="(val, key) in entry.data.options" :key="key" class="text-[11px] font-mono">
                    {{ key }} = {{ JSON.stringify(val) }}
                  </div>
                </div>
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
.stat-pill--accent  { color: var(--p-accent-500); }
.stat-pill--info    { color: var(--p-info-500); }
.stat-pill--warn    { color: var(--p-warn-500); }
.stat-pill--success { color: var(--p-success-500); }

.cap-filter {
  display: flex; gap: 4px; flex-wrap: wrap;
  margin-left: auto;
}
.cap-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px; font-weight: 500;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.cap-chip:hover { color: var(--p-text-color); border-color: var(--p-surface-300); }
.cap-chip--active {
  background: color-mix(in srgb, var(--p-primary-color) 14%, transparent);
  color: var(--p-primary-color);
  border-color: color-mix(in srgb, var(--p-primary-color) 35%, transparent);
}

.ns-head {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--ns-color, var(--p-text-muted-color));
  margin-bottom: 6px;
  padding: 0 4px;
}
.ns-count {
  padding: 0 5px;
  border-radius: 8px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
}

.model-card {
  position: relative;
  padding: 12px;
  border-radius: 6px;
  border: 1px solid var(--p-content-border-color);
  background: var(--p-surface-50);
  cursor: pointer;
  transition: border-color 0.1s, background 0.1s, box-shadow 0.1s;
}
.model-card:hover { border-color: var(--p-surface-300); background: var(--p-surface-100); }
.model-card--selected {
  border-color: var(--prov-color, var(--p-primary-color));
  background: color-mix(in srgb, var(--prov-color, var(--p-primary-color)) 8%, transparent);
  box-shadow: inset 2px 0 0 var(--prov-color, var(--p-primary-color));
}
.model-icon {
  width: 36px; height: 36px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 8px; flex-shrink: 0;
  background: color-mix(in srgb, var(--prov-color, var(--p-primary-color)) 12%, transparent);
  color: var(--prov-color, var(--p-primary-color));
  border: 1px solid color-mix(in srgb, var(--prov-color, var(--p-primary-color)) 25%, transparent);
}
.model-title { font-size: 13px; font-weight: 600; color: var(--p-text-color); }
.model-pmodel {
  font-size: 11px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  color: var(--p-text-muted-color);
}
.family-badge {
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
  font-size: 10px;
}
.cap-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px; font-weight: 500;
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  color: var(--p-info-500);
  border: 1px solid color-mix(in srgb, var(--p-info-500) 28%, transparent);
}
.meta-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px;
  border-radius: 3px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-muted-color);
  font-variant-numeric: tabular-nums;
}
.meta-pill .meta-val { color: var(--p-text-color); font-weight: 600; }
.meta-pill .meta-lbl { color: var(--p-text-muted-color); }

.price-row {
  display: flex; flex-wrap: wrap; gap: 5px; align-items: center;
  margin-top: 6px;
}
.price-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 7px;
  border-radius: 3px;
  font-size: 10px;
  font-variant-numeric: tabular-nums;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
}
.price-pill .price-val { font-weight: 700; color: var(--p-text-color); }
.price-pill .price-unit { color: var(--p-text-muted-color); font-size: 9px; }
.price-pill--in { color: var(--p-info-500); }
.price-pill--in .price-val { color: var(--p-info-500); }
.price-pill--out { color: var(--p-accent-500); }
.price-pill--out .price-val { color: var(--p-accent-500); }
.price-pill--cache { color: var(--p-success-500); }
.price-pill--cache .price-val { color: var(--p-success-500); }

.price-bucket {
  font-size: 9px; font-weight: 700;
  padding: 1px 6px;
  border-radius: 3px;
  text-transform: uppercase; letter-spacing: 0.04em;
  margin-left: 2px;
}
.price-bucket.bucket--free    { background: color-mix(in srgb, var(--p-text-muted-color) 14%, transparent); color: var(--p-text-muted-color); }
.price-bucket.bucket--cheap   { background: color-mix(in srgb, var(--p-success-500) 14%, transparent); color: var(--p-success-500); }
.price-bucket.bucket--mid     { background: color-mix(in srgb, var(--p-warn-500) 14%, transparent); color: var(--p-warn-500); }
.price-bucket.bucket--premium { background: color-mix(in srgb, var(--p-danger-500) 14%, transparent); color: var(--p-danger-500); }

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
.kv { display: grid; grid-template-columns: 110px 1fr; gap: 12px; font-size: 11px; }
.k { color: var(--p-text-muted-color); }
.v { color: var(--p-text-color); word-break: break-word; }
.chip {
  display: inline-block;
  background: var(--p-surface-200); color: var(--p-text-color);
  font-size: 9px; padding: 1px 6px; border-radius: 3px;
}
</style>
