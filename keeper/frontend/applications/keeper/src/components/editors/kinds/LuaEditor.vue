<script setup lang="ts">
import { ref, watch, computed, defineAsyncComponent } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import NumberField from '../fields/NumberField.vue'
import BoolField from '../fields/BoolField.vue'
import LinkBadge from '../fields/LinkBadge.vue'

const MonacoEditor = defineAsyncComponent(() => import('../fields/MonacoEditor.vue'))

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
const activeTab = ref<'general' | 'source'>('general')

const isProcess = computed(() => props.entry.kind === 'process.lua')
const isLibrary = computed(() => props.entry.kind === 'library.lua')
const kindLabel = computed(() => isLibrary.value ? 'Lua Library' : isProcess.value ? 'Lua Process' : 'Lua Function')
const hasImports = computed(() => data.value.imports && Object.keys(data.value.imports).length > 0)
const hasModules = computed(() => data.value.modules && data.value.modules.length > 0)
const hasSource = computed(() => data.value.source !== undefined)

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
  <div class="flex flex-col h-full">
    <!-- Tab bar -->
    <div v-if="hasSource" class="shrink-0 flex gap-0 px-4 pt-2" style="border-bottom: 1px solid var(--p-content-border-color)">
      <button
        v-for="tab in (['general', 'source'] as const)" :key="tab"
        class="px-3 py-1.5 text-[11px] font-medium"
        :style="{
          color: activeTab === tab ? 'var(--p-text-color)' : 'var(--p-text-muted-color)',
          borderBottom: activeTab === tab ? '2px solid var(--p-primary)' : '2px solid transparent',
        }"
        @click="activeTab = tab"
      >
        <Icon :icon="tab === 'source' ? 'tabler:code' : 'tabler:info-circle'" class="w-3 h-3 inline mr-1" />
        {{ tab === 'source' ? 'Source' : 'General' }}
      </button>
    </div>

    <!-- General tab -->
    <div v-show="activeTab === 'general'" class="flex-1 overflow-y-auto">
      <div class="space-y-3 p-4">
        <EditorSection icon="tabler:file-description" title="Description" :description="'Details and purpose of this ' + kindLabel.toLowerCase() + '.'">
          <textarea
            :value="meta.comment || ''"
            @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
            class="ed-textarea"
            rows="3"
            placeholder="Enter description..."
          ></textarea>
        </EditorSection>

        <EditorSection v-if="data.method" icon="tabler:terminal-2" title="Execution Method">
          <div class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.method }}</div>
        </EditorSection>

        <EditorSection v-if="hasImports || hasModules" icon="tabler:puzzle" title="Dependencies & Modules" description="Registry entries and Lua modules this function relies on.">
          <div v-if="hasImports" class="mb-3">
            <div class="text-[10px] font-medium mb-1.5" style="color: var(--p-text-muted-color)">Registry Dependencies</div>
            <div class="flex flex-wrap gap-1.5">
              <LinkBadge v-for="(path, name) in data.imports" :key="String(name)" :id="String(path)" icon="tabler:external-link" @navigate="emit('navigate', $event)" />
            </div>
          </div>
          <div v-if="hasModules" :class="{ 'pt-3': hasImports }" :style="hasImports ? { borderTop: '1px solid var(--p-surface-200)' } : {}">
            <div class="text-[10px] font-medium mb-1.5" style="color: var(--p-text-muted-color)">Required Lua Modules</div>
            <div class="flex flex-wrap gap-1.5">
              <span v-for="mod in data.modules" :key="mod" class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-200); color: var(--p-text-color)">
                <Icon icon="tabler:cube" class="w-3 h-3" />{{ mod }}
              </span>
            </div>
          </div>
        </EditorSection>

        <EditorSection v-if="isProcess && data.pool !== undefined" icon="tabler:stack-2" title="Pool Configuration" description="Settings for the Lua instance execution pool.">
          <div class="grid grid-cols-2 gap-3">
            <FieldRow label="Auto Start">
              <BoolField :model-value="data.auto_start ?? false" @update:model-value="emitData('auto_start', $event)" />
            </FieldRow>
            <FieldRow label="Pool Size">
              <NumberField :model-value="data.pool?.size ?? 1" @update:model-value="emitData('pool', { ...data.pool, size: $event })" :min="1" :max="100" />
            </FieldRow>
          </div>
          <div v-if="data.pool?.min !== undefined || data.pool?.max !== undefined" class="grid grid-cols-2 gap-3 mt-2">
            <div v-if="data.pool?.min !== undefined" class="flex flex-col">
              <span class="text-[10px]" style="color: var(--p-text-muted-color)">Min Workers</span>
              <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.min }}</span>
            </div>
            <div v-if="data.pool?.max !== undefined" class="flex flex-col">
              <span class="text-[10px]" style="color: var(--p-text-muted-color)">Max Workers</span>
              <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.max }}</span>
            </div>
          </div>
        </EditorSection>

        <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:link" title="Dependencies" description="Other registry entries this function relies on.">
          <div class="flex flex-wrap gap-1.5">
            <LinkBadge v-for="dep in meta.depends_on" :key="dep" :id="dep" icon="tabler:link" @navigate="emit('navigate', $event)" />
          </div>
        </EditorSection>
      </div>
    </div>

    <!-- Source tab -->
    <div v-if="hasSource" v-show="activeTab === 'source'" style="flex: 1 1 0; min-height: 0; overflow: hidden;">
      <MonacoEditor
        :model-value="data.source || ''"
        @update:model-value="emitData('source', $event)"
        language="lua"
        :min-height="0"
        style="height: 100%"
      />
    </div>
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
.ed-textarea:focus {
  border-color: var(--p-primary);
}
</style>
