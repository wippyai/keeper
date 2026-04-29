<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { DataflowNode } from '../../api/dataflows'
import { getNodeTokens, getToolCalls, getStatusMessage, getInputOutputSizes, fmtTokens, formatBytes } from './node-utils'

const props = defineProps<{ node: DataflowNode }>()

const tokens = getNodeTokens(props.node)
const toolCalls = getToolCalls(props.node)
const statusMsg = getStatusMessage(props.node)
const sizes = getInputOutputSizes(props.node)
</script>

<template>
  <div v-if="tokens || toolCalls || statusMsg || sizes" class="flex items-center gap-2 flex-wrap">
    <template v-if="tokens">
      <span class="metric" style="color: var(--p-info-400)"><Icon icon="tabler:arrow-down" class="w-2.5 h-2.5" />{{ fmtTokens(tokens.prompt) }}</span>
      <span class="metric" style="color: var(--p-accent-400)"><Icon icon="tabler:arrow-up" class="w-2.5 h-2.5" />{{ fmtTokens(tokens.completion) }}</span>
      <span v-if="tokens.thinking" class="metric" style="color: var(--p-warn-400)"><Icon icon="tabler:brain" class="w-2.5 h-2.5" />{{ fmtTokens(tokens.thinking) }}</span>
      <span v-if="tokens.cache_read" class="metric" style="color: var(--p-success-500)"><Icon icon="tabler:database" class="w-2.5 h-2.5" />R:{{ fmtTokens(tokens.cache_read) }}</span>
      <span v-if="tokens.cache_write" class="metric" style="color: var(--p-success-500)"><Icon icon="tabler:database-plus" class="w-2.5 h-2.5" />W:{{ fmtTokens(tokens.cache_write) }}</span>
    </template>
    <span v-if="toolCalls" class="metric" style="color: var(--p-info-500)"><Icon icon="tabler:tool" class="w-2.5 h-2.5" />{{ toolCalls }}</span>
    <template v-if="sizes">
      <span v-if="sizes.output" class="metric" style="color: var(--p-success-500)"><Icon icon="tabler:arrow-down" class="w-2.5 h-2.5" />{{ formatBytes(Math.floor(sizes.output / 4)) }}</span>
      <span v-if="sizes.input" class="metric" style="color: var(--p-info-400)"><Icon icon="tabler:arrow-up" class="w-2.5 h-2.5" />{{ formatBytes(Math.floor(sizes.input / 4)) }}</span>
    </template>
    <span v-if="statusMsg" class="text-[10px] italic" style="color: var(--p-text-muted-color)">{{ statusMsg }}</span>
  </div>
</template>

<style scoped>
.metric { display: inline-flex; align-items: center; gap: 1px; font-size: 10px; font-weight: 600; line-height: 1; }
</style>
