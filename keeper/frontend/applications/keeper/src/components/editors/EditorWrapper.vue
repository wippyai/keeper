<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../api/registry'
import { resolveEditor } from './EditorRegistry'

const props = defineProps<{
  entry: RegistryEntry
  detail: any
}>()

const emit = defineEmits<{
  save: [updates: { kind?: string; meta?: Record<string, any>; data?: Record<string, any> }]
  navigate: [id: string]
}>()

const editorComponent = computed(() => resolveEditor(props.entry))

const dirty = ref(false)
const saving = ref(false)
const saveError = ref<string | null>(null)
const saveSuccess = ref(false)

const pendingUpdates = ref<{ kind?: string; meta?: Record<string, any>; data?: Record<string, any> }>({})

watch(() => props.entry.id, () => {
  dirty.value = false
  saving.value = false
  saveError.value = null
  saveSuccess.value = false
  pendingUpdates.value = {}
})

function onUpdate(updates: { kind?: string; meta?: Record<string, any>; data?: Record<string, any> }) {
  pendingUpdates.value = { ...pendingUpdates.value, ...updates }
  if (updates.meta) {
    pendingUpdates.value.meta = { ...(pendingUpdates.value.meta || {}), ...updates.meta }
  }
  if (updates.data) {
    pendingUpdates.value.data = { ...(pendingUpdates.value.data || {}), ...updates.data }
  }
  dirty.value = true
  saveError.value = null
  saveSuccess.value = false
}

function save() {
  if (!dirty.value) return
  saving.value = true
  saveError.value = null
  emit('save', pendingUpdates.value)
}

function onSaveResult(success: boolean, error?: string) {
  saving.value = false
  if (success) {
    dirty.value = false
    pendingUpdates.value = {}
    saveSuccess.value = true
    setTimeout(() => { saveSuccess.value = false }, 3000)
  } else {
    saveError.value = error || 'Save failed'
  }
}

defineExpose({ onSaveResult })
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="flex-1 overflow-y-auto">
      <component
        :is="editorComponent"
        :entry="entry"
        :detail="detail"
        @update="onUpdate"
        @navigate="emit('navigate', $event)"
      />
    </div>

    <div class="shrink-0 px-4 py-2 flex items-center gap-2" style="border-top: 1px solid var(--p-content-border-color)">
      <div v-if="saveError" class="flex-1 text-[10px] flex items-center gap-1 text-danger-500">
        <Icon icon="tabler:alert-circle" class="w-3 h-3 shrink-0" />
        <span class="truncate">{{ saveError }}</span>
      </div>
      <div v-else-if="saveSuccess" class="flex-1 text-[10px] flex items-center gap-1 text-success-500">
        <Icon icon="tabler:check" class="w-3 h-3 shrink-0" />
        Saved
      </div>
      <div v-else class="flex-1"></div>
      <button
        class="ed-save-btn"
        :class="{ 'ed-save-btn--active': dirty }"
        :disabled="!dirty || saving"
        @click="save"
      >
        <Icon v-if="saving" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
        <Icon v-else icon="tabler:device-floppy" class="w-3 h-3" />
        Save
      </button>
    </div>
  </div>
</template>

<style scoped>
.ed-save-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  border: none;
  cursor: not-allowed;
}
.ed-save-btn--active {
  background: var(--p-primary);
  color: var(--p-primary-contrast-color);
  cursor: pointer;
  font-weight: 600;
}
.ed-save-btn--active:hover {
  opacity: 0.9;
}
</style>
