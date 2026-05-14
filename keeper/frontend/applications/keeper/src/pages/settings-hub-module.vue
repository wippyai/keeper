<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi } from '../composables/useWippy'
import {
  browseHubModules, listHubVersions, getHubReadme,
  listHubDependencies, installHubDependency, planHubInstall,
  type HubDependency, type HubModule, type HubVersion, type HubPlanRequirement, type HubInstallPlanResponse,
} from '../api/hub'
import PageHeader from '../components/shared/PageHeader.vue'
import RequirementValueInput from '../components/hub/RequirementValueInput.vue'

const route = useRoute()
const router = useRouter()
const api = useApi()

const HUB_URL = 'https://hub.wippy.ai/'

const orgName = computed(() => String(route.params.org || ''))
const modName = computed(() => String(route.params.name || ''))
const fullRef = computed(() => `${orgName.value}/${modName.value}`)

const tab = ref<'readme' | 'versions' | 'overview'>('readme')

const module_ = ref<HubModule | null>(null)
const versions = ref<HubVersion[]>([])
const readmeContent = ref('')
const readmeFilename = ref('')
const readmeVersion = ref('')
const installed = ref(false)
const installedDeps = ref<HubDependency[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const expandedVersion = ref<string | null>(null)

const installOpen = ref(false)
const installVersion = ref('')
const installRunMigrations = ref(true)
const installBusy = ref(false)
const installError = ref<string | null>(null)
const installPlan = ref<HubInstallPlanResponse | null>(null)
const installPlanLoading = ref(false)
const installPlanError = ref<string | null>(null)
const installRequirements = ref<HubPlanRequirement[]>([])
const installParameterValues = ref<Record<string, string>>({})
const installDependencyNamespace = ref('')
const installDependencyNamespaceTouched = ref(false)
const successMsg = ref<string | null>(null)

const latestVersion = computed<HubVersion | null>(() => {
  if (!versions.value.length) return null
  if (module_.value?.latest_version) {
    const m = versions.value.find(v => v.is_latest || v.version === module_.value!.latest_version)
    if (m) return m
  }
  return versions.value[0]
})

function moduleAccent(m: HubModule | null): string {
  if (!m) return 'hsl(220 70% 56%)'
  const s = m.full_name || m.name || m.id
  let hash = 0
  for (let i = 0; i < s.length; i++) hash = (hash * 31 + s.charCodeAt(i)) | 0
  const hues = [261, 200, 24, 142, 330, 174, 12, 220, 280, 50]
  return `hsl(${hues[Math.abs(hash) % hues.length]} 70% 56%)`
}

const TYPE_ICONS: Record<string, string> = {
  library: 'tabler:book-2',
  service: 'tabler:server',
  app: 'tabler:apps',
  page: 'tabler:browser',
  agent: 'tabler:robot',
}
function moduleIcon(m: HubModule | null): string {
  if (!m) return 'tabler:package'
  return TYPE_ICONS[(m.type || '').toLowerCase()] || 'tabler:package'
}

function fmtNum(n: number | undefined): string {
  if (!n) return '0'
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1_000) return (n / 1_000).toFixed(1) + 'k'
  return String(n)
}
function fmtBytes(n: number | undefined): string {
  if (!n) return ''
  if (n >= 1_048_576) return (n / 1_048_576).toFixed(1) + ' MB'
  if (n >= 1024) return (n / 1024).toFixed(1) + ' KB'
  return n + ' B'
}
function timeAgo(s: string | undefined): string {
  if (!s) return ''
  const ms = new Date(s).getTime()
  if (!Number.isFinite(ms)) return ''
  const sec = Math.floor((Date.now() - ms) / 1000)
  if (sec < 60) return 'just now'
  if (sec < 3600) return `${Math.floor(sec / 60)}m ago`
  if (sec < 86400) return `${Math.floor(sec / 3600)}h ago`
  if (sec < 30 * 86400) return `${Math.floor(sec / 86400)}d ago`
  if (sec < 365 * 86400) return `${Math.floor(sec / (30 * 86400))}mo ago`
  return `${Math.floor(sec / (365 * 86400))}y ago`
}
function flash(msg: string, ttl = 3000) {
  successMsg.value = msg
  setTimeout(() => { if (successMsg.value === msg) successMsg.value = null }, ttl)
}
function openLink(url?: string) {
  if (!url) return
  try { window.parent.open(url, '_blank', 'noopener') } catch { window.open(url, '_blank', 'noopener') }
}

// Lightweight syntax highlighter — handles comments, strings, numbers,
// keywords, types per common languages. Outputs HTML-escaped content with
// <span class="hl-*"> wrappers for theme-aware styling.
function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

interface Token { type: string; value: string }

