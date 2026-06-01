import { inject as F, ref as k, createApp as ie, defineComponent as se, computed as ae, useTemplateRef as ce, shallowRef as _, onMounted as le, watchEffect as P, watch as K, onBeforeUnmount as pe, openBlock as L, createElementBlock as T, normalizeStyle as de, toDisplayString as ue, createCommentVNode as fe, withDirectives as he, createElementVNode as me, vShow as ge } from "vue";
import { addCollection as ve } from "@iconify/vue";
import { hostCss as be, loadCss as ye, addIcons as _e, define as ke } from "@wippy-fe/proxy";
import { getActivePinia as we, createPinia as xe, setActivePinia as Ce } from "pinia";
const G = Symbol("wippy:emit"), q = Symbol("wippy:props"), Ee = Symbol("wippy:props_error"), Se = Symbol("wippy:content"), Re = Symbol("wippy:panel-id"), Pe = Symbol("wippy:layout-bus"), Le = Symbol("wippy:host");
function Te() {
  const n = F(q);
  if (!n)
    throw new Error("useProps() must be called inside a WippyVueElement");
  return n;
}
function Ae() {
  const n = F(G);
  if (!n)
    throw new Error("useEvents() must be called inside a WippyVueElement");
  return n;
}
const Me = [
  "themeConfigUrl",
  "primeVueCssUrl",
  "markdownCssUrl",
  "iframeCssUrl"
];
function Oe(n, e) {
  const t = (e ?? Me).map(async (o) => {
    const a = be[o];
    if (!a)
      return console.warn(`[wippy-fe/webcomponent-core] hostCss key "${o}" is undefined — skipping. Remove it from hostCssKeys if the CSS was removed.`), null;
    try {
      return await ye(a);
    } catch (i) {
      return console.warn(`[wippy-fe/webcomponent-core] Failed to load hostCss "${o}" (${a}):`, i), null;
    }
  });
  return Promise.all(t).then((o) => {
    for (const a of o) {
      if (!a)
        continue;
      const i = document.createElement("style");
      i.textContent = a, i.setAttribute("role", "@wippy-fe/host-css"), n.appendChild(i);
    }
  });
}
function Ie(n, e) {
  const r = document.createElement("style");
  r.textContent = e, n.appendChild(r);
}
function J(n) {
  return n.__wippyHost ?? null;
}
function Be(n) {
  return n.replace(/-([a-z])/g, (e, r) => r.toUpperCase());
}
function Ne(n, e, r) {
  switch (r.type) {
    case "string":
      return { value: e };
    case "number": {
      const t = Number.parseFloat(e);
      return Number.isNaN(t) ? { value: void 0, error: `Invalid ${n}: expected a number` } : { value: t };
    }
    case "integer": {
      const t = Number.parseInt(e, 10);
      return Number.isNaN(t) ? { value: void 0, error: `Invalid ${n}: expected an integer` } : { value: t };
    }
    case "boolean":
      return { value: e !== "false" };
    case "array":
    case "object":
      try {
        const t = JSON.parse(e);
        return r.type === "array" && !Array.isArray(t) ? { value: void 0, error: `Invalid ${n}: expected a JSON array` } : { value: t };
      } catch {
        return { value: void 0, error: `Invalid ${n}: must be valid JSON` };
      }
    default:
      return { value: e };
  }
}
function A(n, e) {
  const r = {}, t = [];
  for (const [o, a] of Object.entries(e.properties)) {
    const i = n.getAttribute(o), p = Be(o);
    if (i === null) {
      a.default !== void 0 && (r[p] = a.default);
      continue;
    }
    const u = Ne(o, i, a);
    u.error ? t.push(u.error) : r[p] = u.value;
  }
  return { props: r, errors: t };
}
class De {
  constructor(e, r) {
    this._propsListeners = /* @__PURE__ */ new Set(), this._contentListeners = /* @__PURE__ */ new Set(), this._disposed = !1, this._props = e.props, this._errors = e.errors, this._content = e.content, this._emitToDom = r;
    const t = this;
    this.props = {
      get value() {
        return t._props;
      },
      get errors() {
        return t._errors;
      },
      subscribe(o, a) {
        return t._subscribeProps(o, a);
      }
    }, this.events = {
      emit(o, a) {
        t._disposed || t._emitToDom(o, a);
      }
    }, this.content = e.hasContent ? {
      get value() {
        return t._content;
      },
      subscribe(o, a) {
        return t._subscribeContent(o, a);
      }
    } : null;
  }
  /** @internal */
  notifyProps(e, r) {
    if (!this._disposed) {
      this._props = e, this._errors = r;
      for (const t of this._propsListeners)
        t(e, r);
    }
  }
  /** @internal */
  notifyContent(e) {
    if (!this._disposed) {
      this._content = e;
      for (const r of this._contentListeners)
        r(e);
    }
  }
  /** @internal */
  dispose() {
    this._disposed || (this._disposed = !0, this._propsListeners.clear(), this._contentListeners.clear());
  }
  _subscribeProps(e, r) {
    if (this._disposed || r?.signal?.aborted)
      return () => {
      };
    this._propsListeners.add(e), r?.immediate && e(this._props, this._errors);
    const t = () => {
      this._propsListeners.delete(e), r?.signal?.removeEventListener("abort", t);
    };
    return r?.signal?.addEventListener("abort", t, { once: !0 }), t;
  }
  _subscribeContent(e, r) {
    if (this._disposed || r?.signal?.aborted)
      return () => {
      };
    this._contentListeners.add(e), r?.immediate && e(this._content);
    const t = () => {
      this._contentListeners.delete(e), r?.signal?.removeEventListener("abort", t);
    };
    return r?.signal?.addEventListener("abort", t, { once: !0 }), t;
  }
}
class He extends HTMLElement {
  constructor() {
    super(), this._contentObserver = null, this._initialized = !1, this._container = null, this._reactive = null, this._lastProps = null, this._lastErrors = [], this._lastContent = null, this._internals = this.attachInternals();
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
    const e = this.wippyConfig, r = Object.keys(e.propsSchema.properties), t = e.extraObservedAttributes ?? [];
    return [...r, ...t];
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
  emitEvent(e, r) {
    this.dispatchEvent(new CustomEvent(e, {
      bubbles: !0,
      composed: !0,
      detail: r
    }));
  }
  /**
   * Opt-in reactive adapter — framework-agnostic. Subscribe to prop
   * changes, content changes, or emit typed events from a non-Vue
   * consumer without re-rolling reactivity.
   *
   * ```ts
   * class MyEl extends WippyElement<{ count: number }, { tick: { n: number } }> {
   *   protected onMount() {
   *     const ctrl = new AbortController()
   *     this.reactive.props.subscribe(({ count }) => {
   *       this.shadowRoot!.querySelector('.n')!.textContent = String(count)
   *     }, { signal: ctrl.signal, immediate: true })
   *   }
   *   tick(n: number) { this.reactive.events.emit('tick', { n }) }
   * }
   * ```
   *
   * Allocation cost is zero unless this getter is touched. Disposed on
   * `disconnectedCallback`; a fresh adapter is allocated on the next
   * access after reconnect.
   */
  get reactive() {
    if (!this._reactive) {
      const e = this.constructor.wippyConfig, r = !!e.contentTemplate;
      let t, o;
      if (this._lastProps !== null)
        t = this._lastProps, o = this._lastErrors;
      else {
        const i = A(this, e.propsSchema);
        e.validateProps && i.errors.push(...e.validateProps(i.props)), t = i.props, o = i.errors, this._lastProps = t, this._lastErrors = o;
      }
      const a = r ? this._lastContent ?? this._extractContent(e.contentTemplate) : null;
      r && this._lastContent === null && (this._lastContent = a), this._reactive = new De(
        { props: t, errors: o, content: a, hasContent: r },
        this.emitEvent.bind(this)
      );
    }
    return this._reactive;
  }
  // ── Lifecycle ──────────────────────────────────────────────
  connectedCallback() {
    this._internals.states.add("loading");
    try {
      const e = this.constructor.wippyConfig, r = this._initialized, t = this.shadowRoot ?? this.attachShadow({ mode: e.shadowMode ?? "open" });
      let o;
      if (r)
        o = this._container;
      else {
        this.onInit(t), e.inlineCss && Ie(t, e.inlineCss), (e.hostCssKeys === void 0 || e.hostCssKeys.length > 0) && Oe(t, e.hostCssKeys), o = document.createElement("div");
        const c = e.containerClasses ?? [];
        c.length > 0 && o.classList.add(...c), t.appendChild(o), this._container = o, _e(ve);
      }
      const { props: a, errors: i } = A(this, e.propsSchema);
      e.validateProps && i.push(...e.validateProps(a));
      const p = a;
      this._lastProps = p, this._lastErrors = i;
      let u = null;
      e.contentTemplate && (u = this._extractContent(e.contentTemplate), this._lastContent = u, this._contentObserver = new MutationObserver(() => {
        const c = this._extractContent(e.contentTemplate);
        this._lastContent = c, this._reactive?.notifyContent(c), this.onContentChanged(c);
      }), this._contentObserver.observe(this, {
        childList: !0,
        characterData: !0,
        subtree: !0
      })), this.onMount(t, o, p, i, u, r), this._internals.states.delete("loading"), this._internals.states.add("ready"), r || (this._initialized = !0), this.onReady(), this.emitEvent("load");
    } catch (e) {
      this.onError(e), this._internals.states.delete("loading"), this._internals.states.add("error"), this.emitEvent("error", {
        message: e instanceof Error ? e.message : String(e),
        error: e
      });
    }
  }
  disconnectedCallback() {
    this._contentObserver && (this._contentObserver.disconnect(), this._contentObserver = null), this.onUnmount(), this.emitEvent("unload"), this._internals.states.clear(), this._reactive?.dispose(), this._reactive = null, this._lastProps = null, this._lastErrors = [], this._lastContent = null, delete this.__wippyHost, delete this.__wippyHostBus;
  }
  attributeChangedCallback(e, r, t) {
    if (r === t)
      return;
    const o = this.constructor.wippyConfig, { props: a, errors: i } = A(this, o.propsSchema);
    o.validateProps && i.push(...o.validateProps(a));
    const p = a;
    this._lastProps = p, this._lastErrors = i, this._reactive?.notifyProps(p, i), this.onPropsChanged(p, i);
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
  onPropsChanged(e, r) {
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
function We(n) {
  return n.__wippyHostBus ?? null;
}
function Ve(n) {
  return n.dataset.wippyPanelId ?? null;
}
class ze extends He {
  constructor() {
    super(...arguments), this._vueApp = null, this._propsRef = k({}), this._errorsRef = k([]), this._contentRef = k(null), this._bridgeAbort = null;
  }
  /**
   * Override to provide Vue-specific configuration.
   */
  static get vueConfig() {
    throw new Error("WippyVueElement subclass must override static get vueConfig()");
  }
  onMount(e, r, t, o, a, i) {
    const p = this.constructor.vueConfig;
    this._propsRef.value = t, this._errorsRef.value = o, this._contentRef.value = a ?? null;
    for (const f of o)
      this.emitEvent("invalid", { message: f });
    this._bridgeAbort = new AbortController(), this.reactive.props.subscribe((f, v) => {
      this._propsRef.value = f, this._errorsRef.value = [...v];
      for (const b of v)
        this.emitEvent("invalid", { message: b });
    }, { signal: this._bridgeAbort.signal }), this.reactive.content && this.reactive.content.subscribe((f) => {
      this._contentRef.value = f;
    }, { signal: this._bridgeAbort.signal });
    const u = we();
    this._vueApp = ie(p.rootComponent);
    const c = xe();
    if (p.piniaPlugins)
      for (const f of p.piniaPlugins)
        c.use(f);
    if (this._vueApp.use(c), p.plugins)
      for (const f of p.plugins)
        this._vueApp.use(f);
    this._vueApp.provide(q, this._propsRef), this._vueApp.provide(Ee, this._errorsRef), this._vueApp.provide(G, this.emitEvent.bind(this)), this._vueApp.provide(Se, this._contentRef), this._vueApp.provide(Re, Ve(this)), this._vueApp.provide(Pe, We(this)), this._vueApp.provide(Le, J(this)), p.providers && p.providers(this._vueApp, this), this._vueApp.mount(r), u && Ce(u);
  }
  onUnmount() {
    this._bridgeAbort?.abort(), this._bridgeAbort = null, this._vueApp && (this._vueApp.unmount(), this._vueApp = null);
  }
}
const Ke = () => Te(), Ue = () => Ae();
let Y = null;
function je() {
  return Y;
}
let w = null, M = 0;
function $e(n) {
  if (!w)
    return console.warn("[wippy-monaco] bindShadowStylesheetContainer called before loadMonaco resolved — runtime CSS will leak to document.head"), () => {
    };
  w(n), M++;
  let e = !1;
  return () => {
    e || (e = !0, M--, M === 0 && w?.(null));
  };
}
let x = null;
function O(n, e) {
  if (!x) {
    console.warn("[wippy-monaco] bindHostTheme called before loadMonaco resolved — theme will fall back to global setTheme");
    return;
  }
  x(n, e);
}
function Fe(n) {
  x?.(n, null);
}
let I = null;
function Ge() {
  return I || (I = (async () => {
    const [
      n,
      e,
      r,
      t,
      o,
      a,
      i,
      p
    ] = await Promise.all([
      import("./editor.main-IuBRb3T2.js").then((c) => c.default),
      // Patches add exports to these monaco internals — type augmentations
      // live in `src/types/monaco-stylesheets-patch.d.ts`.
      import("./domStylesheets-yftOQEzv.js").then((c) => c.es),
      import("./standaloneThemeService-DlKGT-Pu.js").then((c) => c.dk),
      import("./editor.worker-5i4BoUdL.js").then((c) => c.default),
      import("./json.worker-rMDXTKJP.js").then((c) => c.default),
      import("./css.worker-DL22xU_S.js").then((c) => c.default),
      import("./html.worker-BTgg5INT.js").then((c) => c.default),
      import("./ts.worker-Dj3vtSc8.js").then((c) => c.default)
    ]);
    Y = n, w = e.setDefaultStylesheetContainer, x = r.setHostTheme, self.MonacoEnvironment = {
      getWorker(c, f) {
        switch (f) {
          case "json":
            return new o();
          case "css":
          case "scss":
          case "less":
            return new a();
          case "html":
          case "handlebars":
          case "razor":
            return new i();
          case "typescript":
          case "javascript":
            return new p();
          default:
            return new t();
        }
      }
    };
    const u = await import("./editor.main-C02GhC8A.js").then((c) => c.b);
    return Xe(u), u;
  })()), I;
}
const X = "keeper-dark", Q = "keeper-light", qe = "keeper-auto-", U = /* @__PURE__ */ new WeakMap();
let Je = 0;
function Ye(n) {
  let e = U.get(n);
  return e || (e = `${qe}${++Je}`, U.set(n, e)), e;
}
const Z = [
  { token: "comment", foreground: "6a737d", fontStyle: "italic" },
  { token: "keyword", foreground: "f59e0b" },
  { token: "string", foreground: "4ade80" },
  { token: "number", foreground: "c084fc" },
  { token: "type", foreground: "60a5fa" },
  { token: "function", foreground: "2dd4bf" },
  { token: "variable", foreground: "e2e8f0" },
  { token: "operator", foreground: "f87171" },
  { token: "delimiter", foreground: "cbd5e1" },
  { token: "", foreground: "e2e8f0" }
], ee = [
  { token: "comment", foreground: "6a737d", fontStyle: "italic" },
  { token: "keyword", foreground: "b45309" },
  { token: "string", foreground: "15803d" },
  { token: "number", foreground: "7e22ce" },
  { token: "type", foreground: "1d4ed8" },
  { token: "function", foreground: "0d9488" },
  { token: "variable", foreground: "1e293b" },
  { token: "operator", foreground: "b91c1c" },
  { token: "delimiter", foreground: "475569" },
  { token: "", foreground: "1e293b" }
];
let j = !1;
function Xe(n) {
  j || (n.editor.defineTheme(X, {
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
  }), n.editor.defineTheme(Q, {
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
function Qe(n, e) {
  const r = Ye(e), t = getComputedStyle(e), o = (p, u) => t.getPropertyValue(p).trim() || u, a = o("--p-content-background", "#1c1a19"), i = Ze(a);
  return n.editor.defineTheme(r, {
    // Match the base of keeper-dark / keeper-light so all keeper themes
    // produce identical mtkN→kind orderings in their colorMaps — required
    // by the per-host theme patch.
    base: "vs",
    inherit: !0,
    rules: [...i ? Z : ee],
    colors: {
      "editor.background": a,
      "editor.foreground": o("--p-text-color", i ? "#fafafa" : "#18181b"),
      "editor.lineHighlightBackground": o("--p-content-hover-background", i ? "#2b2927" : "#f4f4f5"),
      "editor.selectionBackground": i ? "#1e222c80" : "#bfdbfe",
      "editorCursor.foreground": o("--p-primary-500", "#f59e0b"),
      "editorLineNumber.foreground": o("--p-text-muted-color", "#a1a1aa"),
      "editorLineNumber.activeForeground": o("--p-text-color", i ? "#fafafa" : "#18181b"),
      "editor.inactiveSelectionBackground": o("--p-content-hover-background", i ? "#2b2927" : "#f4f4f5"),
      "editorIndentGuide.background": o("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "editorWidget.background": o("--p-content-hover-background", i ? "#2b2927" : "#f4f4f5"),
      "editorWidget.border": o("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "input.background": o("--p-content-background", a),
      "input.border": o("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "scrollbarSlider.background": i ? "#1e222c80" : "#a1a1aa80",
      "scrollbarSlider.hoverBackground": i ? "#2a2f3a" : "#71717a",
      "diffEditor.insertedTextBackground": i ? "#34d39920" : "#16a34a20",
      "diffEditor.removedTextBackground": i ? "#f8717120" : "#dc262620",
      "diffEditor.insertedLineBackground": i ? "#34d39910" : "#16a34a10",
      "diffEditor.removedLineBackground": i ? "#f8717110" : "#dc262610"
    }
  }), r;
}
function Ze(n) {
  const e = n.startsWith("#") ? n.slice(1) : null;
  if (e) {
    const t = e.length === 3 ? e.split("").map((o) => o + o).join("") : e.length >= 6 ? e.slice(0, 6) : null;
    if (t) {
      const o = parseInt(t.slice(0, 2), 16), a = parseInt(t.slice(2, 4), 16), i = parseInt(t.slice(4, 6), 16);
      return $(o, a, i) < 0.5;
    }
  }
  const r = /rgba?\(\s*(\d+)[^\d]+(\d+)[^\d]+(\d+)/.exec(n);
  return r ? $(+r[1], +r[2], +r[3]) < 0.5 : !0;
}
function $(n, e, r) {
  return (0.2126 * n + 0.7152 * e + 0.0722 * r) / 255;
}
function B(n, e, r) {
  switch (e) {
    case "keeper-dark":
      return X;
    case "keeper-light":
      return Q;
    default:
      return Qe(n, r);
  }
}
const er = {
  key: 0,
  class: "monaco-status",
  role: "status"
}, rr = {
  key: 1,
  class: "monaco-status error",
  role: "alert"
}, tr = {
  ref: "container",
  class: "monaco-container"
}, or = /* @__PURE__ */ se({
  __name: "monaco-host",
  setup(n) {
    const e = Ke(), r = Ue(), t = ae(() => {
      const s = e.value?.["min-height"];
      return s && s > 0 ? { minHeight: `${s}px` } : void 0;
    }), o = ce("container"), a = k({ kind: "loading" }), i = _(null), p = _(null), u = _(null), c = _(null), f = _(null);
    let v = null, b = null, y = null, C = !1, E = null, g = null;
    function S(s) {
      const l = s.getRootNode();
      return l instanceof ShadowRoot ? l.host : s;
    }
    function N() {
      return e.value.mode === "diff" ? "diff" : "editor";
    }
    function R() {
      const s = i.value;
      if (!s)
        return;
      const l = o.value;
      if (!l)
        return;
      const d = g ?? S(l), h = B(s, e.value.theme, d);
      O(d, h);
    }
    function D() {
      if (e.value.theme && e.value.theme !== "auto")
        return;
      const s = document.documentElement;
      v = new MutationObserver(() => R()), v.observe(s, { attributes: !0, attributeFilter: ["data-theme", "class"] }), b = window.matchMedia("(prefers-color-scheme: dark)"), y = () => R(), b.addEventListener("change", y);
    }
    function H() {
      v?.disconnect(), v = null, b && y && b.removeEventListener("change", y), b = null, y = null;
    }
    function re() {
      H(), p.value?.dispose(), p.value = null;
      const s = u.value;
      u.value = null, s?.setModel(null), s?.dispose(), c.value?.dispose(), f.value?.dispose(), c.value = null, f.value = null, E?.(), E = null, g && Fe(g), g = null;
    }
    async function te(s, l) {
      g = S(l);
      const d = B(s, e.value.theme, g);
      O(g, d), p.value = s.editor.create(l, {
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
        if (C)
          return;
        const h = p.value?.getValue() ?? "";
        r("change", { value: h });
      });
    }
    async function oe(s, l) {
      g = S(l);
      const d = B(s, e.value.theme, g);
      O(g, d), u.value = s.editor.createDiffEditor(l, {
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
      }), W(s);
    }
    function W(s) {
      const l = u.value;
      if (!l)
        return;
      const d = e.value.language || "plaintext", h = c.value, m = f.value, V = s.editor.createModel(e.value.baseline || "", d), z = s.editor.createModel(e.value.current || "", d);
      c.value = V, f.value = z, l.setModel({ original: V, modified: z }), h?.dispose(), m?.dispose();
    }
    function ne(s) {
      const l = s.getRootNode();
      if (!(l instanceof ShadowRoot) || l.querySelector("style[data-wippy-monaco-css]"))
        return;
      const d = je();
      if (!d)
        return;
      const h = document.createElement("style");
      h.setAttribute("data-wippy-monaco-css", ""), h.textContent = d, l.appendChild(h);
    }
    return le(async () => {
      const s = o.value;
      if (!s) {
        a.value = { kind: "error", message: "monaco container missing" };
        return;
      }
      try {
        const l = await Ge();
        ne(s);
        const d = s.getRootNode();
        d instanceof ShadowRoot && (E = $e(d)), i.value = l, N() === "diff" ? await oe(l, s) : await te(l, s), D(), a.value = { kind: "ready" }, r("load", void 0);
      } catch (l) {
        const d = l instanceof Error ? l.message : String(l);
        a.value = { kind: "error", message: d }, r("error", { message: d, error: l });
      }
    }), P(() => {
      const s = p.value;
      if (!s)
        return;
      const l = e.value.value ?? "";
      s.getValue() !== l && (C = !0, s.setValue(l), C = !1);
    }), P(() => {
      const s = p.value;
      s && s.updateOptions({ readOnly: e.value.readonly === !0 });
    }), P(() => {
      const s = i.value, l = p.value, d = u.value, h = e.value.language || "plaintext";
      if (s && l) {
        const m = l.getModel();
        m && m.getLanguageId() !== h && s.editor.setModelLanguage(m, h);
      }
      if (s && d) {
        const m = d.getModel();
        m && (m.original.getLanguageId() !== h && s.editor.setModelLanguage(m.original, h), m.modified.getLanguageId() !== h && s.editor.setModelLanguage(m.modified, h));
      }
    }), K(() => [e.value.baseline, e.value.current], () => {
      const s = i.value;
      s && N() === "diff" && W(s);
    }), K(() => e.value.theme, () => {
      H(), R(), D();
    }), pe(() => {
      re(), r("unload", void 0);
    }), (s, l) => (L(), T("div", {
      class: "monaco-host",
      style: de(t.value)
    }, [
      a.value.kind === "loading" ? (L(), T("div", er, " Loading editor… ")) : a.value.kind === "error" ? (L(), T("div", rr, ue(a.value.message), 1)) : fe("", !0),
      he(me("div", tr, null, 512), [
        [ge, a.value.kind === "ready"]
      ])
    ], 4));
  }
}), nr = ":root{--p-primary: rgb(0, 95, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-secondary: #6f7385;--p-secondary-50: color-mix(in srgb, var(--p-secondary) 5%, white);--p-secondary-100: color-mix(in srgb, var(--p-secondary) 10%, white);--p-secondary-200: color-mix(in srgb, var(--p-secondary) 20%, white);--p-secondary-300: color-mix(in srgb, var(--p-secondary) 35%, white);--p-secondary-400: color-mix(in srgb, var(--p-secondary) 65%, white);--p-secondary-500: var(--p-secondary);--p-secondary-600: color-mix(in srgb, var(--p-secondary) 80%, black);--p-secondary-700: color-mix(in srgb, var(--p-secondary) 65%, black);--p-secondary-800: color-mix(in srgb, var(--p-secondary) 55%, black);--p-secondary-900: color-mix(in srgb, var(--p-secondary) 50%, black);--p-secondary-950: color-mix(in srgb, var(--p-secondary) 30%, black);--p-danger: rgb(239, 68, 68);--p-danger-50: color-mix(in srgb, var(--p-danger) 5%, white);--p-danger-100: color-mix(in srgb, var(--p-danger) 10%, white);--p-danger-200: color-mix(in srgb, var(--p-danger) 20%, white);--p-danger-300: color-mix(in srgb, var(--p-danger) 30%, white);--p-danger-400: color-mix(in srgb, var(--p-danger) 40%, white);--p-danger-500: var(--p-danger);--p-danger-600: color-mix(in srgb, var(--p-danger) 80%, black);--p-danger-700: color-mix(in srgb, var(--p-danger) 70%, black);--p-danger-800: color-mix(in srgb, var(--p-danger) 60%, black);--p-danger-900: color-mix(in srgb, var(--p-danger) 50%, black);--p-danger-950: color-mix(in srgb, var(--p-danger) 40%, black);--p-success: rgb(34, 197, 94);--p-success-50: color-mix(in srgb, var(--p-success) 5%, white);--p-success-100: color-mix(in srgb, var(--p-success) 10%, white);--p-success-200: color-mix(in srgb, var(--p-success) 20%, white);--p-success-300: color-mix(in srgb, var(--p-success) 30%, white);--p-success-400: color-mix(in srgb, var(--p-success) 40%, white);--p-success-500: var(--p-success);--p-success-600: color-mix(in srgb, var(--p-success) 80%, black);--p-success-700: color-mix(in srgb, var(--p-success) 70%, black);--p-success-800: color-mix(in srgb, var(--p-success) 60%, black);--p-success-900: color-mix(in srgb, var(--p-success) 50%, black);--p-success-950: color-mix(in srgb, var(--p-success) 40%, black);--p-warn: rgb(249, 115, 22);--p-warn-50: color-mix(in srgb, var(--p-warn) 5%, white);--p-warn-100: color-mix(in srgb, var(--p-warn) 10%, white);--p-warn-200: color-mix(in srgb, var(--p-warn) 20%, white);--p-warn-300: color-mix(in srgb, var(--p-warn) 30%, white);--p-warn-400: color-mix(in srgb, var(--p-warn) 40%, white);--p-warn-500: var(--p-warn);--p-warn-600: color-mix(in srgb, var(--p-warn) 80%, black);--p-warn-700: color-mix(in srgb, var(--p-warn) 70%, black);--p-warn-800: color-mix(in srgb, var(--p-warn) 60%, black);--p-warn-900: color-mix(in srgb, var(--p-warn) 50%, black);--p-warn-950: color-mix(in srgb, var(--p-warn) 40%, black);--p-info: rgb(14, 165, 233);--p-info-50: color-mix(in srgb, var(--p-info) 5%, white);--p-info-100: color-mix(in srgb, var(--p-info) 10%, white);--p-info-200: color-mix(in srgb, var(--p-info) 20%, white);--p-info-300: color-mix(in srgb, var(--p-info) 30%, white);--p-info-400: color-mix(in srgb, var(--p-info) 40%, white);--p-info-500: var(--p-info);--p-info-600: color-mix(in srgb, var(--p-info) 80%, black);--p-info-700: color-mix(in srgb, var(--p-info) 70%, black);--p-info-800: color-mix(in srgb, var(--p-info) 60%, black);--p-info-900: color-mix(in srgb, var(--p-info) 50%, black);--p-info-950: color-mix(in srgb, var(--p-info) 40%, black);--p-help: rgb(168, 85, 247);--p-help-50: color-mix(in srgb, var(--p-help) 5%, white);--p-help-100: color-mix(in srgb, var(--p-help) 10%, white);--p-help-200: color-mix(in srgb, var(--p-help) 20%, white);--p-help-300: color-mix(in srgb, var(--p-help) 30%, white);--p-help-400: color-mix(in srgb, var(--p-help) 40%, white);--p-help-500: var(--p-help);--p-help-600: color-mix(in srgb, var(--p-help) 80%, black);--p-help-700: color-mix(in srgb, var(--p-help) 70%, black);--p-help-800: color-mix(in srgb, var(--p-help) 60%, black);--p-help-900: color-mix(in srgb, var(--p-help) 50%, black);--p-help-950: color-mix(in srgb, var(--p-help) 40%, black);--p-accent: rgb(20, 184, 166);--p-accent-50: color-mix(in srgb, var(--p-accent) 5%, white);--p-accent-100: color-mix(in srgb, var(--p-accent) 10%, white);--p-accent-200: color-mix(in srgb, var(--p-accent) 20%, white);--p-accent-300: color-mix(in srgb, var(--p-accent) 30%, white);--p-accent-400: color-mix(in srgb, var(--p-accent) 40%, white);--p-accent-500: var(--p-accent);--p-accent-600: color-mix(in srgb, var(--p-accent) 80%, black);--p-accent-700: color-mix(in srgb, var(--p-accent) 70%, black);--p-accent-800: color-mix(in srgb, var(--p-accent) 60%, black);--p-accent-900: color-mix(in srgb, var(--p-accent) 50%, black);--p-accent-950: color-mix(in srgb, var(--p-accent) 40%, black);--p-surface-0: #ffffff;--p-surface-50: #fafafa;--p-surface-100: #f5f5f5;--p-surface-200: #e5e5e5;--p-surface-300: #d4d4d4;--p-surface-400: #a3a3a3;--p-surface-500: #737373;--p-surface-600: #525252;--p-surface-700: #404040;--p-surface-800: #262626;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #171717;--p-surface-950: #0a0a0a;--p-content-border-radius: 6px}:root{--p-primary-color: var(--p-primary-500);--p-primary-contrast-color: var(--p-surface-0);--p-primary-hover-color: var(--p-primary-600);--p-primary-active-color: var(--p-primary-700);--p-content-border-color: var(--p-surface-200);--p-content-hover-background: var(--p-surface-100);--p-content-hover-color: var(--p-surface-800);--p-highlight-background: var(--p-primary-50);--p-highlight-color: var(--p-primary-700);--p-highlight-focus-background: var(--p-primary-100);--p-highlight-focus-color: var(--p-primary-800);--p-content-background: var(--p-surface-0);--p-text-color: var(--p-surface-700);--p-text-hover-color: var(--p-surface-800);--p-text-muted-color: var(--p-surface-500);--p-text-hover-muted-color: var(--p-surface-600)}@media(prefers-color-scheme:dark){:root{--p-surface-D: #fff;--p-surface-0: #fff;--p-surface-50: #fafafa;--p-surface-100: #f4f4f5;--p-surface-200: #e4e4e7;--p-surface-300: #d4d4d8;--p-surface-400: #a1a1aa;--p-surface-500: #71717a;--p-surface-600: #545250;--p-surface-700: #403e3c;--p-surface-800: #2b2927;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #1c1a19;--p-surface-950: #0f0e0d;--p-primary: rgb(0, 125, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-primary-color: var(--p-primary-400);--p-primary-contrast-color: var(--p-surface-900);--p-primary-hover-color: var(--p-primary-300);--p-primary-active-color: var(--p-primary-200);--p-content-border-color: var(--p-surface-700);--p-content-hover-background: var(--p-surface-800);--p-content-hover-color: var(--p-surface-0);--p-highlight-background: color-mix(in srgb, var(--p-primary-400), transparent 84%);--p-highlight-color: rgba(255, 255, 255, 87%);--p-highlight-focus-background: color-mix(in srgb, var(--p-primary-400), transparent 76%);--p-highlight-focus-color: rgba(255, 255, 255, 87%);--p-content-background: var(--p-surface-900);--p-text-color: var(--p-surface-0);--p-text-hover-color: var(--p-surface-0);--p-text-muted-color: var(--p-surface-400);--p-text-hover-muted-color: var(--p-surface-300)}}:host{display:block;width:100%;height:100%;box-sizing:border-box}:host>div{width:100%;height:100%}.monaco-host{width:100%;height:100%;box-sizing:border-box;display:flex;flex-direction:column}.monaco-container{flex:1 1 auto;width:100%;height:100%;min-height:100px;border:1px solid var(--p-content-border-color);border-radius:4px;overflow:hidden}.monaco-status{flex:1 1 auto;display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;font-size:13px;color:var(--p-text-muted-color);border:1px solid var(--p-content-border-color);border-radius:4px;padding:12px}.monaco-status.error{color:var(--p-danger-color)}", ir = { props: { type: "object", properties: { mode: { type: "string", enum: ["editor", "diff"], default: "editor", description: "Editor mode (single buffer) or diff mode (baseline vs current)." }, language: { type: "string", default: "plaintext", description: "Monaco language id (e.g. lua, javascript, typescript, json, markdown)." }, value: { type: "string", default: "", description: "Initial buffer value for editor mode. Ignored in diff mode." }, baseline: { type: "string", default: "", description: "Original side of the diff (read-only). Diff mode only." }, current: { type: "string", default: "", description: "Modified side of the diff (read-only). Diff mode only." }, readonly: { type: "boolean", default: !1, description: "Editor mode only. Diff mode is always read-only." }, theme: { type: "string", enum: ["auto", "keeper-dark", "keeper-light"], default: "auto", description: "Color theme. `auto` derives from app CSS variables (--p-content-background, --p-text-color, --p-primary-500, --p-surface-*) and re-themes on prefers-color-scheme / [data-theme] changes. `keeper-dark` and `keeper-light` are fixed presets." }, "min-height": { type: "number", default: 0, description: "Minimum height in px. 0 means fill the container." } } } }, sr = {
  wippy: ir
};
class ar extends ze {
  static get wippyConfig() {
    return {
      propsSchema: sr.wippy.props,
      hostCssKeys: ["themeConfigUrl"],
      inlineCss: nr
    };
  }
  static get vueConfig() {
    return {
      rootComponent: or
    };
  }
}
ke(import.meta.url, ar);
//# sourceMappingURL=index.js.map
