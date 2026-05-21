<script setup lang="ts">
import { computed } from 'vue'
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'
import type { DataflowData } from '../../api/dataflows'
import { formatTokens } from '../../api/sessions'
import MarkdownContent from '../shared/MarkdownContent.vue'

const props = defineProps<{ data: DataflowData }>()

function deepParse(val: any): any {
  if (typeof val === 'string') {
    try { return deepParse(JSON.parse(val)) } catch { return val }
  }
  return val
}

const parsed = computed(() => deepParse(props.data.content))

const isAction = computed(() => props.data.type === 'agent.action')
const isDelegation = computed(() => props.data.type === 'agent.delegation')
const isResult = computed(() => props.data.type === 'node.result')
const isReference = computed(() => props.data.content_type === 'dataflow/reference')
const isYield = computed(() => props.data.type.startsWith('node.yield'))

const meta = computed(() => {
  const m = props.data.metadata
  if (!m || (Array.isArray(m) && m.length === 0)) return null
  return typeof m === 'object' ? m as any : null
})
const tokens = computed(() => meta.value?.tokens)
const agentId = computed(() => meta.value?.agent_id)
const model = computed(() => meta.value?.model)
const iteration = computed(() => meta.value?.iteration)
const toolName = computed(() => meta.value?.tool_name)
const finishReason = computed(() => meta.value?.finish_reason)

function typeColor(type: string): string {
  if (type.startsWith('agent.action')) return 'var(--p-success-500)'
  if (type.startsWith('agent.observation')) return 'var(--p-info-500)'
  if (type.startsWith('agent.delegation')) return 'var(--p-accent-500)'
  if (type.startsWith('agent.error')) return 'var(--p-danger-500)'
  if (type.includes('input')) return 'var(--p-warn-500)'
  if (type.includes('output') || type.includes('result')) return 'var(--p-info-500)'
  return 'var(--p-text-muted-color)'
}

function typeIcon(type: string): string {
  if (type.startsWith('agent.action')) return 'tabler:message-bolt'
  if (type.startsWith('agent.observation')) return 'tabler:eye'
  if (type.startsWith('agent.delegation')) return 'tabler:arrow-fork'
  if (type.startsWith('agent.error')) return 'tabler:alert-circle'
  if (type.includes('input')) return 'tabler:arrow-right'
  if (type.includes('output')) return 'tabler:arrow-left'
  if (type.includes('result')) return 'tabler:check'
  return 'tabler:database'
}

function prettyJson(obj: any): string {
  if (obj === null || obj === undefined) return ''
  if (typeof obj === 'string') return obj
  return JSON.stringify(obj, null, 2)
}
</script>

