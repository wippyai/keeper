<script setup lang="ts">
import { ref, watch } from 'vue'

const model = defineModel<any>({ default: null })
defineProps<{
  readonly?: boolean
  rows?: number
}>()

const text = ref('')
const parseError = ref<string | null>(null)

watch(model, (v) => {
  text.value = v != null ? JSON.stringify(v, null, 2) : ''
}, { immediate: true })

function onInput(e: Event) {
  const raw = (e.target as HTMLTextAreaElement).value
  text.value = raw
  try {
    model.value = JSON.parse(raw)
    parseError.value = null
  } catch (err: any) {
    parseError.value = err.message
  }
}
</script>

<template>
  <div>
    <textarea
      v-if="!readonly"
      :value="text"
      @input="onInput"
      :rows="rows || 6"
      class="ed-textarea font-mono"
      :class="{ 'ed-textarea--error': parseError }"
    ></textarea>
    <pre v-else class="ed-pre font-mono">{{ text || '-' }}</pre>
    <div v-if="parseError" class="text-[9px] mt-1" style="color: var(--p-danger-500)">{{ parseError }}</div>
  </div>
</template>

<style scoped>
.ed-textarea {
  width: 100%;
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 10px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  resize: vertical;
  min-height: 80px;
  line-height: 1.5;
}
.ed-textarea:focus {
  border-color: var(--p-primary-color);
}
.ed-textarea--error {
  border-color: var(--p-danger-500);
}
.ed-pre {
  font-size: 10px;
  color: var(--p-text-color);
  background: var(--p-surface-100);
  border-radius: 4px;
  padding: 6px 8px;
  white-space: pre-wrap;
  word-break: break-word;
  margin: 0;
  max-height: 300px;
  overflow: auto;
}
</style>
