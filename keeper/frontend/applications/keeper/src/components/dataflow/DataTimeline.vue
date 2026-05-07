<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import type { DataflowNode, DataflowData } from '../../api/dataflows'
import { nodeTitle } from './node-utils'
import DataRenderer from './DataRenderer.vue'
import JsonBlock from '../shared/JsonBlock.vue'

const props = defineProps<{
  nodes: DataflowNode[]
  data: DataflowData[]
  showInternal: boolean
  nodeFilter: string
  groupTurns: boolean
  newIds?: Set<string>
}>()

const emit = defineEmits<{
  selectNode: [nodeId: string]
}>()

function ts(x: { created_at: any }): number {
  const v = x.created_at
  if (typeof v === 'number') return v
  const t = new Date(v).getTime()
  return Number.isFinite(t) ? t : 0
}

interface NodeInfo {
  node_id: string
  type: string
  title: string
  level: number
}

const levelMap = computed<Map<string, NodeInfo>>(() => {
  const map = new Map<string, { node: DataflowNode; children: string[]; level: number }>()
  for (const n of props.nodes) {
    if (n.status === 'template') continue
    map.set(n.node_id, { node: n, children: [], level: 0 })
  }
  const roots: string[] = []
  for (const [id, entry] of map) {
    const pid = entry.node.parent_node_id
    if (pid && map.has(pid)) {
      map.get(pid)!.children.push(id)
    } else {
      roots.push(id)
    }
  }
  const walk = (id: string, level: number) => {
    const entry = map.get(id)
    if (!entry) return
    entry.level = level
    for (const c of entry.children) walk(c, level + 1)
  }
  for (const r of roots) walk(r, 0)

  const out = new Map<string, NodeInfo>()
  for (const [id, e] of map) {
    out.set(id, {
      node_id: id,
      type: e.node.type,
      title: nodeTitle(e.node),
      level: e.level,
    })
  }
  return out
})

interface TimelineEntry {
  dataItem: DataflowData
  nodeInfo: NodeInfo | null
  isGlobal: boolean
  isGrouped: boolean
  resultItem?: DataflowData
  isTurn?: boolean
  observations?: DataflowData[]
}

function tryParse(s: any): any {
  if (typeof s === 'object') return s
  if (typeof s !== 'string') return null
  try { return JSON.parse(s) } catch { return null }
}

function resolveNodeInfo(d: DataflowData): NodeInfo | null {
  if (!d.node_id) return null
  const info = levelMap.value.get(d.node_id)
  if (info) return info
  const fallback = props.nodes.find(n => n.node_id === d.node_id)
  if (fallback) return { node_id: fallback.node_id, type: fallback.type, title: nodeTitle(fallback), level: 0 }
  return null
}

const entries = computed<TimelineEntry[]>(() => {
  const sorted = [...props.data].sort((a, b) => ts(a) - ts(b))

  // Build tool_call_id → observation map for turn grouping.
  const obsByCallId = new Map<string, DataflowData>()
  if (props.groupTurns) {
    for (const d of sorted) {
      if (d.type !== 'agent.observation') continue
      const meta = (d.metadata as any) || {}
      const callId = meta.tool_call_id
      if (callId) obsByCallId.set(callId, d)
    }
  }
  const consumed = new Set<string>()

  const out: TimelineEntry[] = []
  let i = 0
  while (i < sorted.length) {
    const d = sorted[i]
    if (consumed.has(d.data_id)) { i++; continue }

    const entry: TimelineEntry = {
      dataItem: d,
      nodeInfo: resolveNodeInfo(d),
      isGlobal: !d.node_id,
      isGrouped: false,
    }

    // Yield request/result pairing (unchanged).
    if (d.type === 'node.yield' && i + 1 < sorted.length) {
      const next = sorted[i + 1]
      if (next.type === 'node.yield.result' && next.key === d.key && next.node_id === d.node_id) {
        entry.resultItem = next
        entry.isGrouped = true
        consumed.add(next.data_id)
      }
    }

    // Agent turn grouping: action + its observations (matched by tool_call_id).
    if (props.groupTurns && d.type === 'agent.action') {
      const parsed = tryParse(d.content)
      const calls: any[] = parsed?.tool_calls || []
      const observations: DataflowData[] = []
      for (const call of calls) {
        const obs = call?.id ? obsByCallId.get(call.id) : null
        if (obs && !consumed.has(obs.data_id)) {
          observations.push(obs)
          consumed.add(obs.data_id)
        }
      }
      if (observations.length > 0 || calls.length > 0) {
        entry.isTurn = true
        entry.observations = observations
      }
    }

    out.push(entry)
    i++
  }
  return out
})

