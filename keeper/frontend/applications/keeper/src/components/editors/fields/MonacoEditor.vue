<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch, shallowRef } from 'vue'
import * as monaco from 'monaco-editor'
import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker'

self.MonacoEnvironment = {
  getWorker: () => new editorWorker(),
}

const props = defineProps<{
  modelValue: string
  language?: string
  readonly?: boolean
  minHeight?: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const container = ref<HTMLElement | null>(null)
const editor = shallowRef<monaco.editor.IStandaloneCodeEditor | null>(null)

const keeperThemeDefined = ref(false)

function defineKeeperTheme() {
  if (keeperThemeDefined.value) return
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
      'input.background': '#14171e',
      'input.border': '#1e222c',
      'scrollbarSlider.background': '#1e222c80',
      'scrollbarSlider.hoverBackground': '#2a2f3a',
    },
  })
  keeperThemeDefined.value = true
}

onMounted(() => {
  if (!container.value) return
  defineKeeperTheme()

  editor.value = monaco.editor.create(container.value, {
    value: props.modelValue || '',
    language: props.language || 'lua',
    theme: 'keeper-dark',
    readOnly: props.readonly,
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

  editor.value.onDidChangeModelContent(() => {
    const val = editor.value?.getValue() || ''
    if (val !== props.modelValue) {
      emit('update:modelValue', val)
    }
  })
})

watch(() => props.modelValue, (newVal) => {
  if (editor.value && newVal !== editor.value.getValue()) {
    editor.value.setValue(newVal || '')
  }
})

watch(() => props.readonly, (val) => {
  editor.value?.updateOptions({ readOnly: val })
})

onBeforeUnmount(() => {
  editor.value?.dispose()
})
</script>

<template>
  <div ref="container" class="monaco-container" :style="{ minHeight: minHeight ? minHeight + 'px' : '100%' }"></div>
</template>

<style scoped>
.monaco-container {
  width: 100%;
  height: 100%;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid var(--p-content-border-color);
}
</style>
