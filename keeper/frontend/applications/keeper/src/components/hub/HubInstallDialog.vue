<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../../composables/useWippy'
import {
  planHubInstall, installHubDependency, listHubDependencies, scanHubInstall,
  type HubInstallPlanResponse, type HubPlanRequirement, type InstallPlanNode,
  type HubScanFinding, type HubScanModuleResult, type HubScanResponse, type HubScanStatus,
  type InstallPayload,
} from '../../api/hub'
import RequirementValueInput from './RequirementValueInput.vue'

const props = defineProps<{
  modelValue: boolean
  component: string
  initialVersion?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [boolean]
  installed: [component: string]
}>()

const api = useApi()

const version = ref('')
const dependencyNamespace = ref('')
const dependencyNamespaceTouched = ref(false)
const runMigrations = ref(true)

const busy = ref(false)
const error = ref<string | null>(null)
const scanLoading = ref(false)
const scanError = ref<string | null>(null)
const scanResult = ref<HubScanResponse | null>(null)
const scanSkipped = ref(false)
let scanRevision = 0

const plan = ref<HubInstallPlanResponse | null>(null)
const planLoading = ref(false)
const planError = ref<string | null>(null)
const requirements = ref<HubPlanRequirement[]>([])
const parameterValues = ref<Record<string, string>>({})

// module name -> currently installed version, used to distinguish UPGRADE from
// a plain already-installed node in the plan tree.
const installedVersions = ref<Record<string, string>>({})

// ---------- lifecycle ----------

watch(() => props.modelValue, open => {
  if (open) reset()
})

function reset() {
  version.value = props.initialVersion || ''
  dependencyNamespace.value = ''
  dependencyNamespaceTouched.value = false
  runMigrations.value = true
  busy.value = false
  error.value = null
  resetScanDecision()
  plan.value = null
  planError.value = null
  requirements.value = []
  parameterValues.value = {}
  void loadInstalledVersions()
  void loadPlan()
}

function close() {
  emit('update:modelValue', false)
}

// ---------- requirements ----------

function requirementKey(req: { parameter_name?: string; full_id?: string; name?: string }): string {
  return (req.parameter_name || req.full_id || req.name || '').trim()
}

// Parameters attach to the module being installed, so only the root module's
// requirements are editable and submitted. The root set comes from the plan
// graph (depth 0); requirement rows carry the owning module + transitive flag
// as a fallback when the graph is absent.
const rootModules = computed<Set<string>>(() => {
  const set = new Set<string>()
  for (const n of plan.value?.graph || []) {
    if ((n.depth ?? 0) === 0) set.add(n.module)
  }
  return set
})

function isRootRequirement(req: HubPlanRequirement): boolean {
  if (req.module && rootModules.value.size) return rootModules.value.has(req.module)
  if (req.transitive !== undefined) return !req.transitive
  return (req.depth ?? 0) === 0
}

const rootRequirements = computed(() => requirements.value.filter(isRootRequirement))
const transitiveRequirements = computed(() => requirements.value.filter(req => !isRootRequirement(req)))

// A transitive requirement the plan could not satisfy from existing values or
// defaults blocks the install: this dialog cannot supply it (the backend
// refuses parameters addressed to transitive modules), so the module must be
// installed as an explicit root with the parameter.
function isTransitiveBlocker(req: HubPlanRequirement): boolean {
  if (req.missing) return true
  if (req.invalid) return true
  return !!req.required && !(req.value || '').trim()
}

const transitiveBlockers = computed(() => transitiveRequirements.value.filter(isTransitiveBlocker))

function transitiveValue(req: HubPlanRequirement): string {
  return (req.value || '').trim() || (req.default || '').trim()
}

function setParameter(req: HubPlanRequirement, value: string) {
  const key = requirementKey(req)
  if (!key) return
  if (parameterValues.value[key] !== value) resetScanDecision()
  parameterValues.value[key] = value
}