const LANG_RULES: Record<string, Array<{ type: string; re: RegExp }>> = {
  lua: [
    { type: 'comment', re: /--\[\[[\s\S]*?\]\]|--[^\n]*/y },
    { type: 'string', re: /\[\[[\s\S]*?\]\]|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/y },
    { type: 'number', re: /\b0x[0-9a-fA-F]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/y },
    { type: 'keyword', re: /\b(?:and|break|do|else|elseif|end|false|for|function|goto|if|in|local|nil|not|or|repeat|return|then|true|until|while)\b/y },
    { type: 'builtin', re: /\b(?:require|print|pairs|ipairs|tostring|tonumber|type|setmetatable|getmetatable|rawget|rawset|select|error|pcall|xpcall|assert|next|string|table|math|io|os|coroutine)\b/y },
    { type: 'function', re: /\b[A-Za-z_]\w*(?=\s*\()/y },
    { type: 'punct', re: /[{}()\[\];,]/y },
    { type: 'op', re: /[=+\-*/%<>!~&|^]+/y },
    { type: 'ident', re: /\b[A-Za-z_]\w*\b/y },
  ],
  yaml: [
    { type: 'comment', re: /#[^\n]*/y },
    { type: 'string', re: /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/y },
    { type: 'key', re: /(?<=^|\n)\s*[A-Za-z_][\w.-]*(?=\s*:)/y },
    { type: 'punct', re: /[:|>{}\[\],-]/y },
    { type: 'number', re: /\b\d+(?:\.\d+)?\b/y },
    { type: 'literal', re: /\b(?:true|false|null|yes|no|on|off)\b/y },
    { type: 'value', re: /[^\s#:|>{}\[\],-]+/y },
  ],
  json: [
    { type: 'string', re: /"(?:\\.|[^"\\])*"/y },
    { type: 'number', re: /-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/y },
    { type: 'literal', re: /\b(?:true|false|null)\b/y },
    { type: 'punct', re: /[{}\[\],:]/y },
  ],
  bash: [
    { type: 'comment', re: /#[^\n]*/y },
    { type: 'string', re: /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/y },
    { type: 'keyword', re: /\b(?:if|then|else|elif|fi|case|esac|for|while|until|do|done|in|function|select|return|break|continue|exit)\b/y },
    { type: 'builtin', re: /\b(?:echo|cd|ls|rm|mv|cp|cat|grep|sed|awk|find|export|set|unset|source|read|test|true|false|exec|eval|trap|local)\b/y },
    { type: 'flag', re: /(?<=\s)-{1,2}[A-Za-z][A-Za-z0-9-]*\b/y },
    { type: 'var', re: /\$\{?[A-Za-z_][\w]*\}?/y },
    { type: 'number', re: /\b\d+\b/y },
    { type: 'punct', re: /[|&;()<>{}]/y },
  ],
  typescript: [
    { type: 'comment', re: /\/\*[\s\S]*?\*\/|\/\/[^\n]*/y },
    { type: 'string', re: /`(?:\\.|[^`\\])*`|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/y },
    { type: 'keyword', re: /\b(?:async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|if|import|in|instanceof|interface|let|new|null|of|return|super|switch|this|throw|true|false|try|type|typeof|undefined|var|void|while|with|yield)\b/y },
    { type: 'type', re: /\b(?:string|number|boolean|any|unknown|never|object|Record|Promise|Array|Map|Set|Date|RegExp|Error)\b/y },
    { type: 'function', re: /\b[A-Za-z_$][\w$]*(?=\s*\()/y },
    { type: 'number', re: /\b0x[0-9a-fA-F]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/y },
    { type: 'punct', re: /[{}()\[\];,.:]/y },
    { type: 'op', re: /[=+\-*/%<>!?~&|^]+/y },
    { type: 'ident', re: /\b[A-Za-z_$][\w$]*\b/y },
  ],
}
LANG_RULES.lua = LANG_RULES.lua
LANG_RULES.ts = LANG_RULES.typescript
LANG_RULES.js = LANG_RULES.typescript
LANG_RULES.javascript = LANG_RULES.typescript
LANG_RULES.sh = LANG_RULES.bash
LANG_RULES.shell = LANG_RULES.bash
LANG_RULES.zsh = LANG_RULES.bash
LANG_RULES.yml = LANG_RULES.yaml

function tokenize(code: string, lang: string): Token[] {
  const rules = LANG_RULES[lang]
  if (!rules) return [{ type: 'plain', value: code }]
  const tokens: Token[] = []
  let i = 0
  while (i < code.length) {
    const ch = code[i]
    if (ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r') {
      let j = i
      while (j < code.length && /[\s]/.test(code[j])) j++
      tokens.push({ type: 'ws', value: code.slice(i, j) })
      i = j
      continue
    }
    let matched = false
    for (const rule of rules) {
      rule.re.lastIndex = i
      const m = rule.re.exec(code)
      if (m && m.index === i && m[0].length > 0) {
        tokens.push({ type: rule.type, value: m[0] })
        i += m[0].length
        matched = true
        break
      }
    }
    if (!matched) {
      tokens.push({ type: 'plain', value: code[i] })
      i++
    }
  }
  return tokens
}

function highlightCode(code: string, lang: string): string {
  if (!lang || !LANG_RULES[lang]) return escapeHtml(code)
  const tokens = tokenize(code, lang)
  let out = ''
  for (const t of tokens) {
    const v = escapeHtml(t.value)
    if (t.type === 'ws' || t.type === 'plain') { out += v; continue }
    out += `<span class="hl-${t.type}">${v}</span>`
  }
  return out
}

function renderHubMarkdown(src: string): string {
  if (!src) return ''
  let html = src
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<iframe\b[^>]*>[\s\S]*?<\/iframe>/gi, '')
    .replace(/\son[a-z]+\s*=\s*"[^"]*"/gi, '')
    .replace(/\son[a-z]+\s*=\s*'[^']*'/gi, '')
    .replace(/javascript:/gi, '')
  const fences: string[] = []
  html = html.replace(/```([a-z0-9_-]*)\n([\s\S]*?)```/g, (_, lang, code) => {
    const highlighted = highlightCode(code, (lang || '').toLowerCase())
    fences.push(`<pre class="rm-pre lang-${(lang || 'text').toLowerCase()}"><code>${highlighted}</code></pre>`)
    return ` FENCE${fences.length - 1} `
  })
  html = html.replace(/`([^`\n]+)`/g, (_, code) => {
    const escaped = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return `<code class="rm-code">${escaped}</code>`
  })
  html = html.replace(/^######\s+(.+)$/gm, '<h6>$1</h6>')
  html = html.replace(/^#####\s+(.+)$/gm, '<h5>$1</h5>')
  html = html.replace(/^####\s+(.+)$/gm, '<h4>$1</h4>')
  html = html.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>')
  html = html.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>')
  html = html.replace(/^#\s+(.+)$/gm, '<h1>$1</h1>')
  html = html.replace(/^-{3,}$/gm, '<hr />')

  // Tables: header | sep | body rows
  html = html.replace(/^(\|.+\|)\n(\|[\s:|-]+\|)\n((?:\|.*\|\n?)+)/gm, (_, header, _sep, body) => {
    const cells = (row: string) => row.replace(/^\||\|$/g, '').split('|').map(c => c.trim())
    const headers = cells(header)
    const rows = body.trim().split('\n').map(cells)
    let out = '<table><thead><tr>'
    for (const h of headers) out += `<th>${h}</th>`
    out += '</tr></thead><tbody>'
    for (const r of rows) {
      out += '<tr>'
      for (const c of r) out += `<td>${c}</td>`
      out += '</tr>'
    }
    out += '</tbody></table>'
    return out
  })

  html = html.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/(^|\W)\*([^*\n]+)\*(?!\*)/g, '$1<em>$2</em>')
  html = html.replace(/!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g, '<img src="$2" alt="$1" loading="lazy" />')
  html = html.replace(/\[([^\]]+)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>')
  html = html.replace(/^(\s*)[-*]\s+(.+)$/gm, '$1<li class="rm-uli">$2</li>')
  html = html.replace(/^(\s*)\d+\.\s+(.+)$/gm, '$1<li class="rm-oli">$2</li>')
  html = html.replace(/((?:<li class="rm-uli">.*<\/li>\n?)+)/g, '<ul>$1</ul>')
  html = html.replace(/((?:<li class="rm-oli">.*<\/li>\n?)+)/g, '<ol>$1</ol>')
  html = html.replace(/ FENCE(\d+) /g, (_, i) => fences[Number(i)])
  const BLOCK_RE = /^\s*<\/?(?:[a-z][a-z0-9]*)\b/i
  const paras = html.split(/\n{2,}/)
  html = paras.map(p => {
    p = p.trim()
    if (!p) return ''
    if (BLOCK_RE.test(p)) return p
    return '<p>' + p.replace(/\n/g, '<br />') + '</p>'
  }).join('\n')
  return html
}

const renderedReadme = computed(() => renderHubMarkdown(readmeContent.value))

async function load() {
  loading.value = true
  error.value = null
  module_.value = null
  versions.value = []
  readmeContent.value = ''
  installed.value = false
  installedDeps.value = []

  // Resolve module via search (the hub list endpoint returns the same shape)
  try {
    const search = await browseHubModules(api, { query: modName.value, page_size: 50 })
    if (search?.success) {
      module_.value = (search.items || []).find(m =>
        m.full_name === fullRef.value || (m.org === orgName.value && m.name === modName.value),
      ) || null
    }
  } catch (e: any) {
    error.value = e.message || 'Failed to fetch module'
  }

  // Fetch versions, readme, installed deps in parallel
  const [vRes, rRes, dRes] = await Promise.allSettled([
    listHubVersions(api, fullRef.value, { page_size: 100 }),
    getHubReadme(api, fullRef.value),
    listHubDependencies(api),
  ])
  if (vRes.status === 'fulfilled' && vRes.value?.success) versions.value = vRes.value.items || []
  if (rRes.status === 'fulfilled' && rRes.value?.success) {
    readmeContent.value = rRes.value.content || ''
    readmeFilename.value = rRes.value.filename || ''
    readmeVersion.value = rRes.value.version || ''
  }
  if (dRes.status === 'fulfilled' && dRes.value?.success) {
    installedDeps.value = dRes.value.dependencies || []
    installed.value = installedDeps.value.some(d => d.component === fullRef.value)
  }

  // If we couldn't find the module via search, synthesize a minimal record
  if (!module_.value) {
    module_.value = {
      id: fullRef.value,
      name: modName.value,
      org: orgName.value,
      full_name: fullRef.value,
      latest_version: latestVersion.value?.version,
    } as HubModule
  }

  // Default tab: Readme if present, else Overview
  tab.value = readmeContent.value ? 'readme' : 'overview'
  loading.value = false
}

function openInstallDialog(version?: string) {
  installVersion.value = version || latestVersion.value?.version || module_.value?.latest_version || ''
  installError.value = null
  installPlan.value = null
  installPlanError.value = null
  installRequirements.value = []
  installParameterValues.value = {}
  installDependencyNamespace.value = ''
  installDependencyNamespaceTouched.value = false
  installRunMigrations.value = true
  installOpen.value = true
  void loadInstallPlan()
}

function requirementKey(req: { parameter_name?: string; full_id?: string; name?: string }): string {
  return (req.parameter_name || req.full_id || req.name || '').trim()
}

function setInstallParameter(req: HubPlanRequirement, value: string) {
  const key = requirementKey(req)
  if (!key) return
  installParameterValues.value[key] = value
}

function requirementPlaceholder(req: HubPlanRequirement): string {
  if (req.expected_kind) return `Enter ${req.expected_kind} id or contract value`
  return 'Enter registry id or contract value'
}

function installNamespacePayload(): string | undefined {
  if (!installDependencyNamespaceTouched.value) return undefined
  const namespace = installDependencyNamespace.value.trim()
  return namespace || undefined
}

function markInstallNamespaceTouched() {
  installDependencyNamespaceTouched.value = true
}

function plannedDependencyId(): string {
  return installPlan.value?.dependency?.id || ''
}

function applyInstallPlan(plan: HubInstallPlanResponse, previousValues: Record<string, string> = installParameterValues.value) {
  installPlan.value = plan
  installRequirements.value = plan.requirements || []
  const values: Record<string, string> = {}
  for (const req of installRequirements.value) {
    const key = requirementKey(req)
    if (!key) continue
    values[key] = previousValues[key] ?? req.value ?? ''
  }
  installParameterValues.value = values
}

async function loadInstallPlan() {
  if (!fullRef.value) return
  installPlanLoading.value = true
  installPlanError.value = null
  const previousValues = { ...installParameterValues.value }
  const parameters = Object.entries(previousValues)
    .filter(([, value]) => value.trim() !== '')
    .map(([name, value]) => ({ name, value }))
  try {
    const plan = await planHubInstall(api, {
      component: fullRef.value,
      version: installVersion.value.trim() || undefined,
      namespace: installNamespacePayload(),
      run_migrations: installRunMigrations.value,
      migration_policy: installRunMigrations.value ? 'up' : 'none',
      parameters: parameters.length ? parameters : undefined,
    })
    applyInstallPlan(plan, previousValues)
  } catch (e: any) {
    installPlan.value = null
    installRequirements.value = []
    installParameterValues.value = {}
    installPlanError.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    installPlanLoading.value = false
  }
}

function installParametersPayload(): Array<{ name: string; value: string }> | undefined {
  const out: Array<{ name: string; value: string }> = []
  for (const req of installRequirements.value) {
    const key = requirementKey(req)
    if (!key) continue
    const value = (installParameterValues.value[key] || '').trim()
    if (value && !req.invalid) out.push({ name: key, value })
  }
  return out.length ? out : undefined
}

function missingInstallRequirements(): string[] {
  const missing: string[] = []
  for (const req of installRequirements.value) {
    const key = requirementKey(req)
    if (!key || (!req.required && !req.missing)) continue
    if (req.invalid || !(installParameterValues.value[key] || '').trim()) missing.push(key)
  }
  return missing
}

async function submitInstall() {
  if (!module_.value) return
  const missing = missingInstallRequirements()
  if (missing.length) {
    installError.value = `Configure required parameter${missing.length === 1 ? '' : 's'}: ${missing.join(', ')}`
    return
  }
  installBusy.value = true
  installError.value = null
  try {
    const parameters = installParametersPayload()
    await installHubDependency(api, {
      component: fullRef.value,
      version: installVersion.value.trim() || undefined,
      namespace: installNamespacePayload(),
      run_migrations: installRunMigrations.value,
      migration_policy: installRunMigrations.value ? 'up' : 'none',
      parameters,
    })
    installOpen.value = false
    flash(`Installed ${fullRef.value}`)
    installed.value = true
  } catch (e: any) {
    const details = e.response?.data?.details
    if (details?.requirements && details?.install_payload) {
      applyInstallPlan(details)
    }
    installError.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    installBusy.value = false
  }
}

function toggleVersion(id: string) {
  expandedVersion.value = expandedVersion.value === id ? null : id
}

function back() {
  router.push('/settings/hub')
}

watch(() => fullRef.value, () => { load() })
onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="page-header-row">
      <button class="back-btn" @click="back">
        <Icon icon="tabler:arrow-left" class="w-3.5 h-3.5" />
        Back to hub
      </button>
      <span class="crumb-sep">/</span>
      <Icon icon="tabler:cloud" class="w-3.5 h-3.5 keeper-accent" />
      <span class="crumb">{{ module_?.display_name || modName || 'Module' }}</span>
      <span v-if="loading" class="text-[10px] flex items-center gap-1" style="color: var(--p-text-muted-color)">
        <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" /> loading
      </span>
      <span class="flex-1"></span>
      <button class="refresh-btn" @click="load" title="Refresh">
        <Icon icon="tabler:refresh" class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
      </button>
    </div>

    <div v-if="successMsg" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-success-500/10 text-success-500">
      <Icon icon="tabler:check" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ successMsg }}</span>
    </div>
    <div v-if="error" class="mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-danger-500/15 text-danger-500">
      <Icon icon="tabler:alert-circle" class="w-3.5 h-3.5 shrink-0" />
      <span class="flex-1">{{ error }}</span>
    </div>

    <div v-if="loading && !module_" class="flex-1 flex items-center justify-center">
      <Icon icon="tabler:loader-2" class="w-6 h-6 animate-spin keeper-accent" />
    </div>

    <div v-else-if="module_" class="flex-1 overflow-y-auto" :style="{ '--accent': moduleAccent(module_) }">
      <!-- Hero -->
      <header class="mod-hero">
        <div class="mod-hero-bg"></div>
        <div class="mod-hero-content">
          <div class="mod-hero-icon"><Icon :icon="moduleIcon(module_)" class="w-9 h-9" /></div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
              <h1 class="mod-hero-name">{{ module_.display_name || module_.name }}</h1>
              <span v-if="module_.latest_version" class="version-tag mono">{{ module_.latest_version }}</span>
              <span v-if="installed" class="installed-pill">installed</span>
              <span v-if="module_.deprecated" class="deprecated-pill">deprecated</span>
            </div>
            <div class="mod-hero-org mono">{{ module_.full_name || fullRef }}</div>
            <p v-if="module_.description" class="mod-hero-desc">{{ module_.description }}</p>
            <div v-if="module_.deprecated && module_.deprecation_message" class="mt-2 px-3 py-2 rounded text-[11px] flex items-center gap-2 bg-warn-500/10 text-warn-500">
              <Icon icon="tabler:alert-triangle" class="w-3.5 h-3.5 shrink-0" /> {{ module_.deprecation_message }}
            </div>
            <div class="mod-hero-actions">
              <button class="cta" @click="openInstallDialog()">
                <Icon icon="tabler:download" class="w-4 h-4" />
                {{ installed ? 'Reinstall / update' : 'Install' }}
                <span v-if="module_.latest_version" class="cta-version mono">{{ module_.latest_version }}</span>
              </button>
              <button v-if="module_.repository" class="ghost" @click="openLink(module_.repository)">
                <Icon icon="tabler:brand-github" class="w-3.5 h-3.5" /> Repository
              </button>
              <button v-if="module_.homepage" class="ghost" @click="openLink(module_.homepage)">
                <Icon icon="tabler:home" class="w-3.5 h-3.5" /> Homepage
              </button>
            </div>
          </div>
        </div>
      </header>

      <div class="mod-grid">
        <!-- Sidebar -->
        <aside class="mod-side">
          <section class="meta-block">
            <div class="meta-row">
              <Icon icon="tabler:download" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Downloads</span>
              <span class="meta-val mono">{{ (module_.total_downloads || 0).toLocaleString() }}</span>
            </div>
            <div v-if="module_.favorites_count !== undefined" class="meta-row">
              <Icon icon="tabler:star" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Favorites</span>
              <span class="meta-val">{{ module_.favorites_count }}</span>
            </div>
            <div v-if="module_.license" class="meta-row">
              <Icon icon="tabler:license" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">License</span>
              <span class="meta-val">{{ module_.license }}</span>
            </div>
            <div v-if="module_.type" class="meta-row">
              <Icon icon="tabler:category" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Type</span>
              <span class="meta-val">{{ module_.type }}</span>
            </div>
            <div v-if="module_.update_time" class="meta-row">
              <Icon icon="tabler:clock" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Updated</span>
              <span class="meta-val">{{ timeAgo(module_.update_time) }}</span>
            </div>
            <div v-if="module_.create_time" class="meta-row">
              <Icon icon="tabler:calendar" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Created</span>
              <span class="meta-val">{{ timeAgo(module_.create_time) }}</span>
            </div>
            <div v-if="latestVersion?.entry_count !== undefined" class="meta-row">
              <Icon icon="tabler:list-numbers" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Entries</span>
              <span class="meta-val">{{ latestVersion!.entry_count }}</span>
            </div>
            <div v-if="latestVersion?.size_bytes" class="meta-row">
              <Icon icon="tabler:weight" class="w-3.5 h-3.5 keeper-accent" />
              <span class="meta-key">Size</span>
              <span class="meta-val">{{ fmtBytes(latestVersion!.size_bytes) }}</span>
            </div>
          </section>

          <section v-if="(module_.keywords || []).length" class="meta-block">
            <div class="meta-block-title">Keywords</div>
            <div class="flex flex-wrap gap-1">
              <span v-for="k in module_.keywords" :key="k" class="keyword-chip">{{ k }}</span>
            </div>
          </section>

          <section v-if="(latestVersion?.entry_kinds || []).length" class="meta-block">
            <div class="meta-block-title">Entry kinds</div>
            <div class="flex flex-wrap gap-1">
              <span v-for="k in latestVersion!.entry_kinds" :key="k" class="kind-chip">{{ k }}</span>
            </div>
          </section>

          <section v-if="(latestVersion?.lua_modules || []).length" class="meta-block">
            <div class="meta-block-title">Lua modules</div>
            <div class="flex flex-wrap gap-1">
              <span v-for="m in latestVersion!.lua_modules" :key="m" class="kind-chip mono">{{ m }}</span>
            </div>
          </section>

          <section v-if="(latestVersion?.dependencies || []).length" class="meta-block">
            <div class="meta-block-title">Dependencies</div>
            <div v-for="(d, i) in latestVersion!.dependencies" :key="i" class="dep-line">
              <span class="mono">{{ d.org }}/{{ d.name }}</span>
              <span class="mono dim">{{ d.version_constraint }}</span>
            </div>
          </section>

          <section v-if="(latestVersion?.requirements || []).length" class="meta-block">
            <div class="meta-block-title">Requirements</div>
            <div v-for="(r, i) in latestVersion!.requirements" :key="i" class="req-line">
              <div class="mono" style="color: var(--p-text-color)">{{ r.name }}</div>
              <div v-if="r.description" class="dim" style="font-size: 10px; line-height: 1.4">{{ r.description }}</div>
              <div v-if="r.default" class="dim mono" style="font-size: 10px">default: {{ r.default }}</div>
            </div>
          </section>
        </aside>

        <!-- Main -->
        <main class="mod-main">
          <div class="content-tabs">
            <button class="content-tab" :class="{ active: tab === 'readme' }" @click="tab = 'readme'" :disabled="!readmeContent">Readme</button>
            <button class="content-tab" :class="{ active: tab === 'overview' }" @click="tab = 'overview'">Overview</button>
            <button class="content-tab" :class="{ active: tab === 'versions' }" @click="tab = 'versions'">Versions <span v-if="versions.length" class="opacity-70">{{ versions.length }}</span></button>
          </div>

          <div class="content-body">
            <template v-if="tab === 'readme'">
              <div v-if="!readmeContent" class="empty">
                <Icon icon="tabler:file-off" class="w-10 h-10 mx-auto opacity-30" />
                <p class="mt-2">No README provided.</p>
              </div>
              <div v-else>
                <div class="readme-head">
                  <Icon icon="tabler:file-text" class="w-3.5 h-3.5" />
                  <span class="font-mono">{{ readmeFilename || 'README.md' }}</span>
                  <span class="dim ml-1">version {{ readmeVersion || latestVersion?.version }}</span>
                </div>
                <article class="readme" v-html="renderedReadme"></article>
              </div>
            </template>

            <template v-else-if="tab === 'overview'">
              <div class="ov">
                <p class="ov-lede">{{ module_.description || 'No description provided.' }}</p>

                <!-- Stat tiles -->
                <div class="stat-grid">
                  <div class="stat-tile">
                    <div class="stat-label">Downloads</div>
                    <div class="stat-value">{{ (module_.total_downloads || 0).toLocaleString() }}</div>
                  </div>
                  <div class="stat-tile">
                    <div class="stat-label">Favorites</div>
                    <div class="stat-value">{{ module_.favorites_count || 0 }}</div>
                  </div>
                  <div v-if="latestVersion?.entry_count !== undefined" class="stat-tile">
                    <div class="stat-label">Entries</div>
                    <div class="stat-value">{{ latestVersion!.entry_count }}</div>
                  </div>
                  <div v-if="latestVersion?.size_bytes" class="stat-tile">
                    <div class="stat-label">Size</div>
                    <div class="stat-value">{{ fmtBytes(latestVersion!.size_bytes) }}</div>
                  </div>
                  <div class="stat-tile">
                    <div class="stat-label">Versions</div>
                    <div class="stat-value">{{ versions.length }}</div>
                  </div>
                  <div v-if="module_.update_time" class="stat-tile">
                    <div class="stat-label">Updated</div>
                    <div class="stat-value">{{ timeAgo(module_.update_time) }}</div>
                  </div>
                </div>

                <!-- Latest release card -->
                <section v-if="latestVersion" class="ov-section">
                  <div class="ov-section-head">
                    <h3 class="ov-section-title">Latest release</h3>
                    <div class="flex items-center gap-2">
                      <span class="version-chip mono">{{ latestVersion.version }}</span>
                      <span class="status-badge status-badge--success">latest</span>
                      <span v-if="latestVersion.yanked" class="status-badge status-badge--danger">yanked</span>
                      <span v-if="latestVersion.protected" class="status-badge status-badge--info">protected</span>
                      <span v-if="latestVersion.create_time" class="ov-meta-time">released {{ timeAgo(latestVersion.create_time) }}</span>
                    </div>
                  </div>
                  <div v-if="latestVersion.release_notes" class="release-notes">{{ latestVersion.release_notes }}</div>
                  <div v-else class="text-[11px] italic" style="color: var(--p-text-muted-color)">No release notes provided.</div>
                  <div v-if="latestVersion.published_by || latestVersion.digest" class="release-meta">
                    <span v-if="latestVersion.published_by" class="release-meta-line">
                      <Icon icon="tabler:user" class="w-3 h-3" /> Published by <span class="mono">{{ latestVersion.published_by }}</span>
                    </span>
                    <span v-if="latestVersion.digest" class="release-meta-line">
                      <Icon icon="tabler:hash" class="w-3 h-3" /> <span class="mono" :title="latestVersion.digest">{{ latestVersion.digest.slice(0, 16) }}…</span>
                    </span>
                  </div>
                </section>

                <!-- What's inside -->
                <section v-if="(latestVersion?.entry_kinds || []).length || (latestVersion?.lua_modules || []).length" class="ov-section">
                  <div class="ov-section-head">
                    <h3 class="ov-section-title">What's inside</h3>
                    <span class="ov-meta-time" v-if="latestVersion?.entry_count">{{ latestVersion.entry_count }} registry entries</span>
                  </div>
                  <div v-if="(latestVersion?.entry_kinds || []).length" class="contents-row">
                    <span class="contents-label">Kinds</span>
                    <div class="flex flex-wrap gap-1">
                      <span v-for="k in latestVersion!.entry_kinds" :key="k" class="kind-chip">{{ k }}</span>
                    </div>
                  </div>
                  <div v-if="(latestVersion?.lua_modules || []).length" class="contents-row">
                    <span class="contents-label">Lua modules</span>
                    <div class="flex flex-wrap gap-1">
                      <span v-for="m in latestVersion!.lua_modules" :key="m" class="kind-chip mono">{{ m }}</span>
                    </div>
                  </div>
                </section>

                <!-- Dependencies -->
                <section v-if="(latestVersion?.dependencies || []).length || (latestVersion?.requirements || []).length" class="ov-section">
                  <div class="ov-section-head">
                    <h3 class="ov-section-title">Dependencies</h3>
                  </div>
                  <div v-if="(latestVersion?.dependencies || []).length" class="dep-table">
                    <div v-for="(d, i) in latestVersion!.dependencies" :key="i" class="dep-row">
                      <Icon icon="tabler:package" class="w-3.5 h-3.5 dim" />
                      <span class="mono dep-name">{{ d.org }}/{{ d.name }}</span>
                      <span class="mono dep-constraint">{{ d.version_constraint }}</span>
                    </div>
                  </div>
                  <div v-if="(latestVersion?.requirements || []).length" class="ov-section-subhead">Requirements</div>
                  <div v-if="(latestVersion?.requirements || []).length" class="dep-table">
                    <div v-for="(r, i) in latestVersion!.requirements" :key="i" class="dep-row req-row">
                      <Icon icon="tabler:check-square" class="w-3.5 h-3.5 dim mt-0.5" />
                      <div class="flex-1 min-w-0">
                        <div class="mono dep-name">{{ r.name }}</div>
                        <div v-if="r.description" class="text-[11px] dim">{{ r.description }}</div>
                      </div>
                      <span v-if="r.default" class="mono dep-default" :title="'default: ' + r.default">{{ r.default }}</span>
                    </div>
                  </div>
                </section>

                <!-- Recent versions strip -->
                <section v-if="versions.length > 1" class="ov-section">
                  <div class="ov-section-head">
                    <h3 class="ov-section-title">Recent versions</h3>
                    <button class="link-btn" @click="tab = 'versions'">View all {{ versions.length }} →</button>
                  </div>
                  <div class="ver-strip">
                    <button
                      v-for="v in versions.slice(0, 6)" :key="v.id"
                      class="ver-pill"
                      :class="{ active: v.is_latest || v.version === module_.latest_version }"
                      @click="openInstallDialog(v.version)"
                    >
                      <span class="mono">{{ v.version }}</span>
                      <span v-if="v.is_latest || v.version === module_.latest_version" class="ver-pill-badge">latest</span>
                      <span v-if="v.create_time" class="ver-pill-time">{{ timeAgo(v.create_time) }}</span>
                    </button>
                  </div>
                </section>
              </div>
            </template>

            <template v-else-if="tab === 'versions'">
              <div v-if="versions.length === 0" class="empty">
                <Icon icon="tabler:tag-off" class="w-10 h-10 mx-auto opacity-30" />
                <p class="mt-2">No versions returned.</p>
              </div>
              <div v-else class="ver-list">
                <div v-for="v in versions" :key="v.id" class="ver-block" :class="{ expanded: expandedVersion === v.id }">
                  <div class="ver-row" @click="toggleVersion(v.id)">
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2">
                        <span class="mono text-[13px] font-semibold">{{ v.version }}</span>
                        <span v-if="v.is_latest || v.version === module_.latest_version" class="latest-badge">latest</span>
                        <span v-if="v.yanked" class="yanked-badge">yanked</span>
                        <span v-if="v.protected" class="protected-badge">protected</span>
                      </div>
                      <div class="dim text-[10px] mt-0.5">
                        <span v-if="v.create_time">{{ timeAgo(v.create_time) }}</span>
                        <span v-if="v.download_count !== undefined" class="ml-2">· {{ fmtNum(v.download_count) }} downloads</span>
                        <span v-if="v.entry_count !== undefined" class="ml-2">· {{ v.entry_count }} entries</span>
                        <span v-if="v.size_bytes" class="ml-2">· {{ fmtBytes(v.size_bytes) }}</span>
                      </div>
                    </div>
                    <button class="ghost-sm" @click.stop="openInstallDialog(v.version)">
                      <Icon icon="tabler:download" class="w-3 h-3" /> Install
                    </button>
                    <Icon :icon="expandedVersion === v.id ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3.5 h-3.5 dim" />
                  </div>
                  <div v-if="expandedVersion === v.id" class="ver-body">
                    <div v-if="v.release_notes" class="ver-section">
                      <div class="ver-section-title">Release notes</div>
                      <pre class="release-notes">{{ v.release_notes }}</pre>
                    </div>
                    <div v-if="(v.entry_kinds || []).length" class="ver-section">
                      <div class="ver-section-title">Entry kinds <span class="dim">{{ v.entry_kinds!.length }}</span></div>
                      <div class="flex flex-wrap gap-1">
                        <span v-for="k in v.entry_kinds" :key="k" class="kind-chip">{{ k }}</span>
                      </div>
                    </div>
                    <div v-if="(v.lua_modules || []).length" class="ver-section">
                      <div class="ver-section-title">Lua modules <span class="dim">{{ v.lua_modules!.length }}</span></div>
                      <div class="flex flex-wrap gap-1">
                        <span v-for="m in v.lua_modules" :key="m" class="kind-chip mono">{{ m }}</span>
                      </div>
                    </div>
                    <div v-if="(v.dependencies || []).length" class="ver-section">
                      <div class="ver-section-title">Dependencies</div>
                      <div v-for="(d, i) in v.dependencies" :key="i" class="dep-line">
                        <span class="mono">{{ d.org }}/{{ d.name }}</span>
                        <span class="mono dim">{{ d.version_constraint }}</span>
                      </div>
                    </div>
                    <div v-if="v.published_by || v.digest" class="ver-section">
                      <div v-if="v.published_by" class="kv-line"><span class="kv-key">Published by</span><span class="mono text-[10px]">{{ v.published_by }}</span></div>
                      <div v-if="v.digest" class="kv-line"><span class="kv-key">Digest</span><span class="mono text-[10px]" :title="v.digest">{{ v.digest.slice(0, 24) }}…</span></div>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </main>
      </div>
    </div>

    <!-- Install dialog -->
    <Teleport to="body">
      <div v-if="installOpen" class="overlay" @click.self="installOpen = false">
        <div class="dialog">
          <div class="flex items-center gap-2 mb-3">
            <Icon icon="tabler:download" class="w-5 h-5 text-info-500" />
            <span class="text-sm font-semibold" style="color: var(--p-text-color)">Install {{ fullRef }}</span>
          </div>
          <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
            Installs this component from the hub and applies its registry entries.
          </p>
          <label class="form-label">Version</label>
          <input v-model="installVersion" placeholder="latest" class="form-input mono" @change="loadInstallPlan" />
          <label class="form-label mt-3">Dependency namespace</label>
          <input
            v-model="installDependencyNamespace"
            placeholder="auto"
            class="form-input mono"
            @input="markInstallNamespaceTouched"
            @change="loadInstallPlan"
          />
          <div class="field-hint">
            Auto target uses an existing dependency entry or the strongest dependency namespace cluster.
            <span v-if="plannedDependencyId()" class="mono">{{ plannedDependencyId() }}</span>
          </div>
          <div class="mt-2 flex items-center justify-between gap-2 text-[10px]" style="color: var(--p-text-muted-color)">
            <span v-if="installPlanLoading">Resolving install plan...</span>
            <span v-else-if="installPlan">{{ installPlan.module_count }} module{{ installPlan.module_count === 1 ? '' : 's' }} · {{ installPlan.requirement_count }} setting{{ installPlan.requirement_count === 1 ? '' : 's' }}</span>
            <span v-else>Plan resolves transitive requirements before install.</span>
            <button class="ghost-sm" type="button" @click="loadInstallPlan" :disabled="installPlanLoading">Refresh</button>
          </div>
          <div v-if="installPlan?.graph?.length" class="mt-2 mb-2 max-h-24 overflow-auto rounded border p-2" style="border-color: var(--p-content-border-color)">
            <div v-for="node in installPlan.graph" :key="`${node.module}@${node.version}`" class="flex items-center justify-between gap-2 text-[10px]">
              <span class="mono truncate" style="color: var(--p-text-color)">{{ node.module }}</span>
              <span style="color: var(--p-text-muted-color)">{{ node.direct ? 'root' : 'transitive' }} · {{ node.version || node.constraint }}</span>
            </div>
          </div>
          <div v-if="installRequirements.length" class="mt-3 mb-3">
            <div class="form-label flex items-center gap-1.5">
              <Icon icon="tabler:list-check" class="w-3.5 h-3.5" />
              Configuration <span class="dim">({{ installRequirements.length }})</span>
            </div>
            <div class="space-y-2">
              <label v-for="(req, idx) in installRequirements" :key="req.parameter_name || req.name" class="block">
                <div class="flex items-center gap-2 mb-1">
                  <span class="mono text-[11px]" style="color: var(--p-text-color)">{{ req.parameter_name || req.name }}</span>
                  <span v-if="req.transitive" class="text-[9px]" style="color: var(--p-text-muted-color)">transitive</span>
                  <span v-if="req.required" class="text-[9px]" style="color: var(--p-warn-500)">required</span>
                  <span v-if="req.invalid" class="text-[9px]" style="color: var(--p-danger-500)">invalid</span>
                  <span v-if="req.value_source && req.value_source !== 'empty'" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.value_source }}</span>
                  <span v-if="req.expected_kind" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.expected_kind }}</span>
                  <span v-if="req.targets?.length" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.targets.length }} target{{ req.targets.length === 1 ? '' : 's' }}</span>
                </div>
                <RequirementValueInput
                  :model-value="installParameterValues[requirementKey(req)] || ''"
                  :requirement="req"
                  :placeholder="requirementPlaceholder(req)"
                  @update:model-value="setInstallParameter(req, $event)"
                  @commit="loadInstallPlan"
                />
                <div v-if="req.default && req.value_source !== 'default'" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">Package default: <span class="mono">{{ req.default }}</span></div>
                <div v-if="req.invalid_reason" class="mt-1 text-[10px]" style="color: var(--p-danger-500)">{{ req.invalid_reason }}</div>
                <div v-if="req.module" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.module }}{{ req.version ? '@' + req.version : '' }}</div>
                <div v-if="req.description" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.description }}</div>
              </label>
            </div>
          </div>
          <div v-else-if="installPlan && !installPlanLoading" class="mt-3 mb-3 text-[11px]" style="color: var(--p-text-muted-color)">
            No configuration required.
          </div>
          <label class="form-check">
            <input v-model="installRunMigrations" type="checkbox" />
            Run migrations after install
          </label>
          <div v-if="installPlanError" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ installPlanError }}</div>
          <div v-if="installError" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ installError }}</div>
          <div class="flex justify-end gap-2 mt-4">
            <button class="dialog-btn cancel" @click="installOpen = false" :disabled="installBusy">Cancel</button>
            <button class="dialog-btn proceed" @click="submitInstall" :disabled="installBusy || installPlanLoading || missingInstallRequirements().length > 0">
              <Icon v-if="installBusy" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
              Install
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.mono { font-family: 'JetBrains Mono', monospace; }
.dim { color: var(--p-text-muted-color); }

