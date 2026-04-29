<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { Message } from '../../api/sessions'
import { formatDate } from '../../api/sessions'
import { systemActionText, systemActionIcon, msgColor } from './msg-utils'

defineProps<{ msg: Message }>()
</script>

<template>
  <div class="flex items-center gap-2 text-xs py-1.5" style="color: var(--p-text-muted-color)">
    <Icon :icon="systemActionIcon(msg)" class="w-4 h-4 shrink-0" :style="{ color: msgColor(msg.type) }" />
    <span>{{ systemActionText(msg) }}</span>
    <span class="ml-auto text-[10px]">{{ formatDate(msg.date) }}</span>
  </div>
</template>