function requirementPlaceholder(req: HubPlanRequirement): string {
  if (req.expected_kind) return `Enter ${req.expected_kind} id or contract value`
  return 'Enter registry id or contract value'
}

function namespacePayload(): string | undefined {
  if (!dependencyNamespaceTouched.value) return undefined
  const ns = dependencyNamespace.value.trim()
  return ns || undefined
}

function markNamespaceTouched() {
  dependencyNamespaceTouched.value = true
  resetScanDecision()
}

const plannedDependencyId = computed(() => plan.value?.dependency?.id || '')

function applyPlan(next: HubInstallPlanResponse, previousValues: Record<string, string> = parameterValues.value) {
  plan.value = next
  requirements.value = next.requirements || []
  const values: Record<string, string> = {}
  for (const req of rootRequirements.value) {
    const key = requirementKey(req)
    if (!key) continue
    values[key] = previousValues[key] ?? req.value ?? ''
  }
  parameterValues.value = values
}

async function loadPlan() {
  if (!props.component.trim()) return
  resetScanDecision()
  planLoading.value = true
  planError.value = null
  const previousValues = { ...parameterValues.value }
  const existing = Object.entries(previousValues)
    .filter(([, value]) => value.trim() !== '')
    .map(([name, value]) => ({ name, value }))
  try {
    const next = await planHubInstall(api, {
      component: props.component.trim(),
      version: version.value.trim() || undefined,
      namespace: namespacePayload(),
      run_migrations: runMigrations.value,
      migration_policy: runMigrations.value ? 'up' : 'none',
      parameters: existing.length ? existing : undefined,
    })
    applyPlan(next, previousValues)
  } catch (e: any) {
    plan.value = null
    requirements.value = []
    parameterValues.value = {}
    planError.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    planLoading.value = false
  }
}

async function loadInstalledVersions() {
  try {
    const res = await listHubDependencies(api, { entries: false, migrations: false })
    const map: Record<string, string> = {}
    for (const m of res.modules || []) {
      if (m.name && m.version) map[m.name] = m.version
    }
    for (const d of res.dependencies || []) {
      const name = d.component || d.name
      if (name && d.version && !map[name]) map[name] = d.version
    }
    installedVersions.value = map
  } catch {
    installedVersions.value = {}
  }
}

function parametersPayload(): Array<{ name: string; value: string }> | undefined {
  const out: Array<{ name: string; value: string }> = []
  for (const req of rootRequirements.value) {
    const key = requirementKey(req)
    if (!key) continue
    const value = (parameterValues.value[key] || '').trim()
    if (value !== '' && !req.invalid) out.push({ name: key, value })
  }
  return out.length ? out : undefined
}

function installPayload(): InstallPayload {
  return {
    component: props.component.trim(),
    version: version.value.trim() || undefined,
    namespace: namespacePayload(),
    run_migrations: runMigrations.value,
    migration_policy: runMigrations.value ? 'up' : 'none',
    parameters: parametersPayload(),
  }
}

const missingRequirements = computed<string[]>(() => {
  const missing: string[] = []
  for (const req of rootRequirements.value) {
    const key = requirementKey(req)
    if (!key || (!req.required && !req.missing)) continue
    if (req.invalid || !(parameterValues.value[key] || '').trim()) missing.push(key)
  }
  return missing
})

function resetScanDecision() {
  scanRevision += 1
  scanLoading.value = false
  scanError.value = null
  scanResult.value = null
  scanSkipped.value = false
}

async function runSecurityScan() {
  if (!props.component.trim()) {
    scanError.value = 'Component required'
    return
  }
  scanLoading.value = true
  scanError.value = null
  scanResult.value = null
  scanSkipped.value = false
  const revision = scanRevision + 1
  scanRevision = revision
  try {
    const result = await scanHubInstall(api, installPayload())
    if (revision === scanRevision) scanResult.value = result
  } catch (e: any) {
    if (revision !== scanRevision) return
    const data = e.response?.data
    scanError.value = data?.error || data?.message || e.message || 'Security review failed'
  } finally {
    if (revision === scanRevision) scanLoading.value = false
  }
}