.page-header-row {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 16px;
  border-bottom: 1px solid var(--p-content-border-color);
  flex-shrink: 0;
}
.back-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 3px 8px;
  font-size: 11px;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 0;
  cursor: pointer;
  border-radius: 4px;
}
.back-btn:hover { background: var(--p-surface-100); color: var(--p-text-color); }
.crumb-sep {
  color: var(--p-text-muted-color);
  opacity: 0.5;
  font-size: 12px;
}
.crumb {
  font-size: 12px;
  font-weight: 500;
  color: var(--p-text-color);
}
.refresh-btn {
  width: 26px; height: 26px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 0; cursor: pointer;
}
.refresh-btn:hover { background: var(--p-surface-100); }

/* Hero */
.mod-hero {
  position: relative;
  overflow: hidden;
  border-bottom: 1px solid var(--p-content-border-color);
}
.mod-hero-bg {
  position: absolute; inset: 0;
  background:
    radial-gradient(circle at 18% 30%, color-mix(in srgb, var(--accent) 7%, transparent), transparent 60%),
    var(--p-surface-50);
}
.mod-hero-content {
  position: relative;
  display: flex; align-items: flex-start; gap: 22px;
  padding: 28px 28px 24px;
  max-width: 1100px;
  margin: 0 auto;
}
.mod-hero-icon {
  flex-shrink: 0;
  width: 64px; height: 64px;
  border-radius: 14px;
  display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--accent) 12%, transparent);
  color: var(--accent);
}
.mod-hero-name {
  font-size: 22px; font-weight: 700;
  color: var(--p-text-color);
  margin: 0;
  line-height: 1.2;
}
.mod-hero-org {
  font-size: 12px;
  color: var(--p-text-muted-color);
  margin-top: 4px;
}
.mod-hero-desc {
  font-size: 13px; line-height: 1.55;
  color: var(--p-text-color);
  margin: 10px 0 0;
  max-width: 720px;
}
.mod-hero-actions {
  display: flex; gap: 8px; margin-top: 16px;
  flex-wrap: wrap;
}
.cta {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 7px 14px;
  border-radius: 8px;
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  font-size: 12px; font-weight: 600;
  border: 0; cursor: pointer;
}
.cta:hover { opacity: 0.92; }
.cta-version {
  font-size: 11px;
  background: color-mix(in srgb, var(--p-primary-contrast-color) 18%, transparent);
  padding: 1px 8px;
  border-radius: 6px;
}
.ghost {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 14px;
  border-radius: 10px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  font-size: 12px; font-weight: 500;
  cursor: pointer;
}
.ghost:hover { background: var(--p-surface-200); }

