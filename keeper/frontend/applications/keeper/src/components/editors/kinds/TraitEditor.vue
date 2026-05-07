<script setup lang="ts">
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import TextField from '../fields/TextField.vue'
import ArrayField from '../fields/ArrayField.vue'
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

function emitData(key: string, value: any) {
  data.value[key] = value
  emit('update', { data: { [key]: value } })
}
</script>

<template>
  <div class="space-y-3 p-4">
    <!-- Identity -->
    <EditorSection icon="tabler:info-circle" title="Identity" description="Trait display name and metadata.">
      <div class="space-y-2">
        <div>
          <label class="text-[10px] font-medium" style="color: var(--p-text-muted-color)">Title</label>
          <input :value="meta.title || ''" @input="emitMeta('title', ($event.target as HTMLInputElement).value)" class="ed-input" placeholder="Trait display name" />
        </div>
        <div>
          <label class="text-[10px] font-medium" style="color: var(--p-text-muted-color)">Description</label>
          <textarea :value="meta.comment || ''" @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)" class="ed-textarea" rows="3" placeholder="What behavior does this trait add?"></textarea>
        </div>
      </div>
    </EditorSection>

    <!-- Prompt -->
    <EditorSection icon="tabler:message" title="Trait Prompt" description="The system prompt injected when this trait is applied.">
      <TextField
        :model-value="data.prompt || ''"
        @update:model-value="emitData('prompt', $event)"
        mono
        :rows="10"
        placeholder="Trait prompt..."
      />
    </EditorSection>

    <!-- Functions (read-only) -->
    <EditorSection v-if="data.build_func_id || data.prompt_func_id || data.step_func_id" icon="tabler:code" title="Trait Functions" description="Internal functions that implement trait behavior. Read-only.">
      <div class="space-y-2">
        <div v-if="data.build_func_id" class="flex items-center gap-2">
          <span class="text-[10px] w-16 shrink-0" style="color: var(--p-text-muted-color)">Build</span>
          <LinkBadge :id="data.build_func_id" icon="tabler:hammer" @navigate="emit('navigate', $event)" />
        </div>
        <div v-if="data.prompt_func_id" class="flex items-center gap-2">
          <span class="text-[10px] w-16 shrink-0" style="color: var(--p-text-muted-color)">Prompt</span>
          <LinkBadge :id="data.prompt_func_id" icon="tabler:message" @navigate="emit('navigate', $event)" />
        </div>
        <div v-if="data.step_func_id" class="flex items-center gap-2">
          <span class="text-[10px] w-16 shrink-0" style="color: var(--p-text-muted-color)">Step</span>
          <LinkBadge :id="data.step_func_id" icon="tabler:arrow-right" @navigate="emit('navigate', $event)" />
        </div>
      </div>
    </EditorSection>

    <!-- Tools -->
    <EditorSection v-if="data.tools !== undefined" icon="tabler:tool" title="Tools" description="Tools injected into the agent when this trait is applied.">
      <ArrayField :model-value="data.tools || []" @update:model-value="emitData('tools', $event)" placeholder="Tool name" />
    </EditorSection>

    <!-- Class -->
    <EditorSection v-if="data.class !== undefined && data.class.length > 0" icon="tabler:category" title="Class" description="Agent classes that can use this trait.">
      <div class="flex flex-wrap gap-1.5">
        <span v-for="c in data.class" :key="c" class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-200); color: var(--p-text-color)">{{ c }}</span>
      </div>
    </EditorSection>

    <!-- Context (read-only) -->
    <EditorSection v-if="data.context" icon="tabler:clipboard-list" title="Default Context" description="Default context values passed to trait functions.">
      <pre class="text-[10px] font-mono whitespace-pre-wrap" style="color: var(--p-text-color)">{{ JSON.stringify(data.context, null, 2) }}</pre>
    </EditorSection>

    <!-- Dependencies -->
    <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:link" title="Dependencies" description="Registry entries this trait depends on.">
      <div class="flex flex-wrap gap-1.5">
        <LinkBadge v-for="dep in meta.depends_on" :key="dep" :id="dep" @navigate="emit('navigate', $event)" />
      </div>
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
.ed-input {
  width: 100%; padding: 4px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}
.ed-input:focus { border-color: var(--p-primary-color); }
</style>
