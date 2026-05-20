<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'

export interface NavItem { path: string; name: string; label: string; icon: string }

defineProps<{
  icon: string
  label: string
  items: NavItem[]
  open: boolean
  active: boolean
  currentName: string | null | undefined
  // CSS class applied to the wrapper div — used by the parent's click-outside
  // logic in `onClickOutside` to identify which dropdown was clicked into.
  wrapClass: string
}>()

const emit = defineEmits<{
  (e: 'toggle'): void
  (e: 'navigate', path: string): void
}>()

function pick(path: string) {
  emit('navigate', path)
}
</script>

<template>
  <div :class="['relative', wrapClass]">
    <Button
      variant="text"
      class="k-btn-nav relative !gap-1.5"
      :class="{ 'k-btn-active': active }"
      @click="emit('toggle')"
    >
      <Icon :icon="icon" class="w-3.5 h-3.5" />
      {{ label }}
      <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.5" />
    </Button>
    <div v-if="open" class="status-dropdown">
      <button
        v-for="item in items" :key="item.name"
        class="status-item"
        :class="{ 'status-item--active': currentName === item.name }"
        @click="pick(item.path)"
      >
        <Icon :icon="item.icon" class="w-3.5 h-3.5" />
        {{ item.label }}
        <span v-if="item.name.startsWith('plugin:')" class="plugin-tag" title="Provided by a registered plugin">plugin</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.status-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  min-width: 200px;
  max-width: 320px;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  padding: 4px;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.status-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 6px 10px;
  font-size: 12px;
  text-align: left;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-color);
  border: none;
  cursor: pointer;
  white-space: nowrap;
}
.status-item:hover {
  background: var(--p-surface-100);
}
.status-item--active {
  background: var(--p-surface-100);
  color: var(--p-primary-color);
  font-weight: 500;
}
.plugin-tag {
  margin-left: auto;
  padding: 0 5px;
  font-size: 8px;
  font-weight: 500;
  letter-spacing: 0.02em;
  border-radius: 2px;
  color: var(--p-text-muted-color);
  opacity: 0.55;
}
.status-item .iconify {
  flex-shrink: 0;
  opacity: 0.75;
}
</style>
