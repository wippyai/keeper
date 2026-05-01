<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import { listTokens, createToken, revokeToken, listScopes, type MCPToken, type MCPScope, type MCPPreset, type MCPServerConfig } from '../api/mcp'

const api = useApi()

const tokens = ref<MCPToken[]>([])
const scopes = ref<MCPScope[]>([])
const presets = ref<MCPPreset[]>([])
const serverConfig = ref<MCPServerConfig | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const successMsg = ref<string | null>(null)

interface CurrentUser {
  id?: string
  user_id?: string
  email?: string
  full_name?: string
}

const currentUser = ref<CurrentUser | null>(null)

const showCreate = ref(false)
const newLabel = ref('')
const selectedScopes = ref<Set<string>>(new Set())
const selectedPreset = ref<MCPPreset | null>(null)
const creating = ref(false)
const createdToken = ref<string | null>(null)
const copied = ref(false)

const revoking = ref<string | null>(null)
const copiedSnippet = ref<string | null>(null)

const activeTokens = computed(() => tokens.value.filter(t => !t.revoked))
const revokedTokens = computed(() => tokens.value.filter(t => t.revoked))

const mcpUrl = computed(() =>
  serverConfig.value?.url || ''
)
const endpointStatus = computed(() => serverConfig.value?.enabled === false ? 'Disabled' : 'Enabled')
const snippetToken = computed(() => '<TOKEN>')
const currentIdentity = computed(() =>
  currentUser.value?.user_id || currentUser.value?.id || currentUser.value?.email || ''
)
const currentUserTitle = computed(() =>
  currentUser.value?.full_name || currentUser.value?.email || currentIdentity.value || 'Unknown user'
)
const currentUserSubtitle = computed(() => {
  const email = currentUser.value?.email
  const identity = currentIdentity.value
  if (email && identity && email !== identity) return `${email} · ${identity}`
  return identity || 'Current user could not be resolved'
})

const claudeCodeSnippet = computed(() => JSON.stringify({
  mcpServers: {
    keeper: {
      type: 'http',
      url: mcpUrl.value,
      headers: { Authorization: `Bearer ${snippetToken.value}` },
    },
  },
}, null, 2))

const claudeDesktopSnippet = computed(() => JSON.stringify({
  mcpServers: {
    keeper: {
      url: mcpUrl.value,
      headers: { Authorization: `Bearer ${snippetToken.value}` },
    },
  },
}, null, 2))

const curlSnippet = computed(() =>
  `curl -s -X POST ${mcpUrl.value} \\
  -H "Authorization: Bearer ${snippetToken.value}" \\
  -H "Content-Type: application/json" \\
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'`
)