/* ---------- Badges (consistent with rest of keeper) ---------- */
.version-tag, .version-chip {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  font-weight: 500;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  padding: 1px 7px;
  border-radius: 4px;
}
.status-badge {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  display: inline-flex; align-items: center;
}
.status-badge--success { background: color-mix(in srgb, var(--p-success-500) 15%, transparent); color: var(--p-success-500); }
.status-badge--warn    { background: color-mix(in srgb, var(--p-warn-500) 18%, transparent);    color: var(--p-warn-500); }
.status-badge--danger  { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent);  color: var(--p-danger-500); }
.status-badge--info    { background: color-mix(in srgb, var(--p-info-500) 15%, transparent);    color: var(--p-info-500); }

/* Aliases mapped to the standardized status-badge */
.installed-pill {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-success-500) 15%, transparent);
  color: var(--p-success-500);
}
.deprecated-pill {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-warn-500) 18%, transparent);
  color: var(--p-warn-500);
}

/* Grid */
.mod-grid {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 20px;
  padding: 20px 28px 32px;
  max-width: 1100px;
  margin: 0 auto;
}
@media (max-width: 900px) {
  .mod-grid { grid-template-columns: 1fr; }
}

/* Sidebar */
.mod-side {
  display: flex; flex-direction: column; gap: 14px;
}
.meta-block {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 10px;
  padding: 14px 16px;
}
.meta-row {
  display: grid;
  grid-template-columns: 18px 90px 1fr;
  align-items: center;
  gap: 8px;
  padding: 5px 0;
  font-size: 11px;
}
.meta-key {
  color: var(--p-text-muted-color);
}
.meta-val {
  color: var(--p-text-color);
  text-align: right;
  word-break: break-word;
}
.meta-block-title {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 700;
  color: var(--p-text-muted-color);
  margin-bottom: 8px;
}
.keyword-chip {
  display: inline-block;
  padding: 2px 8px;
  font-size: 10px;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  border-radius: 8px;
}
.kind-chip {
  display: inline-block;
  padding: 2px 7px;
  font-size: 10px;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  border-radius: 4px;
}
.kind-chip.mono { font-family: 'JetBrains Mono', monospace; }
.dep-line {
  display: flex; justify-content: space-between; gap: 10px;
  padding: 4px 0;
  font-size: 11px;
  border-top: 1px dashed var(--p-content-border-color);
}
.dep-line:first-child { border-top: 0; }
.req-line {
  padding: 6px 0;
  border-top: 1px dashed var(--p-content-border-color);
}
.req-line:first-child { border-top: 0; }

