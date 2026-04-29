<script setup lang="ts">
import { Icon } from '@iconify/vue'

defineProps<{
  icon: string
  title: string
  description?: string
}>()
</script>

<template>
  <div class="ed-section">
    <div class="ed-section__header">
      <Icon :icon="icon" class="w-4 h-4 shrink-0 keeper-accent" />
      <div class="flex-1 min-w-0">
        <div class="text-xs font-semibold" style="color: var(--p-text-color)">{{ title }}</div>
        <div v-if="description" class="text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">{{ description }}</div>
      </div>
      <slot name="badge" />
    </div>
    <div class="ed-section__body">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.ed-section {
  border-radius: 6px;
  border: 1px solid var(--p-content-border-color);
  background: var(--p-surface-100);
  overflow: hidden;
}
.ed-section__header {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 10px 12px;
}
.ed-section__body {
  padding: 0 12px 12px;
}
</style>