async function load() {
  loading.value = true
  error.value = null
  try {
    const [tokensRes, scopesRes] = await Promise.all([listTokens(api), listScopes(api), loadCurrentUser()])
    tokens.value = tokensRes.tokens || []
    scopes.value = scopesRes.scopes || []
    presets.value = scopesRes.presets || []
    serverConfig.value = scopesRes.config || null
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function loadCurrentUser() {
  try {
    const { data } = await api.get('/api/v1/user/me')
    if (data.success && data.user) {
      currentUser.value = data.user
    }
  } catch (e: any) {
    currentUser.value = null
  }
}

function applyPreset(preset: MCPPreset) {
  selectedPreset.value = preset
  selectedScopes.value = new Set(preset.scopes)
}

function toggleScope(id: string) {
  const s = new Set(selectedScopes.value)
  if (s.has(id)) s.delete(id); else s.add(id)
  selectedScopes.value = s
}

function openCreate() {
  showCreate.value = true
  newLabel.value = ''
  selectedScopes.value = new Set()
  selectedPreset.value = null
  createdToken.value = null
  copied.value = false
  if (!currentIdentity.value) loadCurrentUser()
}

async function doCreate() {
  if (!newLabel.value.trim()) { error.value = 'Label required'; return }
  if (selectedScopes.value.size === 0) { error.value = 'Select at least one scope'; return }
  if (!currentIdentity.value) await loadCurrentUser()
  const identity = currentIdentity.value.trim()
  if (!identity) { error.value = 'Current user identity is unavailable'; return }

  creating.value = true
  error.value = null
  try {
    const params: Parameters<typeof createToken>[1] = {
      label: newLabel.value.trim(),
      identity,
      scopes: [...selectedScopes.value],
    }
    if (selectedPreset.value) {
      params.preset = selectedPreset.value.id
      if (selectedPreset.value.access_mode !== undefined) params.access_mode = selectedPreset.value.access_mode
      if (selectedPreset.value.trait_filter !== undefined) params.trait_filter = selectedPreset.value.trait_filter
      if (selectedPreset.value.tool_filter !== undefined) params.tool_filter = selectedPreset.value.tool_filter
      if (selectedPreset.value.default_active !== undefined) params.default_active = selectedPreset.value.default_active
    }

    const result = await createToken(api, params)
    if (result.success) {
      createdToken.value = result.token.token
      await load()
    } else {
      error.value = result.error || 'Create failed'
    }
  } catch (e: any) {
    error.value = e.message
  } finally {
    creating.value = false
  }
}

async function copy(text: string, id: string) {
  try {
    await navigator.clipboard.writeText(text)
    copiedSnippet.value = id
    setTimeout(() => { copiedSnippet.value = null }, 1500)
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

async function doRevoke(tokenId: string) {
  error.value = null
  try {
    const result = await revokeToken(api, tokenId)
    if (result.success) {
      revoking.value = null
      await load()
    } else {
      error.value = result.error || 'Revoke failed'
    }
  } catch (e: any) {
    error.value = e.message
  }
}

function formatDate(ts: number) {
  if (!ts) return '-'
  return new Date(ts * 1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

function stableValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(stableValue)
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([k, v]) => [k, stableValue(v)])
    )
  }
  return value ?? null
}

function sameJson(a: unknown, b: unknown) {
  return JSON.stringify(stableValue(a)) === JSON.stringify(stableValue(b))
}

function sameArray(a: string[] | undefined, b: string[] | undefined) {
  const left = [...(a || [])].sort()
  const right = [...(b || [])].sort()
  return left.length === right.length && left.every((v, i) => v === right[i])
}

function matchingPreset(token: MCPToken): MCPPreset | null {
  const set = new Set(token.scopes || [])
  for (const p of presets.value) {
    const scopesMatch = p.scopes.length === set.size && p.scopes.every(s => set.has(s))
    if (!scopesMatch) continue
    if (token.access_mode && token.access_mode !== p.access_mode) continue
    if (token.trait_filter !== undefined && !sameJson(token.trait_filter, p.trait_filter)) continue
    if (token.tool_filter !== undefined && !sameJson(token.tool_filter, p.tool_filter)) continue
    if (token.default_active !== undefined && !sameArray(token.default_active, p.default_active)) continue
    return p
  }
  return null
}

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="shrink-0 px-4 py-2 flex items-center gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
      <Icon icon="tabler:plug-connected" class="w-4 h-4 keeper-accent" />
      <div class="flex-1 min-w-0">
        <div class="text-sm font-semibold" style="color: var(--p-text-color)">MCP Server</div>
        <div class="text-[10px]" style="color: var(--p-text-muted-color)">
          <span class="font-mono">{{ mcpUrl }}</span>
          <span class="mx-2">·</span>
          <span>{{ endpointStatus }}</span>
          <span class="mx-2">·</span>
          <span>{{ activeTokens.length }} token{{ activeTokens.length === 1 ? '' : 's' }}</span>
          <span class="mx-2">·</span>
          <span>{{ scopes.length }} scopes</span>
        </div>
      </div>
      <button class="refresh-btn" @click="load" :disabled="loading">
        <Icon icon="tabler:refresh" class="w-4 h-4" :class="{ 'animate-spin': loading }" />
      </button>
    </div>

    <div v-if="successMsg" class="banner ok">
      <Icon icon="tabler:check" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ successMsg }}</span>
      <button @click="successMsg = null"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>
    <div v-if="error" class="banner err">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
      <button @click="error = null"><Icon icon="tabler:x" class="w-3 h-3" /></button>
    </div>

    <div class="flex-1 overflow-hidden flex min-h-0">
      <!-- Left: server config -->
      <aside class="left-pane">
        <!-- Server info -->
        <section class="card">
          <div class="card-title">
            <Icon icon="tabler:server" class="w-3.5 h-3.5" />
            <span>Server</span>
          </div>
          <div class="kv"><span class="k">Status</span><span class="v">{{ endpointStatus }}</span></div>
          <div class="kv"><span class="k">Endpoint</span><span class="v mono">{{ mcpUrl }}</span></div>
          <div class="kv"><span class="k">Protocol</span><span class="v">JSON-RPC 2.0</span></div>
          <div class="kv"><span class="k">Transport</span><span class="v">HTTP POST</span></div>
        </section>
      </aside>

      <!-- Right: connect snippets + token list -->
      <div class="right-pane">
        <!-- Quick connect -->
        <section class="card snippet-card">
          <div class="card-title">
            <Icon icon="tabler:rocket" class="w-3.5 h-3.5" />
            <span>Quick Connect</span>
          </div>

          <div class="snippet">
            <div class="snippet-head">
              <Icon icon="tabler:brand-vscode" class="w-3 h-3" />
              <span>Claude Code · <code>.mcp.json</code></span>
              <button class="mini-btn" @click="copy(claudeCodeSnippet, 'cc')">
                <Icon :icon="copiedSnippet === 'cc' ? 'tabler:check' : 'tabler:copy'" class="w-3 h-3" />
                {{ copiedSnippet === 'cc' ? 'Copied' : 'Copy' }}
              </button>
            </div>
            <pre class="snippet-code">{{ claudeCodeSnippet }}</pre>
          </div>

          <div class="snippet">
            <div class="snippet-head">
              <Icon icon="tabler:device-desktop" class="w-3 h-3" />
              <span>Claude Desktop · <code>claude_desktop_config.json</code></span>
              <button class="mini-btn" @click="copy(claudeDesktopSnippet, 'cd')">
                <Icon :icon="copiedSnippet === 'cd' ? 'tabler:check' : 'tabler:copy'" class="w-3 h-3" />
                {{ copiedSnippet === 'cd' ? 'Copied' : 'Copy' }}
              </button>
            </div>
            <pre class="snippet-code">{{ claudeDesktopSnippet }}</pre>
          </div>

          <div class="snippet">
            <div class="snippet-head">
              <Icon icon="tabler:terminal-2" class="w-3 h-3" />
              <span>Test with curl</span>
              <button class="mini-btn" @click="copy(curlSnippet, 'curl')">
                <Icon :icon="copiedSnippet === 'curl' ? 'tabler:check' : 'tabler:copy'" class="w-3 h-3" />
                {{ copiedSnippet === 'curl' ? 'Copied' : 'Copy' }}
              </button>
            </div>
            <pre class="snippet-code">{{ curlSnippet }}</pre>
          </div>
        </section>

        <!-- Token list -->
        <section class="card">
          <div class="card-title">
            <Icon icon="tabler:key" class="w-3.5 h-3.5" />
            <span>Scoped Tokens</span>
            <span class="count">{{ activeTokens.length }}</span>
            <div class="flex-1"></div>
            <button class="mini-btn primary" @click="openCreate">
              <Icon icon="tabler:plus" class="w-3 h-3" /> New Token
            </button>
          </div>

          <div v-if="activeTokens.length === 0 && !loading" class="empty">
            <Icon icon="tabler:key-off" class="w-5 h-5" />
            <span>No scoped tokens. Create one for the current user, then paste it into your MCP client.</span>
          </div>

          <div v-for="t in activeTokens" :key="t.token_id" class="t-row">
            <div class="t-row-main">
              <Icon icon="tabler:key" class="w-3 h-3 shrink-0 keeper-accent" />
              <span class="t-label">{{ t.label }}</span>
              <span class="t-chip">{{ t.identity }}</span>
              <span v-if="matchingPreset(t)" class="t-chip preset">
                <Icon :icon="matchingPreset(t)!.icon" class="w-2.5 h-2.5" />
                {{ matchingPreset(t)!.label }}
              </span>
              <span v-else class="t-chip">{{ t.scopes.length }} scopes</span>
              <code class="t-val">{{ t.token }}</code>
              <span class="t-date">{{ formatDate(t.created_at) }}</span>
              <button class="icon-btn" title="Copy" @click="copy(t.token, t.token_id)">
                <Icon :icon="copiedSnippet === t.token_id ? 'tabler:check' : 'tabler:copy'" class="w-3 h-3" />
              </button>
              <button class="icon-btn danger" title="Revoke" @click="revoking = t.token_id">
                <Icon icon="tabler:trash" class="w-3 h-3" />
              </button>
            </div>
          </div>

          <details v-if="revokedTokens.length > 0" class="revoked-group">
            <summary>{{ revokedTokens.length }} revoked</summary>
            <div v-for="t in revokedTokens" :key="t.token_id" class="t-row revoked">
              <Icon icon="tabler:key-off" class="w-3 h-3" />
              <span class="t-label line-through">{{ t.label }}</span>
              <code class="t-val">{{ t.token }}</code>
            </div>
          </details>
        </section>
      </div>
    </div>

    <!-- Create dialog -->
    <Teleport to="body">
      <div v-if="showCreate" class="dialog-overlay" @click.self="showCreate = false">
        <div class="dialog-box">
          <template v-if="!createdToken">
            <div class="dlg-head">
              <Icon icon="tabler:key" class="w-4 h-4 keeper-accent" />
              <span>Create Scoped Token</span>
            </div>

            <label class="field-label">Label</label>
            <input v-model="newLabel" class="input" placeholder="e.g. Claude Code Dev" />

            <label class="field-label">Subject</label>
            <div class="subject-box" :class="{ missing: !currentIdentity }">
              <Icon icon="tabler:user-shield" class="w-4 h-4 shrink-0 keeper-accent" />
              <div class="min-w-0">
                <div class="subject-title">{{ currentUserTitle }}</div>
                <div class="subject-sub">{{ currentUserSubtitle }}</div>
              </div>
            </div>

            <label class="field-label">Preset</label>
            <div class="chip-row">
              <button v-for="p in presets" :key="p.id" class="mini-btn"
                :class="{ primary: selectedPreset?.id === p.id }"
                @click="applyPreset(p)" :title="p.description">
                <Icon :icon="p.icon" class="w-3 h-3" />
                {{ p.label }}
              </button>
            </div>

            <label class="field-label">Scopes ({{ selectedScopes.size }}/{{ scopes.length }})</label>
            <div class="scope-grid">
              <label v-for="s in scopes" :key="s.id" class="scope-item" :title="s.description">
                <input type="checkbox" :checked="selectedScopes.has(s.id)" @change="toggleScope(s.id)" />
                <div>
                  <div class="s-name">{{ s.label }}</div>
                  <div class="s-desc">{{ s.description }}</div>
                </div>
              </label>
            </div>

            <div class="dlg-actions">
              <button class="mini-btn" @click="showCreate = false">Cancel</button>
              <button class="mini-btn primary" :disabled="creating || !currentIdentity" @click="doCreate">
                <Icon v-if="creating" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
                Create
              </button>
            </div>
          </template>

          <template v-else>
            <div class="dlg-head">
              <Icon icon="tabler:circle-check" class="w-4 h-4 text-success-500" />
              <span>Token Created</span>
            </div>
            <div class="card-help">Copy now — this value will not be shown again.</div>
            <div class="token-row" style="margin: 8px 0">
              <code class="token-val">{{ createdToken }}</code>
              <button class="icon-btn" @click="copy(createdToken!, 'new')">
                <Icon :icon="copiedSnippet === 'new' ? 'tabler:check' : 'tabler:copy'" class="w-3.5 h-3.5" />
              </button>
            </div>
            <div class="dlg-actions">
              <button class="mini-btn primary" @click="showCreate = false">Done</button>
            </div>
          </template>
        </div>
      </div>
    </Teleport>

    <Teleport to="body">
      <div v-if="revoking" class="dialog-overlay" @click.self="revoking = null">
        <div class="dialog-box" style="max-width: 340px">
          <div class="dlg-head">
            <Icon icon="tabler:trash" class="w-4 h-4 text-danger-500" />
            <span>Revoke Token</span>
          </div>
          <div class="card-help">This token will stop working immediately. Cannot be undone.</div>
          <div class="dlg-actions">
            <button class="mini-btn" @click="revoking = null">Cancel</button>
            <button class="mini-btn danger" @click="doRevoke(revoking!)">Revoke</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.refresh-btn {
  padding: 4px;
  background: transparent; border: 0;
  color: var(--p-text-muted-color);
  cursor: pointer;
  border-radius: 4px;
}
.refresh-btn:hover { background: var(--p-surface-100); color: var(--p-text-color); }

