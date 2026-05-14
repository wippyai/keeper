<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import {
  getUsageSummary, getUsageByTime, getUsageByModel, getUsageByUser,
  type TokenTotals, type TimePeriod, type ModelUsage, type UserUsage
} from '../api/usage'
import PageHeader from '../components/shared/PageHeader.vue'
import LineChart, { type ChartSeries } from '../components/shared/LineChart.vue'

const api = useApi()

const period = ref('today')
const customStart = ref('')
const customEnd = ref('')
const loading = ref(true)
const error = ref<string | null>(null)

const summary = ref<TokenTotals | null>(null)
const timePeriods = ref<TimePeriod[]>([])
const models = ref<ModelUsage[]>([])
const users = ref<UserUsage[]>([])

const presets = [
  { value: 'today', label: 'Today' },
  { value: 'week', label: '7 Days' },
  { value: 'month', label: '30 Days' },
  { value: 'custom', label: 'Custom' },
]

function fmt(n: number | undefined): string {
  if (!n) return '0'
  return n.toLocaleString()
}

function pct(part: number, total: number): string {
  if (!total) return '0'
  return ((part / total) * 100).toFixed(1)
}

function shortModel(id: string): string {
  const parts = id.split('/')
  return parts[parts.length - 1] || id
}

function formatTimePeriod(tp: string): string {
  if (!tp) return ''
  if (tp.includes('T') || tp.length > 16) {
    const d = new Date(tp + (tp.endsWith('Z') ? '' : 'Z'))
    return d.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
  }
  if (tp.length === 10) {
    const d = new Date(tp + 'T00:00:00Z')
    return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
  }
  if (tp.includes(':')) {
    const d = new Date(tp.replace(' ', 'T') + 'Z')
    if (!isNaN(d.getTime())) {
      return d.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
    }
  }
  return tp
}

function formatChartLabel(tp: string): string {
  if (!tp) return ''
  if (tp.length === 10) {
    const d = new Date(tp + 'T00:00:00Z')
    return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
  }
  if (tp.includes(':') || tp.includes('T')) {
    const d = new Date(tp.replace(' ', 'T') + (tp.endsWith('Z') ? '' : 'Z'))
    if (!isNaN(d.getTime())) {
      return d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })
    }
  }
  return tp
}

const chartLabels = computed(() => timePeriods.value.map(p => p.time_period))

const chartSeries = computed<ChartSeries[]>(() => {
  const result: ChartSeries[] = [
    { label: 'Prompt', color: 'var(--p-accent-500)', data: timePeriods.value.map(p => p.prompt_tokens) },
    { label: 'Completion', color: 'var(--p-accent-400)', data: timePeriods.value.map(p => p.completion_tokens) },
  ]
  const hasThinking = timePeriods.value.some(p => p.thinking_tokens > 0)
  if (hasThinking) {
    result.push({ label: 'Thinking', color: 'var(--p-warn-500)', data: timePeriods.value.map(p => p.thinking_tokens) })
  }
  return result
})

function userDisplay(userId: string): string {
  return userId || 'anonymous'
}

async function load() {
  loading.value = true
  error.value = null
  try {
    let startTime: number | undefined
    let endTime: number | undefined
    const p = period.value

    if (p === 'custom') {
      if (!customStart.value || !customEnd.value) {
        error.value = 'Select both start and end dates'
        loading.value = false
        return
      }
      startTime = Math.floor(new Date(customStart.value).getTime() / 1000)
      endTime = Math.floor(new Date(customEnd.value + 'T23:59:59').getTime() / 1000)
    }

    const [summaryRes, timeRes, modelRes, userRes] = await Promise.all([
      getUsageSummary(api, p, startTime, endTime),
      getUsageByTime(api, p, undefined, startTime, endTime),
      getUsageByModel(api, p, startTime, endTime),
      getUsageByUser(api, p, startTime, endTime),
    ])
    summary.value = summaryRes.summary

    timePeriods.value = timeRes.periods || []

    const rawModels = modelRes.models || []
    const totalModelTokens = rawModels.reduce((s: number, m: any) => s + (m.total_tokens || 0), 0)
    models.value = rawModels.map((m: any) => ({
      ...m,
      percentage: totalModelTokens > 0 ? Math.round((m.total_tokens || 0) / totalModelTokens * 100) : 0,
    }))

    const rawUsers = userRes.users || []
    const totalUserTokens = rawUsers.reduce((s: number, u: any) => s + (u.total_tokens || 0), 0)
    users.value = rawUsers.map((u: any) => ({
      ...u,
      percentage: totalUserTokens > 0 ? Math.round((u.total_tokens || 0) / totalUserTokens * 100) : 0,
    }))
  } catch (e: any) {
    error.value = e.response?.data?.error || e.message
  } finally {
    loading.value = false
  }
}