/* Main */
.mod-main {
  display: flex; flex-direction: column;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 12px;
  overflow: hidden;
  min-width: 0;
}
.content-tabs {
  display: flex; align-items: center; gap: 4px;
  padding: 0 18px;
  border-bottom: 1px solid var(--p-content-border-color);
  background: var(--p-surface-100);
}
.content-tab {
  padding: 12px 16px;
  background: transparent;
  border: 0; border-bottom: 2px solid transparent;
  color: var(--p-text-muted-color);
  font-size: 12px; font-weight: 600;
  cursor: pointer;
}
.content-tab:hover:not(:disabled) { color: var(--p-text-color); }
.content-tab.active {
  color: var(--p-primary-color);
  border-bottom-color: var(--p-primary-color);
}
.content-tab:disabled { opacity: 0.4; cursor: not-allowed; }
.content-body {
  padding: 24px 28px;
}
.empty {
  text-align: center;
  padding: 60px 20px;
  color: var(--p-text-muted-color);
  font-size: 12px;
}

.readme-head {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 5px 10px;
  border-radius: 6px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  font-size: 11px;
  margin-bottom: 18px;
  color: var(--p-text-muted-color);
}

.readme {
  font-size: 13px; line-height: 1.65;
  color: var(--p-text-color);
  word-break: break-word;
}
.readme :deep(h1),
.readme :deep(h2),
.readme :deep(h3),
.readme :deep(h4),
.readme :deep(h5),
.readme :deep(h6) {
  font-weight: 700;
  color: var(--p-text-color);
  line-height: 1.3;
  margin: 22px 0 10px;
}
.readme :deep(h1:first-child),
.readme :deep(h2:first-child) { margin-top: 0; }
.readme :deep(h1) { font-size: 22px; border-bottom: 1px solid var(--p-content-border-color); padding-bottom: 8px; }
.readme :deep(h2) { font-size: 17px; border-bottom: 1px solid var(--p-content-border-color); padding-bottom: 6px; }
.readme :deep(h3) { font-size: 14px; }
.readme :deep(h4) { font-size: 13px; color: var(--p-text-muted-color); }
.readme :deep(p) { margin: 0 0 12px; }
.readme :deep(a) { color: var(--p-info-500); text-decoration: none; }
.readme :deep(a:hover) { text-decoration: underline; }
.readme :deep(img) { max-width: 100%; border-radius: 6px; margin: 6px 0; height: auto; }
.readme :deep(.rm-pre),
.readme :deep(pre) {
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  padding: 14px 18px;
  overflow-x: auto;
  margin: 14px 0;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  line-height: 1.6;
}
.readme :deep(.rm-code),
.readme :deep(code) {
  background: var(--p-surface-100);
  padding: 1px 6px;
  border-radius: 4px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
}
.readme :deep(pre code) { background: none; padding: 0; }

