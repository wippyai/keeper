<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { ClusterChange, SplitGroup } from '../composables/useGit'

type Mode = 'ai' | 'by_prefix' | 'by_kind'

const props = defineProps<{
  open: boolean
  title: string
  changeCount: number
  changes: ClusterChange[] | null
  mode: Mode
  groups: SplitGroup[]
  loading: boolean
  applying: boolean
}>()

const emit = defineEmits<{
  (e: 'update:mode', m: Mode): void
  (e: 'apply'): void
  (e: 'close'): void
}>()

function pathSamples(g: SplitGroup): string[] {
  const changes = props.changes
  if (!changes) return []
  const map: Record<string, string> = {}
  for (const c of changes) map[c.change_id] = c.path
  return g.change_ids.slice(0, 3).map(id => map[id] || id)
}

const MODES: ReadonlyArray<{ key: Mode; icon: string; label: string }> = [
  { key: 'by_prefix', icon: 'tabler:folders',  label: 'By directory' },
  { key: 'by_kind',   icon: 'tabler:category', label: 'By file kind' },
  { key: 'ai',        icon: 'tabler:sparkles', label: 'AI suggest' },
]
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center"
    style="background: var(--p-mask-background)" @click.self="emit('close')">
    <div class="rounded-lg w-full max-w-2xl mx-4 overflow-hidden flex flex-col"
      style="background: var(--p-content-background); border: 1px solid var(--p-content-border-color); max-height: 80vh">
      <header class="px-5 py-3 border-b flex items-center gap-2"
        style="border-color: var(--p-content-border-color)">
        <Icon icon="tabler:arrow-split" class="w-4 h-4" />
        <h3 class="text-[13px] font-semibold flex-1">
          Split <span class="opacity-70">{{ title }}</span>
        </h3>
        <button @click="emit('close')" class="opacity-60 hover:opacity-100">
          <Icon icon="tabler:x" class="w-4 h-4" />
        </button>
      </header>

      <div class="px-5 py-2.5 border-b flex items-center gap-1 text-[11px]"
        style="border-color: var(--p-content-border-color)">
        <span class="opacity-70 mr-1">Strategy:</span>
        <button v-for="m in MODES" :key="m.key"
          @click="emit('update:mode', m.key)"
          :disabled="loading"
          class="px-2 py-1 rounded font-medium flex items-center gap-1"
          :style="{
            background: mode === m.key ? 'var(--p-primary-color)' : 'var(--p-content-hover-background)',
            color: mode === m.key ? 'var(--p-primary-contrast-color)' : 'inherit',
          }">
          <Icon :icon="m.icon" class="w-3 h-3" />
          {{ m.label }}
        </button>
        <span class="ml-auto opacity-60">
          {{ changeCount }} files in source cluster
        </span>
      </div>

      <div class="flex-1 overflow-y-auto p-4">
        <div v-if="loading" class="p-12 text-center text-[12px] opacity-60">
          <Icon icon="tabler:loader-2" class="w-5 h-5 animate-spin mx-auto mb-2" />
          <span v-if="mode === 'ai'">Asking Sonnet to propose sub-clusters…</span>
          <span v-else>Computing groups…</span>
        </div>
        <div v-else-if="groups.length === 0" class="p-12 text-center text-[12px] opacity-60">
          No groups proposed.
        </div>
        <div v-else>
          <p class="text-[11px] opacity-70 mb-3">
            Will create <b>{{ groups.length }}</b> new clusters.
            Source cluster will be {{ groups.reduce((a,g) => a + g.change_ids.length, 0) >= changeCount ? 'removed' : 'reduced' }}.
          </p>
          <ul class="space-y-2">
            <li v-for="(g, i) in groups" :key="i"
              class="rounded p-3"
              style="background: var(--p-content-hover-background); border: 1px solid var(--p-content-border-color)">
              <div class="flex items-baseline gap-2 mb-1">
                <span class="text-[12px] font-semibold flex-1 truncate">{{ g.title }}</span>
                <span class="text-[10px] opacity-70">{{ g.change_ids.length }} files</span>
              </div>
              <p v-if="g.plain_summary" class="text-[11px] opacity-80 mb-1.5">{{ g.plain_summary }}</p>
              <div class="font-mono text-[10px] opacity-60 space-y-0.5">
                <div v-for="p in pathSamples(g)" :key="p" class="truncate">{{ p }}</div>
                <div v-if="g.change_ids.length > 3">+ {{ g.change_ids.length - 3 }} more</div>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <div class="px-5 py-3 border-t flex items-center gap-2"
        style="border-color: var(--p-content-border-color)">
        <button @click="emit('apply')"
          :disabled="loading || applying || groups.length < 2"
          class="px-4 py-1.5 rounded text-[12px] font-semibold flex items-center gap-1.5 disabled:opacity-50 bg-success-500 text-white">
          <Icon :icon="applying ? 'tabler:loader-2' : 'tabler:arrow-split'"
            :class="applying ? 'w-3.5 h-3.5 animate-spin' : 'w-3.5 h-3.5'" />
          {{ applying ? 'Splitting…' : `Apply (creates ${groups.length} clusters)` }}
        </button>
        <button @click="emit('close')" class="px-4 py-1.5 rounded text-[12px] ml-auto"
          style="background: var(--kp-btn-secondary-bg)">Cancel</button>
      </div>
    </div>
  </div>
</template>
