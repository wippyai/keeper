<script setup lang="ts">
import { ref, watch, computed } from 'vue'

const props = defineProps<{
  url: string
  title?: string
  context?: Record<string, unknown>
}>()

const iframe = ref<HTMLIFrameElement | null>(null)
const loaded = ref(false)

function resolveOrigin(): string {
  const own = window.location.origin
  if (own && own !== 'null') return own
  try {
    const parentOrigin = window.parent?.location?.origin
    if (parentOrigin && parentOrigin !== 'null') return parentOrigin
  } catch { /* cross-origin parent — fall through to empty origin */ }
  return ''
}

const fullUrl = computed(() => {
  const base = props.url.startsWith('http') ? props.url : resolveOrigin() + props.url
  const params = new URLSearchParams()
  if (props.context) {
    for (const [k, v] of Object.entries(props.context)) {
      if (v !== undefined && v !== null) params.set(k, String(v))
    }
  }
  const sep = base.includes('?') ? '&' : '?'
  return params.toString() ? base + sep + params.toString() : base
})

watch(fullUrl, () => { loaded.value = false })
</script>

<template>
  <div class="relative w-full h-full" style="min-height: 100px">
    <div v-if="!loaded" class="absolute inset-0 flex items-center justify-center text-[10px]" style="color: var(--p-text-muted-color)">
      Loading plugin...
    </div>
    <iframe
      ref="iframe"
      :src="fullUrl"
      :title="title || 'Plugin'"
      sandbox="allow-scripts allow-same-origin"
      class="w-full h-full border-0"
      @load="loaded = true"
    />
  </div>
</template>
