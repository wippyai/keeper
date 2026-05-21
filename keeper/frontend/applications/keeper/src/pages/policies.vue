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
const sortBy = ref<'namespace' | 'name' | 'effect'>('effect')
const effectFilter = ref<'' | 'allow' | 'deny'>('')
const selectedId = ref<string | null>(null)

interface Condition { field: string; operator: string; value?: any; value_from?: string }

function policyOf(e: RegistryEntry): any {
  const d = e.data || {}
  // Two known layouts: data.policy.{...} or flat data.effect/actions/resources
  return d.policy || d
}
function effectOf(e: RegistryEntry): string {
  return policyOf(e).effect || ''
}
function asArray(v: any): string[] {
  if (Array.isArray(v)) return v.map(String)
  if (typeof v === 'string') return [v]
  return []
}
function actionsOf(e: RegistryEntry): string[]   { return asArray(policyOf(e).actions) }
function resourcesOf(e: RegistryEntry): string[] { return asArray(policyOf(e).resources) }
function groupsOf(e: RegistryEntry): string[]    { return asArray(e.data?.groups) }
function principalsOf(e: RegistryEntry): string[]{ return asArray(policyOf(e).principals) }
function subjectsOf(e: RegistryEntry): string[]  { return asArray(policyOf(e).subjects) }

function conditionsOf(e: RegistryEntry): Condition[] {
  const c = policyOf(e).conditions
  if (!c) return []
  if (Array.isArray(c)) return c
  return Object.entries(c).map(([field, def]: [string, any]) => ({
    field,
    operator: typeof def === 'object' ? Object.keys(def)[0] || 'eq' : 'eq',
    value: typeof def === 'object' ? def[Object.keys(def)[0]] : def,
  }))
}

const OPERATOR_SYMBOL: Record<string, string> = {
  eq: '=', ne: '≠', lt: '<', le: '≤', gt: '>', ge: '≥',
  in: '∈', not_in: '∉', exists: '∃', not_exists: '∄', matches: '≈',
  starts_with: '⊃', ends_with: '⊂', contains: '⊆',
}
function opSym(op: string): string { return OPERATOR_SYMBOL[op] || op }

const filtered = computed(() => {
  let list = entries.value
  if (effectFilter.value) list = list.filter(e => effectOf(e) === effectFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(e => {
      if (e.id.toLowerCase().includes(q)) return true
      if (effectOf(e).toLowerCase().includes(q)) return true
      if (e.meta?.comment && String(e.meta.comment).toLowerCase().includes(q)) return true
      const all = [...groupsOf(e), ...actionsOf(e), ...resourcesOf(e), ...principalsOf(e), ...subjectsOf(e)]
      return all.some(v => v.toLowerCase().includes(q))
    })
  }
  return [...list].sort((a, b) => {
    if (sortBy.value === 'name') return entryName(a.id).localeCompare(entryName(b.id))
    if (sortBy.value === 'effect') {
      const ea = effectOf(a) || 'z'; const eb = effectOf(b) || 'z'
      return ea.localeCompare(eb) || a.id.localeCompare(b.id)
    }
    return a.id.localeCompare(b.id)
  })
})