.banner {
  display: flex; align-items: center; gap: 8px;
  margin: 8px 12px 0;
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 11px;
}
.banner button { background: transparent; border: 0; cursor: pointer; color: var(--p-text-muted-color); }
.banner.ok { background: color-mix(in srgb, var(--p-success-500) 8%, transparent); color: var(--p-success-500); }
.banner.err { background: color-mix(in srgb, var(--p-danger-500) 8%, transparent); color: var(--p-danger-500); }

.left-pane {
  width: 280px;
  flex-shrink: 0;
  padding: 12px;
  overflow-y: auto;
  border-right: 1px solid var(--p-content-border-color);
  display: flex; flex-direction: column; gap: 12px;
}
.right-pane {
  flex: 1;
  min-width: 0;
  overflow-y: auto;
  padding: 12px;
  display: flex; flex-direction: column; gap: 12px;
}

.card {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 10px 12px;
}
.card-title {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--p-text-color);
  margin-bottom: 8px;
}
.card-title .count {
  font-size: 9px; font-weight: 600;
  padding: 1px 6px; border-radius: 3px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.card-help {
  font-size: 10px;
  color: var(--p-text-muted-color);
  margin-bottom: 8px;
  line-height: 1.4;
}
.warn-pill {
  font-size: 9px; font-weight: 600;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-warn-500) 15%, transparent);
  color: var(--p-warn-500);
  text-transform: none;
  letter-spacing: 0;
  margin-left: 6px;
}

