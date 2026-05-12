<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import type { DataflowNode, DataflowData } from '../../api/dataflows'
import { statusColor, statusIcon } from '../../api/dataflows'
import { nodeTitle, nodeIcon, getNodeTokens, fmtTokens, getToolCalls, getStatusMessage, getIteration, getParallelProgress, isParallelNode } from './node-utils'
import JsonBlock from '../shared/JsonBlock.vue'

const props = defineProps<{
  nodes: DataflowNode[]
  data: DataflowData[]
  typeFilter: string
  selectedNodeId: string | null
  newIds?: Set<string>
}>()

const emit = defineEmits<{
  selectNode: [id: string]
  selectData: [id: string]
  jumpToTimeline: [nodeId: string]
}>()

function ts(x: { created_at: any }): number {
  const v = x.created_at
  if (typeof v === 'number') return v
  const t = new Date(v).getTime()
  return Number.isFinite(t) ? t : 0
}

interface FlatNode extends DataflowNode {
  level: number
  hasChildren: boolean
}

const flatNodes = computed<FlatNode[]>(() => {
  const nodeMap = new Map<string, FlatNode & { _children: FlatNode[] }>()
  for (const n of props.nodes) {
    if (n.status === 'template') continue
    nodeMap.set(n.node_id, { ...n, level: 0, hasChildren: false, _children: [] as any })
  }
  const roots: (FlatNode & { _children: FlatNode[] })[] = []
  for (const [, entry] of nodeMap) {
    const pid = entry.parent_node_id
    if (pid && nodeMap.has(pid)) {
      nodeMap.get(pid)!._children.push(entry)
      nodeMap.get(pid)!.hasChildren = true
    } else {
      roots.push(entry)
    }
  }
  const flat: FlatNode[] = []
  const walk = (node: FlatNode & { _children: FlatNode[] }, level: number) => {
    node.level = level
    flat.push(node)
    node._children.sort((a, b) => ts(a) - ts(b))
    for (const c of node._children) walk(c as any, level + 1)
  }
  roots.sort((a, b) => ts(a) - ts(b))
  for (const r of roots) walk(r, 0)
  return flat
})

const filtered = computed<FlatNode[]>(() => {
  if (!props.typeFilter) return flatNodes.value
  return flatNodes.value.filter(n => (n.type.split(':').pop() || n.type).includes(props.typeFilter))
})

const expanded = ref<Set<string>>(new Set())
function toggleExpand(id: string) {
  const s = new Set(expanded.value)
  if (s.has(id)) s.delete(id); else s.add(id)
  expanded.value = s
}

function nodeDataItems(nodeId: string): DataflowData[] {
  return props.data.filter(d => d.node_id === nodeId).sort((a, b) => ts(a) - ts(b))
}

function duration(n: DataflowNode): string | null {
  if (!n.created_at || !n.updated_at) return null
  const start = typeof n.created_at === 'number' ? n.created_at : new Date(n.created_at).getTime() / 1000
  const end = typeof n.updated_at === 'number' ? n.updated_at : new Date(n.updated_at).getTime() / 1000
  const sec = end - start
  if (sec < 0 || n.status === 'running' || n.status === 'pending') return null
  if (sec < 1) return '<1s'
  if (sec < 60) return Math.round(sec) + 's'
  if (sec < 3600) return Math.floor(sec / 60) + 'm ' + Math.round(sec % 60) + 's'
  return Math.floor(sec / 3600) + 'h ' + Math.floor((sec % 3600) / 60) + 'm'
}

function shortId(id: string): string {
  return id.split('-').pop() || id
}

function dataTypeColor(type: string): string {
  if (type.startsWith('agent.action')) return 'var(--p-success-500)'
  if (type.startsWith('agent.observation')) return 'var(--p-info-500)'
  if (type.startsWith('agent.delegation')) return 'var(--p-accent-400)'
  if (type.startsWith('agent.error')) return 'var(--p-danger-500)'
  if (type === 'iteration.error') return 'var(--p-danger-500)'
  if (type === 'iteration.result') return 'var(--p-info-500)'
  if (type.includes('output') || type.includes('result')) return 'var(--p-info-500)'
  if (type.includes('input')) return 'var(--p-warn-500)'
  if (type.startsWith('node.yield')) return 'var(--p-accent-400)'
  return 'var(--p-text-muted-color)'
}
</script>