const grouped = computed(() => {
  if (sortBy.value === 'name') return [['', filtered.value] as [string, RegistryEntry[]]]
  const groups: Record<string, RegistryEntry[]> = {}
  for (const e of filtered.value) {
    const key = sortBy.value === 'effect'
      ? (effectOf(e) || 'unspecified')
      : (e.id.split(':')[0] || 'other')
    if (!groups[key]) groups[key] = []
    groups[key].push(e)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

const stats = computed(() => {
  const list = entries.value
  const allow = list.filter(e => effectOf(e) === 'allow').length
  const deny = list.filter(e => effectOf(e) === 'deny').length
  const conditional = list.filter(e => conditionsOf(e).length).length
  const groupSet = new Set<string>()
  for (const e of list) for (const g of groupsOf(e)) groupSet.add(g)
  return { total: list.length, allow, deny, conditional, groups: groupSet.size }
})

function selectEntry(id: string) {
  selectedId.value = selectedId.value === id ? null : id
}

async function load() {
  loading.value = true
  try {
    const res = await listEntries(api, { kind: 'security.policy', limit: 500 })
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
      icon="tabler:shield-check"
      title="Policies"
      :count="filtered.length === entries.length ? entries.length : `${filtered.length} / ${entries.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search policies, actions, groups…" class="search-input" />
      </div>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="effect">By effect</option>
        <option value="namespace">By namespace</option>
        <option value="name">By name</option>
      </select>
    </PageHeader>

    <!-- Stats / effect filters -->
    <div v-if="!loading && entries.length" class="stats-row">
      <Tag class="k-tag-metric">
        <span class="k-tag-num">{{ stats.total }}</span>
        <span class="k-tag-lbl">policies</span>
      </Tag>
      <Tag severity="success" class="k-tag-metric">
        <Icon icon="tabler:check" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.allow }}</span>
        <span class="k-tag-lbl">allow</span>
      </Tag>
      <Tag severity="danger" class="k-tag-metric">
        <Icon icon="tabler:ban" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.deny }}</span>
        <span class="k-tag-lbl">deny</span>
      </Tag>
      <Tag severity="info" class="k-tag-metric">
        <Icon icon="tabler:users" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.groups }}</span>
        <span class="k-tag-lbl">groups</span>
      </Tag>
      <Tag severity="warn" class="k-tag-metric">
        <Icon icon="tabler:filter" class="w-3 h-3" />
        <span class="k-tag-num">{{ stats.conditional }}</span>
        <span class="k-tag-lbl">conditional</span>
      </Tag>

      <div class="effect-filter">
        <button class="e-chip" :class="{ 'e-chip--active': !effectFilter }" @click="effectFilter = ''">all</button>
        <button class="e-chip e-chip--allow" :class="{ 'e-chip--active': effectFilter === 'allow' }" @click="effectFilter = effectFilter === 'allow' ? '' : 'allow'">allow</button>
        <button class="e-chip e-chip--deny" :class="{ 'e-chip--active': effectFilter === 'deny' }" @click="effectFilter = effectFilter === 'deny' ? '' : 'deny'">deny</button>
      </div>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <div class="flex-1 overflow-y-auto p-4 min-w-0">
        <div v-if="!loading && entries.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <Icon icon="tabler:shield-check" class="w-10 h-10 mx-auto" style="color: var(--p-text-muted-color); opacity: 0.3" />
            <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">No policies found</p>
          </div>
        </div>

        <template v-else>
          <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
            <div v-if="ns" class="ns-head" :class="ns === 'allow' ? 'ns-head--allow' : ns === 'deny' ? 'ns-head--deny' : ''">
              <Icon :icon="ns === 'allow' ? 'tabler:check' : ns === 'deny' ? 'tabler:ban' : 'tabler:folder'" class="w-3 h-3" />
              <span>{{ ns }}</span>
              <Badge severity="secondary" :value="items.length" />
            </div>
            <div class="grid grid-cols-1 gap-2">
              <div
                v-for="entry in items" :key="entry.id"
                class="pol-card"
                :class="[
                  effectOf(entry) === 'allow' ? 'pol-card--allow' : effectOf(entry) === 'deny' ? 'pol-card--deny' : '',
                  { 'pol-card--selected': selectedId === entry.id },
                ]"
                @click="selectEntry(entry.id)"
              >
                <div class="flex items-start gap-3">
                  <div class="pol-icon" :class="effectOf(entry) === 'allow' ? 'pol-icon--allow' : 'pol-icon--deny'">
                    <Icon :icon="effectOf(entry) === 'allow' ? 'tabler:shield-check' : effectOf(entry) === 'deny' ? 'tabler:shield-x' : 'tabler:shield'" class="w-5 h-5" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <!-- Title row -->
                    <div class="flex items-baseline gap-2 flex-wrap">
                      <span class="pol-title">{{ entry.meta?.title || entryName(entry.id) }}</span>
                      <span v-if="effectOf(entry)" class="effect-badge" :class="effectOf(entry) === 'allow' ? 'effect-allow' : 'effect-deny'">
                        {{ effectOf(entry) }}
                      </span>
                      <span class="pol-id">{{ entry.id }}</span>
                    </div>

                    <!-- Comment -->
                    <div v-if="entry.meta?.comment" class="pol-comment">{{ entry.meta.comment }}</div>

                    <!-- Rule grid: groups → actions on resources -->
                    <div class="rule-grid">
                      <!-- Groups -->
                      <div v-if="groupsOf(entry).length" class="rule-row">
                        <span class="rule-lbl">
                          <Icon icon="tabler:users" class="w-3 h-3" /> groups
                        </span>
                        <div class="rule-vals">
                          <span v-for="g in groupsOf(entry)" :key="g" class="val-pill val-pill--info">{{ g }}</span>
                        </div>
                      </div>

                      <!-- Principals/Subjects -->
                      <div v-if="principalsOf(entry).length" class="rule-row">
                        <span class="rule-lbl">
                          <Icon icon="tabler:user" class="w-3 h-3" /> principals
                        </span>
                        <div class="rule-vals">
                          <span v-for="p in principalsOf(entry)" :key="p" class="val-pill val-pill--info">{{ p }}</span>
                        </div>
                      </div>
                      <div v-if="subjectsOf(entry).length" class="rule-row">
                        <span class="rule-lbl">
                          <Icon icon="tabler:user-shield" class="w-3 h-3" /> subjects
                        </span>
                        <div class="rule-vals">
                          <span v-for="s in subjectsOf(entry)" :key="s" class="val-pill val-pill--info">{{ s }}</span>
                        </div>
                      </div>

                      <!-- Actions -->
                      <div v-if="actionsOf(entry).length" class="rule-row">
                        <span class="rule-lbl">
                          <Icon icon="tabler:bolt" class="w-3 h-3" /> actions
                        </span>
                        <div class="rule-vals">
                          <span v-for="a in actionsOf(entry)" :key="a" class="val-pill val-pill--accent">{{ a }}</span>
                        </div>
                      </div>

                      <!-- Resources -->
                      <div v-if="resourcesOf(entry).length" class="rule-row">
                        <span class="rule-lbl">
                          <Icon icon="tabler:folder" class="w-3 h-3" /> resources
                        </span>
                        <div class="rule-vals">
                          <span v-for="r in resourcesOf(entry)" :key="r" class="val-pill val-pill--mono">{{ r }}</span>
                        </div>
                      </div>

                      <!-- Conditions -->
                      <div v-if="conditionsOf(entry).length" class="rule-row">
                        <span class="rule-lbl">
                          <Icon icon="tabler:filter" class="w-3 h-3" /> when
                        </span>
                        <div class="rule-vals">
                          <span v-for="(c, i) in conditionsOf(entry)" :key="i" class="cond-pill" :title="`${c.field} ${c.operator} ${JSON.stringify(c.value ?? c.value_from)}`">
                            <span class="cond-field">{{ c.field }}</span>
                            <span class="cond-op">{{ opSym(c.operator) }}</span>
                            <span class="cond-val">{{ c.value !== undefined ? (typeof c.value === 'string' ? c.value : JSON.stringify(c.value)) : c.value_from }}</span>
                          </span>
                        </div>
                      </div>
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
          icon="tabler:shield-check"
          @close="selectedId = null"
        >
          <template #overview="{ entry }">
            <div v-if="entry?.data" class="space-y-3">
              <div class="kv">
                <div class="k">Effect</div>
                <div class="v">
                  <span v-if="effectOf(entry)" class="effect-badge" :class="effectOf(entry) === 'allow' ? 'effect-allow' : 'effect-deny'">{{ effectOf(entry) }}</span>
                  <span v-else style="color: var(--p-text-muted-color)">—</span>
                </div>
              </div>
              <div v-if="groupsOf(entry).length" class="kv">
                <div class="k">Groups</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="g in groupsOf(entry)" :key="g" class="chip">{{ g }}</span>
                </div>
              </div>
              <div v-if="principalsOf(entry).length" class="kv">
                <div class="k">Principals</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="p in principalsOf(entry)" :key="p" class="chip">{{ p }}</span>
                </div>
              </div>
              <div v-if="actionsOf(entry).length" class="kv">
                <div class="k">Actions</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="a in actionsOf(entry)" :key="a" class="chip">{{ a }}</span>
                </div>
              </div>
              <div v-if="resourcesOf(entry).length" class="kv">
                <div class="k">Resources</div>
                <div class="v flex flex-wrap gap-1">
                  <span v-for="r in resourcesOf(entry)" :key="r" class="chip font-mono">{{ r }}</span>
                </div>
              </div>
              <div v-if="conditionsOf(entry).length">
                <div class="k mb-1">Conditions ({{ conditionsOf(entry).length }})</div>
                <div class="cond-detail">
                  <div v-for="(c, i) in conditionsOf(entry)" :key="i" class="cond-row">
                    <span class="cond-field-d font-mono">{{ c.field }}</span>
                    <span class="cond-op-d">{{ c.operator }} ({{ opSym(c.operator) }})</span>
                    <span class="cond-val-d font-mono">{{ c.value !== undefined ? JSON.stringify(c.value) : (c.value_from ? '←' + c.value_from : '?') }}</span>
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
.effect-filter {
  display: flex; gap: 4px;
  margin-left: auto;
}
.e-chip {
  padding: 3px 10px;
  font-size: 10px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.04em;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.e-chip:hover { color: var(--p-text-color); }
.e-chip--allow.e-chip--active {
  background: color-mix(in srgb, var(--p-success-500) 14%, transparent);
  color: var(--p-success-500);
  border-color: color-mix(in srgb, var(--p-success-500) 40%, transparent);
}
.e-chip--deny.e-chip--active {
  background: color-mix(in srgb, var(--p-danger-500) 14%, transparent);
  color: var(--p-danger-500);
  border-color: color-mix(in srgb, var(--p-danger-500) 40%, transparent);
}
.e-chip--active:not(.e-chip--allow):not(.e-chip--deny) {
  background: var(--p-surface-200);
  color: var(--p-text-color);
}

.ns-head {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--p-text-muted-color);
  margin-bottom: 6px;
  padding: 0 4px;
}
.ns-head--allow { color: var(--p-success-500); }
.ns-head--deny  { color: var(--p-danger-500); }
.pol-card {
  padding: 12px;
  border-radius: 6px;
  border: 1px solid var(--p-content-border-color);
  border-left: 3px solid var(--p-text-muted-color);
  background: var(--p-surface-50);
  cursor: pointer;
  transition: border-color 0.1s, background 0.1s, box-shadow 0.1s;
}
.pol-card:hover { background: var(--p-surface-100); }
.pol-card--allow {
  border-left-color: var(--p-success-500);
  background: color-mix(in srgb, var(--p-success-500) 3%, var(--p-surface-50));
}
.pol-card--deny {
  border-left-color: var(--p-danger-500);
  background: color-mix(in srgb, var(--p-danger-500) 3%, var(--p-surface-50));
}
.pol-card--selected { box-shadow: inset 0 0 0 1px var(--p-primary-color); }

