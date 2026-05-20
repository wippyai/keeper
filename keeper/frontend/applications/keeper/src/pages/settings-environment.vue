<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { useApi } from '../composables/useWippy'
import { listEnvVariables, setEnvVariable, type EnvVariable } from '../api/registry'
import PageHeader from '../components/shared/PageHeader.vue'

const api = useApi()

const envVars = ref<EnvVariable[]>([])
const loading = ref(true)
const search = ref('')
const filter = ref<'all' | 'set' | 'unset'>('all')
const sortBy = ref<'namespace' | 'name' | 'status'>('namespace')
const showValues = ref(false)
const editingVar = ref<string | null>(null)
const editValue = ref('')
const error = ref<string | null>(null)
const successMsg = ref<string | null>(null)
const copiedVar = ref<string | null>(null)

function looksSecret(v: EnvVariable): boolean {
  const id = (v.env_var || v.id || '').toUpperCase()
  return /TOKEN|SECRET|KEY|PASSWORD|PASS|API_KEY|CREDENTIAL/.test(id)
}

const stats = computed(() => {
  const set = envVars.value.filter(v => v.has_value).length
  const unset = envVars.value.length - set
  const secret = envVars.value.filter(looksSecret).length
  return { total: envVars.value.length, set, unset, secret }
})

const filtered = computed(() => {
  let list = envVars.value
  if (filter.value === 'set') list = list.filter(v => v.has_value)
  if (filter.value === 'unset') list = list.filter(v => !v.has_value)
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(v =>
      (v.env_var || '').toLowerCase().includes(q) ||
      v.id.toLowerCase().includes(q) ||
      (v.description || '').toLowerCase().includes(q) ||
      ((v.meta as any)?.description || '').toLowerCase().includes(q),
    )
  }
  return [...list].sort((a, b) => {
    if (sortBy.value === 'name') return (a.env_var || a.id).localeCompare(b.env_var || b.id)
    if (sortBy.value === 'status') return (a.has_value === b.has_value ? 0 : a.has_value ? -1 : 1) || a.id.localeCompare(b.id)
    return a.id.localeCompare(b.id)
  })
})

const grouped = computed(() => {
  if (sortBy.value !== 'namespace') return [['', filtered.value] as [string, EnvVariable[]]]
  const groups: Record<string, EnvVariable[]> = {}
  for (const v of filtered.value) {
    const ns = v.id.split(':')[0] || 'other'
    if (!groups[ns]) groups[ns] = []
    groups[ns].push(v)
  }
  return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
})

