<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import TagsField from '../fields/TagsField.vue'
import JsonField from '../fields/JsonField.vue'

const props = defineProps<{
  entry: RegistryEntry
  detail: any
}>()

const emit = defineEmits<{
  update: [updates: { meta?: Record<string, any>; data?: Record<string, any> }]
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

const methods = computed(() => data.value.methods || [])
</script>

<template>
  <div class="space-y-3 p-4">
    <EditorSection icon="tabler:file-description" title="Description" description="Details and purpose of this contract.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter contract description..."
      ></textarea>
    </EditorSection>

    <EditorSection v-if="meta.tags !== undefined" icon="tabler:tags" title="Tags">
      <TagsField :model-value="Array.isArray(meta.tags) ? meta.tags : (meta.tags || '').split(',').map((s: string) => s.trim()).filter(Boolean)" @update:model-value="emitMeta('tags', $event)" />
    </EditorSection>

    <EditorSection icon="tabler:list" title="Contract Methods" description="Methods defined by this contract.">
      <div v-if="methods.length > 0" class="space-y-2">
        <div v-for="(method, i) in methods" :key="i" class="p-2.5 rounded" style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
          <div class="text-[11px] font-semibold" style="color: var(--p-text-color)">{{ method.name || 'Unnamed' }}</div>
          <div v-if="method.description" class="text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">{{ method.description }}</div>
          <div class="flex gap-3 mt-1.5">
            <span v-if="method.input_schemas" class="text-[9px]" style="color: var(--p-text-muted-color)">
              <Icon icon="tabler:arrow-down" class="w-2.5 h-2.5 inline" /> {{ Array.isArray(method.input_schemas) ? method.input_schemas.length : 0 }} input schemas
            </span>
            <span v-if="method.output_schemas" class="text-[9px]" style="color: var(--p-text-muted-color)">
              <Icon icon="tabler:arrow-up" class="w-2.5 h-2.5 inline" /> {{ Array.isArray(method.output_schemas) ? method.output_schemas.length : 0 }} output schemas
            </span>
          </div>
        </div>
      </div>
      <div v-else class="text-[11px] flex items-center gap-2" style="color: var(--p-text-muted-color)">
        <Icon icon="tabler:info-circle" class="w-3.5 h-3.5" /> No methods defined
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
</style>
