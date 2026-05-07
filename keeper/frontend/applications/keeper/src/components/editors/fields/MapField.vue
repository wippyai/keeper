<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { ref } from 'vue'

const model = defineModel<Record<string, string>>({ default: () => ({}) })
defineProps<{
  keyPlaceholder?: string
  valuePlaceholder?: string
  readonly?: boolean
}>()

const newKey = ref('')
const newVal = ref('')

function add() {
  const k = newKey.value.trim()
  if (!k) return
  model.value = { ...(model.value || {}), [k]: newVal.value }
  newKey.value = ''
  newVal.value = ''
}

function remove(key: string) {
  const obj = { ...(model.value || {}) }
  delete obj[key]
  model.value = obj
}

function updateValue(key: string, value: string) {
  model.value = { ...(model.value || {}), [key]: value }
}
</script>

<template>
  <div class="space-y-1">
    <div v-for="(val, key) in (model || {})" :key="key" class="flex items-center gap-1">
      <span class="text-[11px] font-mono shrink-0 px-1 py-0.5 rounded" style="background: var(--p-surface-200); color: var(--p-text-color)">{{ key }}</span>
      <input
        v-if="!readonly"
        :value="val"
        @input="updateValue(String(key), ($event.target as HTMLInputElement).value)"
        class="ed-input flex-1"
      />
      <span v-else class="text-[11px]" style="color: var(--p-text-color)">{{ val }}</span>
      <button v-if="!readonly" class="ed-icon-btn" @click="remove(String(key))">
        <Icon icon="tabler:x" class="w-3 h-3" />
      </button>
    </div>
    <div v-if="!readonly" class="flex items-center gap-1">
      <input v-model="newKey" :placeholder="keyPlaceholder || 'Key'" class="ed-input w-24" @keydown.enter="add" />
      <input v-model="newVal" :placeholder="valuePlaceholder || 'Value'" class="ed-input flex-1" @keydown.enter="add" />
      <button class="ed-icon-btn" @click="add">
        <Icon icon="tabler:plus" class="w-3 h-3" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.ed-input {
  padding: 3px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  outline: none;
}
.ed-input:focus {
  border-color: var(--p-primary-color);
}
.ed-icon-btn {
  padding: 3px;
  border-radius: 3px;
  color: var(--p-text-muted-color);
  background: none;
  border: none;
  cursor: pointer;
}
.ed-icon-btn:hover {
  background: var(--p-surface-200);
  color: var(--p-text-color);
}
</style>
