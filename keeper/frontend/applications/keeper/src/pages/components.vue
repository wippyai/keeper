<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useApi, useWippy } from '../composables/useWippy'
import {
  listComponents,
  getDoc,
  startBuild,
  listBuilds,
  getBuild,
  captureScreenshot,
  formatBytes,
  formatMtime,
  type ComponentDescriptor,
  type BuildRun,
  type BuildStatus,
} from '../api/components'
import MarkdownContent from '../components/shared/MarkdownContent.vue'
import JsonBlock from '../components/shared/JsonBlock.vue'

const api = useApi()
const route = useRoute()

const applications = ref<ComponentDescriptor[]>([])
const widgets = ref<ComponentDescriptor[]>([])
const kitDocs = ref<string[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

// -------------- Selection / layout --------------
const selectedComponentId = ref<string | null>(null)
const selectedKitDoc = ref<string | null>(null)

const docCache = ref<Record<string, string>>({})
const docLoading = ref<Set<string>>(new Set())

const leftW = ref(260)

let resizing: 'l' | null = null
let sx = 0
let sw = 0

function startResize(d: 'l', e: MouseEvent) {
  resizing = d
  sx = e.clientX
  sw = leftW.value
  document.addEventListener('mousemove', onResize)
  document.addEventListener('mouseup', stopResize)
  document.body.style.cursor = 'col-resize'
  document.body.style.userSelect = 'none'
}
function onResize(e: MouseEvent) {
  if (!resizing) return
  const dx = e.clientX - sx
  leftW.value = Math.max(220, Math.min(400, sw + dx))
}
function stopResize() {
  resizing = null
  document.removeEventListener('mousemove', onResize)
  document.removeEventListener('mouseup', stopResize)
  document.body.style.cursor = ''
  document.body.style.userSelect = ''
}

// -------------- Derived --------------
const allComponents = computed<ComponentDescriptor[]>(() => [
  ...applications.value,
  ...widgets.value,
])

const selectedComponent = computed<ComponentDescriptor | null>(() => {
  if (!selectedComponentId.value) return null
  return allComponents.value.find(c => c.id === selectedComponentId.value) || null
})

const selectedReadmeContent = computed<string | null>(() => {
  const c = selectedComponent.value
  if (!c?.readme_path) return null
  return docCache.value[c.readme_path] || null
})

const selectedKitDocContent = computed<string | null>(() => {
  if (!selectedKitDoc.value) return null
  return docCache.value[selectedKitDoc.value] || null
})

const totalComponents = computed(() => applications.value.length + widgets.value.length)
const totalBuilt = computed(() => allComponents.value.filter(c => c.built).length)

// -------------- Data fetching --------------
async function load() {
  loading.value = true
  error.value = null
  try {
    const res = await listComponents(api)
    if (!res.success) {
      error.value = 'Scan failed'
      return
    }
    applications.value = res.applications || []
    widgets.value = res.widgets || []
    kitDocs.value = res.kit_docs || []
    if (!selectedComponentId.value && !selectedKitDoc.value) {
      if (applications.value[0]) selectedComponentId.value = applications.value[0].id
      else if (widgets.value[0]) selectedComponentId.value = widgets.value[0].id
    }
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function loadDoc(path: string) {
  if (docCache.value[path] || docLoading.value.has(path)) return
  const s = new Set(docLoading.value)
  s.add(path)
  docLoading.value = s
  try {
    const res = await getDoc(api, path)
    if (res.success) docCache.value = { ...docCache.value, [path]: res.content }
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  const s2 = new Set(docLoading.value)
  s2.delete(path)
  docLoading.value = s2
}

watch(selectedComponent, (c) => {
  if (c?.readme_path) loadDoc(c.readme_path)
})
watch(selectedKitDoc, (path) => {
  if (path) loadDoc(path)
})

// -------------- Selection helpers --------------
function selectComponent(id: string) {
  selectedComponentId.value = id
  selectedKitDoc.value = null
}
function selectKitDoc(path: string) {
  selectedKitDoc.value = path
  selectedComponentId.value = null
}

// -------------- Formatting helpers --------------
function docName(path: string): string {
  return (path.split('/').pop() || path).replace(/\.md$/, '')
}
function propsCount(schema: any): number {
  if (!schema?.properties) return 0
  return Object.keys(schema.properties).length
}
function agoShort(ts: number): string {
  const d = Math.floor(Date.now() / 1000) - ts
  if (d < 60) return d + 's'
  if (d < 3600) return Math.floor(d / 60) + 'm'
  if (d < 86400) return Math.floor(d / 3600) + 'h'
  return Math.floor(d / 86400) + 'd'
}

// -------------- Builds (real backend via /keeper/components/builds) --------------

const buildsByComponent = ref<Record<string, BuildRun[]>>({})
const buildInstance = useWippy()

const buildRunsForComponent = computed<BuildRun[]>(() => {
  if (!selectedComponent.value) return []
  return buildsByComponent.value[selectedComponent.value.id] || []
})

function isBuilding(cid: string) {
  const list = buildsByComponent.value[cid] || []
  return list.some(b => b.status === 'queued' || b.status === 'running')
}

async function refreshBuilds(cid: string) {
  try {
    const res = await listBuilds(api, cid)
    if (res.success) {
      buildsByComponent.value = { ...buildsByComponent.value, [cid]: res.builds || [] }
    }
  } catch (e: any) { error.value = e?.response?.data?.error || e.message }
}

function watchBuild(build_id: string, cid: string) {
  // Initial fetch
  getBuild(api, build_id, 0).then(r => {
    if (!r.success) return
    const list = buildsByComponent.value[cid] || []
    const idx = list.findIndex(b => b.build_id === build_id)
    if (idx === -1) list.unshift(r.build)
    else list[idx] = r.build
    buildsByComponent.value = { ...buildsByComponent.value, [cid]: [...list] }
  }).catch(() => {})

  // Real-time updates via relay
  buildInstance.on('keeper.builds', async (evt: any) => {
    const data = evt?.data || evt
    if (!data || data.build_id !== build_id) return
    try {
      const r = await getBuild(api, build_id, 0)
      if (!r.success) return
      const list = buildsByComponent.value[cid] || []
      const idx = list.findIndex(b => b.build_id === build_id)
      if (idx === -1) list.unshift(r.build)
      else list[idx] = r.build
      buildsByComponent.value = { ...buildsByComponent.value, [cid]: [...list] }
    } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  })
}

async function rebuildComponent(cid: string) {
  try {
    const res = await startBuild(api, cid, 'user')
    if (!res.success || !res.build_id) {
      error.value = res.error || 'Failed to start build'
      return
    }
    expandedBuildId.value = res.build_id
    await refreshBuilds(cid)
    watchBuild(res.build_id, cid)
  } catch (e: any) {
    error.value = e.message
  }
}

watch(selectedComponent, (c) => {
  if (c && c.editable) {
    refreshBuilds(c.id)
  }
}, { immediate: true })

const expandedBuildId = ref<string | null>(null)
async function toggleBuild(id: string) {
  if (expandedBuildId.value === id) {
    expandedBuildId.value = null
    return
  }
  expandedBuildId.value = id
  // Lazy-load log lines on first expansion (listBuilds doesn't include them).
  if (!selectedComponent.value) return
  const cid = selectedComponent.value.id
  const list = buildsByComponent.value[cid] || []
  const cached = list.find(b => b.build_id === id)
  if (cached && (!cached.lines || cached.lines.length === 0)) {
    try {
      const r = await getBuild(api, id, 0)
      if (r.success && r.build) {
        const idx = list.findIndex(b => b.build_id === id)
        if (idx !== -1) {
          list[idx] = r.build
          buildsByComponent.value = { ...buildsByComponent.value, [cid]: [...list] }
        }
      }
    } catch (e: any) { error.value = e?.response?.data?.error || e.message }
  }
}

function buildStatusColor(st: BuildStatus): string {
  switch (st) {
    case 'queued': return 'var(--p-text-muted-color)'
    case 'running': return 'var(--p-warn-500)'
    case 'success': return 'var(--p-success-500)'
    case 'failed': return 'var(--p-danger-500)'
    case 'cancelled': return 'var(--p-text-muted-color)'
  }
}
function buildStatusIcon(st: BuildStatus): string {
  switch (st) {
    case 'queued': return 'tabler:clock'
    case 'running': return 'tabler:loader-2'
    case 'success': return 'tabler:check'
    case 'failed': return 'tabler:alert-circle'
    case 'cancelled': return 'tabler:x'
  }
}
function fmtDuration(ms: number | null | undefined): string {
  if (!ms) return '-'
  if (ms < 1000) return ms + 'ms'
  if (ms < 60000) return (ms / 1000).toFixed(1) + 's'
  return Math.floor(ms / 60000) + 'm ' + Math.round((ms % 60000) / 1000) + 's'
}

// -------------- Screenshots --------------
const captureBusy = ref<Set<string>>(new Set())
const liveThumbnails = ref<Record<string, string>>({})
const captureError = ref<string | null>(null)

function thumbnailFor(c: ComponentDescriptor): string {
  return liveThumbnails.value[c.id] || c.thumbnail_url || ''
}

// When capturing the *currently open* keeper page, send the inner SPA's
// route (prefixed with /c/keeper:main) so Playwright lands on the page
// the user is actually looking at, not just the dashboard. For other
// components (main app, widgets) the library infers the route from
// the descriptor when none is sent.
function effectiveRoute(c: ComponentDescriptor, override?: string): string | undefined {
  if (override) return override
  if (c.id === '@wippy/app-keeper') {
    const inner = route.fullPath || '/'
    return '/c/keeper:main' + (inner.startsWith('/') ? inner : '/' + inner)
  }
  return undefined
}

async function captureComponent(c: ComponentDescriptor, opts?: { full?: boolean; route?: string }) {
  const s = new Set(captureBusy.value)
  s.add(c.id)
  captureBusy.value = s
  captureError.value = null
  try {
    const r = await captureScreenshot(api, c.id, {
      full: opts?.full,
      route: effectiveRoute(c, opts?.route),
    })
    if (!r.success) {
      captureError.value = r.error || 'capture failed'
      return
    }
    if (r.screenshot_url) {
      // Cache-bust so the new image actually loads.
      liveThumbnails.value = {
        ...liveThumbnails.value,
        [c.id]: r.screenshot_url + '?t=' + Date.now(),
      }
    }
  } catch (e: any) {
    captureError.value = e.message
  } finally {
    const s2 = new Set(captureBusy.value)
    s2.delete(c.id)
    captureBusy.value = s2
  }
}
function isCapturing(cid: string) { return captureBusy.value.has(cid) }

const zoomImage = ref<string | null>(null)
function openZoom(url: string) { zoomImage.value = url }
function closeZoom() { zoomImage.value = null }

onMounted(load)
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="shrink-0 px-4 py-2 flex items-center gap-3" style="border-bottom: 1px solid var(--p-content-border-color)">
      <Icon icon="tabler:puzzle" class="w-4 h-4 keeper-accent" />
      <div class="flex-1 min-w-0">
        <div class="text-sm font-semibold" style="color: var(--p-text-color)">Components</div>
        <div class="text-[10px]" style="color: var(--p-text-muted-color)">
          {{ applications.length }} apps · {{ widgets.length }} widgets · {{ totalBuilt }}/{{ totalComponents }} built
        </div>
      </div>
      <button class="refresh-btn" @click="load" :disabled="loading">
        <Icon icon="tabler:refresh" class="w-4 h-4" :class="{ 'animate-spin': loading }" />
      </button>
    </div>

    <div v-if="loading && totalComponents === 0" class="flex-1 flex items-center justify-center">
      <Icon icon="tabler:loader-2" class="w-6 h-6 animate-spin keeper-accent" />
    </div>
    <div v-else-if="error" class="flex-1 flex items-center justify-center text-xs text-danger-500">
      <p>{{ error }}</p>
    </div>

    <div v-else class="flex-1 flex overflow-hidden min-h-0">
      <!-- Left sidebar -->
      <aside class="shrink-0 overflow-y-auto" :style="{ width: leftW + 'px' }">
        <div class="group-label">
          <Icon icon="tabler:box-multiple" class="w-3 h-3" />
          Applications
          <span class="gcount">{{ applications.length }}</span>
        </div>
        <button
          v-for="c in applications" :key="c.id"
          class="row" :class="{ sel: selectedComponentId === c.id, dimmed: !c.editable, 'main-app': c.is_main_app }"
          @click="selectComponent(c.id)"
        >
          <div class="thumb">
            <img v-if="thumbnailFor(c)" :src="thumbnailFor(c)" alt="" />
            <Icon v-else :icon="c.is_main_app ? 'tabler:crown' : (c.editable ? 'tabler:app-window-filled' : 'tabler:app-window')"
              class="ic" :class="{ 'text-danger-500': c.is_main_app, 'text-info-500': !c.is_main_app && c.editable, 'text-accent-400': !c.is_main_app && !c.editable }" />
          </div>
          <div class="rinfo">
            <div class="rtitle">
              {{ c.title }}
              <span v-if="c.is_main_app" class="mini-pill main-pill">main app</span>
            </div>
            <div class="rmeta">
              <span class="mono">{{ c.path.split('/').slice(-1)[0] }}</span>
              <span v-if="!c.editable && c.link_kind === 'manifest'" class="mini-pill linked-pill">linked</span>
              <span v-if="!c.editable && c.link_kind === 'none'" class="mini-pill unknown-pill">prebuilt</span>
            </div>
          </div>
          <span v-if="c.built" class="built-badge ok">{{ formatBytes(c.size_bytes) }}</span>
          <span v-else class="built-badge dim">—</span>
        </button>

        <div class="group-label">
          <Icon icon="tabler:puzzle" class="w-3 h-3" />
          Web Components
          <span class="gcount">{{ widgets.length }}</span>
        </div>
        <button
          v-for="c in widgets" :key="c.id"
          class="row" :class="{ sel: selectedComponentId === c.id, dimmed: !c.editable }"
          @click="selectComponent(c.id)"
        >
          <div class="thumb">
            <img v-if="thumbnailFor(c)" :src="thumbnailFor(c)" alt="" />
            <Icon v-else icon="tabler:components" class="ic"
              :class="{ 'text-success-500': c.editable, 'text-accent-400': !c.editable }" />
          </div>
          <div class="rinfo">
            <div class="rtitle">{{ c.title }}</div>
            <div class="rmeta">
              <span class="mono">{{ c.tag_name || c.path.split('/').slice(-1)[0] }}</span>
              <span v-if="!c.editable && c.link_kind === 'manifest'" class="mini-pill linked-pill">linked</span>
              <span v-if="!c.editable && c.link_kind === 'none'" class="mini-pill unknown-pill">prebuilt</span>
            </div>
          </div>
          <span v-if="c.built" class="built-badge ok">{{ formatBytes(c.size_bytes) }}</span>
          <span v-else class="built-badge dim">—</span>
        </button>

        <div v-if="kitDocs.length > 0" class="group-label">
          <Icon icon="tabler:book-2" class="w-3 h-3" />
          Kit Docs
          <span class="gcount">{{ kitDocs.length }}</span>
        </div>
        <button
          v-for="path in kitDocs" :key="path"
          class="row" :class="{ sel: selectedKitDoc === path }"
          @click="selectKitDoc(path)"
        >
          <Icon icon="tabler:file-text" class="ic text-accent-500" />
          <div class="rinfo">
            <div class="rtitle">{{ docName(path) }}</div>
            <div class="rmeta"><span class="mono">{{ path.replace(/^frontend\//, '') }}</span></div>
          </div>
        </button>
      </aside>

      <div class="rh" @mousedown="startResize('l', $event)"></div>

      <!-- Center: component or kit doc detail -->
      <div class="flex-1 overflow-y-auto min-w-0">
        <!-- Component -->
        <template v-if="selectedComponent">
          <div class="detail-head">
            <div class="flex items-start gap-3 mb-2">
              <div class="detail-thumb" :class="{ main: selectedComponent.is_main_app, busy: isCapturing(selectedComponent.id), zoomable: !!thumbnailFor(selectedComponent) }"
                @click="thumbnailFor(selectedComponent) && openZoom(thumbnailFor(selectedComponent))">
                <img v-if="thumbnailFor(selectedComponent)" :src="thumbnailFor(selectedComponent)" alt="" />
                <Icon v-else :icon="selectedComponent.is_main_app ? 'tabler:crown' : (selectedComponent.kind === 'app' ? 'tabler:app-window' : 'tabler:components')"
                  class="w-6 h-6" :style="{ color: selectedComponent.is_main_app ? 'var(--p-danger-500)' : (selectedComponent.editable ? 'var(--p-primary-color)' : 'var(--p-accent-400)') }" />
                <div v-if="isCapturing(selectedComponent.id)" class="thumb-overlay">
                  <Icon icon="tabler:loader-2" class="w-4 h-4 animate-spin" />
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <h1 class="text-lg font-semibold" style="color: var(--p-text-color)">{{ selectedComponent.title }}</h1>
                  <span v-if="selectedComponent.is_main_app" class="kind-pill main">main app</span>
                  <span v-else class="kind-pill" :class="selectedComponent.kind">{{ selectedComponent.kind }}</span>
                  <span v-if="!selectedComponent.editable && selectedComponent.link_kind === 'manifest'" class="kind-pill linked">linked</span>
                  <span v-if="!selectedComponent.editable && selectedComponent.link_kind === 'none'" class="kind-pill unknown">prebuilt</span>
                  <span v-if="selectedComponent.version" class="version-pill">v{{ selectedComponent.version }}</span>
                </div>
                <div v-if="selectedComponent.description" class="text-xs mt-1" style="color: var(--p-text-muted-color)">
                  {{ selectedComponent.description }}
                </div>
                <div v-if="selectedComponent.origin" class="origin-strip mt-2">
                  <Icon icon="tabler:external-link" class="w-3 h-3 shrink-0" />
                  <div class="origin-info">
                    <span class="origin-label">Built from</span>
                    <span v-if="selectedComponent.origin.source_path" class="origin-path mono">{{ selectedComponent.origin.source_path }}</span>
                    <span v-if="selectedComponent.origin.source_repo" class="origin-repo mono">{{ selectedComponent.origin.source_repo }}</span>
                    <span v-if="selectedComponent.origin.built_from_sha" class="origin-sha mono">{{ selectedComponent.origin.built_from_sha.slice(0, 8) }}</span>
                    <span v-if="selectedComponent.origin.built_at" class="origin-time">{{ formatMtime(selectedComponent.origin.built_at) }}</span>
                  </div>
                </div>
                <div v-else-if="!selectedComponent.editable" class="text-[10px] mt-1" style="color: var(--p-text-muted-color)">
                  Prebuilt bundle — no origin manifest. Drop a <span class="mono">.wippy-origin.json</span> next to it to link the source.
                </div>
              </div>
              <div class="head-actions">
                <button class="head-btn ghost" @click="captureComponent(selectedComponent)"
                  :disabled="isCapturing(selectedComponent.id)"
                  :title="'Capture screenshot via Playwright'">
                  <Icon :icon="isCapturing(selectedComponent.id) ? 'tabler:loader-2' : 'tabler:camera'"
                    class="w-3 h-3" :class="{ 'animate-spin': isCapturing(selectedComponent.id) }" />
                  {{ isCapturing(selectedComponent.id) ? 'Capturing…' : 'Snapshot' }}
                </button>
                <button v-if="selectedComponent.editable" class="head-btn ghost" @click="rebuildComponent(selectedComponent.id)"
                  :disabled="isBuilding(selectedComponent.id)"
                  :title="'Run ' + (selectedComponent.scripts.build || 'build') + ' in docker'">
                  <Icon :icon="isBuilding(selectedComponent.id) ? 'tabler:loader-2' : 'tabler:hammer'"
                    class="w-3 h-3" :class="{ 'animate-spin': isBuilding(selectedComponent.id) }" />
                  {{ isBuilding(selectedComponent.id) ? 'Building…' : 'Rebuild' }}
                </button>
              </div>
            </div>
          </div>

          <div class="stat-grid">
            <div class="stat">
              <div class="k">Package</div>
              <div class="v mono">{{ selectedComponent.id }}</div>
            </div>
            <div class="stat">
              <div class="k">Path</div>
              <div class="v mono">{{ selectedComponent.path }}</div>
            </div>
            <div v-if="selectedComponent.tag_name" class="stat">
              <div class="k">Tag</div>
              <div class="v mono">&lt;{{ selectedComponent.tag_name }}&gt;</div>
            </div>
            <div class="stat">
              <div class="k">Toolchain</div>
              <div class="v mono">{{ selectedComponent.toolchain }}</div>
            </div>
            <div class="stat">
              <div class="k">Source</div>
              <div class="v">{{ formatBytes(selectedComponent.source_bytes) }}</div>
            </div>
            <div class="stat">
              <div class="k">Build</div>
              <div class="v">
                <template v-if="selectedComponent.built">
                  {{ formatBytes(selectedComponent.size_bytes) }}
                  <span class="ml-1 text-[10px]" style="color: var(--p-text-muted-color)">
                    ({{ formatMtime(selectedComponent.last_built) }})
                  </span>
                </template>
                <span v-else class="text-[10px]" style="color: var(--p-text-muted-color)">never built</span>
              </div>
            </div>
            <div class="stat">
              <div class="k">Out dir</div>
              <div class="v mono">{{ selectedComponent.out_dir }}</div>
            </div>
            <div v-if="selectedComponent.scripts.build" class="stat">
              <div class="k">Build script</div>
              <div class="v mono">{{ selectedComponent.scripts.build }}</div>
            </div>
          </div>

          <!-- Builds for this component -->
          <div v-if="selectedComponent.editable" class="section">
            <div class="section-title">
              <Icon icon="tabler:hammer" class="w-3 h-3" />
              Builds
              <span class="count">{{ buildRunsForComponent.length }}</span>
              <button class="inline-new" :disabled="isBuilding(selectedComponent.id)" @click="rebuildComponent(selectedComponent.id)">
                <Icon :icon="isBuilding(selectedComponent.id) ? 'tabler:loader-2' : 'tabler:player-play'"
                  class="w-3 h-3" :class="{ 'animate-spin': isBuilding(selectedComponent.id) }" />
                Rebuild
              </button>
            </div>
            <div v-if="buildRunsForComponent.length === 0" class="text-xs italic" style="color: var(--p-text-muted-color)">
              No builds yet. Click Rebuild to run the component toolchain in docker.
            </div>
            <div v-else class="build-list">
              <div v-for="b in buildRunsForComponent" :key="b.build_id" class="build-row" :class="{ exp: expandedBuildId === b.build_id }">
                <button class="build-head" @click="toggleBuild(b.build_id)">
                  <Icon :icon="buildStatusIcon(b.status)"
                    class="w-3.5 h-3.5 shrink-0"
                    :class="{ 'animate-spin': b.status === 'running' }"
                    :style="{ color: buildStatusColor(b.status) }" />
                  <span class="build-status" :style="{ color: buildStatusColor(b.status) }">{{ b.status }}</span>
                  <span class="build-cmd mono">{{ b.command }}</span>
                  <span class="build-img mono">{{ b.image }}</span>
                  <span class="build-trigger" :class="b.trigger">{{ b.trigger }}</span>
                  <span class="build-time">{{ agoShort(b.started_at) }} ago</span>
                  <span v-if="b.duration_ms" class="build-dur mono">{{ fmtDuration(b.duration_ms) }}</span>
                  <Icon :icon="expandedBuildId === b.build_id ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3 shrink-0" style="color: var(--p-text-muted-color)" />
                </button>
                <div v-if="expandedBuildId === b.build_id" class="build-body">
                  <div v-if="b.error" class="build-error">
                    <Icon icon="tabler:alert-circle" class="w-3 h-3 shrink-0" />
                    <span>{{ b.error }}</span>
                  </div>
                  <div class="build-log">
                    <div v-for="l in (b.lines || [])" :key="l.seq" class="log-line" :class="l.stream">
                      <span class="log-stream">{{ l.stream === 'stdout' ? ' ' : l.stream === 'stderr' ? '!' : '$' }}</span>
                      <span class="log-text">{{ l.text }}</span>
                    </div>
                    <div v-if="(b.lines || []).length === 0 && (b.status === 'queued' || b.status === 'running')" class="log-line system">
                      <span class="log-stream">…</span>
                      <span class="log-text">waiting for output</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="selectedComponent.props_schema" class="section">
            <div class="section-title">
              <Icon icon="tabler:code" class="w-3 h-3" />
              Props Schema
              <span class="count">{{ propsCount(selectedComponent.props_schema) }}</span>
            </div>
            <JsonBlock :data="selectedComponent.props_schema" font-size="10px" />
          </div>

          <div v-if="selectedComponent.readme_path" class="section">
            <div class="section-title">
              <Icon icon="tabler:file-text" class="w-3 h-3" />
              README
              <span class="mono-hint">{{ selectedComponent.readme_path }}</span>
            </div>
            <div v-if="selectedReadmeContent" class="md-wrap">
              <MarkdownContent :content="selectedReadmeContent" />
            </div>
            <div v-else class="empty-line">
              <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
              Loading...
            </div>
          </div>
        </template>

        <!-- Kit doc -->
        <template v-else-if="selectedKitDoc">
          <div class="detail-head">
            <div class="flex items-center gap-2 mb-1">
              <Icon icon="tabler:book-2" class="w-5 h-5 text-accent-500" />
              <h1 class="text-lg font-semibold" style="color: var(--p-text-color)">{{ docName(selectedKitDoc) }}</h1>
              <span class="kind-pill kit">kit doc</span>
            </div>
            <div class="text-xs mono" style="color: var(--p-text-muted-color)">{{ selectedKitDoc }}</div>
          </div>
          <div v-if="selectedKitDocContent" class="md-wrap" style="padding: 0 20px 24px">
            <MarkdownContent :content="selectedKitDocContent" />
          </div>
          <div v-else class="empty-line" style="padding: 0 20px">
            <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
            Loading...
          </div>
        </template>

        <div v-else class="empty-state">
          <Icon icon="tabler:puzzle" class="w-8 h-8" />
          <span>Select a component or doc</span>
        </div>
      </div>

    </div>

    <!-- Zoom modal -->
    <Teleport to="body">
      <div v-if="zoomImage" class="zoom-overlay" @click="closeZoom">
        <img :src="zoomImage" class="zoom-image" @click.stop />
        <button class="zoom-close" @click="closeZoom"><Icon icon="tabler:x" class="w-5 h-5" /></button>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.head-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px;
  font-size: 10px; font-weight: 600;
  background: var(--p-primary-color); color: var(--p-primary-contrast-color);
  border: 0; border-radius: 3px; cursor: pointer;
}
.head-btn:hover { opacity: 0.9; }
.head-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.head-btn.ghost {
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
}
.head-btn.ghost:hover { background: var(--p-surface-200); }
.head-actions { display: flex; gap: 6px; }

.refresh-btn {
  padding: 4px;
  background: transparent; border: 0;
  color: var(--p-text-muted-color);
  cursor: pointer; border-radius: 4px;
}
.refresh-btn:hover { background: var(--p-surface-100); color: var(--p-text-color); }
.refresh-btn:disabled { opacity: 0.5; }

aside {
  border-right: 1px solid var(--p-content-border-color);
  padding: 8px 0;
}

.group-label {
  display: flex; align-items: center; gap: 6px;
  padding: 10px 12px 4px;
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--p-text-muted-color);
}
.gcount {
  margin-left: auto;
  font-size: 9px;
  padding: 1px 5px; border-radius: 3px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}

.row {
  display: flex; align-items: center; gap: 10px;
  width: 100%;
  padding: 7px 12px;
  background: transparent; border: 0; cursor: pointer; text-align: left;
  transition: background 0.1s;
}
.row:hover { background: var(--p-surface-100); }
.row.sel {
  background: color-mix(in srgb, var(--p-primary-color) 10%, transparent);
  border-left: 2px solid var(--p-primary-color);
  padding-left: 10px;
}
.row .ic { width: 16px; height: 16px; flex-shrink: 0; }
.row.dimmed .rtitle { color: var(--p-text-muted-color); }
.row.main-app .rtitle { color: var(--p-text-color); font-weight: 700; }
.row.main-app {
  background: linear-gradient(90deg, color-mix(in srgb, var(--p-warn-500) 6%, transparent), transparent 40%);
  border-left: 2px solid color-mix(in srgb, var(--p-warn-500) 50%, transparent);
  padding-left: 10px;
}
.row.main-app:hover {
  background: linear-gradient(90deg, color-mix(in srgb, var(--p-warn-500) 12%, transparent), transparent 40%);
}
.thumb {
  width: 32px; height: 24px;
  flex-shrink: 0;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 3px;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden;
}
.thumb img {
  width: 100%; height: 100%; object-fit: cover;
}
.detail-thumb {
  width: 72px; height: 54px;
  flex-shrink: 0;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden;
}
.detail-thumb img { width: 100%; height: 100%; object-fit: cover; }
.mini-pill {
  font-size: 8px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.04em;
  padding: 1px 5px; border-radius: 3px;
  margin-left: 6px;
}
.linked-pill { background: color-mix(in srgb, var(--p-accent-400) 14%, transparent); color: var(--p-accent-400); }
.unknown-pill { background: var(--p-surface-100); color: var(--p-text-muted-color); border: 1px solid var(--p-content-border-color); }
.main-pill { background: color-mix(in srgb, var(--p-danger-500) 14%, transparent); color: var(--p-danger-500); }

.kind-pill.linked { background: color-mix(in srgb, var(--p-accent-400) 15%, transparent); color: var(--p-accent-400); }
.kind-pill.unknown { background: var(--p-surface-100); color: var(--p-text-muted-color); }
.kind-pill.main { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent); color: var(--p-danger-500); }

.detail-thumb.main { border-color: color-mix(in srgb, var(--p-danger-500) 40%, transparent); background: color-mix(in srgb, var(--p-danger-500) 5%, transparent); }
.detail-thumb { position: relative; }
.detail-thumb.busy { border-color: var(--p-primary-color); }
.detail-thumb.zoomable { cursor: zoom-in; transition: border-color 0.12s; }
.detail-thumb.zoomable:hover { border-color: var(--p-primary-color); }
.thumb-overlay {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--p-primary-color) 25%, transparent);
  color: var(--p-primary-color);
}

.zoom-overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0,0,0,0.85);
  display: flex; align-items: center; justify-content: center;
  padding: 32px;
  cursor: zoom-out;
}
.zoom-image {
  max-width: 100%; max-height: 100%;
  object-fit: contain;
  border-radius: 4px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.5);
  cursor: default;
}
.zoom-close {
  position: absolute; top: 16px; right: 16px;
  width: 36px; height: 36px;
  background: rgba(0,0,0,0.5);
  color: var(--p-text-color);
  border: 1px solid var(--kp-border);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer;
}
.zoom-close:hover { background: rgba(0,0,0,0.7); }

