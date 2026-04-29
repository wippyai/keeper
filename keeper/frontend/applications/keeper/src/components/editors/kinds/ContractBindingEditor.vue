<script setup lang="ts">
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'
import LinkBadge from '../fields/LinkBadge.vue'
import JsonField from '../fields/JsonField.vue'

const props = defineProps<{ entry: RegistryEntry; detail: any }>()
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
    <EditorSection icon="tabler:file-description" title="Description" description="Purpose of this contract binding.">
      <textarea :value="meta.comment || ''" @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)" class="ed-ta" rows="3" placeholder="Binding description..."></textarea>
    </EditorSection>

    <EditorSection icon="tabler:file-certificate" title="Contracts" description="Contract implementations provided by this binding.">
      <div v-if="data.contracts && data.contracts.length > 0" class="space-y-2">
        <div v-for="(c, i) in data.contracts" :key="i" class="bind-card">
          <div class="flex items-center gap-2 mb-2">
            <Icon icon="tabler:file-certificate" class="w-3 h-3 shrink-0 text-accent-400" />
            <LinkBadge v-if="c.contract" :id="c.contract" icon="tabler:file-certificate" @navigate="emit('navigate', $event)" />
            <span v-if="c.default" class="text-[8px] px-1.5 py-0.5 rounded font-medium text-warn-500" style="background: color-mix(in srgb, var(--p-warn-500) 15%, transparent)">default</span>
          </div>
          <div v-if="c.methods && Object.keys(c.methods).length > 0">
            <div class="text-[9px] font-medium mb-1" style="color: var(--p-text-muted-color)">Method Implementations</div>
            <div class="space-y-1">
              <div v-for="(func, method) in c.methods" :key="String(method)" class="flex items-center gap-2 pl-2">
                <span class="text-[10px] font-mono shrink-0" style="color: var(--p-text-muted-color)">{{ method }}</span>
                <Icon icon="tabler:arrow-right" class="w-2.5 h-2.5 shrink-0" style="color: var(--p-text-muted-color)" />
                <LinkBadge :id="String(func)" icon="tabler:code" @navigate="emit('navigate', $event)" />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else class="text-[11px]" style="color: var(--p-text-muted-color)">No contracts bound</div>
    </EditorSection>

    <EditorSection v-if="data.optional_context && Object.keys(data.optional_context).length > 0" icon="tabler:adjustments" title="Context Configuration" description="Optional context parameters that can be provided when using this binding.">
      <div class="space-y-2">
        <div v-for="(cfg, key) in data.optional_context" :key="String(key)" class="ctx-row">
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-mono font-medium" style="color: var(--p-text-color)">{{ key }}</span>
            <span v-if="cfg.type" class="text-[8px] px-1 rounded" style="background: var(--p-surface-200); color: var(--p-text-muted-color)">{{ cfg.type }}</span>
          </div>
          <div v-if="cfg.description" class="text-[9px] mt-0.5" style="color: var(--p-text-muted-color)">{{ cfg.description }}</div>
          <div class="flex gap-3 mt-1 text-[9px]">
            <span v-if="cfg.default_env" style="color: var(--p-text-muted-color)">env: <span class="font-mono" style="color: var(--p-text-color)">{{ cfg.default_env }}</span></span>
            <span v-if="cfg.default_value" style="color: var(--p-text-muted-color)">default: <span class="font-mono" style="color: var(--p-text-color)">{{ cfg.default_value }}</span></span>
          </div>
        </div>
      </div>
    </EditorSection>

    <EditorSection v-if="meta.tags && meta.tags.length > 0" icon="tabler:tags" title="Tags">
      <div class="flex flex-wrap gap-1.5">
        <span v-for="tag in meta.tags" :key="tag" class="text-[9px] px-2 py-0.5 rounded" style="background: var(--p-surface-200); color: var(--p-text-color)">{{ tag }}</span>
      </div>
    </EditorSection>

    <EditorSection v-if="meta.depends_on && meta.depends_on.length > 0" icon="tabler:link" title="Dependencies" description="Registry entries this binding depends on.">
      <div class="flex flex-wrap gap-1.5">
        <LinkBadge v-for="dep in meta.depends_on" :key="dep" :id="dep" @navigate="emit('navigate', $event)" />
      </div>
    </EditorSection>
  </div>
</template>

<style scoped>
.ed-ta {
  width: 100%; padding: 6px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none; resize: vertical;
  min-height: 40px; line-height: 1.5;
}
.ed-ta:focus { border-color: var(--p-primary); }
.bind-card {
  padding: 8px 10px; border-radius: 4px;
  background: var(--p-surface-0); border: 1px solid var(--p-content-border-color);
}
.ctx-row {
  padding: 6px 8px; border-radius: 4px;
  background: var(--p-surface-0); border: 1px solid var(--p-content-border-color);
}
</style>
