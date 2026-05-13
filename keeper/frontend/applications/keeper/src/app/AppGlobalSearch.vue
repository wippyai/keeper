<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { kindColor, kindIcon } from '../api/registry'

export interface SearchResult {
  id: string
  kind: string
  snippet?: string
  icon?: string
  color?: string
  route?: string
}

export interface SearchHint {
  prefix: string
  desc: string
  icon: string
}

defineProps<{
  open: boolean
  query: string
  results: SearchResult[]
  loading: boolean
  hints: SearchHint[]
}>()

const emit = defineEmits<{
  (e: 'update:query', v: string): void
  (e: 'close'): void
  (e: 'search-input'): void
  (e: 'select', r: SearchResult): void
  (e: 'apply-hint', prefix: string): void
}>()

function onEnter(results: SearchResult[]) {
  if (results.length > 0) emit('select', results[0])
}
</script>

<template>
  <Teleport to="body">
    <div v-if="open" class="search-overlay" @click.self="emit('close')">
      <div class="search-modal">
        <div class="search-header">
          <Icon icon="tabler:search" class="w-4 h-4 shrink-0" style="color: var(--p-text-muted-color)" />
          <input
            :value="query"
            @input="emit('update:query', ($event.target as HTMLInputElement).value); emit('search-input')"
            @keydown.escape="emit('close')"
            @keydown.enter="onEnter(results)"
            class="global-search-input" placeholder="Search entries, functions, configs..." autofocus />
          <Icon v-if="loading" icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin" style="color: var(--p-primary-color)" />
          <kbd class="search-kbd">Esc</kbd>
        </div>
        <div v-if="results.length > 0" class="search-results">
          <div v-for="r in results" :key="r.id" class="search-item" @click="emit('select', r)">
            <Icon :icon="r.icon || kindIcon(r.kind)" class="w-3 h-3 shrink-0" :style="{ color: r.color || kindColor(r.kind) }" />
            <div class="flex-1 min-w-0">
              <div class="text-[11px] font-mono truncate" style="color: var(--p-text-color)">{{ r.id }}</div>
              <div v-if="r.snippet" class="text-[9px] truncate" style="color: var(--p-text-muted-color)">{{ r.snippet }}</div>
            </div>
            <span class="text-[8px] px-1 rounded" :style="{ color: r.color || kindColor(r.kind), background: `color-mix(in srgb, ${r.color || kindColor(r.kind)} 12%, transparent)` }">{{ r.kind }}</span>
          </div>
        </div>
        <div v-else-if="query && !loading" class="search-empty">No results</div>
        <div v-else-if="!query" class="search-hints">
          <div v-for="h in hints" :key="h.prefix" class="search-hint" @click="emit('apply-hint', h.prefix)">
            <Icon :icon="h.icon" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
            <span class="text-[10px] font-mono" style="color: var(--p-primary-color)">{{ h.prefix || '*' }}</span>
            <span class="text-[10px]" style="color: var(--p-text-muted-color)">{{ h.desc }}</span>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
