import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { wippyComponentPlugin } from '@wippy-fe/vite-plugin'
import { defineConfig } from 'vite'

/**
 * Strip monaco-editor's CSS side-effect imports during build.
 *
 * Monaco's ESM build has ~150 `import './foo.css'` statements scattered
 * across `node_modules/monaco-editor/esm/**`. Vite's default CSS handling
 * collects them, bundles them, and injects the result into
 * `document.head` at runtime via its CSS-in-JS helper. That works fine
 * for normal pages, but breaks for our web component: styles in
 * `document.head` do NOT pierce shadow boundaries, so `.monaco-editor`
 * and its children (`.overflow-guard`, `.monaco-scrollable-element`,
 * etc.) render as `position: static` and the editor's UI fragments
 * (textarea, scroll-host, content-widgets) end up scattered around the
 * viewport instead of stacked inside the editor.
 *
 * The fix is two-part:
 *   1. This plugin neuters monaco's CSS side-effect imports at build
 *      time so Vite does NOT inject anything into `document.head`.
 *   2. monaco-loader.ts imports `monaco-editor/min/vs/editor/editor.main.css`
 *      as inline text (Vite's `?inline` modifier), and monaco-host.vue
 *      injects it as a `<style>` into the shadow root the first time the
 *      WC mounts in that shadow root.
 *
 * Runtime-emitted styles (theme rules, sash/contextview/menu widget
 * styles via `createStyleSheet(document.head)` from
 * `monaco-editor/esm/vs/base/browser/domStylesheets.js`) are redirected
 * into the shadow root via a patch-package patch that adds
 * `setDefaultStylesheetContainer(node)` to monaco's `domStylesheets.js`
 * — see `patches/monaco-editor+0.55.1.patch` and the
 * `bindShadowStylesheetContainer` wrapper in `src/app/monaco-loader.ts`.
 * Theme CSS specifically is per-host via a sibling patch that adds
 * `setHostTheme(host, themeName)` to `StandaloneThemeService`.
 */
function stripMonacoCssImports() {
  return {
    name: 'wippy-monaco-strip-css-imports',
    enforce: 'pre' as const,
    resolveId(source: string, importer?: string) {
      if (!importer)
        return null
      // Anchor on the node_modules boundary so a user path that happens to
      // contain "monaco-editor" doesn't match. Vite normalizes paths to
      // forward slashes on all platforms, so the backslash form isn't needed.
      if (!importer.includes('/node_modules/monaco-editor/'))
        return null
      if (!source.endsWith('.css'))
        return null
      // Skip our own `?inline` import of `editor.main.css` — that one is
      // intentional and Vite handles it via the asset pipeline before this
      // resolver fires (the `?inline` query suffix means `source` ends with
      // `.css?inline`, not `.css`, so the `endsWith('.css')` check above
      // also filters it out — this comment is here for the next reader).
      return { id: '\0wippy-monaco-stripped-css', moduleSideEffects: false }
    },
    load(id: string) {
      // Side-effect-only CSS imports (`import './foo.css'`) don't read the
      // default export, so returning an empty module is sufficient. Monaco
      // does not use CSS modules / `import styles from './foo.css'`, so we
      // don't need to preserve any export shape.
      if (id === '\0wippy-monaco-stripped-css')
        return 'export default {}'
      return null
    },
  }
}

export default defineConfig({
  plugins: [
    vue(),
    wippyComponentPlugin(),
    stripMonacoCssImports(),
  ],
  // Emit relative URLs for asset and worker references. Default `base: '/'`
  // bakes a root-absolute `/assets/<worker>.js` into the worker-shim's
  // `new Worker(...)` URL — that resolves to the consumer's origin root, not
  // the WC's mount path. The WC is served at `/app/wc/wippy-monaco/` but
  // gets loaded inside iframes whose origin root has no `/assets/` dir, so
  // monaco's worker spawn 404s with "Unexpected token '<'" (the 404 HTML
  // returned in place of the missing JS). With `base: './'` the worker URL
  // becomes `./assets/<worker>.js` which resolves relative to the shim file
  // itself (= `/app/wc/wippy-monaco/assets/<worker>.js`).
  base: './',
  build: {
    target: 'esnext',
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'WippyMonaco',
      fileName: 'index',
      formats: ['es'],
    },
    rollupOptions: {
      input: {
        index: resolve(__dirname, 'src/index.ts'),
      },
      // Externalize peers served by the web-host import map — matches the
      // pattern in app-template's markdown WC and other reference WCs. In
      // particular `pinia` (transitively imported by WippyVueElement) MUST be
      // external: when bundled, pinia.mjs:26 references `process.env.NODE_ENV`
      // which Vite does NOT substitute for library code, and the WC then
      // throws `ReferenceError: process is not defined` at module load and
      // never reaches `define()`. See
      // app-template/frontend/docs/web-component-loading.md.
      external: [
        'vue',
        'pinia',
        '@iconify/vue',
        '@wippy-fe/proxy',
      ],
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name]-[hash].js',
        assetFileNames: '[name]-[hash][extname]',
      },
      // The entry's `define(import.meta.url, ...)` reads `?declare-tag=` off
      // the entry URL the autoload script appends. Letting Rollup emit a
      // facade that re-exports from a sub-chunk would move that statement
      // into the sub-chunk and break custom-element registration. Same as
      // the mermaid WC.
      preserveEntrySignatures: false,
    },
    sourcemap: true,
  },
})