/* Syntax highlight tokens — theme-aware via PrimeVue color vars */
.readme :deep(.hl-comment) { color: var(--p-text-muted-color); font-style: italic; }
.readme :deep(.hl-string) { color: color-mix(in srgb, var(--p-success-500) 75%, var(--p-text-color) 25%); }
.readme :deep(.hl-number) { color: color-mix(in srgb, var(--p-warn-500) 70%, var(--p-text-color) 30%); }
.readme :deep(.hl-keyword) { color: var(--p-primary-color); font-weight: 600; }
.readme :deep(.hl-builtin) { color: color-mix(in srgb, var(--p-info-500) 70%, var(--p-text-color) 30%); }
.readme :deep(.hl-type) { color: color-mix(in srgb, var(--p-info-500) 70%, var(--p-text-color) 30%); }
.readme :deep(.hl-function) { color: color-mix(in srgb, var(--p-accent-500, var(--p-primary-color)) 75%, var(--p-text-color) 25%); }
.readme :deep(.hl-literal) { color: var(--p-primary-color); font-weight: 600; }
.readme :deep(.hl-op) { color: var(--p-text-color); }
.readme :deep(.hl-punct) { color: var(--p-text-muted-color); }
.readme :deep(.hl-key) { color: color-mix(in srgb, var(--p-info-500) 70%, var(--p-text-color) 30%); font-weight: 600; }
.readme :deep(.hl-value) { color: var(--p-text-color); }
.readme :deep(.hl-flag) { color: color-mix(in srgb, var(--p-warn-500) 70%, var(--p-text-color) 30%); }
.readme :deep(.hl-var) { color: color-mix(in srgb, var(--p-info-500) 70%, var(--p-text-color) 30%); }
.readme :deep(.hl-ident) { color: var(--p-text-color); }
.readme :deep(ul),
.readme :deep(ol) { margin: 8px 0 14px; padding-left: 24px; }
.readme :deep(li) { margin: 4px 0; }
.readme :deep(li.rm-uli) { list-style: disc; }
.readme :deep(li.rm-oli) { list-style: decimal; }
.readme :deep(hr) { border: 0; border-top: 1px solid var(--p-content-border-color); margin: 22px 0; }
.readme :deep(blockquote) {
  border-left: 3px solid var(--p-info-500);
  padding: 6px 14px;
  margin: 12px 0;
  background: color-mix(in srgb, var(--p-info-500) 6%, transparent);
  color: var(--p-text-muted-color);
}
.readme :deep(table) { border-collapse: collapse; width: 100%; margin: 12px 0; font-size: 12px; }
.readme :deep(th), .readme :deep(td) {
  text-align: left; padding: 8px 12px; border: 1px solid var(--p-content-border-color);
}
.readme :deep(th) { background: var(--p-surface-100); font-weight: 600; }
.readme :deep(picture),
.readme :deep(picture img) { display: inline-block; max-width: 100%; }

