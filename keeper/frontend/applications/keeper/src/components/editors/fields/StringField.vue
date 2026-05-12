<script setup lang="ts">
const model = defineModel<string>({ default: '' })
defineProps<{
  placeholder?: string
  mono?: boolean
  readonly?: boolean
}>()
</script>

<template>
  <input
    v-if="!readonly"
    :value="model"
    @input="model = ($event.target as HTMLInputElement).value"
    type="text"
    :placeholder="placeholder"
    class="ed-input"
    :class="{ 'font-mono': mono }"
  />
  <span v-else class="text-[11px]" :class="{ 'font-mono': mono }" style="color: var(--p-text-color)">{{ model || '-' }}</span>
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
