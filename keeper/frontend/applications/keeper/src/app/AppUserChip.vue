<script setup lang="ts">
import { Icon } from '@iconify/vue'

defineProps<{
  user: { email: string; full_name: string } | null
}>()

const emit = defineEmits<{
  (e: 'logout'): void
}>()
</script>

<template>
  <div v-if="user" class="flex items-center gap-1.5 text-xs pl-2"
    style="color: var(--p-text-muted-color); border-left: 1px solid var(--p-content-border-color)">
    <span class="truncate max-w-[100px]">{{ user.full_name || user.email }}</span>
    <button
      class="w-6 h-6 inline-flex items-center justify-center rounded-full border-none bg-transparent cursor-pointer transition-colors hover:bg-surface-100 dark:hover:bg-surface-700"
      style="color: var(--p-text-muted-color)"
      title="Logout"
      @click="emit('logout')"
    >
      <Icon icon="tabler:logout" class="w-3 h-3" />
    </button>
  </div>
</template>
