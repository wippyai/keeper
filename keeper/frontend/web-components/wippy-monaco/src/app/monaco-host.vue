<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, shallowRef, useTemplateRef, watch, watchEffect } from 'vue'
import type * as Monaco from 'monaco-editor'
import { useComponentEvents, useComponentProps } from '../constants.ts'
import { bindHostTheme, bindShadowStylesheetContainer, getMonacoMainCss, loadMonaco, resolveThemeName, unbindHostTheme } from './monaco-loader.ts'

type Status =
  | { kind: 'loading' }
  | { kind: 'ready' }
  | { kind: 'error', message: string }

const props = useComponentProps()
const events = useComponentEvents()

const containerStyle = computed(() => {
  const minHeight = props.value?.['min-height']
  return minHeight && minHeight > 0 ? { minHeight: `${minHeight}px` } : undefined
})

const containerRef = useTemplateRef<HTMLElement>('container')
const status = ref<Status>({ kind: 'loading' })

// `shallowRef` because monaco editor instances are large and
// non-reactive — we only need identity tracking for cleanup.
const monacoRef = shallowRef<typeof Monaco | null>(null)
const editorRef = shallowRef<Monaco.editor.IStandaloneCodeEditor | null>(null)
const diffRef = shallowRef<Monaco.editor.IStandaloneDiffEditor | null>(null)
const originalModelRef = shallowRef<Monaco.editor.ITextModel | null>(null)
const modifiedModelRef = shallowRef<Monaco.editor.ITextModel | null>(null)

let themeObserver: MutationObserver | null = null
let darkMq: MediaQueryList | null = null
let darkMqHandler: (() => void) | null = null
let suppressChangeEmit = false
let releaseShadowBinding: (() => void) | null = null
// Element key used for the per-host theme override. The patched
// StandaloneThemeService keys its `_themeByHost` WeakMap on this element.
// For shadow-DOM mounts this is the WC element (the shadow root's host);
// for document mounts it's the container itself (with no per-host override
// effect — monaco falls back to the global theme).
let themeHostEl: Element | null = null

function resolveThemeHostEl(container: HTMLElement): Element {
  const root = container.getRootNode()
  return root instanceof ShadowRoot ? root.host : container
}

function currentMode(): 'editor' | 'diff' {
  return props.value.mode === 'diff' ? 'diff' : 'editor'
}

function applyResolvedTheme() {
  const monaco = monacoRef.value
  if (!monaco)
    return
  const container = containerRef.value
  if (!container)
    return
  // Recompute the theme — for auto mode this re-runs `applyAutoTheme`
  // which re-registers the per-host `keeper-auto-N` theme with fresh
  // values read from the current CSS variables — and re-bind via the
  // patched per-host setter so this WC re-renders without affecting any
  // other live `<wippy-monaco>` element.
  const hostEl = themeHostEl ?? resolveThemeHostEl(container)
  const themeName = resolveThemeName(monaco, props.value.theme, hostEl as HTMLElement)
  bindHostTheme(hostEl, themeName)
}

function watchThemeReactivity() {
  // Only auto-mode needs reactivity — fixed presets don't change.
  if (props.value.theme && props.value.theme !== 'auto')
    return
  const target = document.documentElement
  themeObserver = new MutationObserver(() => applyResolvedTheme())
  themeObserver.observe(target, { attributes: true, attributeFilter: ['data-theme', 'class'] })
  darkMq = window.matchMedia('(prefers-color-scheme: dark)')
  darkMqHandler = () => applyResolvedTheme()
  darkMq.addEventListener('change', darkMqHandler)
}

function disposeThemeReactivity() {
  themeObserver?.disconnect()
  themeObserver = null
  if (darkMq && darkMqHandler) {
    darkMq.removeEventListener('change', darkMqHandler)
  }
  darkMq = null
  darkMqHandler = null
}

