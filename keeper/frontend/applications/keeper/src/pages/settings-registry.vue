<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import {
  getGovernanceConfig,
  getSyncState,
  listEntries,
  listNamespaces,
  syncDownload,
  syncRedo,
  syncUndo,
  syncUpload,
  updateGovernanceConfig,
} from '../api/registry'
import PageHeader from '../components/shared/PageHeader.vue'

const api = useApi()
const router = useRouter()

const syncState = ref<any>(null)
const loading = ref(true)
const syncLoading = ref(false)
const error = ref<string | null>(null)
const successMsg = ref<string | null>(null)
const confirmAction = ref<'download' | 'upload' | 'undo' | 'redo' | null>(null)
const namespaces = ref<{ name: string; count: number }[]>([])
const totalEntries = ref<number>(0)
const kindCounts = ref<{ kind: string; count: number }[]>([])
const managedNamespaces = ref<string[]>([])
const managedDraft = ref<string[]>([])
const managedNewInput = ref('')
const managedSaving = ref(false)
const managedAddInputRef = ref<HTMLInputElement | null>(null)

const confirmLabels: Record<string, { title: string; desc: string; icon: string }> = {
  download: {
    title: 'Download Registry',
    desc: 'This will overwrite the local filesystem with registry state. Any uncommitted filesystem changes will be lost.',
    icon: 'tabler:download',
  },
  upload: {
    title: 'Upload to Registry',
    desc: 'This will apply filesystem changes to the live registry. All validated changes will take effect immediately.',
    icon: 'tabler:upload',
  },
  undo: {
    title: 'Undo Last Change',
    desc: 'This will revert the registry to the previous version. The current version can be restored with Redo.',
    icon: 'tabler:arrow-back',
  },
  redo: {
    title: 'Redo Change',
    desc: 'This will re-apply the next version to the registry.',
    icon: 'tabler:arrow-forward',
  },
}

function formatTimestamp(ts: unknown): string {
  if (typeof ts === 'string') return new Date(ts).toLocaleString()
  if (typeof ts === 'number') {
    const ms = ts > 1e12 ? ts : ts * 1000
    return new Date(ms).toLocaleString()
  }
  return '-'
}

function timeAgo(ts: unknown): string {
  let ms: number
  if (typeof ts === 'string') ms = new Date(ts).getTime()
  else if (typeof ts === 'number') ms = ts > 1e12 ? ts : ts * 1000
  else return ''
  const sec = Math.floor((Date.now() - ms) / 1000)
  if (sec < 60) return `${sec}s ago`
  if (sec < 3600) return `${Math.floor(sec / 60)}m ago`
  if (sec < 86400) return `${Math.floor(sec / 3600)}h ago`
  return `${Math.floor(sec / 86400)}d ago`
}

const topNamespaces = computed(() => [...namespaces.value]
  .sort((a, b) => b.count - a.count)
  .slice(0, 10))

const versionShort = computed(() => {
  const v = syncState.value?.registry?.current_version
  if (typeof v === 'string' && v.length > 16) return v.slice(0, 8) + '…'
  return v ?? '—'
})

const managedNamespaceDirty = computed(() =>
  managedDraft.value.join(',') !== managedNamespaces.value.join(','))

function isValidNamespace(value: string): boolean {
  return /^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)*$/.test(value)
}

function isManagedNamespace(namespace: string): boolean {
  return managedNamespaces.value.some(root => namespace === root || namespace.startsWith(`${root}.`))
}

function resetManagedDraft() {
  managedDraft.value = [...managedNamespaces.value]
  managedNewInput.value = ''
}

function addManagedFromInput() {
  const candidates = managedNewInput.value.split(/[,\s]+/).map(s => s.trim()).filter(Boolean)
  let added = false
  for (const ns of candidates) {
    if (!isValidNamespace(ns)) {
      error.value = `Invalid namespace: ${ns}`
      continue
    }
    if (managedDraft.value.includes(ns)) continue
    managedDraft.value.push(ns)
    added = true
  }
  if (added) error.value = null
  managedNewInput.value = ''
  nextTick(() => managedAddInputRef.value?.focus())
}

