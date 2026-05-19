<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { SnapshotCounts } from '../composables/useGit'

defineProps<{
  stale: boolean
  rebuilding: boolean
  indexAgeText: string
  journalSize: number | null
  counts: SnapshotCounts
  syncFirst: boolean
}>()

const emit = defineEmits<{
  (e: 'rebuild', mode: 'manual' | 'ai'): void
  (e: 'push-confirm'): void
  (e: 'update:syncFirst', v: boolean): void
}>()
</script>

<template>
  <header class="px-5 py-2.5 border-b flex items-center gap-3 text-[12px]"
    style="border-color: var(--p-content-border-color)">
    <Icon icon="tabler:git-pull-request" class="w-4 h-4" />
    <h1 class="text-[13px] font-semibold">Git</h1>

    <span class="opacity-50">·</span>

    <div class="flex items-center gap-2 px-2 py-1 rounded"
      :class="{ 'bg-warn-500/10': stale }"
      :style="!stale ? { background: 'var(--p-content-hover-background)' } : {}">
      <Icon :icon="stale ? 'tabler:alert-triangle' : 'tabler:database'"
        class="w-3.5 h-3.5"
        :class="{ 'text-warn-500': stale }" />
      <span class="text-[11px]" :class="{ 'text-warn-500': stale }">
        Index built {{ indexAgeText }}
        <template v-if="journalSize !== null">
          · {{ journalSize }} changes
        </template>
      </span>
      <button @click="emit('rebuild', 'ai')" :disabled="rebuilding"
        class="text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1 text-white"
        :class="{ 'bg-warn-500': stale }"
        :style="!stale ? { background: 'var(--p-primary-color)' } : {}"
        title="AI-clustered rebuild — groups changes by topic via Sonnet (~30-90s)">
        <Icon :icon="rebuilding ? 'tabler:loader-2' : 'tabler:sparkles'"
          :class="rebuilding ? 'w-3 h-3 animate-spin' : 'w-3 h-3'" />
        {{ rebuilding ? 'Rebuilding…' : 'AI rebuild' }}
      </button>
      <button @click="emit('rebuild', 'manual')" :disabled="rebuilding"
        class="text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1"
        style="background: var(--kp-btn-secondary-bg)"
        title="Manual rebuild — group by directory prefix (no LLM, instant)">
        <Icon icon="tabler:list" class="w-3 h-3" />
        Manual
      </button>
      <label class="flex items-center gap-1 cursor-pointer text-[10px] opacity-70 hover:opacity-100"
        title="Sync registry overlays to disk before scanning git">
        <input type="checkbox" :checked="syncFirst" @change="emit('update:syncFirst', ($event.target as HTMLInputElement).checked)" class="w-3 h-3" />
        sync first
      </label>
    </div>

    <span class="opacity-50">·</span>
    <span class="opacity-70">{{ counts.all }} clusters · {{ counts.suspect }} suspect</span>

    <button v-if="(counts.pushable_ready || 0) > 0" @click="emit('push-confirm')"
      class="ml-auto px-3 py-1 rounded text-[11px] font-semibold flex items-center gap-1.5 bg-success-500 text-white">
      <Icon icon="tabler:upload" class="w-3.5 h-3.5" />
      Push {{ counts.pushable_ready }} ready
    </button>
    <span v-else-if="(counts.blocked_ready || 0) > 0" class="ml-auto opacity-60 text-[11px]">
      {{ counts.blocked_ready }} ready for review only
    </span>
    <span v-else class="ml-auto opacity-50 text-[11px]">
      Mark clusters ready to enable push
    </span>
  </header>
</template>
