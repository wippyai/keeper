<script setup lang="ts">
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import TextField from '../fields/TextField.vue'
import ArrayField from '../fields/ArrayField.vue'
import TagsField from '../fields/TagsField.vue'
import SliderField from '../fields/SliderField.vue'
import ModelSelect from '../fields/ModelSelect.vue'
import EntryPicker from '../fields/EntryPicker.vue'
import LinkBadge from '../fields/LinkBadge.vue'
import JsonField from '../fields/JsonField.vue'

const props = defineProps<{ entry: RegistryEntry; detail: any }>()
const emit = defineEmits<{
  update: [updates: { meta?: Record<string, any>; data?: Record<string, any> }]
  navigate: [id: string]
}>()

const meta = ref<Record<string, any>>({})
const data = ref<Record<string, any>>({})
const tab = ref<string>('basic')
const expandedTools = ref<Set<number>>(new Set())
const expandedTraits = ref<Set<number>>(new Set())
const expandedDelegates = ref<Set<number>>(new Set())

watch(() => props.detail, (d) => {
  const e = d?.entry || props.entry
  meta.value = JSON.parse(JSON.stringify(e.meta || {}))
  data.value = JSON.parse(JSON.stringify(e.data || {}))
  if (!data.value.delegates) data.value.delegates = []
  if (!data.value.traits) data.value.traits = []
  if (!data.value.tools) data.value.tools = []
  if (!data.value.memory) data.value.memory = []
  if (!data.value.start_prompts) data.value.start_prompts = []
}, { immediate: true })

function emitMeta(key: string, value: any) { meta.value[key] = value; emit('update', { meta: { [key]: value } }) }
function emitData(key: string, value: any) { data.value[key] = value; emit('update', { data: { [key]: value } }) }

function toolId(t: any): string { return typeof t === 'string' ? t : t.id || t }
function toolObj(t: any): any { return typeof t === 'string' ? { id: t } : { ...t } }

function addTool(id: string) {
  if (data.value.tools.some((t: any) => toolId(t) === id)) return
  emitData('tools', [...data.value.tools, id])
}
function removeTool(id: string) { emitData('tools', data.value.tools.filter((t: any) => toolId(t) !== id)) }
function updateToolProp(i: number, key: string, val: any) {
  const tools = [...data.value.tools]
  const obj = toolObj(tools[i])
  obj[key] = val
  if (key === 'alias' && !val) delete obj.alias
  if (key === 'description' && !val) delete obj.description
  if (key === 'context' && (!val || Object.keys(val).length === 0)) delete obj.context
  tools[i] = Object.keys(obj).length === 1 && obj.id ? obj.id : obj
  emitData('tools', tools)
}

function traitId(t: any): string { return typeof t === 'string' ? t : t.id || t }
function traitObj(t: any): any { return typeof t === 'string' ? { id: t } : { ...t } }
function addTrait(id: string) {
  if (data.value.traits.some((t: any) => traitId(t) === id)) return
  emitData('traits', [...data.value.traits, id])
}
function removeTrait(id: string) { emitData('traits', data.value.traits.filter((t: any) => traitId(t) !== id)) }
function updateTraitProp(i: number, key: string, val: any) {
  const traits = [...data.value.traits]
  const obj = traitObj(traits[i])
  obj[key] = val
  if (key === 'context' && (!val || Object.keys(val).length === 0)) delete obj.context
  traits[i] = Object.keys(obj).length === 1 && obj.id ? obj.id : obj
  emitData('traits', traits)
}

function addDelegate() { emitData('delegates', [...data.value.delegates, { name: '', id: '', rule: '' }]) }
function removeDelegate(i: number) { const d = [...data.value.delegates]; d.splice(i, 1); emitData('delegates', d) }
function updateDelegate(i: number, key: string, val: any) {
  const d = [...data.value.delegates]; d[i] = { ...d[i], [key]: val }; emitData('delegates', d)
}