const filtered = computed<TimelineEntry[]>(() => {
  let list = entries.value
  if (props.nodeFilter && props.nodeFilter !== 'all') {
    list = list.filter(e => e.dataItem.node_id === props.nodeFilter)
  }
  if (!props.showInternal) {
    const internalTypes = new Set(['node.yield', 'node.result', 'node.yield.result', 'node.input'])
    list = list.filter(e => {
      if (e.isGrouped && e.dataItem.type === 'node.yield') return false
      return !internalTypes.has(e.dataItem.type)
    })
  }
  return list
})

const expanded = ref<Set<string>>(new Set())
function toggleExpand(id: string) {
  const s = new Set(expanded.value)
  if (s.has(id)) s.delete(id); else s.add(id)
  expanded.value = s
}

function formatDataTitle(d: DataflowData): string {
  const m = d.metadata as any
  if (m?.title) return m.title
  if (d.key && d.content_type === 'dataflow/reference') return d.key
  if (d.key && !isUuid(d.key)) return d.key
  if (d.type) {
    return d.type
      .replace(/\./g, ' ')
      .replace(/\b([a-z])/g, (_, c) => c.toUpperCase())
  }
  return 'Data Item'
}

function isUuid(s: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
}

function shortId(id: string): string {
  if (!id) return ''
  const parts = id.split('-')
  return parts[parts.length - 1]
}

function formatCompactTime(v: any): string {
  if (!v) return ''
  const d = typeof v === 'number' ? new Date(v * 1000) : new Date(v)
  if (!Number.isFinite(d.getTime())) return ''
  const now = new Date()
  const sameDay = d.getDate() === now.getDate() && d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear()
  if (sameDay) return d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false })
  return d.toLocaleString(undefined, { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false })
}

function formatFullDate(v: any): string {
  if (!v) return ''
  const d = typeof v === 'number' ? new Date(v * 1000) : new Date(v)
  return Number.isFinite(d.getTime()) ? d.toLocaleString() : String(v)
}

function typeIcon(type: string, isRef: boolean): string {
  if (isRef) return 'tabler:link'
  if (type.startsWith('agent.action')) return 'tabler:message-bolt'
  if (type.startsWith('agent.observation')) return 'tabler:eye'
  if (type.startsWith('agent.delegation')) return 'tabler:arrow-fork'
  if (type.startsWith('agent.error')) return 'tabler:alert-circle'
  if (type === 'iteration.result') return 'tabler:check'
  if (type === 'iteration.error') return 'tabler:alert-triangle'
  if (type === 'dataflow.input') return 'tabler:cloud-upload'
  if (type === 'dataflow.output') return 'tabler:cloud-download'
  if (type === 'node.input') return 'tabler:arrow-right'
  if (type === 'node.result') return 'tabler:file-check'
  if (type === 'node.yield') return 'tabler:corner-down-right'
  if (type === 'node.yield.result') return 'tabler:corner-down-right-double'
  return 'tabler:database'
}

function typeColor(type: string): string {
  if (type.startsWith('agent.action')) return 'var(--p-success-500)'
  if (type.startsWith('agent.observation')) return 'var(--p-info-500)'
  if (type.startsWith('agent.delegation')) return 'var(--p-warn-500)'
  if (type.startsWith('agent.error')) return 'var(--p-danger-500)'
  if (type === 'iteration.error') return 'var(--p-danger-500)'
  if (type === 'iteration.result') return 'var(--p-info-500)'
  if (type.includes('input')) return 'var(--p-warn-500)'
  if (type.includes('output') || type.includes('result')) return 'var(--p-info-500)'
  if (type.startsWith('node.yield')) return 'var(--p-accent-400)'
  return 'var(--p-text-muted-color)'
}

