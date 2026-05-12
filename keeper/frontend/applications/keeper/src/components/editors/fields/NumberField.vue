<script setup lang="ts">
const model = defineModel<number>({ default: 0 })
defineProps<{
  placeholder?: string
  min?: number
  max?: number
  step?: number
  readonly?: boolean
}>()

function onInput(e: Event) {
  const v = (e.target as HTMLInputElement).value
  model.value = v === '' ? 0 : Number(v)
}
</script>

<template>
  <input
    v-if="!readonly"
    :value="model"
    @input="onInput"
    type="number"
    :placeholder="placeholder"
    :min="min"
    :max="max"
    :step="step"
    class="ed-input font-mono"
  />
  <span v-else class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ model }}</span>
</template>

<style scoped>
.ed-input {
  width: 100%;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
}
.ed-input:focus {
  border-color: var(--p-primary-color);
}
</style>