.origin-strip {
  display: flex; align-items: center; gap: 6px;
  font-size: 10px;
  padding: 5px 8px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--p-accent-400) 8%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-accent-400) 20%, transparent);
  color: var(--p-accent-400);
}
.origin-info {
  display: flex; align-items: center; gap: 8px;
  flex-wrap: wrap;
}
.origin-label { font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; font-size: 9px; opacity: 0.85; }
.origin-path { color: var(--p-text-color); }
.origin-repo { color: var(--p-text-color); opacity: 0.85; }
.origin-sha { color: var(--p-text-muted-color); opacity: 0.7; }
.origin-time { color: var(--p-text-muted-color); opacity: 0.7; font-size: 9px; }
.rinfo { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.rtitle {
  font-size: 12px; font-weight: 600;
  color: var(--p-text-color);
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.rmeta { font-size: 10px; color: var(--p-text-muted-color); }
.mono { font-family: ui-monospace, monospace; }

.built-badge {
  font-size: 9px; font-family: ui-monospace, monospace;
  padding: 1px 5px; border-radius: 3px;
  flex-shrink: 0;
}
.built-badge.ok { background: color-mix(in srgb, var(--p-success-500) 12%, transparent); color: var(--p-success-500); }
.built-badge.dim { background: var(--p-surface-100); color: var(--p-text-muted-color); opacity: 0.6; }

.rh {
  width: 4px; cursor: col-resize; flex-shrink: 0;
  border-left: 1px solid var(--p-content-border-color);
}
.rh:hover { background: var(--p-primary-color); opacity: 0.25; }

.detail-head {
  padding: 16px 20px 12px;
  border-bottom: 1px solid var(--p-content-border-color);
}

.kind-pill {
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.05em;
  padding: 2px 7px; border-radius: 3px;
}
.kind-pill.app { background: color-mix(in srgb, var(--p-info-500) 15%, transparent); color: var(--p-info-500); }
.kind-pill.widget { background: color-mix(in srgb, var(--p-success-500) 15%, transparent); color: var(--p-success-500); }
.kind-pill.kit { background: color-mix(in srgb, var(--p-accent-500) 15%, transparent); color: var(--p-accent-500); }
.version-pill {
  font-size: 9px; font-family: ui-monospace, monospace;
  padding: 2px 6px; border-radius: 3px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 10px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--p-content-border-color);
}
.stat {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  padding: 8px 10px;
}
.stat .k {
  font-size: 9px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--p-text-muted-color);
  margin-bottom: 3px;
}
.stat .v {
  font-size: 11px; color: var(--p-text-color);
  word-break: break-all;
}
.stat .v.mono { font-family: ui-monospace, monospace; font-size: 10px; }

