<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../../composables/useWippy'
import { listEntries, kindIcon, type RegistryEntry } from '../../api/registry'
import type { HubPlanRequirement } from '../../api/hub'

interface Candidate {
  value: string
  label: string
  source: string
  kind?: string
  preferred?: boolean
  registry?: boolean
}

const props = defineProps<{
  modelValue: string
  requirement: HubPlanRequirement
  placeholder?: string
}>()

const emit = defineEmits<{
  'update:model-value': [value: string]
  commit: []
}>()

const api = useApi()
const open = ref(false)
const loading = ref(false)
const search = ref(props.modelValue || '')
const registryEntries = ref<RegistryEntry[]>([])
const error = ref<string | null>(null)
const anchorEl = ref<HTMLElement | null>(null)
const menuStyle = ref<Record<string, string>>({})

let searchTimer: ReturnType<typeof setTimeout> | null = null
let searchSeq = 0

watch(() => props.modelValue, value => {
  const next = value || ''
  if (next !== search.value) search.value = next
})

const plannerCandidates = computed<Candidate[]>(() => {
  return (props.requirement.suggestions || [])
    .filter(s => s.value)
    .map(s => ({
      value: s.value,
      label: s.label || s.value,
      source: s.source || 'plan',
      kind: s.kind,
      preferred: s.preferred,
      registry: false,
    }))
})

function expectedKind(): string {
  return String(props.requirement.expected_kind || '').trim().toLowerCase()
}

function matchesExpected(entry: RegistryEntry): boolean {
  const expected = expectedKind()
  if (!expected) return false
  const kind = String(entry.kind || '').toLowerCase()
  const type = String(entry.meta?.type || '').toLowerCase()
  return kind === expected || type === expected || kind.includes(expected) || type.includes(expected)
}

function entryCandidate(entry: RegistryEntry): Candidate {
  return {
    value: entry.id,
    label: entry.meta?.title || entry.id,
    source: matchesExpected(entry) ? 'registry match' : 'registry',
    kind: entry.meta?.type || entry.kind,
    preferred: matchesExpected(entry),
    registry: true,
  }
}

const candidates = computed<Candidate[]>(() => {
  const seen = new Set<string>()
  const out: Candidate[] = []

  for (const c of plannerCandidates.value) {
    if (seen.has(c.value)) continue
    seen.add(c.value)
    out.push(c)
  }

  const registry = registryEntries.value
    .map(entryCandidate)
    .sort((a, b) => {
      if (!!a.preferred !== !!b.preferred) return a.preferred ? -1 : 1
      return a.value.localeCompare(b.value)
    })

  for (const c of registry) {
    if (seen.has(c.value)) continue
    seen.add(c.value)
    out.push(c)
  }

  return out.slice(0, 80)
})

function candidateIcon(c: Candidate): string {
  if (!c.registry) return c.preferred ? 'tabler:star' : 'tabler:sparkles'
  return kindIcon(c.kind || 'registry.entry')
}

function scheduleRegistrySearch(delay = 180) {
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => { void loadRegistryEntries() }, delay)
}

function updateMenuPosition() {
  const anchor = anchorEl.value
  if (!anchor) return
  const rect = anchor.getBoundingClientRect()
  const gap = 4
  const viewportPadding = 10
  const below = window.innerHeight - rect.bottom - viewportPadding
  const above = rect.top - viewportPadding
  const placeAbove = below < 180 && above > below
  const maxHeight = Math.max(160, Math.min(320, placeAbove ? above - gap : below - gap))
  const width = Math.min(rect.width, window.innerWidth - viewportPadding * 2)
  const left = Math.min(Math.max(viewportPadding, rect.left), window.innerWidth - viewportPadding - width)
  menuStyle.value = {
    left: `${left}px`,
    top: `${placeAbove ? Math.max(viewportPadding, rect.top - gap - maxHeight) : rect.bottom + gap}px`,
    width: `${width}px`,
    maxHeight: `${maxHeight}px`,
  }
}

function bindMenuPositioning() {
  window.addEventListener('resize', updateMenuPosition)
  window.addEventListener('scroll', updateMenuPosition, true)
}

function unbindMenuPositioning() {
  window.removeEventListener('resize', updateMenuPosition)
  window.removeEventListener('scroll', updateMenuPosition, true)
}

function updateValue(value: string) {
  search.value = value
  emit('update:model-value', value)
  scheduleRegistrySearch()
}

async function loadRegistryEntries() {
  const seq = ++searchSeq
  loading.value = true
  error.value = null
  try {
    const response = await listEntries(api, {
      query: search.value.trim() || undefined,
      limit: 80,
    })
    if (seq !== searchSeq) return
    registryEntries.value = response.entries || []
  } catch (e: unknown) {
    if (seq !== searchSeq) return
    registryEntries.value = []
    error.value = e instanceof Error ? e.message : 'Registry search failed'
  } finally {
    if (seq === searchSeq) loading.value = false
  }
}

