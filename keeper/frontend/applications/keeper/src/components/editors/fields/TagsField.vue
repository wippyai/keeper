<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { ref } from 'vue'

const model = defineModel<string[]>({ default: () => [] })
defineProps<{
  placeholder?: string
  readonly?: boolean
}>()

const input = ref('')

function add() {
  const v = input.value.trim()
  if (!v || (model.value || []).includes(v)) return
  model.value = [...(model.value || []), v]
  input.value = ''
}

function remove(tag: string) {
  model.value = (model.value || []).filter(t => t !== tag)
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter') { e.preventDefault(); add() }
  if (e.key === 'Backspace' && !input.value && (model.value || []).length > 0) {
    model.value = (model.value || []).slice(0, -1)
  }
}
</script>

<template>
  <div class="tags-wrap">
    <span v-for="tag in (model || [])" :key="tag" class="tag">
      {{ tag }}
      <button v-if="!readonly" class="tag-remove" @click="remove(tag)">
        <Icon icon="tabler:x" class="w-2.5 h-2.5" />
      </button>
    </span>
    <input
      v-if="!readonly"
      v-model="input"
      :placeholder="(model || []).length === 0 ? (placeholder || 'Add tag...') : ''"
      class="tag-input"
      @keydown="onKeydown"
    />
  </div>
</template>

<style scoped>
.tags-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  padding: 4px;
  border-radius: 4px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  min-height: 28px;
  align-items: center;
}
.tag {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  background: var(--p-surface-200);
  color: var(--p-text-color);
}
.tag-remove {
  display: inline-flex;
  padding: 0;
  background: none;
  border: none;
  color: var(--p-text-muted-color);
  cursor: pointer;
}
.tag-remove:hover {
  color: var(--p-danger-500);
}
.tag-input {
  flex: 1;
  min-width: 60px;
  padding: 2px 4px;
  font-size: 10px;
  background: transparent;
  color: var(--p-text-color);
  border: none;
  outline: none;
}
</style>