function skipSecurityScan() {
  scanRevision += 1
  scanLoading.value = false
  scanError.value = null
  scanResult.value = null
  scanSkipped.value = true
}

const scanDecisionMade = computed(() => scanSkipped.value || !!scanResult.value)
const installDisabled = computed(() =>
  busy.value ||
  planLoading.value ||
  scanLoading.value ||
  !scanDecisionMade.value ||
  missingRequirements.value.length > 0 ||
  transitiveBlockers.value.length > 0,
)

function scanStatusLabel(status: HubScanStatus | undefined): string {
  return (status || 'pending').toString().toUpperCase()
}

function scanTone(status: HubScanStatus | undefined): string {
  const s = (status || '').toString().toLowerCase()
  if (s === 'clean') return 'clean'
  if (s === 'critical') return 'critical'
  if (s === 'warnings' || s === 'warning') return 'warnings'
  if (s === 'error') return 'error'
  return 'pending'
}

function findingTone(finding: HubScanFinding): string {
  return scanTone(finding.severity)
}

const scanModules = computed<HubScanModuleResult[]>(() => scanResult.value?.modules || [])
const scanFindings = computed<Array<HubScanFinding & { module_name: string }>>(() => {
  const out: Array<HubScanFinding & { module_name: string }> = []
  for (const moduleResult of scanModules.value) {
    for (const finding of moduleResult.findings || []) {
      out.push({ ...finding, module_name: moduleResult.module })
    }
  }
  return out
})

async function submit() {
  if (!props.component.trim()) {
    error.value = 'Component required'
    return
  }
  if (missingRequirements.value.length) {
    const n = missingRequirements.value.length
    error.value = `Configure required parameter${n === 1 ? '' : 's'}: ${missingRequirements.value.join(', ')}`
    return
  }
  if (transitiveBlockers.value.length) {
    const req = transitiveBlockers.value[0]
    error.value = `Requirement ${requirementKey(req)} of ${req.module} is unsatisfied and cannot be configured here; install ${req.module} directly with this parameter first`
    return
  }
  busy.value = true
  error.value = null
  try {
    await installHubDependency(api, installPayload())
    emit('installed', props.component.trim())
    close()
  } catch (e: any) {
    const data = e.response?.data
    if (data?.code === 'PARAMETER_TARGET_TRANSITIVE') {
      error.value = data.error || data.message || 'Parameter targets a transitive module; install that module directly with this parameter'
    } else {
      const details = data?.details
      if (details?.requirements && details?.install_payload) applyPlan(details)
      error.value = data?.error || data?.message || e.message
    }
  } finally {
    busy.value = false
  }
}

// ---------- plan tree ----------

interface TreeRow {
  node: InstallPlanNode
  depth: number
  last: boolean
  guides: boolean[]
}

// Order the flat graph into a depth-first tree using `parent`, keeping each
// module's provided `depth` for indentation. `guides` tracks, per ancestor
// level, whether a vertical connector should continue past this row.
const treeRows = computed<TreeRow[]>(() => {
  const nodes = plan.value?.graph || []
  if (!nodes.length) return []
  const byParent = new Map<string, InstallPlanNode[]>()
  const roots: InstallPlanNode[] = []
  for (const n of nodes) {
    if (!n.parent || (n.depth ?? 0) === 0) {
      roots.push(n)
    } else {
      const list = byParent.get(n.parent) || []
      list.push(n)
      byParent.set(n.parent, list)
    }
  }
  const rows: TreeRow[] = []
  const seen = new Set<string>()
  const walk = (node: InstallPlanNode, depth: number, last: boolean, guides: boolean[]) => {
    if (seen.has(node.module)) return
    seen.add(node.module)
    rows.push({ node, depth, last, guides })
    const children = byParent.get(node.module) || []
    children.forEach((child, i) => {
      walk(child, depth + 1, i === children.length - 1, [...guides, !last])
    })
  }
  roots.forEach((root, i) => walk(root, 0, i === roots.length - 1, []))
  // Any node not reachable through parent links still gets shown, ordered by depth.
  for (const n of nodes) {
    if (!seen.has(n.module)) rows.push({ node: n, depth: n.depth ?? 0, last: true, guides: [] })
  }
  return rows
})

