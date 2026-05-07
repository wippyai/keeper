<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import StringField from '../fields/StringField.vue'
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

const methodColors: Record<string, string> = {
  GET: 'var(--p-success-500)', POST: 'var(--p-info-500)', PUT: 'var(--p-warn-500)', DELETE: 'var(--p-danger-500)',
  PATCH: 'var(--p-accent-400)', OPTIONS: 'var(--p-accent-400)', HEAD: 'var(--p-accent-400)',
}

const methodColor = computed(() => methodColors[(data.value.method || 'GET').toUpperCase()] || 'var(--p-text-muted-color)')

const handlerFuncId = computed(() => {
  if (!data.value.func) return ''
  if (data.value.func.includes(':')) return data.value.func
  const ns = props.entry.id.split(':')[0]
  return ns ? `${ns}:${data.value.func}` : data.value.func
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
    <!-- Description -->
    <EditorSection icon="tabler:file-description" title="Description" description="Details and purpose of this HTTP endpoint.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter endpoint description..."
      ></textarea>
    </EditorSection>

    <!-- HTTP Method & Path -->
    <EditorSection icon="tabler:world" title="HTTP Method & Path" description="The HTTP method and URL path pattern for this endpoint.">
      <div class="flex items-start gap-4">
        <div>
          <div class="text-[10px] mb-1" style="color: var(--p-text-muted-color)">Method</div>
          <span class="inline-block px-3 py-1 rounded text-xs font-mono font-bold" :style="{ background: methodColor + '20', color: methodColor }">
            {{ (data.method || 'GET').toUpperCase() }}
          </span>
        </div>
        <div class="flex-1">
          <div class="text-[10px] mb-1" style="color: var(--p-text-muted-color)">Endpoint Path</div>
          <input
            type="text"
            :value="data.path || ''"
            @input="emitData('path', ($event.target as HTMLInputElement).value)"
            class="ed-input font-mono"
            placeholder="/example/path"
          />
        </div>
      </div>
    </EditorSection>

    <!-- Routing & Handler -->
    <EditorSection v-if="meta.router || data.func" icon="tabler:arrows-split" title="Routing & Handler" description="How this endpoint is routed and which function handles requests.">
      <div class="space-y-2">
        <div v-if="meta.router" class="p-2 rounded" style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
          <div class="text-[10px] mb-1" style="color: var(--p-text-muted-color)">Router</div>
          <LinkBadge :id="meta.router" icon="tabler:server-2" @navigate="emit('navigate', $event)" />
        </div>
        <div v-if="data.func" class="p-2 rounded" style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
          <div class="text-[10px] mb-1" style="color: var(--p-text-muted-color)">Handler Function</div>
          <LinkBadge :id="handlerFuncId" icon="tabler:code" @navigate="emit('navigate', $event)" />
        </div>
      </div>
    </EditorSection>

    <!-- Dependencies -->
    <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:puzzle" title="Dependencies" description="Other registry entries this endpoint depends on.">
      <div class="flex flex-wrap gap-1.5">
        <LinkBadge v-for="dep in meta.depends_on" :key="dep" :id="dep" @navigate="emit('navigate', $event)" />
      </div>
    </EditorSection>
  </div>
</template>

<style scoped>
.ed-textarea {
  width: 100%;
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-0);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  resize: vertical;
  min-height: 50px;
  line-height: 1.5;
}
.ed-textarea:focus { border-color: var(--p-primary-color); }
.ed-input {
  width: 100%;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-0);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
}
.ed-input:focus { border-color: var(--p-primary-color); }
</style>