.token-row {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 8px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  margin-bottom: 6px;
}
.token-val {
  flex: 1; min-width: 0;
  font-family: ui-monospace, monospace;
  font-size: 10px;
  color: var(--p-text-color);
  word-break: break-all;
  user-select: all;
}

.icon-btn {
  padding: 4px;
  background: transparent;
  border: 0;
  cursor: pointer;
  color: var(--p-text-muted-color);
  border-radius: 3px;
  flex-shrink: 0;
}
.icon-btn:hover { background: var(--p-surface-200); color: var(--p-text-color); }
.icon-btn.danger:hover { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent); color: var(--p-danger-500); }

.btn-row { display: flex; gap: 4px; flex-wrap: wrap; }

.mini-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px;
  font-size: 10px; font-weight: 600;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-color);
  border-radius: 3px;
  cursor: pointer;
  line-height: 1.3;
}
.mini-btn:hover { background: var(--p-surface-200); }
.mini-btn.primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
}
.mini-btn.primary:hover { opacity: 0.9; }
.mini-btn.primary:disabled { opacity: 0.5; cursor: not-allowed; }
.mini-btn.danger {
  background: transparent;
  color: var(--p-danger-500);
  border-color: color-mix(in srgb, var(--p-danger-500) 30%, transparent);
}
.mini-btn.danger:hover { background: color-mix(in srgb, var(--p-danger-500) 12%, transparent); }

