<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'

defineProps<{
  icon: string
  iconColor?: string
  title: string
  subtitle?: string
  tabs: string[]
}>()

const activeTab = defineModel<string>('activeTab', { required: true })
const emit = defineEmits<{ close: [] }>()
</script>

<template>
  <div class="flex flex-col overflow-hidden h-full">
    <div class="shrink-0 px-4 py-2 flex items-center gap-2" style="border-bottom: 1px solid var(--p-content-border-color)">
      <Icon :icon="icon" class="w-4 h-4" :style="{ color: iconColor || 'var(--p-text-color)' }" />
      <span class="text-xs font-semibold" style="color: var(--p-text-color)">{{ title }}</span>
      <span v-if="subtitle" class="text-[10px]" style="color: var(--p-text-muted-color)">{{ subtitle }}</span>
      <slot name="badges" />
      <div class="ml-auto flex gap-1">
        <button
          v-for="t in tabs" :key="t"
          class="text-[10px] px-2 py-0.5 rounded"
          :style="{
            background: activeTab === t ? 'var(--p-surface-100)' : 'transparent',
            color: activeTab === t ? 'var(--p-text-color)' : 'var(--p-text-muted-color)',
          }"
          @click="activeTab = t"
        >{{ t }}</button>
      </div>
      <Button class="k-btn-icon !p-0.5 !rounded" @click="emit('close')">
        <Icon icon="tabler:x" class="w-3.5 h-3.5" />
      </Button>
    </div>
    <slot name="subheader" />
    <div class="flex-1 overflow-y-auto p-4">
      <slot />
    </div>
    <slot name="footer" />
  </div>
</template>