function nodeTypeIcon(type: string): string {
  if (type.includes('agent')) return 'tabler:robot'
  if (type.includes('parallel')) return 'tabler:arrows-split'
  if (type.includes('cycle')) return 'tabler:refresh'
  if (type.includes('tool')) return 'tabler:tool'
  if (type.includes('func')) return 'tabler:function'
  return 'tabler:circle-dot'
}

function sourceNode(e: TimelineEntry): NodeInfo | null {
  const meta = e.dataItem.metadata as any
  const srcId = meta?.source_node_id
  if (!srcId) return null
  return levelMap.value.get(srcId) || null
}

function iterationNumber(e: TimelineEntry): number | null {
  const meta = e.dataItem.metadata as any
  return typeof meta?.iteration === 'number' ? meta.iteration : null
}

function entryKey(e: TimelineEntry): string {
  return e.dataItem.data_id
}

function turnTitle(e: TimelineEntry): string {
  const parsed = tryParse(e.dataItem.content)
  const iter = (e.dataItem.metadata as any)?.iteration
  if (parsed?.result && typeof parsed.result === 'string' && parsed.result.trim()) {
    const r = parsed.result.replace(/\n+/g, ' ').trim()
    return `Turn ${iter || '?'}: ${r.slice(0, 60)}${r.length > 60 ? '…' : ''}`
  }
  const callCount = parsed?.tool_calls?.length || 0
  return `Turn ${iter || '?'}${callCount ? ` · ${callCount} tool call${callCount === 1 ? '' : 's'}` : ''}`
}
</script>

