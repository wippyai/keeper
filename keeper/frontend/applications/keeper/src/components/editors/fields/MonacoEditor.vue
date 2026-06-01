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

// `readonly` is a reserved HTML boolean attribute, so Vue coerces any truthy
// value (including the string "false") to a bare `readonly=""` and only drops
// the attribute for a real boolean false. Pass a boolean so the WC sees the
// attribute solely when read-only; absence falls back to its `false` default.
const isReadonly = computed(() => props.readonly === true)
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
    :readonly="isReadonly"
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
