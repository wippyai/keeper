<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { Message } from '../../api/sessions'
import { formatDate } from '../../api/sessions'

defineProps<{ msg: Message }>()
</script>

<template>
  <div class="flex items-center gap-2 text-[11px] py-0.5" style="color: var(--p-text-muted-color); opacity: 0.6">
    <Icon icon="tabler:terminal" class="w-3 h-3 shrink-0 text-accent-500" />
    <span class="truncate">{{ msg.data }}</span>
    <span class="ml-auto text-[10px] shrink-0">{{ formatDate(msg.date) }}</span>
  </div>
</template>