.input {
  width: 100%;
  padding: 6px 10px;
  font-size: 11px;
  font-family: ui-monospace, monospace;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-color);
  border-radius: 4px;
  outline: none;
  margin-bottom: 6px;
}
.input:focus { border-color: var(--p-primary-color); }

.kv {
  display: flex; justify-content: space-between;
  padding: 2px 0;
  font-size: 11px;
}
.kv .k { color: var(--p-text-muted-color); }
.kv .v { color: var(--p-text-color); }
.kv .v.mono { font-family: ui-monospace, monospace; }

/* Snippet card */
.snippet-card { display: flex; flex-direction: column; gap: 10px; }
.snippet {
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  overflow: hidden;
}
.snippet-head {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 10px;
  background: var(--p-surface-50);
  border-bottom: 1px solid var(--p-content-border-color);
  font-size: 10px;
  font-weight: 600;
  color: var(--p-text-color);
}
.snippet-head code {
  font-size: 10px;
  color: var(--p-text-muted-color);
  font-weight: 400;
}
.snippet-head .mini-btn { margin-left: auto; }
.snippet-code {
  padding: 10px 12px;
  font-family: ui-monospace, monospace;
  font-size: 10px;
  line-height: 1.5;
  color: var(--p-text-color);
  white-space: pre-wrap;
  word-break: break-word;
  margin: 0;
  max-height: 260px;
  overflow-y: auto;
}

