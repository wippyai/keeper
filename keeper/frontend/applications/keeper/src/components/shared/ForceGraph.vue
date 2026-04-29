<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch, shallowRef } from 'vue'
import { forceSimulation, forceLink, forceManyBody, forceCenter, forceCollide, type SimulationNodeDatum, type SimulationLinkDatum } from 'd3-force'

interface GNode extends SimulationNodeDatum {
  id: string
  label: string
  kind?: string
  type: string
}

interface GEdge extends SimulationLinkDatum<GNode> {
  source: string | GNode
  target: string | GNode
  type?: string
}

const props = defineProps<{
  nodes: Array<{ id: string; label: string; kind?: string; type: string }>
  edges: Array<{ source: string; target: string; type?: string }>
  selectedId?: string | null
}>()

const emit = defineEmits<{
  select: [id: string]
}>()

const container = ref<HTMLElement | null>(null)
const canvasEl = ref<HTMLCanvasElement | null>(null)
let ctx: CanvasRenderingContext2D | null = null
let sim: ReturnType<typeof forceSimulation<GNode, GEdge>> | null = null
let animFrame = 0
let simNodes: GNode[] = []
let simEdges: GEdge[] = []
let nodeMap = new Map<string, GNode>()
let dpr = 1
let width = 800
let height = 600

let transform = { x: 0, y: 0, k: 1 }
let dragNode: GNode | null = null
let hoveredNode: GNode | null = null
let panning = false
let panStart = { x: 0, y: 0, tx: 0, ty: 0 }
let didDrag = false

const BASE_R = 10
function nr() { return Math.max(6, BASE_R * Math.sqrt(transform.k)) }
const kindColorCache = new Map<string, string>()

interface ThemeColors {
  muted: string
  text: string
  textStrong: string
  success: string
  info: string
  warn: string
  danger: string
  accent: string
  edge: string
  edgeArrow: string
}
let themeCache: ThemeColors | null = null
let themeObs: MutationObserver | null = null
function themeColors(): ThemeColors {
  if (themeCache) return themeCache
  const cs = getComputedStyle(document.documentElement)
  const v = (name: string, fallback: string) => (cs.getPropertyValue(name).trim() || fallback)
  themeCache = {
    muted: v('--p-text-muted-color', '#71717a'),
    text: v('--p-text-color', '#a1a1aa'),
    textStrong: v('--p-surface-0', '#fff'),
    success: v('--p-success-500', '#22c55e'),
    info: v('--p-info-500', '#3b82f6'),
    warn: v('--p-warn-500', '#f59e0b'),
    danger: v('--p-danger-500', '#ef4444'),
    accent: v('--p-accent-500', '#a78bfa'),
    edge: v('--p-surface-600', '#555'),
    edgeArrow: v('--p-surface-500', '#666'),
  }
  return themeCache
}

function hashStr(s: string): number {
  let h1 = 0xdeadbeef, h2 = 0x41c6ce57
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i)
    h1 = Math.imul(h1 ^ c, 2654435761)
    h2 = Math.imul(h2 ^ c, 1597334677)
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507)
  h2 = Math.imul(h2 ^ (h2 >>> 13), 3266489909)
  return 4294967296 * (2097151 & h2) + (h1 >>> 0)
}

function kindColor(kind?: string): string {
  if (!kind) return themeColors().muted
  if (kindColorCache.has(kind)) return kindColorCache.get(kind)!
  const h = hashStr(kind)
  const c = `hsl(${h % 360}, ${65 + ((h >> 10) % 25)}%, ${60 + ((h >> 20) % 15)}%)`
  kindColorCache.set(kind, c)
  return c
}

function nodeColor(n: GNode): string {
  if (n.type === 'entry' && n.kind) return kindColor(n.kind)
  if (n.type === 'dependency') return themeColors().success
  return themeColors().muted
}

function buildSim() {
  if (sim) sim.stop()
  cancelAnimationFrame(animFrame)

  simNodes = props.nodes.map(n => ({ ...n } as GNode))
  nodeMap = new Map(simNodes.map(n => [n.id, n]))
  simEdges = props.edges
    .filter(e => nodeMap.has(e.source as string) && nodeMap.has(e.target as string))
    .map(e => ({ source: e.source, target: e.target, type: e.type }))

  const n = simNodes.length
  const charge = n > 300 ? -300 : n > 100 ? -200 : -150
  const linkDist = n > 300 ? 120 : n > 100 ? 100 : 80

  sim = forceSimulation<GNode, GEdge>(simNodes)
    .force('link', forceLink<GNode, GEdge>(simEdges).id(d => d.id).distance(linkDist).strength(0.15))
    .force('charge', forceManyBody().strength(charge))
    .force('center', forceCenter(width / 2, height / 2))
    .force('collide', forceCollide<GNode>().radius(BASE_R + 8))
    .alphaDecay(0.015)
    .on('tick', () => {})

  transform = { x: 0, y: 0, k: 1 }
  render()
}

