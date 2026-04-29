<script setup lang="ts">
import { ref, watch } from 'vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
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
</script>

<template>
  <div class="space-y-3 p-4">
    <EditorSection icon="tabler:file-description" title="Description" description="Purpose and behavior of this router.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter router description..."
      ></textarea>
    </EditorSection>

    <EditorSection v-if="data.prefix" icon="tabler:route" title="Router Path" description="Base path prefix applied to all endpoints under this router.">
      <div class="text-[11px] font-mono px-2 py-1.5 rounded" style="background: var(--p-surface-0); color: var(--p-text-color)">{{ data.prefix }}</div>
    </EditorSection>

    <EditorSection v-if="data.mount_path" icon="tabler:map-pin" title="Mount Path" description="Where this router is mounted in the HTTP server.">
      <div class="text-[11px] font-mono px-2 py-1.5 rounded" style="background: var(--p-surface-0); color: var(--p-text-color)">{{ data.mount_path }}</div>
    </EditorSection>

    <EditorSection v-if="meta.server" icon="tabler:server" title="Server" description="The HTTP server this router is attached to.">
      <LinkBadge :id="meta.server" icon="tabler:server-2" @navigate="emit('navigate', $event)" />
    </EditorSection>

    <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:puzzle" title="Dependencies" description="Other registry entries this router depends on.">
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
.ed-textarea:focus { border-color: var(--p-primary); }
</style>