function openMenu() {
  open.value = true
  void nextTick(updateMenuPosition)
  if (!registryEntries.value.length) void loadRegistryEntries()
}

function selectCandidate(c: Candidate) {
  updateValue(c.value)
  emit('commit')
  open.value = false
}

function commitValue() {
  emit('commit')
}

function onInput(event: Event) {
  updateValue((event.target as HTMLInputElement).value)
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter') {
    event.preventDefault()
    commitValue()
    open.value = false
  } else if (event.key === 'Escape') {
    open.value = false
  }
}

function onBlur() {
  window.setTimeout(() => {
    open.value = false
    commitValue()
  }, 120)
}

onBeforeUnmount(() => {
  if (searchTimer) clearTimeout(searchTimer)
  unbindMenuPositioning()
})

watch(open, value => {
  if (value) {
    bindMenuPositioning()
    void nextTick(updateMenuPosition)
  } else {
    unbindMenuPositioning()
  }
})
</script>

<template>
  <div class="req-value">
    <div ref="anchorEl" class="req-value-input-wrap">
      <Icon icon="tabler:search" class="req-value-icon" />
      <input
        :value="search"
        class="req-value-input mono"
        :placeholder="placeholder || 'Search registry or type value'"
        autocomplete="off"
        @focus="openMenu"
        @input="onInput"
        @keydown="onKeydown"
        @change="commitValue"
        @blur="onBlur"
      />
      <button type="button" class="req-value-toggle" @mousedown.prevent="openMenu">
        <Icon icon="tabler:chevron-down" class="w-3 h-3" />
      </button>
    </div>

    <Teleport to="body">
      <div v-if="open" class="req-value-menu" :style="menuStyle">
        <div v-if="loading" class="req-value-empty">
          <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
          Searching registry...
        </div>
        <button
          v-for="candidate in candidates"
          :key="candidate.source + ':' + candidate.value"
          type="button"
          class="req-value-option"
          @mousedown.prevent="selectCandidate(candidate)"
          @click.prevent="selectCandidate(candidate)"
        >
          <Icon :icon="candidateIcon(candidate)" class="req-value-option-icon" />
          <span class="req-value-option-main">
            <span class="req-value-option-label">{{ candidate.label }}</span>
            <span class="req-value-option-id mono">{{ candidate.value }}</span>
          </span>
          <span class="req-value-option-meta">{{ candidate.kind || candidate.source }}</span>
        </button>
        <div v-if="!loading && !candidates.length" class="req-value-empty">
          No registry matches. Keep typing to use a custom value.
        </div>
        <div v-if="error" class="req-value-error">{{ error }}</div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.req-value { position: relative; }
.req-value-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.req-value-icon {
  position: absolute;
  left: 9px;
  top: 50%;
  width: 13px;
  height: 13px;
  transform: translateY(-50%);
  color: var(--p-text-muted-color);
  pointer-events: none;
  z-index: 1;
}
.req-value-input {
  width: 100%;
  min-width: 0;
  height: 30px;
  padding: 6px 30px 6px 28px;
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  background: var(--p-surface-0);
  color: var(--p-text-color);
  font-size: 12px;
  line-height: 16px;
  outline: none;
}
.req-value-input::placeholder { color: var(--p-text-muted-color); }
.req-value-input:hover { border-color: var(--p-surface-300); }
.req-value-input:focus {
  border-color: var(--p-primary-color);
  box-shadow: 0 0 0 1px color-mix(in srgb, var(--p-primary-color) 35%, transparent);
}
.req-value-toggle {
  position: absolute;
  right: 6px;
  top: 50%;
  transform: translateY(-50%);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border: 0;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-muted-color);
  cursor: pointer;
}
.req-value-toggle:hover { background: var(--p-surface-100); color: var(--p-text-color); }
.req-value-menu {
  position: fixed;
  z-index: 10000;
  overflow-y: auto;
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  background: var(--p-surface-50);
  box-shadow: 0 12px 28px rgba(0,0,0,0.32);
}
.req-value-option {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 9px;
  border: 0;
  border-bottom: 1px solid var(--p-content-border-color);
  background: transparent;
  color: var(--p-text-color);
  text-align: left;
  cursor: pointer;
}
.req-value-option:hover { background: var(--p-surface-100); }
.req-value-option-icon { width: 14px; height: 14px; flex-shrink: 0; color: var(--p-text-muted-color); }
.req-value-option-main { min-width: 0; flex: 1; display: flex; flex-direction: column; gap: 1px; }
.req-value-option-label,
.req-value-option-id { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.req-value-option-label { font-size: 11px; }
.req-value-option-id { font-size: 10px; color: var(--p-text-muted-color); }
.req-value-option-meta {
  flex-shrink: 0; max-width: 110px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  font-size: 9px; color: var(--p-text-muted-color);
}
.req-value-empty,
.req-value-error {
  display: flex; align-items: center; justify-content: center; gap: 6px;
  padding: 12px; font-size: 11px; color: var(--p-text-muted-color);
}
.req-value-error { color: var(--p-danger-500); }
</style>
