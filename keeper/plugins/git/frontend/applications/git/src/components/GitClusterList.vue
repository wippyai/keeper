<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'
import type { ClusterSummary, SnapshotCounts, Importance, Verdict } from '../composables/useGit'
import { importanceTone, verdictTone, fmtChanges } from '../tones'

export type Filter = 'all' | 'pending' | 'ready' | 'hidden' | 'suspect'

defineProps<{
  clusters: ClusterSummary[]
  counts: SnapshotCounts
  filter: Filter
  selectedId: string | null
  loading: boolean
  error: string | null
  hasAnyClusters: boolean
}>()

const emit = defineEmits<{
  (e: 'update:filter', v: Filter): void
  (e: 'select', id: string): void
}>()

const FILTER_CHIPS: Array<{ key: Filter; label: string }> = [
  { key: 'all',     label: 'All' },
  { key: 'pending', label: 'Pending' },
  { key: 'ready',   label: 'Ready to push' },
  { key: 'hidden',  label: 'Hidden' },
  { key: 'suspect', label: 'Suspect' },
]
</script>

<template>
  <div class="flex flex-col">
    <!-- chip filters -->
    <div class="px-5 py-2 border-b flex items-center gap-1 text-[10px]"
      style="border-color: var(--p-content-border-color)">
      <button v-for="chip in FILTER_CHIPS" :key="chip.key"
        @click="emit('update:filter', chip.key)"
        class="px-1.5 py-0.5 rounded font-medium flex items-center gap-1 transition"
        :style="{
          background: filter === chip.key ? 'var(--p-primary-color)' : 'var(--p-content-hover-background)',
          color: filter === chip.key ? 'var(--p-primary-contrast-color)' : 'inherit',
        }">
        {{ chip.label }}
        <span class="opacity-80">{{ counts[chip.key] }}</span>
      </button>
    </div>

    <!-- list -->
    <section class="flex-1 overflow-y-auto border-r" style="border-color: var(--p-content-border-color)">
      <div v-if="loading && !hasAnyClusters" class="p-8 text-center text-[12px] opacity-60">
        Loading…
      </div>
      <div v-else-if="error" class="p-6 text-[12px] text-danger-500">
        {{ error }}
      </div>
      <div v-else-if="clusters.length === 0" class="p-12 text-center text-[12px] opacity-60">
        <span v-if="!hasAnyClusters">
          No cluster index yet. Click Rebuild above to build one.
        </span>
        <span v-else>Nothing matches.</span>
      </div>
      <article v-for="c in clusters" :key="c.id"
        @click="emit('select', c.id)"
        class="px-4 py-3 border-b cursor-pointer transition"
        :style="{
          borderColor: 'var(--p-content-border-color)',
          background: selectedId === c.id ? 'var(--p-content-hover-background)' : 'transparent',
          opacity: c.decision !== 'pending' ? 0.65 : 1,
        }">
        <div class="flex items-center gap-2 mb-1.5">
          <span class="w-2 h-2 rounded-full shrink-0"
            :style="{ background: importanceTone[c.importance as Importance].dot }" />
          <h3 class="text-[12px] font-semibold flex-1 truncate">{{ c.title }}</h3>
          <Icon v-if="c.decision === 'approved'" icon="tabler:circle-check" class="w-3.5 h-3.5 shrink-0 text-success-500" />
          <Icon v-else-if="c.decision === 'split'" icon="tabler:arrow-split" class="w-3.5 h-3.5 shrink-0 opacity-50" />
          <Icon v-else-if="c.decision === 'skipped'" icon="tabler:archive" class="w-3.5 h-3.5 shrink-0 opacity-50" />
        </div>
        <div class="flex items-center gap-2 text-[10px] opacity-70 mb-1">
          <span>{{ fmtChanges(c.change_count) }}</span>
          <span class="opacity-50">·</span>
          <span class="flex items-center gap-1"
            :style="{ color: verdictTone[c.verdict as Verdict].color }">
            <Icon :icon="verdictTone[c.verdict as Verdict].icon" class="w-3 h-3" />
            {{ verdictTone[c.verdict as Verdict].phrase }}
          </span>
          <Tag v-if="c.rec_open > 0" severity="warn" class="ml-auto !text-[9px] !px-1 !py-0">
            {{ c.rec_open }} open
          </Tag>
        </div>
        <p class="text-[10px] opacity-70 leading-snug truncate">{{ c.plain_summary }}</p>
      </article>
    </section>
  </div>
</template>
