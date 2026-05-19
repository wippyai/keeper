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

// Monaco ships its main stylesheet as `editor.main.css` (~300 KB). When
// monaco-editor evaluates inside a normal page it injects these rules into
// `document.head` via Vite's CSS-in-JS — but a web component lives in a
// shadow root, where those styles do NOT reach. Without the CSS,
// `.monaco-editor` falls back to `position: static`, and the inner
// `.monaco-scrollable-element` / `.overflow-guard` (all `position: absolute`)
// end up positioned relative to the viewport instead of the editor, so the
// textarea and the rendered editor view end up in completely different
// places.
//
// Vite plugin `wippy-monaco-strip-css-imports` (see vite.config.ts) replaces
// every monaco-editor CSS side-effect import with an empty module, so Vite
// no longer auto-injects monaco's static CSS into `document.head`. We then
// fetch the pre-built `editor.main.css` lazily (via dynamic import + Vite
// `?inline`) inside `loadMonaco()` so it lives in the lazy monaco chunk,
// not the eager WC entry chunk, and inject it into the shadow root once
// per shadow tree (see monaco-host.vue's `injectMonacoCssIntoShadow`).

let monacoCssText: string | null = null
export function getMonacoMainCss(): string | null {
  return monacoCssText
}

// --- Shadow-DOM stylesheet container binding ---
// Monaco's runtime CSS that lands via `createStyleSheet(mainWindow.document.head, ...)`
// in `monaco-editor/esm/vs/base/browser/domStylesheets.js`. We apply a
// patch-package patch (see `patches/monaco-editor+0.55.1.patch`) that adds a
// `setDefaultStylesheetContainer` setter. Each `<wippy-monaco>` instance
// binds the default to its own shadow root on mount and releases on unmount,
// so monaco's runtime styles land where they actually apply.
//
// Single-default limitation: with two editors in two different shadow roots
// mounted at once, only the most recently bound shadow root receives further
// runtime style additions from this entry point. Theme CSS — by far the
// biggest source of runtime styles — is per-host via the separate
// `setHostTheme` patch (see `bindHostTheme` below), so the practical impact
// of this single-default is limited to widget styles (suggest, hover, find,
// sash); accepting that limitation for now.
let setDefaultStylesheetContainer: ((c: Node | null) => void) | null = null
let activeShadowRefs = 0

export function bindShadowStylesheetContainer(shadow: ShadowRoot): () => void {
  if (!setDefaultStylesheetContainer) {
    // loadMonaco() resolves before any consumer calls this, so the setter is
    // always populated. If we get here, monaco-host.vue's lifecycle changed
    // and called us out of order — fail loud in dev.
    // eslint-disable-next-line no-console
    console.warn('[wippy-monaco] bindShadowStylesheetContainer called before loadMonaco resolved — runtime CSS will leak to document.head')
    return () => {}
  }
  setDefaultStylesheetContainer(shadow)
  activeShadowRefs++
  let released = false
  return () => {
    if (released)
      return
    released = true
    activeShadowRefs--
    if (activeShadowRefs === 0)
      setDefaultStylesheetContainer?.(null)
    // else leave the most recent binding in place — last-mount wins
  }
}

// --- Per-host theme binding ---
// Patch adds `setHostTheme(host, themeName)` to monaco's
// `StandaloneThemeService` (see `patches/monaco-editor+0.55.1.patch`). It
// stores the theme override in a `WeakMap<Element, StandaloneTheme>` keyed
// by the WC host element. `_updateCSS` then renders each style element
// against its host's override (falling back to the global theme set via
// `monaco.editor.setTheme`).
//
// With this, two `<wippy-monaco>` elements with different `theme=` props in
// the same page each render with their own theme — no more last-create-wins
// monaco singleton-theme footgun.
let setHostThemeFn: ((host: Element, themeName: string | null) => void) | null = null

export function bindHostTheme(host: Element, themeName: string): void {
  if (!setHostThemeFn) {
    // loadMonaco() resolves before any consumer calls this.
    // eslint-disable-next-line no-console
    console.warn('[wippy-monaco] bindHostTheme called before loadMonaco resolved — theme will fall back to global setTheme')
    return
  }
  setHostThemeFn(host, themeName)
}

