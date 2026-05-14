<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue'
import { Chart, LineController, LineElement, PointElement, LinearScale, CategoryScale, Filler, Tooltip, Legend } from 'chart.js'

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Filler, Tooltip, Legend)

export interface ChartSeries {
  label: string
  color: string
  data: number[]
}

const props = defineProps<{
  labels: string[]
  series: ChartSeries[]
  height?: number
  stacked?: boolean
  fill?: boolean
  formatValue?: (v: number) => string
  formatLabel?: (l: string) => string
}>()

const canvasRef = ref<HTMLCanvasElement | null>(null)
let chart: Chart | null = null
let updateKey = 0

function fmtVal(v: number): string {
  if (props.formatValue) return props.formatValue(v)
  if (v >= 1000000) return (v / 1000000).toFixed(1) + 'M'
  if (v >= 1000) return (v / 1000).toFixed(1) + 'K'
  return String(Math.round(v))
}

function fmtLabel(l: string): string {
  if (props.formatLabel) return props.formatLabel(l)
  return l
}

function resolveColor(c: string): string {
  // Chart.js needs concrete color strings for canvas. If we got a `var(--x)`
  // reference, resolve it via getComputedStyle on the document root.
  // The #71717a fallback below is a host-less dev safety net — fires only when
  // the CSS var is undefined (no facade injected). Per theming.md §"Defensive
  // fallbacks": JS canvas reads keep numeric fallbacks; CSS-level var fallbacks
  // are stripped.
  if (typeof c === 'string' && c.startsWith('var(')) {
    const m = c.match(/var\(\s*([^,)]+)/)
    if (m && m[1]) {
      const v = getComputedStyle(document.documentElement).getPropertyValue(m[1].trim()).trim()
      if (v) return v
    }
    return '#71717a'
  }
  return c
}
function alphaize(color: string, alpha: number): string {
  // Use color-mix so we don't have to parse hex/rgb here. Modern browsers
  // accept color-mix in canvas contexts as of Chrome 111+.
  return `color-mix(in srgb, ${color} ${Math.round(alpha * 100)}%, transparent)`
}

function makeDatasets() {
  return props.series.map((s, i) => {
    const color = resolveColor(s.color)
    return {
      label: s.label,
      data: [...s.data],
      borderColor: color,
      backgroundColor: alphaize(color, 0.18),
      borderWidth: 1.5,
      pointRadius: 0,
      pointHoverRadius: 3,
      pointHoverBackgroundColor: color,
      pointHoverBorderColor: color,
      tension: 0.3,
      fill: props.fill ?? (props.stacked ? 'origin' : false),
      order: props.series.length - i,
    }
  })
}

function themeColors() {
  // Resolve theme-aware colors at draw time so the chart flips with the theme.
  // Per-var fallbacks below are host-less dev safety nets for Chart.js canvas
  // reads — fire only when the proxy hasn't injected the theme bundle. See
  // theming.md §"Defensive fallbacks".
  const cs = getComputedStyle(document.documentElement)
  const get = (name: string, fallback: string) => (cs.getPropertyValue(name).trim() || fallback)
  const text = get('--p-text-color', '#a1a1aa')
  const muted = get('--p-text-muted-color', '#71717a')
  const surface = get('--p-content-background', '#ffffff')
  const border = get('--p-content-border-color', '#e4e4e7')
  return {
    text, muted, surface, border,
    grid: `color-mix(in srgb, ${border} 60%, transparent)`,
    tickColor: muted,
    tooltipBg: `color-mix(in srgb, ${surface} 92%, ${text} 8%)`,
    tooltipTitle: muted,
    tooltipBody: text,
  }
}