.pol-icon {
  width: 36px; height: 36px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 8px; flex-shrink: 0;
  background: color-mix(in srgb, var(--p-text-muted-color) 12%, transparent);
  color: var(--p-text-muted-color);
}
.pol-icon--allow {
  background: color-mix(in srgb, var(--p-success-500) 12%, transparent);
  color: var(--p-success-500);
  border: 1px solid color-mix(in srgb, var(--p-success-500) 25%, transparent);
}
.pol-icon--deny {
  background: color-mix(in srgb, var(--p-danger-500) 12%, transparent);
  color: var(--p-danger-500);
  border: 1px solid color-mix(in srgb, var(--p-danger-500) 25%, transparent);
}
.pol-title { font-size: 13px; font-weight: 600; color: var(--p-text-color); }
.pol-id {
  font-size: 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  color: var(--p-text-muted-color);
  margin-left: auto;
  opacity: 0.7;
}
.pol-comment {
  font-size: 11px; line-height: 1.5;
  color: var(--p-text-muted-color);
  margin-top: 4px;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden;
}

.effect-badge {
  font-size: 9px;
  font-weight: 800;
  padding: 1px 7px;
  border-radius: 3px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.effect-allow {
  background: color-mix(in srgb, var(--p-success-500) 16%, transparent);
  color: var(--p-success-500);
  border: 1px solid color-mix(in srgb, var(--p-success-500) 32%, transparent);
}
.effect-deny {
  background: color-mix(in srgb, var(--p-danger-500) 16%, transparent);
  color: var(--p-danger-500);
  border: 1px solid color-mix(in srgb, var(--p-danger-500) 32%, transparent);
}

.rule-grid {
  margin-top: 8px;
  display: flex; flex-direction: column; gap: 4px;
}
.rule-row {
  display: grid;
  grid-template-columns: 80px 1fr;
  gap: 8px;
  align-items: baseline;
}
.rule-lbl {
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.04em;
  color: var(--p-text-muted-color);
}
.rule-vals {
  display: flex; flex-wrap: wrap; gap: 4px;
}
.val-pill {
  display: inline-flex; align-items: center;
  font-size: 10px;
  padding: 1px 6px;
  border-radius: 3px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-color);
}
.val-pill--info {
  background: color-mix(in srgb, var(--p-info-500) 10%, transparent);
  color: var(--p-info-500);
  border-color: color-mix(in srgb, var(--p-info-500) 26%, transparent);
}
.val-pill--accent {
  background: color-mix(in srgb, var(--p-accent-500) 10%, transparent);
  color: var(--p-accent-500);
  border-color: color-mix(in srgb, var(--p-accent-500) 26%, transparent);
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}
.val-pill--mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}

.cond-pill {
  display: inline-flex; align-items: center; gap: 3px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  background: color-mix(in srgb, var(--p-warn-500) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-warn-500) 28%, transparent);
}
.cond-field { color: var(--p-text-color); font-weight: 600; }
.cond-op {
  color: var(--p-warn-500);
  font-weight: 700;
  font-size: 11px;
}
.cond-val { color: var(--p-text-muted-color); }

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

.cond-detail {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  padding: 6px 8px;
  display: flex; flex-direction: column; gap: 4px;
  font-size: 11px;
}
.cond-row {
  display: grid;
  grid-template-columns: minmax(0, auto) auto 1fr;
  gap: 8px;
  align-items: baseline;
}
.cond-field-d { color: var(--p-text-color); font-weight: 600; }
.cond-op-d    { color: var(--p-warn-500); font-size: 10px; }
.cond-val-d   { color: var(--p-text-muted-color); font-size: 10px; }
</style>
