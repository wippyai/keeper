<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { ClusterSummary, Importance } from '../composables/useGit'
import { importanceTone, fmtChanges } from '../tones'

defineProps<{
  open: boolean
  count: number
  pushing: boolean
  clusters: ClusterSummary[]
}>()

const emit = defineEmits<{
  (e: 'push'): void
  (e: 'close'): void
}>()
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center"
    style="background: var(--p-mask-background)" @click.self="emit('close')">
    <div class="rounded-lg w-full max-w-md mx-4 overflow-hidden"
      style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
      <div class="px-5 py-3 border-b flex items-center gap-2"
        style="border-color: var(--p-content-border-color)">
        <Icon icon="tabler:upload" class="w-4 h-4" />
        <h3 class="text-[13px] font-semibold flex-1">Push {{ count }} clusters to main</h3>
        <button @click="emit('close')" class="opacity-60 hover:opacity-100">
          <Icon icon="tabler:x" class="w-4 h-4" />
        </button>
      </div>
      <div class="px-5 py-4">
        <p class="text-[11px] opacity-80 leading-relaxed">
          Each cluster runs through governance (lint → version → migrations → tests → registry → fs) and
          merges to main on success. Failed clusters stay in <b>Pending</b> with the failure attached.
        </p>
        <div class="rounded border mt-3" style="border-color: var(--p-content-border-color); max-height: 240px; overflow-y: auto">
          <div v-for="c in clusters" :key="c.id"
            class="px-3 py-2 border-b last:border-0 flex items-center gap-2"
            style="border-color: var(--p-content-border-color)">
            <span class="w-1.5 h-1.5 rounded-full shrink-0"
              :style="{ background: importanceTone[c.importance as Importance].dot }" />
            <span class="text-[11px] flex-1 truncate">{{ c.title }}</span>
            <span class="text-[10px] opacity-60 shrink-0">{{ fmtChanges(c.change_count) }}</span>
          </div>
        </div>
      </div>
      <div class="px-5 py-3 border-t flex items-center gap-2"
        style="border-color: var(--p-content-border-color)">
        <button @click="emit('push')" :disabled="pushing"
          class="px-4 py-1.5 rounded text-[12px] font-semibold flex items-center gap-1.5 disabled:opacity-60 bg-success-500 text-white">
          <Icon :icon="pushing ? 'tabler:loader-2' : 'tabler:upload'"
            :class="pushing ? 'w-3.5 h-3.5 animate-spin' : 'w-3.5 h-3.5'" />
          {{ pushing ? 'Pushing…' : 'Push all' }}
        </button>
        <button @click="emit('close')" :disabled="pushing"
          class="px-4 py-1.5 rounded text-[12px]" style="background: var(--p-surface-200)">
          Cancel
        </button>
      </div>
    </div>
  </div>
</template>
