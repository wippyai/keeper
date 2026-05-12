<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import LinkBadge from '../fields/LinkBadge.vue'

const props = defineProps<{
  entry: RegistryEntry
  detail: any
}>()

const emit = defineEmits<{
  update: [updates: { meta?: Record<string, any>; data?: Record<string, any> }]
  navigate: [id: string]
}>()

const meta = ref<Record<string, any>>({})
const data = ref<Record<string, any>>({})

watch(() => props.detail, (d) => {
  const e = d?.entry || props.entry
  meta.value = JSON.parse(JSON.stringify(e.meta || {}))
  data.value = JSON.parse(JSON.stringify(e.data || {}))
}, { immediate: true })

function emitMeta(key: string, value: any) {
  meta.value[key] = value
  emit('update', { meta: { [key]: value } })
}

const hasHandlers = computed(() => data.value.handlers && Object.keys(data.value.handlers).length > 0)
const hasPricing = computed(() => data.value.pricing && Object.keys(data.value.pricing).length > 0)
const hasCapabilities = computed(() => meta.value.capabilities && meta.value.capabilities.length > 0)

const capabilityIcons: Record<string, string> = {
  tool_use: 'tabler:tool', vision: 'tabler:eye', thinking: 'tabler:brain',
  caching: 'tabler:database', generate: 'tabler:text-size', multilingual: 'tabler:language',
  audio: 'tabler:microphone', video: 'tabler:video', structured_output: 'tabler:table',
}

const pricingLabels: Record<string, string> = {
  input: 'Input', output: 'Output', cached_input: 'Cached Input',
  input_long: 'Long Input', output_long: 'Long Output',
  output_reasoning: 'Reasoning Output', grounding: 'Grounding',
}

function formatTokenCount(count: any): string {
  if (count == null) return '-'
  const num = typeof count === 'string' ? parseFloat(count) : count
  if (num >= 1_000_000) return (num / 1_000_000).toFixed(1) + 'M'
  if (num >= 1_000) return (num / 1_000).toFixed(1) + 'K'
  return String(num)
}

function formatCapability(cap: string): string {
  return cap.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')
}

function formatHandlerType(type: string): string {
  return type.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')
}
</script>

<template>
  <div class="space-y-3 p-4">
    <!-- Description -->
    <EditorSection icon="tabler:file-description" title="Description" description="Notes and purpose of this LLM model configuration.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter model description..."
      ></textarea>
    </EditorSection>

    <!-- Model Information -->
    <EditorSection icon="tabler:info-circle" title="Model Information" description="Basic information about this model.">
      <div class="grid grid-cols-2 gap-0 rounded overflow-hidden" style="background: var(--p-surface-0)">
        <div class="p-2.5" style="border-right: 1px solid var(--p-content-border-color); border-bottom: 1px solid var(--p-content-border-color)">
          <div class="text-[10px]" style="color: var(--p-text-muted-color)">Title</div>
          <div class="text-[11px] font-semibold" style="color: var(--p-text-color)">{{ meta.title || '-' }}</div>
        </div>
        <div class="p-2.5" style="border-bottom: 1px solid var(--p-content-border-color)">
          <div class="text-[10px]" style="color: var(--p-text-muted-color)">Provider Model</div>
          <div class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.provider_model || '-' }}</div>
        </div>
        <div class="p-2.5" style="border-right: 1px solid var(--p-content-border-color)">
          <div class="text-[10px]" style="color: var(--p-text-muted-color)">Max Tokens</div>
          <div class="text-[11px] font-semibold" style="color: var(--p-text-color)">{{ formatTokenCount(data.max_tokens) }}</div>
        </div>
        <div class="p-2.5">
          <div class="text-[10px]" style="color: var(--p-text-muted-color)">Output Tokens</div>
          <div class="text-[11px] font-semibold" style="color: var(--p-text-color)">{{ formatTokenCount(data.output_tokens) }}</div>
        </div>
      </div>
    </EditorSection>

    <!-- Capabilities -->
    <EditorSection v-if="hasCapabilities" icon="tabler:trending-up" title="Capabilities" description="Features and capabilities of this model.">
      <div class="flex flex-wrap gap-1.5">
        <span v-for="cap in meta.capabilities" :key="cap" class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-200); color: var(--p-text-color)">
          <Icon :icon="capabilityIcons[cap] || 'tabler:circle-check'" class="w-3 h-3" />
          {{ formatCapability(cap) }}
        </span>
      </div>
    </EditorSection>

    <!-- Handlers -->
    <EditorSection v-if="hasHandlers" icon="tabler:code" title="Handlers" description="Function handlers for model operations.">
      <div class="space-y-2">
        <div v-for="(handler, type) in data.handlers" :key="String(type)" class="p-2 rounded" style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
          <div class="text-[10px] mb-1" style="color: var(--p-text-muted-color)">{{ formatHandlerType(String(type)) }}</div>
          <LinkBadge :id="String(handler)" icon="tabler:code" @navigate="emit('navigate', $event)" />
        </div>
      </div>
    </EditorSection>

    <!-- Pricing -->
    <EditorSection v-if="hasPricing" icon="tabler:coin" title="Pricing" description="Cost information per 1M tokens.">
      <table class="w-full text-[11px]">
        <thead>
          <tr style="border-bottom: 1px solid var(--p-content-border-color)">
            <th class="text-left py-1.5 px-2 text-[10px] uppercase" style="color: var(--p-text-muted-color)">Category</th>
            <th class="text-right py-1.5 px-2 text-[10px] uppercase" style="color: var(--p-text-muted-color)">USD per 1M</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(price, type) in data.pricing" :key="String(type)" style="border-bottom: 1px solid var(--p-content-border-color)">
            <td class="py-1.5 px-2" style="color: var(--p-text-color)">{{ pricingLabels[String(type)] || formatHandlerType(String(type)) }}</td>
            <td class="py-1.5 px-2 text-right font-mono" style="color: var(--p-text-color)">${{ Number(price).toFixed(2) }}</td>
          </tr>
        </tbody>
      </table>
    </EditorSection>

    <!-- Additional Info -->
    <EditorSection v-if="data.knowledge_cutoff || data.model_family || data.mteb_performance || data.dimensions" icon="tabler:clipboard-list" title="Additional Information">
      <div class="grid grid-cols-2 gap-3">
        <div v-if="data.knowledge_cutoff" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Knowledge Cutoff</span>
          <span class="text-[11px]" style="color: var(--p-text-color)">{{ data.knowledge_cutoff }}</span>
        </div>
        <div v-if="data.model_family" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Model Family</span>
          <span class="text-[11px]" style="color: var(--p-text-color)">{{ data.model_family }}</span>
        </div>
        <div v-if="data.mteb_performance" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">MTEB Performance</span>
          <span class="text-[11px]" style="color: var(--p-text-color)">{{ data.mteb_performance }}%</span>
        </div>
        <div v-if="data.dimensions" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Dimensions</span>
          <span class="text-[11px]" style="color: var(--p-text-color)">{{ data.dimensions }}</span>
        </div>
      </div>
    </EditorSection>
  </div>
</template>

<style scoped>
.ed-textarea {
  width: 100%;
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-0);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  resize: vertical;
  min-height: 50px;
  line-height: 1.5;
}
.ed-textarea:focus { border-color: var(--p-primary-color); }
</style>