function selectPeriod(p: string) {
  period.value = p
  if (p !== 'custom') load()
}

function applyCustomRange() {
  if (customStart.value && customEnd.value) load()
}

onMounted(() => {
  const now = new Date()
  customEnd.value = now.toISOString().slice(0, 10)
  const weekAgo = new Date(now.getTime() - 7 * 86400000)
  customStart.value = weekAgo.toISOString().slice(0, 10)
  load()
})
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader title="Token Usage" :loading="loading" @refresh="load" />

    <div v-if="error" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
      <button @click="error = null" style="color: var(--p-text-muted-color)"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>

    <div class="flex-1 overflow-y-auto p-4 space-y-5">
      <!-- Period selector -->
      <div class="flex items-center gap-2 flex-wrap">
        <button
          v-for="p in presets" :key="p.value"
          class="period-btn" :class="{ active: period === p.value }"
          @click="selectPeriod(p.value)"
        >{{ p.label }}</button>
        <template v-if="period === 'custom'">
          <input type="date" v-model="customStart" class="date-input" />
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">to</span>
          <input type="date" v-model="customEnd" class="date-input" />
          <button class="period-btn active" @click="applyCustomRange">Apply</button>
        </template>
      </div>

      <!-- Summary cards -->
      <div v-if="summary" class="grid grid-cols-3 gap-3">
        <div class="stat-card">
          <div class="stat-label">Total Tokens</div>
          <div class="stat-value">{{ fmt(summary.total_tokens) }}</div>
          <div class="stat-sub">{{ fmt(summary.request_count) }} requests</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Prompt</div>
          <div class="stat-value text-accent-500">{{ fmt(summary.prompt_tokens) }}</div>
          <div class="stat-sub">{{ pct(summary.prompt_tokens, summary.total_tokens) }}%</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Completion</div>
          <div class="stat-value text-accent-400">{{ fmt(summary.completion_tokens) }}</div>
          <div class="stat-sub">{{ pct(summary.completion_tokens, summary.total_tokens) }}%</div>
        </div>
      </div>

      <!-- Secondary stats -->
      <div v-if="summary && (summary.thinking_tokens || summary.cache_read_tokens || summary.cache_write_tokens)" class="grid grid-cols-3 gap-3">
        <div v-if="summary.thinking_tokens" class="stat-card-sm">
          <div class="stat-label">Thinking</div>
          <div class="stat-value-sm text-warn-500">{{ fmt(summary.thinking_tokens) }}</div>
        </div>
        <div v-if="summary.cache_read_tokens" class="stat-card-sm">
          <div class="stat-label">Cache Read</div>
          <div class="stat-value-sm text-info-500">{{ fmt(summary.cache_read_tokens) }}</div>
        </div>
        <div v-if="summary.cache_write_tokens" class="stat-card-sm">
          <div class="stat-label">Cache Write</div>
          <div class="stat-value-sm text-warn-500">{{ fmt(summary.cache_write_tokens) }}</div>
        </div>
      </div>

      <!-- Line chart: usage over time -->
      <section v-if="timePeriods.length > 0">
        <div class="section-header">
          <Icon icon="tabler:chart-line" class="w-3.5 h-3.5 text-accent-500" />
          <span>Over Time</span>
          <div class="flex items-center gap-3 ml-auto">
            <span v-for="s in chartSeries" :key="s.label" class="flex items-center gap-1 text-[9px]" style="color: var(--p-text-muted-color)">
              <span class="w-2 h-2 rounded-full" :style="{ background: s.color }" />
              {{ s.label }}
            </span>
          </div>
        </div>
        <LineChart
          v-if="timePeriods.length > 0"
          :labels="chartLabels"
          :series="chartSeries"
          :height="200"
          :fill="true"
          :format-label="formatChartLabel"
        />
        <div v-else class="breakdown-list">
          <div v-for="tp in timePeriods" :key="tp.time_period" class="breakdown-row">
            <span class="text-[11px]" style="color: var(--p-text-muted-color)">{{ formatTimePeriod(tp.time_period) }}</span>
            <span class="text-[11px] font-mono text-accent-500">{{ fmt(tp.prompt_tokens) }} prompt</span>
            <span class="text-[11px] font-mono text-accent-400">{{ fmt(tp.completion_tokens) }} completion</span>
            <span class="text-[11px] font-mono ml-auto" style="color: var(--p-text-color)">{{ fmt(tp.total_tokens) }} total</span>
          </div>
        </div>
      </section>

      <!-- By Model -->
      <section v-if="models.length > 0">
        <div class="section-header">
          <Icon icon="tabler:cpu" class="w-3.5 h-3.5 text-accent-500" />
          <span>By Model</span>
        </div>
        <div class="breakdown-list">
          <div v-for="m in models" :key="m.model_id" class="breakdown-row">
            <div class="flex items-center gap-2 min-w-0 flex-1">
              <span class="font-mono text-[11px] truncate" style="color: var(--p-text-color)">{{ shortModel(m.model_id) }}</span>
              <span class="text-[9px] px-1.5 py-0.5 rounded" style="background: color-mix(in srgb, var(--p-text-color) 10%, transparent); color: var(--p-text-muted-color)">{{ m.percentage }}%</span>
            </div>
            <div class="breakdown-bar-container">
              <div class="breakdown-bar" style="background: var(--p-primary-color)" :style="{ width: m.percentage + '%' }" />
            </div>
            <div class="breakdown-tokens">
              <span class="text-[10px] font-mono" style="color: var(--p-text-color)">{{ fmt(m.total_tokens) }}</span>
              <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ fmt(m.request_count) }} req</span>
            </div>
          </div>
        </div>
      </section>

      <!-- By User -->
      <section v-if="users.length > 0">
        <div class="section-header">
          <Icon icon="tabler:users" class="w-3.5 h-3.5 text-accent-500" />
          <span>By User</span>
        </div>
        <div class="breakdown-list">
          <div v-for="u in users" :key="u.user_id" class="breakdown-row">
            <div class="flex items-center gap-2 min-w-0 flex-1">
              <Icon icon="tabler:user" class="w-3.5 h-3.5 shrink-0" style="color: var(--p-text-muted-color)" />
              <span class="text-[11px] truncate" style="color: var(--p-text-color)">{{ userDisplay(u.user_id) }}</span>
              <span class="text-[9px] px-1.5 py-0.5 rounded" style="background: color-mix(in srgb, var(--p-text-color) 10%, transparent); color: var(--p-text-muted-color)">{{ u.percentage }}%</span>
            </div>
            <div class="breakdown-bar-container">
              <div class="breakdown-bar bg-accent-500" :style="{ width: u.percentage + '%' }" />
            </div>
            <div class="breakdown-tokens">
              <span class="text-[10px] font-mono" style="color: var(--p-text-color)">{{ fmt(u.total_tokens) }}</span>
              <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ fmt(u.request_count) }} req</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Empty state -->
      <div v-if="!loading && summary && !summary.total_tokens" class="text-center py-12">
        <Icon icon="tabler:chart-bar-off" class="w-8 h-8 mx-auto mb-2" style="color: var(--p-text-muted-color); opacity: 0.4" />
        <div class="text-xs" style="color: var(--p-text-muted-color)">No usage data for this period</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* --usage-elevated / --usage-chip defined in src/styles.css :root */