function disposeAll() {
  disposeThemeReactivity()
  editorRef.value?.dispose()
  editorRef.value = null
  const e = diffRef.value
  diffRef.value = null
  e?.setModel(null)
  e?.dispose()
  originalModelRef.value?.dispose()
  modifiedModelRef.value?.dispose()
  originalModelRef.value = null
  modifiedModelRef.value = null
  releaseShadowBinding?.()
  releaseShadowBinding = null
  // Clear the per-host theme override so the host's WeakMap entry can be
  // GC'd along with the element when it leaves the DOM.
  if (themeHostEl)
    unbindHostTheme(themeHostEl)
  themeHostEl = null
}

async function mountEditor(monaco: typeof Monaco, container: HTMLElement) {
  themeHostEl = resolveThemeHostEl(container)
  const themeName = resolveThemeName(monaco, props.value.theme, themeHostEl as HTMLElement)
  // Bind BEFORE `monaco.editor.create` so the initial render of this
  // editor's style element picks up the per-host override on first paint.
  bindHostTheme(themeHostEl, themeName)
  editorRef.value = monaco.editor.create(container, {
    value: props.value.value || '',
    language: props.value.language || 'plaintext',
    theme: themeName,
    readOnly: props.value.readonly === true,
    minimap: { enabled: false },
    fontSize: 12,
    lineHeight: 18,
    padding: { top: 8, bottom: 8 },
    scrollBeyondLastLine: false,
    automaticLayout: true,
    tabSize: 2,
    renderLineHighlight: 'line',
    overviewRulerBorder: false,
    hideCursorInOverviewRuler: true,
    overviewRulerLanes: 0,
    scrollbar: {
      verticalScrollbarSize: 6,
      horizontalScrollbarSize: 6,
    },
    lineNumbers: 'on',
    lineDecorationsWidth: 0,
    lineNumbersMinChars: 3,
    glyphMargin: false,
    folding: true,
    wordWrap: 'on',
    contextmenu: false,
  })

  editorRef.value.onDidChangeModelContent(() => {
    if (suppressChangeEmit)
      return
    const value = editorRef.value?.getValue() ?? ''
    events('change', { value })
  })
}

async function mountDiff(monaco: typeof Monaco, container: HTMLElement) {
  themeHostEl = resolveThemeHostEl(container)
  const themeName = resolveThemeName(monaco, props.value.theme, themeHostEl as HTMLElement)
  bindHostTheme(themeHostEl, themeName)
  diffRef.value = monaco.editor.createDiffEditor(container, {
    theme: themeName,
    readOnly: true,
    minimap: { enabled: false },
    fontSize: 12,
    lineHeight: 18,
    padding: { top: 8, bottom: 8 },
    scrollBeyondLastLine: false,
    automaticLayout: true,
    renderSideBySide: true,
    enableSplitViewResizing: true,
    renderOverviewRuler: false,
    overviewRulerBorder: false,
    renderIndicators: true,
    originalEditable: false,
  })
  rebuildDiffModels(monaco)
}

function rebuildDiffModels(monaco: typeof Monaco) {
  const diff = diffRef.value
  if (!diff)
    return
  const lang = props.value.language || 'plaintext'
  const prevOriginal = originalModelRef.value
  const prevModified = modifiedModelRef.value
  const nextOriginal = monaco.editor.createModel(props.value.baseline || '', lang)
  const nextModified = monaco.editor.createModel(props.value.current || '', lang)
  originalModelRef.value = nextOriginal
  modifiedModelRef.value = nextModified
  diff.setModel({ original: nextOriginal, modified: nextModified })
  prevOriginal?.dispose()
  prevModified?.dispose()
}

