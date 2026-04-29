<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { Message } from '../../api/sessions'
import { formatDate, formatTokens } from '../../api/sessions'
import { msgColor, msgIcon } from './msg-utils'

defineProps<{ msg: Message }>()
</script>

<template>
  <div class="flex items-center flex-wrap gap-2 mb-2">
    <Icon :icon="msgIcon(msg.type)" class="w-4 h-4 shrink-0" :style="{ color: msgColor(msg.type) }" />
    <span class="text-xs font-semibold" :style="{ color: msgColor(msg.type) }">{{ msg.type }}</span>
    <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ formatDate(msg.date) }}</span>
    <span v-if="msg.metadata?.model" class="text-[10px] px-1.5 py-0.5 rounded" style="background: var(--p-surface-100); color: var(--p-text-muted-color)">{{ msg.metadata.model }}</span>
    <span v-if="msg.metadata?.agent_id" class="text-[10px] px-1.5 py-0.5 rounded text-accent-500 font-mono" style="background: color-mix(in srgb, var(--p-accent-500) 12%, transparent); border: 1px solid color-mix(in srgb, var(--p-accent-500) 25%, transparent)">{{ msg.metadata.agent_id }}</span>
    <span v-if="msg.metadata?.function_name" class="text-[10px] px-1.5 py-0.5 rounded flex items-center gap-1 text-warn-500" style="background: color-mix(in srgb, var(--p-warn-500) 10%, transparent)">
      <Icon icon="tabler:function" class="w-3 h-3" /> {{ msg.metadata.function_name }}
    </span>
    <span v-if="msg.metadata?.status" class="text-[10px] px-1.5 py-0.5 rounded flex items-center gap-1"
      :class="{ 'text-danger-500': msg.metadata.status === 'error', 'text-success-500': msg.metadata.status !== 'error' }"
      :style="{ background: msg.metadata.status === 'error' ? 'color-mix(in srgb, var(--p-danger-500) 10%, transparent)' : 'color-mix(in srgb, var(--p-success-500) 10%, transparent)' }">
      <Icon :icon="msg.metadata.status === 'error' ? 'tabler:x' : 'tabler:check'" class="w-3 h-3" /> {{ msg.metadata.status }}
    </span>
    <span v-if="msg.metadata?.tokens" class="text-[10px] font-mono ml-auto flex items-center gap-2" style="color: var(--p-text-muted-color)">
      <span class="text-accent-500" title="Prompt tokens">P&nbsp;{{ formatTokens(msg.metadata.tokens.prompt_tokens) }}</span>
      <span class="text-accent-400" title="Completion tokens">C&nbsp;{{ formatTokens(msg.metadata.tokens.completion_tokens) }}</span>
      <span v-if="msg.metadata.tokens.thinking_tokens" class="text-warn-500" title="Thinking tokens">T&nbsp;{{ formatTokens(msg.metadata.tokens.thinking_tokens) }}</span>
      <span v-if="msg.metadata.tokens.cache_read_tokens" class="text-info-500" title="Cache read tokens">CR&nbsp;{{ formatTokens(msg.metadata.tokens.cache_read_tokens) }}</span>
    </span>
  </div>
</template>
