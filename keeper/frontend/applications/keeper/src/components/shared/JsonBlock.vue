<script setup lang="ts">
const props = defineProps<{ data: any; maxHeight?: string; fontSize?: string }>()

function prettyJson(obj: any): string {
  if (obj === null || obj === undefined) return ''
  if (typeof obj === 'string') { try { return JSON.stringify(JSON.parse(obj), null, 2) } catch { return obj } }
  return JSON.stringify(obj, null, 2)
}
</script>

<template>
  <pre
    class="rounded-md p-3 font-mono overflow-auto whitespace-pre-wrap break-words"
    :style="{
      background: 'var(--p-surface-100)',
      color: 'var(--p-text-color)',
      fontSize: fontSize || '11px',
      maxHeight: maxHeight || '500px',
    }"
  >{{ prettyJson(data) }}</pre>
</template>
