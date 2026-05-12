<script setup lang="ts">
import { ref, watch } from 'vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import StringField from '../fields/StringField.vue'
import BoolField from '../fields/BoolField.vue'
import MapField from '../fields/MapField.vue'
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

function emitData(key: string, value: any) {
  data.value[key] = value
  emit('update', { data: { [key]: value } })
}
</script>

<template>
  <div class="space-y-3 p-4">
    <EditorSection icon="tabler:file-description" title="Description" description="Purpose and configuration notes for this storage.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        :placeholder="'Enter ' + entry.kind + ' description...'"
      ></textarea>
    </EditorSection>

    <EditorSection icon="tabler:database" :title="entry.kind" description="Connection and path configuration for this storage backend.">
      <div class="space-y-2">
        <FieldRow v-if="data.directory !== undefined" label="Directory">
          <StringField :model-value="data.directory || ''" @update:model-value="emitData('directory', $event)" mono />
        </FieldRow>
        <FieldRow v-if="data.auto_init !== undefined" label="Auto Init">
          <BoolField :model-value="data.auto_init ?? false" @update:model-value="emitData('auto_init', $event)" />
        </FieldRow>
        <FieldRow v-if="data.mode !== undefined" label="Mode">
          <StringField :model-value="data.mode || ''" @update:model-value="emitData('mode', $event)" mono />
        </FieldRow>
        <FieldRow v-if="data.type !== undefined" label="Type">
          <StringField :model-value="data.type || 'standard'" @update:model-value="emitData('type', $event)" />
        </FieldRow>
        <FieldRow v-if="data.driver !== undefined" label="Driver">
          <StringField :model-value="data.driver || ''" readonly mono />
        </FieldRow>
        <FieldRow v-if="data.path !== undefined" label="Path">
          <StringField :model-value="data.path || ''" @update:model-value="emitData('path', $event)" mono />
        </FieldRow>
        <FieldRow v-if="data.dsn !== undefined" label="DSN">
          <StringField :model-value="data.dsn || ''" @update:model-value="emitData('dsn', $event)" mono />
        </FieldRow>
        <FieldRow v-if="data.bucket !== undefined" label="Bucket">
          <StringField :model-value="data.bucket || ''" @update:model-value="emitData('bucket', $event)" mono />
        </FieldRow>
        <FieldRow v-if="data.endpoint !== undefined" label="Endpoint">
          <StringField :model-value="data.endpoint || ''" @update:model-value="emitData('endpoint', $event)" mono />
        </FieldRow>
      </div>
    </EditorSection>

    <EditorSection v-if="data.options !== undefined && Object.keys(data.options).length > 0" icon="tabler:adjustments" title="Options" description="Additional configuration options.">
      <MapField :model-value="data.options || {}" @update:model-value="emitData('options', $event)" />
    </EditorSection>

    <EditorSection v-if="data.schema !== undefined" icon="tabler:schema" title="Schema" description="Database schema definition.">
      <JsonField :model-value="data.schema" @update:model-value="emitData('schema', $event)" :rows="8" />
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
