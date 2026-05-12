<script setup lang="ts">
import { ref, watch } from 'vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import StringField from '../fields/StringField.vue'
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
    <EditorSection icon="tabler:file-description" title="Description" description="Notes about this page.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter description..."
      ></textarea>
    </EditorSection>

    <EditorSection icon="tabler:browser" title="Page Configuration" description="URL path, icon, and display title for navigation.">
      <div class="space-y-2">
        <FieldRow label="URL">
          <StringField :model-value="data.url || ''" @update:model-value="emitData('url', $event)" mono placeholder="/path" />
        </FieldRow>
        <FieldRow v-if="data.icon !== undefined" label="Icon">
          <StringField :model-value="data.icon || ''" @update:model-value="emitData('icon', $event)" />
        </FieldRow>
        <FieldRow v-if="meta.title !== undefined" label="Title">
          <StringField :model-value="meta.title || ''" @update:model-value="emitMeta('title', $event)" />
        </FieldRow>
      </div>
    </EditorSection>

    <EditorSection v-if="data.proxy !== undefined" icon="tabler:arrows-exchange" title="Proxy Config" description="Proxy configuration for embedding external content.">
      <JsonField :model-value="data.proxy" @update:model-value="emitData('proxy', $event)" :rows="6" />
    </EditorSection>

    <EditorSection v-if="data.options !== undefined && Object.keys(data.options).length > 0" icon="tabler:adjustments" title="Options" description="Additional page options.">
      <MapField :model-value="data.options || {}" @update:model-value="emitData('options', $event)" />
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