function removeManagedDraft(ns: string) {
  managedDraft.value = managedDraft.value.filter(n => n !== ns)
}

const namespaceSuggestions = computed(() => {
  const q = managedNewInput.value.trim().toLowerCase()
  if (!q || q.length < 1) return []
  return namespaces.value
    .map(n => n.name.split('.')[0])
    .filter((v, i, arr) => arr.indexOf(v) === i)
    .filter(name => name.toLowerCase().startsWith(q) && !managedDraft.value.includes(name))
    .slice(0, 6)
})

function pickSuggestion(ns: string) {
  if (!managedDraft.value.includes(ns)) managedDraft.value.push(ns)
  managedNewInput.value = ''
  nextTick(() => managedAddInputRef.value?.focus())
}

function openNamespace(ns: string) {
  router.push({ path: '/structure', query: { ns } })
}

async function load() {
  loading.value = true; error.value = null
  try {
    const [sync, ns, entries, config] = await Promise.allSettled([
      getSyncState(api),
      listNamespaces(api),
      listEntries(api, { limit: 1000 }),
      getGovernanceConfig(api),
    ])
    if (sync.status === 'fulfilled') syncState.value = sync.value
    if (ns.status === 'fulfilled') {
      namespaces.value = (ns.value.namespaces || []).map((n: any) => ({ name: n.name, count: n.count || 0 }))
    }
    if (entries.status === 'fulfilled') {
      totalEntries.value = entries.value.total || (entries.value.entries || []).length
      const buckets: Record<string, number> = {}
      for (const e of (entries.value.entries || [])) {
        buckets[e.kind] = (buckets[e.kind] || 0) + 1
      }
      kindCounts.value = Object.entries(buckets)
        .map(([kind, count]) => ({ kind, count }))
        .sort((a, b) => b.count - a.count)
    }
    if (config.status === 'fulfilled') {
      managedNamespaces.value = config.value.managed_namespaces || []
      resetManagedDraft()
    }
  } catch (e: any) {
    error.value = 'Failed to load registry state'
  } finally {
    loading.value = false
  }
}

function requestSync(action: 'download' | 'upload' | 'undo' | 'redo') {
  confirmAction.value = action
}

function cancelConfirm() {
  confirmAction.value = null
}

async function executeConfirmed() {
  const action = confirmAction.value
  if (!action) return
  confirmAction.value = null
  syncLoading.value = true
  error.value = null
  successMsg.value = null
  try {
    let result: any
    if (action === 'download') result = await syncDownload(api)
    else if (action === 'upload') result = await syncUpload(api)
    else if (action === 'undo') result = await syncUndo(api)
    else if (action === 'redo') result = await syncRedo(api)
    if (result && !result.success) {
      error.value = result.message || `${action} failed`
    } else {
      successMsg.value = result?.message || `${action} completed`
      setTimeout(() => { successMsg.value = null }, 5000)
    }
    await load()
  } catch (e: any) {
    const msg = e.response?.data?.message || e.response?.data?.error || e.message
    error.value = `${action}: ${msg}`
  } finally {
    syncLoading.value = false
  }
}

async function saveManagedNamespaces() {
  const namespaces = [...managedDraft.value]
  if (namespaces.length === 0) {
    error.value = 'At least one managed namespace is required'
    return
  }
  const invalid = namespaces.find(n => !isValidNamespace(n))
  if (invalid) {
    error.value = `Invalid namespace: ${invalid}`
    return
  }

  managedSaving.value = true
  error.value = null
  successMsg.value = null
  try {
    const result = await updateGovernanceConfig(api, namespaces)
    managedNamespaces.value = result.managed_namespaces || namespaces
    resetManagedDraft()
    successMsg.value = result.message || 'Managed namespaces updated'
    setTimeout(() => { successMsg.value = null }, 5000)
  } catch (e: any) {
    const msg = e.response?.data?.message || e.response?.data?.error || e.message
    error.value = `managed namespaces: ${msg}`
  } finally {
    managedSaving.value = false
  }
}