function addStartPrompt() { emitData('start_prompts', [...data.value.start_prompts, '']) }
function removeStartPrompt(i: number) { const a = [...data.value.start_prompts]; a.splice(i, 1); emitData('start_prompts', a) }
function updateStartPrompt(i: number, v: string) { const a = [...data.value.start_prompts]; a[i] = v; emitData('start_prompts', a) }

function fmtTokens(v: number): string { return v >= 1000 ? (v / 1000) + 'K' : String(v) }

const tabs = [
  { id: 'basic', icon: 'tabler:file-text', label: 'Basic' },
  { id: 'model', icon: 'tabler:brain', label: 'Model' },
  { id: 'delegates', icon: 'tabler:users', label: 'Delegates' },
  { id: 'traits', icon: 'tabler:sparkles', label: 'Traits' },
  { id: 'tools', icon: 'tabler:tool', label: 'Tools' },
  { id: 'memory', icon: 'tabler:database', label: 'Memory' },
  { id: 'prompts', icon: 'tabler:message', label: 'Prompts' },
]
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="shrink-0 flex gap-0 px-3 pt-1" style="border-bottom: 1px solid var(--p-content-border-color)">
      <button v-for="t in tabs" :key="t.id" class="tab-btn" :class="{ 'tab-btn--active': tab === t.id }" @click="tab = t.id">
        <Icon :icon="t.icon" class="w-3 h-3" /> {{ t.label }}
        <span v-if="t.id === 'delegates' && data.delegates?.length" class="tab-cnt">{{ data.delegates.length }}</span>
        <span v-if="t.id === 'traits' && data.traits?.length" class="tab-cnt">{{ data.traits.length }}</span>
        <span v-if="t.id === 'tools' && data.tools?.length" class="tab-cnt">{{ data.tools.length }}</span>
      </button>
    </div>

    <div class="flex-1 overflow-y-auto">
      <!-- BASIC -->
      <div v-show="tab === 'basic'" class="space-y-3 p-4">
        <EditorSection icon="tabler:info-circle" title="Identity" description="Agent display name, icon, and metadata.">
          <div class="id-grid">
            <label class="field-label">Title</label>
            <input :value="meta.title || ''" @input="emitMeta('title', ($event.target as HTMLInputElement).value)" class="ed-in" placeholder="e.g. Research Assistant" />
            <label class="field-label">Icon</label>
            <input :value="meta.icon || ''" @input="emitMeta('icon', ($event.target as HTMLInputElement).value)" class="ed-in" placeholder="tabler:robot" />
            <label class="field-label">Tags</label>
            <TagsField :model-value="meta.tags || []" @update:model-value="emitMeta('tags', $event)" placeholder="tag" />
          </div>
        </EditorSection>

        <EditorSection icon="tabler:file-description" title="Description" description="Purpose and behavior of this agent. Shown in agent listings and to other agents during delegation.">
          <textarea :value="meta.comment || ''" @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)" class="ed-ta" rows="3" placeholder="What does this agent do?"></textarea>
        </EditorSection>

        <EditorSection icon="tabler:category" title="Classes" description="Controls agent visibility. 'public' makes it available in session start, 'delegate' allows other agents to use it.">
          <TagsField :model-value="meta.class || []" @update:model-value="emitMeta('class', $event)" placeholder="e.g. public, delegate" />
        </EditorSection>

        <EditorSection icon="tabler:message" title="System Prompt" description="The core instruction set that defines agent behavior and personality.">
          <TextField :model-value="data.prompt || ''" @update:model-value="emitData('prompt', $event)" mono :rows="12" placeholder="You are..." />
        </EditorSection>
      </div>

      <!-- MODEL -->
      <div v-show="tab === 'model'" class="space-y-3 p-4">
        <EditorSection icon="tabler:brain" title="Model" description="LLM model used for generation. Different models have different capabilities and pricing.">
          <ModelSelect :model-value="data.model || ''" @update:model-value="emitData('model', $event)" />
        </EditorSection>
        <EditorSection icon="tabler:adjustments" title="Generation Parameters" description="Fine-tune model behavior. These settings affect response quality, length, and cost.">
          <div class="param-grid">
            <span class="field-label">Max Tokens</span>
            <SliderField :model-value="data.max_tokens || 8000" @update:model-value="emitData('max_tokens', $event)" :min="1000" :max="100000" :step="1000" :format-value="fmtTokens" />
            <span class="field-label">Temperature</span>
            <SliderField :model-value="data.temperature ?? 0.7" @update:model-value="emitData('temperature', $event)" :min="0" :max="1" :step="0.1" />
            <span class="field-label">Thinking</span>
            <SliderField :model-value="data.thinking_effort ?? 0" @update:model-value="emitData('thinking_effort', $event)" :min="0" :max="100" :step="5" />
          </div>
        </EditorSection>
      </div>

      <!-- DELEGATES -->
      <div v-show="tab === 'delegates'" class="space-y-3 p-4">
        <EditorSection icon="tabler:users" title="Delegates" description="Other agents that this agent can hand off tasks to. Each delegate becomes a tool the agent can call.">
          <div class="space-y-2">
            <div v-for="(d, i) in data.delegates" :key="i" class="item-card">
              <div class="item-head" @click="expandedDelegates.has(i) ? expandedDelegates.delete(i) : expandedDelegates.add(i)">
                <Icon icon="tabler:robot" class="w-3 h-3 shrink-0" style="color: var(--p-warn-500)" />
                <span class="flex-1 text-[11px] font-mono truncate" style="color: var(--p-text-color)">{{ d.name || d.id || 'New delegate' }}</span>
                <Icon :icon="expandedDelegates.has(i) ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3" style="color: var(--p-text-muted-color)" />
                <Button class="k-btn-icon k-btn-icon-danger !p-0.5" @click.stop="removeDelegate(i)"><Icon icon="tabler:x" class="w-3 h-3" /></Button>
              </div>
              <div v-if="expandedDelegates.has(i)" class="item-body">
                <div class="mb-2">
                  <label class="field-label">Tool Name <span class="field-hint">How this delegate appears as a tool to the agent</span></label>
                  <input :value="d.name" @input="updateDelegate(i, 'name', ($event.target as HTMLInputElement).value)" class="ed-in" placeholder="e.g. research_data" />
                </div>
                <div class="mb-2">
                  <label class="field-label">Agent <span class="field-hint">Target agent to delegate to</span></label>
                  <LinkBadge v-if="d.id" :id="d.id" icon="tabler:robot" @navigate="emit('navigate', $event)" />
                  <EntryPicker v-else meta-type="agent.gen1" :selected="[]" placeholder="Select agent..." icon="tabler:robot" @add="updateDelegate(i, 'id', $event)" />
                </div>
                <div class="mb-2">
                  <label class="field-label">Delegation Rule <span class="field-hint">When should the agent delegate to this one</span></label>
                  <textarea :value="d.rule || ''" @input="updateDelegate(i, 'rule', ($event.target as HTMLTextAreaElement).value)" class="ed-ta" rows="2" placeholder="when you need factual data..."></textarea>
                </div>
                <div>
                  <label class="field-label">Context (JSON) <span class="field-hint">Additional context passed during delegation</span></label>
                  <JsonField :model-value="d.context || {}" @update:model-value="updateDelegate(i, 'context', $event)" :rows="3" />
                </div>
              </div>
            </div>
            <Button class="k-btn-dashed" @click="addDelegate"><Icon icon="tabler:plus" class="w-3 h-3" /> Add Delegate</Button>
          </div>
        </EditorSection>
      </div>

      <!-- TRAITS -->
      <div v-show="tab === 'traits'" class="space-y-3 p-4">
        <EditorSection icon="tabler:sparkles" title="Traits" description="Behavioral extensions that inject additional prompt context, tools, and capabilities into the agent.">
          <div class="space-y-2 mb-2">
            <div v-for="(t, i) in data.traits" :key="i" class="item-card">
              <div class="item-head" @click="expandedTraits.has(i) ? expandedTraits.delete(i) : expandedTraits.add(i)">
                <Icon icon="tabler:sparkles" class="w-3 h-3 shrink-0" style="color: var(--p-accent-400)" />
                <span class="flex-1 text-[11px] font-mono truncate" style="color: var(--p-text-color)">{{ traitId(t) }}</span>
                <Icon :icon="expandedTraits.has(i) ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3" style="color: var(--p-text-muted-color)" />
                <Button class="k-btn-icon k-btn-icon-danger !p-0.5" @click.stop="removeTrait(traitId(t))"><Icon icon="tabler:x" class="w-3 h-3" /></Button>
              </div>
              <div v-if="expandedTraits.has(i)" class="item-body">
                <div class="mb-2">
                  <LinkBadge :id="traitId(t)" icon="tabler:sparkles" @navigate="emit('navigate', $event)" />
                </div>
                <div>
                  <label class="field-label">Context Override (JSON) <span class="field-hint">Override default trait context values</span></label>
                  <JsonField :model-value="traitObj(t).context || {}" @update:model-value="updateTraitProp(i, 'context', $event)" :rows="3" />
                </div>
              </div>
            </div>
          </div>
          <EntryPicker meta-type="agent.trait" :selected="data.traits || []" placeholder="Add trait..." icon="tabler:sparkles" @add="addTrait" @remove="removeTrait" />
        </EditorSection>
      </div>

      <!-- TOOLS -->
      <div v-show="tab === 'tools'" class="space-y-3 p-4">
        <EditorSection icon="tabler:tool" title="Tools" description="Functions the agent can call. Each tool provides a specific capability like web search, file operations, or API calls.">
          <div class="space-y-2 mb-2">
            <div v-for="(t, i) in data.tools" :key="i" class="item-card">
              <div class="item-head" @click="expandedTools.has(i) ? expandedTools.delete(i) : expandedTools.add(i)">
                <Icon icon="tabler:tool" class="w-3 h-3 shrink-0" style="color: var(--p-info-500)" />
                <span class="flex-1 text-[11px] font-mono truncate" style="color: var(--p-text-color)">{{ toolId(t) }}</span>
                <Icon :icon="expandedTools.has(i) ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3" style="color: var(--p-text-muted-color)" />
                <Button class="k-btn-icon k-btn-icon-danger !p-0.5" @click.stop="removeTool(toolId(t))"><Icon icon="tabler:x" class="w-3 h-3" /></Button>
              </div>
              <div v-if="expandedTools.has(i)" class="item-body">
                <div class="mb-2">
                  <LinkBadge :id="toolId(t)" icon="tabler:tool" @navigate="emit('navigate', $event)" />
                </div>
                <div class="mb-2">
                  <label class="field-label">Alias <span class="field-hint">Custom name for this tool when presented to the model</span></label>
                  <input :value="toolObj(t).alias || ''" @input="updateToolProp(i, 'alias', ($event.target as HTMLInputElement).value)" class="ed-in" placeholder="Optional alias" />
                </div>
                <div class="mb-2">
                  <label class="field-label">Description <span class="field-hint">Custom description overriding the tool's default</span></label>
                  <textarea :value="toolObj(t).description || ''" @input="updateToolProp(i, 'description', ($event.target as HTMLTextAreaElement).value)" class="ed-ta" rows="2" placeholder="Custom description..."></textarea>
                </div>
                <div>
                  <label class="field-label">Context (JSON) <span class="field-hint">Additional parameters passed to the tool at runtime</span></label>
                  <JsonField :model-value="toolObj(t).context || {}" @update:model-value="updateToolProp(i, 'context', $event)" :rows="3" />
                </div>
              </div>
            </div>
          </div>
          <EntryPicker meta-type="tool" :selected="data.tools || []" placeholder="Add tool..." icon="tabler:tool" @add="addTool" @remove="removeTool" />
        </EditorSection>
      </div>

      <!-- MEMORY -->
      <div v-show="tab === 'memory'" class="space-y-3 p-4">
        <EditorSection v-if="data.memory_contract" icon="tabler:link" title="Memory Contract" description="Persistent memory implementation bound to this agent. Enables long-term recall across sessions.">
          <FieldRow label="Implementation">
            <LinkBadge v-if="data.memory_contract.implementation_id" :id="data.memory_contract.implementation_id" @navigate="emit('navigate', $event)" />
            <span v-else class="text-[11px]" style="color: var(--p-text-muted-color)">Not configured</span>
          </FieldRow>
          <div v-if="data.memory_contract.context_values" class="mt-2">
            <label class="field-label">Context Values <span class="field-hint">Configuration passed to the memory implementation</span></label>
            <JsonField :model-value="data.memory_contract.context_values" @update:model-value="emitData('memory_contract', { ...data.memory_contract, context_values: $event })" :rows="4" />
          </div>
        </EditorSection>
        <EditorSection icon="tabler:database" title="Static Memory" description="Fixed memory entries loaded at the start of every session. Use for persistent facts or instructions.">
          <ArrayField :model-value="data.memory || []" @update:model-value="emitData('memory', $event)" placeholder="Memory entry..." />
        </EditorSection>
      </div>

      <!-- PROMPTS -->
      <div v-show="tab === 'prompts'" class="space-y-3 p-4">
        <EditorSection icon="tabler:message" title="Start Prompts" description="Suggested prompts displayed when a user starts a new session with this agent. Helps guide initial interaction.">
          <div class="space-y-2">
            <div v-for="(p, i) in data.start_prompts" :key="i" class="flex items-start gap-1.5">
              <textarea :value="p" @input="updateStartPrompt(i, ($event.target as HTMLTextAreaElement).value)" class="ed-ta flex-1" rows="2" placeholder="Ask me about..."></textarea>
              <Button class="k-btn-icon k-btn-icon-danger !p-0.5 mt-1" @click="removeStartPrompt(i)"><Icon icon="tabler:trash" class="w-3 h-3" /></Button>
            </div>
            <Button class="k-btn-dashed" @click="addStartPrompt"><Icon icon="tabler:plus" class="w-3 h-3" /> Add Prompt</Button>
          </div>
        </EditorSection>
      </div>
    </div>
  </div>
