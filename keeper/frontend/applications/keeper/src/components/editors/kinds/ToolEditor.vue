<script setup lang="ts">
import { ref, watch, computed, defineAsyncComponent } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import StringField from '../fields/StringField.vue'
import TextField from '../fields/TextField.vue'
import JsonField from '../fields/JsonField.vue'
import TagsField from '../fields/TagsField.vue'
import LinkBadge from '../fields/LinkBadge.vue'

const MonacoEditor = defineAsyncComponent(() => import('../fields/MonacoEditor.vue'))

const props = defineProps<{ entry: RegistryEntry; detail: any }>()
const emit = defineEmits<{
  update: [updates: { meta?: Record<string, any>; data?: Record<string, any> }]
  navigate: [id: string]
}>()

const meta = ref<Record<string, any>>({})
const data = ref<Record<string, any>>({})
const schemaTab = ref<'input' | 'output'>('input')
const mainTab = ref<'tool' | 'function' | 'source'>('tool')

const isFunction = computed(() => props.entry.kind === 'function.lua' || props.entry.kind === 'library.lua' || props.entry.kind === 'process.lua')
const hasSource = computed(() => data.value.source !== undefined)
const hasImports = computed(() => data.value.imports && Object.keys(data.value.imports).length > 0)
const hasModules = computed(() => data.value.modules && data.value.modules.length > 0)

watch(() => props.detail, (d) => {
  const e = d?.entry || props.entry
  meta.value = JSON.parse(JSON.stringify(e.meta || {}))
  data.value = JSON.parse(JSON.stringify(e.data || {}))
}, { immediate: true })

function emitMeta(key: string, value: any) { meta.value[key] = value; emit('update', { meta: { [key]: value } }) }
function emitData(key: string, value: any) { data.value[key] = value; emit('update', { data: { [key]: value } }) }

function parseSchema(raw: any): any {
  if (!raw) return null
  if (typeof raw === 'string') { try { return JSON.parse(raw) } catch { return null } }
  return raw
}

const inputSchema = computed(() => parseSchema(meta.value.input_schema || data.value.input_schema))
const outputSchema = computed(() => parseSchema(meta.value.output_schema || data.value.output_schema))

const schemaProperties = computed(() => {
  const schema = schemaTab.value === 'input' ? inputSchema.value : outputSchema.value
  if (!schema?.properties) return []
  return Object.entries(schema.properties).map(([name, prop]: [string, any]) => ({
    name,
    type: prop.type || (prop.enum ? 'enum' : 'any'),
    description: prop.description || '',
    required: (schema.required || []).includes(name),
    enum: prop.enum,
    default: prop.default,
    items: prop.items,
  }))
})

function entryName(id: string): string {
  const idx = id.indexOf(':')
  return idx >= 0 ? id.slice(idx + 1) : id
}

function typeColor(t: string): string {
  const m: Record<string, string> = {
    string: 'var(--p-success-500)', number: 'var(--p-accent-500)', integer: 'var(--p-accent-500)',
    boolean: 'var(--p-warn-500)', array: 'var(--p-info-500)', object: 'var(--p-accent-400)', enum: 'var(--p-info-500)',
  }
  return m[t] || 'var(--p-text-muted-color)'
}