const maxNsCount = computed(() => Math.max(1, ...topNamespaces.value.map(n => n.count)))
const maxKindCount = computed(() => Math.max(1, ...kindCounts.value.map(k => k.count)))

// Decorative palette — purely categorical, no semantic meaning. Visually
// distinguishes registry kinds (function.lua / library.lua / http.endpoint /
// ns.requirement / …). Raw hex on purpose so chart colors stay stable when
// the brand re-tints `--p-primary` or any severity token. Per theming.md
// §"Semantic vs decorative — the inverse rule": don't force severity tokens
// into purely decorative contexts.
const KIND_COLORS = [
  '#f59e0b', // amber
  '#10b981', // emerald
  '#f97316', // orange
  '#0ea5e9', // sky
  '#ef4444', // red
  '#14b8a6', // teal
  '#a855f7', // purple
  '#06b6d4', // cyan
  '#84cc16', // lime
  '#ec4899', // pink
]
function kindColor(idx: number): string { return KIND_COLORS[idx % KIND_COLORS.length] }

const KIND_ICONS: Record<string, string> = {
  'function.lua': 'tabler:function',
  'library.lua': 'tabler:books',
  'http.endpoint': 'tabler:api',
  'http.router': 'tabler:route',
  'http.cors': 'tabler:shield',
  'process.lua': 'tabler:cpu',
  'process.host': 'tabler:server-2',
  'registry.entry': 'tabler:database',
  'security.policy': 'tabler:shield-check',
  'db.sql.sqlite': 'tabler:database-export',
  'queue': 'tabler:list-numbers',
  'ledger': 'tabler:notebook',
  'env.variable': 'tabler:variable',
  'lua.module': 'tabler:cube',
  'binding': 'tabler:link',
  'definition': 'tabler:braces',
}
function kindIcon(kind: string): string {
  return KIND_ICONS[kind] || 'tabler:circle-dot'
}

const kindChart = computed(() => {
  const total = kindCounts.value.reduce((s, k) => s + k.count, 0) || 1
  let cum = 0
  return kindCounts.value.map((k, i) => {
    const pct = k.count / total
    const start = cum
    cum += pct
    return {
      ...k,
      color: kindColor(i),
      pct,
      pctLabel: (pct * 100).toFixed(pct < 0.01 ? 2 : pct < 0.1 ? 1 : 0),
      startAngle: start * 2 * Math.PI - Math.PI / 2,
      endAngle: cum * 2 * Math.PI - Math.PI / 2,
    }
  })
})

function arcPath(startAngle: number, endAngle: number, rOuter = 60, rInner = 38, cx = 70, cy = 70): string {
  const x1 = cx + rOuter * Math.cos(startAngle)
  const y1 = cy + rOuter * Math.sin(startAngle)
  const x2 = cx + rOuter * Math.cos(endAngle)
  const y2 = cy + rOuter * Math.sin(endAngle)
  const x3 = cx + rInner * Math.cos(endAngle)
  const y3 = cy + rInner * Math.sin(endAngle)
  const x4 = cx + rInner * Math.cos(startAngle)
  const y4 = cy + rInner * Math.sin(startAngle)
  const large = endAngle - startAngle > Math.PI ? 1 : 0
  return `M ${x1} ${y1} A ${rOuter} ${rOuter} 0 ${large} 1 ${x2} ${y2} L ${x3} ${y3} A ${rInner} ${rInner} 0 ${large} 0 ${x4} ${y4} Z`
}

const hoveredKind = ref<string | null>(null)
function isKindActive(k: string): boolean {
  return hoveredKind.value === null || hoveredKind.value === k
}

