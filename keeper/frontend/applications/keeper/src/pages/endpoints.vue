<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'
import Badge from 'primevue/badge'
import { useApi } from '../composables/useWippy'
import { listEntries, getEntry, type RegistryEntry } from '../api/registry'
import EntryDetailPanel from '../components/shared/EntryDetailPanel.vue'
import PageHeader from '../components/shared/PageHeader.vue'

const api = useApi()

interface Endpoint {
  id: string
  method: string
  path: string
  func: string
  router: string
  comment: string
  middleware: string[]
  options: Record<string, any>
  depends_on: string[]
}

const endpoints = ref<Endpoint[]>([])
const loading = ref(true)
const search = ref('')
const sortBy = ref<'namespace' | 'path' | 'method' | 'router'>('namespace')
const methodFilter = ref<string>('')
const routerFilter = ref<string>('')
const selectedId = ref<string | null>(null)

const methodColors: Record<string, string> = {
  GET:    'var(--p-success-500)',
  POST:   'var(--p-info-500)',
  PUT:    'var(--p-warn-500)',
  DELETE: 'var(--p-danger-500)',
  PATCH:  'var(--p-accent-500)',
  HEAD:   'var(--p-text-muted-color)',
  OPTIONS:'var(--p-text-muted-color)',
}

const filtered = computed(() => {
  let list = endpoints.value
  if (methodFilter.value) list = list.filter(e => e.method === methodFilter.value)
  if (routerFilter.value) list = list.filter(e => e.router === routerFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(e =>
      e.path.toLowerCase().includes(q) ||
      e.id.toLowerCase().includes(q) ||
      e.method.toLowerCase().includes(q) ||
      e.func.toLowerCase().includes(q) ||
      e.router.toLowerCase().includes(q) ||
      e.comment.toLowerCase().includes(q),
    )
  }
  return [...list].sort((a, b) => {
    if (sortBy.value === 'path') return a.path.localeCompare(b.path)
    if (sortBy.value === 'method') return a.method.localeCompare(b.method) || a.path.localeCompare(b.path)
    if (sortBy.value === 'router') return (a.router || '').localeCompare(b.router || '') || a.path.localeCompare(b.path)
    return a.id.localeCompare(b.id)
  })
})

