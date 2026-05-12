// Type augmentations for the patch-package patches applied to monaco
// (see `patches/monaco-editor+0.55.1.patch`). The patches add exports
// that the shipped `.d.ts` files don't reflect, so we declare them here.

declare module 'monaco-editor/esm/vs/base/browser/domStylesheets.js' {
  /**
   * Redirect monaco's default `createStyleSheet` target from
   * `document.head` to the given node (typically a `ShadowRoot`).
   * Passing `null` restores the document.head default.
   *
   * Used by `<wippy-monaco>` to route monaco's runtime CSS injections
   * (theme rules, widget styles, etc.) into its own shadow root.
   */
  export function setDefaultStylesheetContainer(container: Node | null): void
}

declare module 'monaco-editor/esm/vs/editor/standalone/browser/standaloneThemeService.js' {
  /**
   * Apply a per-host theme override. `host` is the element whose shadow
   * root contains a monaco editor (typically a custom-element host like
   * `<wippy-monaco>`); `themeName` is a theme registered via
   * `monaco.editor.defineTheme`. Passing `null` for `themeName` clears
   * the override and the host falls back to the global theme set via
   * `monaco.editor.setTheme(name)`.
   *
   * The per-host override is stored in a `WeakMap<Element, Theme>` inside
   * monaco's `StandaloneThemeService`, and takes precedence over the
   * global theme for that host's style element only — other editors in
   * other shadow roots are unaffected.
   */
  export function setHostTheme(host: Element, themeName: string | null): void
}