const treemap = computed(() => {
  // Squarified treemap (Bruls 2000 simplified): place rectangles with sizes proportional to counts
  const items = topNamespaces.value
  if (!items.length) return []
  const W = 100, H = 100
  const total = items.reduce((s, n) => s + n.count, 0) || 1
  const scaled = items.map(n => ({ ...n, area: (n.count / total) * (W * H) }))
  const out: Array<{ name: string; count: number; x: number; y: number; w: number; h: number }> = []

  let x = 0, y = 0, remW = W, remH = H, idx = 0
  while (idx < scaled.length) {
    const horizontal = remW >= remH
    const sliceLen = horizontal ? remH : remW
    let row: typeof scaled = []
    let rowSum = 0
    let bestWorst = Infinity
    while (idx < scaled.length) {
      const next = scaled[idx]
      const newSum = rowSum + next.area
      const rowAreas = [...row.map(r => r.area), next.area]
      const rowLen = newSum / sliceLen
      const worst = Math.max(...rowAreas.map(a => Math.max((rowLen * rowLen) / a, a / (rowLen * rowLen))))
      if (worst < bestWorst || row.length === 0) {
        row.push(next)
        rowSum = newSum
        bestWorst = worst
        idx++
      } else break
    }
    const rowLen = rowSum / sliceLen
    let cursor = 0
    for (const r of row) {
      const seg = r.area / rowLen
      if (horizontal) {
        out.push({ name: r.name, count: r.count, x: x, y: y + cursor, w: rowLen, h: seg })
      } else {
        out.push({ name: r.name, count: r.count, x: x + cursor, y: y, w: seg, h: rowLen })
      }
      cursor += seg
    }
    if (horizontal) { x += rowLen; remW -= rowLen } else { y += rowLen; remH -= rowLen }
  }
  return out
})

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader icon="tabler:database" title="Registry" :loading="loading" @refresh="load" />

    <div v-if="successMsg" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-success-500/10 text-success-500">
      <Icon icon="tabler:check" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ successMsg }}</span>
      <button @click="successMsg = null" style="color: var(--p-text-muted-color)"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>

    <div v-if="error" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
      <button @click="error = null" style="color: var(--p-text-muted-color)"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>

    <Teleport to="body">
      <div v-if="confirmAction" class="confirm-overlay" @click.self="cancelConfirm">
        <div class="confirm-dialog">
          <div class="flex items-center gap-2 mb-3">
            <Icon :icon="confirmLabels[confirmAction].icon" class="w-5 h-5 keeper-accent" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">{{ confirmLabels[confirmAction].title }}</span>
          </div>
          <p class="text-[11px] mb-4 leading-relaxed" style="color: var(--p-text-muted-color)">
            {{ confirmLabels[confirmAction].desc }}
          </p>
          <div class="flex justify-end gap-2">
            <button class="confirm-btn cancel" @click="cancelConfirm">Cancel</button>
            <button class="confirm-btn proceed" @click="executeConfirmed">Proceed</button>
          </div>
        </div>
      </div>
    </Teleport>

    <div class="flex-1 overflow-y-auto p-4 space-y-4">
      <!-- Stats grid -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-label">Entries</div>
          <div class="stat-value">{{ totalEntries.toLocaleString() }}</div>
          <div class="stat-sub">across {{ namespaces.length }} namespaces</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Version</div>
          <div class="stat-value font-mono">{{ versionShort }}</div>
          <div class="stat-sub">{{ syncState?.registry?.timestamp ? timeAgo(syncState.registry.timestamp) : '—' }}</div>
        </div>
        <div class="stat-card" :class="syncState?.registry?.has_changes ? 'stat-card--warn' : 'stat-card--ok'">
          <div class="stat-label">Pending</div>
          <div class="stat-value">{{ syncState?.registry?.has_changes ? 'Yes' : 'None' }}</div>
          <div class="stat-sub">{{ syncState?.registry?.has_changes ? 'fs not synced' : 'in sync' }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Syncer</div>
          <div class="stat-value capitalize">{{ syncState?.syncer?.status || 'N/A' }}</div>
          <div class="stat-sub">governance</div>
        </div>
      </div>

      <!-- Sync actions -->
      <section class="panel">
        <div class="panel-head">
          <Icon icon="tabler:refresh" class="w-4 h-4" />
          <span class="panel-title">Sync</span>
          <span class="panel-sub">filesystem ↔ registry</span>
        </div>
        <div class="panel-body">
          <div v-if="syncState?.syncer?.status === 'unknown'" class="text-[10px] mb-3 px-2 py-1.5 rounded bg-warn-500/10 text-warn-500">
            Governance service not running. Sync/undo/redo unavailable.
          </div>
          <div class="flex gap-2 flex-wrap">
            <button class="sync-btn" @click="requestSync('download')" :disabled="syncLoading">
              <Icon icon="tabler:download" class="w-3.5 h-3.5" /> Download
            </button>
            <button class="sync-btn" @click="requestSync('upload')" :disabled="syncLoading" :class="syncState?.registry?.has_changes ? 'sync-btn--primary' : ''">
              <Icon icon="tabler:upload" class="w-3.5 h-3.5" /> Upload
            </button>
            <button class="sync-btn" @click="requestSync('undo')" :disabled="syncLoading">
              <Icon icon="tabler:arrow-back" class="w-3.5 h-3.5" /> Undo
            </button>
            <button class="sync-btn" @click="requestSync('redo')" :disabled="syncLoading">
              <Icon icon="tabler:arrow-forward" class="w-3.5 h-3.5" /> Redo
            </button>
            <Icon v-if="syncLoading" icon="tabler:loader-2" class="w-4 h-4 animate-spin keeper-accent" />
          </div>
        </div>
      </section>

      <!-- Managed namespaces -->
      <section class="panel">
        <div class="panel-head">
          <Icon icon="tabler:list-check" class="w-4 h-4" />
          <span class="panel-title">Managed namespaces</span>
          <span class="panel-sub">{{ managedDraft.length }} root{{ managedDraft.length === 1 ? '' : 's' }}</span>
        </div>
        <div class="panel-body">
          <div class="managed-editor">
            <span
              v-for="ns in managedDraft"
              :key="ns"
              class="managed-chip"
              @click="openNamespace(ns)"
              :title="`Open ${ns} in Structure`"
            >
              {{ ns }}
              <button
                class="managed-chip-x"
                :title="`Remove ${ns}`"
                @click.stop="removeManagedDraft(ns)"
                :disabled="managedSaving"
              >
                <Icon icon="tabler:x" class="w-2.5 h-2.5" />
              </button>
            </span>
            <div class="managed-input-wrap">
              <input
                ref="managedAddInputRef"
                v-model="managedNewInput"
                class="managed-add-input"
                placeholder="Add namespace…"
                spellcheck="false"
                :disabled="managedSaving"
                @keydown.enter.prevent="addManagedFromInput"
                @keydown.tab="addManagedFromInput"
                @keydown.,.prevent="addManagedFromInput"
                @keydown.space.prevent="addManagedFromInput"
                @keydown.backspace="managedNewInput === '' && managedDraft.length && (managedDraft = managedDraft.slice(0, -1))"
              />
              <ul v-if="namespaceSuggestions.length" class="managed-suggestions">
                <li v-for="s in namespaceSuggestions" :key="s" @mousedown.prevent="pickSuggestion(s)">
                  <Icon icon="tabler:plus" class="w-3 h-3" />
                  <span class="font-mono">{{ s }}</span>
                </li>
              </ul>
            </div>
          </div>
          <div class="flex items-center gap-2 mt-3">
            <button
              class="sync-btn sync-btn--primary"
              :disabled="managedSaving || !managedNamespaceDirty"
              @click="saveManagedNamespaces"
            >
              <Icon icon="tabler:device-floppy" class="w-3.5 h-3.5" /> Save
            </button>
            <button class="sync-btn" :disabled="managedSaving || !managedNamespaceDirty" @click="resetManagedDraft">
              <Icon icon="tabler:restore" class="w-3.5 h-3.5" /> Reset
            </button>
            <span class="text-[10px] ml-auto" style="color: var(--p-text-muted-color)">
              Tip: type and press <kbd class="kbd">Enter</kbd> or <kbd class="kbd">,</kbd> to add. Click a chip to open it.
            </span>
            <Icon v-if="managedSaving" icon="tabler:loader-2" class="w-4 h-4 animate-spin keeper-accent" />
          </div>
        </div>
      </section>

      <!-- Composition row: donut chart + namespace treemap -->
      <div class="composition-grid" v-if="kindCounts.length || treemap.length">
        <!-- Donut: by kind -->
        <section v-if="kindCounts.length" class="panel">
          <div class="panel-head">
            <Icon icon="tabler:chart-donut" class="w-4 h-4" />
            <span class="panel-title">Composition by kind</span>
            <span class="panel-sub">{{ kindCounts.length }} kinds</span>
          </div>
          <div class="panel-body donut-wrap">
            <svg viewBox="0 0 140 140" class="donut-svg">
              <g>
                <path
                  v-for="(slice, i) in kindChart" :key="slice.kind"
                  :d="arcPath(slice.startAngle, slice.endAngle)"
                  :fill="slice.color"
                  :class="['donut-slice', { 'donut-slice--dim': hoveredKind && hoveredKind !== slice.kind }]"
                  @mouseenter="hoveredKind = slice.kind"
                  @mouseleave="hoveredKind = null"
                />
              </g>
              <text x="70" y="66" text-anchor="middle" class="donut-center-num">{{ totalEntries }}</text>
              <text x="70" y="80" text-anchor="middle" class="donut-center-label">entries</text>
            </svg>
            <ul class="donut-legend">
              <li v-for="slice in kindChart" :key="slice.kind"
                class="donut-legend-item"
                :class="{ 'donut-legend-item--dim': hoveredKind && hoveredKind !== slice.kind }"
                @mouseenter="hoveredKind = slice.kind"
                @mouseleave="hoveredKind = null">
                <span class="donut-swatch" :style="{ background: slice.color }"></span>
                <Icon :icon="kindIcon(slice.kind)" class="w-3 h-3 shrink-0" :style="{ color: slice.color }" />
                <span class="donut-kind-name">{{ slice.kind }}</span>
                <span class="donut-kind-pct">{{ slice.pctLabel }}%</span>
                <span class="donut-kind-count">{{ slice.count }}</span>
              </li>
            </ul>
          </div>
        </section>

        <!-- Treemap: top namespaces -->
        <section v-if="treemap.length" class="panel">
          <div class="panel-head">
            <Icon icon="tabler:layout-grid" class="w-4 h-4" />
            <span class="panel-title">Top namespaces</span>
            <span class="panel-sub">{{ namespaces.length }} total</span>
          </div>
          <div class="panel-body">
            <div class="treemap-wrap">
              <button
                v-for="cell in treemap" :key="cell.name"
                class="treemap-cell"
                :class="{ 'treemap-cell--managed': isManagedNamespace(cell.name) }"
                :style="{
                  left: cell.x + '%', top: cell.y + '%',
                  width: cell.w + '%', height: cell.h + '%',
                  fontSize: Math.max(9, Math.min(16, Math.sqrt(cell.w * cell.h) * 0.7)) + 'px',
                }"
                :title="`Open ${cell.name} in Structure (${cell.count} entries)`"
                @click="openNamespace(cell.name)">
                <div class="treemap-name">{{ cell.name }}</div>
                <div class="treemap-count">{{ cell.count }}</div>
              </button>
            </div>
            <p class="text-[9px] mt-2" style="color: var(--p-text-muted-color)">
              Cell area ∝ entry count. Outlined cells are managed.
            </p>
          </div>
        </section>
      </div>

      <p v-if="kindCounts.length" class="text-[9px] -mt-2 px-1" style="color: var(--p-text-muted-color)">
        Counts derived from a 1000-entry sample; see Structure → Registry for the full browser.
      </p>
    </div>
  </div>
