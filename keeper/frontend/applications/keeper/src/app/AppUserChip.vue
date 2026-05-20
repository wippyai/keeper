<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'

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
    <Button
      class="k-btn-icon !w-6 !h-6 !p-0 !rounded-full"
      title="Logout"
      @click="emit('logout')"
    >
      <Icon icon="tabler:logout" class="w-3 h-3" />
    </Button>
  </div>
</template>