/* Token list */
.t-row {
  display: flex; align-items: center;
  padding: 6px 8px;
  border-top: 1px solid var(--p-content-border-color);
  font-size: 11px;
}
.t-row:first-of-type { border-top: 0; }
.t-row-main { display: flex; align-items: center; gap: 8px; width: 100%; }
.t-label { font-weight: 600; color: var(--p-text-color); flex-shrink: 0; }
.t-chip {
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 9px; font-weight: 600;
  padding: 1px 6px; border-radius: 3px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  flex-shrink: 0;
}
.t-chip.preset {
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  color: var(--p-primary-color);
  border-color: color-mix(in srgb, var(--p-primary-color) 30%, transparent);
}
.t-val {
  flex: 1; min-width: 0;
  font-family: ui-monospace, monospace;
  font-size: 9px;
  color: var(--p-text-muted-color);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.t-date {
  font-size: 9px;
  color: var(--p-text-muted-color);
  font-family: ui-monospace, monospace;
  flex-shrink: 0;
}
.t-row.revoked { opacity: 0.5; }
.line-through { text-decoration: line-through; }

.empty {
  display: flex; align-items: center; gap: 8px;
  padding: 16px;
  font-size: 11px;
  color: var(--p-text-muted-color);
  font-style: italic;
}

.revoked-group { margin-top: 8px; }
.revoked-group summary {
  font-size: 10px;
  color: var(--p-text-muted-color);
  cursor: pointer;
  padding: 4px 0;
}

/* Dialog */
.dialog-overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0,0,0,0.6);
  display: flex; align-items: center; justify-content: center;
}
.dialog-box {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  padding: 16px;
  width: 480px;
  max-width: 92vw;
  box-shadow: 0 12px 40px rgba(0,0,0,0.4);
}
.dlg-head {
  display: flex; align-items: center; gap: 6px;
  font-size: 13px; font-weight: 700;
  color: var(--p-text-color);
  margin-bottom: 10px;
}
.dlg-actions {
  display: flex; justify-content: flex-end; gap: 6px;
  margin-top: 12px;
}
.field-label {
  display: block;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--p-text-muted-color);
  margin: 8px 0 4px;
}
.chip-row { display: flex; flex-wrap: wrap; gap: 4px; }
.subject-box {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
}
.subject-box.missing {
  border-color: color-mix(in srgb, var(--p-danger-500) 35%, transparent);
}
.subject-title {
  font-size: 11px;
  font-weight: 700;
  color: var(--p-text-color);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.subject-sub {
  font-family: ui-monospace, monospace;
  font-size: 9px;
  color: var(--p-text-muted-color);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.scope-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 2px;
  max-height: 200px;
  overflow-y: auto;
  padding: 4px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
}
.scope-item {
  display: flex; align-items: flex-start; gap: 5px;
  padding: 4px 6px;
  border-radius: 3px;
  cursor: pointer;
}
.scope-item:hover { background: var(--p-surface-200); }
.scope-item input { margin-top: 2px; accent-color: var(--p-primary-color); flex-shrink: 0; }
.s-name { font-size: 10px; color: var(--p-text-color); font-weight: 500; }
.s-desc { font-size: 9px; color: var(--p-text-muted-color); }
</style>