</template>

<style scoped>
.tab-btn {
  display: flex; align-items: center; gap: 4px;
  padding: 6px 8px; font-size: 10px; font-weight: 500;
  color: var(--p-text-muted-color); border-bottom: 2px solid transparent;
}
.tab-btn--active { color: var(--p-text-color); border-bottom-color: var(--p-primary-color); }
.tab-cnt { font-size: 8px; padding: 0 4px; border-radius: 6px; background: var(--p-surface-200); }

.item-card { border-radius: 4px; border: 1px solid var(--p-content-border-color); overflow: hidden; }
.item-head {
  display: flex; align-items: center; gap: 6px; padding: 5px 8px; cursor: pointer;
  background: var(--p-surface-0);
}
.item-head:hover { background: var(--p-surface-100); }
.item-body { padding: 8px 10px; border-top: 1px solid var(--p-content-border-color); }

.id-grid {
  display: grid; grid-template-columns: 48px 1fr; gap: 6px 8px; align-items: center;
}
.param-grid {
  display: grid; grid-template-columns: 72px 1fr; gap: 8px 10px; align-items: center;
}
.field-label { font-size: 10px; font-weight: 500; color: var(--p-text-muted-color); }
.field-hint { font-weight: 400; opacity: 0.6; margin-left: 4px; }

.ed-ta {
  width: 100%; padding: 4px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none; resize: vertical;
  min-height: 32px; line-height: 1.5;
}
.ed-ta:focus { border-color: var(--p-primary-color); }
.ed-in {
  width: 100%; padding: 3px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}
.ed-in:focus { border-color: var(--p-primary-color); }

.rm-btn { padding: 2px; border-radius: 3px; color: var(--p-text-muted-color); background: none; border: none; cursor: pointer; }
.rm-btn:hover { color: var(--p-danger-500); background: var(--p-surface-200); }
.add-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px dashed var(--p-surface-300); cursor: pointer;
}
.add-btn:hover { border-color: var(--p-primary-color); }
</style>
