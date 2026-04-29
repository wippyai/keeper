<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../../../composables/useWippy'
import { entryName } from '../../../utils'
import { listEntries, listNamespaces, kindIcon, type RegistryEntry } from '../../../api/registry'

const props = defineProps<{
  metaType: string
  selected: Array<string | { id: string; [key: string]: any }>
  label?: string
  placeholder?: string
  icon?: string
}>()

const emit = defineEmits<{
  add: [id: string]
  remove: [id: string]
}>()

const api = useApi()
const available = ref<RegistryEntry[]>([])
const namespaces = ref<string[]>([])
const loading = ref(false)
const search = ref('')
const nsFilter = ref('')
const open = ref(false)

const selectedIds = computed(() =>
  new Set(props.selected.map(s => typeof s === 'string' ? s : s.id))
)

const filtered = computed(() => {
  let list = available.value
  if (nsFilter.value) list = list.filter(e => e.id.startsWith(nsFilter.value + ':'))
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(e =>
      e.id.toLowerCase().includes(q) ||
      (e.meta?.title || '').toLowerCase().includes(q) ||
      (e.meta?.name || '').toLowerCase().includes(q)
    )
  }
  return list
})

function entryNs(id: string): string {
  const idx = id.indexOf(':')
  return idx >= 0 ? id.slice(0, idx) : ''
}

function toggle(id: string) {
  if (selectedIds.value.has(id)) emit('remove', id)
  else emit('add', id)
}

async function load() {
  loading.value = true
  try {
    const [entries, ns] = await Promise.all([
      listEntries(api, { metaType: props.metaType, limit: 1000 }),
      listNamespaces(api),
    ])
    available.value = (entries.entries || []).sort((a, b) => a.id.localeCompare(b.id))
    const nsSet = new Set<string>()
    for (const e of available.value) {
      const n = entryNs(e.id)
      if (n) nsSet.add(n)
    }
    namespaces.value = [...nsSet].sort()
  } catch {
    available.value = []
  } finally {
    loading.value = false
  }
}

function handleClickOutside(e: MouseEvent) {
  const el = (e.target as HTMLElement).closest('.entry-picker')
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
  <div class="entry-picker">
    <button class="ep-trigger" @click="open = !open">
      <Icon :icon="icon || 'tabler:plus'" class="w-3 h-3 shrink-0" style="color: var(--p-primary)" />
      <span class="flex-1 text-left text-[10px]" style="color: var(--p-text-muted-color)">{{ placeholder || 'Add ' + metaType + '...' }}</span>
      <span class="text-[9px]" style="color: var(--p-text-muted-color)">{{ available.length }}</span>
      <Icon icon="tabler:chevron-down" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
    </button>

    <Teleport to="body">
      <div v-if="open" class="ep-dropdown" :style="{ position: 'fixed', zIndex: 9999 }">
        <div class="ep-header">
          <div class="relative flex-1">
            <Icon icon="tabler:search" class="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3" style="color: var(--p-text-muted-color)" />
            <input v-model="search" type="text" :placeholder="'Search ' + metaType + '...'" class="ep-search" />
          </div>
          <select v-if="namespaces.length > 1" v-model="nsFilter" class="ep-ns-select">
            <option value="">All</option>
            <option v-for="ns in namespaces" :key="ns" :value="ns">{{ ns }}</option>
          </select>
        </div>
        <div class="ep-list">
          <div v-if="loading" class="ep-empty"><Icon icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin" /> Loading...</div>
          <div v-else-if="filtered.length === 0" class="ep-empty">No entries found</div>
          <div
            v-for="entry in filtered" :key="entry.id"
            class="ep-item"
            :class="{ 'ep-item--selected': selectedIds.has(entry.id) }"
            @click="toggle(entry.id)"
          >
            <Icon v-if="selectedIds.has(entry.id)" icon="tabler:check" class="w-3 h-3 shrink-0" style="color: var(--p-primary)" />
            <Icon v-else :icon="kindIcon(entry.kind, entry.meta?.type)" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
            <div class="flex-1 min-w-0">
              <div class="text-[11px] truncate" style="color: var(--p-text-color)">{{ entry.meta?.title || entryName(entry.id) }}</div>
              <div class="text-[9px] font-mono truncate" style="color: var(--p-text-muted-color)">{{ entry.id }}</div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.ep-trigger {
  display: flex; align-items: center; gap: 6px; width: 100%;
  padding: 4px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px dashed var(--p-surface-300); cursor: pointer;
}
.ep-trigger:hover { border-color: var(--p-primary); }
.ep-dropdown {
  width: 360px; max-height: 400px; border-radius: 6px;
  background: var(--p-surface-50); border: 1px solid var(--p-content-border-color);
  box-shadow: 0 8px 24px rgba(0,0,0,0.4); overflow: hidden;
  display: flex; flex-direction: column;
  top: 50%; left: 50%; transform: translate(-50%, -50%);
}
.ep-header {
  display: flex; align-items: center; gap: 4px;
  padding: 6px 8px; border-bottom: 1px solid var(--p-content-border-color);
}
.ep-search {
  width: 100%; padding: 3px 6px 3px 24px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}
.ep-ns-select {
  padding: 3px 4px; border-radius: 4px; font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}
.ep-list { flex: 1; overflow-y: auto; max-height: 320px; }
.ep-item {
  display: flex; align-items: center; gap: 6px;
  padding: 5px 10px; cursor: pointer;
  border-bottom: 1px solid var(--p-content-border-color);
}
.ep-item:hover { background: var(--p-surface-100); }
.ep-item--selected { background: rgba(245,158,11,0.05); }
.ep-empty { padding: 16px; text-align: center; font-size: 11px; color: var(--p-text-muted-color); display: flex; align-items: center; justify-content: center; gap: 6px; }
</style>
