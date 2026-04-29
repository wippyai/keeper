<script setup lang="ts">
import { Icon } from '@iconify/vue'

defineProps<{
  title: string
  icon?: string
  count?: number | string
  loading?: boolean
}>()

const emit = defineEmits<{ refresh: [] }>()
</script>

<template>
  <div class="shrink-0 px-4 py-2 flex items-center justify-between gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
    <div class="flex items-center gap-2">
      <Icon v-if="icon" :icon="icon" class="w-4 h-4 keeper-accent" />
      <span class="text-xs font-medium" style="color: var(--p-text-color)">{{ title }}</span>
      <span v-if="count !== undefined" class="text-[10px]" style="color: var(--p-text-muted-color)">{{ count }}</span>
      <Icon v-if="loading" icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin keeper-accent" />
    </div>
    <div class="flex items-center gap-2">
      <slot />
      <button class="p-1 rounded" style="color: var(--p-text-muted-color)" @click="emit('refresh')">
        <Icon icon="tabler:refresh" class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
      </button>
    </div>
  </div>
</template>