function injectMonacoCssIntoShadow(container: HTMLElement) {
  // Monaco's `editor.main.css` (positioning, line layout, scrollbar visuals,
  // syntax-token classes) would normally be injected into `document.head` by
  // Vite's CSS handling of monaco's side-effect `.css` imports. Our
  // `wippy-monaco-strip-css-imports` Vite plugin (see vite.config.ts) strips
  // those imports so nothing leaks into `document.head`; here we inject the
  // pre-built `editor.main.css` into the shadow root so the rules actually
  // reach `.monaco-editor` and its descendants. Without this, `.monaco-editor`
  // is `position: static` and its `position: absolute` children land relative
  // to the viewport instead of the editor — see
  // app-template/frontend/docs/web-component-loading.md.
  const root = container.getRootNode()
  if (!(root instanceof ShadowRoot))
    return
  if (root.querySelector('style[data-wippy-monaco-css]'))
    return
  const cssText = getMonacoMainCss()
  if (!cssText)
    return
  const style = document.createElement('style')
  style.setAttribute('data-wippy-monaco-css', '')
  style.textContent = cssText
  root.appendChild(style)
}

onMounted(async () => {
  const container = containerRef.value
  if (!container) {
    status.value = { kind: 'error', message: 'monaco container missing' }
    return
  }
  try {
    const monaco = await loadMonaco()
    injectMonacoCssIntoShadow(container)
    // Bind monaco's default stylesheet container to our shadow root so the
    // theme rules `monaco.editor.setTheme` writes (and any later widget
    // style additions) land in the shadow root instead of leaking into
    // `document.head`. Released in `disposeAll` on unmount.
    const root = container.getRootNode()
    if (root instanceof ShadowRoot)
      releaseShadowBinding = bindShadowStylesheetContainer(root)
    monacoRef.value = monaco
    if (currentMode() === 'diff')
      await mountDiff(monaco, container)
    else
      await mountEditor(monaco, container)
    watchThemeReactivity()
    status.value = { kind: 'ready' }
    events('load', undefined)
  }
  catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    status.value = { kind: 'error', message }
    events('error', { message, error: err })
  }
})

watchEffect(() => {
  // Editor-mode value sync (parent → editor). Suppress the change event
  // we'd otherwise emit back when the parent sets the same value.
  const editor = editorRef.value
  if (!editor)
    return
  const next = props.value.value ?? ''
  if (editor.getValue() !== next) {
    suppressChangeEmit = true
    editor.setValue(next)
    suppressChangeEmit = false
  }
})

watchEffect(() => {
  const editor = editorRef.value
  if (!editor)
    return
  editor.updateOptions({ readOnly: props.value.readonly === true })
})

watchEffect(() => {
  const monaco = monacoRef.value
  const editor = editorRef.value
  const diff = diffRef.value
  const lang = props.value.language || 'plaintext'
  if (monaco && editor) {
    const model = editor.getModel()
    if (model && model.getLanguageId() !== lang)
      monaco.editor.setModelLanguage(model, lang)
  }
  if (monaco && diff) {
    const m = diff.getModel()
    if (m) {
      if (m.original.getLanguageId() !== lang)
        monaco.editor.setModelLanguage(m.original, lang)
      if (m.modified.getLanguageId() !== lang)
        monaco.editor.setModelLanguage(m.modified, lang)
    }
  }
})

watch(() => [props.value.baseline, props.value.current], () => {
  const monaco = monacoRef.value
  if (!monaco)
    return
  if (currentMode() === 'diff')
    rebuildDiffModels(monaco)
})

watch(() => props.value.theme, () => {
  // Switching to/from auto: tear down + re-arm the reactivity wires.
  disposeThemeReactivity()
  applyResolvedTheme()
  watchThemeReactivity()
})

onBeforeUnmount(() => {
  disposeAll()
  events('unload', undefined)
})
</script>

<template>
  <div class="monaco-host" :style="containerStyle">
    <div
      v-if="status.kind === 'loading'"
      class="monaco-status"
      role="status"
    >
      Loading editor…
    </div>
    <div
      v-else-if="status.kind === 'error'"
      class="monaco-status error"
      role="alert"
    >
      {{ status.message }}
    </div>
    <div ref="container" class="monaco-container" v-show="status.kind === 'ready'" />
  </div>
</template>