/* Overview */
.ov { display: flex; flex-direction: column; gap: 22px; }
.ov-lede {
  font-size: 14px; line-height: 1.6;
  color: var(--p-text-color);
  margin: 0;
}
.stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 8px;
}
.stat-tile {
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 10px 12px;
}
.stat-label {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 700;
  color: var(--p-text-muted-color);
}
.stat-value {
  font-size: 16px; font-weight: 700;
  color: var(--p-text-color);
  margin-top: 4px;
  font-variant-numeric: tabular-nums;
}

.ov-section {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  padding: 14px 16px;
}
.ov-section-head {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}
.ov-section-title {
  font-size: 13px; font-weight: 700;
  color: var(--p-text-color);
  margin: 0;
}
.ov-section-subhead {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 700;
  color: var(--p-text-muted-color);
  margin: 12px 0 6px;
}
.ov-meta-time {
  font-size: 11px;
  color: var(--p-text-muted-color);
  margin-left: auto;
}
.link-btn {
  font-size: 11px;
  color: var(--p-primary-color);
  background: transparent; border: 0;
  cursor: pointer;
  margin-left: auto;
}
.link-btn:hover { text-decoration: underline; }

.release-notes {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 12px 14px;
  white-space: pre-wrap;
  word-break: break-word;
  max-height: 320px; overflow-y: auto;
  color: var(--p-text-color);
}
.release-meta {
  display: flex; flex-wrap: wrap; gap: 14px;
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px dashed var(--p-content-border-color);
  font-size: 11px;
  color: var(--p-text-muted-color);
}
.release-meta-line {
  display: inline-flex; align-items: center; gap: 4px;
}

