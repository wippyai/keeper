<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
import type { Message } from '../../api/sessions'
import { prettyJson, truncate } from './msg-utils'
import MsgHeader from './MsgHeader.vue'

const props = defineProps<{ msg: Message }>()
const expanded = ref(false)
const result = (props.msg.metadata as any)?.result
const hasLongContent = (props.msg.data?.length || 0) > 400 || JSON.stringify(result || '').length > 400
</script>

<template>
  <div>
    <MsgHeader :msg="msg" />
    <div class="space-y-2">
      <div class="code-block" :class="{ 'max-h-36': !expanded }">
        <div class="code-label">Arguments</div>
        <pre>{{ expanded ? prettyJson(msg.data) : truncate(msg.data, 400) }}</pre>
      </div>
      <div v-if="result" class="code-block" :class="{ 'max-h-44': !expanded }">
        <div class="code-label">Result</div>
        <pre>{{ expanded ? prettyJson(result) : truncate(JSON.stringify(result), 400) }}</pre>
      </div>
    </div>
    <button v-if="hasLongContent" class="text-[11px] mt-1.5 flex items-center gap-1" style="color: var(--p-primary-color)" @click="expanded = !expanded">
      <Icon :icon="expanded ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3" />
      {{ expanded ? 'Collapse' : 'Expand' }}
    </button>
  </div>
</template>

<style scoped>
.code-block { background: var(--p-surface-100); color: var(--p-text-color); border-radius: 6px; padding: 8px 10px; font-size: 11px; font-family: monospace; overflow: auto; white-space: pre-wrap; word-break: break-word; }
.code-label { font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600; color: var(--p-text-muted-color); margin-bottom: 3px; }
</style>
