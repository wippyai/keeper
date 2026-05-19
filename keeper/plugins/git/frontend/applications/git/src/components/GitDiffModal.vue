<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { FileDiff } from '../composables/useGit'

defineProps<{
  path: string | null
  data: FileDiff | null
  loading: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()
</script>

<template>
  <div v-if="path" class="fixed inset-0 z-50 flex"
    style="background: var(--p-mask-background)" @click.self="emit('close')">
    <aside class="ml-auto w-[820px] h-full overflow-hidden flex flex-col"
      style="background: var(--p-content-background); border-left: 1px solid var(--p-content-border-color)">
      <header class="px-4 py-2.5 border-b flex items-center gap-2"
        style="border-color: var(--p-content-border-color)">
        <Icon icon="tabler:diff" class="w-4 h-4" />
        <span class="text-[11px] font-mono flex-1 truncate">{{ path }}</span>
        <button @click="emit('close')" class="opacity-60 hover:opacity-100">
          <Icon icon="tabler:x" class="w-4 h-4" />
        </button>
      </header>

      <div v-if="loading" class="p-12 text-center text-[12px] opacity-60">
        <Icon icon="tabler:loader-2" class="w-5 h-5 animate-spin mx-auto mb-2" />
        Loading diff…
      </div>

      <div v-else-if="!data || (data.hunks.length === 0 && !data.diff_text)"
        class="p-12 text-center text-[12px] opacity-60">
        No diff (file may be untracked or identical to base).
      </div>

      <div v-else class="flex-1 overflow-y-auto font-mono text-[11px] leading-snug">
        <div v-for="(h, hi) in data.hunks" :key="hi">
          <div class="px-3 py-1 sticky top-0 z-10 text-[10px] opacity-60"
            style="background: var(--p-content-hover-background); border-bottom: 1px solid var(--p-content-border-color)">
            {{ h.header }}
          </div>
          <pre v-for="(ln, li) in h.lines" :key="li"
            class="px-0 py-0.5 flex whitespace-pre"
            :class="{
              'bg-success-500/5 text-success-500': ln.kind === '+',
              'bg-danger-500/5 text-danger-500': ln.kind === '-',
            }">
            <span class="w-10 text-right pr-2 opacity-40 select-none shrink-0">{{ ln.old_no || '' }}</span>
            <span class="w-10 text-right pr-2 opacity-40 select-none shrink-0">{{ ln.new_no || '' }}</span>
            <span class="w-4 text-center opacity-60 select-none shrink-0">{{ ln.kind === ' ' ? '' : ln.kind }}</span>
            <span>{{ ln.text }}</span>
          </pre>
        </div>
      </div>
    </aside>
  </div>
</template>