<template>
  <div class="list">
    <template v-for="node in filtered" :key="node.node_id">
      <div class="row" :data-node-id="node.node_id" :class="{ sel: selectedNodeId === node.node_id, exp: expanded.has(node.node_id), 'new-item': newIds?.has(node.node_id) }">
        <div class="header" @click="toggleExpand(node.node_id)">
          <!-- Indent rail -->
          <div class="rail" :style="{ width: (node.level * 18 + 8) + 'px' }">
            <div v-if="node.level > 0" class="rail-v" :style="{ left: ((node.level - 1) * 18 + 9) + 'px' }"></div>
            <div v-if="node.level > 0" class="rail-h" :style="{ left: ((node.level - 1) * 18 + 9) + 'px' }"></div>
          </div>

          <!-- Icon -->
          <div class="icon-box" :style="{ color: statusColor(node.status) }">
            <Icon :icon="nodeIcon(node)" class="w-4 h-4"
              :class="{ 'animate-pulse': node.status === 'running' }" />
          </div>

          <!-- Title + badges -->
          <div class="info">
            <div class="title-row">
              <span class="title">{{ nodeTitle(node) }}</span>
              <span class="status-pill"
                :style="{ background: statusColor(node.status) + '18', color: statusColor(node.status) }">
                <Icon :icon="statusIcon(node.status)" class="w-3 h-3" />
                {{ node.status }}
              </span>
            </div>
            <div class="meta-row">
              <span class="type">{{ node.type.split(':').pop() || node.type }}</span>
              <span class="short">{{ shortId(node.node_id) }}</span>
              <template v-if="getIteration(node)">
                <span class="iter">iter {{ getIteration(node) }}</span>
              </template>
              <template v-if="node.hasChildren && isParallelNode(node)">
                <span class="kids">{{ getParallelProgress(node, nodes.filter(n => n.parent_node_id === node.node_id)).completed }}/{{ getParallelProgress(node, nodes.filter(n => n.parent_node_id === node.node_id)).total }}</span>
              </template>
              <span v-if="duration(node)" class="dur">{{ duration(node) }}</span>
              <span v-if="getNodeTokens(node)" class="tok flex items-center gap-2">
                <span style="color: var(--p-accent-500)" title="Prompt tokens">P&nbsp;{{ fmtTokens(getNodeTokens(node)!.prompt) }}</span>
                <span style="color: var(--p-accent-400)" title="Completion tokens">C&nbsp;{{ fmtTokens(getNodeTokens(node)!.completion) }}</span>
              </span>
              <template v-if="getToolCalls(node)">
                <span class="tool-count">{{ getToolCalls(node) }} tools</span>
              </template>
            </div>
          </div>

          <button class="timeline-btn" @click.stop="emit('jumpToTimeline', node.node_id)" title="Show in timeline">
            <Icon icon="tabler:timeline" class="w-3.5 h-3.5" />
          </button>
          <Icon :icon="expanded.has(node.node_id) ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="chev" />
        </div>

        <div v-if="expanded.has(node.node_id)" class="body" :style="{ paddingLeft: (node.level * 18 + 48) + 'px' }">
          <div class="ids">
            <span class="id-label">node_id</span>
            <span class="id-val">{{ node.node_id }}</span>
            <template v-if="node.parent_node_id">
              <span class="id-label">parent_id</span>
              <span class="id-val">{{ node.parent_node_id }}</span>
            </template>
            <span class="id-label">type</span>
            <span class="id-val">{{ node.type }}</span>
          </div>

          <div v-if="getStatusMessage(node)" class="msg">{{ getStatusMessage(node) }}</div>

          <div v-if="node.config && Object.keys(node.config as any).length" class="section">
            <div class="sub-label">Config</div>
            <JsonBlock :data="node.config" font-size="10px" />
          </div>

          <div v-if="node.metadata && Object.keys(node.metadata as any).length" class="section">
            <div class="sub-label">Metadata</div>
            <JsonBlock :data="node.metadata" font-size="10px" />
          </div>

          <div v-if="nodeDataItems(node.node_id).length" class="section">
            <div class="sub-label">Linked Data ({{ nodeDataItems(node.node_id).length }})</div>
            <div class="data-cards">
              <button v-for="d in nodeDataItems(node.node_id)" :key="d.data_id" class="data-card" @click="emit('selectData', d.data_id)">
                <span class="data-type" :style="{ color: dataTypeColor(d.type) }">{{ d.type }}</span>
                <span v-if="d.discriminator" class="data-disc">{{ d.discriminator }}</span>
                <span v-if="d.key" class="data-key">{{ d.key }}</span>
                <span class="data-short">{{ shortId(d.data_id) }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </template>
    <div v-if="filtered.length === 0" class="empty">
      <Icon icon="tabler:sitemap-off" class="w-8 h-8" />
      <span>No nodes</span>
    </div>
  </div>
</template>

<style scoped>
.list { display: flex; flex-direction: column; }
.empty {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  padding: 48px 24px; font-size: 12px; color: var(--p-text-muted-color);
}

.row {
  border-top: 1px solid var(--p-content-border-color);
  background: var(--p-content-background);
  transition: background 0.1s;
}
.row:first-child { border-top: 0; }
.row.sel { background: var(--p-surface-100); }
.row.exp { background: color-mix(in srgb, var(--p-surface-100) 50%, transparent); }
.row.new-item { animation: kp-newin 0.55s cubic-bezier(0.22, 0.9, 0.32, 1.2) forwards, kp-newglow 2.4s ease-out 0.4s forwards; }
@keyframes kp-newin {
  from { opacity: 0; transform: translateY(-6px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes kp-newglow {
  0% { box-shadow: inset 3px 0 0 0 var(--p-primary-color); background: color-mix(in srgb, var(--p-primary-color) 8%, transparent); }
  100% { box-shadow: inset 0 0 0 0 transparent; }
}

.header {
  display: flex; align-items: center;
  column-gap: 12px;
  padding: 10px 16px;
  cursor: pointer;
  min-height: 48px;
}
.header:hover { background: color-mix(in srgb, var(--p-surface-100) 80%, transparent); }

.rail {
  position: relative;
  height: 36px;
  flex-shrink: 0;
}
.rail-v {
  position: absolute;
  top: -18px; bottom: 18px;
  width: 1px;
  background: var(--p-surface-300);
}
.rail-h {
  position: absolute;
  top: 17px;
  width: 12px;
  height: 1px;
  background: var(--p-surface-300);
}

.icon-box {
  width: 32px; height: 32px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 6px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  flex-shrink: 0;
}

.info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.title-row { display: flex; align-items: center; column-gap: 10px; flex-wrap: wrap; row-gap: 3px; }
.title {
  font-size: 13px; font-weight: 600;
  color: var(--p-text-color);
  letter-spacing: 0.01em;
}
.status-pill {
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 2px 7px; border-radius: 4px;
}

.meta-row {
  display: flex; align-items: center;
  flex-wrap: wrap;
  column-gap: 10px; row-gap: 3px;
  font-size: 10px;
  color: var(--p-text-muted-color);
}
.meta-row > * {
  display: inline-flex; align-items: center;
}
.meta-row > *:not(:last-child)::after {
  content: '';
  width: 3px; height: 3px;
  border-radius: 50%;
  background: var(--p-surface-300);
  margin-left: 10px;
}
.type {
  font-family: ui-monospace, monospace;
  font-weight: 600;
  color: var(--p-text-color);
}
.short {
  font-family: ui-monospace, monospace;
  opacity: 0.55;
  font-size: 9px;
}
.iter {
  padding: 1px 6px; border-radius: 3px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  font-family: ui-monospace, monospace;
  font-weight: 600;
  color: var(--p-text-muted-color);
}
.kids, .dur, .tool-count {
  font-family: ui-monospace, monospace;
}
.tok {
  font-family: ui-monospace, monospace;
  font-size: 9px;
}

.timeline-btn {
  padding: 5px 7px;
  background: transparent;
  border: 1px solid transparent;
  cursor: pointer;
  color: var(--p-text-muted-color);
  border-radius: 4px;
  flex-shrink: 0;
  transition: all 0.12s;
}
.timeline-btn:hover {
  background: color-mix(in srgb, var(--p-primary-color) 10%, transparent);
  color: var(--p-primary-color);
  border-color: color-mix(in srgb, var(--p-primary-color) 25%, transparent);
}
.chev {
  width: 16px; height: 16px;
  color: var(--p-text-muted-color);
  flex-shrink: 0;
  opacity: 0.5;
  transition: opacity 0.1s;
}
.header:hover .chev { opacity: 1; }

.body {
  padding: 14px 20px 18px;
  display: flex; flex-direction: column; gap: 14px;
  border-top: 1px dashed var(--p-surface-200);
  background: color-mix(in srgb, var(--p-surface-50) 50%, transparent);
}

.ids {
  display: flex; flex-wrap: wrap;
  column-gap: 16px; row-gap: 4px;
  font-size: 10px;
  padding-bottom: 6px;
  border-bottom: 1px dashed var(--p-surface-200);
}
.id-label {
  color: var(--p-text-muted-color);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-right: 5px;
}
.id-val {
  color: var(--p-text-color);
  font-family: ui-monospace, monospace;
  word-break: break-all;
}

.msg {
  font-size: 12px;
  color: var(--p-text-color);
  font-style: italic;
  padding: 6px 10px;
  background: color-mix(in srgb, var(--p-primary-color) 6%, transparent);
  border-left: 3px solid color-mix(in srgb, var(--p-primary-color) 40%, transparent);
  border-radius: 3px;
}

.section { display: flex; flex-direction: column; gap: 6px; }
.sub-label {
  font-size: 10px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--p-text-muted-color);
}

.data-cards { display: flex; flex-direction: column; gap: 5px; }
.data-card {
  display: flex; align-items: center;
  column-gap: 12px;
  padding: 6px 10px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  font-size: 11px;
  cursor: pointer;
  text-align: left;
  transition: all 0.12s;
}
.data-card:hover {
  background: var(--p-surface-100);
  border-color: var(--p-surface-300);
}
.data-type {
  font-weight: 700;
  font-family: ui-monospace, monospace;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}
.data-disc {
  color: var(--p-text-muted-color);
  font-family: ui-monospace, monospace;
  font-size: 10px;
}
.data-key {
  color: var(--p-text-color);
  font-family: ui-monospace, monospace;
  font-size: 10px;
}
.data-short {
  color: var(--p-text-muted-color);
  font-family: ui-monospace, monospace;
  margin-left: auto;
  opacity: 0.55;
  font-size: 9px;
}
</style>
