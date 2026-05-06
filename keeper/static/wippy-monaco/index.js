import { inject as ge, defineComponent as Be, ref as R, shallowRef as M, onMounted as He, watch as q, onUnmounted as xt, h as _e, nextTick as kt, hasInjectionContext as _t, effectScope as St, markRaw as We, toRaw as Y, unref as Et, createApp as It, computed as Ct, useTemplateRef as Ot, watchEffect as ne, onBeforeUnmount as Tt, openBlock as re, createElementBlock as oe, normalizeStyle as Pt, toDisplayString as At, createCommentVNode as Rt, withDirectives as Lt, createElementVNode as Nt, vShow as jt } from "vue";
import { hostCss as Mt, loadCss as Dt, addIcons as $t, define as Vt } from "@wippy-fe/proxy";
const ze = Symbol("wippy:emit"), Ge = Symbol("wippy:props"), Ft = Symbol("wippy:props_error"), Ut = Symbol("wippy:content"), Bt = Symbol("wippy:panel-id"), Ht = Symbol("wippy:layout-bus"), Wt = Symbol("wippy:host");
function zt() {
  const e = ge(Ge);
  if (!e)
    throw new Error("useProps() must be called inside a WippyVueElement");
  return e;
}
function Gt() {
  const e = ge(ze);
  if (!e)
    throw new Error("useEvents() must be called inside a WippyVueElement");
  return e;
}
const Ke = /^[a-z0-9]+(-[a-z0-9]+)*$/, ee = (e, t, n, r = "") => {
  const o = e.split(":");
  if (e.slice(0, 1) === "@") {
    if (o.length < 2 || o.length > 3)
      return null;
    r = o.shift().slice(1);
  }
  if (o.length > 3 || !o.length)
    return null;
  if (o.length > 1) {
    const a = o.pop(), c = o.pop(), l = {
      // Allow provider without '@': "provider:prefix:name"
      provider: o.length > 0 ? o[0] : r,
      prefix: c,
      name: a
    };
    return t && !H(l) ? null : l;
  }
  const i = o[0], s = i.split("-");
  if (s.length > 1) {
    const a = {
      provider: r,
      prefix: s.shift(),
      name: s.join("-")
    };
    return t && !H(a) ? null : a;
  }
  if (n && r === "") {
    const a = {
      provider: r,
      prefix: "",
      name: i
    };
    return t && !H(a, n) ? null : a;
  }
  return null;
}, H = (e, t) => e ? !!// Check prefix: cannot be empty, unless allowSimpleName is enabled
// Check name: cannot be empty
((t && e.prefix === "" || e.prefix) && e.name) : !1, Qe = Object.freeze(
  {
    left: 0,
    top: 0,
    width: 16,
    height: 16
  }
), X = Object.freeze({
  rotate: 0,
  vFlip: !1,
  hFlip: !1
}), te = Object.freeze({
  ...Qe,
  ...X
}), le = Object.freeze({
  ...te,
  body: "",
  hidden: !1
});
function Kt(e, t) {
  const n = {};
  !e.hFlip != !t.hFlip && (n.hFlip = !0), !e.vFlip != !t.vFlip && (n.vFlip = !0);
  const r = ((e.rotate || 0) + (t.rotate || 0)) % 4;
  return r && (n.rotate = r), n;
}
function Se(e, t) {
  const n = Kt(e, t);
  for (const r in le)
    r in X ? r in e && !(r in n) && (n[r] = X[r]) : r in t ? n[r] = t[r] : r in e && (n[r] = e[r]);
  return n;
}
function Qt(e, t) {
  const n = e.icons, r = e.aliases || /* @__PURE__ */ Object.create(null), o = /* @__PURE__ */ Object.create(null);
  function i(s) {
    if (n[s])
      return o[s] = [];
    if (!(s in o)) {
      o[s] = null;
      const a = r[s] && r[s].parent, c = a && i(a);
      c && (o[s] = [a].concat(c));
    }
    return o[s];
  }
  return Object.keys(n).concat(Object.keys(r)).forEach(i), o;
}
function Jt(e, t, n) {
  const r = e.icons, o = e.aliases || /* @__PURE__ */ Object.create(null);
  let i = {};
  function s(a) {
    i = Se(
      r[a] || o[a],
      i
    );
  }
  return s(t), n.forEach(s), Se(e, i);
}
function Je(e, t) {
  const n = [];
  if (typeof e != "object" || typeof e.icons != "object")
    return n;
  e.not_found instanceof Array && e.not_found.forEach((o) => {
    t(o, null), n.push(o);
  });
  const r = Qt(e);
  for (const o in r) {
    const i = r[o];
    i && (t(o, Jt(e, o, i)), n.push(o));
  }
  return n;
}
const qt = {
  provider: "",
  aliases: {},
  not_found: {},
  ...Qe
};
function ie(e, t) {
  for (const n in t)
    if (n in e && typeof e[n] != typeof t[n])
      return !1;
  return !0;
}
function qe(e) {
  if (typeof e != "object" || e === null)
    return null;
  const t = e;
  if (typeof t.prefix != "string" || !e.icons || typeof e.icons != "object" || !ie(e, qt))
    return null;
  const n = t.icons;
  for (const o in n) {
    const i = n[o];
    if (
      // Name cannot be empty
      !o || // Must have body
      typeof i.body != "string" || // Check other props
      !ie(
        i,
        le
      )
    )
      return null;
  }
  const r = t.aliases || /* @__PURE__ */ Object.create(null);
  for (const o in r) {
    const i = r[o], s = i.parent;
    if (
      // Name cannot be empty
      !o || // Parent must be set and point to existing icon
      typeof s != "string" || !n[s] && !r[s] || // Check other props
      !ie(
        i,
        le
      )
    )
      return null;
  }
  return t;
}
const Ee = /* @__PURE__ */ Object.create(null);
function Yt(e, t) {
  return {
    provider: e,
    prefix: t,
    icons: /* @__PURE__ */ Object.create(null),
    missing: /* @__PURE__ */ new Set()
  };
}
function $(e, t) {
  const n = Ee[e] || (Ee[e] = /* @__PURE__ */ Object.create(null));
  return n[t] || (n[t] = Yt(e, t));
}
function Ye(e, t) {
  return qe(t) ? Je(t, (n, r) => {
    r ? e.icons[n] = r : e.missing.add(n);
  }) : [];
}
function Xt(e, t, n) {
  try {
    if (typeof n.body == "string")
      return e.icons[t] = { ...n }, !0;
  } catch {
  }
  return !1;
}
let B = !1;
function Xe(e) {
  return typeof e == "boolean" && (B = e), B;
}
function Zt(e) {
  const t = typeof e == "string" ? ee(e, !0, B) : e;
  if (t) {
    const n = $(t.provider, t.prefix), r = t.name;
    return n.icons[r] || (n.missing.has(r) ? null : void 0);
  }
}
function en(e, t) {
  const n = ee(e, !0, B);
  if (!n)
    return !1;
  const r = $(n.provider, n.prefix);
  return t ? Xt(r, n.name, t) : (r.missing.add(n.name), !0);
}
function Ze(e, t) {
  if (typeof e != "object")
    return !1;
  if (typeof t != "string" && (t = e.provider || ""), B && !t && !e.prefix) {
    let o = !1;
    return qe(e) && (e.prefix = "", Je(e, (i, s) => {
      en(i, s) && (o = !0);
    })), o;
  }
  const n = e.prefix;
  if (!H({
    prefix: n,
    name: "a"
  }))
    return !1;
  const r = $(t, n);
  return !!Ye(r, e);
}
const et = Object.freeze({
  width: null,
  height: null
}), tt = Object.freeze({
  // Dimensions
  ...et,
  // Transformations
  ...X
}), tn = /(-?[0-9.]*[0-9]+[0-9.]*)/g, nn = /^-?[0-9.]*[0-9]+[0-9.]*$/g;
function Ie(e, t, n) {
  if (t === 1)
    return e;
  if (n = n || 100, typeof e == "number")
    return Math.ceil(e * t * n) / n;
  if (typeof e != "string")
    return e;
  const r = e.split(tn);
  if (r === null || !r.length)
    return e;
  const o = [];
  let i = r.shift(), s = nn.test(i);
  for (; ; ) {
    if (s) {
      const a = parseFloat(i);
      isNaN(a) ? o.push(i) : o.push(Math.ceil(a * t * n) / n);
    } else
      o.push(i);
    if (i = r.shift(), i === void 0)
      return o.join("");
    s = !s;
  }
}
function rn(e, t = "defs") {
  let n = "";
  const r = e.indexOf("<" + t);
  for (; r >= 0; ) {
    const o = e.indexOf(">", r), i = e.indexOf("</" + t);
    if (o === -1 || i === -1)
      break;
    const s = e.indexOf(">", i);
    if (s === -1)
      break;
    n += e.slice(o + 1, i).trim(), e = e.slice(0, r).trim() + e.slice(s + 1);
  }
  return {
    defs: n,
    content: e
  };
}
function on(e, t) {
  return e ? "<defs>" + e + "</defs>" + t : t;
}
function sn(e, t, n) {
  const r = rn(e);
  return on(r.defs, t + r.content + n);
}
const an = (e) => e === "unset" || e === "undefined" || e === "none";
function cn(e, t) {
  const n = {
    ...te,
    ...e
  }, r = {
    ...tt,
    ...t
  }, o = {
    left: n.left,
    top: n.top,
    width: n.width,
    height: n.height
  };
  let i = n.body;
  [n, r].forEach((b) => {
    const p = [], T = b.hFlip, O = b.vFlip;
    let E = b.rotate;
    T ? O ? E += 2 : (p.push(
      "translate(" + (o.width + o.left).toString() + " " + (0 - o.top).toString() + ")"
    ), p.push("scale(-1 1)"), o.top = o.left = 0) : O && (p.push(
      "translate(" + (0 - o.left).toString() + " " + (o.height + o.top).toString() + ")"
    ), p.push("scale(1 -1)"), o.top = o.left = 0);
    let S;
    switch (E < 0 && (E -= Math.floor(E / 4) * 4), E = E % 4, E) {
      case 1:
        S = o.height / 2 + o.top, p.unshift(
          "rotate(90 " + S.toString() + " " + S.toString() + ")"
        );
        break;
      case 2:
        p.unshift(
          "rotate(180 " + (o.width / 2 + o.left).toString() + " " + (o.height / 2 + o.top).toString() + ")"
        );
        break;
      case 3:
        S = o.width / 2 + o.left, p.unshift(
          "rotate(-90 " + S.toString() + " " + S.toString() + ")"
        );
        break;
    }
    E % 2 === 1 && (o.left !== o.top && (S = o.left, o.left = o.top, o.top = S), o.width !== o.height && (S = o.width, o.width = o.height, o.height = S)), p.length && (i = sn(
      i,
      '<g transform="' + p.join(" ") + '">',
      "</g>"
    ));
  });
  const s = r.width, a = r.height, c = o.width, l = o.height;
  let u, d;
  s === null ? (d = a === null ? "1em" : a === "auto" ? l : a, u = Ie(d, c / l)) : (u = s === "auto" ? c : s, d = a === null ? Ie(u, l / c) : a === "auto" ? l : a);
  const h = {}, v = (b, p) => {
    an(p) || (h[b] = p.toString());
  };
  v("width", u), v("height", d);
  const y = [o.left, o.top, c, l];
  return h.viewBox = y.join(" "), {
    attributes: h,
    viewBox: y,
    body: i
  };
}
const ln = /\sid="(\S+)"/g, un = "IconifyId" + Date.now().toString(16) + (Math.random() * 16777216 | 0).toString(16);
let fn = 0;
function dn(e, t = un) {
  const n = [];
  let r;
  for (; r = ln.exec(e); )
    n.push(r[1]);
  if (!n.length)
    return e;
  const o = "suffix" + (Math.random() * 16777216 | Date.now()).toString(16);
  return n.forEach((i) => {
    const s = typeof t == "function" ? t(i) : t + (fn++).toString(), a = i.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    e = e.replace(
      // Allowed characters before id: [#;"]
      // Allowed characters after id: [)"], .[a-z]
      new RegExp('([#;"])(' + a + ')([")]|\\.[a-z])', "g"),
      "$1" + s + o + "$3"
    );
  }), e = e.replace(new RegExp(o, "g"), ""), e;
}
const ue = /* @__PURE__ */ Object.create(null);
function pn(e, t) {
  ue[e] = t;
}
function fe(e) {
  return ue[e] || ue[""];
}
function me(e) {
  let t;
  if (typeof e.resources == "string")
    t = [e.resources];
  else if (t = e.resources, !(t instanceof Array) || !t.length)
    return null;
  return {
    // API hosts
    resources: t,
    // Root path
    path: e.path || "/",
    // URL length limit
    maxURL: e.maxURL || 500,
    // Timeout before next host is used.
    rotate: e.rotate || 750,
    // Timeout before failing query.
    timeout: e.timeout || 5e3,
    // Randomise default API end point.
    random: e.random === !0,
    // Start index
    index: e.index || 0,
    // Receive data after time out (used if time out kicks in first, then API module sends data anyway).
    dataAfterTimeout: e.dataAfterTimeout !== !1
  };
}
const ve = /* @__PURE__ */ Object.create(null), F = [
  "https://api.simplesvg.com",
  "https://api.unisvg.com"
], W = [];
for (; F.length > 0; )
  F.length === 1 || Math.random() > 0.5 ? W.push(F.shift()) : W.push(F.pop());