</template>

<style scoped>
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 10px;
}
.stat-card {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  padding: 12px 14px;
}
.stat-card--ok { border-color: color-mix(in srgb, var(--p-success-500) 30%, var(--p-content-border-color)); }
.stat-card--warn { border-color: color-mix(in srgb, var(--p-warn-500) 35%, var(--p-content-border-color)); }
.stat-label {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600;
  color: var(--p-text-muted-color);
}
.stat-value {
  font-size: 18px; font-weight: 700;
  color: var(--p-text-color);
  margin-top: 4px;
  font-variant-numeric: tabular-nums;
}
.stat-sub {
  font-size: 10px;
  color: var(--p-text-muted-color);
  margin-top: 2px;
}

.panel {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  overflow: hidden;
}
.panel-head {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 14px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: var(--p-surface-100);
  color: var(--p-primary-color);
}
.panel-title {
  font-size: 12px; font-weight: 600;
  color: var(--p-text-color);
}
.panel-sub {
  font-size: 10px;
  color: var(--p-text-muted-color);
  margin-left: auto;
}
.panel-body {
  padding: 12px 14px;
}

.sync-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.sync-btn:hover:not(:disabled) { background: var(--p-surface-100); }
.sync-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.sync-btn--primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
  font-weight: 600;
}
.sync-btn--primary:hover:not(:disabled) { opacity: 0.9; }