.period-btn {
  padding: 4px 12px; border-radius: 4px; font-size: 11px;
  background: var(--usage-elevated); color: var(--p-text-muted-color);
  border: 1px solid transparent;
}
.period-btn:hover { background: var(--p-content-hover-background); }
.period-btn.active {
  background: var(--p-primary-color); color: var(--p-primary-contrast-color); font-weight: 600;
}

.date-input {
  padding: 3px 8px; border-radius: 4px; font-size: 11px;
  background: var(--usage-elevated); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}
.date-input:focus { border-color: var(--p-primary-color); }

.stat-card {
  background: var(--usage-elevated); border-radius: 8px; padding: 12px 14px;
}
.stat-label { font-size: 10px; color: var(--p-text-muted-color); margin-bottom: 4px; }
.stat-value { font-size: 18px; font-weight: 700; color: var(--p-text-color); font-variant-numeric: tabular-nums; }
.stat-sub { font-size: 10px; color: var(--p-text-muted-color); margin-top: 2px; }

.stat-card-sm {
  background: var(--usage-elevated); border-radius: 6px; padding: 8px 12px;
}
.stat-value-sm { font-size: 14px; font-weight: 600; font-variant-numeric: tabular-nums; }

.section-header {
  display: flex; align-items: center; gap: 6px; margin-bottom: 8px;
  font-size: 11px; font-weight: 600; color: var(--p-text-color);
}

.breakdown-list {
  background: var(--usage-elevated); border-radius: 8px; padding: 4px 0;
}
.breakdown-row {
  display: flex; align-items: center; gap: 10px; padding: 6px 12px;
}
.breakdown-row:hover { background: var(--p-content-hover-background); }
.breakdown-bar-container {
  width: 80px; height: 6px; background: var(--usage-chip);
  border-radius: 3px; overflow: hidden; flex-shrink: 0;
}
.breakdown-bar { height: 100%; border-radius: 3px; min-width: 2px; }
.breakdown-tokens {
  display: flex; flex-direction: column; align-items: flex-end;
  width: 80px; flex-shrink: 0;
}
</style>