ve[""] = me({
  resources: ["https://api.iconify.design"].concat(W)
});
function hn(e, t) {
  const n = me(t);
  return n === null ? !1 : (ve[e] = n, !0);
}
function be(e) {
  return ve[e];
}
const gn = () => {
  let e;
  try {
    if (e = fetch, typeof e == "function")
      return e;
  } catch {
  }
};
let Ce = gn();
function mn(e, t) {
  const n = be(e);
  if (!n)
    return 0;
  let r;
  if (!n.maxURL)
    r = 0;
  else {
    let o = 0;
    n.resources.forEach((s) => {
      o = Math.max(o, s.length);
    });
    const i = t + ".json?icons=";
    r = n.maxURL - o - n.path.length - i.length;
  }
  return r;
}
function vn(e) {
  return e === 404;
}
const bn = (e, t, n) => {
  const r = [], o = mn(e, t), i = "icons";
  let s = {
    type: i,
    provider: e,
    prefix: t,
    icons: []
  }, a = 0;
  return n.forEach((c, l) => {
    a += c.length + 1, a >= o && l > 0 && (r.push(s), s = {
      type: i,
      provider: e,
      prefix: t,
      icons: []
    }, a = c.length), s.icons.push(c);
  }), r.push(s), r;
};
function yn(e) {
  if (typeof e == "string") {
    const t = be(e);
    if (t)
      return t.path;
  }
  return "/";
}
const wn = (e, t, n) => {
  if (!Ce) {
    n("abort", 424);
    return;
  }
  let r = yn(t.provider);
  switch (t.type) {
    case "icons": {
      const i = t.prefix, a = t.icons.join(","), c = new URLSearchParams({
        icons: a
      });
      r += i + ".json?" + c.toString();
      break;
    }
    case "custom": {
      const i = t.uri;
      r += i.slice(0, 1) === "/" ? i.slice(1) : i;
      break;
    }
    default:
      n("abort", 400);
      return;
  }
  let o = 503;
  Ce(e + r).then((i) => {
    const s = i.status;
    if (s !== 200) {
      setTimeout(() => {
        n(vn(s) ? "abort" : "next", s);
      });
      return;
    }
    return o = 501, i.json();
  }).then((i) => {
    if (typeof i != "object" || i === null) {
      setTimeout(() => {
        i === 404 ? n("abort", i) : n("next", o);
      });
      return;
    }
    setTimeout(() => {
      n("success", i);
    });
  }).catch(() => {
    n("next", o);
  });
}, xn = {
  prepare: bn,
  send: wn
};
function kn(e) {
  const t = {
    loaded: [],
    missing: [],
    pending: []
  }, n = /* @__PURE__ */ Object.create(null);
  e.sort((o, i) => o.provider !== i.provider ? o.provider.localeCompare(i.provider) : o.prefix !== i.prefix ? o.prefix.localeCompare(i.prefix) : o.name.localeCompare(i.name));
  let r = {
    provider: "",
    prefix: "",
    name: ""
  };
  return e.forEach((o) => {
    if (r.name === o.name && r.prefix === o.prefix && r.provider === o.provider)
      return;
    r = o;
    const i = o.provider, s = o.prefix, a = o.name, c = n[i] || (n[i] = /* @__PURE__ */ Object.create(null)), l = c[s] || (c[s] = $(i, s));
    let u;
    a in l.icons ? u = t.loaded : s === "" || l.missing.has(a) ? u = t.missing : u = t.pending;
    const d = {
      provider: i,
      prefix: s,
      name: a
    };
    u.push(d);
  }), t;
}
function nt(e, t) {
  e.forEach((n) => {
    const r = n.loaderCallbacks;
    r && (n.loaderCallbacks = r.filter((o) => o.id !== t));
  });
}
function _n(e) {
  e.pendingCallbacksFlag || (e.pendingCallbacksFlag = !0, setTimeout(() => {
    e.pendingCallbacksFlag = !1;
    const t = e.loaderCallbacks ? e.loaderCallbacks.slice(0) : [];
    if (!t.length)
      return;
    let n = !1;
    const r = e.provider, o = e.prefix;
    t.forEach((i) => {
      const s = i.icons, a = s.pending.length;
      s.pending = s.pending.filter((c) => {
        if (c.prefix !== o)
          return !0;
        const l = c.name;
        if (e.icons[l])
          s.loaded.push({
            provider: r,
            prefix: o,
            name: l
          });
        else if (e.missing.has(l))
          s.missing.push({
            provider: r,
            prefix: o,
            name: l
          });
        else
          return n = !0, !0;
        return !1;
      }), s.pending.length !== a && (n || nt([e], i.id), i.callback(
        s.loaded.slice(0),
        s.missing.slice(0),
        s.pending.slice(0),
        i.abort
      ));
    });
  }));
}
let Sn = 0;
function En(e, t, n) {
  const r = Sn++, o = nt.bind(null, n, r);
  if (!t.pending.length)
    return o;
  const i = {
    id: r,
    icons: t,
    callback: e,
    abort: o
  };
  return n.forEach((s) => {
    (s.loaderCallbacks || (s.loaderCallbacks = [])).push(i);
  }), o;
}
function In(e, t = !0, n = !1) {
  const r = [];
  return e.forEach((o) => {
    const i = typeof o == "string" ? ee(o, t, n) : o;
    i && r.push(i);
  }), r;
}
var Cn = {
  resources: [],
  index: 0,
  timeout: 2e3,
  rotate: 750,
  random: !1,
  dataAfterTimeout: !1
};
function On(e, t, n, r) {
  const o = e.resources.length, i = e.random ? Math.floor(Math.random() * o) : e.index;
  let s;
  if (e.random) {
    let m = e.resources.slice(0);
    for (s = []; m.length > 1; ) {
      const f = Math.floor(Math.random() * m.length);
      s.push(m[f]), m = m.slice(0, f).concat(m.slice(f + 1));
    }
    s = s.concat(m);
  } else
    s = e.resources.slice(i).concat(e.resources.slice(0, i));
  const a = Date.now();
  let c = "pending", l = 0, u, d = null, h = [], v = [];
  typeof r == "function" && v.push(r);
  function y() {
    d && (clearTimeout(d), d = null);
  }
  function b() {
    c === "pending" && (c = "aborted"), y(), h.forEach((m) => {
      m.status === "pending" && (m.status = "aborted");
    }), h = [];
  }
  function p(m, f) {
    f && (v = []), typeof m == "function" && v.push(m);
  }
  function T() {
    return {
      startTime: a,
      payload: t,
      status: c,
      queriesSent: l,
      queriesPending: h.length,
      subscribe: p,
      abort: b
    };
  }
  function O() {
    c = "failed", v.forEach((m) => {
      m(void 0, u);
    });
  }
  function E() {
    h.forEach((m) => {
      m.status === "pending" && (m.status = "aborted");
    }), h = [];
  }
  function S(m, f, g) {
    const w = f !== "success";
    switch (h = h.filter((x) => x !== m), c) {
      case "pending":
        break;
      case "failed":
        if (w || !e.dataAfterTimeout)
          return;
        break;
      default:
        return;
    }
    if (f === "abort") {
      u = g, O();
      return;
    }
    if (w) {
      u = g, h.length || (s.length ? V() : O());
      return;
    }
    if (y(), E(), !e.random) {
      const x = e.resources.indexOf(m.resource);
      x !== -1 && x !== e.index && (e.index = x);
    }
    c = "completed", v.forEach((x) => {
      x(g);
    });
  }
  function V() {
    if (c !== "pending")
      return;
    y();
    const m = s.shift();
    if (m === void 0) {
      if (h.length) {
        d = setTimeout(() => {
          y(), c === "pending" && (E(), O());
        }, e.timeout);
        return;
      }
      O();
      return;
    }
    const f = {
      status: "pending",
      resource: m,
      callback: (g, w) => {
        S(f, g, w);
      }
    };
    h.push(f), l++, d = setTimeout(V, e.rotate), n(m, t, f.callback);
  }
  return setTimeout(V), T;
}
function rt(e) {
  const t = {
    ...Cn,
    ...e
  };
  let n = [];
  function r() {
    n = n.filter((a) => a().status === "pending");
  }
  function o(a, c, l) {
    const u = On(
      t,
      a,
      c,
      (d, h) => {
        r(), l && l(d, h);
      }
    );
    return n.push(u), u;
  }
  function i(a) {
    return n.find((c) => a(c)) || null;
  }
  return {
    query: o,
    find: i,
    setIndex: (a) => {
      t.index = a;
    },
    getIndex: () => t.index,
    cleanup: r
  };
}
function Oe() {
}
const se = /* @__PURE__ */ Object.create(null);
function Tn(e) {
  if (!se[e]) {
    const t = be(e);
    if (!t)
      return;
    const n = rt(t), r = {
      config: t,
      redundancy: n
    };
    se[e] = r;
  }
  return se[e];
}
function Pn(e, t, n) {
  let r, o;
  if (typeof e == "string") {
    const i = fe(e);
    if (!i)
      return n(void 0, 424), Oe;
    o = i.send;
    const s = Tn(e);
    s && (r = s.redundancy);
  } else {
    const i = me(e);
    if (i) {
      r = rt(i);
      const s = e.resources ? e.resources[0] : "", a = fe(s);
      a && (o = a.send);
    }
  }
  return !r || !o ? (n(void 0, 424), Oe) : r.query(t, o, n)().abort;
}
function Te() {
}
function An(e) {
  e.iconsLoaderFlag || (e.iconsLoaderFlag = !0, setTimeout(() => {
    e.iconsLoaderFlag = !1, _n(e);
  }));
}
function Rn(e) {
  const t = [], n = [];
  return e.forEach((r) => {
    (r.match(Ke) ? t : n).push(r);
  }), {
    valid: t,
    invalid: n
  };
}
function U(e, t, n) {
  function r() {
    const o = e.pendingIcons;
    t.forEach((i) => {
      o && o.delete(i), e.icons[i] || e.missing.add(i);
    });
  }
  if (n && typeof n == "object")
    try {
      if (!Ye(e, n).length) {
        r();
        return;
      }
    } catch (o) {
      console.error(o);
    }
  r(), An(e);
}
function Pe(e, t) {
  e instanceof Promise ? e.then((n) => {
    t(n);
  }).catch(() => {
    t(null);
  }) : t(e);
}
function Ln(e, t) {
  e.iconsToLoad ? e.iconsToLoad = e.iconsToLoad.concat(t).sort() : e.iconsToLoad = t, e.iconsQueueFlag || (e.iconsQueueFlag = !0, setTimeout(() => {
    e.iconsQueueFlag = !1;
    const { provider: n, prefix: r } = e, o = e.iconsToLoad;
    if (delete e.iconsToLoad, !o || !o.length)
      return;
    const i = e.loadIcon;
    if (e.loadIcons && (o.length > 1 || !i)) {
      Pe(
        e.loadIcons(o, r, n),
        (u) => {
          U(e, o, u);
        }
      );
      return;
    }
    if (i) {
      o.forEach((u) => {
        const d = i(u, r, n);
        Pe(d, (h) => {
          const v = h ? {
            prefix: r,
            icons: {
              [u]: h
            }
          } : null;
          U(e, [u], v);
        });
      });
      return;
    }
    const { valid: s, invalid: a } = Rn(o);
    if (a.length && U(e, a, null), !s.length)
      return;
    const c = r.match(Ke) ? fe(n) : null;
    if (!c) {
      U(e, s, null);
      return;
    }
    c.prepare(n, r, s).forEach((u) => {
      Pn(n, u, (d) => {
        U(e, u.icons, d);
      });
    });
  }));
}
const Nn = (e, t) => {
  const n = In(e, !0, Xe()), r = kn(n);
  if (!r.pending.length) {
    let c = !0;
    return t && setTimeout(() => {
      c && t(
        r.loaded,
        r.missing,
        r.pending,
        Te
      );
    }), () => {
      c = !1;
    };
  }
  const o = /* @__PURE__ */ Object.create(null), i = [];
  let s, a;
  return r.pending.forEach((c) => {
    const { provider: l, prefix: u } = c;
    if (u === a && l === s)
      return;
    s = l, a = u, i.push($(l, u));
    const d = o[l] || (o[l] = /* @__PURE__ */ Object.create(null));
    d[u] || (d[u] = []);
  }), r.pending.forEach((c) => {
    const { provider: l, prefix: u, name: d } = c, h = $(l, u), v = h.pendingIcons || (h.pendingIcons = /* @__PURE__ */ new Set());
    v.has(d) || (v.add(d), o[l][u].push(d));
  }), i.forEach((c) => {
    const l = o[c.provider][c.prefix];
    l.length && Ln(c, l);
  }), t ? En(t, r, i) : Te;
};
function jn(e, t) {
  const n = {
    ...e
  };
  for (const r in t) {
    const o = t[r], i = typeof o;
    r in et ? (o === null || o && (i === "string" || i === "number")) && (n[r] = o) : i === typeof n[r] && (n[r] = r === "rotate" ? o % 4 : o);
  }
  return n;
}
const Mn = /[\s,]+/;
function Dn(e, t) {
  t.split(Mn).forEach((n) => {
    switch (n.trim()) {
      case "horizontal":
        e.hFlip = !0;
        break;
      case "vertical":
        e.vFlip = !0;
        break;
    }
  });
}
function $n(e, t = 0) {
  const n = e.replace(/^-?[0-9.]*/, "");
  function r(o) {
    for (; o < 0; )
      o += 4;
    return o % 4;
  }
  if (n === "") {
    const o = parseInt(e);
    return isNaN(o) ? 0 : r(o);
  } else if (n !== e) {
    let o = 0;
    switch (n) {
      case "%":
        o = 25;
        break;
      case "deg":
        o = 90;
    }
    if (o) {
      let i = parseFloat(e.slice(0, e.length - n.length));
      return isNaN(i) ? 0 : (i = i / o, i % 1 === 0 ? r(i) : 0);
    }
  }
  return t;
}
function Vn(e, t) {
  let n = e.indexOf("xlink:") === -1 ? "" : ' xmlns:xlink="http://www.w3.org/1999/xlink"';
  for (const r in t)
    n += " " + r + '="' + t[r] + '"';
  return '<svg xmlns="http://www.w3.org/2000/svg"' + n + ">" + e + "</svg>";
}
function Fn(e) {
  return e.replace(/"/g, "'").replace(/%/g, "%25").replace(/#/g, "%23").replace(/</g, "%3C").replace(/>/g, "%3E").replace(/\s+/g, " ");
}
function Un(e) {
  return "data:image/svg+xml," + Fn(e);
}
function Bn(e) {
  return 'url("' + Un(e) + '")';
}
const Ae = {
  ...tt,
  inline: !1
}, Hn = {
  xmlns: "http://www.w3.org/2000/svg",
  "xmlns:xlink": "http://www.w3.org/1999/xlink",
  "aria-hidden": !0,
  role: "img"
}, Wn = {
  display: "inline-block"
}, de = {
  backgroundColor: "currentColor"
}, ot = {
  backgroundColor: "transparent"
}, Re = {
  Image: "var(--svg)",
  Repeat: "no-repeat",
  Size: "100% 100%"
}, Le = {
  webkitMask: de,
  mask: de,
  background: ot
};
for (const e in Le) {
  const t = Le[e];
  for (const n in Re)
    t[e + n] = Re[n];
}
const z = {};
["horizontal", "vertical"].forEach((e) => {
  const t = e.slice(0, 1) + "Flip";
  z[e + "-flip"] = t, z[e.slice(0, 1) + "-flip"] = t, z[e + "Flip"] = t;
});
function Ne(e) {
  return e + (e.match(/^[-0-9.]+$/) ? "px" : "");
}
const je = (e, t) => {
  const n = jn(Ae, t), r = { ...Hn }, o = t.mode || "svg", i = {}, s = t.style, a = typeof s == "object" && !(s instanceof Array) ? s : {};
  for (let b in t) {
    const p = t[b];
    if (p !== void 0)
      switch (b) {
        // Properties to ignore
        case "icon":
        case "style":
        case "onLoad":
        case "mode":
        case "ssr":
          break;
        // Boolean attributes
        case "inline":
        case "hFlip":
        case "vFlip":
          n[b] = p === !0 || p === "true" || p === 1;
          break;
        // Flip as string: 'horizontal,vertical'
        case "flip":
          typeof p == "string" && Dn(n, p);
          break;
        // Color: override style
        case "color":
          i.color = p;
          break;
        // Rotation as string
        case "rotate":
          typeof p == "string" ? n[b] = $n(p) : typeof p == "number" && (n[b] = p);
          break;
        // Remove aria-hidden
        case "ariaHidden":
        case "aria-hidden":
          p !== !0 && p !== "true" && delete r["aria-hidden"];
          break;
        default: {
          const T = z[b];
          T ? (p === !0 || p === "true" || p === 1) && (n[T] = !0) : Ae[b] === void 0 && (r[b] = p);
        }
      }
  }
  const c = cn(e, n), l = c.attributes;
  if (n.inline && (i.verticalAlign = "-0.125em"), o === "svg") {
    r.style = {
      ...i,
      ...a
    }, Object.assign(r, l);
    let b = 0, p = t.id;
    return typeof p == "string" && (p = p.replace(/-/g, "_")), r.innerHTML = dn(c.body, p ? () => p + "ID" + b++ : "iconifyVue"), _e("svg", r);
  }
  const { body: u, width: d, height: h } = e, v = o === "mask" || (o === "bg" ? !1 : u.indexOf("currentColor") !== -1), y = Vn(u, {
    ...l,
    width: d + "",
    height: h + ""
  });
  return r.style = {
    ...i,
    "--svg": Bn(y),
    width: Ne(l.width),
    height: Ne(l.height),
    ...Wn,
    ...v ? de : ot,
    ...a
  }, _e("span", r);
};
Xe(!0);
pn("", xn);
if (typeof document < "u" && typeof window < "u") {
  const e = window;
  if (e.IconifyPreload !== void 0) {
    const t = e.IconifyPreload, n = "Invalid IconifyPreload syntax.";
    typeof t == "object" && t !== null && (t instanceof Array ? t : [t]).forEach((r) => {
      try {
        // Check if item is an object and not null/array
        (typeof r != "object" || r === null || r instanceof Array || // Check for 'icons' and 'prefix'
        typeof r.icons != "object" || typeof r.prefix != "string" || // Add icon set
        !Ze(r)) && console.error(n);
      } catch {
        console.error(n);
      }
    });
  }
  if (e.IconifyProviders !== void 0) {
    const t = e.IconifyProviders;
    if (typeof t == "object" && t !== null)
      for (let n in t) {
        const r = "IconifyProviders[" + n + "] is invalid.";
        try {
          const o = t[n];
          if (typeof o != "object" || !o || o.resources === void 0)
            continue;
          hn(n, o) || console.error(r);
        } catch {
          console.error(r);
        }
      }
  }
}
const zn = {
  ...te,
  body: ""
};
Be((e, { emit: t }) => {
  const n = R(null);
  function r() {
    n.value && (n.value.abort?.(), n.value = null);
  }
  const o = R(!!e.ssr), i = R(""), s = M(null);
  function a() {
    const l = e.icon;
    if (typeof l == "object" && l !== null && typeof l.body == "string")
      return i.value = "", {
        data: l
      };
    let u;
    if (typeof l != "string" || (u = ee(l, !1, !0)) === null)
      return null;
    let d = Zt(u);
    if (!d) {
      const y = n.value;
      return (!y || y.name !== l) && (d === null ? n.value = {
        name: l
      } : n.value = {
        name: l,
        abort: Nn([u], c)
      }), null;
    }
    r(), i.value !== l && (i.value = l, kt(() => {
      t("load", l);
    }));
    const h = e.customise;
    if (h) {
      d = Object.assign({}, d);
      const y = h(d.body, u.name, u.prefix, u.provider);
      typeof y == "string" && (d.body = y);
    }
    const v = ["iconify"];
    return u.prefix !== "" && v.push("iconify--" + u.prefix), u.provider !== "" && v.push("iconify--" + u.provider), { data: d, classes: v };
  }
  function c() {
    const l = a();
    l ? l.data !== s.value?.data && (s.value = l) : s.value = null;
  }
  return o.value ? c() : He(() => {
    o.value = !0, c();
  }), q(() => e.icon, c), xt(r), () => {
    const l = s.value;
    if (!l)
      return je(zn, e);
    let u = e;
    return l.classes && (u = {
      ...e,
      class: l.classes.join(" ")
    }), je({
      ...te,
      ...l.data
    }, u);
  };
}, {
  props: [
    // Icon and render mode
    "icon",
    "mode",
    "ssr",
    // Layout and style
    "width",
    "height",
    "style",
    "color",
    "inline",
    // Transformations
    "rotate",
    "hFlip",
    "horizontalFlip",
    "vFlip",
    "verticalFlip",
    "flip",
    // Misc
    "id",
    "ariaHidden",
    "customise",
    "title"
  ],
  emits: ["load"]
});
const Gn = [
  "themeConfigUrl",
  "primeVueCssUrl",
  "markdownCssUrl",
  "iframeCssUrl"
];
function Kn(e, t) {
  const r = (t ?? Gn).map(async (o) => {
    const i = Mt[o];
    if (!i)
      return console.warn(`[wippy-fe/webcomponent-core] hostCss key "${o}" is undefined — skipping. Remove it from hostCssKeys if the CSS was removed.`), null;
    try {
      return await Dt(i);
    } catch (s) {
      return console.warn(`[wippy-fe/webcomponent-core] Failed to load hostCss "${o}" (${i}):`, s), null;
    }
  });
  return Promise.all(r).then((o) => {
    for (const i of o) {
      if (!i)
        continue;
      const s = document.createElement("style");
      s.textContent = i, s.setAttribute("role", "@wippy-fe/host-css"), e.appendChild(s);
    }
  });
}
function Qn(e, t) {
  const n = document.createElement("style");
  n.textContent = t, e.appendChild(n);
}
function it(e) {
  return e.__wippyHost ?? null;
}
function Jn(e) {
  return e.replace(/-([a-z])/g, (t, n) => n.toUpperCase());
}
function qn(e, t, n) {
  switch (n.type) {
    case "string":
      return { value: t };
    case "number": {
      const r = Number.parseFloat(t);
      return Number.isNaN(r) ? { value: void 0, error: `Invalid ${e}: expected a number` } : { value: r };
    }
    case "integer": {
      const r = Number.parseInt(t, 10);
      return Number.isNaN(r) ? { value: void 0, error: `Invalid ${e}: expected an integer` } : { value: r };
    }
    case "boolean":
      return { value: t !== "false" };
    case "array":
    case "object":
      try {
        const r = JSON.parse(t);
        return n.type === "array" && !Array.isArray(r) ? { value: void 0, error: `Invalid ${e}: expected a JSON array` } : { value: r };
      } catch {
        return { value: void 0, error: `Invalid ${e}: must be valid JSON` };
      }
    default:
      return { value: t };
  }
}
function Me(e, t) {
  const n = {}, r = [];
  for (const [o, i] of Object.entries(t.properties)) {
    const s = e.getAttribute(o), a = Jn(o);
    if (s === null) {
      i.default !== void 0 && (n[a] = i.default);
      continue;
    }
    const c = qn(o, s, i);
    c.error ? r.push(c.error) : n[a] = c.value;
  }
  return { props: n, errors: r };
}
class Yn extends HTMLElement {
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
    const t = this.wippyConfig, n = Object.keys(t.propsSchema.properties), r = t.extraObservedAttributes ?? [];
    return [...n, ...r];
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
    return it(this);
  }
  /**
   * Emit a CustomEvent that bubbles and crosses shadow DOM boundaries.
   */
  emitEvent(t, n) {
    this.dispatchEvent(new CustomEvent(t, {
      bubbles: !0,
      composed: !0,
      detail: n
    }));
  }
  // ── Lifecycle ──────────────────────────────────────────────
  connectedCallback() {
    this._internals.states.add("loading");
    try {
      const t = this.constructor.wippyConfig, n = this._initialized, r = this.shadowRoot ?? this.attachShadow({ mode: t.shadowMode ?? "open" });
      let o;
      if (n)
        o = this._container;
      else {
        this.onInit(r), t.inlineCss && Qn(r, t.inlineCss), (t.hostCssKeys === void 0 || t.hostCssKeys.length > 0) && Kn(r, t.hostCssKeys), o = document.createElement("div");
        const l = t.containerClasses ?? [];
        l.length > 0 && o.classList.add(...l), r.appendChild(o), this._container = o, $t(Ze);
      }
      const { props: i, errors: s } = Me(this, t.propsSchema);
      t.validateProps && s.push(...t.validateProps(i));
      const a = i;
      let c = null;
      t.contentTemplate && (c = this._extractContent(t.contentTemplate), this._contentObserver = new MutationObserver(() => {
        const l = this._extractContent(t.contentTemplate);
        this.onContentChanged(l);
      }), this._contentObserver.observe(this, {
        childList: !0,
        characterData: !0,
        subtree: !0
      })), this.onMount(r, o, a, s, c, n), this._internals.states.delete("loading"), this._internals.states.add("ready"), n || (this._initialized = !0), this.onReady(), this.emitEvent("load");
    } catch (t) {
      this.onError(t), this._internals.states.delete("loading"), this._internals.states.add("error"), this.emitEvent("error", {
        message: t instanceof Error ? t.message : String(t),
        error: t
      });
    }
  }
  disconnectedCallback() {
    this._contentObserver && (this._contentObserver.disconnect(), this._contentObserver = null), this.onUnmount(), this.emitEvent("unload"), this._internals.states.clear(), delete this.__wippyHost, delete this.__wippyHostBus;
  }
  attributeChangedCallback(t, n, r) {
    if (n === r)
      return;
    const o = this.constructor.wippyConfig, { props: i, errors: s } = Me(this, o.propsSchema);
    o.validateProps && s.push(...o.validateProps(i)), this.onPropsChanged(i, s);
  }
  // ── Hooks ──────────────────────────────────────────────────
  /** Called right after shadow DOM is attached, before CSS or container. */
  onInit(t) {
  }
  /** Called after internals state is set to ready, before the `load` event. */
  onReady() {
  }
  /** Called when connectedCallback throws. Default logs to console. */
  onError(t) {
    console.error(`${this.constructor.name} initialization failed:`, t);
  }
  /** Called when observed attributes change. Override to update framework state. */
  onPropsChanged(t, n) {
  }
  /**
   * Extract text from a child `<template data-type="...">` element.
   * Uses `.content.textContent` since `<template>` stores content in a DocumentFragment.
   */
  _extractContent(t) {
    return this.querySelector(`template[data-type="${t}"]`)?.content.textContent?.trim() ?? null;
  }
  /** Called when child `<template>` content changes. Override to update framework state. */
  onContentChanged(t) {
  }
}
function Xn(e) {
  return e.__wippyHostBus ?? null;
}
function Zn(e) {
  return e.dataset.wippyPanelId ?? null;
}
function er() {
  return st().__VUE_DEVTOOLS_GLOBAL_HOOK__;
}
function st() {
  return typeof navigator < "u" && typeof window < "u" ? window : typeof globalThis < "u" ? globalThis : {};
}
const tr = typeof Proxy == "function", nr = "devtools-plugin:setup", rr = "plugin:settings:set";
let j, pe;
function or() {
  var e;
  return j !== void 0 || (typeof window < "u" && window.performance ? (j = !0, pe = window.performance) : typeof globalThis < "u" && (!((e = globalThis.perf_hooks) === null || e === void 0) && e.performance) ? (j = !0, pe = globalThis.perf_hooks.performance) : j = !1), j;
}
function ir() {
  return or() ? pe.now() : Date.now();
}
class sr {
  constructor(t, n) {
    this.target = null, this.targetQueue = [], this.onQueue = [], this.plugin = t, this.hook = n;
    const r = {};
    if (t.settings)
      for (const s in t.settings) {
        const a = t.settings[s];
        r[s] = a.defaultValue;
      }
    const o = `__vue-devtools-plugin-settings__${t.id}`;
    let i = Object.assign({}, r);
    try {
      const s = localStorage.getItem(o), a = JSON.parse(s);
      Object.assign(i, a);
    } catch {
    }
    this.fallbacks = {
      getSettings() {
        return i;
      },
      setSettings(s) {
        try {
          localStorage.setItem(o, JSON.stringify(s));
        } catch {
        }
        i = s;
      },
      now() {
        return ir();
      }
    }, n && n.on(rr, (s, a) => {
      s === this.plugin.id && this.fallbacks.setSettings(a);
    }), this.proxiedOn = new Proxy({}, {
      get: (s, a) => this.target ? this.target.on[a] : (...c) => {
        this.onQueue.push({
          method: a,
          args: c
        });
      }
    }), this.proxiedTarget = new Proxy({}, {
      get: (s, a) => this.target ? this.target[a] : a === "on" ? this.proxiedOn : Object.keys(this.fallbacks).includes(a) ? (...c) => (this.targetQueue.push({
        method: a,
        args: c,
        resolve: () => {
        }
      }), this.fallbacks[a](...c)) : (...c) => new Promise((l) => {
        this.targetQueue.push({
          method: a,
          args: c,
          resolve: l
        });
      })
    });
  }
  async setRealTarget(t) {
    this.target = t;
    for (const n of this.onQueue)
      this.target.on[n.method](...n.args);
    for (const n of this.targetQueue)
      n.resolve(await this.target[n.method](...n.args));
  }
}
function at(e, t) {
  const n = e, r = st(), o = er(), i = tr && n.enableEarlyProxy;
  if (o && (r.__VUE_DEVTOOLS_PLUGIN_API_AVAILABLE__ || !i))
    o.emit(nr, e, t);
  else {
    const s = i ? new sr(n, o) : null;
    (r.__VUE_DEVTOOLS_PLUGINS__ = r.__VUE_DEVTOOLS_PLUGINS__ || []).push({
      pluginDescriptor: n,
      setupFn: t,
      proxy: s
    }), s && t(s.proxiedTarget);
  }
}
/*!
 * pinia v2.3.1
 * (c) 2025 Eduardo San Martin Morote
 * @license MIT
 */