export function unbindHostTheme(host: Element): void {
  setHostThemeFn?.(host, null)
}

let monacoPromise: Promise<typeof Monaco> | null = null

export function loadMonaco(): Promise<typeof Monaco> {
  if (!monacoPromise) {
    monacoPromise = (async () => {
      // Workers must be wired BEFORE the first model creation so monaco
      // doesn't fall back to its main-thread tokenizer. CSS is fetched in
      // parallel so it lands in the lazy monaco chunk, not the eager WC
      // entry chunk.
      const [
        cssModule,
        domStylesheets,
        themeService,
        EditorWorker,
        JsonWorker,
        CssWorker,
        HtmlWorker,
        TsWorker,
      ] = await Promise.all([
        import('monaco-editor/min/vs/editor/editor.main.css?inline').then(m => m.default),
        // Patches add exports to these monaco internals — type augmentations
        // live in `src/types/monaco-stylesheets-patch.d.ts`.
        import('monaco-editor/esm/vs/base/browser/domStylesheets.js'),
        import('monaco-editor/esm/vs/editor/standalone/browser/standaloneThemeService.js'),
        import('monaco-editor/esm/vs/editor/editor.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/json/json.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/css/css.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/html/html.worker?worker').then(m => m.default),
        import('monaco-editor/esm/vs/language/typescript/ts.worker?worker').then(m => m.default),
      ])
      monacoCssText = cssModule
      setDefaultStylesheetContainer = domStylesheets.setDefaultStylesheetContainer
      setHostThemeFn = themeService.setHostTheme

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
// The auto theme is per-host: each `<wippy-monaco>` reads its own CSS
// variables and registers a uniquely-named theme via `defineTheme`, so two
// instances in different host contexts (e.g. one in a dark panel, one in
// a light panel) don't overwrite each other's auto theme definition.
const KEEPER_AUTO_PREFIX = 'keeper-auto-'
const autoThemeNames = new WeakMap<Element, string>()
let autoThemeCounter = 0
function autoThemeNameFor(hostElement: Element): string {
  let name = autoThemeNames.get(hostElement)
  if (!name) {
    name = `${KEEPER_AUTO_PREFIX}${++autoThemeCounter}`
    autoThemeNames.set(hostElement, name)
  }
  return name
}

// Shared keeper token palettes — referenced by both the fixed
// keeper-dark/keeper-light presets AND by the auto theme, so the syntax
// identity is consistent across all three modes.
const KEEPER_DARK_TOKEN_RULES = [
  { token: 'comment', foreground: '6a737d', fontStyle: 'italic' },
  { token: 'keyword', foreground: 'f59e0b' },
  { token: 'string', foreground: '4ade80' },
  { token: 'number', foreground: 'c084fc' },
  { token: 'type', foreground: '60a5fa' },
  { token: 'function', foreground: '2dd4bf' },
  { token: 'variable', foreground: 'e2e8f0' },
  { token: 'operator', foreground: 'f87171' },
] as const

const KEEPER_LIGHT_TOKEN_RULES = [
  { token: 'comment', foreground: '6a737d', fontStyle: 'italic' },
  { token: 'keyword', foreground: 'b45309' },
  { token: 'string', foreground: '15803d' },
  { token: 'number', foreground: '7e22ce' },
  { token: 'type', foreground: '1d4ed8' },
  { token: 'function', foreground: '0d9488' },
  { token: 'variable', foreground: '1e293b' },
  { token: 'operator', foreground: 'b91c1c' },
] as const

let themesRegistered = false

function registerThemes(monaco: typeof Monaco) {
  if (themesRegistered)
    return
  // keeper-dark / keeper-light — preserved palette from the original keeper
  // MonacoEditor.vue / DiffViewer.vue so the visual identity carries forward.
  //
  // The hex literals below are DELIBERATE FIXED IDENTITY, not theme drift:
  // monaco's `defineTheme` requires concrete colors at registration time and
  // these are the keeper sub-app's branded editor look. They match the same
  // intentional-divergence rationale as the 4-way warm-grey configOverrides
  // in CLAUDE.md §"Intentional patterns". Do not migrate to var(--p-*) reads
  // unless you also re-derive the patch's `_themeByHost` mapping.
  //
  // Both keeper-dark and keeper-light intentionally inherit from the same
  // base (`vs`) with identical rule lists. This produces matching
  // `tokenTheme.getColorMap()` orderings across all keeper themes, so
  // multiple `<wippy-monaco>` elements with different themes share the
  // same `mtkN`→token-kind mapping — required for the per-host theme
  // patch (see `patches/monaco-editor+0.55.1.patch`) to render correctly
  // when monaco's tokenization registry (which is global) tags tokens
  // against whatever theme was set last.
  monaco.editor.defineTheme(KEEPER_DARK, {
    base: 'vs',
    inherit: true,
    rules: [...KEEPER_DARK_TOKEN_RULES],
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
    rules: [...KEEPER_LIGHT_TOKEN_RULES],
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
 * Read app theme tokens off `host` (the WC element) and update a per-host
 * auto theme. CSS custom properties cross the shadow-DOM boundary, so we
 * get the same `--p-*` values the outer page declared at `:root`. Both
 * chrome colors (background/foreground/widget borders) AND syntax-token
 * colors (keyword/string/number/etc.) follow the host's light-vs-dark
 * state — chrome comes from the host's `--p-*` palette, tokens reuse the
 * same keeper-dark / keeper-light palettes the explicit presets use.
 * Re-themes live on `data-theme` / `class` mutations and
 * `prefers-color-scheme` flips (see `watchThemeReactivity` in
 * monaco-host.vue).
 *
 * The theme is named uniquely per host (`keeper-auto-N`) so multiple
 * `<wippy-monaco>` elements in auto mode each maintain their own palette
 * without overwriting one another via `monaco.editor.defineTheme`.
 */
export function applyAutoTheme(monaco: typeof Monaco, host: HTMLElement): string {
  const themeName = autoThemeNameFor(host)
  const cs = getComputedStyle(host)
  // Per-var fallbacks below are host-less dev safety nets — fire only when the
  // host hasn't injected the keeper theme bundle (standalone preview / unit
  // tests). Monaco needs concrete hex at registration. See theming.md
  // §"Defensive fallbacks".
  const v = (name: string, fallback: string): string => {
    const raw = cs.getPropertyValue(name).trim()
    return raw || fallback
  }
  // Detect light vs dark from the current --p-content-background luminance.
  const bg = v('--p-content-background', '#1c1a19')
  const isDark = isDarkColor(bg)

  monaco.editor.defineTheme(themeName, {
    // Match the base of keeper-dark / keeper-light so all keeper themes
    // produce identical mtkN→kind orderings in their colorMaps — required
    // by the per-host theme patch.
    base: 'vs',
    inherit: true,
    rules: [...(isDark ? KEEPER_DARK_TOKEN_RULES : KEEPER_LIGHT_TOKEN_RULES)],
    colors: {
      'editor.background': bg,
      'editor.foreground': v('--p-text-color', isDark ? '#fafafa' : '#18181b'),
      'editor.lineHighlightBackground': v('--p-content-hover-background', isDark ? '#2b2927' : '#f4f4f5'),
      'editor.selectionBackground': isDark ? '#1e222c80' : '#bfdbfe',
      'editorCursor.foreground': v('--p-primary-500', '#f59e0b'),
      'editorLineNumber.foreground': v('--p-text-muted-color', isDark ? '#a1a1aa' : '#a1a1aa'),
      'editorLineNumber.activeForeground': v('--p-text-color', isDark ? '#fafafa' : '#18181b'),
      'editor.inactiveSelectionBackground': v('--p-content-hover-background', isDark ? '#2b2927' : '#f4f4f5'),
      'editorIndentGuide.background': v('--p-content-border-color', isDark ? '#403e3c' : '#e4e4e7'),
      'editorWidget.background': v('--p-content-hover-background', isDark ? '#2b2927' : '#f4f4f5'),
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
  return themeName
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