.section {
  padding: 16px 20px;
  border-bottom: 1px solid var(--p-content-border-color);
}
.section:last-child { border-bottom: 0; }
.section-title {
  display: flex; align-items: center; gap: 6px;
  font-size: 10px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--p-text-muted-color);
  margin-bottom: 10px;
}
.section-title .count {
  font-size: 9px;
  padding: 1px 5px; border-radius: 3px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.section-title .mono-hint {
  font-family: ui-monospace, monospace;
  font-size: 9px; font-weight: 400;
  text-transform: none; letter-spacing: 0;
  margin-left: auto; opacity: 0.6;
}
.inline-new {
  margin-left: auto;
  display: inline-flex; align-items: center; gap: 3px;
  font-size: 9px; font-weight: 600;
  padding: 2px 6px; border-radius: 3px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-color); cursor: pointer;
  text-transform: none; letter-spacing: 0;
}
.inline-new:hover { background: var(--p-surface-200); }

.md-wrap {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 5px;
  padding: 12px 14px;
}

/* Build runs */
.build-list { display: flex; flex-direction: column; gap: 4px; }
.build-row {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  overflow: hidden;
}
.build-row.exp { border-color: var(--p-surface-300); }
.build-head {
  display: flex; align-items: center;
  width: 100%;
  gap: 10px;
  padding: 7px 10px;
  background: transparent;
  border: 0;
  cursor: pointer;
  font-size: 10px;
  text-align: left;
}
.build-head:hover { background: var(--p-surface-100); }
.build-status {
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-size: 9px;
  flex-shrink: 0;
  min-width: 52px;
}
.build-cmd {
  flex: 1; min-width: 0;
  color: var(--p-text-color);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.build-img {
  color: var(--p-text-muted-color);
  opacity: 0.7;
  font-size: 9px;
  flex-shrink: 0;
}
.build-trigger {
  font-size: 9px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  padding: 1px 5px;
  border-radius: 3px;
  flex-shrink: 0;
}
.build-trigger.user { background: color-mix(in srgb, var(--p-info-500) 12%, transparent); color: var(--p-info-500); }
.build-trigger.agent { background: color-mix(in srgb, var(--p-accent-400) 12%, transparent); color: var(--p-accent-400); }
.build-trigger.session { background: color-mix(in srgb, var(--p-success-500) 12%, transparent); color: var(--p-success-500); }
.build-time, .build-dur {
  font-size: 9px;
  color: var(--p-text-muted-color);
  flex-shrink: 0;
}
.build-body {
  border-top: 1px dashed var(--p-surface-200);
  padding: 8px 12px;
  background: var(--p-surface-100);
}
.build-error {
  display: flex; align-items: flex-start; gap: 6px;
  padding: 6px 10px;
  margin-bottom: 8px;
  border-radius: 3px;
  background: color-mix(in srgb, var(--p-danger-500) 8%, transparent);
  color: var(--p-danger-500);
  font-size: 10px;
  font-family: ui-monospace, monospace;
}
.build-log {
  font-family: ui-monospace, monospace;
  font-size: 10px;
  line-height: 1.5;
  max-height: 300px;
  overflow-y: auto;
  background: var(--p-surface-0);
  border: 1px solid var(--p-content-border-color);
  border-radius: 3px;
  padding: 6px 8px;
}
.log-line {
  display: flex; gap: 6px;
  color: var(--p-text-color);
}
.log-line.stderr { color: var(--p-danger-500); }
.log-line.system { color: var(--p-text-muted-color); opacity: 0.8; }
.log-stream {
  width: 10px;
  flex-shrink: 0;
  opacity: 0.5;
  text-align: center;
}
.log-text { flex: 1; min-width: 0; word-break: break-all; }

.empty-state {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  padding: 60px 20px;
  font-size: 12px;
  color: var(--p-text-muted-color);
}
.empty-line {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px;
  color: var(--p-text-muted-color);
  padding: 12px 0;
}
</style>
