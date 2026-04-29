<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch, shallowRef } from 'vue'
import * as monaco from 'monaco-editor'
import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker'

self.MonacoEnvironment = {
  getWorker: () => new editorWorker(),
}

const props = defineProps<{
  baseline: string
  current: string
  language?: string
}>()

const container = ref<HTMLElement | null>(null)
const editor = shallowRef<monaco.editor.IStandaloneDiffEditor | null>(null)
const originalModel = shallowRef<monaco.editor.ITextModel | null>(null)
const modifiedModel = shallowRef<monaco.editor.ITextModel | null>(null)
const themeDefined = ref(false)

function defineTheme() {
  if (themeDefined.value) return
  monaco.editor.defineTheme('keeper-dark', {
    base: 'vs-dark',
    inherit: true,
    rules: [
      { token: 'comment', foreground: '6a737d', fontStyle: 'italic' },
      { token: 'keyword', foreground: 'f59e0b' },
      { token: 'string', foreground: '4ade80' },
      { token: 'number', foreground: 'c084fc' },
      { token: 'type', foreground: '60a5fa' },
      { token: 'function', foreground: '2dd4bf' },
      { token: 'variable', foreground: 'e2e8f0' },
      { token: 'operator', foreground: 'f87171' },
    ],
    colors: {
      'editor.background': '#0c0e12',
      'editor.foreground': '#e2e8f0',
      'editor.lineHighlightBackground': '#14171e',
      'editor.selectionBackground': '#1e222c80',
      'editorCursor.foreground': '#f59e0b',
      'editorLineNumber.foreground': '#8b949e50',
      'editorLineNumber.activeForeground': '#8b949e',
      'editor.inactiveSelectionBackground': '#14171e',
      'editorIndentGuide.background': '#1e222c',
      'editorWidget.background': '#10131a',
      'editorWidget.border': '#1e222c',
      'diffEditor.insertedTextBackground': '#34d39920',
      'diffEditor.removedTextBackground': '#f8717120',
      'diffEditor.insertedLineBackground': '#34d39910',
      'diffEditor.removedLineBackground': '#f8717110',
    },
  })
  themeDefined.value = true
}

function disposeModels() {
  const prevOriginal = originalModel.value
  const prevModified = modifiedModel.value
  originalModel.value = null
  modifiedModel.value = null
  prevOriginal?.dispose()
  prevModified?.dispose()
}

function updateModels() {
  if (!editor.value) return
  const lang = props.language || 'plaintext'
  const prevOriginal = originalModel.value
  const prevModified = modifiedModel.value
  const nextOriginal = monaco.editor.createModel(props.baseline || '', lang)
  const nextModified = monaco.editor.createModel(props.current || '', lang)
  originalModel.value = nextOriginal
  modifiedModel.value = nextModified
  editor.value.setModel({ original: nextOriginal, modified: nextModified })
  prevOriginal?.dispose()
  prevModified?.dispose()
}

onMounted(() => {
  if (!container.value) return
  defineTheme()

  editor.value = monaco.editor.createDiffEditor(container.value, {
    theme: 'keeper-dark',
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

  updateModels()
})

watch(() => [props.baseline, props.current, props.language], updateModels)

onBeforeUnmount(() => {
  const e = editor.value
  editor.value = null
  e?.setModel(null)
  e?.dispose()
  disposeModels()
})
</script>

<template>
  <div ref="container" style="width: 100%; height: 100%; min-height: 200px; border-radius: 8px; overflow: hidden" />
</template>
