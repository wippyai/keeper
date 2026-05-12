import { inject as F, ref as x, createApp as ie, defineComponent as ae, computed as se, useTemplateRef as ce, shallowRef as y, onMounted as le, watchEffect as T, watch as z, onBeforeUnmount as pe, openBlock as M, createElementBlock as P, normalizeStyle as de, toDisplayString as ue, createCommentVNode as fe, withDirectives as me, createElementVNode as ge, vShow as he } from "vue";
import { addCollection as ve } from "@iconify/vue";
import { hostCss as be, loadCss as ye, addIcons as we, define as xe } from "@wippy-fe/proxy";
import { getActivePinia as ke, createPinia as _e, setActivePinia as Ee } from "pinia";
const G = Symbol("wippy:emit"), q = Symbol("wippy:props"), Ce = Symbol("wippy:props_error"), Se = Symbol("wippy:content"), Re = Symbol("wippy:panel-id"), Te = Symbol("wippy:layout-bus"), Me = Symbol("wippy:host");
function Pe() {
  const r = F(q);
  if (!r)
    throw new Error("useProps() must be called inside a WippyVueElement");
  return r;
}
function Oe() {
  const r = F(G);
  if (!r)
    throw new Error("useEvents() must be called inside a WippyVueElement");
  return r;
}
const Le = [
  "themeConfigUrl",
  "primeVueCssUrl",
  "markdownCssUrl",
  "iframeCssUrl"
];
function Be(r, e) {
  const a = (e ?? Le).map(async (n) => {
    const s = be[n];
    if (!s)
      return console.warn(`[wippy-fe/webcomponent-core] hostCss key "${n}" is undefined — skipping. Remove it from hostCssKeys if the CSS was removed.`), null;
    try {
      return await ye(s);
    } catch (i) {
      return console.warn(`[wippy-fe/webcomponent-core] Failed to load hostCss "${n}" (${s}):`, i), null;
    }
  });
  return Promise.all(a).then((n) => {
    for (const s of n) {
      if (!s)
        continue;
      const i = document.createElement("style");
      i.textContent = s, i.setAttribute("role", "@wippy-fe/host-css"), r.appendChild(i);
    }
  });
}
function Ie(r, e) {
  const t = document.createElement("style");
  t.textContent = e, r.appendChild(t);
}
function J(r) {
  return r.__wippyHost ?? null;
}
function Ne(r) {
  return r.replace(/-([a-z])/g, (e, t) => t.toUpperCase());
}
function Ae(r, e, t) {
  switch (t.type) {
    case "string":
      return { value: e };
    case "number": {
      const a = Number.parseFloat(e);
      return Number.isNaN(a) ? { value: void 0, error: `Invalid ${r}: expected a number` } : { value: a };
    }
    case "integer": {
      const a = Number.parseInt(e, 10);
      return Number.isNaN(a) ? { value: void 0, error: `Invalid ${r}: expected an integer` } : { value: a };
    }
    case "boolean":
      return { value: e !== "false" };
    case "array":
    case "object":
      try {
        const a = JSON.parse(e);
        return t.type === "array" && !Array.isArray(a) ? { value: void 0, error: `Invalid ${r}: expected a JSON array` } : { value: a };
      } catch {
        return { value: void 0, error: `Invalid ${r}: must be valid JSON` };
      }
    default:
      return { value: e };
  }
}
function K(r, e) {
  const t = {}, a = [];
  for (const [n, s] of Object.entries(e.properties)) {
    const i = r.getAttribute(n), p = Ne(n);
    if (i === null) {
      s.default !== void 0 && (t[p] = s.default);
      continue;
    }
    const u = Ae(n, i, s);
    u.error ? a.push(u.error) : t[p] = u.value;
  }
  return { props: t, errors: a };
}
class He extends HTMLElement {
  constructor() {
    super(), this._contentObserver = null, this._initialized = !1, this._container = null, this._internals = this.attachInternals();
  }
  /**
   * Override to provide the component's configuration.
   * Must be static because `observedAttributes` reads it before construction.
   *
   * Specify the generic to get typed `validateProps`:
   * ```ts
   * static get wippyConfig(): WippyElementConfig<MyProps> { ... }
   * ```
   */
  static get wippyConfig() {
    return { propsSchema: { properties: {} } };
  }
  /**
   * Derived from the props schema + any `extraObservedAttributes`.
   */
  static get observedAttributes() {
    const e = this.wippyConfig, t = Object.keys(e.propsSchema.properties), a = e.extraObservedAttributes ?? [];
    return [...t, ...a];
  }
  /**
   * Panel-scoped `host` wrapper attached by the managed-layout shell's
   * content resolvers (`ComponentResolver` / `WebComponentPackageLoader`).
   *
   * Inside a managed-layout panel, this is a wrapper around the universal
   * `host` API where context-aware calls (`layout.broadcast / send / on`)
   * are routed through the panel-bound bus — so `sourcePanelId` is
   * attributed correctly without postMessage indirection. Layout
   * mutations and other host methods pass through unchanged.
   *
   * `null` outside a managed-layout context (compat shell, chat sidebar,
   * standalone playground). Subclass code that needs a host in those
   * cases can fall back to `import { host } from '@wippy-fe/proxy'`.
   */
  get host() {
    return J(this);
  }
  /**
   * Emit a CustomEvent that bubbles and crosses shadow DOM boundaries.
   */
  emitEvent(e, t) {
    this.dispatchEvent(new CustomEvent(e, {
      bubbles: !0,
      composed: !0,
      detail: t
    }));
  }
  // ── Lifecycle ──────────────────────────────────────────────
  connectedCallback() {
    this._internals.states.add("loading");
    try {
      const e = this.constructor.wippyConfig, t = this._initialized, a = this.shadowRoot ?? this.attachShadow({ mode: e.shadowMode ?? "open" });
      let n;
      if (t)
        n = this._container;
      else {
        this.onInit(a), e.inlineCss && Ie(a, e.inlineCss), (e.hostCssKeys === void 0 || e.hostCssKeys.length > 0) && Be(a, e.hostCssKeys), n = document.createElement("div");
        const l = e.containerClasses ?? [];
        l.length > 0 && n.classList.add(...l), a.appendChild(n), this._container = n, we(ve);
      }
      const { props: s, errors: i } = K(this, e.propsSchema);
      e.validateProps && i.push(...e.validateProps(s));
      const p = s;
      let u = null;
      e.contentTemplate && (u = this._extractContent(e.contentTemplate), this._contentObserver = new MutationObserver(() => {
        const l = this._extractContent(e.contentTemplate);
        this.onContentChanged(l);
      }), this._contentObserver.observe(this, {
        childList: !0,
        characterData: !0,
        subtree: !0
      })), this.onMount(a, n, p, i, u, t), this._internals.states.delete("loading"), this._internals.states.add("ready"), t || (this._initialized = !0), this.onReady(), this.emitEvent("load");
    } catch (e) {
      this.onError(e), this._internals.states.delete("loading"), this._internals.states.add("error"), this.emitEvent("error", {
        message: e instanceof Error ? e.message : String(e),
        error: e
      });
    }
  }
  disconnectedCallback() {
    this._contentObserver && (this._contentObserver.disconnect(), this._contentObserver = null), this.onUnmount(), this.emitEvent("unload"), this._internals.states.clear(), delete this.__wippyHost, delete this.__wippyHostBus;
  }
  attributeChangedCallback(e, t, a) {
    if (t === a)
      return;
    const n = this.constructor.wippyConfig, { props: s, errors: i } = K(this, n.propsSchema);
    n.validateProps && i.push(...n.validateProps(s)), this.onPropsChanged(s, i);
  }
  // ── Hooks ──────────────────────────────────────────────────
  /** Called right after shadow DOM is attached, before CSS or container. */
  onInit(e) {
  }
  /** Called after internals state is set to ready, before the `load` event. */
  onReady() {
  }
  /** Called when connectedCallback throws. Default logs to console. */
  onError(e) {
    console.error(`${this.constructor.name} initialization failed:`, e);
  }
  /** Called when observed attributes change. Override to update framework state. */
  onPropsChanged(e, t) {
  }
  /**
   * Extract text from a child `<template data-type="...">` element.
   * Uses `.content.textContent` since `<template>` stores content in a DocumentFragment.
   */
  _extractContent(e) {
    return this.querySelector(`template[data-type="${e}"]`)?.content.textContent?.trim() ?? null;
  }
  /** Called when child `<template>` content changes. Override to update framework state. */
  onContentChanged(e) {
  }
}
function De(r) {
  return r.__wippyHostBus ?? null;
}
function We(r) {
  return r.dataset.wippyPanelId ?? null;
}
class Ve extends He {
  constructor() {
    super(...arguments), this._vueApp = null, this._propsRef = x({}), this._errorsRef = x([]), this._contentRef = x(null);
  }
  /**
   * Override to provide Vue-specific configuration.
   */
  static get vueConfig() {
    throw new Error("WippyVueElement subclass must override static get vueConfig()");
  }
  onMount(e, t, a, n, s, i) {
    const p = this.constructor.vueConfig;
    this._propsRef.value = a, this._errorsRef.value = n, this._contentRef.value = s ?? null;
    for (const m of n)
      this.emitEvent("invalid", { message: m });
    const u = ke();
    this._vueApp = ie(p.rootComponent);
    const l = _e();
    if (p.piniaPlugins)
      for (const m of p.piniaPlugins)
        l.use(m);
    if (this._vueApp.use(l), p.plugins)
      for (const m of p.plugins)
        this._vueApp.use(m);
    this._vueApp.provide(q, this._propsRef), this._vueApp.provide(Ce, this._errorsRef), this._vueApp.provide(G, this.emitEvent.bind(this)), this._vueApp.provide(Se, this._contentRef), this._vueApp.provide(Re, We(this)), this._vueApp.provide(Te, De(this)), this._vueApp.provide(Me, J(this)), p.providers && p.providers(this._vueApp, this), this._vueApp.mount(t), u && Ee(u);
  }
  onUnmount() {
    this._vueApp && (this._vueApp.unmount(), this._vueApp = null);
  }
  onPropsChanged(e, t) {
    this._propsRef.value = e, this._errorsRef.value = t;
    for (const a of t)
      this.emitEvent("invalid", { message: a });
  }
  onContentChanged(e) {
    this._contentRef.value = e;
  }
}
const ze = () => Pe(), Ke = () => Oe();
let Y = null;
function Ue() {
  return Y;
}
let k = null, O = 0;
function je(r) {
  if (!k)
    return console.warn("[wippy-monaco] bindShadowStylesheetContainer called before loadMonaco resolved — runtime CSS will leak to document.head"), () => {
    };
  k(r), O++;
  let e = !1;
  return () => {
    e || (e = !0, O--, O === 0 && k?.(null));
  };
}
let _ = null;
function L(r, e) {
  if (!_) {
    console.warn("[wippy-monaco] bindHostTheme called before loadMonaco resolved — theme will fall back to global setTheme");
    return;
  }
  _(r, e);
}
function $e(r) {
  _?.(r, null);
}
let B = null;
function Fe() {
  return B || (B = (async () => {
    const [
      r,
      e,
      t,
      a,
      n,
      s,
      i,
      p
    ] = await Promise.all([
      import("./editor.main-IuBRb3T2.js").then((l) => l.default),
      // Patches add exports to these monaco internals — type augmentations
      // live in `src/types/monaco-stylesheets-patch.d.ts`.
      import("./domStylesheets-yftOQEzv.js").then((l) => l.es),
      import("./standaloneThemeService-DlKGT-Pu.js").then((l) => l.dk),
      import("./editor.worker-6fjUqSQw.js").then((l) => l.default),
      import("./json.worker-QrKabbIj.js").then((l) => l.default),
      import("./css.worker-B_353apr.js").then((l) => l.default),
      import("./html.worker-vLFr0FfR.js").then((l) => l.default),
      import("./ts.worker-DE0dpLt9.js").then((l) => l.default)
    ]);
    Y = r, k = e.setDefaultStylesheetContainer, _ = t.setHostTheme, self.MonacoEnvironment = {
      getWorker(l, m) {
        switch (m) {
          case "json":
            return new n();
          case "css":
          case "scss":
          case "less":
            return new s();
          case "html":
          case "handlebars":
          case "razor":
            return new i();
          case "typescript":
          case "javascript":
            return new p();
          default:
            return new a();
        }
      }
    };
    const u = await import("./editor.main-IabBdevM.js").then((l) => l.b);
    return Ye(u), u;
  })()), B;
}
const X = "keeper-dark", Q = "keeper-light", Ge = "keeper-auto-", U = /* @__PURE__ */ new WeakMap();
let qe = 0;
function Je(r) {
  let e = U.get(r);
  return e || (e = `${Ge}${++qe}`, U.set(r, e)), e;
}
const Z = [
  { token: "comment", foreground: "6a737d", fontStyle: "italic" },
  { token: "keyword", foreground: "f59e0b" },
  { token: "string", foreground: "4ade80" },
  { token: "number", foreground: "c084fc" },
  { token: "type", foreground: "60a5fa" },
  { token: "function", foreground: "2dd4bf" },
  { token: "variable", foreground: "e2e8f0" },
  { token: "operator", foreground: "f87171" }
], ee = [
  { token: "comment", foreground: "6a737d", fontStyle: "italic" },
  { token: "keyword", foreground: "b45309" },
  { token: "string", foreground: "15803d" },
  { token: "number", foreground: "7e22ce" },
  { token: "type", foreground: "1d4ed8" },
  { token: "function", foreground: "0d9488" },
  { token: "variable", foreground: "1e293b" },
  { token: "operator", foreground: "b91c1c" }
];
let j = !1;
function Ye(r) {
  j || (r.editor.defineTheme(X, {
    base: "vs",
    inherit: !0,
    rules: [...Z],
    colors: {
      "editor.background": "#0c0e12",
      "editor.foreground": "#e2e8f0",
      "editor.lineHighlightBackground": "#14171e",
      "editor.selectionBackground": "#1e222c80",
      "editorCursor.foreground": "#f59e0b",
      "editorLineNumber.foreground": "#8b949e50",
      "editorLineNumber.activeForeground": "#8b949e",
      "editor.inactiveSelectionBackground": "#14171e",
      "editorIndentGuide.background": "#1e222c",
      "editorWidget.background": "#10131a",
      "editorWidget.border": "#1e222c",
      "input.background": "#14171e",
      "input.border": "#1e222c",
      "scrollbarSlider.background": "#1e222c80",
      "scrollbarSlider.hoverBackground": "#2a2f3a",
      "diffEditor.insertedTextBackground": "#34d39920",
      "diffEditor.removedTextBackground": "#f8717120",
      "diffEditor.insertedLineBackground": "#34d39910",
      "diffEditor.removedLineBackground": "#f8717110"
    }
  }), r.editor.defineTheme(Q, {
    base: "vs",
    inherit: !0,
    rules: [...ee],
    colors: {
      "editor.background": "#ffffff",
      "editor.foreground": "#1e293b",
      "editor.lineHighlightBackground": "#f4f4f5",
      "editor.selectionBackground": "#bfdbfe",
      "editorCursor.foreground": "#b45309",
      "editorLineNumber.foreground": "#a1a1aa",
      "editorLineNumber.activeForeground": "#52525b",
      "editor.inactiveSelectionBackground": "#e4e4e7",
      "editorIndentGuide.background": "#e4e4e7",
      "editorWidget.background": "#ffffff",
      "editorWidget.border": "#e4e4e7",
      "input.background": "#ffffff",
      "input.border": "#e4e4e7",
      "scrollbarSlider.background": "#a1a1aa80",
      "scrollbarSlider.hoverBackground": "#71717a",
      "diffEditor.insertedTextBackground": "#16a34a20",
      "diffEditor.removedTextBackground": "#dc262620",
      "diffEditor.insertedLineBackground": "#16a34a10",
      "diffEditor.removedLineBackground": "#dc262610"
    }
  }), j = !0);
}
function Xe(r, e) {
  const t = Je(e), a = getComputedStyle(e), n = (p, u) => a.getPropertyValue(p).trim() || u, s = n("--p-content-background", "#1c1a19"), i = Qe(s);
  return r.editor.defineTheme(t, {
    // Match the base of keeper-dark / keeper-light so all keeper themes
    // produce identical mtkN→kind orderings in their colorMaps — required
    // by the per-host theme patch.
    base: "vs",
    inherit: !0,
    rules: [...i ? Z : ee],
    colors: {
      "editor.background": s,
      "editor.foreground": n("--p-text-color", i ? "#fafafa" : "#18181b"),
      "editor.lineHighlightBackground": n("--p-surface-100", i ? "#2b2927" : "#f4f4f5"),
      "editor.selectionBackground": i ? "#1e222c80" : "#bfdbfe",
      "editorCursor.foreground": n("--p-primary-500", "#f59e0b"),
      "editorLineNumber.foreground": n("--p-text-muted-color", "#a1a1aa"),
      "editorLineNumber.activeForeground": n("--p-text-color", i ? "#fafafa" : "#18181b"),
      "editor.inactiveSelectionBackground": n("--p-surface-100", i ? "#2b2927" : "#e4e4e7"),
      "editorIndentGuide.background": n("--p-surface-200", i ? "#403e3c" : "#e4e4e7"),
      "editorWidget.background": n("--p-surface-100", i ? "#2b2927" : "#ffffff"),
      "editorWidget.border": n("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "input.background": n("--p-content-background", s),
      "input.border": n("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "scrollbarSlider.background": i ? "#1e222c80" : "#a1a1aa80",
      "scrollbarSlider.hoverBackground": i ? "#2a2f3a" : "#71717a",
      "diffEditor.insertedTextBackground": i ? "#34d39920" : "#16a34a20",
      "diffEditor.removedTextBackground": i ? "#f8717120" : "#dc262620",
      "diffEditor.insertedLineBackground": i ? "#34d39910" : "#16a34a10",
      "diffEditor.removedLineBackground": i ? "#f8717110" : "#dc262610"
    }
  }), t;
}
function Qe(r) {
  const e = r.startsWith("#") ? r.slice(1) : null;
  if (e) {
    const a = e.length === 3 ? e.split("").map((n) => n + n).join("") : e.length >= 6 ? e.slice(0, 6) : null;
    if (a) {
      const n = parseInt(a.slice(0, 2), 16), s = parseInt(a.slice(2, 4), 16), i = parseInt(a.slice(4, 6), 16);
      return $(n, s, i) < 0.5;
    }
  }
  const t = /rgba?\(\s*(\d+)[^\d]+(\d+)[^\d]+(\d+)/.exec(r);
  return t ? $(+t[1], +t[2], +t[3]) < 0.5 : !0;
}
function $(r, e, t) {
  return (0.2126 * r + 0.7152 * e + 0.0722 * t) / 255;
}
function I(r, e, t) {
  switch (e) {
    case "keeper-dark":
      return X;
    case "keeper-light":
      return Q;
    default:
      return Xe(r, t);
  }
}
const Ze = {
  key: 0,
  class: "monaco-status",
  role: "status"
}, er = {
  key: 1,
  class: "monaco-status error",
  role: "alert"
}, rr = {
  ref: "container",
  class: "monaco-container"
}, or = /* @__PURE__ */ ae({
  __name: "monaco-host",
  setup(r) {
    const e = ze(), t = Ke(), a = se(() => {
      const o = e.value?.["min-height"];
      return o && o > 0 ? { minHeight: `${o}px` } : void 0;
    }), n = ce("container"), s = x({ kind: "loading" }), i = y(null), p = y(null), u = y(null), l = y(null), m = y(null);
    let w = null, v = null, b = null, E = !1, C = null, h = null;
    function S(o) {
      const c = o.getRootNode();
      return c instanceof ShadowRoot ? c.host : o;
    }
    function N() {
      return e.value.mode === "diff" ? "diff" : "editor";
    }
    function R() {
      const o = i.value;
      if (!o)
        return;
      const c = n.value;
      if (!c)
        return;
      const d = h ?? S(c), f = I(o, e.value.theme, d);
      L(d, f);
    }
    function A() {
      if (e.value.theme && e.value.theme !== "auto")
        return;
      const o = document.documentElement;
      w = new MutationObserver(() => R()), w.observe(o, { attributes: !0, attributeFilter: ["data-theme", "class"] }), v = window.matchMedia("(prefers-color-scheme: dark)"), b = () => R(), v.addEventListener("change", b);
    }
    function H() {
      w?.disconnect(), w = null, v && b && v.removeEventListener("change", b), v = null, b = null;
    }
    function re() {
      H(), p.value?.dispose(), p.value = null;
      const o = u.value;
      u.value = null, o?.setModel(null), o?.dispose(), l.value?.dispose(), m.value?.dispose(), l.value = null, m.value = null, C?.(), C = null, h && $e(h), h = null;
    }
    async function oe(o, c) {
      h = S(c);
      const d = I(o, e.value.theme, h);
      L(h, d), p.value = o.editor.create(c, {
        value: e.value.value || "",
        language: e.value.language || "plaintext",
        theme: d,
        readOnly: e.value.readonly === !0,
        minimap: { enabled: !1 },
        fontSize: 12,
        lineHeight: 18,
        padding: { top: 8, bottom: 8 },
        scrollBeyondLastLine: !1,
        automaticLayout: !0,
        tabSize: 2,
        renderLineHighlight: "line",
        overviewRulerBorder: !1,
        hideCursorInOverviewRuler: !0,
        overviewRulerLanes: 0,
        scrollbar: {
          verticalScrollbarSize: 6,
          horizontalScrollbarSize: 6
        },
        lineNumbers: "on",
        lineDecorationsWidth: 0,
        lineNumbersMinChars: 3,
        glyphMargin: !1,
        folding: !0,
        wordWrap: "on",
        contextmenu: !1
      }), p.value.onDidChangeModelContent(() => {
        if (E)
          return;
        const f = p.value?.getValue() ?? "";
        t("change", { value: f });
      });
    }
    async function te(o, c) {
      h = S(c);
      const d = I(o, e.value.theme, h);
      L(h, d), u.value = o.editor.createDiffEditor(c, {
        theme: d,
        readOnly: !0,
        minimap: { enabled: !1 },
        fontSize: 12,
        lineHeight: 18,
        padding: { top: 8, bottom: 8 },
        scrollBeyondLastLine: !1,
        automaticLayout: !0,
        renderSideBySide: !0,
        enableSplitViewResizing: !0,
        renderOverviewRuler: !1,
        overviewRulerBorder: !1,
        renderIndicators: !0,
        originalEditable: !1
      }), D(o);
    }
    function D(o) {
      const c = u.value;
      if (!c)
        return;
      const d = e.value.language || "plaintext", f = l.value, g = m.value, W = o.editor.createModel(e.value.baseline || "", d), V = o.editor.createModel(e.value.current || "", d);
      l.value = W, m.value = V, c.setModel({ original: W, modified: V }), f?.dispose(), g?.dispose();
    }
    function ne(o) {
      const c = o.getRootNode();
      if (!(c instanceof ShadowRoot) || c.querySelector("style[data-wippy-monaco-css]"))
        return;
      const d = Ue();
      if (!d)
        return;
      const f = document.createElement("style");
      f.setAttribute("data-wippy-monaco-css", ""), f.textContent = d, c.appendChild(f);
    }
    return le(async () => {
      const o = n.value;
      if (!o) {
        s.value = { kind: "error", message: "monaco container missing" };
        return;
      }
      try {
        const c = await Fe();
        ne(o);
        const d = o.getRootNode();
        d instanceof ShadowRoot && (C = je(d)), i.value = c, N() === "diff" ? await te(c, o) : await oe(c, o), A(), s.value = { kind: "ready" }, t("load", void 0);
      } catch (c) {
        const d = c instanceof Error ? c.message : String(c);
        s.value = { kind: "error", message: d }, t("error", { message: d, error: c });
      }
    }), T(() => {
      const o = p.value;
      if (!o)
        return;
      const c = e.value.value ?? "";
      o.getValue() !== c && (E = !0, o.setValue(c), E = !1);
    }), T(() => {
      const o = p.value;
      o && o.updateOptions({ readOnly: e.value.readonly === !0 });
    }), T(() => {
      const o = i.value, c = p.value, d = u.value, f = e.value.language || "plaintext";
      if (o && c) {
        const g = c.getModel();
        g && g.getLanguageId() !== f && o.editor.setModelLanguage(g, f);
      }
      if (o && d) {
        const g = d.getModel();
        g && (g.original.getLanguageId() !== f && o.editor.setModelLanguage(g.original, f), g.modified.getLanguageId() !== f && o.editor.setModelLanguage(g.modified, f));
      }
    }), z(() => [e.value.baseline, e.value.current], () => {
      const o = i.value;
      o && N() === "diff" && D(o);
    }), z(() => e.value.theme, () => {
      H(), R(), A();
    }), pe(() => {
      re(), t("unload", void 0);
    }), (o, c) => (M(), P("div", {
      class: "monaco-host",
      style: de(a.value)
    }, [
      s.value.kind === "loading" ? (M(), P("div", Ze, " Loading editor… ")) : s.value.kind === "error" ? (M(), P("div", er, ue(s.value.message), 1)) : fe("", !0),
      me(ge("div", rr, null, 512), [
        [he, s.value.kind === "ready"]
      ])
    ], 4));
  }
}), tr = ":root{--p-primary: rgb(0, 95, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-secondary: #6f7385;--p-secondary-50: color-mix(in srgb, var(--p-secondary) 5%, white);--p-secondary-100: color-mix(in srgb, var(--p-secondary) 10%, white);--p-secondary-200: color-mix(in srgb, var(--p-secondary) 20%, white);--p-secondary-300: color-mix(in srgb, var(--p-secondary) 35%, white);--p-secondary-400: color-mix(in srgb, var(--p-secondary) 65%, white);--p-secondary-500: var(--p-secondary);--p-secondary-600: color-mix(in srgb, var(--p-secondary) 80%, black);--p-secondary-700: color-mix(in srgb, var(--p-secondary) 65%, black);--p-secondary-800: color-mix(in srgb, var(--p-secondary) 55%, black);--p-secondary-900: color-mix(in srgb, var(--p-secondary) 50%, black);--p-secondary-950: color-mix(in srgb, var(--p-secondary) 30%, black);--p-danger: rgb(239, 68, 68);--p-danger-50: color-mix(in srgb, var(--p-danger) 5%, white);--p-danger-100: color-mix(in srgb, var(--p-danger) 10%, white);--p-danger-200: color-mix(in srgb, var(--p-danger) 20%, white);--p-danger-300: color-mix(in srgb, var(--p-danger) 30%, white);--p-danger-400: color-mix(in srgb, var(--p-danger) 40%, white);--p-danger-500: var(--p-danger);--p-danger-600: color-mix(in srgb, var(--p-danger) 80%, black);--p-danger-700: color-mix(in srgb, var(--p-danger) 70%, black);--p-danger-800: color-mix(in srgb, var(--p-danger) 60%, black);--p-danger-900: color-mix(in srgb, var(--p-danger) 50%, black);--p-danger-950: color-mix(in srgb, var(--p-danger) 40%, black);--p-success: rgb(34, 197, 94);--p-success-50: color-mix(in srgb, var(--p-success) 5%, white);--p-success-100: color-mix(in srgb, var(--p-success) 10%, white);--p-success-200: color-mix(in srgb, var(--p-success) 20%, white);--p-success-300: color-mix(in srgb, var(--p-success) 30%, white);--p-success-400: color-mix(in srgb, var(--p-success) 40%, white);--p-success-500: var(--p-success);--p-success-600: color-mix(in srgb, var(--p-success) 80%, black);--p-success-700: color-mix(in srgb, var(--p-success) 70%, black);--p-success-800: color-mix(in srgb, var(--p-success) 60%, black);--p-success-900: color-mix(in srgb, var(--p-success) 50%, black);--p-success-950: color-mix(in srgb, var(--p-success) 40%, black);--p-warn: rgb(249, 115, 22);--p-warn-50: color-mix(in srgb, var(--p-warn) 5%, white);--p-warn-100: color-mix(in srgb, var(--p-warn) 10%, white);--p-warn-200: color-mix(in srgb, var(--p-warn) 20%, white);--p-warn-300: color-mix(in srgb, var(--p-warn) 30%, white);--p-warn-400: color-mix(in srgb, var(--p-warn) 40%, white);--p-warn-500: var(--p-warn);--p-warn-600: color-mix(in srgb, var(--p-warn) 80%, black);--p-warn-700: color-mix(in srgb, var(--p-warn) 70%, black);--p-warn-800: color-mix(in srgb, var(--p-warn) 60%, black);--p-warn-900: color-mix(in srgb, var(--p-warn) 50%, black);--p-warn-950: color-mix(in srgb, var(--p-warn) 40%, black);--p-info: rgb(14, 165, 233);--p-info-50: color-mix(in srgb, var(--p-info) 5%, white);--p-info-100: color-mix(in srgb, var(--p-info) 10%, white);--p-info-200: color-mix(in srgb, var(--p-info) 20%, white);--p-info-300: color-mix(in srgb, var(--p-info) 30%, white);--p-info-400: color-mix(in srgb, var(--p-info) 40%, white);--p-info-500: var(--p-info);--p-info-600: color-mix(in srgb, var(--p-info) 80%, black);--p-info-700: color-mix(in srgb, var(--p-info) 70%, black);--p-info-800: color-mix(in srgb, var(--p-info) 60%, black);--p-info-900: color-mix(in srgb, var(--p-info) 50%, black);--p-info-950: color-mix(in srgb, var(--p-info) 40%, black);--p-help: rgb(168, 85, 247);--p-help-50: color-mix(in srgb, var(--p-help) 5%, white);--p-help-100: color-mix(in srgb, var(--p-help) 10%, white);--p-help-200: color-mix(in srgb, var(--p-help) 20%, white);--p-help-300: color-mix(in srgb, var(--p-help) 30%, white);--p-help-400: color-mix(in srgb, var(--p-help) 40%, white);--p-help-500: var(--p-help);--p-help-600: color-mix(in srgb, var(--p-help) 80%, black);--p-help-700: color-mix(in srgb, var(--p-help) 70%, black);--p-help-800: color-mix(in srgb, var(--p-help) 60%, black);--p-help-900: color-mix(in srgb, var(--p-help) 50%, black);--p-help-950: color-mix(in srgb, var(--p-help) 40%, black);--p-accent: rgb(20, 184, 166);--p-accent-50: color-mix(in srgb, var(--p-accent) 5%, white);--p-accent-100: color-mix(in srgb, var(--p-accent) 10%, white);--p-accent-200: color-mix(in srgb, var(--p-accent) 20%, white);--p-accent-300: color-mix(in srgb, var(--p-accent) 30%, white);--p-accent-400: color-mix(in srgb, var(--p-accent) 40%, white);--p-accent-500: var(--p-accent);--p-accent-600: color-mix(in srgb, var(--p-accent) 80%, black);--p-accent-700: color-mix(in srgb, var(--p-accent) 70%, black);--p-accent-800: color-mix(in srgb, var(--p-accent) 60%, black);--p-accent-900: color-mix(in srgb, var(--p-accent) 50%, black);--p-accent-950: color-mix(in srgb, var(--p-accent) 40%, black);--p-surface-0: #ffffff;--p-surface-50: #fafafa;--p-surface-100: #f5f5f5;--p-surface-200: #e5e5e5;--p-surface-300: #d4d4d4;--p-surface-400: #a3a3a3;--p-surface-500: #737373;--p-surface-600: #525252;--p-surface-700: #404040;--p-surface-800: #262626;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #171717;--p-surface-950: #0a0a0a;--p-content-border-radius: 6px}:root{--p-primary-color: var(--p-primary-500);--p-primary-contrast-color: var(--p-surface-0);--p-primary-hover-color: var(--p-primary-600);--p-primary-active-color: var(--p-primary-700);--p-content-border-color: var(--p-surface-200);--p-content-hover-background: var(--p-surface-100);--p-content-hover-color: var(--p-surface-800);--p-highlight-background: var(--p-primary-50);--p-highlight-color: var(--p-primary-700);--p-highlight-focus-background: var(--p-primary-100);--p-highlight-focus-color: var(--p-primary-800);--p-content-background: var(--p-surface-0);--p-text-color: var(--p-surface-700);--p-text-hover-color: var(--p-surface-800);--p-text-muted-color: var(--p-surface-500);--p-text-hover-muted-color: var(--p-surface-600)}@media(prefers-color-scheme:dark){:root{--p-surface-D: #fff;--p-surface-0: #fff;--p-surface-50: #fafafa;--p-surface-100: #f4f4f5;--p-surface-200: #e4e4e7;--p-surface-300: #d4d4d8;--p-surface-400: #a1a1aa;--p-surface-500: #71717a;--p-surface-600: #545250;--p-surface-700: #403e3c;--p-surface-800: #2b2927;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #1c1a19;--p-surface-950: #0f0e0d;--p-primary: rgb(0, 125, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-primary-color: var(--p-primary-400);--p-primary-contrast-color: var(--p-surface-900);--p-primary-hover-color: var(--p-primary-300);--p-primary-active-color: var(--p-primary-200);--p-content-border-color: var(--p-surface-700);--p-content-hover-background: var(--p-surface-800);--p-content-hover-color: var(--p-surface-0);--p-highlight-background: color-mix(in srgb, var(--p-primary-400), transparent 84%);--p-highlight-color: rgba(255, 255, 255, 87%);--p-highlight-focus-background: color-mix(in srgb, var(--p-primary-400), transparent 76%);--p-highlight-focus-color: rgba(255, 255, 255, 87%);--p-content-background: var(--p-surface-900);--p-text-color: var(--p-surface-0);--p-text-hover-color: var(--p-surface-0);--p-text-muted-color: var(--p-surface-400);--p-text-hover-muted-color: var(--p-surface-300)}}:host{display:block;width:100%;height:100%;box-sizing:border-box}:host>div{width:100%;height:100%}.monaco-host{width:100%;height:100%;box-sizing:border-box;display:flex;flex-direction:column}.monaco-container{flex:1 1 auto;width:100%;height:100%;min-height:100px;border:1px solid var(--p-content-border-color);border-radius:4px;overflow:hidden}.monaco-status{flex:1 1 auto;display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;font-size:13px;color:var(--p-text-muted-color);border:1px solid var(--p-content-border-color);border-radius:4px;padding:12px}.monaco-status.error{color:var(--p-red-500, #ef4444)}", nr = { props: { type: "object", properties: { mode: { type: "string", enum: ["editor", "diff"], default: "editor", description: "Editor mode (single buffer) or diff mode (baseline vs current)." }, language: { type: "string", default: "plaintext", description: "Monaco language id (e.g. lua, javascript, typescript, json, markdown)." }, value: { type: "string", default: "", description: "Initial buffer value for editor mode. Ignored in diff mode." }, baseline: { type: "string", default: "", description: "Original side of the diff (read-only). Diff mode only." }, current: { type: "string", default: "", description: "Modified side of the diff (read-only). Diff mode only." }, readonly: { type: "boolean", default: !1, description: "Editor mode only. Diff mode is always read-only." }, theme: { type: "string", enum: ["auto", "keeper-dark", "keeper-light"], default: "auto", description: "Color theme. `auto` derives from app CSS variables (--p-content-background, --p-text-color, --p-primary-500, --p-surface-*) and re-themes on prefers-color-scheme / [data-theme] changes. `keeper-dark` and `keeper-light` are fixed presets." }, "min-height": { type: "number", default: 0, description: "Minimum height in px. 0 means fill the container." } } } }, ir = {
  wippy: nr
};
class ar extends Ve {
  static get wippyConfig() {
    return {
      propsSchema: ir.wippy.props,
      hostCssKeys: ["themeConfigUrl"],
      inlineCss: tr
    };
  }
  static get vueConfig() {
    return {
      rootComponent: or
    };
  }
}
xe(import.meta.url, ar);
//# sourceMappingURL=index.js.map