const availableTabs = computed(() => {
  const tabs = [{ id: 'tool', icon: 'tabler:tool', label: 'Tool' }]
  if (isFunction.value) tabs.push({ id: 'function', icon: 'tabler:code', label: 'Function' })
  if (hasSource.value) tabs.push({ id: 'source', icon: 'tabler:file-code', label: 'Source' })
  return tabs
})
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Tabs -->
    <div v-if="availableTabs.length > 1" class="shrink-0 flex gap-0 px-3 pt-1" style="border-bottom: 1px solid var(--p-content-border-color)">
      <button v-for="t in availableTabs" :key="t.id" class="tab-btn" :class="{ 'tab-btn--active': mainTab === t.id }" @click="mainTab = t.id as any">
        <Icon :icon="t.icon" class="w-3 h-3" /> {{ t.label }}
      </button>
    </div>

    <!-- TOOL TAB -->
    <div v-show="mainTab === 'tool'" class="flex-1 overflow-y-auto">
      <div class="space-y-3 p-4">
        <!-- Identity -->
        <EditorSection icon="tabler:tool" title="Tool Identity" description="Display name and LLM-facing configuration.">
          <div class="id-grid">
            <label class="lbl">Title</label>
            <StringField :model-value="meta.title || ''" @update:model-value="emitMeta('title', $event)" placeholder="Tool display name" />
            <label class="lbl">LLM Alias</label>
            <StringField :model-value="meta.llm_alias || ''" @update:model-value="emitMeta('llm_alias', $event)" mono placeholder="FunctionName" />
            <label class="lbl">Tags</label>
            <TagsField :model-value="meta.tags || []" @update:model-value="emitMeta('tags', $event)" placeholder="tag" />
          </div>
        </EditorSection>

        <!-- LLM Description -->
        <EditorSection icon="tabler:message" title="LLM Description" description="How the model understands this tool. Be specific about when and how to use it.">
          <TextField :model-value="meta.llm_description || ''" @update:model-value="emitMeta('llm_description', $event)" :rows="4" placeholder="Describe what this tool does..." />
        </EditorSection>

        <!-- Schema -->
        <EditorSection icon="tabler:schema" title="Schema" description="Input and output parameter definitions for the LLM.">
          <div class="flex gap-0 mb-3">
            <button class="schema-tab" :class="{ 'schema-tab--active': schemaTab === 'input' }" @click="schemaTab = 'input'">
              <Icon icon="tabler:arrow-down" class="w-3 h-3" /> Input
              <span v-if="inputSchema?.properties" class="cnt">{{ Object.keys(inputSchema.properties).length }}</span>
            </button>
            <button class="schema-tab" :class="{ 'schema-tab--active': schemaTab === 'output' }" @click="schemaTab = 'output'">
              <Icon icon="tabler:arrow-up" class="w-3 h-3" /> Output
              <span v-if="outputSchema?.properties" class="cnt">{{ Object.keys(outputSchema.properties).length }}</span>
            </button>
          </div>

          <div v-if="schemaProperties.length > 0" class="space-y-1.5">
            <div v-for="prop in schemaProperties" :key="prop.name" class="prop-row">
              <div class="flex items-center gap-2">
                <span class="text-[11px] font-mono font-medium" style="color: var(--p-text-color)">{{ prop.name }}</span>
                <span class="text-[8px] px-1 rounded font-mono" :style="{ background: typeColor(prop.type) + '20', color: typeColor(prop.type) }">{{ prop.type }}</span>
                <span v-if="prop.required" class="text-[8px] px-1 rounded" style="background: rgba(248,113,113,0.15); color: var(--p-danger-500)">required</span>
              </div>
              <div v-if="prop.description" class="text-[9px] mt-0.5" style="color: var(--p-text-muted-color)">{{ prop.description }}</div>
              <div class="flex gap-3 mt-0.5 text-[9px]">
                <span v-if="prop.enum" style="color: var(--p-text-muted-color)">values: <span class="font-mono" style="color: var(--p-info-500)">{{ prop.enum.join(', ') }}</span></span>
                <span v-if="prop.default !== undefined" style="color: var(--p-text-muted-color)">default: <span class="font-mono" style="color: var(--p-text-color)">{{ prop.default }}</span></span>
                <span v-if="prop.items?.type" style="color: var(--p-text-muted-color)">items: <span class="font-mono" :style="{ color: typeColor(prop.items.type) }">{{ prop.items.type }}</span></span>
              </div>
            </div>
          </div>
          <div v-else class="text-[11px]" style="color: var(--p-text-muted-color)">
            No {{ schemaTab }} schema defined
          </div>

          <div class="mt-3 pt-3" style="border-top: 1px solid var(--p-content-border-color)">
            <div class="text-[9px] font-medium mb-1" style="color: var(--p-text-muted-color)">Raw {{ schemaTab }} schema</div>
            <JsonField
              v-if="schemaTab === 'input'"
              :model-value="meta.input_schema || data.input_schema || ''"
              @update:model-value="emitMeta('input_schema', typeof $event === 'string' ? $event : JSON.stringify($event, null, 2))"
              :rows="8"
            />
            <JsonField
              v-else
              :model-value="meta.output_schema || data.output_schema || ''"
              @update:model-value="emitMeta('output_schema', typeof $event === 'string' ? $event : JSON.stringify($event, null, 2))"
              :rows="8"
            />
          </div>
        </EditorSection>

        <!-- Notes -->
        <EditorSection icon="tabler:file-description" title="Internal Notes" description="Developer notes about this tool.">
          <textarea :value="meta.comment || ''" @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)" class="ed-ta" rows="2" placeholder="Internal notes..."></textarea>
        </EditorSection>

        <!-- Dependencies -->
        <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:link" title="Dependencies" description="Registry entries this tool depends on.">
          <div class="flex flex-wrap gap-1.5">
            <LinkBadge v-for="dep in meta.depends_on" :key="dep" :id="dep" @navigate="emit('navigate', $event)" />
          </div>
        </EditorSection>
      </div>
    </div>

    <!-- FUNCTION TAB -->
    <div v-if="isFunction" v-show="mainTab === 'function'" class="flex-1 overflow-y-auto">
      <div class="space-y-3 p-4">
        <EditorSection v-if="data.method" icon="tabler:terminal-2" title="Execution Method" description="How the runtime invokes this function.">
          <div class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.method }}</div>
        </EditorSection>

        <EditorSection v-if="hasImports || hasModules" icon="tabler:puzzle" title="Dependencies & Modules" description="Registry imports and Lua modules required at runtime.">
          <div v-if="hasImports" class="mb-3">
            <div class="text-[10px] font-medium mb-1.5" style="color: var(--p-text-muted-color)">Registry Imports</div>
            <div class="flex flex-wrap gap-1.5">
              <LinkBadge v-for="(path, name) in data.imports" :key="String(name)" :id="String(path)" icon="tabler:external-link" @navigate="emit('navigate', $event)" />
            </div>
          </div>
          <div v-if="hasModules" :class="{ 'pt-3': hasImports }" :style="hasImports ? { borderTop: '1px solid var(--p-surface-200)' } : {}">
            <div class="text-[10px] font-medium mb-1.5" style="color: var(--p-text-muted-color)">Lua Modules</div>
            <div class="flex flex-wrap gap-1.5">
              <span v-for="mod in data.modules" :key="mod" class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-200); color: var(--p-text-color)">
                <Icon icon="tabler:cube" class="w-3 h-3" />{{ mod }}
              </span>
            </div>
          </div>
        </EditorSection>

        <EditorSection v-if="data.pool" icon="tabler:stack-2" title="Pool Configuration" description="Worker pool settings for this function.">
          <div class="id-grid">
            <label class="lbl">Size</label>
            <span class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ data.pool.size || '-' }}</span>
          </div>
        </EditorSection>
      </div>
    </div>

    <!-- SOURCE TAB -->
    <div v-if="hasSource" v-show="mainTab === 'source'" style="flex: 1 1 0; min-height: 0; overflow: hidden;">
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
.tab-btn {
  display: flex; align-items: center; gap: 4px;
  padding: 6px 8px; font-size: 10px; font-weight: 500;
  color: var(--p-text-muted-color); border-bottom: 2px solid transparent;
}
.tab-btn--active { color: var(--p-text-color); border-bottom-color: var(--p-primary); }
.id-grid { display: grid; grid-template-columns: 64px 1fr; gap: 6px 8px; align-items: center; }
.lbl { font-size: 10px; font-weight: 500; color: var(--p-text-muted-color); }
.ed-ta {
  width: 100%; padding: 6px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none; resize: vertical;
  min-height: 40px; line-height: 1.5;
}
.ed-ta:focus { border-color: var(--p-primary); }
.schema-tab {
  display: flex; align-items: center; gap: 4px;
  padding: 4px 10px; font-size: 10px; font-weight: 500;
  color: var(--p-text-muted-color); background: none; border: 1px solid var(--p-content-border-color);
  cursor: pointer; border-radius: 4px 4px 0 0;
}
.schema-tab--active { color: var(--p-text-color); background: var(--p-surface-0); border-bottom-color: var(--p-surface-0); }
.cnt { font-size: 8px; padding: 0 4px; border-radius: 6px; background: var(--p-surface-200); }
.prop-row {
  padding: 6px 8px; border-radius: 4px;
  background: var(--p-surface-0); border: 1px solid var(--p-content-border-color);
}
</style>