let ct;
const lt = (e) => ct = e, ar = () => _t() && ge(ut) || ct, ut = process.env.NODE_ENV !== "production" ? Symbol("pinia") : (
  /* istanbul ignore next */
  Symbol()
);
var N;
(function(e) {
  e.direct = "direct", e.patchObject = "patch object", e.patchFunction = "patch function";
})(N || (N = {}));
const he = typeof window < "u", De = typeof window == "object" && window.window === window ? window : typeof self == "object" && self.self === self ? self : typeof global == "object" && global.global === global ? global : typeof globalThis == "object" ? globalThis : { HTMLElement: null };
function cr(e, { autoBom: t = !1 } = {}) {
  return t && /^\s*(?:text\/\S*|application\/xml|\S*\/\S*\+xml)\s*;.*charset\s*=\s*utf-8/i.test(e.type) ? new Blob(["\uFEFF", e], { type: e.type }) : e;
}
function ye(e, t, n) {
  const r = new XMLHttpRequest();
  r.open("GET", e), r.responseType = "blob", r.onload = function() {
    pt(r.response, t, n);
  }, r.onerror = function() {
    console.error("could not download file");
  }, r.send();
}
function ft(e) {
  const t = new XMLHttpRequest();
  t.open("HEAD", e, !1);
  try {
    t.send();
  } catch {
  }
  return t.status >= 200 && t.status <= 299;
}
function G(e) {
  try {
    e.dispatchEvent(new MouseEvent("click"));
  } catch {
    const n = document.createEvent("MouseEvents");
    n.initMouseEvent("click", !0, !0, window, 0, 0, 0, 80, 20, !1, !1, !1, !1, 0, null), e.dispatchEvent(n);
  }
}
const K = typeof navigator == "object" ? navigator : { userAgent: "" }, dt = /Macintosh/.test(K.userAgent) && /AppleWebKit/.test(K.userAgent) && !/Safari/.test(K.userAgent), pt = he ? (
  // Use download attribute first if possible (#193 Lumia mobile) unless this is a macOS WebView or mini program
  typeof HTMLAnchorElement < "u" && "download" in HTMLAnchorElement.prototype && !dt ? lr : (
    // Use msSaveOrOpenBlob as a second approach
    "msSaveOrOpenBlob" in K ? ur : (
      // Fallback to using FileReader and a popup
      fr
    )
  )
) : () => {
};
function lr(e, t = "download", n) {
  const r = document.createElement("a");
  r.download = t, r.rel = "noopener", typeof e == "string" ? (r.href = e, r.origin !== location.origin ? ft(r.href) ? ye(e, t, n) : (r.target = "_blank", G(r)) : G(r)) : (r.href = URL.createObjectURL(e), setTimeout(function() {
    URL.revokeObjectURL(r.href);
  }, 4e4), setTimeout(function() {
    G(r);
  }, 0));
}
function ur(e, t = "download", n) {
  if (typeof e == "string")
    if (ft(e))
      ye(e, t, n);
    else {
      const r = document.createElement("a");
      r.href = e, r.target = "_blank", setTimeout(function() {
        G(r);
      });
    }
  else
    navigator.msSaveOrOpenBlob(cr(e, n), t);
}
function fr(e, t, n, r) {
  if (r = r || open("", "_blank"), r && (r.document.title = r.document.body.innerText = "downloading..."), typeof e == "string")
    return ye(e, t, n);
  const o = e.type === "application/octet-stream", i = /constructor/i.test(String(De.HTMLElement)) || "safari" in De, s = /CriOS\/[\d]+/.test(navigator.userAgent);
  if ((s || o && i || dt) && typeof FileReader < "u") {
    const a = new FileReader();
    a.onloadend = function() {
      let c = a.result;
      if (typeof c != "string")
        throw r = null, new Error("Wrong reader.result type");
      c = s ? c : c.replace(/^data:[^;]*;/, "data:attachment/file;"), r ? r.location.href = c : location.assign(c), r = null;
    }, a.readAsDataURL(e);
  } else {
    const a = URL.createObjectURL(e);
    r ? r.location.assign(a) : location.href = a, r = null, setTimeout(function() {
      URL.revokeObjectURL(a);
    }, 4e4);
  }
}
function k(e, t) {
  const n = "🍍 " + e;
  typeof __VUE_DEVTOOLS_TOAST__ == "function" ? __VUE_DEVTOOLS_TOAST__(n, t) : t === "error" ? console.error(n) : t === "warn" ? console.warn(n) : console.log(n);
}
function we(e) {
  return "_a" in e && "install" in e;
}
function ht() {
  if (!("clipboard" in navigator))
    return k("Your browser doesn't support the Clipboard API", "error"), !0;
}
function gt(e) {
  return e instanceof Error && e.message.toLowerCase().includes("document is not focused") ? (k('You need to activate the "Emulate a focused page" setting in the "Rendering" panel of devtools.', "warn"), !0) : !1;
}
async function dr(e) {
  if (!ht())
    try {
      await navigator.clipboard.writeText(JSON.stringify(e.state.value)), k("Global state copied to clipboard.");
    } catch (t) {
      if (gt(t))
        return;
      k("Failed to serialize the state. Check the console for more details.", "error"), console.error(t);
    }
}
async function pr(e) {
  if (!ht())
    try {
      mt(e, JSON.parse(await navigator.clipboard.readText())), k("Global state pasted from clipboard.");
    } catch (t) {
      if (gt(t))
        return;
      k("Failed to deserialize the state from clipboard. Check the console for more details.", "error"), console.error(t);
    }
}
async function hr(e) {
  try {
    pt(new Blob([JSON.stringify(e.state.value)], {
      type: "text/plain;charset=utf-8"
    }), "pinia-state.json");
  } catch (t) {
    k("Failed to export the state as JSON. Check the console for more details.", "error"), console.error(t);
  }
}
let P;
function gr() {
  P || (P = document.createElement("input"), P.type = "file", P.accept = ".json");
  function e() {
    return new Promise((t, n) => {
      P.onchange = async () => {
        const r = P.files;
        if (!r)
          return t(null);
        const o = r.item(0);
        return t(o ? { text: await o.text(), file: o } : null);
      }, P.oncancel = () => t(null), P.onerror = n, P.click();
    });
  }
  return e;
}
async function mr(e) {
  try {
    const n = await gr()();
    if (!n)
      return;
    const { text: r, file: o } = n;
    mt(e, JSON.parse(r)), k(`Global state imported from "${o.name}".`);
  } catch (t) {
    k("Failed to import the state from JSON. Check the console for more details.", "error"), console.error(t);
  }
}
function mt(e, t) {
  for (const n in t) {
    const r = e.state.value[n];
    r ? Object.assign(r, t[n]) : e.state.value[n] = t[n];
  }
}
function C(e) {
  return {
    _custom: {
      display: e
    }
  };
}
const vt = "🍍 Pinia (root)", Q = "_root";
function vr(e) {
  return we(e) ? {
    id: Q,
    label: vt
  } : {
    id: e.$id,
    label: e.$id
  };
}
function br(e) {
  if (we(e)) {
    const n = Array.from(e._s.keys()), r = e._s;
    return {
      state: n.map((i) => ({
        editable: !0,
        key: i,
        value: e.state.value[i]
      })),
      getters: n.filter((i) => r.get(i)._getters).map((i) => {
        const s = r.get(i);
        return {
          editable: !1,
          key: i,
          value: s._getters.reduce((a, c) => (a[c] = s[c], a), {})
        };
      })
    };
  }
  const t = {
    state: Object.keys(e.$state).map((n) => ({
      editable: !0,
      key: n,
      value: e.$state[n]
    }))
  };
  return e._getters && e._getters.length && (t.getters = e._getters.map((n) => ({
    editable: !1,
    key: n,
    value: e[n]
  }))), e._customProperties.size && (t.customProperties = Array.from(e._customProperties).map((n) => ({
    editable: !0,
    key: n,
    value: e[n]
  }))), t;
}
function yr(e) {
  return e ? Array.isArray(e) ? e.reduce((t, n) => (t.keys.push(n.key), t.operations.push(n.type), t.oldValue[n.key] = n.oldValue, t.newValue[n.key] = n.newValue, t), {
    oldValue: {},
    keys: [],
    operations: [],
    newValue: {}
  }) : {
    operation: C(e.type),
    key: C(e.key),
    oldValue: e.oldValue,
    newValue: e.newValue
  } : {};
}
function wr(e) {
  switch (e) {
    case N.direct:
      return "mutation";
    case N.patchFunction:
      return "$patch";
    case N.patchObject:
      return "$patch";
    default:
      return "unknown";
  }
}
let D = !0;
const J = [], L = "pinia:mutations", _ = "pinia", { assign: xr } = Object, Z = (e) => "🍍 " + e;
function kr(e, t) {
  at({
    id: "dev.esm.pinia",
    label: "Pinia 🍍",
    logo: "https://pinia.vuejs.org/logo.svg",
    packageName: "pinia",
    homepage: "https://pinia.vuejs.org",
    componentStateTypes: J,
    app: e
  }, (n) => {
    typeof n.now != "function" && k("You seem to be using an outdated version of Vue Devtools. Are you still using the Beta release instead of the stable one? You can find the links at https://devtools.vuejs.org/guide/installation.html."), n.addTimelineLayer({
      id: L,
      label: "Pinia 🍍",
      color: 15064968
    }), n.addInspector({
      id: _,
      label: "Pinia 🍍",
      icon: "storage",
      treeFilterPlaceholder: "Search stores",
      actions: [
        {
          icon: "content_copy",
          action: () => {
            dr(t);
          },
          tooltip: "Serialize and copy the state"
        },
        {
          icon: "content_paste",
          action: async () => {
            await pr(t), n.sendInspectorTree(_), n.sendInspectorState(_);
          },
          tooltip: "Replace the state with the content of your clipboard"
        },
        {
          icon: "save",
          action: () => {
            hr(t);
          },
          tooltip: "Save the state as a JSON file"
        },
        {
          icon: "folder_open",
          action: async () => {
            await mr(t), n.sendInspectorTree(_), n.sendInspectorState(_);
          },
          tooltip: "Import the state from a JSON file"
        }
      ],
      nodeActions: [
        {
          icon: "restore",
          tooltip: 'Reset the state (with "$reset")',
          action: (r) => {
            const o = t._s.get(r);
            o ? typeof o.$reset != "function" ? k(`Cannot reset "${r}" store because it doesn't have a "$reset" method implemented.`, "warn") : (o.$reset(), k(`Store "${r}" reset.`)) : k(`Cannot reset "${r}" store because it wasn't found.`, "warn");
          }
        }
      ]
    }), n.on.inspectComponent((r, o) => {
      const i = r.componentInstance && r.componentInstance.proxy;
      if (i && i._pStores) {
        const s = r.componentInstance.proxy._pStores;
        Object.values(s).forEach((a) => {
          r.instanceData.state.push({
            type: Z(a.$id),
            key: "state",
            editable: !0,
            value: a._isOptionsAPI ? {
              _custom: {
                value: Y(a.$state),
                actions: [
                  {
                    icon: "restore",
                    tooltip: "Reset the state of this store",
                    action: () => a.$reset()
                  }
                ]
              }
            } : (
              // NOTE: workaround to unwrap transferred refs
              Object.keys(a.$state).reduce((c, l) => (c[l] = a.$state[l], c), {})
            )
          }), a._getters && a._getters.length && r.instanceData.state.push({
            type: Z(a.$id),
            key: "getters",
            editable: !1,
            value: a._getters.reduce((c, l) => {
              try {
                c[l] = a[l];
              } catch (u) {
                c[l] = u;
              }
              return c;
            }, {})
          });
        });
      }
    }), n.on.getInspectorTree((r) => {
      if (r.app === e && r.inspectorId === _) {
        let o = [t];
        o = o.concat(Array.from(t._s.values())), r.rootNodes = (r.filter ? o.filter((i) => "$id" in i ? i.$id.toLowerCase().includes(r.filter.toLowerCase()) : vt.toLowerCase().includes(r.filter.toLowerCase())) : o).map(vr);
      }
    }), globalThis.$pinia = t, n.on.getInspectorState((r) => {
      if (r.app === e && r.inspectorId === _) {
        const o = r.nodeId === Q ? t : t._s.get(r.nodeId);
        if (!o)
          return;
        o && (r.nodeId !== Q && (globalThis.$store = Y(o)), r.state = br(o));
      }
    }), n.on.editInspectorState((r, o) => {
      if (r.app === e && r.inspectorId === _) {
        const i = r.nodeId === Q ? t : t._s.get(r.nodeId);
        if (!i)
          return k(`store "${r.nodeId}" not found`, "error");
        const { path: s } = r;
        we(i) ? s.unshift("state") : (s.length !== 1 || !i._customProperties.has(s[0]) || s[0] in i.$state) && s.unshift("$state"), D = !1, r.set(i, s, r.state.value), D = !0;
      }
    }), n.on.editComponentState((r) => {
      if (r.type.startsWith("🍍")) {
        const o = r.type.replace(/^🍍\s*/, ""), i = t._s.get(o);
        if (!i)
          return k(`store "${o}" not found`, "error");
        const { path: s } = r;
        if (s[0] !== "state")
          return k(`Invalid path for store "${o}":
${s}
Only state can be modified.`);
        s[0] = "$state", D = !1, r.set(i, s, r.state.value), D = !0;
      }
    });
  });
}
function _r(e, t) {
  J.includes(Z(t.$id)) || J.push(Z(t.$id)), at({
    id: "dev.esm.pinia",
    label: "Pinia 🍍",
    logo: "https://pinia.vuejs.org/logo.svg",
    packageName: "pinia",
    homepage: "https://pinia.vuejs.org",
    componentStateTypes: J,
    app: e,
    settings: {
      logStoreChanges: {
        label: "Notify about new/deleted stores",
        type: "boolean",
        defaultValue: !0
      }
      // useEmojis: {
      //   label: 'Use emojis in messages ⚡️',
      //   type: 'boolean',
      //   defaultValue: true,
      // },
    }
  }, (n) => {
    const r = typeof n.now == "function" ? n.now.bind(n) : Date.now;
    t.$onAction(({ after: s, onError: a, name: c, args: l }) => {
      const u = bt++;
      n.addTimelineEvent({
        layerId: L,
        event: {
          time: r(),
          title: "🛫 " + c,
          subtitle: "start",
          data: {
            store: C(t.$id),
            action: C(c),
            args: l
          },
          groupId: u
        }
      }), s((d) => {
        A = void 0, n.addTimelineEvent({
          layerId: L,
          event: {
            time: r(),
            title: "🛬 " + c,
            subtitle: "end",
            data: {
              store: C(t.$id),
              action: C(c),
              args: l,
              result: d
            },
            groupId: u
          }
        });
      }), a((d) => {
        A = void 0, n.addTimelineEvent({
          layerId: L,
          event: {
            time: r(),
            logType: "error",
            title: "💥 " + c,
            subtitle: "end",
            data: {
              store: C(t.$id),
              action: C(c),
              args: l,
              error: d
            },
            groupId: u
          }
        });
      });
    }, !0), t._customProperties.forEach((s) => {
      q(() => Et(t[s]), (a, c) => {
        n.notifyComponentUpdate(), n.sendInspectorState(_), D && n.addTimelineEvent({
          layerId: L,
          event: {
            time: r(),
            title: "Change",
            subtitle: s,
            data: {
              newValue: a,
              oldValue: c
            },
            groupId: A
          }
        });
      }, { deep: !0 });
    }), t.$subscribe(({ events: s, type: a }, c) => {
      if (n.notifyComponentUpdate(), n.sendInspectorState(_), !D)
        return;
      const l = {
        time: r(),
        title: wr(a),
        data: xr({ store: C(t.$id) }, yr(s)),
        groupId: A
      };
      a === N.patchFunction ? l.subtitle = "⤵️" : a === N.patchObject ? l.subtitle = "🧩" : s && !Array.isArray(s) && (l.subtitle = s.type), s && (l.data["rawEvent(s)"] = {
        _custom: {
          display: "DebuggerEvent",
          type: "object",
          tooltip: "raw DebuggerEvent[]",
          value: s
        }
      }), n.addTimelineEvent({
        layerId: L,
        event: l
      });
    }, { detached: !0, flush: "sync" });
    const o = t._hotUpdate;
    t._hotUpdate = We((s) => {
      o(s), n.addTimelineEvent({
        layerId: L,
        event: {
          time: r(),
          title: "🔥 " + t.$id,
          subtitle: "HMR update",
          data: {
            store: C(t.$id),
            info: C("HMR update")
          }
        }
      }), n.notifyComponentUpdate(), n.sendInspectorTree(_), n.sendInspectorState(_);
    });
    const { $dispose: i } = t;
    t.$dispose = () => {
      i(), n.notifyComponentUpdate(), n.sendInspectorTree(_), n.sendInspectorState(_), n.getSettings().logStoreChanges && k(`Disposed "${t.$id}" store 🗑`);
    }, n.notifyComponentUpdate(), n.sendInspectorTree(_), n.sendInspectorState(_), n.getSettings().logStoreChanges && k(`"${t.$id}" store installed 🆕`);
  });
}
let bt = 0, A;
function $e(e, t, n) {
  const r = t.reduce((o, i) => (o[i] = Y(e)[i], o), {});
  for (const o in r)
    e[o] = function() {
      const i = bt, s = n ? new Proxy(e, {
        get(...c) {
          return A = i, Reflect.get(...c);
        },
        set(...c) {
          return A = i, Reflect.set(...c);
        }
      }) : e;
      A = i;
      const a = r[o].apply(s, arguments);
      return A = void 0, a;
    };
}
function Sr({ app: e, store: t, options: n }) {
  if (!t.$id.startsWith("__hot:")) {
    if (t._isOptionsAPI = !!n.state, !t._p._testing) {
      $e(t, Object.keys(n.actions), t._isOptionsAPI);
      const r = t._hotUpdate;
      Y(t)._hotUpdate = function(o) {
        r.apply(this, arguments), $e(t, Object.keys(o._hmrPayload.actions), !!t._isOptionsAPI);
      };
    }
    _r(
      e,
      // FIXME: is there a way to allow the assignment from Store<Id, S, G, A> to StoreGeneric?
      t
    );
  }
}
function Er() {
  const e = St(!0), t = e.run(() => R({}));
  let n = [], r = [];
  const o = We({
    install(i) {
      lt(o), o._a = i, i.provide(ut, o), i.config.globalProperties.$pinia = o, process.env.NODE_ENV !== "production" && process.env.NODE_ENV !== "test" && he && kr(i, o), r.forEach((s) => n.push(s)), r = [];
    },
    use(i) {
      return this._a ? n.push(i) : r.push(i), this;
    },
    _p: n,
    // it's actually undefined here
    // @ts-expect-error
    _a: null,
    _e: e,
    _s: /* @__PURE__ */ new Map(),
    state: t
  });
  return process.env.NODE_ENV !== "production" && process.env.NODE_ENV !== "test" && he && typeof Proxy < "u" && o.use(Sr), o;
}
process.env.NODE_ENV !== "production" ? Symbol("pinia:skipHydration") : (
  /* istanbul ignore next */
  Symbol()
);
class Ir extends Yn {
  constructor() {
    super(...arguments), this._vueApp = null, this._propsRef = R({}), this._errorsRef = R([]), this._contentRef = R(null);
  }
  /**
   * Override to provide Vue-specific configuration.
   */
  static get vueConfig() {
    throw new Error("WippyVueElement subclass must override static get vueConfig()");
  }
  onMount(t, n, r, o, i, s) {
    const a = this.constructor.vueConfig;
    this._propsRef.value = r, this._errorsRef.value = o, this._contentRef.value = i ?? null;
    for (const u of o)
      this.emitEvent("invalid", { message: u });
    const c = ar();
    this._vueApp = It(a.rootComponent);
    const l = Er();
    if (a.piniaPlugins)
      for (const u of a.piniaPlugins)
        l.use(u);
    if (this._vueApp.use(l), a.plugins)
      for (const u of a.plugins)
        this._vueApp.use(u);
    this._vueApp.provide(Ge, this._propsRef), this._vueApp.provide(Ft, this._errorsRef), this._vueApp.provide(ze, this.emitEvent.bind(this)), this._vueApp.provide(Ut, this._contentRef), this._vueApp.provide(Bt, Zn(this)), this._vueApp.provide(Ht, Xn(this)), this._vueApp.provide(Wt, it(this)), a.providers && a.providers(this._vueApp, this), this._vueApp.mount(n), c && lt(c);
  }
  onUnmount() {
    this._vueApp && (this._vueApp.unmount(), this._vueApp = null);
  }
  onPropsChanged(t, n) {
    this._propsRef.value = t, this._errorsRef.value = n;
    for (const r of n)
      this.emitEvent("invalid", { message: r });
  }
  onContentChanged(t) {
    this._contentRef.value = t;
  }
}
const Cr = () => zt(), Or = () => Gt();
let ae = null;
function Tr() {
  return ae || (ae = (async () => {
    const [
      e,
      t,
      n,
      r,
      o
    ] = await Promise.all([
      import("./editor.worker-6fjUqSQw.js").then((s) => s.default),
      import("./json.worker-QrKabbIj.js").then((s) => s.default),
      import("./css.worker-B_353apr.js").then((s) => s.default),
      import("./html.worker-vLFr0FfR.js").then((s) => s.default),
      import("./ts.worker-DE0dpLt9.js").then((s) => s.default)
    ]);
    self.MonacoEnvironment = {
      getWorker(s, a) {
        switch (a) {
          case "json":
            return new t();
          case "css":
          case "scss":
          case "less":
            return new n();
          case "html":
          case "handlebars":
          case "razor":
            return new r();
          case "typescript":
          case "javascript":
            return new o();
          default:
            return new e();
        }
      }
    };
    const i = await import("./editor.main-EgONQ7Gq.js").then((s) => s.b);
    return Pr(i), i;
  })()), ae;
}
const yt = "keeper-dark", wt = "keeper-light", Ve = "keeper-auto";
let Fe = !1;
function Pr(e) {
  Fe || (e.editor.defineTheme(yt, {
    base: "vs-dark",
    inherit: !0,
    rules: [
      { token: "comment", foreground: "6a737d", fontStyle: "italic" },
      { token: "keyword", foreground: "f59e0b" },
      { token: "string", foreground: "4ade80" },
      { token: "number", foreground: "c084fc" },
      { token: "type", foreground: "60a5fa" },
      { token: "function", foreground: "2dd4bf" },
      { token: "variable", foreground: "e2e8f0" },
      { token: "operator", foreground: "f87171" }
    ],
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
  }), e.editor.defineTheme(wt, {
    base: "vs",
    inherit: !0,
    rules: [
      { token: "comment", foreground: "6a737d", fontStyle: "italic" },
      { token: "keyword", foreground: "b45309" },
      { token: "string", foreground: "15803d" },
      { token: "number", foreground: "7e22ce" },
      { token: "type", foreground: "1d4ed8" },
      { token: "function", foreground: "0d9488" },
      { token: "variable", foreground: "1e293b" },
      { token: "operator", foreground: "b91c1c" }
    ],
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
  }), Fe = !0);
}
function Ar(e, t) {
  const n = getComputedStyle(t), r = (s, a) => n.getPropertyValue(s).trim() || a, o = r("--p-content-background", "#1c1a19"), i = Rr(o);
  return e.editor.defineTheme(Ve, {
    base: i ? "vs-dark" : "vs",
    inherit: !0,
    rules: [],
    colors: {
      "editor.background": o,
      "editor.foreground": r("--p-text-color", i ? "#fafafa" : "#18181b"),
      "editor.lineHighlightBackground": r("--p-surface-100", i ? "#2b2927" : "#f4f4f5"),
      "editor.selectionBackground": i ? "#1e222c80" : "#bfdbfe",
      "editorCursor.foreground": r("--p-primary-500", "#f59e0b"),
      "editorLineNumber.foreground": r("--p-text-muted-color", "#a1a1aa"),
      "editorLineNumber.activeForeground": r("--p-text-color", i ? "#fafafa" : "#18181b"),
      "editor.inactiveSelectionBackground": r("--p-surface-100", i ? "#2b2927" : "#e4e4e7"),
      "editorIndentGuide.background": r("--p-surface-200", i ? "#403e3c" : "#e4e4e7"),
      "editorWidget.background": r("--p-surface-100", i ? "#2b2927" : "#ffffff"),
      "editorWidget.border": r("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "input.background": r("--p-content-background", o),
      "input.border": r("--p-content-border-color", i ? "#403e3c" : "#e4e4e7"),
      "scrollbarSlider.background": i ? "#1e222c80" : "#a1a1aa80",
      "scrollbarSlider.hoverBackground": i ? "#2a2f3a" : "#71717a",
      "diffEditor.insertedTextBackground": i ? "#34d39920" : "#16a34a20",
      "diffEditor.removedTextBackground": i ? "#f8717120" : "#dc262620",
      "diffEditor.insertedLineBackground": i ? "#34d39910" : "#16a34a10",
      "diffEditor.removedLineBackground": i ? "#f8717110" : "#dc262610"
    }
  }), Ve;
}
function Rr(e) {
  const t = e.startsWith("#") ? e.slice(1) : null;
  if (t) {
    const r = t.length === 3 ? t.split("").map((o) => o + o).join("") : t.length >= 6 ? t.slice(0, 6) : null;
    if (r) {
      const o = parseInt(r.slice(0, 2), 16), i = parseInt(r.slice(2, 4), 16), s = parseInt(r.slice(4, 6), 16);
      return Ue(o, i, s) < 0.5;
    }
  }
  const n = /rgba?\(\s*(\d+)[^\d]+(\d+)[^\d]+(\d+)/.exec(e);
  return n ? Ue(+n[1], +n[2], +n[3]) < 0.5 : !0;
}
function Ue(e, t, n) {
  return (0.2126 * e + 0.7152 * t + 0.0722 * n) / 255;
}
function ce(e, t, n) {
  switch (t) {
    case "keeper-dark":
      return yt;
    case "keeper-light":
      return wt;
    default:
      return Ar(e, n);
  }
}
const Lr = {
  key: 0,
  class: "monaco-status",
  role: "status"
}, Nr = {
  key: 1,
  class: "monaco-status error",
  role: "alert"
}, jr = {
  ref: "container",
  class: "monaco-container"
}, Mr = /* @__PURE__ */ Be({
  __name: "monaco-host",
  setup(e) {
    const t = Cr(), n = Or(), r = Ct(() => {
      const f = t.value?.["min-height"];
      return f && f > 0 ? { minHeight: `${f}px` } : void 0;
    }), o = Ot("container"), i = R({ kind: "loading" }), s = M(null), a = M(null), c = M(null), l = M(null), u = M(null);
    let d = null, h = null, v = null, y = !1;
    function b() {
      return t.value.mode === "diff" ? "diff" : "editor";
    }
    function p() {
      const f = s.value;
      if (!f)
        return;
      const g = o.value;
      if (!g)
        return;
      const w = ce(f, t.value.theme, g);
      f.editor.setTheme(w);
    }
    function T() {
      if (t.value.theme && t.value.theme !== "auto")
        return;
      const f = document.documentElement;
      d = new MutationObserver(() => p()), d.observe(f, { attributes: !0, attributeFilter: ["data-theme", "class"] }), h = window.matchMedia("(prefers-color-scheme: dark)"), v = () => p(), h.addEventListener("change", v);
    }
    function O() {
      d?.disconnect(), d = null, h && v && h.removeEventListener("change", v), h = null, v = null;
    }
    function E() {
      O(), a.value?.dispose(), a.value = null;
      const f = c.value;
      c.value = null, f?.setModel(null), f?.dispose(), l.value?.dispose(), u.value?.dispose(), l.value = null, u.value = null;
    }
    async function S(f, g) {
      const w = ce(f, t.value.theme, g);
      a.value = f.editor.create(g, {
        value: t.value.value || "",
        language: t.value.language || "plaintext",
        theme: w,
        readOnly: t.value.readonly === !0,
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
      }), a.value.onDidChangeModelContent(() => {
        if (y)
          return;
        const x = a.value?.getValue() ?? "";
        n("change", { value: x });
      });
    }
    async function V(f, g) {
      const w = ce(f, t.value.theme, g);
      c.value = f.editor.createDiffEditor(g, {
        theme: w,
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
      }), m(f);
    }
    function m(f) {
      const g = c.value;
      if (!g)
        return;
      const w = t.value.language || "plaintext", x = l.value, I = u.value, xe = f.editor.createModel(t.value.baseline || "", w), ke = f.editor.createModel(t.value.current || "", w);
      l.value = xe, u.value = ke, g.setModel({ original: xe, modified: ke }), x?.dispose(), I?.dispose();
    }
    return He(async () => {
      const f = o.value;
      if (!f) {
        i.value = { kind: "error", message: "monaco container missing" };
        return;
      }
      try {
        const g = await Tr();
        s.value = g, b() === "diff" ? await V(g, f) : await S(g, f), T(), i.value = { kind: "ready" }, n("load", void 0);
      } catch (g) {
        const w = g instanceof Error ? g.message : String(g);
        i.value = { kind: "error", message: w }, n("error", { message: w, error: g });
      }
    }), ne(() => {
      const f = a.value;
      if (!f)
        return;
      const g = t.value.value ?? "";
      f.getValue() !== g && (y = !0, f.setValue(g), y = !1);
    }), ne(() => {
      const f = a.value;
      f && f.updateOptions({ readOnly: t.value.readonly === !0 });
    }), ne(() => {
      const f = s.value, g = a.value, w = c.value, x = t.value.language || "plaintext";
      if (f && g) {
        const I = g.getModel();
        I && I.getLanguageId() !== x && f.editor.setModelLanguage(I, x);
      }
      if (f && w) {
        const I = w.getModel();
        I && (I.original.getLanguageId() !== x && f.editor.setModelLanguage(I.original, x), I.modified.getLanguageId() !== x && f.editor.setModelLanguage(I.modified, x));
      }
    }), q(() => [t.value.baseline, t.value.current], () => {
      const f = s.value;
      f && b() === "diff" && m(f);
    }), q(() => t.value.theme, () => {
      O(), p(), T();
    }), Tt(() => {
      E(), n("unload", void 0);
    }), (f, g) => (re(), oe("div", {
      class: "monaco-host",
      style: Pt(r.value)
    }, [
      i.value.kind === "loading" ? (re(), oe("div", Lr, " Loading editor… ")) : i.value.kind === "error" ? (re(), oe("div", Nr, At(i.value.message), 1)) : Rt("", !0),
      Lt(Nt("div", jr, null, 512), [
        [jt, i.value.kind === "ready"]
      ])
    ], 4));
  }
}), Dr = ":root{--p-primary: rgb(0, 95, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-secondary: #6f7385;--p-secondary-50: color-mix(in srgb, var(--p-secondary) 5%, white);--p-secondary-100: color-mix(in srgb, var(--p-secondary) 10%, white);--p-secondary-200: color-mix(in srgb, var(--p-secondary) 20%, white);--p-secondary-300: color-mix(in srgb, var(--p-secondary) 35%, white);--p-secondary-400: color-mix(in srgb, var(--p-secondary) 65%, white);--p-secondary-500: var(--p-secondary);--p-secondary-600: color-mix(in srgb, var(--p-secondary) 80%, black);--p-secondary-700: color-mix(in srgb, var(--p-secondary) 65%, black);--p-secondary-800: color-mix(in srgb, var(--p-secondary) 55%, black);--p-secondary-900: color-mix(in srgb, var(--p-secondary) 50%, black);--p-secondary-950: color-mix(in srgb, var(--p-secondary) 30%, black);--p-danger: rgb(239, 68, 68);--p-danger-50: color-mix(in srgb, var(--p-danger) 5%, white);--p-danger-100: color-mix(in srgb, var(--p-danger) 10%, white);--p-danger-200: color-mix(in srgb, var(--p-danger) 20%, white);--p-danger-300: color-mix(in srgb, var(--p-danger) 30%, white);--p-danger-400: color-mix(in srgb, var(--p-danger) 40%, white);--p-danger-500: var(--p-danger);--p-danger-600: color-mix(in srgb, var(--p-danger) 80%, black);--p-danger-700: color-mix(in srgb, var(--p-danger) 70%, black);--p-danger-800: color-mix(in srgb, var(--p-danger) 60%, black);--p-danger-900: color-mix(in srgb, var(--p-danger) 50%, black);--p-danger-950: color-mix(in srgb, var(--p-danger) 40%, black);--p-success: rgb(34, 197, 94);--p-success-50: color-mix(in srgb, var(--p-success) 5%, white);--p-success-100: color-mix(in srgb, var(--p-success) 10%, white);--p-success-200: color-mix(in srgb, var(--p-success) 20%, white);--p-success-300: color-mix(in srgb, var(--p-success) 30%, white);--p-success-400: color-mix(in srgb, var(--p-success) 40%, white);--p-success-500: var(--p-success);--p-success-600: color-mix(in srgb, var(--p-success) 80%, black);--p-success-700: color-mix(in srgb, var(--p-success) 70%, black);--p-success-800: color-mix(in srgb, var(--p-success) 60%, black);--p-success-900: color-mix(in srgb, var(--p-success) 50%, black);--p-success-950: color-mix(in srgb, var(--p-success) 40%, black);--p-warn: rgb(249, 115, 22);--p-warn-50: color-mix(in srgb, var(--p-warn) 5%, white);--p-warn-100: color-mix(in srgb, var(--p-warn) 10%, white);--p-warn-200: color-mix(in srgb, var(--p-warn) 20%, white);--p-warn-300: color-mix(in srgb, var(--p-warn) 30%, white);--p-warn-400: color-mix(in srgb, var(--p-warn) 40%, white);--p-warn-500: var(--p-warn);--p-warn-600: color-mix(in srgb, var(--p-warn) 80%, black);--p-warn-700: color-mix(in srgb, var(--p-warn) 70%, black);--p-warn-800: color-mix(in srgb, var(--p-warn) 60%, black);--p-warn-900: color-mix(in srgb, var(--p-warn) 50%, black);--p-warn-950: color-mix(in srgb, var(--p-warn) 40%, black);--p-info: rgb(14, 165, 233);--p-info-50: color-mix(in srgb, var(--p-info) 5%, white);--p-info-100: color-mix(in srgb, var(--p-info) 10%, white);--p-info-200: color-mix(in srgb, var(--p-info) 20%, white);--p-info-300: color-mix(in srgb, var(--p-info) 30%, white);--p-info-400: color-mix(in srgb, var(--p-info) 40%, white);--p-info-500: var(--p-info);--p-info-600: color-mix(in srgb, var(--p-info) 80%, black);--p-info-700: color-mix(in srgb, var(--p-info) 70%, black);--p-info-800: color-mix(in srgb, var(--p-info) 60%, black);--p-info-900: color-mix(in srgb, var(--p-info) 50%, black);--p-info-950: color-mix(in srgb, var(--p-info) 40%, black);--p-help: rgb(168, 85, 247);--p-help-50: color-mix(in srgb, var(--p-help) 5%, white);--p-help-100: color-mix(in srgb, var(--p-help) 10%, white);--p-help-200: color-mix(in srgb, var(--p-help) 20%, white);--p-help-300: color-mix(in srgb, var(--p-help) 30%, white);--p-help-400: color-mix(in srgb, var(--p-help) 40%, white);--p-help-500: var(--p-help);--p-help-600: color-mix(in srgb, var(--p-help) 80%, black);--p-help-700: color-mix(in srgb, var(--p-help) 70%, black);--p-help-800: color-mix(in srgb, var(--p-help) 60%, black);--p-help-900: color-mix(in srgb, var(--p-help) 50%, black);--p-help-950: color-mix(in srgb, var(--p-help) 40%, black);--p-accent: rgb(20, 184, 166);--p-accent-50: color-mix(in srgb, var(--p-accent) 5%, white);--p-accent-100: color-mix(in srgb, var(--p-accent) 10%, white);--p-accent-200: color-mix(in srgb, var(--p-accent) 20%, white);--p-accent-300: color-mix(in srgb, var(--p-accent) 30%, white);--p-accent-400: color-mix(in srgb, var(--p-accent) 40%, white);--p-accent-500: var(--p-accent);--p-accent-600: color-mix(in srgb, var(--p-accent) 80%, black);--p-accent-700: color-mix(in srgb, var(--p-accent) 70%, black);--p-accent-800: color-mix(in srgb, var(--p-accent) 60%, black);--p-accent-900: color-mix(in srgb, var(--p-accent) 50%, black);--p-accent-950: color-mix(in srgb, var(--p-accent) 40%, black);--p-surface-0: #ffffff;--p-surface-50: #fafafa;--p-surface-100: #f5f5f5;--p-surface-200: #e5e5e5;--p-surface-300: #d4d4d4;--p-surface-400: #a3a3a3;--p-surface-500: #737373;--p-surface-600: #525252;--p-surface-700: #404040;--p-surface-800: #262626;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #171717;--p-surface-950: #0a0a0a;--p-content-border-radius: 6px}:root{--p-primary-color: var(--p-primary-500);--p-primary-contrast-color: var(--p-surface-0);--p-primary-hover-color: var(--p-primary-600);--p-primary-active-color: var(--p-primary-700);--p-content-border-color: var(--p-surface-200);--p-content-hover-background: var(--p-surface-100);--p-content-hover-color: var(--p-surface-800);--p-highlight-background: var(--p-primary-50);--p-highlight-color: var(--p-primary-700);--p-highlight-focus-background: var(--p-primary-100);--p-highlight-focus-color: var(--p-primary-800);--p-content-background: var(--p-surface-0);--p-text-color: var(--p-surface-700);--p-text-hover-color: var(--p-surface-800);--p-text-muted-color: var(--p-surface-500);--p-text-hover-muted-color: var(--p-surface-600)}@media(prefers-color-scheme:dark){:root{--p-surface-D: #fff;--p-surface-0: #fff;--p-surface-50: #fafafa;--p-surface-100: #f4f4f5;--p-surface-200: #e4e4e7;--p-surface-300: #d4d4d8;--p-surface-400: #a1a1aa;--p-surface-500: #71717a;--p-surface-600: #545250;--p-surface-700: #403e3c;--p-surface-800: #2b2927;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #1c1a19;--p-surface-950: #0f0e0d;--p-primary: rgb(0, 125, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-primary-color: var(--p-primary-400);--p-primary-contrast-color: var(--p-surface-900);--p-primary-hover-color: var(--p-primary-300);--p-primary-active-color: var(--p-primary-200);--p-content-border-color: var(--p-surface-700);--p-content-hover-background: var(--p-surface-800);--p-content-hover-color: var(--p-surface-0);--p-highlight-background: color-mix(in srgb, var(--p-primary-400), transparent 84%);--p-highlight-color: rgba(255, 255, 255, 87%);--p-highlight-focus-background: color-mix(in srgb, var(--p-primary-400), transparent 76%);--p-highlight-focus-color: rgba(255, 255, 255, 87%);--p-content-background: var(--p-surface-900);--p-text-color: var(--p-surface-0);--p-text-hover-color: var(--p-surface-0);--p-text-muted-color: var(--p-surface-400);--p-text-hover-muted-color: var(--p-surface-300)}}.monaco-host{width:100%;height:100%;box-sizing:border-box;display:flex;flex-direction:column}.monaco-container{flex:1 1 auto;width:100%;height:100%;min-height:100px;border:1px solid var(--p-content-border-color);border-radius:4px;overflow:hidden}.monaco-status{flex:1 1 auto;display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;font-size:13px;color:var(--p-text-muted-color);border:1px solid var(--p-content-border-color);border-radius:4px;padding:12px}.monaco-status.error{color:var(--p-red-500, #ef4444)}", $r = { props: { type: "object", properties: { mode: { type: "string", enum: ["editor", "diff"], default: "editor", description: "Editor mode (single buffer) or diff mode (baseline vs current)." }, language: { type: "string", default: "plaintext", description: "Monaco language id (e.g. lua, javascript, typescript, json, markdown)." }, value: { type: "string", default: "", description: "Initial buffer value for editor mode. Ignored in diff mode." }, baseline: { type: "string", default: "", description: "Original side of the diff (read-only). Diff mode only." }, current: { type: "string", default: "", description: "Modified side of the diff (read-only). Diff mode only." }, readonly: { type: "boolean", default: !1, description: "Editor mode only. Diff mode is always read-only." }, theme: { type: "string", enum: ["auto", "keeper-dark", "keeper-light"], default: "auto", description: "Color theme. `auto` derives from app CSS variables (--p-content-background, --p-text-color, --p-primary-500, --p-surface-*) and re-themes on prefers-color-scheme / [data-theme] changes. `keeper-dark` and `keeper-light` are fixed presets." }, "min-height": { type: "number", default: 0, description: "Minimum height in px. 0 means fill the container." } } } }, Vr = {
  wippy: $r
};
class Fr extends Ir {
  static get wippyConfig() {
    return {
      propsSchema: Vr.wippy.props,
      hostCssKeys: ["themeConfigUrl"],
      inlineCss: Dr
    };
  }
  static get vueConfig() {
    return {
      rootComponent: Mr
    };
  }
}
Vt(import.meta.url, Fr);
//# sourceMappingURL=index.js.map