function createChart() {
  if (!canvasRef.value) return
  if (chart) { chart.destroy(); chart = null }

  const t = themeColors()
  chart = new Chart(canvasRef.value, {
    type: 'line',
    data: {
      labels: props.labels.map(fmtLabel),
      datasets: makeDatasets(),
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: t.tooltipBg,
          titleColor: t.tooltipTitle,
          bodyColor: t.tooltipBody,
          borderColor: t.border,
          borderWidth: 1,
          titleFont: { size: 10 },
          bodyFont: { size: 11 },
          bodySpacing: 4,
          padding: { top: 6, bottom: 6, left: 10, right: 10 },
          cornerRadius: 4,
          displayColors: true,
          boxWidth: 8, boxHeight: 8, boxPadding: 4,
          callbacks: {
            label: (ctx: any) => `${ctx.dataset.label}: ${fmtVal(ctx.parsed.y)}`,
          },
        },
      },
      scales: {
        x: {
          display: props.labels.some(l => l !== ''),
          grid: { color: t.grid, drawTicks: false },
          ticks: {
            color: t.tickColor, font: { size: 9 },
            maxRotation: 0, autoSkip: true, maxTicksLimit: 10, padding: 4,
          },
          border: { display: false },
        },
        y: {
          stacked: props.stacked ?? false,
          grid: { color: t.grid, drawTicks: false },
          ticks: {
            color: t.tickColor, font: { size: 9 },
            callback: (val: any) => fmtVal(val), padding: 6, maxTicksLimit: 5,
          },
          border: { display: false },
          beginAtZero: true,
        },
      },
      layout: { padding: { top: 4, right: 4, bottom: 0, left: 0 } },
      animation: { duration: 200 },
    },
  })
}

// Re-render whenever the theme attribute or color-scheme media query flips.
let themeObserver: MutationObserver | null = null
let mediaListener: ((e: MediaQueryListEvent) => void) | null = null
function watchThemeChanges() {
  themeObserver = new MutationObserver(() => createChart())
  themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme', 'class'] })
  const mq = window.matchMedia('(prefers-color-scheme: dark)')
  mediaListener = () => createChart()
  mq.addEventListener?.('change', mediaListener)
}

function syncChart() {
  if (!chart) { createChart(); return }

  const labels = props.labels.map(fmtLabel)
  const datasets = makeDatasets()

  chart.data.labels = labels

  while (chart.data.datasets.length > datasets.length) {
    chart.data.datasets.pop()
  }
  for (let i = 0; i < datasets.length; i++) {
    if (i < chart.data.datasets.length) {
      chart.data.datasets[i].data = datasets[i].data
      chart.data.datasets[i].label = datasets[i].label
      chart.data.datasets[i].borderColor = datasets[i].borderColor
      chart.data.datasets[i].backgroundColor = datasets[i].backgroundColor
    } else {
      chart.data.datasets.push(datasets[i] as any)
    }
  }

  chart.update('none')
}

watch(
  () => {
    updateKey++
    return props.series.map(s => s.data.length).join(',') + '|' + props.labels.length + '|' + updateKey
  },
  () => syncChart(),
)

// Also poll-sync every 500ms as a fallback for reactive edge cases
let syncTimer: ReturnType<typeof setInterval> | null = null

onMounted(() => {
  createChart()
  watchThemeChanges()
  syncTimer = setInterval(() => {
    if (chart && canvasRef.value) syncChart()
  }, 500)
})

onUnmounted(() => {
  if (chart) { chart.destroy(); chart = null }
  if (syncTimer) clearInterval(syncTimer)
  if (themeObserver) themeObserver.disconnect()
  if (mediaListener) window.matchMedia('(prefers-color-scheme: dark)').removeEventListener?.('change', mediaListener)
})
</script>

<template>
  <div class="chart-container" :style="{ height: (height || 180) + 'px' }">
    <canvas ref="canvasRef" />
  </div>
</template>

<style scoped>
.chart-container {
  position: relative;
  width: 100%;
  background: var(--p-surface-100);
  border-radius: 8px;
  padding: 8px;
}
</style>
