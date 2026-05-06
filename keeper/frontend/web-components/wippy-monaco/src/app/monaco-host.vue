<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, shallowRef, useTemplateRef, watch, watchEffect } from 'vue'
import type * as Monaco from 'monaco-editor'
import { useComponentEvents, useComponentProps } from '../constants.ts'
import { loadMonaco, resolveThemeName } from './monaco-loader.ts'

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

function currentMode(): 'editor' | 'diff' {
  return props.value.mode === 'diff' ? 'diff' : 'editor'
}

function applyResolvedTheme() {
  const monaco = monacoRef.value
  if (!monaco)
    return
  const host = containerRef.value
  if (!host)
    return
  const themeName = resolveThemeName(monaco, props.value.theme, host)
  monaco.editor.setTheme(themeName)
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
}

async function mountEditor(monaco: typeof Monaco, container: HTMLElement) {
  const themeName = resolveThemeName(monaco, props.value.theme, container)
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
  const themeName = resolveThemeName(monaco, props.value.theme, container)
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

onMounted(async () => {
  const container = containerRef.value
  if (!container) {
    status.value = { kind: 'error', message: 'monaco container missing' }
    return
  }
  try {
    const monaco = await loadMonaco()
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
