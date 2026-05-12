<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  modelValue: string
  language?: string
  readonly?: boolean
  minHeight?: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

// Boolean → string coercion: HTML attributes are always strings; the WC
// prop-parser converts "true"/"false" back to boolean per the JSON schema.
const readonlyAttr = computed(() => (props.readonly ? 'true' : 'false'))
const minHeightAttr = computed(() => (props.minHeight && props.minHeight > 0 ? String(props.minHeight) : '0'))

function onChange(event: Event) {
  const detail = (event as CustomEvent<{ value: string }>).detail
  if (detail?.value !== undefined && detail.value !== props.modelValue) {
    emit('update:modelValue', detail.value)
  }
}
</script>

<template>
  <wippy-monaco
    mode="editor"
    :value="modelValue"
    :language="language || 'plaintext'"
    :readonly="readonlyAttr"
    :min-height="minHeightAttr"
    class="monaco-wrap"
    @change="onChange"
  />
</template>

<style scoped>
.monaco-wrap {
  display: block;
  width: 100%;
  height: 100%;
}
</style>
