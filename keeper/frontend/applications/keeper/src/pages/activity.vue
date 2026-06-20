<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { useApi, useWippy } from '../composables/useWippy'
import { useEvents } from '../composables/useEvents'
import { EVENT_TOPICS } from '../api/events'
import PageHeader from '../components/shared/PageHeader.vue'

const api = useApi()
const instance = useWippy()
const { subscribed, muted, pending, error, ensureSubscribed, mute, unmute } = useEvents()

interface ActivityItem {
  kind: string
  event: string
  data: any
  receivedAt: number
}

const items = ref<ActivityItem[]>([])
const expandedIdx = ref<number | null>(null)
const maxItems = 500

const KIND_META: Record<string, { label: string; icon: string; color: string }> = {
  changeset: { label: 'Changeset', icon: 'tabler:git-commit', color: 'var(--p-primary-color)' },
  git: { label: 'Git', icon: 'tabler:git-branch', color: 'var(--p-text-color)' },
  version: { label: 'Registry', icon: 'tabler:versions', color: 'var(--p-text-muted-color)' },
}

function record(kind: string, evt: any) {
  const payload = evt?.data ?? evt
  // changeset/git carry { event, data }; version carries the change fields directly.
  const event = payload?.event || (kind === 'version' ? 'version' : '')
  const data = payload?.data ?? payload
  items.value = [{ kind, event, data, receivedAt: Date.now() }, ...items.value].slice(0, maxItems)
}

function formatTs(ms: number): string {
  const d = new Date(ms)
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  const ss = String(d.getSeconds()).padStart(2, '0')
  return `${hh}:${mm}:${ss}`
}

function kindMeta(kind: string) {
  return KIND_META[kind] || { label: kind, icon: 'tabler:point', color: 'var(--p-text-muted-color)' }
}

function summary(item: ActivityItem): string {
  const d = item.data
  if (d == null) return ''
  if (typeof d === 'string') return d
  if (item.kind === 'version') {
    return d.new_version ? `${d.old_version || '?'} → ${d.new_version}` : ''
  }
  return d.id || d.name || d.changeset_id || d.message || d.version || ''
}

function toggleExpand(idx: number) {
  expandedIdx.value = expandedIdx.value === idx ? null : idx
}

function clearFeed() {
  items.value = []
}

const unsubs: Array<() => void> = []

onMounted(() => {
  ensureSubscribed(api)
  unsubs.push(instance.on(EVENT_TOPICS.changeset, (evt: any) => record('changeset', evt)))
  unsubs.push(instance.on(EVENT_TOPICS.git, (evt: any) => record('git', evt)))
  unsubs.push(instance.on(EVENT_TOPICS.version, (evt: any) => record('version', evt)))
})

onUnmounted(() => {
  for (const u of unsubs) u?.()
})
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader title="Activity" icon="tabler:broadcast" :count="items.length" :loading="pending" @refresh="clearFeed">
      <span class="flex items-center gap-1 text-[10px]" :style="{ color: subscribed ? 'var(--p-primary-color)' : 'var(--p-text-muted-color)' }">
        <span class="status-dot" :class="{ live: subscribed }" />
        {{ muted ? 'Muted' : subscribed ? 'Live' : 'Off' }}
      </span>
      <Button v-if="muted" class="k-btn-icon !rounded" title="Unmute admin events" @click="unmute(api)">
        <Icon icon="tabler:bell" class="w-3.5 h-3.5" />
      </Button>
      <Button v-else class="k-btn-icon !rounded" title="Mute admin events" @click="mute(api)">
        <Icon icon="tabler:bell-off" class="w-3.5 h-3.5" />
      </Button>
    </PageHeader>

    <div v-if="error" class="mx-4 mt-1 px-3 py-1.5 rounded text-[10px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3 h-3 shrink-0" />
      <span class="flex-1">{{ error }}</span>
    </div>

    <div class="flex-1 overflow-y-auto font-mono text-[10px]">
      <div
        v-for="(item, idx) in items" :key="item.receivedAt + '-' + idx"
        class="act-row"
        @click="toggleExpand(idx)"
      >
        <div class="act-line">
          <span class="act-ts">{{ formatTs(item.receivedAt) }}</span>
          <span class="act-kind" :style="{ color: kindMeta(item.kind).color }">
            <Icon :icon="kindMeta(item.kind).icon" class="w-3 h-3" />
            {{ kindMeta(item.kind).label }}
          </span>
          <span class="act-event">{{ item.event }}</span>
          <span class="act-summary">{{ summary(item) }}</span>
          <Icon icon="tabler:dots" class="w-3 h-3 shrink-0 ml-auto" style="color: var(--p-text-muted-color); opacity: 0.4" />
        </div>
        <div v-if="expandedIdx === idx" class="act-detail">
          <pre>{{ JSON.stringify(item.data, null, 2) }}</pre>
        </div>
      </div>

      <div v-if="items.length === 0" class="flex flex-col items-center justify-center py-16" style="color: var(--p-text-muted-color)">
        <Icon :icon="muted ? 'tabler:bell-off' : 'tabler:broadcast-off'" class="w-8 h-8 mb-2" style="opacity: 0.3" />
        <span class="text-xs">{{ muted ? 'Muted — admin events are not being received' : 'Waiting for admin events' }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.status-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--p-text-muted-color); opacity: 0.5; }
.status-dot.live { background: var(--p-primary-color); opacity: 1; }

.act-row { border-bottom: 1px solid var(--p-surface-100); cursor: pointer; }
.act-row:hover { background: var(--p-surface-50); }
.act-line { display: flex; align-items: center; gap: 8px; padding: 2px 12px; min-height: 22px; }
.act-ts { color: var(--p-text-muted-color); opacity: 0.6; width: 55px; flex-shrink: 0; white-space: nowrap; }
.act-kind { display: flex; align-items: center; gap: 3px; width: 90px; flex-shrink: 0; font-weight: 600; }
.act-event { color: var(--p-text-color); width: 140px; flex-shrink: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.act-summary { color: var(--p-text-muted-color); flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.act-detail { padding: 4px 12px 6px 67px; background: var(--p-surface-100); }
.act-detail pre { margin: 0; white-space: pre-wrap; word-break: break-all; color: var(--p-text-color); }
</style>