type BadgeKind = 'new' | 'upgrade' | 'shared' | 'installed'

function nodeBadge(node: InstallPlanNode): { kind: BadgeKind; label: string; title: string } {
  if (!node.installed) {
    return { kind: 'new', label: 'NEW', title: 'Not installed yet — will be added' }
  }
  const current = installedVersions.value[node.module]
  const planned = node.version
  if (current && planned && current !== planned) {
    return { kind: 'upgrade', label: `UPGRADE ${current} → ${planned}`, title: 'Installed at a different version — this install changes it' }
  }
  if (node.shared) {
    return { kind: 'shared', label: 'SHARED', title: 'Already installed and reused — reached from another installed module' }
  }
  return { kind: 'installed', label: 'INSTALLED', title: 'Already installed at this version' }
}

const planSummary = computed(() => {
  const rows = treeRows.value
  let added = 0, reused = 0, upgraded = 0
  for (const r of rows) {
    const k = nodeBadge(r.node).kind
    if (k === 'new') added++
    else if (k === 'upgrade') upgraded++
    else reused++
  }
  return { added, reused, upgraded, total: rows.length }
})
</script>

<template>
  <Teleport to="body">
    <div v-if="modelValue" class="overlay" @click.self="close">
      <div class="dialog">
        <div class="flex items-center gap-2 mb-3">
          <Icon icon="tabler:download" class="w-5 h-5 text-info-500" />
          <span class="text-sm font-semibold" style="color: var(--p-text-color)">Install {{ component }}</span>
        </div>
        <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
          Installs a component from the hub and applies its registry entries. The plan below resolves the full dependency tree before anything changes.
        </p>

        <label class="form-label">Version</label>
        <input v-model="version" placeholder="latest" class="form-input mono" @input="resetScanDecision" @change="loadPlan" />

        <label class="form-label mt-3">Dependency namespace</label>
        <input
          v-model="dependencyNamespace"
          placeholder="auto"
          class="form-input mono"
          @input="markNamespaceTouched"
          @change="loadPlan"
        />
        <div class="field-hint">
          Auto target uses an existing dependency entry or the strongest dependency namespace cluster.
          <span v-if="plannedDependencyId" class="mono">{{ plannedDependencyId }}</span>
        </div>

        <!-- Plan summary + refresh -->
        <div class="mt-3 flex items-center justify-between gap-2 text-[10px]" style="color: var(--p-text-muted-color)">
          <span v-if="planLoading">Resolving install plan…</span>
          <span v-else-if="plan">
            {{ planSummary.total }} module{{ planSummary.total === 1 ? '' : 's' }} ·
            <span class="text-success-500">{{ planSummary.added }} new</span>
            <template v-if="planSummary.upgraded"> · <span class="text-warn-500">{{ planSummary.upgraded }} upgrade</span></template>
            <template v-if="planSummary.reused"> · {{ planSummary.reused }} reused</template>
          </span>
          <span v-else>Plan resolves transitive dependencies before install.</span>
          <button class="ghost-sm" type="button" @click="loadPlan" :disabled="planLoading">Refresh</button>
        </div>

        <!-- Dependency tree -->
        <div v-if="treeRows.length" class="tree">
          <div v-for="row in treeRows" :key="row.node.path || row.node.module" class="tree-row">
            <span class="tree-indent">
              <span v-for="(g, i) in row.guides" :key="i" class="tree-guide" :class="{ on: g }"></span>
              <span v-if="row.depth > 0" class="tree-branch">{{ row.last ? '└' : '├' }}</span>
            </span>
            <span class="tree-name mono" :class="{ direct: row.node.direct }" :title="row.node.module">{{ row.node.module }}</span>
            <span class="tree-ver mono">{{ row.node.version || row.node.constraint || '' }}</span>
            <span v-if="row.node.direct" class="tree-role">direct</span>
            <span
              class="node-badge"
              :class="nodeBadge(row.node).kind"
              :title="nodeBadge(row.node).title"
            >{{ nodeBadge(row.node).label }}</span>
          </div>
        </div>

        <!-- Legend -->
        <div v-if="treeRows.length" class="legend">
          <span class="node-badge new">NEW</span><span class="legend-txt">added by this install</span>
          <span class="node-badge upgrade">UPGRADE</span><span class="legend-txt">installed version changes</span>
          <span class="node-badge shared">SHARED</span><span class="legend-txt">already installed, reused</span>
          <span class="node-badge installed">INSTALLED</span><span class="legend-txt">present, unchanged</span>
        </div>

        <!-- Configuration: root module requirements, editable and submitted -->
        <div v-if="rootRequirements.length" class="mt-3 mb-3">
          <div class="form-label flex items-center gap-1.5">
            <Icon icon="tabler:list-check" class="w-3.5 h-3.5" />
            Configuration <span class="dim">({{ rootRequirements.length }})</span>
          </div>
          <div class="space-y-2">
            <label v-for="req in rootRequirements" :key="req.parameter_name || req.name" class="block">
              <div class="flex items-center gap-2 mb-1">
                <span class="mono text-[11px]" style="color: var(--p-text-color)">{{ req.parameter_name || req.name }}</span>
                <span v-if="req.required" class="text-[9px]" style="color: var(--p-warn-500)">required</span>
                <span v-if="req.invalid" class="text-[9px]" style="color: var(--p-danger-500)">invalid</span>
                <span v-if="req.value_source && req.value_source !== 'empty'" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.value_source }}</span>
                <span v-if="req.expected_kind" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.expected_kind }}</span>
                <span v-if="req.targets?.length" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.targets.length }} target{{ req.targets.length === 1 ? '' : 's' }}</span>
              </div>
              <RequirementValueInput
                :model-value="parameterValues[requirementKey(req)] || ''"
                :requirement="req"
                :placeholder="requirementPlaceholder(req)"
                @update:model-value="setParameter(req, $event)"
                @commit="loadPlan"
              />
              <div v-if="req.default && req.value_source !== 'default'" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">Package default: <span class="mono">{{ req.default }}</span></div>
              <div v-if="req.invalid_reason" class="mt-1 text-[10px]" style="color: var(--p-danger-500)">{{ req.invalid_reason }}</div>
              <div v-if="req.module" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.module }}{{ req.version ? '@' + req.version : '' }}</div>
              <div v-if="req.description" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.description }}</div>
            </label>
          </div>
        </div>

        <!-- Dependency configuration: transitive modules own these; parameters
             apply only to the module being installed, so they render read-only
             and are never submitted. -->
        <div v-if="transitiveRequirements.length" class="mt-3 mb-3">
          <div class="form-label flex items-center gap-1.5">
            <Icon icon="tabler:sitemap" class="w-3.5 h-3.5" />
            Dependency configuration <span class="dim">({{ transitiveRequirements.length }})</span>
          </div>
          <div class="space-y-2">
            <div
              v-for="req in transitiveRequirements"
              :key="req.parameter_name || req.name"
              class="transitive-req"
              :class="{ blocked: isTransitiveBlocker(req) }"
            >
              <div class="flex items-center gap-2 mb-1">
                <span class="mono text-[11px]" style="color: var(--p-text-color)">{{ req.parameter_name || req.name }}</span>
                <span class="text-[9px]" style="color: var(--p-text-muted-color)">transitive</span>
                <span v-if="isTransitiveBlocker(req)" class="text-[9px]" style="color: var(--p-danger-500)">unsatisfied</span>
                <span v-else-if="req.value_source && req.value_source !== 'empty'" class="text-[9px]" style="color: var(--p-text-muted-color)">{{ req.value_source }}</span>
              </div>
              <div class="transitive-value mono">{{ transitiveValue(req) || '(not set)' }}</div>
              <div v-if="isTransitiveBlocker(req)" class="mt-1 text-[10px]" style="color: var(--p-danger-500)">
                {{ req.invalid_reason || 'No value satisfies this requirement.' }}
                Install <span class="mono">{{ req.module }}</span> directly with this parameter to configure it.
              </div>
              <div v-else class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">
                Configured by <span class="mono">{{ req.module }}</span>; to override, install <span class="mono">{{ req.module }}</span> directly with this parameter.
              </div>
              <div v-if="req.description" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">{{ req.description }}</div>
            </div>
          </div>
        </div>
        <div v-if="plan && !planLoading && !requirements.length" class="mt-3 mb-3 text-[11px]" style="color: var(--p-text-muted-color)">
          No configuration required.
        </div>

        <label class="form-check">
          <input v-model="runMigrations" type="checkbox" @change="resetScanDecision" />
          Run migrations after install
        </label>

        <section class="scan-panel">
          <div class="scan-head">
            <div class="scan-title">
              <Icon icon="tabler:shield-check" class="w-3.5 h-3.5" />
              Security review
            </div>
            <span
              class="scan-badge"
              :class="scanSkipped ? 'skipped' : scanTone(scanResult?.overall_status)"
            >
              {{ scanSkipped ? 'SKIPPED' : scanResult ? scanStatusLabel(scanResult.overall_status) : scanLoading ? 'RUNNING' : 'PENDING' }}
            </span>
          </div>

          <div v-if="scanLoading" class="scan-state">
            <Icon icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin" />
            Reviewing {{ component }} before install
          </div>
          <div v-else-if="scanResult" class="scan-summary">
            <div class="scan-summary-line">
              {{ scanResult.overall_summary }}
              <span class="mono dim">{{ scanResult.scanned }}/{{ scanResult.total }}</span>
            </div>
            <div v-if="scanModules.length" class="scan-modules">
              <div v-for="mod in scanModules" :key="mod.module" class="scan-module">
                <span class="mono scan-module-name">{{ mod.module }}</span>
                <span class="mono dim">{{ mod.version || '' }}</span>
                <span class="scan-mini-badge" :class="scanTone(mod.status)">{{ scanStatusLabel(mod.status) }}</span>
              </div>
            </div>
            <div v-if="scanFindings.length" class="scan-findings">
              <div v-for="(finding, i) in scanFindings" :key="i" class="scan-finding" :class="findingTone(finding)">
                <div class="scan-finding-title">
                  <span>{{ finding.title }}</span>
                  <span class="mono dim">{{ finding.module_name }}</span>
                </div>
                <div v-if="finding.location" class="mono scan-finding-location">{{ finding.location }}</div>
                <div v-if="finding.detail" class="scan-finding-detail">{{ finding.detail }}</div>
              </div>
            </div>
          </div>
          <div v-else-if="scanSkipped" class="scan-state skipped">
            <Icon icon="tabler:shield-off" class="w-3.5 h-3.5" />
            Install will continue without a security review.
          </div>
          <div v-else class="scan-state">
            <Icon icon="tabler:shield-question" class="w-3.5 h-3.5" />
            Choose a security review path before installing.
          </div>

          <div v-if="scanError" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ scanError }}</div>

          <div class="scan-actions">
            <button class="scan-btn primary" type="button" @click="runSecurityScan" :disabled="scanLoading || busy || planLoading">
              <Icon :icon="scanLoading ? 'tabler:loader-2' : 'tabler:shield-search'" class="w-3.5 h-3.5" :class="{ 'animate-spin': scanLoading }" />
              {{ scanResult ? 'Run again' : 'Run scan' }}
            </button>
            <button class="scan-btn secondary" type="button" @click="skipSecurityScan" :disabled="scanLoading || busy">
              <Icon icon="tabler:player-skip-forward" class="w-3.5 h-3.5" />
              Skip
            </button>
          </div>
        </section>

        <div v-if="transitiveBlockers.length" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">
          {{ transitiveBlockers.length }} dependency requirement{{ transitiveBlockers.length === 1 ? ' is' : 's are' }} unsatisfied.
          Install the owning module{{ transitiveBlockers.length === 1 ? '' : 's' }} directly with the parameter to proceed.
        </div>
        <div v-if="planError" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ planError }}</div>
        <div v-if="error" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ error }}</div>

        <div class="flex justify-end gap-2 mt-4">
          <button class="dialog-btn cancel" @click="close" :disabled="busy">Cancel</button>
          <button class="dialog-btn proceed" @click="submit" :disabled="installDisabled">
            <Icon v-if="busy" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
            Install
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.mono { font-family: 'JetBrains Mono', monospace; }
.dim { color: var(--p-text-muted-color); }

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
  width: 460px; max-width: 90vw;
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
.form-input:focus { border-color: var(--p-primary-color); }
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

