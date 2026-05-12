<script setup lang="ts">
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import StringField from '../fields/StringField.vue'
import BoolField from '../fields/BoolField.vue'
import NumberField from '../fields/NumberField.vue'
import MapField from '../fields/MapField.vue'
import LinkBadge from '../fields/LinkBadge.vue'
import JsonField from '../fields/JsonField.vue'

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

function emitData(key: string, value: any) {
  data.value[key] = value
  emit('update', { data: { [key]: value } })
}
</script>

<template>
  <div class="space-y-3 p-4">
    <EditorSection icon="tabler:file-description" title="Description" description="Purpose and behavior of this process.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter description..."
      ></textarea>
    </EditorSection>

    <EditorSection icon="tabler:cpu" title="Process Configuration" description="Host assignment and startup behavior.">
      <div class="space-y-2">
        <FieldRow v-if="data.host !== undefined" label="Host">
          <LinkBadge :id="data.host" icon="tabler:server" @navigate="emit('navigate', $event)" />
        </FieldRow>
        <FieldRow v-if="data.process !== undefined" label="Process">
          <StringField :model-value="data.process || ''" readonly mono />
        </FieldRow>
        <FieldRow v-if="data.auto_start !== undefined" label="Auto Start">
          <BoolField :model-value="data.auto_start ?? false" @update:model-value="emitData('auto_start', $event)" />
        </FieldRow>
      </div>
    </EditorSection>

    <EditorSection v-if="data.pool !== undefined" icon="tabler:stack-2" title="Pool Configuration" description="Worker pool sizing and timeout settings.">
      <div class="grid grid-cols-2 gap-3">
        <div v-if="data.pool?.min !== undefined" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Min Workers</span>
          <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.min }}</span>
        </div>
        <div v-if="data.pool?.max !== undefined" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Max Workers</span>
          <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.max }}</span>
        </div>
        <div v-if="data.pool?.idle_timeout !== undefined" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Idle Timeout</span>
          <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.idle_timeout }}</span>
        </div>
        <div v-if="data.pool?.warmup !== undefined" class="flex flex-col">
          <span class="text-[10px]" style="color: var(--p-text-muted-color)">Warmup</span>
          <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.warmup }}</span>
        </div>
      </div>
    </EditorSection>

    <!-- Modules -->
    <EditorSection v-if="data.modules && data.modules.length > 0" icon="tabler:puzzle" title="Required Modules" description="Lua modules this process needs at runtime.">
      <div class="flex flex-wrap gap-1.5">
        <span v-for="mod in data.modules" :key="mod" class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-200); color: var(--p-text-color)">
          <Icon icon="tabler:cube" class="w-3 h-3" />{{ mod }}
        </span>
      </div>
    </EditorSection>

    <!-- Imports -->
    <EditorSection v-if="data.imports && Object.keys(data.imports).length > 0" icon="tabler:external-link" title="Registry Dependencies" description="Other registry entries this process imports.">
      <div class="flex flex-wrap gap-1.5">
        <LinkBadge v-for="(path, name) in data.imports" :key="String(name)" :id="String(path)" icon="tabler:external-link" @navigate="emit('navigate', $event)" />
      </div>
    </EditorSection>

    <EditorSection v-if="data.env !== undefined && Object.keys(data.env).length > 0" icon="tabler:variable" title="Environment" description="Environment variables passed to the process.">
      <MapField :model-value="data.env || {}" @update:model-value="emitData('env', $event)" key-placeholder="VAR" value-placeholder="Value" />
    </EditorSection>

    <EditorSection v-if="data.lifecycle !== undefined" icon="tabler:repeat" title="Lifecycle" description="Process lifecycle and restart configuration.">
      <JsonField :model-value="data.lifecycle" @update:model-value="emitData('lifecycle', $event)" :rows="6" />
    </EditorSection>
  </div>
</template>

<style scoped>
.ed-textarea {
  width: 100%; padding: 6px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none; resize: vertical;
  min-height: 50px; line-height: 1.5;
}
.ed-textarea:focus { border-color: var(--p-primary-color); }
</style>
