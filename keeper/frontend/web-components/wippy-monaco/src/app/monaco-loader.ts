/**
 * Lazy monaco-editor loader.
 *
 * `import('monaco-editor')` is dynamically imported, which Vite code-splits
 * into its own chunk. The chunk is fetched the first time any
 * `<wippy-monaco>` instance mounts in the page; module-level promise
 * caching means subsequent instances share the same fetch.
 *
 * Web workers (editor / json / css / html / ts) load on-demand, driven by
 * monaco itself via `MonacoEnvironment.getWorker`. They each ship in their
 * own Vite-emitted worker chunk.
 */
import type * as Monaco from 'monaco-editor'

let monacoPromise: Promise<typeof Monaco> | null = null

export function loadMonaco(): Promise<typeof Monaco> {
  if (!monacoPromise) {
    monacoPromise = (async () => {
      // Workers must be wired BEFORE the first model creation so monaco
      // doesn't fall back to its main-thread tokenizer.
      const [
        EditorWorker,
        JsonWorker,
        CssWorker,
        HtmlWorker,
        TsWorker,
      ] = await Promise.all([
        import('monaco-editor/esm/vs/editor/editor.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/json/json.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/css/css.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/html/html.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/typescript/ts.worker?worker').then(m => m.default),
      ])

      ;(self as unknown as { MonacoEnvironment: { getWorker: (id: string, label: string) => Worker } }).MonacoEnvironment = {
        getWorker(_id, label) {
          switch (label) {
            case 'json':
              return new JsonWorker()
            case 'css':
            case 'scss':
            case 'less':
              return new CssWorker()
            case 'html':
            case 'handlebars':
            case 'razor':
              return new HtmlWorker()
            case 'typescript':
            case 'javascript':
              return new TsWorker()
            default:
              return new EditorWorker()
          }
        },
      }

      const monaco = await import('monaco-editor')
      registerThemes(monaco)
      return monaco
    })()
  }
  return monacoPromise
}

const KEEPER_DARK = 'keeper-dark'
const KEEPER_LIGHT = 'keeper-light'
const KEEPER_AUTO = 'keeper-auto'

let themesRegistered = false

function registerThemes(monaco: typeof Monaco) {
  if (themesRegistered)
    return
  // keeper-dark — preserved verbatim from the original keeper MonacoEditor.vue
  // / DiffViewer.vue palette so the visual identity carries forward.
  monaco.editor.defineTheme(KEEPER_DARK, {
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
      'diffEditor.insertedTextBackground': '#34d39920',
      'diffEditor.removedTextBackground': '#f8717120',
      'diffEditor.insertedLineBackground': '#34d39910',
      'diffEditor.removedLineBackground': '#f8717110',
    },
  })

  // keeper-light — light-mode counterpart with the same accent palette.
  monaco.editor.defineTheme(KEEPER_LIGHT, {
    base: 'vs',
    inherit: true,
    rules: [
      { token: 'comment', foreground: '6a737d', fontStyle: 'italic' },
      { token: 'keyword', foreground: 'b45309' },
      { token: 'string', foreground: '15803d' },
      { token: 'number', foreground: '7e22ce' },
      { token: 'type', foreground: '1d4ed8' },
      { token: 'function', foreground: '0d9488' },
      { token: 'variable', foreground: '1e293b' },
      { token: 'operator', foreground: 'b91c1c' },
    ],
    colors: {
      'editor.background': '#ffffff',
      'editor.foreground': '#1e293b',
      'editor.lineHighlightBackground': '#f4f4f5',
      'editor.selectionBackground': '#bfdbfe',
      'editorCursor.foreground': '#b45309',
      'editorLineNumber.foreground': '#a1a1aa',
      'editorLineNumber.activeForeground': '#52525b',
      'editor.inactiveSelectionBackground': '#e4e4e7',
      'editorIndentGuide.background': '#e4e4e7',
      'editorWidget.background': '#ffffff',
      'editorWidget.border': '#e4e4e7',
      'input.background': '#ffffff',
      'input.border': '#e4e4e7',
      'scrollbarSlider.background': '#a1a1aa80',
      'scrollbarSlider.hoverBackground': '#71717a',
      'diffEditor.insertedTextBackground': '#16a34a20',
      'diffEditor.removedTextBackground': '#dc262620',
      'diffEditor.insertedLineBackground': '#16a34a10',
      'diffEditor.removedLineBackground': '#dc262610',
    },
  })

  themesRegistered = true
}

