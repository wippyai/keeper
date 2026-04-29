<script setup lang="ts">
const model = defineModel<string>({ default: '' })
defineProps<{
  options: Array<string | { label: string; value: string }>
  placeholder?: string
  readonly?: boolean
}>()

function optionValue(o: string | { label: string; value: string }): string {
  return typeof o === 'string' ? o : o.value
}
function optionLabel(o: string | { label: string; value: string }): string {
  return typeof o === 'string' ? o : o.label
}
</script>

<template>
  <select
    v-if="!readonly"
    :value="model"
    @change="model = ($event.target as HTMLSelectElement).value"
    class="ed-select"
  >
    <option v-if="placeholder" value="" disabled>{{ placeholder }}</option>
    <option v-for="opt in options" :key="optionValue(opt)" :value="optionValue(opt)">{{ optionLabel(opt) }}</option>
  </select>
  <span v-else class="text-[11px]" style="color: var(--p-text-color)">{{ model || '-' }}</span>
</template>

<style scoped>
.ed-select {
  width: 100%;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  cursor: pointer;
}
.ed-select:focus {
  border-color: var(--p-primary);
}
</style>