const grouped = computed(() => {
  if (sortBy.value === 'path') return [['', filtered.value] as [string, Endpoint[]]]
  const groups: Record<string, Endpoint[]> = {}
  for (const e of filtered.value) {
    let key: string
    if (sortBy.value === 'method') key = e.method
    else if (sortBy.value === 'router') key = e.router || '(no router)'
    else key = e.id.split(':')[0] || 'other'
    if (!groups[key]) groups[key] = []
    groups[key].push(e)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

const distinctMethods = computed(() => {
  const set = new Set<string>()
  for (const e of endpoints.value) set.add(e.method)
  return Array.from(set).sort()
})

const distinctRouters = computed(() => {
  const set = new Set<string>()
  for (const e of endpoints.value) if (e.router) set.add(e.router)
  return Array.from(set).sort()
})

const stats = computed(() => {
  const list = endpoints.value
  const byMethod: Record<string, number> = {}
  for (const e of list) byMethod[e.method] = (byMethod[e.method] || 0) + 1
  const withMiddleware = list.filter(e => e.middleware.length).length
  const withOptions = list.filter(e => Object.keys(e.options).length).length
  return {
    total: list.length,
    routers: distinctRouters.value.length,
    byMethod,
    withMiddleware,
    withOptions,
  }
})

function methodColor(method: string): string {
  return methodColors[(method || '').toUpperCase()] || 'var(--p-text-muted-color)'
}

function selectEndpoint(id: string) {
  selectedId.value = selectedId.value === id ? null : id
}

async function load() {
  loading.value = true
  try {
    const res = await listEntries(api, { kind: 'http.endpoint', limit: 500 })
    const entries = res.entries || []
    const details = await Promise.allSettled(entries.map(e => getEntry(api, e.id)))
    endpoints.value = entries.map((e, i) => {
      const d = details[i].status === 'fulfilled' ? (details[i] as PromiseFulfilledResult<any>).value : null
      const entry = d?.entry || e
      const data = entry.data || {}
      const meta = entry.meta || {}
      return {
        id: e.id,
        method: (data.method || 'GET').toUpperCase(),
        path: data.path || '',
        func: data.func || '',
        router: meta.router || '',
        comment: meta.comment || '',
        middleware: Array.isArray(data.middleware) ? data.middleware : [],
        options: (data.options && typeof data.options === 'object') ? data.options : {},
        depends_on: Array.isArray(meta.depends_on) ? meta.depends_on : [],
      }
    })
  } catch {
    endpoints.value = []
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader
      icon="tabler:api"
      title="Endpoints"
      :count="filtered.length === endpoints.length ? endpoints.length : `${filtered.length} / ${endpoints.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search path, handler, comment…" class="search-input" />
      </div>
      <select v-model="routerFilter" class="sort-select" title="Filter by router">
        <option value="">All routers</option>
        <option v-for="r in distinctRouters" :key="r" :value="r">{{ r }}</option>
      </select>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="namespace">By namespace</option>
        <option value="path">By path</option>
        <option value="method">By method</option>
        <option value="router">By router</option>
      </select>
    </PageHeader>

    <!-- Stats / method filters -->
    <div v-if="!loading && endpoints.length" class="stats-row">
      <Tag class="k-tag-metric">
        <span class="k-tag-num">{{ stats.total }}</span>
        <span class="k-tag-lbl">endpoints</span>
      </Tag>
      <Tag severity="info" class="k-tag-metric">
        <Icon icon="tabler:route" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.routers }}</span>
        <span class="k-tag-lbl">routers</span>
      </Tag>
      <Tag v-if="stats.withMiddleware" severity="warn" class="k-tag-metric">
        <Icon icon="tabler:filter" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withMiddleware }}</span>
        <span class="k-tag-lbl">middleware</span>
      </Tag>
      <Tag v-if="stats.withOptions" class="k-tag-metric k-tag-tone-accent">
        <Icon icon="tabler:settings" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.withOptions }}</span>
        <span class="k-tag-lbl">options</span>
      </Tag>

      <div class="method-filter">
        <button class="m-chip" :class="{ 'm-chip--active': !methodFilter }" @click="methodFilter = ''">all</button>
        <button
          v-for="m in distinctMethods" :key="m"
          class="m-chip"
          :class="{ 'm-chip--active': methodFilter === m }"
          :style="{ '--mc': methodColor(m) }"
          @click="methodFilter = methodFilter === m ? '' : m"
        >
          {{ m }} <span class="m-count">{{ stats.byMethod[m] || 0 }}</span>
        </button>
      </div>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <div class="flex-1 overflow-y-auto p-4 min-w-0">
        <div v-if="!loading && endpoints.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:api" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
            <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No endpoints found</p>
          </div>
        </div>

        <template v-else>
          <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
            <div v-if="ns" class="ns-head">
              <Icon icon="tabler:folder" class="w-3 h-3" />
              <span>{{ ns }}</span>
              <Badge severity="secondary" :value="items.length" />
            </div>
            <div class="ep-list">
              <div
                v-for="ep in items" :key="ep.id"
                class="ep-row"
                :class="{ 'ep-row--selected': selectedId === ep.id }"
                :style="{ '--mc': methodColor(ep.method) }"
                :title="ep.comment || ep.id"
                @click="selectEndpoint(ep.id)"
              >
                <span class="method-badge" :style="{ background: 'color-mix(in srgb, ' + methodColor(ep.method) + ' 18%, transparent)', color: methodColor(ep.method), borderColor: 'color-mix(in srgb, ' + methodColor(ep.method) + ' 35%, transparent)' }">
                  {{ ep.method }}
                </span>
                <span class="ep-path">{{ ep.path || '-' }}</span>
                <span v-if="ep.func" class="ep-func" :title="`Handler: ${ep.func}`">
                  <Icon icon="tabler:bolt" class="w-3 h-3 shrink-0" />
                  <span class="font-mono truncate">{{ ep.func }}</span>
                </span>
                <span v-if="ep.middleware.length" class="ep-mw" :title="ep.middleware.join(', ')">
                  <Icon icon="tabler:filter" class="w-3 h-3" />
                  <span>{{ ep.middleware.length }}</span>
                </span>
                <span v-if="Object.keys(ep.options).length" class="ep-opts" :title="Object.entries(ep.options).map(([k,v]) => k + '=' + (typeof v === 'string' ? v : JSON.stringify(v))).join(' ')">
                  <Icon icon="tabler:settings" class="w-3 h-3" />
                  <span>{{ Object.keys(ep.options).length }}</span>
                </span>
                <span v-if="ep.router" class="ep-router" :title="`Router: ${ep.router}`">{{ ep.router }}</span>
              </div>
            </div>
          </div>
        </template>
      </div>

      <div v-if="selectedId" class="shrink-0 detail-pane">
        <EntryDetailPanel
          :entry-id="selectedId"
          icon="tabler:api"
          @close="selectedId = null"
        >
          <template #overview="{ entry }">
            <div v-if="entry?.data" class="space-y-3">
              <div class="kv">
                <div class="k">Method</div>
                <div class="v">
                  <span class="method-badge" :style="{ background: 'color-mix(in srgb, ' + methodColor((entry.data.method || 'GET').toUpperCase()) + ' 18%, transparent)', color: methodColor((entry.data.method || 'GET').toUpperCase()) }">
                    {{ (entry.data.method || 'GET').toUpperCase() }}
                  </span>
                </div>
              </div>
              <div v-if="entry.data.path" class="kv">
                <div class="k">Path</div>
                <div class="v font-mono">{{ entry.data.path }}</div>
              </div>
              <div v-if="entry.data.func" class="kv">
                <div class="k">Handler</div>
                <div class="v font-mono text-[11px]">{{ entry.data.func }}</div>
              </div>
              <div v-if="entry.meta?.router" class="kv">
                <div class="k">Router</div>
                <div class="v font-mono text-[11px]">{{ entry.meta.router }}</div>
              </div>
              <div v-if="entry.meta?.comment" class="kv">
                <div class="k">Comment</div>
                <div class="v leading-relaxed text-[11px]" style="color: var(--p-text-muted-color)">{{ entry.meta.comment }}</div>
              </div>
              <div v-if="entry.data.middleware && entry.data.middleware.length" class="kv">
                <div class="k">Middleware ({{ entry.data.middleware.length }})</div>
                <div class="v">
                  <div v-for="m in entry.data.middleware" :key="m" class="text-[11px] font-mono">{{ m }}</div>
                </div>
              </div>
              <div v-if="entry.data.options && Object.keys(entry.data.options).length" class="kv">
                <div class="k">Options</div>
                <div class="v">
                  <div v-for="(val, key) in entry.data.options" :key="key" class="text-[10px] font-mono">
                    {{ key }} = {{ JSON.stringify(val) }}
                  </div>
                </div>
              </div>
              <div v-if="entry.meta?.depends_on && entry.meta.depends_on.length" class="kv">
                <div class="k">Dependencies</div>
                <div class="v">
                  <div v-for="d in entry.meta.depends_on" :key="d" class="text-[11px] font-mono">{{ d }}</div>
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
.method-filter {
  display: flex; gap: 4px; flex-wrap: wrap;
  margin-left: auto;
}
.m-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px; font-weight: 700;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.m-chip:hover { color: var(--p-text-color); border-color: var(--p-surface-300); }
.m-chip--active {
  background: color-mix(in srgb, var(--mc, var(--p-primary-color)) 14%, transparent);
  color: var(--mc, var(--p-primary-color));
  border-color: color-mix(in srgb, var(--mc, var(--p-primary-color)) 40%, transparent);
}
.m-count {
  font-weight: 500; font-size: 9px;
  background: var(--p-surface-200);
  padding: 0 4px;
  border-radius: 3px;
}

