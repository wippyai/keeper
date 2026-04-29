<script setup lang="ts">
defineProps<{
  prompt: number
  completion: number
  thinking?: number
  cacheRead?: number
  cacheWrite?: number
  total?: number
}>()

function fmt(n: number): string { return n?.toLocaleString() || '0' }
</script>

<template>
  <div class="flex flex-wrap gap-x-4 gap-y-0.5 text-[10px] font-mono" style="color: var(--p-text-muted-color)">
    <span><span class="text-accent-500">P</span> {{ fmt(prompt) }}</span>
    <span><span class="text-accent-400">C</span> {{ fmt(completion) }}</span>
    <span v-if="thinking"><span class="text-warn-500">T</span> {{ fmt(thinking) }}</span>
    <span v-if="cacheRead"><span class="text-info-500">CR</span> {{ fmt(cacheRead) }}</span>
    <span v-if="cacheWrite"><span class="text-warn-500">CW</span> {{ fmt(cacheWrite) }}</span>
    <span v-if="total" style="color: var(--p-text-color)">Total {{ fmt(total) }}</span>
  </div>
</template>
