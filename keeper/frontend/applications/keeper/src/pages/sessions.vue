<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import PageHeader from '../components/shared/PageHeader.vue'
import {
  listSessions,
  formatTokens,
  timeAgo,
  type Session,
} from '../api/sessions'

const api = useApi()
const router = useRouter()

const sessions = ref<Session[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const searchTerm = ref('')
const currentPage = ref(0)
const pageSize = 30

const filteredSessions = computed(() => {
  if (!searchTerm.value) return sessions.value
  const term = searchTerm.value.toLowerCase()
  return sessions.value.filter(s =>
    (s.title && s.title.toLowerCase().includes(term))
    || s.session_id.toLowerCase().includes(term),
  )
})

const paginatedSessions = computed(() => {
  const start = currentPage.value * pageSize
  return filteredSessions.value.slice(start, start + pageSize)
})

const startIndex = computed(() => filteredSessions.value.length === 0 ? 0 : currentPage.value * pageSize + 1)
const endIndex = computed(() => Math.min((currentPage.value + 1) * pageSize, filteredSessions.value.length))
const hasPrev = computed(() => currentPage.value > 0)
const hasNext = computed(() => endIndex.value < filteredSessions.value.length)

function totalTokens(s: Session): number {
  return s.meta?.tokens?.total_tokens || 0
}

function viewSession(sessionId: string) {
  router.push(`/session/${sessionId}`)
}

async function loadSessions() {
  loading.value = true
  error.value = null
  try {
    const result = await listSessions(api, 1000)
    sessions.value = result.sessions || []
  } catch (e: any) {
    error.value = e.message || 'Failed to load sessions'
  } finally {
    loading.value = false
  }
}

const importOpen = ref(false)
const importJson = ref('')
const importError = ref<string | null>(null)

function openImport() {
  importJson.value = ''
  importError.value = null
  importOpen.value = true
}

async function pasteFromClipboard() {
  try {
    importJson.value = await navigator.clipboard.readText()
  } catch {}
}

function importFromFile(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    importJson.value = String(reader.result || '')
  }
  reader.readAsText(file)
}

function submitImport() {
  importError.value = null
  const raw = importJson.value.trim()
  if (!raw) { importError.value = 'Paste a JSON dump first.'; return }
  try {
    const dump = JSON.parse(raw)
    if (!dump.session && !dump.messages) {
      importError.value = 'Expected an object with `session` and `messages` fields.'
      return
    }
    localStorage.setItem('@keeper/imported-session', raw)
    importOpen.value = false
    router.push('/session/imported')
  } catch (e: any) {
    importError.value = 'Invalid JSON: ' + (e.message || 'parse error')
  }
}