<template>
  <div class="timeline">
    <template v-if="filtered.length === 0">
      <div class="empty">
        <Icon icon="tabler:timeline-off" class="w-8 h-8" />
        <span>No data items</span>
      </div>
    </template>
    <template v-for="(entry, i) in filtered" :key="entryKey(entry)">
      <div class="entry" :class="{ zebra: i % 2 === 1, expanded: expanded.has(entryKey(entry)), 'new-item': newIds?.has(entryKey(entry)) }"
        :style="{
          paddingLeft: (entry.isGlobal ? 12 : ((entry.nodeInfo?.level || 0) * 18 + 30)) + 'px',
          borderLeftColor: entry.isGlobal ? 'var(--p-surface-300)' : typeColor(entry.dataItem.type),
        }"
      >
        <div class="header" @click="toggleExpand(entryKey(entry))">
          <div class="icon-bubble" :style="{ background: typeColor(entry.dataItem.type) + '20', color: typeColor(entry.dataItem.type) }">
            <Icon :icon="typeIcon(entry.dataItem.type, entry.dataItem.content_type === 'dataflow/reference')" class="w-3.5 h-3.5" />
          </div>

          <span class="title">
            <template v-if="entry.isGrouped">Yield Request/Result</template>
            <template v-else-if="entry.isTurn">{{ turnTitle(entry) }}</template>
            <template v-else>{{ formatDataTitle(entry.dataItem) }}</template>
          </span>

          <span class="time" :title="formatFullDate(entry.dataItem.created_at)">{{ formatCompactTime(entry.dataItem.created_at) }}</span>

          <span v-if="entry.isGrouped" class="type-badge text-accent-400" style="background: color-mix(in srgb, var(--p-accent-400) 15%, transparent)">yield/result</span>
          <span v-else-if="entry.isTurn" class="type-badge text-success-500" style="background: color-mix(in srgb, var(--p-success-500) 15%, transparent)">
            turn · {{ entry.observations?.length || 0 }} obs
          </span>
          <span v-else class="type-badge" :style="{ background: `color-mix(in srgb, ${typeColor(entry.dataItem.type)} 18%, transparent)`, color: typeColor(entry.dataItem.type) }">
            {{ entry.dataItem.type }}
          </span>

          <span v-if="iterationNumber(entry) !== null" class="iter-badge">#{{ iterationNumber(entry) }}</span>

          <button v-if="entry.nodeInfo" class="node-badge" @click.stop="emit('selectNode', entry.nodeInfo.node_id)">
            <Icon :icon="nodeTypeIcon(entry.nodeInfo.type)" class="w-3 h-3" />
            <span class="node-title">{{ entry.nodeInfo.title }}</span>
            <span class="node-short">{{ shortId(entry.nodeInfo.node_id) }}</span>
          </button>

          <span v-if="entry.isGlobal" class="global-badge"><Icon icon="tabler:world" class="w-3 h-3" /> Global</span>

          <button v-if="sourceNode(entry)" class="src-badge" @click.stop="emit('selectNode', sourceNode(entry)!.node_id)" :title="'Source: ' + sourceNode(entry)!.title">
            <Icon icon="tabler:arrow-back-up" class="w-3 h-3" />
            from {{ sourceNode(entry)!.title }}
          </button>

          <Icon :icon="expanded.has(entryKey(entry)) ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="chev" />
        </div>

        <div v-if="expanded.has(entryKey(entry))" class="body">
          <template v-if="entry.isGrouped">
            <div class="sub-block">
              <div class="sub-label"><Icon icon="tabler:corner-down-right" class="w-3 h-3" /> Yield Request</div>
              <DataRenderer :data="entry.dataItem" />
            </div>
            <div class="sub-block">
              <div class="sub-label"><Icon icon="tabler:corner-down-right-double" class="w-3 h-3" /> Yield Result</div>
              <DataRenderer :data="entry.resultItem!" />
            </div>
          </template>
          <template v-else-if="entry.isTurn">
            <div class="sub-block">
              <div class="sub-label"><Icon icon="tabler:message-bolt" class="w-3 h-3" /> Agent Action</div>
              <DataRenderer :data="entry.dataItem" />
            </div>
            <div v-for="obs in entry.observations" :key="obs.data_id" class="sub-block obs">
              <div class="sub-label">
                <Icon icon="tabler:eye" class="w-3 h-3" />
                Observation
                <span v-if="(obs.metadata as any)?.tool_name" class="tool-tag">{{ (obs.metadata as any).tool_name }}</span>
                <span v-if="(obs.metadata as any)?.is_error" class="err-tag">error</span>
              </div>
              <DataRenderer :data="obs" />
            </div>
          </template>
          <template v-else>
            <DataRenderer :data="entry.dataItem" />
            <div v-if="entry.dataItem.metadata && Object.keys(entry.dataItem.metadata as any).length" class="meta-block">
              <div class="sub-label">Metadata</div>
              <JsonBlock :data="entry.dataItem.metadata" font-size="10px" />
            </div>
            <div class="ids">
              <span class="id-label">data_id</span>
              <span class="id-val">{{ entry.dataItem.data_id }}</span>
              <template v-if="entry.dataItem.key">
                <span class="id-label">key</span>
                <span class="id-val">{{ entry.dataItem.key }}</span>
              </template>
              <template v-if="entry.dataItem.discriminator">
                <span class="id-label">discriminator</span>
                <span class="id-val">{{ entry.dataItem.discriminator }}</span>
              </template>
              <span class="id-label">content_type</span>
              <span class="id-val">{{ entry.dataItem.content_type }}</span>
            </div>
          </template>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.timeline { display: flex; flex-direction: column; }
.empty {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  padding: 48px 24px; font-size: 12px; color: var(--p-text-muted-color);
}

