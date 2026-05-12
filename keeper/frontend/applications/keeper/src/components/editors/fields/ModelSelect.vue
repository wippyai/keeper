<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed, nextTick } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../../../composables/useWippy'
import { entryName } from '../../../utils'
import { listEntries, type RegistryEntry } from '../../../api/registry'

const model = defineModel<string>({ default: '' })

const api = useApi()
const models = ref<RegistryEntry[]>([])
const loading = ref(false)
const open = ref(false)
const search = ref('')
const triggerEl = ref<HTMLElement | null>(null)
const dropdownStyle = ref<Record<string, string>>({})

const filtered = computed(() => {
  if (!search.value) return models.value
  const q = search.value.toLowerCase()
  return models.value.filter(m =>
    m.id.toLowerCase().includes(q) ||
    (m.meta?.title || '').toLowerCase().includes(q) ||
    (m.meta?.name || '').toLowerCase().includes(q)
  )
})

const selectedModel = computed(() =>
  models.value.find(m => m.meta?.name === model.value || m.id === model.value)
)

const displayName = computed(() => {
  if (selectedModel.value) {
    return selectedModel.value.meta?.title || selectedModel.value.meta?.name || entryName(selectedModel.value.id)
  }
  return model.value || 'Select model...'
})

function select(entry: RegistryEntry) {
  model.value = entry.meta?.name || entryName(entry.id)
  open.value = false
  search.value = ''
}

async function load() {
  loading.value = true
  try {
    const r = await listEntries(api, { metaType: 'llm.model', limit: 500 })
    models.value = (r.entries || []).sort((a, b) =>
      (a.meta?.title || a.id).localeCompare(b.meta?.title || b.id)
    )
  } catch {
    models.value = []
  } finally {
    loading.value = false
  }
}

function positionDropdown() {
  if (!triggerEl.value) return
  const rect = triggerEl.value.getBoundingClientRect()
  const spaceBelow = window.innerHeight - rect.bottom
  const dropUp = spaceBelow < 280 && rect.top > 280
  dropdownStyle.value = {
    left: rect.left + 'px',
    width: Math.max(rect.width, 320) + 'px',
    ...(dropUp
      ? { bottom: (window.innerHeight - rect.top + 2) + 'px' }
      : { top: (rect.bottom + 2) + 'px' }),
  }
}

function toggle() {
  open.value = !open.value
  if (open.value) nextTick(positionDropdown)
}

function handleClickOutside(e: MouseEvent) {
  const el = (e.target as HTMLElement).closest('.model-select') || (e.target as HTMLElement).closest('.ms-dropdown')
  if (!el) open.value = false
}

onMounted(() => {
  load()
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="model-select">
    <button ref="triggerEl" class="ms-trigger" @click="toggle">
      <Icon v-if="loading" icon="tabler:loader-2" class="w-3 h-3 animate-spin shrink-0" />
      <Icon v-else icon="tabler:brain" class="w-3 h-3 shrink-0" style="color: var(--p-primary-color)" />
      <span class="flex-1 text-left truncate">{{ displayName }}</span>
      <Icon icon="tabler:chevron-down" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
    </button>

    <Teleport to="body">
    <div v-if="open" class="ms-dropdown" :style="dropdownStyle">
      <div class="ms-search">
        <Icon icon="tabler:search" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
        <input v-model="search" type="text" placeholder="Search models..." class="ms-search-input" ref="searchInput" />
      </div>
      <div class="ms-list">
        <div
          v-for="entry in filtered" :key="entry.id"
          class="ms-item"
          :class="{ 'ms-item--active': (entry.meta?.name || entryName(entry.id)) === model }"
          @click="select(entry)"
        >
          <div class="flex-1 min-w-0">
            <div class="text-[11px] truncate" style="color: var(--p-text-color)">{{ entry.meta?.title || entryName(entry.id) }}</div>
            <div class="text-[9px] font-mono truncate" style="color: var(--p-text-muted-color)">{{ entry.meta?.name || entryName(entry.id) }}</div>
          </div>
          <div v-if="entry.meta?.capabilities" class="flex gap-0.5 shrink-0">
            <Icon v-if="entry.meta.capabilities.includes('tool_use')" icon="tabler:tool" class="w-2.5 h-2.5" style="color: var(--p-text-muted-color)" />
            <Icon v-if="entry.meta.capabilities.includes('vision')" icon="tabler:eye" class="w-2.5 h-2.5" style="color: var(--p-text-muted-color)" />
            <Icon v-if="entry.meta.capabilities.includes('thinking')" icon="tabler:brain" class="w-2.5 h-2.5" style="color: var(--p-text-muted-color)" />
          </div>
          <Icon v-if="(entry.meta?.name || entryName(entry.id)) === model" icon="tabler:check" class="w-3 h-3 shrink-0" style="color: var(--p-primary-color)" />
        </div>
        <div v-if="filtered.length === 0" class="px-3 py-2 text-[10px]" style="color: var(--p-text-muted-color)">
          {{ loading ? 'Loading...' : 'No models found' }}
        </div>
      </div>
    </div>
    </Teleport>
  </div>
</template>

<style scoped>
.model-select {
  position: relative;
}
.ms-trigger {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-0);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  text-align: left;
}
.ms-trigger:hover {
  border-color: var(--p-surface-300);
}
.ms-dropdown {
  position: fixed;
  width: 320px;
  border-radius: 6px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  box-shadow: 0 8px 24px rgba(0,0,0,0.4);
  z-index: 9999;
  overflow: hidden;
}
.ms-search {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  border-bottom: 1px solid var(--p-content-border-color);
}
.ms-search-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  font-size: 11px;
  color: var(--p-text-color);
}
.ms-list {
  max-height: 240px;
  overflow-y: auto;
}
.ms-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  cursor: pointer;
}
.ms-item:hover {
  background: var(--p-surface-100);
}
.ms-item--active {
  background: var(--p-surface-100);
}
</style>
