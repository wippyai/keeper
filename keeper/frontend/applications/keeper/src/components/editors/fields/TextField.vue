<script setup lang="ts">
const model = defineModel<string>({ default: '' })
defineProps<{
  placeholder?: string
  rows?: number
  mono?: boolean
  readonly?: boolean
}>()
</script>

<template>
  <textarea
    v-if="!readonly"
    :value="model"
    @input="model = ($event.target as HTMLTextAreaElement).value"
    :placeholder="placeholder"
    :rows="rows || 4"
    class="ed-textarea"
    :class="{ 'font-mono': mono }"
  ></textarea>
  <pre v-else class="ed-pre" :class="{ 'font-mono': mono }">{{ model || '-' }}</pre>
</template>

<style scoped>
.ed-textarea {
  width: 100%;
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
  resize: vertical;
  min-height: 60px;
  line-height: 1.5;
}
.ed-textarea:focus {
  border-color: var(--p-primary-color);
}
.ed-pre {
  font-size: 11px;
  color: var(--p-text-color);
  white-space: pre-wrap;
  word-break: break-word;
  margin: 0;
}
</style>