<template>
  <div>
    <!-- Header badges -->
    <div class="flex items-center flex-wrap gap-2 mb-3">
      <Icon :icon="typeIcon(data.type)" class="w-4 h-4 shrink-0" :style="{ color: typeColor(data.type) }" />
      <span class="text-xs font-semibold" :style="{ color: typeColor(data.type) }">{{ data.type }}</span>
      <Tag v-if="iteration" severity="secondary" class="!font-medium">iter {{ iteration }}</Tag>
      <Tag v-if="agentId" class="k-tag-tone-accent !font-medium">{{ agentId }}</Tag>
      <Tag v-if="model" severity="secondary" class="!font-medium">{{ model }}</Tag>
      <Tag v-if="toolName" severity="warn" class="!font-medium">{{ toolName }}</Tag>
      <span v-if="finishReason" class="text-[10px]" :class="{ 'text-success-500': finishReason === 'stop', 'text-accent-400': finishReason === 'tool_call' }" :style="{ color: (finishReason !== 'stop' && finishReason !== 'tool_call') ? 'var(--p-text-muted-color)' : undefined }">{{ finishReason }}</span>
      <span v-if="tokens" class="text-[10px] font-mono ml-auto flex items-center gap-2" style="color: var(--p-text-muted-color)">
        <span class="text-accent-500" title="Prompt tokens">P&nbsp;{{ formatTokens(tokens.prompt_tokens) }}</span>
        <span class="text-accent-400" title="Completion tokens">C&nbsp;{{ formatTokens(tokens.completion_tokens) }}</span>
        <span v-if="tokens.thinking_tokens" class="text-warn-500" title="Thinking tokens">T&nbsp;{{ formatTokens(tokens.thinking_tokens) }}</span>
      </span>
    </div>

    <!-- Reference -->
    <div v-if="isReference" class="flex items-center gap-2 text-xs" style="color: var(--p-text-muted-color)">
      <Icon icon="tabler:link" class="w-3.5 h-3.5" />
      Reference to: <span class="font-mono">{{ data.key || data.data_id }}</span>
    </div>

    <!-- Yield (compact) -->
    <div v-else-if="isYield" class="text-xs" style="color: var(--p-text-muted-color)">
      <div v-if="parsed?.yield_context?.run_nodes?.length" class="flex items-center gap-1.5">
        <Icon icon="tabler:player-play" class="w-3.5 h-3.5" />
        Running {{ parsed.yield_context.run_nodes.length }} child node(s)
      </div>
      <div v-else class="flex items-center gap-1.5">
        <Icon icon="tabler:clock" class="w-3.5 h-3.5" />
        Yield (waiting for coordination)
      </div>
    </div>

    <!-- Agent action -->
    <template v-else-if="isAction && parsed && typeof parsed === 'object'">
      <!-- Response text -->
      <MarkdownContent v-if="parsed.result" :content="parsed.result" class="mb-3" />

      <!-- Tool calls -->
      <div v-if="parsed.tool_calls?.length" class="space-y-2 mb-3">
        <div class="section-label">Tool Calls ({{ parsed.tool_calls.length }})</div>
        <div v-for="tc in parsed.tool_calls" :key="tc.id" class="tool-block">
          <div class="flex items-center gap-1.5 mb-1.5">
            <Icon icon="tabler:tool" class="w-3.5 h-3.5 text-info-500" />
            <span class="text-xs font-medium text-info-500">{{ tc.name }}</span>
            <span class="font-mono text-[9px]" style="color: var(--p-text-muted-color)">{{ tc.id?.slice(0, 24) }}</span>
          </div>
          <pre class="text-[11px] font-mono whitespace-pre-wrap break-words" style="color: var(--p-text-color)">{{ prettyJson(tc.arguments) }}</pre>
        </div>
      </div>

      <!-- Delegate calls -->
      <div v-if="parsed.delegate_calls?.length" class="space-y-2">
        <div class="section-label">Delegate Calls ({{ parsed.delegate_calls.length }})</div>
        <div v-for="dc in parsed.delegate_calls" :key="dc.id" class="delegate-block">
          <div class="flex items-center gap-1.5 mb-1.5">
            <Icon icon="tabler:arrow-fork" class="w-3.5 h-3.5 text-accent-500" />
            <span class="text-xs font-medium text-accent-500">{{ dc.name }}</span>
            <span class="font-mono text-[9px]" style="color: var(--p-text-muted-color)">{{ dc.id?.slice(0, 24) }}</span>
          </div>
          <pre class="text-[11px] font-mono whitespace-pre-wrap break-words" style="color: var(--p-text-color)">{{ prettyJson(dc.arguments) }}</pre>
        </div>
      </div>

      <!-- No text, no calls -->
      <div v-if="!parsed.result && !parsed.tool_calls?.length && !parsed.delegate_calls?.length" class="text-xs italic" style="color: var(--p-text-muted-color)">(empty action)</div>
    </template>

    <!-- Node result -->
    <template v-else-if="isResult && parsed && typeof parsed === 'object'">
      <div class="flex items-center gap-2 text-sm mb-2">
        <Icon :icon="parsed.success ? 'tabler:circle-check' : 'tabler:circle-x'" class="w-5 h-5" :class="{ 'text-success-500': parsed.success, 'text-danger-500': !parsed.success }" />
        <span class="font-medium" :class="{ 'text-success-500': parsed.success, 'text-danger-500': !parsed.success }">{{ parsed.message || (parsed.success ? 'Completed successfully' : 'Failed') }}</span>
      </div>
      <div v-if="parsed.data_ids?.length" class="text-xs" style="color: var(--p-text-muted-color)">
        {{ parsed.data_ids.length }} output data item(s)
      </div>
    </template>

    <!-- Delegation result (text content) -->
    <MarkdownContent v-else-if="isDelegation && typeof parsed === 'string'" :content="parsed" />

    <!-- Plain text input/output (render as markdown for output) -->
    <MarkdownContent v-else-if="(data.type.includes('output') || isDelegation) && typeof parsed === 'string'" :content="parsed" />
    <div v-else-if="data.content_type === 'text/plain' || (typeof parsed === 'string' && parsed.length > 0)" class="text-[13px] whitespace-pre-wrap break-words leading-relaxed" style="color: var(--p-text-color)">{{ typeof parsed === 'string' ? parsed : String(data.content) }}</div>

    <!-- JSON object fallback -->
    <pre v-else-if="parsed && typeof parsed === 'object'" class="code-block">{{ prettyJson(parsed) }}</pre>

    <!-- Raw fallback -->
    <pre v-else-if="data.content" class="code-block">{{ String(data.content) }}</pre>
  </div>
</template>

<style scoped>
.badge { display: inline-flex; align-items: center; gap: 3px; padding: 1px 6px; border-radius: 4px; font-size: 10px; font-weight: 500; }
.section-label { font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600; color: var(--p-text-muted-color); margin-bottom: 4px; }
.tool-block { background: var(--p-surface-100); border-radius: 6px; padding: 10px 12px; }
.delegate-block { background: color-mix(in srgb, var(--p-accent-500) 5%, transparent); border: 1px solid color-mix(in srgb, var(--p-accent-500) 10%, transparent); border-radius: 6px; padding: 10px 12px; }
.code-block { background: var(--p-surface-100); color: var(--p-text-color); border-radius: 6px; padding: 10px 12px; font-size: 11px; font-family: monospace; overflow: auto; white-space: pre-wrap; word-break: break-word; max-height: 500px; }
</style>