.ns-head {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--p-text-muted-color);
  margin-bottom: 6px;
  padding: 0 4px;
}
.ep-list {
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  overflow: hidden;
  background: var(--p-surface-50);
}
.ep-row {
  display: flex; align-items: center; gap: 10px;
  padding: 4px 10px 4px 0;
  border-left: 3px solid var(--mc, var(--p-text-muted-color));
  border-bottom: 1px solid var(--p-content-border-color);
  cursor: pointer;
  font-size: 11px;
  min-width: 0;
  transition: background 0.08s;
}
.ep-row:last-child { border-bottom: none; }
.ep-row:hover { background: color-mix(in srgb, var(--mc) 6%, transparent); }
.ep-row--selected {
  background: color-mix(in srgb, var(--mc) 12%, transparent);
}

.method-badge {
  flex-shrink: 0;
  margin-left: 8px;
  font-size: 9px; font-weight: 800;
  padding: 2px 7px;
  border-radius: 3px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  border: 1px solid transparent;
  letter-spacing: 0.04em;
  min-width: 52px;
  text-align: center;
}

.ep-path {
  flex: 1 1 auto;
  min-width: 0;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 12px;
  color: var(--p-text-color);
  font-weight: 500;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}

.ep-func {
  display: inline-flex; align-items: center; gap: 3px;
  flex-shrink: 1;
  min-width: 0;
  max-width: 280px;
  font-size: 10px;
  color: var(--p-text-muted-color);
}
.ep-func .truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.ep-mw {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-warn-500) 12%, transparent);
  color: var(--p-warn-500);
  border: 1px solid color-mix(in srgb, var(--p-warn-500) 28%, transparent);
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
}
.ep-opts {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  background: color-mix(in srgb, var(--p-accent-500) 10%, transparent);
  color: var(--p-accent-500);
  border: 1px solid color-mix(in srgb, var(--p-accent-500) 24%, transparent);
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
}

.ep-router {
  font-size: 10px;
  color: var(--p-text-muted-color);
  flex-shrink: 0;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  opacity: 0.85;
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
</style>
