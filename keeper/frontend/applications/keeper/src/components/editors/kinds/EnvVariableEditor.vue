<script setup lang="ts">
import { ref, watch } from 'vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import StringField from '../fields/StringField.vue'
import BoolField from '../fields/BoolField.vue'

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

function emitData(key: string, value: any) {
  data.value[key] = value
  emit('update', { data: { [key]: value } })
}
</script>

<template>
  <div class="space-y-3 p-4">
    <EditorSection icon="tabler:file-description" title="Description" description="Notes about this environment variable.">
      <textarea
        :value="meta.comment || meta.description || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter description..."
      ></textarea>
    </EditorSection>

    <EditorSection icon="tabler:variable" title="Variable Configuration" description="Variable name, default value, and storage backend.">
      <div class="space-y-2">
        <FieldRow label="Variable">
          <StringField :model-value="data.variable || ''" @update:model-value="emitData('variable', $event)" mono />
        </FieldRow>
        <FieldRow label="Default">
          <StringField :model-value="data.default || ''" @update:model-value="emitData('default', $event)" />
        </FieldRow>
        <FieldRow v-if="data.storage !== undefined" label="Storage">
          <StringField :model-value="data.storage || ''" readonly mono />
        </FieldRow>
        <FieldRow v-if="data.secure !== undefined" label="Secure">
          <BoolField :model-value="data.secure ?? false" @update:model-value="emitData('secure', $event)" />
        </FieldRow>
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