.entry {
  border-top: 1px solid var(--p-content-border-color);
  border-left: 3px solid transparent;
  padding-right: 16px;
  transition: background 0.1s;
}
.entry:first-child { border-top: 0; }
.entry.zebra { background: color-mix(in srgb, var(--p-surface-50) 50%, transparent); }
.entry.expanded { background: color-mix(in srgb, var(--p-surface-100) 70%, transparent); }
.entry.new-item { animation: kp-newin 0.55s cubic-bezier(0.22, 0.9, 0.32, 1.2) forwards, kp-newglow 2.4s ease-out 0.4s forwards; }
@keyframes kp-newin {
  from { opacity: 0; transform: translateY(-6px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes kp-newglow {
  0% { box-shadow: inset 3px 0 0 0 var(--p-primary-color), 0 0 0 0 color-mix(in srgb, var(--p-primary-color) 25%, transparent); background: color-mix(in srgb, var(--p-primary-color) 8%, transparent); }
  100% { box-shadow: inset 0 0 0 0 transparent, 0 0 0 0 transparent; }
}

.header {
  display: flex; align-items: center;
  column-gap: 9px;
  row-gap: 3px;
  padding: 5px 0;
  cursor: pointer;
  min-height: 26px;
  flex-wrap: wrap;
}
.header:hover { background: color-mix(in srgb, var(--p-surface-100) 80%, transparent); }

.icon-bubble {
  width: 20px; height: 20px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 50%;
  flex-shrink: 0;
}

.title {
  font-size: 12px; font-weight: 600;
  color: var(--p-text-color);
  flex-shrink: 0;
  max-width: 280px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  letter-spacing: 0.01em;
}

.time {
  font-size: 10px; font-family: ui-monospace, monospace;
  color: var(--p-text-muted-color);
  flex-shrink: 0;
  padding: 0 2px;
  opacity: 0.75;
}

.type-badge {
  font-size: 9px; font-weight: 700;
  padding: 2px 7px; border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  flex-shrink: 0;
  font-family: ui-monospace, monospace;
}

.iter-badge {
  font-size: 9px; font-family: ui-monospace, monospace; font-weight: 700;
  padding: 2px 6px; border-radius: 4px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  flex-shrink: 0;
}

.node-badge {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 2px 8px; border-radius: 4px;
  background: color-mix(in srgb, var(--p-primary-color) 10%, transparent);
  color: var(--p-primary-color);
  font-size: 10px; font-weight: 500;
  border: 1px solid color-mix(in srgb, var(--p-primary-color) 25%, transparent);
  cursor: pointer;
  flex-shrink: 0;
  transition: all 0.12s;
}
.node-badge:hover {
  background: color-mix(in srgb, var(--p-primary-color) 20%, transparent);
  border-color: color-mix(in srgb, var(--p-primary-color) 40%, transparent);
}
.node-title { max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.node-short { font-family: ui-monospace, monospace; opacity: 0.55; font-size: 9px; }

.global-badge {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 7px; border-radius: 4px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  font-size: 9px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  flex-shrink: 0;
}

.src-badge {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 4px;
  background: color-mix(in srgb, var(--p-accent-400) 10%, transparent);
  color: var(--p-accent-400);
  border: 1px solid color-mix(in srgb, var(--p-accent-400) 25%, transparent);
  font-size: 10px;
  cursor: pointer;
  flex-shrink: 0;
  transition: all 0.12s;
}
.src-badge:hover { background: color-mix(in srgb, var(--p-accent-400) 20%, transparent); border-color: color-mix(in srgb, var(--p-accent-400) 40%, transparent); }

.chev {
  width: 16px; height: 16px;
  color: var(--p-text-muted-color);
  margin-left: auto;
  flex-shrink: 0;
  opacity: 0.6;
  transition: opacity 0.1s;
}
.header:hover .chev { opacity: 1; }

.body {
  padding: 12px 16px 16px 28px;
  display: flex; flex-direction: column; gap: 12px;
  border-top: 1px dashed var(--p-surface-200);
  margin-top: 2px;
  background: color-mix(in srgb, var(--p-surface-50) 40%, transparent);
}

.sub-block {
  border-left: 3px solid color-mix(in srgb, var(--p-primary-color) 30%, transparent);
  padding: 6px 0 6px 12px;
}
.sub-block.obs {
  border-left-color: color-mix(in srgb, var(--p-info-500) 50%, transparent);
}
.sub-label {
  display: inline-flex; align-items: center; gap: 5px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--p-text-muted-color);
  margin-bottom: 6px;
}
.tool-tag {
  font-size: 9px; font-weight: 600;
  padding: 1px 5px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  color: var(--p-info-500);
  letter-spacing: 0;
  text-transform: none;
  font-family: ui-monospace, monospace;
}
.err-tag {
  font-size: 9px; font-weight: 700;
  padding: 1px 5px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-danger-500) 12%, transparent);
  color: var(--p-danger-500);
  letter-spacing: 0.03em;
}

.meta-block { padding-top: 8px; border-top: 1px dashed var(--p-surface-200); }

.ids {
  display: flex; flex-wrap: wrap;
  column-gap: 14px; row-gap: 4px;
  font-size: 10px;
  padding: 8px 0 0;
  border-top: 1px dashed var(--p-surface-200);
}
.id-label {
  color: var(--p-text-muted-color);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-right: 4px;
}
.id-val {
  color: var(--p-text-color);
  font-family: ui-monospace, monospace;
  word-break: break-all;
}
</style>