function render() {
  const cvs = canvasEl.value
  if (!cvs || !ctx) return

  ctx.clearRect(0, 0, width * dpr, height * dpr)
  ctx.save()
  ctx.scale(dpr, dpr)
  ctx.translate(transform.x, transform.y)
  ctx.scale(transform.k, transform.k)

  // Edges with arrows
  for (const e of simEdges) {
    const s = e.source as GNode, t = e.target as GNode
    if (s.x == null || t.x == null) continue
    const dx = t.x - s.x!, dy = t.y! - s.y!
    const dist = Math.sqrt(dx * dx + dy * dy)
    if (dist < 1) continue
    const ux = dx / dist, uy = dy / dist

    const tc = themeColors()
    ctx.beginPath()
    ctx.moveTo(s.x! + ux * nr(), s.y! + uy * nr())
    ctx.lineTo(t.x! - ux * (nr() + 5), t.y! - uy * (nr() + 5))
    ctx.strokeStyle = tc.edge
    ctx.lineWidth = 1
    ctx.stroke()

    const ex = t.x! - ux * (nr() + 5), ey = t.y! - uy * (nr() + 5)
    const a = Math.atan2(dy, dx), as2 = 4
    ctx.fillStyle = tc.edgeArrow
    ctx.beginPath()
    ctx.moveTo(ex + ux * as2, ey + uy * as2)
    ctx.lineTo(ex + Math.cos(a + Math.PI * 5 / 6) * as2, ey + Math.sin(a + Math.PI * 5 / 6) * as2)
    ctx.lineTo(ex + Math.cos(a - Math.PI * 5 / 6) * as2, ey + Math.sin(a - Math.PI * 5 / 6) * as2)
    ctx.closePath(); ctx.fill()
  }

  // Nodes
  const fs = Math.max(7, 10 / Math.sqrt(transform.k))
  const kfs = Math.max(5, 8 / Math.sqrt(transform.k))

  for (const n of simNodes) {
    if (n.x == null) continue
    const isH = hoveredNode?.id === n.id
    const isSel = props.selectedId === n.id
    const r = isH ? nr() + 2 : nr()

    ctx.beginPath()
    ctx.arc(n.x, n.y!, r, 0, Math.PI * 2)
    ctx.fillStyle = nodeColor(n)
    ctx.globalAlpha = isH || isSel ? 1 : 0.9
    ctx.fill()
    ctx.globalAlpha = 1

    const tc = themeColors()
    if (isSel) {
      ctx.strokeStyle = tc.warn
      ctx.lineWidth = 2
      ctx.stroke()
    } else if (isH) {
      ctx.strokeStyle = tc.textStrong
      ctx.lineWidth = 1.5
      ctx.stroke()
    }

    // Labels: always show name, show kind on hover or when zoomed
    const showLabel = isH || isSel || transform.k > 0.4
    const showKind = isH || isSel || transform.k > 0.8

    if (showLabel) {
      ctx.fillStyle = isH || isSel ? tc.textStrong : tc.text
      ctx.font = `${fs}px ui-monospace, monospace`
      ctx.textAlign = 'center'
      ctx.globalAlpha = isH || isSel ? 1 : Math.min(1, (transform.k - 0.3) * 3)
      ctx.fillText(n.label, n.x, n.y! + r + 12)
      ctx.globalAlpha = 1
    }

    if (showKind && n.kind) {
      ctx.fillStyle = isH || isSel ? tc.text : tc.muted
      ctx.font = `${kfs}px ui-monospace, monospace`
      ctx.textAlign = 'center'
      ctx.globalAlpha = isH || isSel ? 1 : Math.min(1, (transform.k - 0.6) * 3)
      ctx.fillText(n.kind, n.x, n.y! + r + 22)
      ctx.globalAlpha = 1
    }
  }

  ctx.restore()
  animFrame = requestAnimationFrame(render)
}

function screenToWorld(sx: number, sy: number): [number, number] {
  return [(sx - transform.x) / transform.k, (sy - transform.y) / transform.k]
}

function findNode(sx: number, sy: number): GNode | null {
  const [wx, wy] = screenToWorld(sx, sy)
  for (let i = simNodes.length - 1; i >= 0; i--) {
    const n = simNodes[i]
    if (n.x == null) continue
    const dx = n.x - wx, dy = n.y! - wy
    if (dx * dx + dy * dy < (nr() + 3) * (nr() + 3)) return n
  }
  return null
}

function onDown(e: MouseEvent) {
  const rect = canvasEl.value!.getBoundingClientRect()
  const sx = e.clientX - rect.left, sy = e.clientY - rect.top
  const node = findNode(sx, sy)
  if (node) {
    dragNode = node
    dragNode.fx = dragNode.x
    dragNode.fy = dragNode.y
    didDrag = false
    sim?.alphaTarget(0.3).restart()
  } else {
    panning = true
    panStart = { x: e.clientX, y: e.clientY, tx: transform.x, ty: transform.y }
  }
}