.scan-panel {
  margin-top: 12px;
  padding: 10px;
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  background: var(--p-surface-0);
}
.scan-head {
  display: flex; align-items: center; justify-content: space-between; gap: 8px;
  margin-bottom: 8px;
}
.scan-title {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 11px; font-weight: 700;
  color: var(--p-text-color);
}
.scan-badge,
.scan-mini-badge {
  flex-shrink: 0;
  font-size: 8.5px; font-weight: 800; letter-spacing: 0.04em;
  padding: 1px 6px;
  border-radius: 3px;
}
.scan-badge.pending,
.scan-mini-badge.pending {
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.scan-badge.clean,
.scan-mini-badge.clean {
  background: color-mix(in srgb, var(--p-green-500) 16%, transparent);
  color: var(--p-green-500);
}
.scan-badge.warnings,
.scan-mini-badge.warnings,
.scan-badge.error,
.scan-mini-badge.error {
  background: color-mix(in srgb, var(--p-orange-500) 16%, transparent);
  color: var(--p-orange-500);
}
.scan-badge.critical,
.scan-mini-badge.critical {
  background: color-mix(in srgb, var(--p-danger-500) 16%, transparent);
  color: var(--p-danger-500);
}
.scan-badge.skipped {
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
}
.scan-state {
  display: flex; align-items: center; gap: 6px;
  min-height: 24px;
  font-size: 11px;
  color: var(--p-text-muted-color);
}
.scan-state.skipped { color: var(--p-text-color); }
.scan-summary {
  font-size: 11px;
  color: var(--p-text-color);
}
.scan-summary-line {
  display: flex; justify-content: space-between; gap: 8px;
  line-height: 1.4;
}
.scan-modules {
  margin-top: 8px;
  display: grid;
  gap: 4px;
}
.scan-module {
  display: flex; align-items: center; gap: 6px;
  min-width: 0;
  padding: 4px 6px;
  border-radius: 4px;
  background: var(--p-surface-100);
}
.scan-module-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: var(--p-text-color);
}
.scan-findings {
  margin-top: 8px;
  display: grid;
  gap: 6px;
}
.scan-finding {
  padding: 6px 8px;
  border: 1px solid var(--p-content-border-color);
  border-left-width: 3px;
  border-radius: 5px;
  background: var(--p-surface-50);
}
.scan-finding.warning,
.scan-finding.warnings,
.scan-finding.error {
  border-left-color: var(--p-orange-500);
}
.scan-finding.critical {
  border-left-color: var(--p-danger-500);
}
.scan-finding.clean,
.scan-finding.info,
.scan-finding.pending {
  border-left-color: var(--p-text-muted-color);
}
.scan-finding-title {
  display: flex; justify-content: space-between; gap: 8px;
  color: var(--p-text-color);
  font-weight: 600;
}
.scan-finding-location {
  margin-top: 2px;
  color: var(--p-text-muted-color);
  font-size: 10px;
}
.scan-finding-detail {
  margin-top: 3px;
  color: var(--p-text-muted-color);
  line-height: 1.35;
}
.scan-actions {
  display: flex; justify-content: flex-end; gap: 6px;
  margin-top: 8px;
}
.scan-btn {
  display: inline-flex; align-items: center; gap: 4px;
  min-height: 26px;
  padding: 4px 9px;
  font-size: 10px; font-weight: 600;
  border-radius: 4px;
  cursor: pointer;
}
.scan-btn.primary {
  color: var(--p-info-500);
  background: color-mix(in srgb, var(--p-info-500) 12%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-info-500) 45%, transparent);
}
.scan-btn.secondary {
  color: var(--p-text-muted-color);
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
}
.scan-btn:hover:not(:disabled) { filter: brightness(1.05); }
.scan-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.ghost-sm {
  padding: 3px 8px; font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px; cursor: pointer;
}
.ghost-sm:hover:not(:disabled) { background: var(--p-surface-200); }
.ghost-sm:disabled { opacity: 0.5; cursor: not-allowed; }