/**
 * Read app theme tokens off `host` (the WC element) and update the dynamic
 * `keeper-auto` theme. CSS custom properties cross the shadow-DOM
 * boundary, so we get the same `--p-*` values the outer page declared at
 * `:root`.
 */
export function applyAutoTheme(monaco: typeof Monaco, host: HTMLElement): string {
  const cs = getComputedStyle(host)
  const v = (name: string, fallback: string): string => {
    const raw = cs.getPropertyValue(name).trim()
    return raw || fallback
  }
  // Detect light vs dark from the current --p-content-background luminance.
  const bg = v('--p-content-background', '#1c1a19')
  const isDark = isDarkColor(bg)

  monaco.editor.defineTheme(KEEPER_AUTO, {
    base: isDark ? 'vs-dark' : 'vs',
    inherit: true,
    rules: [],
    colors: {
      'editor.background': bg,
      'editor.foreground': v('--p-text-color', isDark ? '#fafafa' : '#18181b'),
      'editor.lineHighlightBackground': v('--p-surface-100', isDark ? '#2b2927' : '#f4f4f5'),
      'editor.selectionBackground': isDark ? '#1e222c80' : '#bfdbfe',
      'editorCursor.foreground': v('--p-primary-500', '#f59e0b'),
      'editorLineNumber.foreground': v('--p-text-muted-color', isDark ? '#a1a1aa' : '#a1a1aa'),
      'editorLineNumber.activeForeground': v('--p-text-color', isDark ? '#fafafa' : '#18181b'),
      'editor.inactiveSelectionBackground': v('--p-surface-100', isDark ? '#2b2927' : '#e4e4e7'),
      'editorIndentGuide.background': v('--p-surface-200', isDark ? '#403e3c' : '#e4e4e7'),
      'editorWidget.background': v('--p-surface-100', isDark ? '#2b2927' : '#ffffff'),
      'editorWidget.border': v('--p-content-border-color', isDark ? '#403e3c' : '#e4e4e7'),
      'input.background': v('--p-content-background', bg),
      'input.border': v('--p-content-border-color', isDark ? '#403e3c' : '#e4e4e7'),
      'scrollbarSlider.background': isDark ? '#1e222c80' : '#a1a1aa80',
      'scrollbarSlider.hoverBackground': isDark ? '#2a2f3a' : '#71717a',
      'diffEditor.insertedTextBackground': isDark ? '#34d39920' : '#16a34a20',
      'diffEditor.removedTextBackground': isDark ? '#f8717120' : '#dc262620',
      'diffEditor.insertedLineBackground': isDark ? '#34d39910' : '#16a34a10',
      'diffEditor.removedLineBackground': isDark ? '#f8717110' : '#dc262610',
    },
  })
  return KEEPER_AUTO
}

function isDarkColor(input: string): boolean {
  // Accept #rgb, #rrggbb, rgb(), rgba(); fall back to "dark" for anything
  // unparseable so the auto theme errs toward the most common keeper UI.
  const hex = input.startsWith('#') ? input.slice(1) : null
  if (hex) {
    const expanded = hex.length === 3
      ? hex.split('').map(c => c + c).join('')
      : hex.length >= 6 ? hex.slice(0, 6) : null
    if (expanded) {
      const r = parseInt(expanded.slice(0, 2), 16)
      const g = parseInt(expanded.slice(2, 4), 16)
      const b = parseInt(expanded.slice(4, 6), 16)
      return luminance(r, g, b) < 0.5
    }
  }
  const m = /rgba?\(\s*(\d+)[^\d]+(\d+)[^\d]+(\d+)/.exec(input)
  if (m)
    return luminance(+m[1]!, +m[2]!, +m[3]!) < 0.5
  return true
}

function luminance(r: number, g: number, b: number): number {
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
}

export function resolveThemeName(
  monaco: typeof Monaco,
  theme: 'auto' | 'keeper-dark' | 'keeper-light' | undefined,
  host: HTMLElement,
): string {
  switch (theme) {
    case 'keeper-dark': return KEEPER_DARK
    case 'keeper-light': return KEEPER_LIGHT
    default: return applyAutoTheme(monaco, host)
  }
}