function onMove(e: MouseEvent) {
  const rect = canvasEl.value!.getBoundingClientRect()
  const sx = e.clientX - rect.left, sy = e.clientY - rect.top

  if (dragNode) {
    const [wx, wy] = screenToWorld(sx, sy)
    const dx = wx - (dragNode.fx || 0), dy = wy - (dragNode.fy || 0)
    if (dx * dx + dy * dy > 4) didDrag = true
    dragNode.fx = wx; dragNode.fy = wy
  } else if (panning) {
    transform.x = panStart.tx + (e.clientX - panStart.x)
    transform.y = panStart.ty + (e.clientY - panStart.y)
  } else {
    const prev = hoveredNode
    hoveredNode = findNode(sx, sy)
    if (hoveredNode !== prev) canvasEl.value!.style.cursor = hoveredNode ? 'pointer' : 'grab'
  }
}

function onUp(e: MouseEvent) {
  if (dragNode) {
    if (!didDrag) emit('select', dragNode.id)
    dragNode.fx = null; dragNode.fy = null; dragNode = null
    sim?.alphaTarget(0)
  }
  panning = false
}

function onWheel(e: WheelEvent) {
  e.preventDefault()
  const rect = canvasEl.value!.getBoundingClientRect()
  const sx = e.clientX - rect.left, sy = e.clientY - rect.top
  const factor = e.deltaY > 0 ? 0.9 : 1.1
  const newK = Math.max(0.05, Math.min(5, transform.k * factor))
  transform.x = sx - (sx - transform.x) * (newK / transform.k)
  transform.y = sy - (sy - transform.y) * (newK / transform.k)
  transform.k = newK
}

function fitToView() {
  if (simNodes.length === 0) return
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
  for (const n of simNodes) {
    if (n.x == null) continue
    minX = Math.min(minX, n.x); maxX = Math.max(maxX, n.x)
    minY = Math.min(minY, n.y!); maxY = Math.max(maxY, n.y!)
  }
  const gw = maxX - minX + 100, gh = maxY - minY + 100
  const k = Math.max(0.05, Math.min(Math.min(width / gw, height / gh), 1.5))
  const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
  transform.k = k
  transform.x = width / 2 - cx * k
  transform.y = height / 2 - cy * k
}

let resizeObs: ResizeObserver | null = null

function updateSize() {
  if (!container.value || !canvasEl.value) return
  const r = container.value.getBoundingClientRect()
  if (r.width === 0 || r.height === 0) return
  const wasZero = width === 0 || height === 0
  width = r.width; height = r.height
  canvasEl.value.width = width * dpr; canvasEl.value.height = height * dpr
  if (wasZero && simNodes.length > 0) {
    fitToView()
  }
}

watch(() => [props.nodes, props.edges], () => {
  if (props.nodes.length > 0) buildSim()
}, { deep: true })

onMounted(() => {
  dpr = window.devicePixelRatio || 1
  updateSize()
  ctx = canvasEl.value!.getContext('2d')
  resizeObs = new ResizeObserver(updateSize)
  resizeObs.observe(container.value!)
  themeColors()
  themeObs = new MutationObserver(() => { themeCache = null; kindColorCache.clear() })
  themeObs.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme', 'class'] })
  if (props.nodes.length > 0) buildSim()
})

onBeforeUnmount(() => {
  if (sim) sim.stop()
  cancelAnimationFrame(animFrame)
  resizeObs?.disconnect()
  themeObs?.disconnect()
})
</script>

<template>
  <div ref="container" class="graph-wrap">
    <canvas ref="canvasEl" :style="{ width: width + 'px', height: height + 'px' }"
      @mousedown="onDown" @mousemove="onMove" @mouseup="onUp" @mouseleave="onUp($event)" @wheel="onWheel"
    ></canvas>
    <div class="g-ctrl">
      <button @click="transform.k = Math.min(5, transform.k * 1.2)">+</button>
      <span class="g-zpct">{{ Math.round(transform.k * 100) }}%</span>
      <button @click="transform.k = Math.max(0.05, transform.k / 1.2)">-</button>
      <button @click="fitToView()">FIT</button>
    </div>
    <div class="g-stats">{{ simNodes.length }} nodes / {{ simEdges.length }} edges</div>
  </div>
</template>

<style scoped>
.graph-wrap { width: 100%; height: 100%; position: relative; background: var(--p-surface-50); overflow: hidden; }
.graph-wrap canvas { display: block; cursor: grab; }
.g-ctrl { position: absolute; top: 8px; right: 8px; display: flex; flex-direction: column; gap: 2px; }
.g-ctrl button { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; background: color-mix(in srgb, var(--p-surface-100) 80%, transparent); border: none; border-radius: 4px; color: var(--p-text-color); font-size: 14px; font-family: monospace; cursor: pointer; }
.g-ctrl button:hover { background: color-mix(in srgb, var(--p-content-border-color) 90%, transparent); color: var(--p-text-color); }
.g-zpct { width: 28px; text-align: center; font-size: 9px; color: var(--p-text-muted-color); font-family: monospace; background: color-mix(in srgb, var(--p-surface-50) 80%, transparent); border-radius: 4px; padding: 2px 0; }
.g-stats { position: absolute; bottom: 8px; left: 8px; font-size: 10px; color: var(--p-text-muted-color); background: color-mix(in srgb, var(--p-surface-50) 80%, transparent); padding: 2px 8px; border-radius: 4px; }
</style>
