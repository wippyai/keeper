<script setup lang="ts">
import { ref, computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { Message } from '../../api/sessions'
import { truncate, getThinking } from './msg-utils'
import MsgHeader from './MsgHeader.vue'
import MarkdownContent from '../shared/MarkdownContent.vue'

const props = defineProps<{ msg: Message }>()
const expanded = ref(false)
const showThinking = ref(false)
const isLong = computed(() => (props.msg.data?.length || 0) > 400)
const thinking = computed(() => getThinking(props.msg))
</script>

<template>
  <div>
    <MsgHeader :msg="msg" />

    <!-- Thinking block -->
    <div v-if="thinking" class="mb-2">
      <button class="text-[10px] flex items-center gap-1 mb-1 text-warn-500" @click="showThinking = !showThinking">
        <Icon icon="tabler:brain" class="w-3 h-3" />
        <span>Thinking ({{ (thinking.length / 1000).toFixed(1) }}K)</span>
        <Icon :icon="showThinking ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-2.5 h-2.5" />
      </button>
      <div v-if="showThinking" class="rounded-md p-3 text-xs whitespace-pre-wrap break-words leading-relaxed" style="background: color-mix(in srgb, var(--p-warn-500) 6%, transparent); border: 1px solid color-mix(in srgb, var(--p-warn-500) 15%, transparent); color: var(--p-text-color); max-height: 300px; overflow-y: auto">{{ thinking }}</div>
    </div>

    <!-- Content -->
    <MarkdownContent v-if="msg.data && (msg.type === 'assistant' || msg.type === 'user')" :content="expanded ? msg.data : truncate(msg.data, 400)" :max-height="!expanded && isLong ? '200px' : 'none'" />
    <div v-else-if="msg.data" class="text-[13px] whitespace-pre-wrap break-words leading-relaxed" style="color: var(--p-text-color)">
      {{ expanded ? msg.data : truncate(msg.data, 400) }}
    </div>
    <div v-else-if="msg.type === 'assistant'" class="text-xs italic" style="color: var(--p-text-muted-color)">
      (empty response - continued with tool calls)
    </div>

    <button v-if="isLong" class="text-[11px] mt-1.5 flex items-center gap-1" style="color: var(--p-primary-color)" @click="expanded = !expanded">
      <Icon :icon="expanded ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3" />
      {{ expanded ? 'Collapse' : `Show all (${(msg.data!.length / 1000).toFixed(1)}K)` }}
    </button>
  </div>
</template>
