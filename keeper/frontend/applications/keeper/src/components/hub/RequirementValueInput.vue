<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import AutoComplete from 'primevue/autocomplete'
import InputText from 'primevue/inputtext'
import { useApi } from '../../composables/useWippy'
import { listEntries, type RegistryEntry } from '../../api/registry'
import type { HubPlanRequirement, RequirementValue } from '../../api/hub'
import { parseValue, valueText } from './requirementValue'

interface Candidate { value: string; label: string; source: string; kind?: string }
const props = defineProps<{
  modelValue: RequirementValue
  requirement: HubPlanRequirement
  placeholder?: string
  disabled?: boolean
}>()
const emit = defineEmits<{
  'update:model-value': [value: RequirementValue]
  validity: [valid: boolean]
  commit: []
}>()
const api = useApi()
const search = ref(valueText(props.modelValue))
const registryEntries = ref<RegistryEntry[]>([])
const error = ref<string | null>(null)
const loading = ref(false)
let searchSeq = 0
let searchTimer: ReturnType<typeof setTimeout> | undefined
let committedText = valueText(props.modelValue)
let localText = committedText
let pendingCommit = false

watch(() => props.modelValue, value => {
  const text = valueText(value)
  search.value = text
  if (text !== localText) {
    committedText = text
    localText = text
    pendingCommit = false
  }
})
const literal = computed(() => !!props.requirement.expected_type)
const candidates = computed<Candidate[]>(() => {
  const planned = (props.requirement.suggestions || [])
    .filter(s => typeof s.value === 'string' && s.value !== '')
    .map(s => ({value: s.value as string, label: s.label || String(s.value), source: s.source || 'plan', kind: s.kind}))
  const validIds = new Set(planned.map(s => s.value))
  const expected = props.requirement.expected_kind
  const found = registryEntries.value
    .filter(entry => !expected || entry.kind === expected || validIds.has(entry.id))
    .map(entry => ({value: entry.id, label: entry.meta?.title || entry.id, source: 'registry', kind: entry.kind}))
  const seen = new Set<string>()
  return [...planned, ...found].filter(candidate => {
    if (seen.has(candidate.value)) return false
    seen.add(candidate.value)
    return true
  }).slice(0, 80)
})

function updateValue(text: string) {
  search.value = text
  try {
    const value = parseValue(text, props.requirement.expected_type)
    localText = valueText(value)
    pendingCommit = localText !== committedText
    error.value = null
    emit('validity', true)
    emit('update:model-value', value)
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Invalid requirement value'
    emit('validity', false)
  }
  if (!literal.value) {
    if (searchTimer) clearTimeout(searchTimer)
    searchTimer = setTimeout(() => { void loadRegistryEntries() }, 180)
  }
}

async function loadRegistryEntries() {
  if (literal.value) return
  const seq = ++searchSeq
  loading.value = true
  error.value = null
  try {
    const response = await listEntries(api, {query: search.value.trim() || undefined, limit: 80})
    if (seq === searchSeq) registryEntries.value = response.entries || []
  } catch (e: unknown) {
    if (seq !== searchSeq) return
    registryEntries.value = []
    error.value = e instanceof Error ? e.message : 'Registry search failed'
  } finally {
    if (seq === searchSeq) loading.value = false
  }
}

function commitValue() {
  if (props.disabled || error.value || !pendingCommit) return
  committedText = localText
  pendingCommit = false
  emit('commit')
}
function onInput(value: string | Candidate) {
  if (props.disabled) return
  updateValue(typeof value === 'string' ? value : value.value)
}
function selectCandidate(event: {value: Candidate}) {
  onInput(event.value)
  commitValue()
}
function onEscape(event: KeyboardEvent) {
  if (event.target instanceof Element && event.target.getAttribute('aria-expanded') === 'true') {
    event.stopPropagation()
  }
}
onBeforeUnmount(() => {
  searchSeq += 1
  if (searchTimer) clearTimeout(searchTimer)
})
</script>

<template>
  <div class="req-value">
    <InputText v-if="literal" :model-value="search" class="req-value-input mono"
      :aria-label="requirement.parameter_name" :aria-invalid="!!error" :disabled="disabled"
      :placeholder="placeholder || `Enter ${requirement.expected_type}`"
      @update:model-value="updateValue($event || '')" @change="commitValue" @blur="commitValue"
      @keydown.enter.prevent="commitValue" />
    <AutoComplete v-else :model-value="search" :suggestions="candidates" option-label="value" dropdown complete-on-focus :delay="0" :min-length="0"
      :loading="loading" :disabled="disabled" :placeholder="placeholder || 'Search registry or type value'"
      :input-props="{'aria-label': requirement.parameter_name}" input-class="req-value-input mono"
      :pt="{option: {class: 'req-value-option'}, dropdown: {'aria-label': 'Show requirement candidates'}}"
      @update:model-value="onInput" @complete="loadRegistryEntries"
      @option-select="selectCandidate" @change="commitValue" @blur="commitValue"
      @keydown.enter="commitValue" @keydown.esc="onEscape">
      <template #option="{option}">
        <span class="req-value-option-main">
          <span>{{ option.label }}</span>
          <span class="mono">{{ option.value }}</span>
          <span class="req-value-option-meta">{{ option.kind || option.source }}</span>
        </span>
      </template>
    </AutoComplete>
    <p v-if="error" role="alert" class="req-value-error">{{ error }}</p>
  </div>
</template>

<style scoped>
.req-value { width: 100%; }
.req-value-input { width: 100%; font-size: 12px; }
.req-value-option-main { display: flex; flex-direction: column; gap: 2px; color: var(--p-text-color); }
.req-value-option-main .mono { font-size: 10px; color: var(--p-text-muted-color); }
.req-value-error { font-size: 11px; color: var(--p-danger-500); }
</style>