/* ---------- tree ---------- */
.tree {
  margin-top: 8px;
  max-height: 220px; overflow: auto;
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 6px 8px;
  background: var(--p-surface-0);
}
.tree-row {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; line-height: 1.9;
  white-space: nowrap;
}
.tree-indent {
  display: inline-flex; align-items: center;
  flex-shrink: 0;
  color: var(--p-text-muted-color);
  opacity: 0.55;
  font-family: 'JetBrains Mono', monospace;
}
.tree-guide { display: inline-block; width: 12px; text-align: center; }
.tree-guide.on::before { content: '│'; }
.tree-branch { display: inline-block; width: 12px; }
.tree-name {
  color: var(--p-text-muted-color);
  overflow: hidden; text-overflow: ellipsis;
  min-width: 0;
}
.tree-name.direct { color: var(--p-text-color); font-weight: 600; }
.tree-ver { color: var(--p-text-muted-color); font-size: 10px; }
.tree-role {
  font-size: 8px; text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--p-primary-color);
  border: 1px solid var(--p-primary-color);
  border-radius: 3px; padding: 0 3px;
  opacity: 0.85;
}
.node-badge {
  margin-left: auto;
  flex-shrink: 0;
  font-size: 8.5px; font-weight: 700; letter-spacing: 0.04em;
  text-transform: uppercase;
  padding: 1px 5px; border-radius: 3px;
  white-space: nowrap;
}
.node-badge.new { background: color-mix(in srgb, var(--p-green-500) 18%, transparent); color: var(--p-green-500); }
.node-badge.upgrade { background: color-mix(in srgb, var(--p-orange-500) 18%, transparent); color: var(--p-orange-500); }
.node-badge.shared { background: var(--p-surface-200); color: var(--p-text-muted-color); }
.node-badge.installed { background: transparent; color: var(--p-text-muted-color); border: 1px solid var(--p-content-border-color); }

.transitive-req {
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 6px 8px;
  background: var(--p-surface-0);
}
.transitive-req.blocked { border-color: var(--p-danger-500); }
.transitive-value {
  font-size: 11px;
  color: var(--p-text-muted-color);
  padding: 4px 8px;
  border-radius: 4px;
  background: var(--p-surface-100);
  overflow-wrap: anywhere;
}

.legend {
  display: flex; flex-wrap: wrap; align-items: center; gap: 4px 8px;
  margin-top: 8px;
  font-size: 9px;
}
.legend .node-badge { margin-left: 0; }
.legend-txt { color: var(--p-text-muted-color); margin-right: 4px; }

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
