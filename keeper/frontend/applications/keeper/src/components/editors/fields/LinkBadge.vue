<script setup lang="ts">
import { Icon } from '@iconify/vue'

defineProps<{
  id: string
  icon?: string
}>()

const emit = defineEmits<{
  navigate: [id: string]
}>()
</script>

<template>
  <button
    class="link-badge"
    @click="emit('navigate', id)"
  >
    <Icon :icon="icon || 'tabler:external-link'" class="w-3 h-3 shrink-0" />
    <span class="truncate">{{ id }}</span>
  </button>
</template>

<style scoped>
.link-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-family: monospace;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  border: none;
  cursor: pointer;
  max-width: 100%;
}
.link-badge:hover {
  background: var(--p-surface-300);
  color: var(--p-primary);
}
</style>
