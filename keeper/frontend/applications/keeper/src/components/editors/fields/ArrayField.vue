<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { ref } from 'vue'

const model = defineModel<string[]>({ default: () => [] })
defineProps<{
  placeholder?: string
  readonly?: boolean
}>()

const newItem = ref('')

function add() {
  const v = newItem.value.trim()
  if (!v) return
  model.value = [...(model.value || []), v]
  newItem.value = ''
}

function remove(index: number) {
  const arr = [...(model.value || [])]
  arr.splice(index, 1)
  model.value = arr
}

function update(index: number, value: string) {
  const arr = [...(model.value || [])]
  arr[index] = value
  model.value = arr
}
</script>

<template>
  <div class="space-y-1">
    <div v-for="(item, i) in (model || [])" :key="i" class="flex items-center gap-1">
      <input
        v-if="!readonly"
        :value="item"
        @input="update(i, ($event.target as HTMLInputElement).value)"
        class="ed-input flex-1"
      />
      <span v-else class="text-[11px] font-mono" style="color: var(--p-text-color)">{{ item }}</span>
      <Button v-if="!readonly" class="k-btn-icon" @click="remove(i)">
        <Icon icon="tabler:x" class="w-3 h-3" />
      </Button>
    </div>
    <div v-if="!readonly" class="flex items-center gap-1">
      <input
        v-model="newItem"
        :placeholder="placeholder || 'Add item...'"
        class="ed-input flex-1"
        @keydown.enter="add"
      />
      <Button class="k-btn-icon" @click="add">
        <Icon icon="tabler:plus" class="w-3 h-3" />
      </Button>
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