.managed-editor {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
  min-height: 36px;
  padding: 6px 8px;
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  background: var(--p-surface-0);
  transition: border-color 0.12s;
}
.managed-editor:focus-within {
  border-color: color-mix(in srgb, var(--p-primary-color) 60%, var(--p-content-border-color));
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--p-primary-color) 14%, transparent);
}
.managed-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 6px 2px 8px;
  border-radius: 4px;
  border: 1px solid color-mix(in srgb, var(--p-success-500) 30%, var(--p-content-border-color));
  background: color-mix(in srgb, var(--p-success-500) 12%, transparent);
  color: var(--p-text-color);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 11px;
  cursor: pointer;
  transition: background 0.1s, border-color 0.1s;
  user-select: none;
}
.managed-chip:hover {
  background: color-mix(in srgb, var(--p-success-500) 22%, transparent);
  border-color: color-mix(in srgb, var(--p-success-500) 50%, transparent);
}
.managed-chip-x {
  display: inline-flex; align-items: center; justify-content: center;
  width: 14px; height: 14px;
  border: none;
  background: transparent;
  color: var(--p-text-muted-color);
  border-radius: 3px;
  cursor: pointer;
  transition: background 0.1s, color 0.1s;
}
.managed-chip-x:hover {
  background: color-mix(in srgb, var(--p-danger-500) 18%, transparent);
  color: var(--p-danger-500);
}

