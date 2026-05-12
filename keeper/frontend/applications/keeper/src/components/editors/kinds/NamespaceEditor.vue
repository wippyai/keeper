<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import FieldRow from '../fields/FieldRow.vue'
import StringField from '../fields/StringField.vue'
import ArrayField from '../fields/ArrayField.vue'
import MapField from '../fields/MapField.vue'
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

const kindLabel = computed(() => {
  const m: Record<string, string> = {
    'ns.definition': 'Namespace Definition',
    'ns.dependency': 'Namespace Dependency',
    'ns.requirement': 'Namespace Requirement',
  }
  return m[props.entry.kind] || 'Namespace'
})

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
    <EditorSection icon="tabler:file-description" title="Description" description="Notes about this namespace entry.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        :placeholder="'Enter ' + kindLabel.toLowerCase() + ' description...'"
      ></textarea>
    </EditorSection>

    <EditorSection icon="tabler:package" :title="kindLabel" description="Namespace identity and version information.">
      <div class="space-y-2">
        <FieldRow v-if="data.namespace !== undefined" label="Namespace">
          <StringField :model-value="data.namespace || ''" readonly mono />
        </FieldRow>
        <FieldRow v-if="data.version !== undefined" label="Version">
          <StringField :model-value="data.version || ''" readonly mono />
        </FieldRow>
      </div>
    </EditorSection>

    <EditorSection v-if="data.requires !== undefined && data.requires.length > 0" icon="tabler:plug" title="Requires" description="Namespaces that must be present for this one to function.">
      <div class="flex flex-wrap gap-1.5">
        <LinkBadge v-for="req in data.requires" :key="req" :id="req" icon="tabler:plug" @navigate="emit('navigate', $event)" />
      </div>
    </EditorSection>

    <EditorSection v-if="data.provides !== undefined && data.provides.length > 0" icon="tabler:package" title="Provides" description="Capabilities this namespace provides to others.">
      <div class="flex flex-wrap gap-1.5">
        <span v-for="cap in data.provides" :key="cap" class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px]" style="background: var(--p-surface-200); color: var(--p-text-color)">{{ cap }}</span>
      </div>
    </EditorSection>

    <EditorSection v-if="data.options !== undefined && Object.keys(data.options).length > 0" icon="tabler:adjustments" title="Options" description="Additional namespace options.">
      <MapField :model-value="data.options || {}" @update:model-value="emitData('options', $event)" />
    </EditorSection>

    <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:link" title="Dependencies" description="Other registry entries this namespace depends on.">
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
</style>