onMounted(loadSessions)
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader title="Sessions" :count="filteredSessions.length" :loading="loading" @refresh="loadSessions">
      <div class="search-wrap">
        <Icon icon="tabler:search" class="search-icon" />
        <input v-model="searchTerm" @input="currentPage = 0" type="text" placeholder="Search sessions..." class="search-input" />
      </div>
      <button class="header-btn" @click="openImport" title="Import a session JSON dump">
        <Icon icon="tabler:upload" class="w-3.5 h-3.5" />
        Import
      </button>
    </PageHeader>

    <div v-if="error" class="mx-3 mt-2 px-2 py-1.5 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
      <button @click="loadSessions" class="underline">Retry</button>
    </div>

    <div v-if="!loading && filteredSessions.length === 0" class="flex-1 flex items-center justify-center">
      <div class="text-center text-xs" style="color: var(--p-text-muted-color)">
        {{ searchTerm ? 'No matches' : 'No sessions' }}
      </div>
    </div>

    <div v-else class="flex-1 overflow-y-auto">
      <div
        v-for="session in paginatedSessions"
        :key="session.session_id"
        class="session-row flex items-center gap-3 px-3 py-2 cursor-pointer"
        style="border-bottom: 1px solid var(--p-content-border-color)"
        @click="viewSession(session.session_id)"
      >
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-1.5 text-xs">
            <span class="truncate" style="color: var(--p-text-color)">{{ session.title || 'Untitled' }}</span>
            <span v-if="session.status === 'running'" class="shrink-0 w-1.5 h-1.5 rounded-full animate-pulse bg-success-500"></span>
            <span v-if="session.current_model" class="shrink-0 text-[10px]" style="color: var(--p-text-muted-color)">{{ session.current_model }}</span>
          </div>
          <div class="text-[10px] font-mono mt-0.5 truncate" style="color: var(--p-text-muted-color)">{{ session.session_id }}</div>
        </div>
        <span v-if="totalTokens(session)" class="shrink-0 text-[10px] font-mono" style="color: var(--p-text-muted-color)">{{ formatTokens(totalTokens(session)) }}</span>
        <span class="shrink-0 text-[10px] w-16 text-right" style="color: var(--p-text-muted-color)">{{ timeAgo(session.last_message_date) }}</span>
        <Icon icon="tabler:chevron-right" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color); opacity: 0.4" />
      </div>
    </div>

    <div
      v-if="filteredSessions.length > pageSize"
      class="shrink-0 px-3 py-1.5 flex items-center justify-between text-[10px]"
      style="border-top: 1px solid var(--p-content-border-color); color: var(--p-text-muted-color)"
    >
      <span>{{ startIndex }}-{{ endIndex }} of {{ filteredSessions.length }}</span>
      <div class="flex gap-1">
        <button :disabled="!hasPrev" @click="currentPage--" class="px-2 py-0.5 rounded" :style="{ opacity: hasPrev ? 1 : 0.3, background: 'var(--p-surface-100)' }">Prev</button>
        <button :disabled="!hasNext" @click="currentPage++" class="px-2 py-0.5 rounded" :style="{ opacity: hasNext ? 1 : 0.3, background: 'var(--p-surface-100)' }">Next</button>
      </div>
    </div>

    <!-- Import dialog -->
    <Teleport to="body">
      <div v-if="importOpen" class="import-overlay" @click.self="importOpen = false">
        <div class="import-dialog">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:upload" class="w-5 h-5 keeper-accent" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Import session</span>
          </div>
          <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
            Paste a session JSON dump to render it locally — no live backend required.
            The dump should look like
            <code class="font-mono">{ session, messages, artifacts? }</code>.
          </p>

          <textarea
            v-model="importJson"
            class="import-textarea"
            placeholder='{ "session": { "session_id": "..." }, "messages": [...] }'
            spellcheck="false"
          />

          <div v-if="importError" class="mt-2 px-2 py-1.5 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
            <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
            <span>{{ importError }}</span>
          </div>

          <div class="flex items-center gap-2 mt-3">
            <button class="header-btn" @click="pasteFromClipboard">
              <Icon icon="tabler:clipboard" class="w-3.5 h-3.5" /> Paste
            </button>
            <label class="header-btn cursor-pointer">
              <Icon icon="tabler:file-upload" class="w-3.5 h-3.5" /> Open file…
              <input type="file" accept=".json,application/json" class="hidden" @change="importFromFile" />
            </label>
            <span class="flex-1"></span>
            <button class="header-btn" @click="importOpen = false">Cancel</button>
            <button class="primary-btn" :disabled="!importJson.trim()" @click="submitImport">
              Render
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.session-row:hover {
  background: var(--p-surface-100);
}

.header-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 10px; border-radius: 4px;
  font-size: 11px; font-weight: 500;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background 0.1s, border-color 0.1s;
}
.header-btn:hover { background: var(--p-surface-200); border-color: var(--p-primary-color); }
.primary-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 12px; border-radius: 4px;
  font-size: 11px; font-weight: 600;
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border: 1px solid var(--p-primary-color);
  cursor: pointer;
}
.primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.primary-btn:not(:disabled):hover { opacity: 0.9; }

.import-overlay {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(0,0,0,0.6);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}
.import-dialog {
  width: 600px; max-width: 100%;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}
.import-textarea {
  width: 100%;
  height: 220px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  padding: 8px 10px;
  background: var(--p-surface-50);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  outline: none;
  resize: vertical;
}
.import-textarea:focus { border-color: var(--p-primary-color); }
.hidden { display: none; }
</style>
