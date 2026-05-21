<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'
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
    <Tag v-if="msg.metadata?.model" severity="secondary">{{ msg.metadata.model }}</Tag>
    <Tag v-if="msg.metadata?.agent_id" class="k-tag-tone-accent !font-mono" :style="{ border: '1px solid color-mix(in srgb, var(--p-accent-500) 25%, transparent)' }">{{ msg.metadata.agent_id }}</Tag>
    <Tag v-if="msg.metadata?.function_name" severity="warn">
      <Icon icon="tabler:function" class="w-3 h-3" /> {{ msg.metadata.function_name }}
    </Tag>
    <Tag v-if="msg.metadata?.status" :severity="msg.metadata.status === 'error' ? 'danger' : 'success'">
      <Icon :icon="msg.metadata.status === 'error' ? 'tabler:x' : 'tabler:check'" class="w-3 h-3" /> {{ msg.metadata.status }}
    </Tag>
    <span v-if="msg.metadata?.tokens" class="text-[10px] font-mono ml-auto flex items-center gap-2" style="color: var(--p-text-muted-color)">
      <span class="text-accent-500" title="Prompt tokens">P&nbsp;{{ formatTokens(msg.metadata.tokens.prompt_tokens) }}</span>
      <span class="text-accent-400" title="Completion tokens">C&nbsp;{{ formatTokens(msg.metadata.tokens.completion_tokens) }}</span>
      <span v-if="msg.metadata.tokens.thinking_tokens" class="text-warn-500" title="Thinking tokens">T&nbsp;{{ formatTokens(msg.metadata.tokens.thinking_tokens) }}</span>
      <span v-if="msg.metadata.tokens.cache_read_tokens" class="text-info-500" title="Cache read tokens">CR&nbsp;{{ formatTokens(msg.metadata.tokens.cache_read_tokens) }}</span>
    </span>
  </div>
</template>
