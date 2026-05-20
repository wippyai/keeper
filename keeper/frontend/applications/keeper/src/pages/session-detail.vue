<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'
import { useApi, useWippy } from '../composables/useWippy'
import { getSession, getSessionMessages, formatTokens, formatDate, timeAgo, type Session, type Message } from '../api/sessions'
import { msgColor, msgIcon, isSystemAction, systemActionText, prettyJson } from '../components/messages/msg-utils'

function msgBg(type: string): string {
  return ({ user: 'color-mix(in srgb, var(--p-info-500) 4%, transparent)', assistant: 'color-mix(in srgb, var(--p-success-500) 3%, transparent)', delegation: 'color-mix(in srgb, var(--p-danger-500) 3%, transparent)', function: 'color-mix(in srgb, var(--p-accent-400) 3%, transparent)' } as Record<string, string>)[type] || 'transparent'
}
import MsgRenderer from '../components/messages/MsgRenderer.vue'
import DetailPanel from '../components/shared/DetailPanel.vue'
import TokenBar from '../components/shared/TokenBar.vue'
import JsonBlock from '../components/shared/JsonBlock.vue'

const route = useRoute()
const router = useRouter()
const api = useApi()
const instance = useWippy()

const session = ref<Session | null>(null)
const messages = ref<Message[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const typeFilter = ref<string | null>(null)
const selected = ref<Message | null>(null)
const detailTab = ref('content')
const hasMore = ref(false)
const nextCursor = ref('')
const loadingMore = ref(false)
const showMeta = ref(false)
const showConfig = ref(false)
const showCheckpoints = ref(false)
const hideNoise = ref(true)
const copiedMsgId = ref<string | null>(null)

const STORAGE_KEY = 'keeper-session-panels'
const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')
const leftW = ref(saved.left || 190)
const rightW = ref(saved.right || 420)
function saveW() { localStorage.setItem(STORAGE_KEY, JSON.stringify({ left: leftW.value, right: rightW.value })) }

function goBack() {
  if (window.history.length > 1) router.back()
  else router.push('/sessions')
}

let resDir: 'l' | 'r' | null = null; let sx = 0; let sw = 0
function startResize(d: 'l' | 'r', e: MouseEvent) { resDir = d; sx = e.clientX; sw = d === 'l' ? leftW.value : rightW.value; document.addEventListener('mousemove', onR); document.addEventListener('mouseup', stopR); document.body.style.cursor = 'col-resize'; document.body.style.userSelect = 'none' }
function onR(e: MouseEvent) { if (!resDir) return; const dx = e.clientX - sx; if (resDir === 'l') leftW.value = Math.max(140, Math.min(300, sw + dx)); else rightW.value = Math.max(280, Math.min(700, sw - dx)) }
function stopR() { resDir = null; document.removeEventListener('mousemove', onR); document.removeEventListener('mouseup', stopR); document.body.style.cursor = ''; document.body.style.userSelect = ''; saveW() }

const sessionId = computed(() => route.params.id as string)
const filtered = computed(() => {
  let list = messages.value
  if (hideNoise.value) list = list.filter(m => m.type !== 'developer' && !(m.type === 'system' && m.metadata?.system_action) && m.type !== 'artifact')
  if (typeFilter.value) list = list.filter(m => m.type === typeFilter.value)
  return list
})
const msgCounts = computed(() => { const c: Record<string, number> = {}; for (const m of messages.value) c[m.type] = (c[m.type] || 0) + 1; return Object.entries(c).sort((a, b) => b[1] - a[1]) })
const tokens = computed(() => {
  const s = { total: 0, prompt: 0, completion: 0, thinking: 0, cache_read: 0, cache_write: 0 }
  for (const m of messages.value) { if (m.metadata?.tokens) { const t = m.metadata.tokens; s.total += t.total_tokens || 0; s.prompt += t.prompt_tokens || 0; s.completion += t.completion_tokens || 0; s.thinking += t.thinking_tokens || 0; s.cache_read += t.cache_read_tokens || 0; s.cache_write += t.cache_write_tokens || 0 } }
  return s
})

function selectMsg(m: Message) { selected.value = selected.value?.message_id === m.message_id ? null : m; detailTab.value = 'content' }

async function copyMsg(e: Event, m: Message) {
  e.stopPropagation()
  try {
    await navigator.clipboard.writeText(JSON.stringify(m, null, 2))
    copiedMsgId.value = m.message_id
    setTimeout(() => { if (copiedMsgId.value === m.message_id) copiedMsgId.value = null }, 1500)
  } catch {}
}

const exportToast = ref<string | null>(null)
function exportSession() {
  if (!session.value) return
  const dump = {
    exported_at: new Date().toISOString(),
    session: session.value,
    messages: messages.value,
    artifacts: artifactMessages.value,
  }
  const dataStr = JSON.stringify(dump, null, 2)
  // Copy to clipboard (best effort)
  navigator.clipboard?.writeText(dataStr).catch(() => {})
  // Trigger file download
  const blob = new Blob([dataStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `session-${sessionId.value || 'export'}.json`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
  exportToast.value = 'Exported + copied to clipboard'
  setTimeout(() => { exportToast.value = null }, 2500)
}

const isImported = computed(() => sessionId.value === 'imported')

const checkpoints = computed(() => {
  const cp = (session.value as any)?.meta?.checkpoints
  return Array.isArray(cp) ? cp : []
})

const artifactMessages = computed(() => messages.value.filter(m => m.type === 'artifact'))
function msgSummary(m: Message) { if (isSystemAction(m)) return systemActionText(m); if (m.type === 'function') return m.metadata?.function_name || 'call'; if (!m.data) return '(empty)'; return m.data.replace(/\n/g, ' ').slice(0, 100) }

async function loadMore() { if (!hasMore.value || loadingMore.value) return; loadingMore.value = true; try { const r = await getSessionMessages(api, sessionId.value, 100, nextCursor.value); messages.value.push(...r.messages); hasMore.value = r.pagination?.has_more || false; nextCursor.value = r.pagination?.next_cursor || '' } finally { loadingMore.value = false } }

function loadFromImport() {
  loading.value = true; error.value = null
  try {
    const raw = localStorage.getItem('@keeper/imported-session')
    if (!raw) { error.value = 'No imported session found in storage. Re-import from the Sessions list.'; return }
    const dump = JSON.parse(raw)
    session.value = dump.session || dump
    messages.value = (dump.messages || []).slice().sort((a: any, b: any) =>
      a.date && b.date ? new Date(a.date).getTime() - new Date(b.date).getTime() : 0
    )
    hasMore.value = false
    nextCursor.value = ''
  } catch (e: any) {
    error.value = 'Import parse failed: ' + (e.message || 'invalid JSON')
  } finally { loading.value = false }
}

async function load() {
  if (isImported.value) return loadFromImport()
  loading.value = true; error.value = null
  try {
    const [s, m] = await Promise.all([getSession(api, sessionId.value), getSessionMessages(api, sessionId.value, 500)])
    session.value = s.session
    messages.value = m.messages || []
    hasMore.value = m.pagination?.has_more || false
    nextCursor.value = m.pagination?.next_cursor || ''
  } catch (e: any) { error.value = e.message }
  finally { loading.value = false }
}

let unsubMessage: (() => void) | null = null
let unsubStatus: (() => void) | null = null

onMounted(() => {
  load()
  // Don't subscribe to live events for imported (offline) sessions.
  if (!isImported.value) {
    unsubMessage = instance.on('session:message', (d: any) => { if (d?.session_id === sessionId.value && d?.message) messages.value.push(d.message) })
    unsubStatus = instance.on('session:status', (d: any) => { if (d?.session_id === sessionId.value && session.value) session.value.status = d.status })
  }
})

onUnmounted(() => {
  unsubMessage?.()
  unsubStatus?.()
})
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="shrink-0 px-4 py-2 flex items-center gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
      <Button class="k-btn-icon !rounded" @click="goBack" title="Back"><Icon icon="tabler:arrow-left" class="w-4 h-4" /></Button>
      <div class="flex-1 min-w-0">
        <div class="text-sm font-medium truncate" style="color: var(--p-text-color)">{{ session?.title || '...' }}</div>
        <div class="flex items-center gap-3 text-[10px] mt-0.5" style="color: var(--p-text-muted-color)">
          <span class="font-mono">{{ sessionId.slice(0, 20) }}</span>
          <span v-if="session?.current_model">{{ session.current_model }}</span>
          <span>{{ formatTokens(tokens.total) }} tokens</span>
        </div>
      </div>
      <span v-if="isImported" class="flex items-center gap-1 px-2 py-0.5 rounded text-[10px] bg-info-500/15 text-info-500" title="Read-only — loaded from a JSON dump"><Icon icon="tabler:download" class="w-3 h-3" />Imported</span>
      <span v-else-if="session?.status === 'running'" class="flex items-center gap-1 px-2 py-0.5 rounded text-[10px] bg-success-500/15 text-success-500"><span class="w-1.5 h-1.5 rounded-full animate-pulse bg-success-500"></span>Running</span>
      <Button v-if="!isImported && session" class="k-btn-icon !rounded" @click="exportSession" title="Export JSON (download + clipboard)"><Icon icon="tabler:download" class="w-4 h-4" /></Button>
      <Button v-if="!isImported" class="k-btn-icon !rounded" @click="load" :disabled="loading"><Icon icon="tabler:refresh" class="w-4 h-4" :class="{ 'animate-spin': loading }" /></Button>
    </div>
    <div v-if="exportToast" class="export-toast">{{ exportToast }}</div>

    <div v-if="loading" class="flex-1 flex items-center justify-center"><Icon icon="tabler:loader-2" class="w-6 h-6 animate-spin keeper-accent" /></div>
    <div v-else-if="error" class="flex-1 flex items-center justify-center text-xs text-danger-500"><p>{{ error }}</p></div>

    <div v-else class="flex-1 flex overflow-hidden">
      <!-- Left sidebar -->
      <aside class="shrink-0 overflow-y-auto px-3 py-3 space-y-4" :style="{ width: leftW + 'px' }">
        <div>
          <div class="lbl">Tokens</div>
          <div class="space-y-1 text-[11px]">
            <div class="srow"><span>Prompt</span><span class="font-mono text-accent-500">{{ tokens.prompt.toLocaleString() }}</span></div>
            <div class="srow"><span>Completion</span><span class="font-mono text-accent-400">{{ tokens.completion.toLocaleString() }}</span></div>
            <div v-if="tokens.thinking" class="srow"><span>Thinking</span><span class="font-mono text-warn-500">{{ tokens.thinking.toLocaleString() }}</span></div>
            <div v-if="tokens.cache_read" class="srow"><span>Cache R</span><span class="font-mono text-info-500">{{ tokens.cache_read.toLocaleString() }}</span></div>
            <div v-if="tokens.cache_write" class="srow"><span>Cache W</span><span class="font-mono text-success-500">{{ tokens.cache_write.toLocaleString() }}</span></div>
            <div class="srow pt-1" style="border-top: 1px solid var(--p-content-border-color)"><span class="font-medium" style="color: var(--p-text-color)">Total</span><span style="color: var(--p-text-color)" class="font-mono font-semibold">{{ tokens.total.toLocaleString() }}</span></div>
          </div>
        </div>
        <div>
          <div class="lbl flex items-center justify-between">
            <span>Messages</span>
            <label class="flex items-center gap-1 cursor-pointer text-[10px] normal-case tracking-normal font-normal" style="color: var(--p-text-muted-color)">
              <input type="checkbox" v-model="hideNoise" class="w-3 h-3" /> Clean
            </label>
          </div>
          <button class="fbtn" :class="{ act: !typeFilter }" @click="typeFilter = null"><span>All</span><span class="cnt">{{ filtered.length }}</span></button>
          <button v-for="[t, c] in msgCounts" :key="t" class="fbtn" :class="{ act: typeFilter === t }" @click="typeFilter = typeFilter === t ? null : t"><span :style="{ color: msgColor(t) }">{{ t }}</span><span class="cnt">{{ c }}</span></button>
        </div>
        <div>
          <div class="lbl">Session</div>
          <div class="space-y-1 text-[11px]">
            <div class="srow"><span>Status</span><span style="color: var(--p-text-color)">{{ session!.status || 'idle' }}</span></div>
            <div class="srow"><span>Kind</span><span style="color: var(--p-text-color)">{{ session!.kind || 'default' }}</span></div>
            <div class="srow"><span>Started</span><span style="color: var(--p-text-color)" :title="String(session!.start_date)">{{ formatDate(session!.start_date) }}</span></div>
            <div class="srow"><span>Active</span><span style="color: var(--p-text-color)" :title="formatDate(session!.last_message_date)">{{ timeAgo(session!.last_message_date) }}</span></div>
          </div>
        </div>

        <!-- Checkpoints (collapsible) -->
        <div v-if="checkpoints.length">
          <button class="lbl cursor-pointer flex items-center gap-1" @click="showCheckpoints = !showCheckpoints">
            <Icon :icon="showCheckpoints ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3" />
            Checkpoints <span class="font-normal opacity-60 normal-case tracking-normal">({{ checkpoints.length }})</span>
          </button>
          <div v-if="showCheckpoints" class="space-y-1.5 text-[10px] mt-1">
            <div v-for="cp in checkpoints" :key="cp.checkpoint_id" class="rounded p-2" style="background: var(--p-surface-100); border: 1px solid var(--p-content-border-color)">
              <div class="font-mono truncate text-[10px]" style="color: var(--p-text-color)" :title="cp.checkpoint_id">{{ cp.checkpoint_id }}</div>
              <div class="text-[9px] mt-0.5" style="color: var(--p-text-muted-color)">{{ formatDate(cp.created_at) }}</div>
              <div v-if="cp.checkpoint_tokens" class="flex flex-wrap gap-x-2 gap-y-0.5 text-[9px] font-mono mt-1">
                <span class="text-accent-500">P&nbsp;{{ (cp.checkpoint_tokens.prompt_tokens || 0).toLocaleString() }}</span>
                <span class="text-accent-400">C&nbsp;{{ (cp.checkpoint_tokens.completion_tokens || 0).toLocaleString() }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Artifacts (linked to messages of type=artifact) -->
        <div v-if="artifactMessages.length">
          <div class="lbl">Artifacts <span class="font-normal opacity-60 normal-case tracking-normal">({{ artifactMessages.length }})</span></div>
          <div class="space-y-1">
            <button v-for="m in artifactMessages.slice(0, 8)" :key="m.message_id" class="fbtn" :class="{ act: selected?.message_id === m.message_id }" @click="selectMsg(m); typeFilter = 'artifact'; hideNoise = false">
              <span class="truncate text-info-500" :title="m.metadata?.function_name || m.data?.slice(0, 80) || m.message_id">{{ m.metadata?.function_name || m.data?.slice(0, 32) || 'artifact' }}</span>
              <span class="cnt">{{ formatDate(m.date) }}</span>
            </button>
          </div>
        </div>
        <div v-if="session?.meta && Object.keys(session.meta).length">
          <button class="lbl cursor-pointer flex items-center gap-1" @click="showMeta = !showMeta"><Icon :icon="showMeta ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3" /> Meta</button>
          <JsonBlock v-if="showMeta" :data="session.meta" font-size="10px" max-height="200px" class="mt-1" />
        </div>
        <div v-if="(session as any)?.config">
          <button class="lbl cursor-pointer flex items-center gap-1" @click="showConfig = !showConfig"><Icon :icon="showConfig ? 'tabler:chevron-down' : 'tabler:chevron-right'" class="w-3 h-3" /> Config</button>
          <JsonBlock v-if="showConfig" :data="(session as any).config" font-size="10px" max-height="200px" class="mt-1" />
        </div>
      </aside>

      <div class="rh" @mousedown="startResize('l', $event)"></div>

      <!-- Center: message list -->
      <div class="flex-1 overflow-y-auto min-w-0">
        <div
          v-for="msg in filtered" :key="msg.message_id"
          class="msg-row group relative px-4 py-3 cursor-pointer"
          :class="{ 'msg-sel': selected?.message_id === msg.message_id }"
          :style="{ background: selected?.message_id === msg.message_id ? 'var(--p-surface-100)' : msgBg(msg.type) }"
          @click="selectMsg(msg)"
        >
          <MsgRenderer :msg="msg" />
          <button
            class="copy-btn opacity-0 group-hover:opacity-100"
            :title="copiedMsgId === msg.message_id ? 'Copied!' : 'Copy JSON'"
            @click="copyMsg($event, msg)"
          >
            <Icon :icon="copiedMsgId === msg.message_id ? 'tabler:check' : 'tabler:copy'" class="w-3 h-3" />
          </button>
        </div>
        <div v-if="hasMore" class="px-4 py-3 text-center">
          <button class="text-xs px-3 py-1 rounded" style="color: var(--p-primary-color); background: var(--p-surface-100)" @click="loadMore" :disabled="loadingMore">{{ loadingMore ? 'Loading...' : 'Load more' }}</button>
        </div>
      </div>

      <!-- Right: detail panel -->
      <template v-if="selected">
        <div class="rh" @mousedown="startResize('r', $event)"></div>
        <div class="shrink-0" :style="{ width: rightW + 'px' }">
          <DetailPanel :icon="msgIcon(selected.type)" :icon-color="msgColor(selected.type)" :title="selected.type" :subtitle="formatDate(selected.date)" :tabs="['content', 'meta', 'raw']" v-model:active-tab="detailTab" @close="selected = null">
            <template #subheader>
              <div v-if="selected.metadata?.tokens" class="px-4 py-1.5" style="border-bottom: 1px solid var(--p-content-border-color)">
                <TokenBar :prompt="selected.metadata.tokens.prompt_tokens" :completion="selected.metadata.tokens.completion_tokens" :thinking="selected.metadata.tokens.thinking_tokens" :cache-read="selected.metadata.tokens.cache_read_tokens" :cache-write="selected.metadata.tokens.cache_write_tokens" :total="selected.metadata.tokens.total_tokens" />
              </div>
            </template>
            <template v-if="detailTab === 'content'">
              <div v-if="selected.data" class="text-sm whitespace-pre-wrap break-words leading-relaxed" style="color: var(--p-text-color)">{{ selected.data }}</div>
              <div v-else class="text-xs italic" style="color: var(--p-text-muted-color)">(empty)</div>
            </template>
            <template v-else-if="detailTab === 'meta'">
              <JsonBlock v-if="selected.metadata" :data="selected.metadata" />
              <div v-else class="text-xs italic" style="color: var(--p-text-muted-color)">No metadata</div>
            </template>
            <template v-else>
              <JsonBlock :data="selected" font-size="10px" />
            </template>
            <template #footer>
              <div class="px-4 py-1 text-[9px] font-mono truncate" style="border-top: 1px solid var(--p-content-border-color); color: var(--p-text-muted-color); opacity: 0.5">{{ selected.message_id }}</div>
            </template>
          </DetailPanel>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.lbl { font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600; color: var(--p-text-muted-color); margin-bottom: 6px; }
.srow { display: flex; justify-content: space-between; color: var(--p-text-muted-color); }
.fbtn { width: 100%; display: flex; justify-content: space-between; padding: 3px 8px; border-radius: 4px; font-size: 11px; color: var(--p-text-color); }
.fbtn:hover { background: var(--p-surface-100); }
.fbtn.act { background: var(--p-surface-100); }
.fbtn .cnt { color: var(--p-text-muted-color); }
.rh { width: 4px; cursor: col-resize; flex-shrink: 0; border-left: 1px solid var(--p-content-border-color); }
.rh:hover { background: var(--p-primary-color); opacity: 0.25; }
.msg-row { border-bottom: 1px solid var(--p-content-border-color); cursor: pointer; }
.msg-row:hover { background: var(--p-surface-100); }
.msg-sel { background: var(--p-surface-100) !important; }
.copy-btn {
  position: absolute; top: 8px; right: 8px;
  display: flex; align-items: center; justify-content: center;
  width: 22px; height: 22px;
  background: var(--p-surface-50);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  cursor: pointer;
  transition: opacity 0.15s, background 0.1s, color 0.1s;
}
.copy-btn:hover { background: var(--p-surface-100); color: var(--p-text-color); }
.export-toast {
  position: fixed; top: 60px; right: 16px; z-index: 100;
  background: var(--p-content-background); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  padding: 8px 14px; border-radius: 6px; font-size: 11px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  display: flex; align-items: center; gap: 8px;
}
</style>
