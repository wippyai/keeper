<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { useApi } from '../../composables/useWippy'
import { getEntry, type RegistryEntry } from '../../api/registry'
import DetailPanel from './DetailPanel.vue'
import JsonBlock from './JsonBlock.vue'

const props = defineProps<{
  entryId: string | null
  // Pre-fetched entry; when provided we skip the API call.
  entry?: RegistryEntry | null
  icon?: string
  iconColor?: string
}>()

const emit = defineEmits<{ close: [] }>()

const api = useApi()
const router = useRouter()

const tab = ref('overview')
const loading = ref(false)
const error = ref<string | null>(null)
const fetched = ref<RegistryEntry | null>(null)
const copyToast = ref<string | null>(null)

const current = computed<RegistryEntry | null>(() => fetched.value || props.entry || null)

watch(
  () => props.entryId,
  async (id) => {
    if (!id) { fetched.value = null; return }
    if (props.entry && props.entry.id === id) { fetched.value = null; return }
    loading.value = true
    error.value = null
    try {
      const r = await getEntry(api, id)
      fetched.value = r.entry
    } catch (e: any) {
      error.value = e?.message || 'Failed to load entry'
      fetched.value = null
    } finally {
      loading.value = false
    }
  },
  { immediate: true },
)

function copy(text: string, label: string) {
  navigator.clipboard?.writeText(text).then(() => {
    copyToast.value = label + ' copied'
    setTimeout(() => { copyToast.value = null }, 1500)
  }).catch(() => {})
}

function openInRegistry() {
  if (!props.entryId) return
  router.push({ path: '/structure', query: { entry: props.entryId } })
  emit('close')
}

const namespace = computed(() => (props.entryId || '').split(':')[0] || '')
const name = computed(() => (props.entryId || '').split(':')[1] || props.entryId || '')
const meta = computed(() => current.value?.meta || {})
const data = computed(() => current.value?.data || {})
const hasMeta = computed(() => Object.keys(meta.value).length > 0)
const hasData = computed(() => Object.keys(data.value).length > 0)
</script>

<template>
  <div class="h-full flex flex-col" style="background: var(--p-content-background)">
    <DetailPanel
      v-if="entryId"
      :icon="icon || 'tabler:circle-dot'"
      :icon-color="iconColor"
      :title="meta.title || name"
      :subtitle="namespace"
      :tabs="['overview', 'meta', 'data', 'raw']"
      v-model:active-tab="tab"
      @close="emit('close')"
    >
      <template #subheader>
        <div v-if="copyToast" class="px-4 py-1 text-[10px]" style="color: var(--p-success-500); border-bottom: 1px solid var(--p-content-border-color)">{{ copyToast }}</div>
      </template>
      <template #footer>
        <div class="shrink-0 px-4 py-2 flex items-center gap-2" style="border-top: 1px solid var(--p-content-border-color)">
          <Button severity="secondary" class="!px-2 !py-[3px] !text-[10px] !font-medium !rounded" @click="copy(entryId!, 'ID')" title="Copy ID">
            <Icon icon="tabler:copy" class="w-3 h-3" /> Copy ID
          </Button>
          <Button severity="secondary" class="!px-2 !py-[3px] !text-[10px] !font-medium !rounded" @click="copy(JSON.stringify(current, null, 2), 'Entry JSON')" :disabled="!current">
            <Icon icon="tabler:braces" class="w-3 h-3" /> Copy JSON
          </Button>
          <span class="flex-1"></span>
          <Button class="!px-2 !py-[3px] !text-[10px] !font-medium !rounded" @click="openInRegistry">
            <Icon icon="tabler:arrow-up-right" class="w-3 h-3" /> Open in Registry
          </Button>
        </div>
      </template>

      <div v-if="loading" class="flex items-center gap-2 text-[11px]" style="color: var(--p-text-muted-color)">
        <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" /> Loading…
      </div>
      <div v-else-if="error" class="text-[11px] text-danger-500">{{ error }}</div>

      <template v-else-if="tab === 'overview'">
        <div class="space-y-3">
          <div class="kv">
            <div class="k">ID</div>
            <div class="v font-mono">{{ entryId }}</div>
          </div>
          <div class="kv">
            <div class="k">Kind</div>
            <div class="v"><span class="kind-badge">{{ current?.kind || '—' }}</span></div>
          </div>
          <div v-if="meta.type" class="kv">
            <div class="k">Type</div>
            <div class="v">{{ meta.type }}</div>
          </div>
          <div v-if="meta.title" class="kv">
            <div class="k">Title</div>
            <div class="v">{{ meta.title }}</div>
          </div>
          <div v-if="meta.comment" class="kv">
            <div class="k">Comment</div>
            <div class="v leading-relaxed" style="color: var(--p-text-muted-color)">{{ meta.comment }}</div>
          </div>
          <slot name="overview" :entry="current" />
        </div>
      </template>

      <template v-else-if="tab === 'meta'">
        <div v-if="hasMeta" class="space-y-1">
          <div v-for="(val, key) in meta" :key="key" class="kv-row">
            <div class="k-row">{{ key }}</div>
            <div class="v-row">
              <template v-if="typeof val === 'string' || typeof val === 'number' || typeof val === 'boolean'">{{ val }}</template>
              <pre v-else class="json-mini">{{ JSON.stringify(val, null, 2) }}</pre>
            </div>
          </div>
        </div>
        <div v-else class="text-[11px] italic" style="color: var(--p-text-muted-color)">No meta fields</div>
      </template>

      <template v-else-if="tab === 'data'">
        <div v-if="hasData">
          <JsonBlock :data="data" font-size="11px" />
        </div>
        <div v-else class="text-[11px] italic" style="color: var(--p-text-muted-color)">No data payload</div>
      </template>

      <template v-else-if="tab === 'raw'">
        <JsonBlock v-if="current" :data="current" font-size="11px" />
      </template>
    </DetailPanel>
  </div>
</template>

<style scoped>
.kv {
  display: grid;
  grid-template-columns: 90px 1fr;
  gap: 12px;
  font-size: 11px;
}
.k { color: var(--p-text-muted-color); }
.v { color: var(--p-text-color); word-break: break-all; }
.kv-row {
  padding: 4px 0;
  border-bottom: 1px solid var(--p-content-border-color);
}
.kv-row:last-child { border-bottom: 0; }
.k-row { font-size: 10px; color: var(--p-text-muted-color); margin-bottom: 2px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600; }
.v-row { font-size: 11px; color: var(--p-text-color); word-break: break-word; }
.kind-badge {
  display: inline-block;
  padding: 1px 8px; border-radius: 3px;
  font-size: 10px; font-family: 'JetBrains Mono', monospace;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
}
.json-mini {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  background: var(--p-surface-50);
  padding: 4px 6px; border-radius: 3px;
  max-height: 160px; overflow: auto;
}
.footer-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 3px 8px; border-radius: 4px;
  font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.footer-btn:hover:not(:disabled) { background: var(--p-surface-200); }
.footer-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.footer-btn.primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
}
.footer-btn.primary:hover { opacity: 0.9; }
</style>