.contents-row {
  display: grid;
  grid-template-columns: 100px 1fr;
  gap: 10px;
  align-items: flex-start;
  padding: 6px 0;
}
.contents-label {
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600;
  color: var(--p-text-muted-color);
}

.dep-table {
  display: flex; flex-direction: column;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  overflow: hidden;
}
.dep-row {
  display: flex; align-items: center; gap: 10px;
  padding: 7px 12px;
  font-size: 11px;
  border-top: 1px solid var(--p-content-border-color);
}
.dep-row:first-child { border-top: 0; }
.dep-row.req-row { align-items: flex-start; }
.dep-name {
  font-size: 11px;
  color: var(--p-text-color);
  flex: 1;
}
.dep-constraint, .dep-default {
  font-size: 10px;
  color: var(--p-text-muted-color);
  background: var(--p-surface-200);
  padding: 1px 7px;
  border-radius: 4px;
}

.ver-strip {
  display: flex; gap: 8px;
  flex-wrap: wrap;
}
.ver-pill {
  display: inline-flex; flex-direction: column; align-items: flex-start; gap: 2px;
  padding: 8px 12px;
  border-radius: 6px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  text-align: left;
  min-width: 100px;
}
.ver-pill:hover { background: var(--p-surface-200); border-color: var(--p-primary-color); }
.ver-pill.active {
  border-color: var(--p-primary-color);
  background: color-mix(in srgb, var(--p-primary-color) 8%, transparent);
}
.ver-pill .mono { font-size: 12px; font-weight: 600; color: var(--p-text-color); }
.ver-pill-badge {
  font-size: 8px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 5px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-success-500) 15%, transparent);
  color: var(--p-success-500);
}
.ver-pill-time {
  font-size: 9px;
  color: var(--p-text-muted-color);
}

/* Versions */
.ver-list { display: flex; flex-direction: column; }
.ver-block {
  border-top: 1px solid var(--p-content-border-color);
}
.ver-block:first-child { border-top: 0; }
.ver-row {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 0;
  cursor: pointer;
}
.ver-block.expanded { background: color-mix(in srgb, var(--p-surface-100) 60%, transparent); }
.ver-body {
  padding: 4px 4px 16px;
  display: flex; flex-direction: column; gap: 14px;
}
.ver-section { display: flex; flex-direction: column; gap: 6px; }
.ver-section-title {
  font-size: 9px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 700;
  color: var(--p-text-muted-color);
}
.kv-line { display: flex; gap: 10px; align-items: baseline; font-size: 11px; }
.kv-key { color: var(--p-text-muted-color); min-width: 90px; }

.latest-badge {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-success-500) 15%, transparent);
  color: var(--p-success-500);
}
.yanked-badge {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-danger-500) 15%, transparent);
  color: var(--p-danger-500);
}
.protected-badge {
  font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 6px; border-radius: 3px;
  background: color-mix(in srgb, var(--p-info-500) 15%, transparent);
  color: var(--p-info-500);
}

.ghost-sm {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  cursor: pointer;
}
.ghost-sm:hover { background: var(--p-surface-200); }

/* Dialog */
.overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0, 0, 0, 0.6);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
  overflow: auto;
}
.dialog {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 10px;
  padding: 18px;
  width: 420px; max-width: 90vw;
  max-height: calc(100dvh - 32px);
  overflow-y: auto;
  overscroll-behavior: contain;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}
.form-label {
  display: block;
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600;
  color: var(--p-text-muted-color);
  margin-bottom: 4px;
}
.form-input {
  width: 100%;
  padding: 6px 10px; font-size: 12px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px; outline: none;
}
.field-hint {
  margin-top: 5px;
  font-size: 10px;
  line-height: 1.35;
  color: var(--p-text-muted-color);
}
.form-check {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px;
  color: var(--p-text-color);
  margin-top: 12px;
  cursor: pointer;
}
.dialog-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 5px 14px;
  font-size: 11px;
  border-radius: 4px;
  cursor: pointer; border: 1px solid transparent;
}
.dialog-btn.cancel {
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border-color: var(--p-content-border-color);
}
.dialog-btn.cancel:hover { background: var(--p-surface-200); }
.dialog-btn.proceed {
  background: var(--p-info-500);
  color: white; font-weight: 600;
}
.dialog-btn.proceed:hover:not(:disabled) { opacity: 0.9; }
.dialog-btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
