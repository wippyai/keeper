<script setup lang="ts">
import { ref, watch } from 'vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import JsonField from '../fields/JsonField.vue'

const props = defineProps<{
  entry: RegistryEntry
  detail: any
}>()

const emit = defineEmits<{
  update: [updates: { kind?: string; meta?: Record<string, any>; data?: Record<string, any> }]
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

function onMetaChange(v: any) {
  meta.value = v
  emit('update', { meta: v })
}

function onDataChange(v: any) {
  data.value = v
  emit('update', { data: v })
}
</script>

<template>
  <div class="space-y-3 p-4">
    <!-- Description (if comment exists) -->
    <EditorSection icon="tabler:file-description" title="Description" description="General notes about this entry.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter description..."
      ></textarea>
    </EditorSection>

    <!-- Entry Info -->
    <EditorSection icon="tabler:info-circle" title="Entry" description="Basic entry identification.">
      <div class="space-y-1.5">
        <div class="flex justify-between text-[11px]">
          <span style="color: var(--p-text-muted-color)">ID</span>
          <span class="font-mono" style="color: var(--p-text-color)">{{ entry.id }}</span>
        </div>
        <div class="flex justify-between text-[11px]">
          <span style="color: var(--p-text-muted-color)">Kind</span>
          <span style="color: var(--p-text-color)">{{ entry.kind }}</span>
        </div>
        <div v-if="meta.type" class="flex justify-between text-[11px]">
          <span style="color: var(--p-text-muted-color)">Type</span>
          <span style="color: var(--p-text-color)">{{ meta.type }}</span>
        </div>
      </div>
    </EditorSection>

    <EditorSection icon="tabler:code" title="Meta (JSON)" description="Entry metadata as raw JSON. Edit carefully.">
      <JsonField v-model="meta" :rows="8" @update:model-value="onMetaChange" />
    </EditorSection>

    <EditorSection icon="tabler:database" title="Data (JSON)" description="Entry data payload as raw JSON. Edit carefully.">
      <JsonField v-model="data" :rows="10" @update:model-value="onDataChange" />
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
.ed-textarea:focus { border-color: var(--p-primary); }
</style>