.managed-input-wrap {
  position: relative;
  flex: 1;
  min-width: 140px;
}
.managed-add-input {
  width: 100%;
  border: none;
  background: transparent;
  color: var(--p-text-color);
  padding: 2px 4px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 12px;
  outline: none;
}
.managed-add-input::placeholder { color: var(--p-text-muted-color); }

.managed-suggestions {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  right: 0;
  z-index: 10;
  margin: 0; padding: 4px;
  list-style: none;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  box-shadow: 0 6px 18px rgba(0, 0, 0, 0.12);
}
.managed-suggestions li {
  display: flex; align-items: center; gap: 6px;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  color: var(--p-text-color);
  cursor: pointer;
}
.managed-suggestions li:hover {
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
}

.kbd {
  display: inline-block;
  padding: 0 4px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 9px;
  border: 1px solid var(--p-content-border-color);
  background: var(--p-surface-100);
  border-radius: 3px;
  color: var(--p-text-color);
}

/* Composition grid: donut + treemap side by side */
.composition-grid {
  display: grid;
  grid-template-columns: minmax(320px, 0.9fr) minmax(360px, 1.1fr);
  gap: 14px;
}
@media (max-width: 980px) {
  .composition-grid { grid-template-columns: 1fr; }
}

/* Donut chart */
.donut-wrap {
  display: grid;
  grid-template-columns: 150px 1fr;
  gap: 18px;
  align-items: start;
}
.donut-svg {
  width: 150px;
  height: 150px;
  display: block;
  position: sticky;
  top: 0;
}
.donut-slice {
  transition: opacity 0.15s, transform 0.15s;
  transform-origin: 70px 70px;
  cursor: pointer;
}
.donut-slice:hover { transform: scale(1.04); }
.donut-slice--dim { opacity: 0.25; }
.donut-center-num {
  font-size: 18px; font-weight: 700;
  fill: var(--p-text-color);
  font-variant-numeric: tabular-nums;
}
.donut-center-label {
  font-size: 9px;
  fill: var(--p-text-muted-color);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.donut-legend {
  list-style: none;
  margin: 0; padding: 0;
  display: flex; flex-direction: column;
  gap: 1px;
}
.donut-legend-item {
  display: grid;
  grid-template-columns: 8px 12px 1fr auto auto;
  align-items: center;
  gap: 6px;
  padding: 3px 4px;
  border-radius: 3px;
  font-size: 11px;
  color: var(--p-text-color);
  cursor: pointer;
  transition: background 0.1s, opacity 0.15s;
}
.donut-legend-item:hover {
  background: var(--p-surface-100);
}
.donut-legend-item--dim { opacity: 0.4; }
.donut-swatch {
  width: 8px; height: 8px; border-radius: 2px;
  display: inline-block;
}
.donut-kind-name {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 10px;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.donut-kind-pct {
  font-size: 10px;
  color: var(--p-text-muted-color);
  font-variant-numeric: tabular-nums;
  min-width: 32px; text-align: right;
}
.donut-kind-count {
  font-size: 10px;
  font-weight: 600;
  color: var(--p-text-color);
  font-variant-numeric: tabular-nums;
  min-width: 28px; text-align: right;
}

/* Treemap */
.treemap-wrap {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: var(--p-surface-100);
  border-radius: 6px;
  overflow: hidden;
}
.treemap-cell {
  position: absolute;
  background: color-mix(in srgb, var(--p-primary-color) 18%, var(--p-surface-50));
  border: 1px solid var(--p-surface-100);
  color: var(--p-text-color);
  padding: 4px 6px;
  display: flex; flex-direction: column; justify-content: flex-start;
  text-align: left;
  overflow: hidden;
  cursor: pointer;
  transition: background 0.12s, transform 0.12s, box-shadow 0.12s;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
.treemap-cell:hover {
  background: color-mix(in srgb, var(--p-primary-color) 38%, var(--p-surface-50));
  border-color: var(--p-primary-color);
  box-shadow: inset 0 0 0 1px var(--p-primary-color);
  z-index: 2;
}
.treemap-cell:focus-visible {
  outline: 2px solid var(--p-primary-color);
  outline-offset: -2px;
  z-index: 3;
}
.treemap-cell--managed {
  background: color-mix(in srgb, var(--p-success-500) 18%, var(--p-surface-50));
  border-color: color-mix(in srgb, var(--p-success-500) 35%, transparent);
}
.treemap-cell--managed:hover {
  background: color-mix(in srgb, var(--p-success-500) 32%, var(--p-surface-50));
}
.treemap-name {
  font-weight: 600;
  line-height: 1.15;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.treemap-count {
  margin-top: auto;
  font-size: 0.85em;
  font-weight: 700;
  color: var(--p-primary-color);
  font-variant-numeric: tabular-nums;
}
.treemap-cell--managed .treemap-count {
  color: var(--p-success-500);
}

.confirm-overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0, 0, 0, 0.6);
  display: flex; align-items: center; justify-content: center;
}
.confirm-dialog {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  padding: 20px;
  width: 380px;
  max-width: 90vw;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}
.confirm-btn {
  display: inline-flex; align-items: center;
  padding: 6px 16px; border-radius: 4px; font-size: 11px;
  cursor: pointer; border: none;
}
.confirm-btn.cancel {
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
}
.confirm-btn.cancel:hover { background: var(--p-surface-200); }
.confirm-btn.proceed {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  font-weight: 600;
}
.confirm-btn.proceed:hover { opacity: 0.9; }
</style>