async function load() {
  loading.value = true; error.value = null
  try {
    const r = await listEnvVariables(api)
    envVars.value = r.variables || []
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function startEdit(v: EnvVariable) {
  editingVar.value = v.id
  editValue.value = v.value || ''
}

async function saveVar(v: EnvVariable) {
  try {
    await setEnvVariable(api, v.id, editValue.value)
    editingVar.value = null
    successMsg.value = `${v.env_var || v.id} updated`
    setTimeout(() => { successMsg.value = null }, 2500)
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

function cancelEdit() {
  editingVar.value = null
}

function copyValue(v: EnvVariable) {
  if (!v.has_value) return
  navigator.clipboard?.writeText(v.value || '').then(() => {
    copiedVar.value = v.id
    setTimeout(() => { if (copiedVar.value === v.id) copiedVar.value = null }, 1500)
  })
}

function copyAsEnv() {
  const lines = filtered.value
    .filter(v => v.has_value)
    .map(v => `${v.env_var || v.id}=${(v.value || '').replace(/\n/g, '\\n')}`)
  if (!lines.length) return
  navigator.clipboard?.writeText(lines.join('\n')).then(() => {
    successMsg.value = `${lines.length} variables copied as .env`
    setTimeout(() => { successMsg.value = null }, 2500)
  })
}

function maskedValue(v: EnvVariable): string {
  if (!v.value) return ''
  if (showValues.value || !looksSecret(v)) return v.value
  if (v.value.length <= 8) return '••••'
  return v.value.slice(0, 4) + '•'.repeat(Math.max(4, v.value.length - 8)) + v.value.slice(-4)
}

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader
      icon="tabler:variable"
      title="Environment"
      :count="filtered.length === envVars.length ? envVars.length : `${filtered.length} / ${envVars.length}`"
      :loading="loading"
      @refresh="load"
    >
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="search" type="text" placeholder="Search variables…" class="search-input" />
      </div>
      <select v-model="filter" class="sort-select" title="Filter">
        <option value="all">All</option>
        <option value="set">Set</option>
        <option value="unset">Unset</option>
      </select>
      <select v-model="sortBy" class="sort-select" title="Sort by">
        <option value="namespace">By namespace</option>
        <option value="name">By name</option>
        <option value="status">By status</option>
      </select>
      <button class="header-btn" :class="{ active: showValues }" @click="showValues = !showValues" title="Reveal masked values">
        <Icon :icon="showValues ? 'tabler:eye-off' : 'tabler:eye'" class="w-3.5 h-3.5" />
        {{ showValues ? 'Hide' : 'Reveal' }}
      </button>
      <Button severity="secondary" @click="copyAsEnv" title="Copy filtered as .env">
        <Icon icon="tabler:download" class="w-3.5 h-3.5" />
        .env
      </Button>
    </PageHeader>

    <!-- Stats strip -->
    <div class="stats-strip">
      <div class="stat-tile">
        <span class="stat-label">Total</span>
        <span class="stat-value">{{ stats.total }}</span>
      </div>
      <div class="stat-tile">
        <span class="stat-label">Set</span>
        <span class="stat-value text-success-500">{{ stats.set }}</span>
      </div>
      <div class="stat-tile">
        <span class="stat-label">Unset</span>
        <span class="stat-value" :class="stats.unset > 0 ? 'text-warn-500' : ''">{{ stats.unset }}</span>
      </div>
      <div class="stat-tile">
        <span class="stat-label">Secrets</span>
        <span class="stat-value text-info-500">{{ stats.secret }}</span>
      </div>
    </div>

    <div v-if="successMsg" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-success-500/15 text-success-500">
      <Icon icon="tabler:check" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ successMsg }}</span>
    </div>
    <div v-if="error" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
      <button @click="error = null" style="color: var(--p-text-muted-color)"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>

    <div class="flex-1 overflow-y-auto p-4">
      <div v-if="filtered.length === 0 && !loading" class="text-center py-12">
        <Icon icon="tabler:variable" class="w-10 h-10 mx-auto opacity-30" style="color: var(--p-text-muted-color)" />
        <p class="mt-2 text-xs" style="color: var(--p-text-muted-color)">{{ search || filter !== 'all' ? 'No variables match' : 'No environment variables configured' }}</p>
      </div>

      <template v-else>
        <div v-for="[ns, items] in grouped" :key="ns" class="mb-4">
          <div v-if="ns" class="text-[9px] uppercase tracking-wider font-semibold mb-2 px-1" style="color: var(--p-text-muted-color)">
            {{ ns }} <span class="opacity-60">· {{ items.length }}</span>
          </div>
          <div class="rounded-lg overflow-hidden" style="border: 1px solid var(--p-content-border-color)">
            <div v-for="v in items" :key="v.id" class="env-row">
              <div class="env-icon" :class="{ 'env-icon--secret': looksSecret(v) }">
                <Icon :icon="(v.meta as any)?.icon || (looksSecret(v) ? 'tabler:lock' : 'tabler:variable')" class="w-3.5 h-3.5" />
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <span class="font-mono font-semibold text-[11px]" style="color: var(--p-text-color)">{{ v.env_var || v.id }}</span>
                  <span v-if="v.has_value" class="status-dot status-dot--set" title="Set"></span>
                  <span v-else class="status-dot status-dot--unset" title="Not set"></span>
                  <span v-if="looksSecret(v)" class="secret-tag">secret</span>
                  <span v-if="v.readonly" class="readonly-tag">readonly</span>
                </div>
                <div v-if="v.description || (v.meta as any)?.description" class="text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">{{ v.description || (v.meta as any)?.description }}</div>
                <div class="text-[9px] font-mono mt-0.5 opacity-50" style="color: var(--p-text-muted-color)">{{ v.id }}</div>
              </div>

              <div class="env-value">
                <template v-if="editingVar === v.id">
                  <input
                    v-model="editValue"
                    class="env-input"
                    @keydown.enter="saveVar(v)"
                    @keydown.escape="cancelEdit"
                  />
                  <button class="row-btn ok" @click="saveVar(v)" title="Save (Enter)"><Icon icon="tabler:check" class="w-3.5 h-3.5" /></button>
                  <Button class="k-btn-icon !w-[22px] !h-[22px] !p-0" @click="cancelEdit" title="Cancel (Esc)"><Icon icon="tabler:x" class="w-3.5 h-3.5" /></Button>
                </template>
                <template v-else>
                  <span v-if="v.has_value" class="env-value-text font-mono">{{ maskedValue(v) }}</span>
                  <span v-else class="env-value-empty italic">not set</span>
                  <Button v-if="v.has_value" class="k-btn-icon !w-[22px] !h-[22px] !p-0" @click="copyValue(v)" :title="copiedVar === v.id ? 'Copied!' : 'Copy value'">
                    <Icon :icon="copiedVar === v.id ? 'tabler:check' : 'tabler:copy'" class="w-3 h-3" :class="copiedVar === v.id ? 'text-success-500' : ''" />
                  </Button>
                  <Button v-if="!v.readonly" class="k-btn-icon !w-[22px] !h-[22px] !p-0" @click="startEdit(v)" title="Edit">
                    <Icon icon="tabler:pencil" class="w-3 h-3" />
                  </Button>
                </template>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.stats-strip {
  display: flex;
  gap: 8px;
  padding: 8px 16px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: color-mix(in srgb, var(--p-surface-50) 60%, transparent);
}
.stat-tile {
  display: flex; align-items: baseline; gap: 6px;
  padding: 4px 10px;
  border-radius: 4px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
}
.stat-label {
  font-size: 10px;
  color: var(--p-text-muted-color);
}
.stat-value {
  font-size: 14px;
  font-weight: 700;
  color: var(--p-text-color);
  font-variant-numeric: tabular-nums;
}

.env-row {
  display: flex; align-items: center; gap: 12px;
  padding: 10px 12px;
  border-top: 1px solid var(--p-content-border-color);
  font-size: 11px;
}
.env-row:first-child { border-top: 0; }
.env-row:hover { background: var(--p-surface-100); }
.env-icon {
  width: 28px; height: 28px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 6px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  flex-shrink: 0;
}
.env-icon--secret {
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  color: var(--p-info-500);
}

.status-dot {
  display: inline-block;
  width: 6px; height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}
.status-dot--set { background: var(--p-success-500); }
.status-dot--unset { background: var(--p-text-muted-color); opacity: 0.4; }

.secret-tag, .readonly-tag {
  font-size: 8px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 1px 5px;
  border-radius: 3px;
}
.secret-tag {
  background: color-mix(in srgb, var(--p-info-500) 14%, transparent);
  color: var(--p-info-500);
}
.readonly-tag {
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
}

.env-value {
  display: flex; align-items: center; gap: 6px;
  flex-shrink: 0;
  max-width: 50%;
}
.env-value-text {
  font-size: 11px;
  color: var(--p-text-color);
  font-family: 'JetBrains Mono', monospace;
  max-width: 280px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.env-value-empty {
  font-size: 11px;
  color: var(--p-text-muted-color);
}
.env-input {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  padding: 3px 8px;
  border-radius: 4px;
  width: 280px;
  background: var(--p-surface-0);
  color: var(--p-text-color);
  border: 1px solid var(--p-primary-color);
  outline: none;
}

.row-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 22px; height: 22px;
  border-radius: 3px;
  background: transparent;
  color: var(--p-text-muted-color);
  border: none;
  cursor: pointer;
}
.row-btn:hover { background: var(--p-surface-200); color: var(--p-text-color); }
.row-btn.ok { color: var(--p-success-500); }
.row-btn.ok:hover { background: color-mix(in srgb, var(--p-success-500) 12%, transparent); }

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

.header-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.header-btn:hover { background: var(--p-surface-200); }
.header-btn.active {
  background: color-mix(in srgb, var(--p-primary-color) 14%, transparent);
  border-color: var(--p-primary-color);
  color: var(--p-primary-color);
}
</style>
