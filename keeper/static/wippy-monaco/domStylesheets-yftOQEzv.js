class Zn {
  constructor() {
    this.listeners = [], this.unexpectedErrorHandler = function(e) {
      setTimeout(() => {
        throw e.stack ? Le.isErrorNoTelemetry(e) ? new Le(e.message + `

` + e.stack) : new Error(e.message + `

` + e.stack) : e;
      }, 0);
    };
  }
  emit(e) {
    this.listeners.forEach((n) => {
      n(e);
    });
  }
  onUnexpectedError(e) {
    this.unexpectedErrorHandler(e), this.emit(e);
  }
  // For external errors, we don't want the listeners to be called
  onUnexpectedExternalError(e) {
    this.unexpectedErrorHandler(e);
  }
}
const t1 = new Zn();
function dt(t) {
  t1.onUnexpectedError(t);
}
function se(t) {
  X1(t) || t1.onUnexpectedError(t);
}
function Vr(t) {
  X1(t) || t1.onUnexpectedExternalError(t);
}
function Jn(t) {
  if (t instanceof Error) {
    const { name: e, message: n, cause: s } = t, i = t.stacktrace || t.stack;
    return {
      $isError: !0,
      name: e,
      message: n,
      stack: i,
      noTelemetry: Le.isErrorNoTelemetry(t),
      cause: s ? Jn(s) : void 0,
      code: t.code
    };
  }
  return t;
}
const ft = "Canceled";
function X1(t) {
  return t instanceof ye ? !0 : t instanceof Error && t.name === ft && t.message === ft;
}
class ye extends Error {
  constructor() {
    super(ft), this.name = this.message;
  }
}
function xr() {
  const t = new Error(ft);
  return t.name = t.message, t;
}
function es(t) {
  return t ? new Error(`Illegal argument: ${t}`) : new Error("Illegal argument");
}
function Ur(t) {
  return t ? new Error(`Illegal state: ${t}`) : new Error("Illegal state");
}
class Br extends Error {
  constructor(e) {
    super("NotSupported"), e && (this.message = e);
  }
}
class Le extends Error {
  constructor(e) {
    super(e), this.name = "CodeExpectedError";
  }
  static fromError(e) {
    if (e instanceof Le)
      return e;
    const n = new Le();
    return n.message = e.message, n.stack = e.stack, n;
  }
  static isErrorNoTelemetry(e) {
    return e.name === "CodeExpectedError";
  }
}
class K extends Error {
  constructor(e) {
    super(e || "An unexpected bug occurred."), Object.setPrototypeOf(this, K.prototype);
  }
}
function Wr(t, e) {
  if (!t)
    throw new Error(e ? `Assertion failed (${e})` : "Assertion Failed");
}
function $r(t, e = "Unreachable") {
  throw new Error(e);
}
function ts(t, e = "unexpected state") {
  if (!t)
    throw typeof e == "string" ? new K(`Assertion Failed: ${e}`) : e;
}
function Hr(t, e = "Soft Assertion Failed") {
  t || se(new K(e));
}
function Z1(t) {
  if (!t()) {
    debugger;
    t(), se(new K("Assertion Failed"));
  }
}
function qr(t, e) {
  let n = 0;
  for (; n < t.length - 1; ) {
    const s = t[n], i = t[n + 1];
    if (!e(s, i))
      return !1;
    n++;
  }
  return !0;
}
function ns(t) {
  return typeof t == "string";
}
function Gr(t, e) {
  return Array.isArray(t) && t.every(e);
}
function jr(t) {
  return typeof t == "object" && t !== null && !Array.isArray(t) && !(t instanceof RegExp) && !(t instanceof Date);
}
function zr(t) {
  const e = Object.getPrototypeOf(Uint8Array);
  return typeof t == "object" && t instanceof e;
}
function Qr(t) {
  return typeof t == "number" && !isNaN(t);
}
function ss(t) {
  return !!t && typeof t[Symbol.iterator] == "function";
}
function Yr(t) {
  return t === !0 || t === !1;
}
function is(t) {
  return typeof t > "u";
}
function Me(t) {
  return !J1(t);
}
function J1(t) {
  return is(t) || t === null;
}
function Xr(t, e) {
  if (!t)
    throw new Error(e ? `Unexpected type, expected '${e}'` : "Unexpected type");
}
function Zr(t) {
  return ts(t != null, "Argument is `undefined` or `null`."), t;
}
function rs(t) {
  return typeof t == "function";
}
function Jr(t, e) {
  const n = Math.min(t.length, e.length);
  for (let s = 0; s < n; s++)
    os(t[s], e[s]);
}
function os(t, e) {
  if (ns(e)) {
    if (typeof t !== e)
      throw new Error(`argument does not match constraint: typeof ${e}`);
  } else if (rs(e)) {
    try {
      if (t instanceof e)
        return;
    } catch {
    }
    if (!J1(t) && t.constructor === e || e.length === 1 && e.call(void 0, t) === !0)
      return;
    throw new Error("argument does not match one of these constraints: arg instanceof constraint, arg.constructor === constraint, nor constraint(arg) === true");
  }
}
function eo(t) {
  return t;
}
var Ut;
(function(t) {
  function e(y) {
    return !!y && typeof y == "object" && typeof y[Symbol.iterator] == "function";
  }
  t.is = e;
  const n = Object.freeze([]);
  function s() {
    return n;
  }
  t.empty = s;
  function* i(y) {
    yield y;
  }
  t.single = i;
  function r(y) {
    return e(y) ? y : i(y);
  }
  t.wrap = r;
  function o(y) {
    return y || n;
  }
  t.from = o;
  function* a(y) {
    for (let b = y.length - 1; b >= 0; b--)
      yield y[b];
  }
  t.reverse = a;
  function u(y) {
    return !y || y[Symbol.iterator]().next().done === !0;
  }
  t.isEmpty = u;
  function l(y) {
    return y[Symbol.iterator]().next().value;
  }
  t.first = l;
  function d(y, b) {
    let w = 0;
    for (const x of y)
      if (b(x, w++))
        return !0;
    return !1;
  }
  t.some = d;
  function c(y, b) {
    let w = 0;
    for (const x of y)
      if (!b(x, w++))
        return !1;
    return !0;
  }
  t.every = c;
  function p(y, b) {
    for (const w of y)
      if (b(w))
        return w;
  }
  t.find = p;
  function* O(y, b) {
    for (const w of y)
      b(w) && (yield w);
  }
  t.filter = O;
  function* V(y, b) {
    let w = 0;
    for (const x of y)
      yield b(x, w++);
  }
  t.map = V;
  function* Z(y, b) {
    let w = 0;
    for (const x of y)
      yield* b(x, w++);
  }
  t.flatMap = Z;
  function* re(...y) {
    for (const b of y)
      ss(b) ? yield* b : yield b;
  }
  t.concat = re;
  function be(y, b, w) {
    let x = w;
    for (const De of y)
      x = b(x, De);
    return x;
  }
  t.reduce = be;
  function J(y) {
    let b = 0;
    for (const w of y)
      b++;
    return b;
  }
  t.length = J;
  function* W(y, b, w = y.length) {
    for (b < -y.length && (b = 0), b < 0 && (b += y.length), w < 0 ? w += y.length : w > y.length && (w = y.length); b < w; b++)
      yield y[b];
  }
  t.slice = W;
  function Tt(y, b = Number.POSITIVE_INFINITY) {
    const w = [];
    if (b === 0)
      return [w, y];
    const x = y[Symbol.iterator]();
    for (let De = 0; De < b; De++) {
      const m = x.next();
      if (m.done)
        return [w, t.empty()];
      w.push(m.value);
    }
    return [w, { [Symbol.iterator]() {
      return x;
    } }];
  }
  t.consume = Tt;
  async function Rt(y) {
    const b = [];
    for await (const w of y)
      b.push(w);
    return b;
  }
  t.asyncToArray = Rt;
  async function Kt(y) {
    let b = [];
    for await (const w of y)
      b = b.concat(w);
    return b;
  }
  t.asyncToArrayFlat = Kt;
})(Ut || (Ut = {}));
function to(t) {
  return t;
}
function as(t) {
  return typeof t == "object" && t !== null && typeof t.dispose == "function" && t.dispose.length === 0;
}
function n1(t) {
  if (Ut.is(t)) {
    const e = [];
    for (const n of t)
      if (n)
        try {
          n.dispose();
        } catch (s) {
          e.push(s);
        }
    if (e.length === 1)
      throw e[0];
    if (e.length > 1)
      throw new AggregateError(e, "Encountered errors while disposing of store");
    return Array.isArray(t) ? [] : t;
  } else if (t)
    return t.dispose(), t;
}
function us(...t) {
  return q(() => n1(t));
}
class ls {
  constructor(e) {
    this._isDisposed = !1, this._fn = e;
  }
  dispose() {
    if (!this._isDisposed) {
      if (!this._fn)
        throw new Error("Unbound disposable context: Need to use an arrow function to preserve the value of this");
      this._isDisposed = !0, this._fn();
    }
  }
}
function q(t) {
  return new ls(t);
}
class M {
  static {
    this.DISABLE_DISPOSED_WARNING = !1;
  }
  constructor() {
    this._toDispose = /* @__PURE__ */ new Set(), this._isDisposed = !1;
  }
  /**
   * Dispose of all registered disposables and mark this object as disposed.
   *
   * Any future disposables added to this object will be disposed of on `add`.
   */
  dispose() {
    this._isDisposed || (this._isDisposed = !0, this.clear());
  }
  /**
   * @return `true` if this object has been disposed of.
   */
  get isDisposed() {
    return this._isDisposed;
  }
  /**
   * Dispose of all registered disposables but do not mark this object as disposed.
   */
  clear() {
    if (this._toDispose.size !== 0)
      try {
        n1(this._toDispose);
      } finally {
        this._toDispose.clear();
      }
  }
  /**
   * Add a new {@link IDisposable disposable} to the collection.
   */
  add(e) {
    if (!e || e === _e.None)
      return e;
    if (e === this)
      throw new Error("Cannot register a disposable on itself!");
    return this._isDisposed ? M.DISABLE_DISPOSED_WARNING || console.warn(new Error("Trying to add a disposable to a DisposableStore that has already been disposed of. The added object will be leaked!").stack) : this._toDispose.add(e), e;
  }
  /**
   * Deletes a disposable from store and disposes of it. This will not throw or warn and proceed to dispose the
   * disposable even when the disposable is not part in the store.
   */
  delete(e) {
    if (e) {
      if (e === this)
        throw new Error("Cannot dispose a disposable on itself!");
      this._toDispose.delete(e), e.dispose();
    }
  }
}
class _e {
  static {
    this.None = Object.freeze({ dispose() {
    } });
  }
  constructor() {
    this._store = new M(), this._store;
  }
  dispose() {
    this._store.dispose();
  }
  /**
   * Adds `o` to the collection of disposables managed by this object.
   */
  _register(e) {
    if (e === this)
      throw new Error("Cannot register a disposable on itself!");
    return this._store.add(e);
  }
}
class no {
  constructor() {
    this._isDisposed = !1;
  }
  /**
   * Get the currently held disposable value, or `undefined` if this MutableDisposable has been disposed
   */
  get value() {
    return this._isDisposed ? void 0 : this._value;
  }
  /**
   * Set a new disposable value.
   *
   * Behaviour:
   * - If the MutableDisposable has been disposed, the setter is a no-op.
   * - If the new value is strictly equal to the current value, the setter is a no-op.
   * - Otherwise the previous value (if any) is disposed and the new value is stored.
   *
   * Related helpers:
   * - clear() resets the value to `undefined` (and disposes the previous value).
   * - clearAndLeak() returns the old value without disposing it and removes its parent.
   */
  set value(e) {
    this._isDisposed || e === this._value || (this._value?.dispose(), this._value = e);
  }
  /**
   * Resets the stored value and disposed of the previously stored value.
   */
  clear() {
    this.value = void 0;
  }
  dispose() {
    this._isDisposed = !0, this._value?.dispose(), this._value = void 0;
  }
}
class so {
  constructor(e) {
    this._disposable = e, this._counter = 1;
  }
  acquire() {
    return this._counter++, this;
  }
  release() {
    return --this._counter === 0 && this._disposable.dispose(), this;
  }
}
class io {
  constructor(e) {
    this.object = e;
  }
  dispose() {
  }
}
class ro {
  constructor() {
    this._store = /* @__PURE__ */ new Map(), this._isDisposed = !1;
  }
  /**
   * Disposes of all stored values and mark this object as disposed.
   *
   * Trying to use this object after it has been disposed of is an error.
   */
  dispose() {
    this._isDisposed = !0, this.clearAndDisposeAll();
  }
  /**
   * Disposes of all stored values and clear the map, but DO NOT mark this object as disposed.
   */
  clearAndDisposeAll() {
    if (this._store.size)
      try {
        n1(this._store.values());
      } finally {
        this._store.clear();
      }
  }
  get(e) {
    return this._store.get(e);
  }
  set(e, n, s = !1) {
    this._isDisposed && console.warn(new Error("Trying to add a disposable to a DisposableMap that has already been disposed of. The added object will be leaked!").stack), s || this._store.get(e)?.dispose(), this._store.set(e, n);
  }
  /**
   * Delete the value stored for `key` from this map and also dispose of it.
   */
  deleteAndDispose(e) {
    this._store.get(e)?.dispose(), this._store.delete(e);
  }
  values() {
    return this._store.values();
  }
  [Symbol.iterator]() {
    return this._store[Symbol.iterator]();
  }
}
function oo(t) {
  if (t.length === 0)
    throw new Error("Invalid tail call");
  return [t.slice(0, t.length - 1), t[t.length - 1]];
}
function cs(t, e, n = (s, i) => s === i) {
  if (t === e)
    return !0;
  if (!t || !e || t.length !== e.length)
    return !1;
  for (let s = 0, i = t.length; s < i; s++)
    if (!n(t[s], e[s]))
      return !1;
  return !0;
}
function ao(t, e) {
  const n = t.length - 1;
  e < n && (t[e] = t[n]), t.pop();
}
function uo(t, e, n) {
  return ds(t.length, (s) => n(t[s], e));
}
function ds(t, e) {
  let n = 0, s = t - 1;
  for (; n <= s; ) {
    const i = (n + s) / 2 | 0, r = e(i);
    if (r < 0)
      n = i + 1;
    else if (r > 0)
      s = i - 1;
    else
      return i;
  }
  return -(n + 1);
}
function A1(t, e, n) {
  if (t = t | 0, t >= e.length)
    throw new TypeError("invalid index");
  const s = e[Math.floor(e.length * Math.random())], i = [], r = [], o = [];
  for (const a of e) {
    const u = n(a, s);
    u < 0 ? i.push(a) : u > 0 ? r.push(a) : o.push(a);
  }
  return t < i.length ? A1(t, i, n) : t < i.length + o.length ? o[0] : A1(t - (i.length + o.length), r, n);
}
function lo(t, e) {
  const n = [];
  let s;
  for (const i of t.slice(0).sort(e))
    !s || e(s[0], i) !== 0 ? (s = [i], n.push(s)) : s.push(i);
  return n;
}
function* co(t, e) {
  let n, s;
  for (const i of t)
    s !== void 0 && e(s, i) ? n.push(i) : (n && (yield n), n = [i]), s = i;
  n && (yield n);
}
function fo(t, e) {
  for (let n = 0; n <= t.length; n++)
    e(n === 0 ? void 0 : t[n - 1], n === t.length ? void 0 : t[n]);
}
function ho(t, e) {
  for (let n = 0; n < t.length; n++)
    e(n === 0 ? void 0 : t[n - 1], t[n], n + 1 === t.length ? void 0 : t[n + 1]);
}
function po(t) {
  return t.filter((e) => !!e);
}
function mo(t) {
  let e = 0;
  for (let n = 0; n < t.length; n++)
    t[n] && (t[e] = t[n], e += 1);
  t.length = e;
}
function _o(t) {
  return !Array.isArray(t) || t.length === 0;
}
function yo(t) {
  return Array.isArray(t) && t.length > 0;
}
function go(t, e = (n) => n) {
  const n = /* @__PURE__ */ new Set();
  return t.filter((s) => {
    const i = e(s);
    return n.has(i) ? !1 : (n.add(i), !0);
  });
}
function bo(t, e) {
  let n = typeof e == "number" ? t : 0;
  typeof e == "number" ? n = t : (n = 0, e = t);
  const s = [];
  if (n <= e)
    for (let i = n; i < e; i++)
      s.push(i);
  else
    for (let i = n; i > e; i--)
      s.push(i);
  return s;
}
function Co(t, e, n) {
  const s = t.slice(0, e), i = t.slice(e);
  return s.concat(n, i);
}
function vo(t, e) {
  const n = t.indexOf(e);
  n > -1 && (t.splice(n, 1), t.unshift(e));
}
function wo(t, e) {
  const n = t.indexOf(e);
  n > -1 && (t.splice(n, 1), t.push(e));
}
function Eo(t, e) {
  for (const n of e)
    t.push(n);
}
function Ao(t, e) {
  const n = [];
  for (const s of t) {
    const i = e(s);
    i !== void 0 && n.push(i);
  }
  return n;
}
function So(t) {
  return Array.isArray(t) ? t : [t];
}
function fs(t, e, n) {
  const s = en(t, e), i = t.length, r = n.length;
  t.length = i + r;
  for (let o = i - 1; o >= s; o--)
    t[o + r] = t[o];
  for (let o = 0; o < r; o++)
    t[o + s] = n[o];
}
function Do(t, e, n, s) {
  const i = en(t, e);
  let r = t.splice(i, n);
  return r === void 0 && (r = []), fs(t, i, s), r;
}
function en(t, e) {
  return e < 0 ? Math.max(e + t.length, 0) : Math.min(e, t.length);
}
var he;
(function(t) {
  function e(r) {
    return r < 0;
  }
  t.isLessThan = e;
  function n(r) {
    return r <= 0;
  }
  t.isLessThanOrEqual = n;
  function s(r) {
    return r > 0;
  }
  t.isGreaterThan = s;
  function i(r) {
    return r === 0;
  }
  t.isNeitherLessOrGreaterThan = i, t.greaterThan = 1, t.lessThan = -1, t.neitherLessOrGreaterThan = 0;
})(he || (he = {}));
function Oo(t, e) {
  return (n, s) => e(t(n), t(s));
}
function To(...t) {
  return (e, n) => {
    for (const s of t) {
      const i = s(e, n);
      if (!he.isNeitherLessOrGreaterThan(i))
        return i;
    }
    return he.neitherLessOrGreaterThan;
  };
}
const hs = (t, e) => t - e, Ro = (t, e) => hs(t ? 1 : 0, e ? 1 : 0);
function Ko(t) {
  return (e, n) => -t(e, n);
}
function ko(t) {
  return (e, n) => e === void 0 ? n === void 0 ? he.neitherLessOrGreaterThan : he.lessThan : n === void 0 ? he.greaterThan : t(e, n);
}
class Lo {
  /**
   * Constructs a queue that is backed by the given array. Runtime is O(1).
  */
  constructor(e) {
    this.firstIdx = 0, this.items = e, this.lastIdx = this.items.length - 1;
  }
  get length() {
    return this.lastIdx - this.firstIdx + 1;
  }
  /**
   * Consumes elements from the beginning of the queue as long as the predicate returns true.
   * If no elements were consumed, `null` is returned. Has a runtime of O(result.length).
  */
  takeWhile(e) {
    let n = this.firstIdx;
    for (; n < this.items.length && e(this.items[n]); )
      n++;
    const s = n === this.firstIdx ? null : this.items.slice(this.firstIdx, n);
    return this.firstIdx = n, s;
  }
  /**
   * Consumes elements from the end of the queue as long as the predicate returns true.
   * If no elements were consumed, `null` is returned.
   * The result has the same order as the underlying array!
  */
  takeFromEndWhile(e) {
    let n = this.lastIdx;
    for (; n >= 0 && e(this.items[n]); )
      n--;
    const s = n === this.lastIdx ? null : this.items.slice(n + 1, this.lastIdx + 1);
    return this.lastIdx = n, s;
  }
  peek() {
    if (this.length !== 0)
      return this.items[this.firstIdx];
  }
  dequeue() {
    const e = this.items[this.firstIdx];
    return this.firstIdx++, e;
  }
  takeCount(e) {
    const n = this.items.slice(this.firstIdx, this.firstIdx + e);
    return this.firstIdx += e, n;
  }
}
class rt {
  static {
    this.empty = new rt((e) => {
    });
  }
  constructor(e) {
    this.iterate = e;
  }
  toArray() {
    const e = [];
    return this.iterate((n) => (e.push(n), !0)), e;
  }
  filter(e) {
    return new rt((n) => this.iterate((s) => e(s) ? n(s) : !0));
  }
  map(e) {
    return new rt((n) => this.iterate((s) => n(e(s))));
  }
  findLast(e) {
    let n;
    return this.iterate((s) => (e(s) && (n = s), !0)), n;
  }
  findLastMaxBy(e) {
    let n, s = !0;
    return this.iterate((i) => ((s || he.isGreaterThan(e(i, n))) && (s = !1, n = i), !0)), n;
  }
}
class Bt {
  constructor(e) {
    this._indexMap = e;
  }
  /**
   * Returns a permutation that sorts the given array according to the given compare function.
   */
  static createSortPermutation(e, n) {
    const s = Array.from(e.keys()).sort((i, r) => n(e[i], e[r]));
    return new Bt(s);
  }
  /**
   * Returns a new array with the elements of the given array re-arranged according to this permutation.
   */
  apply(e) {
    return e.map((n, s) => e[this._indexMap[s]]);
  }
  /**
   * Returns a new permutation that undoes the re-arrangement of this permutation.
  */
  inverse() {
    const e = this._indexMap.slice();
    for (let n = 0; n < this._indexMap.length; n++)
      e[this._indexMap[n]] = n;
    return new Bt(e);
  }
}
function No(t) {
  return t.reduce((e, n) => e + n, 0);
}
function ps(t, e) {
  const n = this;
  let s = !1, i;
  return function() {
    return s || (s = !0, i = t.apply(n, arguments)), i;
  };
}
class D {
  static {
    this.Undefined = new D(void 0);
  }
  constructor(e) {
    this.element = e, this.next = D.Undefined, this.prev = D.Undefined;
  }
}
class ms {
  constructor() {
    this._first = D.Undefined, this._last = D.Undefined, this._size = 0;
  }
  get size() {
    return this._size;
  }
  isEmpty() {
    return this._first === D.Undefined;
  }
  clear() {
    let e = this._first;
    for (; e !== D.Undefined; ) {
      const n = e.next;
      e.prev = D.Undefined, e.next = D.Undefined, e = n;
    }
    this._first = D.Undefined, this._last = D.Undefined, this._size = 0;
  }
  unshift(e) {
    return this._insert(e, !1);
  }
  push(e) {
    return this._insert(e, !0);
  }
  _insert(e, n) {
    const s = new D(e);
    if (this._first === D.Undefined)
      this._first = s, this._last = s;
    else if (n) {
      const r = this._last;
      this._last = s, s.prev = r, r.next = s;
    } else {
      const r = this._first;
      this._first = s, s.next = r, r.prev = s;
    }
    this._size += 1;
    let i = !1;
    return () => {
      i || (i = !0, this._remove(s));
    };
  }
  shift() {
    if (this._first !== D.Undefined) {
      const e = this._first.element;
      return this._remove(this._first), e;
    }
  }
  pop() {
    if (this._last !== D.Undefined) {
      const e = this._last.element;
      return this._remove(this._last), e;
    }
  }
  _remove(e) {
    if (e.prev !== D.Undefined && e.next !== D.Undefined) {
      const n = e.prev;
      n.next = e.next, e.next.prev = n;
    } else e.prev === D.Undefined && e.next === D.Undefined ? (this._first = D.Undefined, this._last = D.Undefined) : e.next === D.Undefined ? (this._last = this._last.prev, this._last.next = D.Undefined) : e.prev === D.Undefined && (this._first = this._first.next, this._first.prev = D.Undefined);
    this._size -= 1;
  }
  *[Symbol.iterator]() {
    let e = this._first;
    for (; e !== D.Undefined; )
      yield e.element, e = e.next;
  }
}
const _s = globalThis.performance.now.bind(globalThis.performance);
class s1 {
  static create(e) {
    return new s1(e);
  }
  constructor(e) {
    this._now = e === !1 ? Date.now : _s, this._startTime = this._now(), this._stopTime = -1;
  }
  stop() {
    this._stopTime = this._now();
  }
  reset() {
    this._startTime = this._now(), this._stopTime = -1;
  }
  elapsed() {
    return this._stopTime !== -1 ? this._stopTime - this._startTime : this._now() - this._startTime;
  }
}
var He;
(function(t) {
  t.None = () => _e.None;
  function e(m, f) {
    return p(m, () => {
    }, 0, void 0, !0, void 0, f);
  }
  t.defer = e;
  function n(m) {
    return (f, _ = null, h) => {
      let g = !1, v;
      return v = m((E) => {
        if (!g)
          return v ? v.dispose() : g = !0, f.call(_, E);
      }, null, h), g && v.dispose(), v;
    };
  }
  t.once = n;
  function s(m, f) {
    return t.once(t.filter(m, f));
  }
  t.onceIf = s;
  function i(m, f, _) {
    return d((h, g = null, v) => m((E) => h.call(g, f(E)), null, v), _);
  }
  t.map = i;
  function r(m, f, _) {
    return d((h, g = null, v) => m((E) => {
      f(E), h.call(g, E);
    }, null, v), _);
  }
  t.forEach = r;
  function o(m, f, _) {
    return d((h, g = null, v) => m((E) => f(E) && h.call(g, E), null, v), _);
  }
  t.filter = o;
  function a(m) {
    return m;
  }
  t.signal = a;
  function u(...m) {
    return (f, _ = null, h) => {
      const g = us(...m.map((v) => v((E) => f.call(_, E))));
      return c(g, h);
    };
  }
  t.any = u;
  function l(m, f, _, h) {
    let g = _;
    return i(m, (v) => (g = f(g, v), g), h);
  }
  t.reduce = l;
  function d(m, f) {
    let _;
    const h = {
      onWillAddFirstListener() {
        _ = m(g.fire, g);
      },
      onDidRemoveLastListener() {
        _?.dispose();
      }
    }, g = new F(h);
    return f?.add(g), g.event;
  }
  function c(m, f) {
    return f instanceof Array ? f.push(m) : f && f.add(m), m;
  }
  function p(m, f, _ = 100, h = !1, g = !1, v, E) {
    let L, U, Ce, Je = 0, Fe;
    const Qn = {
      leakWarningThreshold: v,
      onWillAddFirstListener() {
        L = m((Yn) => {
          Je++, U = f(U, Yn), h && !Ce && (et.fire(U), U = void 0), Fe = () => {
            const Xn = U;
            U = void 0, Ce = void 0, (!h || Je > 1) && et.fire(Xn), Je = 0;
          }, typeof _ == "number" ? (Ce && clearTimeout(Ce), Ce = setTimeout(Fe, _)) : Ce === void 0 && (Ce = null, queueMicrotask(Fe));
        });
      },
      onWillRemoveListener() {
        g && Je > 0 && Fe?.();
      },
      onDidRemoveLastListener() {
        Fe = void 0, L.dispose();
      }
    }, et = new F(Qn);
    return E?.add(et), et.event;
  }
  t.debounce = p;
  function O(m, f = 0, _) {
    return t.debounce(m, (h, g) => h ? (h.push(g), h) : [g], f, void 0, !0, void 0, _);
  }
  t.accumulate = O;
  function V(m, f = (h, g) => h === g, _) {
    let h = !0, g;
    return o(m, (v) => {
      const E = h || !f(v, g);
      return h = !1, g = v, E;
    }, _);
  }
  t.latch = V;
  function Z(m, f, _) {
    return [
      t.filter(m, f, _),
      t.filter(m, (h) => !f(h), _)
    ];
  }
  t.split = Z;
  function re(m, f = !1, _ = [], h) {
    let g = _.slice(), v = m((U) => {
      g ? g.push(U) : L.fire(U);
    });
    h && h.add(v);
    const E = () => {
      g?.forEach((U) => L.fire(U)), g = null;
    }, L = new F({
      onWillAddFirstListener() {
        v || (v = m((U) => L.fire(U)), h && h.add(v));
      },
      onDidAddFirstListener() {
        g && (f ? setTimeout(E) : E());
      },
      onDidRemoveLastListener() {
        v && v.dispose(), v = null;
      }
    });
    return h && h.add(L), L.event;
  }
  t.buffer = re;
  function be(m, f) {
    return (h, g, v) => {
      const E = f(new W());
      return m(function(L) {
        const U = E.evaluate(L);
        U !== J && h.call(g, U);
      }, void 0, v);
    };
  }
  t.chain = be;
  const J = Symbol("HaltChainable");
  class W {
    constructor() {
      this.steps = [];
    }
    map(f) {
      return this.steps.push(f), this;
    }
    forEach(f) {
      return this.steps.push((_) => (f(_), _)), this;
    }
    filter(f) {
      return this.steps.push((_) => f(_) ? _ : J), this;
    }
    reduce(f, _) {
      let h = _;
      return this.steps.push((g) => (h = f(h, g), h)), this;
    }
    latch(f = (_, h) => _ === h) {
      let _ = !0, h;
      return this.steps.push((g) => {
        const v = _ || !f(g, h);
        return _ = !1, h = g, v ? g : J;
      }), this;
    }
    evaluate(f) {
      for (const _ of this.steps)
        if (f = _(f), f === J)
          break;
      return f;
    }
  }
  function Tt(m, f, _ = (h) => h) {
    const h = (...L) => E.fire(_(...L)), g = () => m.on(f, h), v = () => m.removeListener(f, h), E = new F({ onWillAddFirstListener: g, onDidRemoveLastListener: v });
    return E.event;
  }
  t.fromNodeEventEmitter = Tt;
  function Rt(m, f, _ = (h) => h) {
    const h = (...L) => E.fire(_(...L)), g = () => m.addEventListener(f, h), v = () => m.removeEventListener(f, h), E = new F({ onWillAddFirstListener: g, onDidRemoveLastListener: v });
    return E.event;
  }
  t.fromDOMEventEmitter = Rt;
  function Kt(m, f) {
    let _;
    const h = new Promise((g, v) => {
      const E = n(m)(g, null, f);
      _ = () => E.dispose();
    });
    return h.cancel = _, h;
  }
  t.toPromise = Kt;
  function y(m, f) {
    return m((_) => f.fire(_));
  }
  t.forward = y;
  function b(m, f, _) {
    return f(_), m((h) => f(h));
  }
  t.runAndSubscribe = b;
  class w {
    constructor(f, _) {
      this._observable = f, this._counter = 0, this._hasChanged = !1;
      const h = {
        onWillAddFirstListener: () => {
          f.addObserver(this), this._observable.reportChanges();
        },
        onDidRemoveLastListener: () => {
          f.removeObserver(this);
        }
      };
      this.emitter = new F(h), _ && _.add(this.emitter);
    }
    beginUpdate(f) {
      this._counter++;
    }
    handlePossibleChange(f) {
    }
    handleChange(f, _) {
      this._hasChanged = !0;
    }
    endUpdate(f) {
      this._counter--, this._counter === 0 && (this._observable.reportChanges(), this._hasChanged && (this._hasChanged = !1, this.emitter.fire(this._observable.get())));
    }
  }
  function x(m, f) {
    return new w(m, f).emitter.event;
  }
  t.fromObservable = x;
  function De(m) {
    return (f, _, h) => {
      let g = 0, v = !1;
      const E = {
        beginUpdate() {
          g++;
        },
        endUpdate() {
          g--, g === 0 && (m.reportChanges(), v && (v = !1, f.call(_)));
        },
        handlePossibleChange() {
        },
        handleChange() {
          v = !0;
        }
      };
      m.addObserver(E), m.reportChanges();
      const L = {
        dispose() {
          m.removeObserver(E);
        }
      };
      return h instanceof M ? h.add(L) : Array.isArray(h) && h.push(L), L;
    };
  }
  t.fromObservableLight = De;
})(He || (He = {}));
class ht {
  static {
    this.all = /* @__PURE__ */ new Set();
  }
  static {
    this._idPool = 0;
  }
  constructor(e) {
    this.listenerCount = 0, this.invocationCount = 0, this.elapsedOverall = 0, this.durations = [], this.name = `${e}_${ht._idPool++}`, ht.all.add(this);
  }
  start(e) {
    this._stopWatch = new s1(), this.listenerCount = e;
  }
  stop() {
    if (this._stopWatch) {
      const e = this._stopWatch.elapsed();
      this.durations.push(e), this.elapsedOverall += e, this.invocationCount += 1, this._stopWatch = void 0;
    }
  }
}
let ys = -1;
class i1 {
  static {
    this._idPool = 1;
  }
  constructor(e, n, s = (i1._idPool++).toString(16).padStart(3, "0")) {
    this._errorHandler = e, this.threshold = n, this.name = s, this._warnCountdown = 0;
  }
  dispose() {
    this._stacks?.clear();
  }
  check(e, n) {
    const s = this.threshold;
    if (s <= 0 || n < s)
      return;
    this._stacks || (this._stacks = /* @__PURE__ */ new Map());
    const i = this._stacks.get(e.value) || 0;
    if (this._stacks.set(e.value, i + 1), this._warnCountdown -= 1, this._warnCountdown <= 0) {
      this._warnCountdown = s * 0.5;
      const [r, o] = this.getMostFrequentStack(), a = `[${this.name}] potential listener LEAK detected, having ${n} listeners already. MOST frequent listener (${o}):`;
      console.warn(a), console.warn(r);
      const u = new gs(a, r);
      this._errorHandler(u);
    }
    return () => {
      const r = this._stacks.get(e.value) || 0;
      this._stacks.set(e.value, r - 1);
    };
  }
  getMostFrequentStack() {
    if (!this._stacks)
      return;
    let e, n = 0;
    for (const [s, i] of this._stacks)
      (!e || n < i) && (e = [s, i], n = i);
    return e;
  }
}
class r1 {
  static create() {
    const e = new Error();
    return new r1(e.stack ?? "");
  }
  constructor(e) {
    this.value = e;
  }
  print() {
    console.warn(this.value.split(`
`).slice(2).join(`
`));
  }
}
class gs extends Error {
  constructor(e, n) {
    super(e), this.name = "ListenerLeakError", this.stack = n;
  }
}
class bs extends Error {
  constructor(e, n) {
    super(e), this.name = "ListenerRefusalError", this.stack = n;
  }
}
class kt {
  constructor(e) {
    this.value = e;
  }
}
const Cs = 2;
class F {
  constructor(e) {
    this._size = 0, this._options = e, this._leakageMon = this._options?.leakWarningThreshold ? new i1(e?.onListenerError ?? se, this._options?.leakWarningThreshold ?? ys) : void 0, this._perfMon = this._options?._profName ? new ht(this._options._profName) : void 0, this._deliveryQueue = this._options?.deliveryQueue;
  }
  dispose() {
    this._disposed || (this._disposed = !0, this._deliveryQueue?.current === this && this._deliveryQueue.reset(), this._listeners && (this._listeners = void 0, this._size = 0), this._options?.onDidRemoveLastListener?.(), this._leakageMon?.dispose());
  }
  /**
   * For the public to allow to subscribe
   * to events from this Emitter
   */
  get event() {
    return this._event ??= (e, n, s) => {
      if (this._leakageMon && this._size > this._leakageMon.threshold ** 2) {
        const a = `[${this._leakageMon.name}] REFUSES to accept new listeners because it exceeded its threshold by far (${this._size} vs ${this._leakageMon.threshold})`;
        console.warn(a);
        const u = this._leakageMon.getMostFrequentStack() ?? ["UNKNOWN stack", -1], l = new bs(`${a}. HINT: Stack shows most frequent listener (${u[1]}-times)`, u[0]);
        return (this._options?.onListenerError || se)(l), _e.None;
      }
      if (this._disposed)
        return _e.None;
      n && (e = e.bind(n));
      const i = new kt(e);
      let r;
      this._leakageMon && this._size >= Math.ceil(this._leakageMon.threshold * 0.2) && (i.stack = r1.create(), r = this._leakageMon.check(i.stack, this._size + 1)), this._listeners ? this._listeners instanceof kt ? (this._deliveryQueue ??= new tn(), this._listeners = [this._listeners, i]) : this._listeners.push(i) : (this._options?.onWillAddFirstListener?.(this), this._listeners = i, this._options?.onDidAddFirstListener?.(this)), this._options?.onDidAddListener?.(this), this._size++;
      const o = q(() => {
        r?.(), this._removeListener(i);
      });
      return s instanceof M ? s.add(o) : Array.isArray(s) && s.push(o), o;
    }, this._event;
  }
  _removeListener(e) {
    if (this._options?.onWillRemoveListener?.(this), !this._listeners)
      return;
    if (this._size === 1) {
      this._listeners = void 0, this._options?.onDidRemoveLastListener?.(this), this._size = 0;
      return;
    }
    const n = this._listeners, s = n.indexOf(e);
    if (s === -1)
      throw console.log("disposed?", this._disposed), console.log("size?", this._size), console.log("arr?", JSON.stringify(this._listeners)), new Error("Attempted to dispose unknown listener");
    this._size--, n[s] = void 0;
    const i = this._deliveryQueue.current === this;
    if (this._size * Cs <= n.length) {
      let r = 0;
      for (let o = 0; o < n.length; o++)
        n[o] ? n[r++] = n[o] : i && r < this._deliveryQueue.end && (this._deliveryQueue.end--, r < this._deliveryQueue.i && this._deliveryQueue.i--);
      n.length = r;
    }
  }
  _deliver(e, n) {
    if (!e)
      return;
    const s = this._options?.onListenerError || se;
    if (!s) {
      e.value(n);
      return;
    }
    try {
      e.value(n);
    } catch (i) {
      s(i);
    }
  }
  /** Delivers items in the queue. Assumes the queue is ready to go. */
  _deliverQueue(e) {
    const n = e.current._listeners;
    for (; e.i < e.end; )
      this._deliver(n[e.i++], e.value);
    e.reset();
  }
  /**
   * To be kept private to fire an event to
   * subscribers
   */
  fire(e) {
    if (this._deliveryQueue?.current && (this._deliverQueue(this._deliveryQueue), this._perfMon?.stop()), this._perfMon?.start(this._size), this._listeners) if (this._listeners instanceof kt)
      this._deliver(this._listeners, e);
    else {
      const n = this._deliveryQueue;
      n.enqueue(this, e, this._listeners.length), this._deliverQueue(n);
    }
    this._perfMon?.stop();
  }
  hasListeners() {
    return this._size > 0;
  }
}
const Io = () => new tn();
class tn {
  constructor() {
    this.i = -1, this.end = 0;
  }
  enqueue(e, n, s) {
    this.i = 0, this.end = s, this.current = e, this.value = n;
  }
  reset() {
    this.i = this.end, this.current = void 0, this.value = void 0;
  }
}
class vs extends F {
  constructor(e) {
    super(e), this._isPaused = 0, this._eventQueue = new ms(), this._mergeFn = e?.merge;
  }
  pause() {
    this._isPaused++;
  }
  resume() {
    if (this._isPaused !== 0 && --this._isPaused === 0)
      if (this._mergeFn) {
        if (this._eventQueue.size > 0) {
          const e = Array.from(this._eventQueue);
          this._eventQueue.clear(), super.fire(this._mergeFn(e));
        }
      } else
        for (; !this._isPaused && this._eventQueue.size !== 0; )
          super.fire(this._eventQueue.shift());
  }
  fire(e) {
    this._size && (this._isPaused !== 0 ? this._eventQueue.push(e) : super.fire(e));
  }
}
class Fo extends vs {
  constructor(e) {
    super(e), this._delay = e.delay ?? 100;
  }
  fire(e) {
    this._handle || (this.pause(), this._handle = setTimeout(() => {
      this._handle = void 0, this.resume();
    }, this._delay)), super.fire(e);
  }
}
class Mo extends F {
  constructor(e) {
    super(e), this._queuedEvents = [], this._mergeFn = e?.merge;
  }
  fire(e) {
    this.hasListeners() && (this._queuedEvents.push(e), this._queuedEvents.length === 1 && queueMicrotask(() => {
      this._mergeFn ? super.fire(this._mergeFn(this._queuedEvents)) : this._queuedEvents.forEach((n) => super.fire(n)), this._queuedEvents = [];
    }));
  }
}
class Po {
  constructor() {
    this.hasListeners = !1, this.events = [], this.emitter = new F({
      onWillAddFirstListener: () => this.onFirstListenerAdd(),
      onDidRemoveLastListener: () => this.onLastListenerRemove()
    });
  }
  get event() {
    return this.emitter.event;
  }
  add(e) {
    const n = { event: e, listener: null };
    return this.events.push(n), this.hasListeners && this.hook(n), q(ps(() => {
      this.hasListeners && this.unhook(n);
      const i = this.events.indexOf(n);
      this.events.splice(i, 1);
    }));
  }
  onFirstListenerAdd() {
    this.hasListeners = !0, this.events.forEach((e) => this.hook(e));
  }
  onLastListenerRemove() {
    this.hasListeners = !1, this.events.forEach((e) => this.unhook(e));
  }
  hook(e) {
    e.listener = e.event((n) => this.emitter.fire(n));
  }
  unhook(e) {
    e.listener?.dispose(), e.listener = null;
  }
  dispose() {
    this.emitter.dispose();
    for (const e of this.events)
      e.listener?.dispose();
    this.events = [];
  }
}
class Vo {
  constructor() {
    this.data = [];
  }
  wrapEvent(e, n, s) {
    return (i, r, o) => e((a) => {
      const u = this.data[this.data.length - 1];
      if (!n) {
        u ? u.buffers.push(() => i.call(r, a)) : i.call(r, a);
        return;
      }
      const l = u;
      if (!l) {
        i.call(r, n(s, a));
        return;
      }
      l.items ??= [], l.items.push(a), l.buffers.length === 0 && u.buffers.push(() => {
        l.reducedResult ??= s ? l.items.reduce(n, s) : l.items.reduce(n), i.call(r, l.reducedResult);
      });
    }, void 0, o);
  }
  bufferEvents(e) {
    const n = { buffers: new Array() };
    this.data.push(n);
    const s = e();
    return this.data.pop(), n.buffers.forEach((i) => i()), s;
  }
}
class xo {
  constructor() {
    this.listening = !1, this.inputEvent = He.None, this.inputEventListener = _e.None, this.emitter = new F({
      onDidAddFirstListener: () => {
        this.listening = !0, this.inputEventListener = this.inputEvent(this.emitter.fire, this.emitter);
      },
      onDidRemoveLastListener: () => {
        this.listening = !1, this.inputEventListener.dispose();
      }
    }), this.event = this.emitter.event;
  }
  set input(e) {
    this.inputEvent = e, this.listening && (this.inputEventListener.dispose(), this.inputEventListener = e(this.emitter.fire, this.emitter));
  }
  dispose() {
    this.inputEventListener.dispose(), this.emitter.dispose();
  }
}
let ve;
function ws(t) {
  ve ? ve instanceof S1 ? ve.loggers.push(t) : ve = new S1([ve, t]) : ve = t;
}
function P() {
  return ve;
}
class S1 {
  constructor(e) {
    this.loggers = e;
  }
  handleObservableCreated(e, n) {
    for (const s of this.loggers)
      s.handleObservableCreated(e, n);
  }
  handleOnListenerCountChanged(e, n) {
    for (const s of this.loggers)
      s.handleOnListenerCountChanged(e, n);
  }
  handleObservableUpdated(e, n) {
    for (const s of this.loggers)
      s.handleObservableUpdated(e, n);
  }
  handleAutorunCreated(e, n) {
    for (const s of this.loggers)
      s.handleAutorunCreated(e, n);
  }
  handleAutorunDisposed(e) {
    for (const n of this.loggers)
      n.handleAutorunDisposed(e);
  }
  handleAutorunDependencyChanged(e, n, s) {
    for (const i of this.loggers)
      i.handleAutorunDependencyChanged(e, n, s);
  }
  handleAutorunStarted(e) {
    for (const n of this.loggers)
      n.handleAutorunStarted(e);
  }
  handleAutorunFinished(e) {
    for (const n of this.loggers)
      n.handleAutorunFinished(e);
  }
  handleDerivedDependencyChanged(e, n, s) {
    for (const i of this.loggers)
      i.handleDerivedDependencyChanged(e, n, s);
  }
  handleDerivedCleared(e) {
    for (const n of this.loggers)
      n.handleDerivedCleared(e);
  }
  handleBeginTransaction(e) {
    for (const n of this.loggers)
      n.handleBeginTransaction(e);
  }
  handleEndTransaction(e) {
    for (const n of this.loggers)
      n.handleEndTransaction(e);
  }
}
var B;
(function(t) {
  let e = !1;
  function n() {
    e = !0;
  }
  t.enable = n;
  function s() {
    if (!e)
      return;
    const i = Error, r = i.stackTraceLimit;
    i.stackTraceLimit = 3;
    const o = new Error().stack;
    return i.stackTraceLimit = r, o1.fromStack(o, 2);
  }
  t.ofCaller = s;
})(B || (B = {}));
class o1 {
  static fromStack(e, n) {
    const s = e.split(`
`), i = Es(s[n + 1]);
    if (i)
      return new o1(i.fileName, i.line, i.column, i.id);
  }
  constructor(e, n, s, i) {
    this.fileName = e, this.line = n, this.column = s, this.id = i;
  }
}
function Es(t) {
  const e = t.match(/\((.*):(\d+):(\d+)\)/);
  if (e)
    return {
      fileName: e[1],
      line: parseInt(e[2]),
      column: parseInt(e[3]),
      id: t
    };
  const n = t.match(/at ([^\(\)]*):(\d+):(\d+)/);
  if (n)
    return {
      fileName: n[1],
      line: parseInt(n[2]),
      column: parseInt(n[3]),
      id: t
    };
}
const te = (t, e) => t === e;
function Uo(t = te) {
  return (e, n) => cs(e, n, t);
}
function Bo() {
  return (t, e) => t.equals(e);
}
function Wo(t, e, n) {
  if (n !== void 0) {
    const s = t;
    return s == null || e === void 0 || e === null ? e === s : n(s, e);
  } else {
    const s = t;
    return (i, r) => i == null || r === void 0 || r === null ? r === i : s(i, r);
  }
}
function D1(t, e) {
  if (t === e)
    return !0;
  if (Array.isArray(t) && Array.isArray(e)) {
    if (t.length !== e.length)
      return !1;
    for (let n = 0; n < t.length; n++)
      if (!D1(t[n], e[n]))
        return !1;
    return !0;
  }
  if (t && typeof t == "object" && e && typeof e == "object" && Object.getPrototypeOf(t) === Object.prototype && Object.getPrototypeOf(e) === Object.prototype) {
    const n = t, s = e, i = Object.keys(n), r = Object.keys(s), o = new Set(r);
    if (i.length !== r.length)
      return !1;
    for (const a of i)
      if (!o.has(a) || !D1(n[a], s[a]))
        return !1;
    return !0;
  }
  return !1;
}
class G {
  constructor(e, n, s) {
    this.owner = e, this.debugNameSource = n, this.referenceFn = s;
  }
  getDebugName(e) {
    return As(e, this);
  }
}
const O1 = /* @__PURE__ */ new Map(), Wt = /* @__PURE__ */ new WeakMap();
function As(t, e) {
  const n = Wt.get(t);
  if (n)
    return n;
  const s = Ss(t, e);
  if (s) {
    let i = O1.get(s) ?? 0;
    i++, O1.set(s, i);
    const r = i === 1 ? s : `${s}#${i}`;
    return Wt.set(t, r), r;
  }
}
function Ss(t, e) {
  const n = Wt.get(t);
  if (n)
    return n;
  const s = e.owner ? Os(e.owner) + "." : "";
  let i;
  const r = e.debugNameSource;
  if (r !== void 0)
    if (typeof r == "function") {
      if (i = r(), i !== void 0)
        return s + i;
    } else
      return s + r;
  const o = e.referenceFn;
  if (o !== void 0 && (i = a1(o), i !== void 0))
    return s + i;
  if (e.owner !== void 0) {
    const a = Ds(e.owner, t);
    if (a !== void 0)
      return s + a;
  }
}
function Ds(t, e) {
  for (const n in t)
    if (t[n] === e)
      return n;
}
const T1 = /* @__PURE__ */ new Map(), R1 = /* @__PURE__ */ new WeakMap();
function Os(t) {
  const e = R1.get(t);
  if (e)
    return e;
  const n = nn(t) ?? "Object";
  let s = T1.get(n) ?? 0;
  s++, T1.set(n, s);
  const i = s === 1 ? n : `${n}#${s}`;
  return R1.set(t, i), i;
}
function nn(t) {
  const e = t.constructor;
  if (e)
    return e.name === "Object" ? void 0 : e.name;
}
function a1(t) {
  const e = t.toString(), s = /\/\*\*\s*@description\s*([^*]*)\*\//.exec(e);
  return (s ? s[1] : void 0)?.trim();
}
let $t;
function Ts(t) {
  $t = t;
}
let sn;
function Rs(t) {
  sn = t;
}
class Ks {
  get TChange() {
    return null;
  }
  reportChanges() {
    this.get();
  }
  /** @sealed */
  read(e) {
    return e ? e.readObservable(this) : this.get();
  }
  map(e, n, s = B.ofCaller()) {
    const i = n === void 0 ? void 0 : e, r = n === void 0 ? e : n;
    return $t({
      owner: i,
      debugName: () => {
        const o = a1(r);
        if (o !== void 0)
          return o;
        const u = /^\s*\(?\s*([a-zA-Z_$][a-zA-Z_$0-9]*)\s*\)?\s*=>\s*\1(?:\??)\.([a-zA-Z_$][a-zA-Z_$0-9]*)\s*$/.exec(r.toString());
        if (u)
          return `${this.debugName}.${u[2]}`;
        if (!i)
          return `${this.debugName} (mapped)`;
      },
      debugReferenceFn: r
    }, (o) => r(this.read(o), o), s);
  }
  /**
   * @sealed
   * Converts an observable of an observable value into a direct observable of the value.
  */
  flatten() {
    return $t({
      owner: void 0,
      debugName: () => `${this.debugName} (flattened)`
    }, (e) => this.read(e).read(e));
  }
  recomputeInitiallyAndOnChange(e, n) {
    return e.add(sn(this, n)), this;
  }
}
class u1 extends Ks {
  constructor(e) {
    super(), this._observers = /* @__PURE__ */ new Set(), P()?.handleObservableCreated(this, e);
  }
  addObserver(e) {
    const n = this._observers.size;
    this._observers.add(e), n === 0 && this.onFirstObserverAdded(), n !== this._observers.size && P()?.handleOnListenerCountChanged(this, this._observers.size);
  }
  removeObserver(e) {
    const n = this._observers.delete(e);
    n && this._observers.size === 0 && this.onLastObserverRemoved(), n && P()?.handleOnListenerCountChanged(this, this._observers.size);
  }
  onFirstObserverAdded() {
  }
  onLastObserverRemoved() {
  }
  debugGetObservers() {
    return this._observers;
  }
}
function ks(t) {
  switch (t) {
    case 0:
      return "initial";
    case 1:
      return "dependenciesMightHaveChanged";
    case 2:
      return "stale";
    case 3:
      return "upToDate";
    default:
      return "<unknown>";
  }
}
class Y extends u1 {
  get debugName() {
    return this._debugNameData.getDebugName(this) ?? "(anonymous)";
  }
  constructor(e, n, s, i = void 0, r, o) {
    super(o), this._debugNameData = e, this._computeFn = n, this._changeTracker = s, this._handleLastObserverRemoved = i, this._equalityComparator = r, this._state = 0, this._value = void 0, this._updateCount = 0, this._dependencies = /* @__PURE__ */ new Set(), this._dependenciesToBeRemoved = /* @__PURE__ */ new Set(), this._changeSummary = void 0, this._isUpdating = !1, this._isComputing = !1, this._didReportChange = !1, this._isInBeforeUpdate = !1, this._isReaderValid = !1, this._store = void 0, this._delayedStore = void 0, this._removedObserverToCallEndUpdateOn = null, this._changeSummary = this._changeTracker?.createChangeSummary(void 0);
  }
  onLastObserverRemoved() {
    this._state = 0, this._value = void 0, P()?.handleDerivedCleared(this);
    for (const e of this._dependencies)
      e.removeObserver(this);
    this._dependencies.clear(), this._store !== void 0 && (this._store.dispose(), this._store = void 0), this._delayedStore !== void 0 && (this._delayedStore.dispose(), this._delayedStore = void 0), this._handleLastObserverRemoved?.();
  }
  get() {
    if (this._isComputing, this._observers.size === 0) {
      let n;
      try {
        this._isReaderValid = !0;
        let s;
        this._changeTracker && (s = this._changeTracker.createChangeSummary(void 0), this._changeTracker.beforeUpdate?.(this, s)), n = this._computeFn(this, s);
      } finally {
        this._isReaderValid = !1;
      }
      return this.onLastObserverRemoved(), n;
    } else {
      do {
        if (this._state === 1) {
          for (const n of this._dependencies)
            if (n.reportChanges(), this._state === 2)
              break;
        }
        this._state === 1 && (this._state = 3), this._state !== 3 && this._recompute();
      } while (this._state !== 3);
      return this._value;
    }
  }
  _recompute() {
    let e = !1;
    this._isComputing = !0, this._didReportChange = !1;
    const n = this._dependenciesToBeRemoved;
    this._dependenciesToBeRemoved = this._dependencies, this._dependencies = n;
    try {
      const s = this._changeSummary;
      this._isReaderValid = !0, this._changeTracker && (this._isInBeforeUpdate = !0, this._changeTracker.beforeUpdate?.(this, s), this._isInBeforeUpdate = !1, this._changeSummary = this._changeTracker?.createChangeSummary(s));
      const i = this._state !== 0, r = this._value;
      this._state = 3;
      const o = this._delayedStore;
      o !== void 0 && (this._delayedStore = void 0);
      try {
        this._store !== void 0 && (this._store.dispose(), this._store = void 0), this._value = this._computeFn(this, s);
      } finally {
        this._isReaderValid = !1;
        for (const a of this._dependenciesToBeRemoved)
          a.removeObserver(this);
        this._dependenciesToBeRemoved.clear(), o !== void 0 && o.dispose();
      }
      e = this._didReportChange || i && !this._equalityComparator(r, this._value), P()?.handleObservableUpdated(this, {
        oldValue: r,
        newValue: this._value,
        change: void 0,
        didChange: e,
        hadValue: i
      });
    } catch (s) {
      dt(s);
    }
    if (this._isComputing = !1, !this._didReportChange && e)
      for (const s of this._observers)
        s.handleChange(this, void 0);
    else
      this._didReportChange = !1;
  }
  toString() {
    return `LazyDerived<${this.debugName}>`;
  }
  // IObserver Implementation
  beginUpdate(e) {
    if (this._isUpdating)
      throw new K("Cyclic deriveds are not supported yet!");
    this._updateCount++, this._isUpdating = !0;
    try {
      const n = this._updateCount === 1;
      if (this._state === 3 && (this._state = 1, !n))
        for (const s of this._observers)
          s.handlePossibleChange(this);
      if (n)
        for (const s of this._observers)
          s.beginUpdate(this);
    } finally {
      this._isUpdating = !1;
    }
  }
  endUpdate(e) {
    if (this._updateCount--, this._updateCount === 0) {
      const n = [...this._observers];
      for (const s of n)
        s.endUpdate(this);
      if (this._removedObserverToCallEndUpdateOn) {
        const s = [...this._removedObserverToCallEndUpdateOn];
        this._removedObserverToCallEndUpdateOn = null;
        for (const i of s)
          i.endUpdate(this);
      }
    }
    Z1(() => this._updateCount >= 0);
  }
  handlePossibleChange(e) {
    if (this._state === 3 && this._dependencies.has(e) && !this._dependenciesToBeRemoved.has(e)) {
      this._state = 1;
      for (const n of this._observers)
        n.handlePossibleChange(this);
    }
  }
  handleChange(e, n) {
    if (this._dependencies.has(e) && !this._dependenciesToBeRemoved.has(e) || this._isInBeforeUpdate) {
      P()?.handleDerivedDependencyChanged(this, e, n);
      let s = !1;
      try {
        s = this._changeTracker ? this._changeTracker.handleChange({
          changedObservable: e,
          change: n,
          // eslint-disable-next-line local/code-no-any-casts
          didChange: (r) => r === e
        }, this._changeSummary) : !0;
      } catch (r) {
        dt(r);
      }
      const i = this._state === 3;
      if (s && (this._state === 1 || i) && (this._state = 2, i))
        for (const r of this._observers)
          r.handlePossibleChange(this);
    }
  }
  // IReader Implementation
  _ensureReaderValid() {
    if (!this._isReaderValid)
      throw new K("The reader object cannot be used outside its compute function!");
  }
  readObservable(e) {
    this._ensureReaderValid(), e.addObserver(this);
    const n = e.get();
    return this._dependencies.add(e), this._dependenciesToBeRemoved.delete(e), n;
  }
  get store() {
    return this._ensureReaderValid(), this._store === void 0 && (this._store = new M()), this._store;
  }
  addObserver(e) {
    const n = !this._observers.has(e) && this._updateCount > 0;
    super.addObserver(e), n && (this._removedObserverToCallEndUpdateOn && this._removedObserverToCallEndUpdateOn.has(e) ? this._removedObserverToCallEndUpdateOn.delete(e) : e.beginUpdate(this));
  }
  removeObserver(e) {
    this._observers.has(e) && this._updateCount > 0 && (this._removedObserverToCallEndUpdateOn || (this._removedObserverToCallEndUpdateOn = /* @__PURE__ */ new Set()), this._removedObserverToCallEndUpdateOn.add(e)), super.removeObserver(e);
  }
  debugGetState() {
    return {
      state: this._state,
      stateStr: ks(this._state),
      updateCount: this._updateCount,
      isComputing: this._isComputing,
      dependencies: this._dependencies,
      value: this._value
    };
  }
  debugSetValue(e) {
    this._value = e;
  }
  debugRecompute() {
    this._isComputing ? this._state = 2 : this._recompute();
  }
  setValue(e, n, s) {
    this._value = e;
    const i = this._observers;
    n.updateObserver(this, this);
    for (const r of i)
      r.handleChange(this, s);
  }
}
class Ls extends Y {
  constructor(e, n, s, i = void 0, r, o, a) {
    super(e, n, s, i, r, a), this.set = o;
  }
}
function Pe(t, e, n = B.ofCaller()) {
  return e !== void 0 ? new Y(new G(t, void 0, e), e, void 0, void 0, te, n) : new Y(
    // eslint-disable-next-line local/code-no-any-casts
    new G(void 0, void 0, t),
    // eslint-disable-next-line local/code-no-any-casts
    t,
    void 0,
    void 0,
    te,
    n
  );
}
function $o(t, e, n, s = B.ofCaller()) {
  return new Ls(new G(t, void 0, e), e, void 0, void 0, te, n, s);
}
function qe(t, e, n = B.ofCaller()) {
  return new Y(new G(t.owner, t.debugName, t.debugReferenceFn), e, void 0, t.onLastObserverRemoved, t.equalsFn ?? te, n);
}
Ts(qe);
function Ho(t, e, n = B.ofCaller()) {
  return new Y(new G(t.owner, t.debugName, void 0), e, t.changeTracker, void 0, t.equalityComparer ?? te, n);
}
function qo(t, e, n = B.ofCaller()) {
  let s, i;
  e === void 0 ? (s = t, i = void 0) : (i = t, s = e);
  let r;
  return new Y(new G(i, void 0, s), (o) => {
    r ? r.clear() : r = new M();
    const a = s(o);
    return a && r.add(a), a;
  }, void 0, () => {
    r && (r.dispose(), r = void 0);
  }, te, n);
}
const rn = Object.freeze(function(t, e) {
  const n = setTimeout(t.bind(e), 0);
  return { dispose() {
    clearTimeout(n);
  } };
});
var pt;
(function(t) {
  function e(n) {
    return n === t.None || n === t.Cancelled || n instanceof ot ? !0 : !n || typeof n != "object" ? !1 : typeof n.isCancellationRequested == "boolean" && typeof n.onCancellationRequested == "function";
  }
  t.isCancellationToken = e, t.None = Object.freeze({
    isCancellationRequested: !1,
    onCancellationRequested: He.None
  }), t.Cancelled = Object.freeze({
    isCancellationRequested: !0,
    onCancellationRequested: rn
  });
})(pt || (pt = {}));
class ot {
  constructor() {
    this._isCancelled = !1, this._emitter = null;
  }
  cancel() {
    this._isCancelled || (this._isCancelled = !0, this._emitter && (this._emitter.fire(void 0), this.dispose()));
  }
  get isCancellationRequested() {
    return this._isCancelled;
  }
  get onCancellationRequested() {
    return this._isCancelled ? rn : (this._emitter || (this._emitter = new F()), this._emitter.event);
  }
  dispose() {
    this._emitter && (this._emitter.dispose(), this._emitter = null);
  }
}
class Et {
  constructor(e) {
    this._token = void 0, this._parentListener = void 0, this._parentListener = e && e.onCancellationRequested(this.cancel, this);
  }
  get token() {
    return this._token || (this._token = new ot()), this._token;
  }
  cancel() {
    this._token ? this._token instanceof ot && this._token.cancel() : this._token = pt.Cancelled;
  }
  dispose(e = !1) {
    e && this.cancel(), this._parentListener?.dispose(), this._token ? this._token instanceof ot && this._token.dispose() : this._token = pt.None;
  }
}
function Go(t) {
  const e = new Et();
  return t.add({ dispose() {
    e.cancel();
  } }), e.token;
}
function Ns(t) {
  switch (t) {
    case 1:
      return "dependenciesMightHaveChanged";
    case 2:
      return "stale";
    case 3:
      return "upToDate";
    default:
      return "<unknown>";
  }
}
class Ge {
  get debugName() {
    return this._debugNameData.getDebugName(this) ?? "(anonymous)";
  }
  constructor(e, n, s, i) {
    this._debugNameData = e, this._runFn = n, this._changeTracker = s, this._state = 2, this._updateCount = 0, this._disposed = !1, this._dependencies = /* @__PURE__ */ new Set(), this._dependenciesToBeRemoved = /* @__PURE__ */ new Set(), this._isRunning = !1, this._store = void 0, this._delayedStore = void 0, this._changeSummary = this._changeTracker?.createChangeSummary(void 0), P()?.handleAutorunCreated(this, i), this._run();
  }
  dispose() {
    if (!this._disposed) {
      this._disposed = !0;
      for (const e of this._dependencies)
        e.removeObserver(this);
      this._dependencies.clear(), this._store !== void 0 && this._store.dispose(), this._delayedStore !== void 0 && this._delayedStore.dispose(), P()?.handleAutorunDisposed(this);
    }
  }
  _run() {
    const e = this._dependenciesToBeRemoved;
    this._dependenciesToBeRemoved = this._dependencies, this._dependencies = e, this._state = 3;
    try {
      if (!this._disposed) {
        P()?.handleAutorunStarted(this);
        const n = this._changeSummary, s = this._delayedStore;
        s !== void 0 && (this._delayedStore = void 0);
        try {
          this._isRunning = !0, this._changeTracker && (this._changeTracker.beforeUpdate?.(this, n), this._changeSummary = this._changeTracker.createChangeSummary(n)), this._store !== void 0 && (this._store.dispose(), this._store = void 0), this._runFn(this, n);
        } catch (i) {
          dt(i);
        } finally {
          this._isRunning = !1, s !== void 0 && s.dispose();
        }
      }
    } finally {
      this._disposed || P()?.handleAutorunFinished(this);
      for (const n of this._dependenciesToBeRemoved)
        n.removeObserver(this);
      this._dependenciesToBeRemoved.clear();
    }
  }
  toString() {
    return `Autorun<${this.debugName}>`;
  }
  // IObserver implementation
  beginUpdate(e) {
    this._state === 3 && (this._state = 1), this._updateCount++;
  }
  endUpdate(e) {
    try {
      if (this._updateCount === 1)
        do {
          if (this._state === 1) {
            this._state = 3;
            for (const n of this._dependencies)
              if (n.reportChanges(), this._state === 2)
                break;
          }
          this._state !== 3 && this._run();
        } while (this._state !== 3);
    } finally {
      this._updateCount--;
    }
    Z1(() => this._updateCount >= 0);
  }
  handlePossibleChange(e) {
    this._state === 3 && this._isDependency(e) && (this._state = 1);
  }
  handleChange(e, n) {
    if (this._isDependency(e)) {
      P()?.handleAutorunDependencyChanged(this, e, n);
      try {
        (this._changeTracker ? this._changeTracker.handleChange({
          changedObservable: e,
          change: n,
          // eslint-disable-next-line local/code-no-any-casts
          didChange: (i) => i === e
        }, this._changeSummary) : !0) && (this._state = 2);
      } catch (s) {
        dt(s);
      }
    }
  }
  _isDependency(e) {
    return this._dependencies.has(e) && !this._dependenciesToBeRemoved.has(e);
  }
  // IReader implementation
  _ensureNoRunning() {
    if (!this._isRunning)
      throw new K("The reader object cannot be used outside its compute function!");
  }
  readObservable(e) {
    if (this._ensureNoRunning(), this._disposed)
      return e.get();
    e.addObserver(this);
    const n = e.get();
    return this._dependencies.add(e), this._dependenciesToBeRemoved.delete(e), n;
  }
  get store() {
    if (this._ensureNoRunning(), this._disposed)
      throw new K("Cannot access store after dispose");
    return this._store === void 0 && (this._store = new M()), this._store;
  }
  debugGetState() {
    return {
      isRunning: this._isRunning,
      updateCount: this._updateCount,
      dependencies: this._dependencies,
      state: this._state,
      stateStr: Ns(this._state)
    };
  }
  debugRerun() {
    this._isRunning ? this._state = 2 : this._run();
  }
}
function on(t, e = B.ofCaller()) {
  return new Ge(new G(void 0, void 0, t), t, void 0, e);
}
function an(t, e, n = B.ofCaller()) {
  return new Ge(new G(t.owner, t.debugName, t.debugReferenceFn ?? e), e, void 0, n);
}
function Is(t, e, n = B.ofCaller()) {
  return new Ge(new G(t.owner, t.debugName, t.debugReferenceFn ?? e), e, t.changeTracker, n);
}
function jo(t, e) {
  const n = new M(), s = Is({
    owner: t.owner,
    debugName: t.debugName,
    debugReferenceFn: t.debugReferenceFn ?? e,
    changeTracker: t.changeTracker
  }, (i, r) => {
    n.clear(), e(i, r, n);
  });
  return q(() => {
    s.dispose(), n.dispose();
  });
}
function zo(t) {
  const e = new M(), n = an({
    owner: void 0,
    debugName: void 0,
    debugReferenceFn: t
  }, (s) => {
    e.clear(), t(s, e);
  });
  return q(() => {
    n.dispose(), e.dispose();
  });
}
function Qo(t, e) {
  let n;
  return an({ debugReferenceFn: e }, (s) => {
    const i = t.read(s), r = n;
    n = i, e({ lastValue: r, newValue: i });
  });
}
function K1(t) {
  const e = new Error("BugIndicatingErrorRecovery: " + t);
  se(e), console.error("recovered from an error that indicates a bug", e);
}
function un(t, e) {
  const n = new At(t, e);
  try {
    t(n);
  } finally {
    n.finish();
  }
}
let tt;
function Yo(t) {
  if (tt)
    t(tt);
  else {
    const e = new At(t, void 0);
    tt = e;
    try {
      t(e);
    } finally {
      e.finish(), tt = void 0;
    }
  }
}
async function Xo(t, e) {
  const n = new At(t, e);
  try {
    await t(n);
  } finally {
    n.finish();
  }
}
function Fs(t, e, n) {
  t ? e(t) : un(e, n);
}
class At {
  constructor(e, n) {
    this._fn = e, this._getDebugName = n, this._updatingObservers = [], P()?.handleBeginTransaction(this);
  }
  getDebugName() {
    return this._getDebugName ? this._getDebugName() : a1(this._fn);
  }
  updateObserver(e, n) {
    if (!this._updatingObservers) {
      K1("Transaction already finished!"), un((s) => {
        s.updateObserver(e, n);
      });
      return;
    }
    this._updatingObservers.push({ observer: e, observable: n }), e.beginUpdate(n);
  }
  finish() {
    const e = this._updatingObservers;
    if (!e) {
      K1("transaction.finish() has already been called!");
      return;
    }
    for (let n = 0; n < e.length; n++) {
      const { observer: s, observable: i } = e[n];
      s.endUpdate(i);
    }
    this._updatingObservers = null, P()?.handleEndTransaction(this);
  }
  debugGetUpdatingObservers() {
    return this._updatingObservers;
  }
}
function Ht(...t) {
  let e, n, s, i;
  return t.length === 2 ? [n, s] = t : [e, n, s, i] = t, new le(new G(e, void 0, s), n, s, () => le.globalTransaction, te, i ?? B.ofCaller());
}
function Zo(t, e, n, s = B.ofCaller()) {
  return new le(new G(t.owner, t.debugName, t.debugReferenceFn ?? n), e, n, () => le.globalTransaction, t.equalsFn ?? te, s);
}
class le extends u1 {
  constructor(e, n, s, i, r, o) {
    super(o), this._debugNameData = e, this.event = n, this._getValue = s, this._getTransaction = i, this._equalityComparator = r, this._hasValue = !1, this.handleEvent = (a) => {
      const u = this._getValue(a), l = this._value, d = !this._hasValue || !this._equalityComparator(l, u);
      let c = !1;
      d && (this._value = u, this._hasValue && (c = !0, Fs(this._getTransaction(), (p) => {
        P()?.handleObservableUpdated(this, { oldValue: l, newValue: u, change: void 0, didChange: d, hadValue: this._hasValue });
        for (const O of this._observers)
          p.updateObserver(O, this), O.handleChange(this, void 0);
      }, () => {
        const p = this.getDebugName();
        return "Event fired" + (p ? `: ${p}` : "");
      })), this._hasValue = !0), c || P()?.handleObservableUpdated(this, { oldValue: l, newValue: u, change: void 0, didChange: d, hadValue: this._hasValue });
    };
  }
  getDebugName() {
    return this._debugNameData.getDebugName(this);
  }
  get debugName() {
    const e = this.getDebugName();
    return "From Event" + (e ? `: ${e}` : "");
  }
  onFirstObserverAdded() {
    this._subscription = this.event(this.handleEvent);
  }
  onLastObserverRemoved() {
    this._subscription.dispose(), this._subscription = void 0, this._hasValue = !1, this._value = void 0;
  }
  get() {
    return this._subscription ? (this._hasValue || this.handleEvent(void 0), this._value) : this._getValue(void 0);
  }
  debugSetValue(e) {
    this._value = e;
  }
  debugGetState() {
    return { value: this._value, hasValue: this._hasValue };
  }
}
(function(t) {
  t.Observer = le;
  function e(n, s) {
    let i = !1;
    le.globalTransaction === void 0 && (le.globalTransaction = n, i = !0);
    try {
      s();
    } finally {
      i && (le.globalTransaction = void 0);
    }
  }
  t.batchEventsGlobally = e;
})(Ht || (Ht = {}));
function Jo(t, e) {
  let n = !1, s, i;
  return Ht((r) => {
    const o = on((a) => {
      const u = t.read(a);
      n ? (i && clearTimeout(i), i = setTimeout(() => {
        s = u, r();
      }, e)) : (n = !0, s = u);
    });
    return {
      dispose() {
        o.dispose(), n = !1, s = void 0;
      }
    };
  }, () => n ? s : t.get());
}
function Ms(t, e) {
  const n = new Ps(!0, e);
  t.addObserver(n);
  try {
    n.beginUpdate(t);
  } finally {
    n.endUpdate(t);
  }
  return q(() => {
    t.removeObserver(n);
  });
}
Rs(Ms);
class Ps {
  constructor(e, n) {
    this._forceRecompute = e, this._handleValue = n, this._counter = 0;
  }
  beginUpdate(e) {
    this._counter++;
  }
  endUpdate(e) {
    this._counter === 1 && this._forceRecompute && (this._handleValue ? this._handleValue(e.get()) : e.reportChanges()), this._counter--;
  }
  handlePossibleChange(e) {
  }
  handleChange(e, n) {
  }
}
function e0(t, e) {
  let n;
  return qe({ owner: t, debugReferenceFn: e }, (i) => (n = e(i, n), n));
}
function t0(t, e, n, s) {
  let i = new k1(n, s);
  return qe({
    debugReferenceFn: n,
    owner: t,
    onLastObserverRemoved: () => {
      i.dispose(), i = new k1(n);
    }
  }, (o) => (i.setItems(e.read(o)), i.getItems()));
}
class k1 {
  constructor(e, n) {
    this._map = e, this._keySelector = n, this._cache = /* @__PURE__ */ new Map(), this._items = [];
  }
  dispose() {
    this._cache.forEach((e) => e.store.dispose()), this._cache.clear();
  }
  setItems(e) {
    const n = [], s = new Set(this._cache.keys());
    for (const i of e) {
      const r = this._keySelector ? this._keySelector(i) : i;
      let o = this._cache.get(r);
      if (o)
        s.delete(r);
      else {
        const a = new M();
        o = { out: this._map(i, a), store: a }, this._cache.set(r, o);
      }
      n.push(o.out);
    }
    for (const i of s)
      this._cache.get(i).store.dispose(), this._cache.delete(i);
    this._items = n;
  }
  getItems() {
    return this._items;
  }
}
function Te(t, e) {
  switch (typeof t) {
    case "number":
      return "" + t;
    case "string":
      return t.length + 2 <= e ? `"${t}"` : `"${t.substr(0, e - 7)}"+...`;
    case "boolean":
      return t ? "true" : "false";
    case "undefined":
      return "undefined";
    case "object":
      return t === null ? "null" : Array.isArray(t) ? Vs(t, e) : xs(t, e);
    case "symbol":
      return t.toString();
    case "function":
      return `[[Function${t.name ? " " + t.name : ""}]]`;
    default:
      return "" + t;
  }
}
function Vs(t, e) {
  let n = "[ ", s = !0;
  for (const i of t) {
    if (s || (n += ", "), n.length - 5 > e) {
      n += "...";
      break;
    }
    s = !1, n += `${Te(i, e - n.length)}`;
  }
  return n += " ]", n;
}
function xs(t, e) {
  if (typeof t.toString == "function" && t.toString !== Object.prototype.toString) {
    const r = t.toString();
    return r.length <= e ? r : r.substring(0, e - 3) + "...";
  }
  const n = nn(t);
  let s = n ? n + "(" : "{ ", i = !0;
  for (const [r, o] of Object.entries(t)) {
    if (i || (s += ", "), s.length - 5 > e) {
      s += "...";
      break;
    }
    i = !1, s += `${r}: ${Te(o, e - s.length)}`;
  }
  return s += n ? ")" : " }", s;
}
class l1 {
  static createClient(e, n) {
    return new l1(e, n);
  }
  constructor(e, n) {
    this._channelFactory = e, this._getHandler = n, this._channel = this._channelFactory({
      handleNotification: (r) => {
        const o = r, a = this._getHandler().notifications[o[0]];
        if (!a)
          throw new Error(`Unknown notification "${o[0]}"!`);
        a(...o[1]);
      },
      handleRequest: (r) => {
        const o = r;
        try {
          return { type: "result", value: this._getHandler().requests[o[0]](...o[1]) };
        } catch (a) {
          return { type: "error", value: a };
        }
      }
    });
    const s = new Proxy({}, {
      get: (r, o) => async (...a) => {
        const u = await this._channel.sendRequest([o, a]);
        if (u.type === "error")
          throw u.value;
        return u.value;
      }
    }), i = new Proxy({}, {
      get: (r, o) => (...a) => {
        this._channel.sendNotification([o, a]);
      }
    });
    this.api = { notifications: i, requests: s };
  }
}
function Us(t, e) {
  const n = globalThis;
  let s = [], i;
  const { channel: r, handler: o } = Bs({
    sendNotification: (u) => {
      i ? i.sendNotification(u) : s.push(u);
    }
  });
  let a;
  return (n.$$debugValueEditor_debugChannels ?? (n.$$debugValueEditor_debugChannels = {}))[t] = (u) => {
    a = e(), i = u;
    for (const l of s)
      u.sendNotification(l);
    return s = [], o;
  }, l1.createClient(r, () => {
    if (!a)
      throw new Error("Not supported");
    return a;
  });
}
function Bs(t) {
  let e;
  return {
    channel: (s) => (e = s, {
      sendNotification: (i) => {
        t.sendNotification(i);
      },
      sendRequest: (i) => {
        throw new Error("not supported");
      }
    }),
    handler: {
      handleRequest: (s) => s.type === "notification" ? e?.handleNotification(s.data) : e?.handleRequest(s.data)
    }
  };
}
let Ws = class {
  constructor() {
    this._timeout = void 0;
  }
  throttle(e, n) {
    this._timeout === void 0 && (this._timeout = setTimeout(() => {
      this._timeout = void 0, e();
    }, n));
  }
  dispose() {
    this._timeout !== void 0 && clearTimeout(this._timeout);
  }
};
function ln(t, e) {
  for (const n in e)
    t[n] && typeof t[n] == "object" && e[n] && typeof e[n] == "object" ? ln(t[n], e[n]) : t[n] = e[n];
}
function cn(t, e) {
  for (const n in e)
    e[n] === null ? delete t[n] : t[n] && typeof t[n] == "object" && e[n] && typeof e[n] == "object" ? cn(t[n], e[n]) : t[n] = e[n];
}
function L1(t, e, n = B.ofCaller()) {
  let s;
  return typeof t == "string" ? s = new G(void 0, t, void 0) : s = new G(t, void 0, void 0), new mt(s, e, te, n);
}
class mt extends u1 {
  get debugName() {
    return this._debugNameData.getDebugName(this) ?? "ObservableValue";
  }
  constructor(e, n, s, i) {
    super(i), this._debugNameData = e, this._equalityComparator = s, this._value = n, P()?.handleObservableUpdated(this, { hadValue: !1, newValue: n, change: void 0, didChange: !0, oldValue: void 0 });
  }
  get() {
    return this._value;
  }
  set(e, n, s) {
    if (s === void 0 && this._equalityComparator(this._value, e))
      return;
    let i;
    n || (n = i = new At(() => {
    }, () => `Setting ${this.debugName}`));
    try {
      const r = this._value;
      this._setValue(e), P()?.handleObservableUpdated(this, { oldValue: r, newValue: e, change: s, didChange: !0, hadValue: !0 });
      for (const o of this._observers)
        n.updateObserver(o, this), o.handleChange(this, s);
    } finally {
      i && i.finish();
    }
  }
  toString() {
    return `${this.debugName}: ${this._value}`;
  }
  _setValue(e) {
    this._value = e;
  }
  debugGetState() {
    return {
      value: this._value
    };
  }
  debugSetValue(e) {
    this._value = e;
  }
}
function s0(t, e, n = B.ofCaller()) {
  let s;
  return typeof t == "string" ? s = new G(void 0, t, void 0) : s = new G(t, void 0, void 0), new $s(s, e, te, n);
}
class $s extends mt {
  _setValue(e) {
    this._value !== e && (this._value && this._value.dispose(), this._value = e);
  }
  dispose() {
    this._value?.dispose();
  }
}
class Re {
  static {
    this._instance = void 0;
  }
  static getInstance() {
    return Re._instance === void 0 && (Re._instance = new Re()), Re._instance;
  }
  getTransactionState() {
    const e = [], n = [...this._activeTransactions];
    if (n.length === 0)
      return;
    const s = n.flatMap((r) => r.debugGetUpdatingObservers() ?? []).map((r) => r.observer), i = /* @__PURE__ */ new Set();
    for (; s.length > 0; ) {
      const r = s.shift();
      if (i.has(r))
        continue;
      i.add(r);
      const o = this._getInfo(r, (a) => {
        i.has(a) || s.push(a);
      });
      o && e.push(o);
    }
    return { names: n.map((r) => r.getDebugName() ?? "tx"), affected: e };
  }
  _getObservableInfo(e) {
    const n = this._instanceInfos.get(e);
    if (!n) {
      se(new K("No info found"));
      return;
    }
    return n;
  }
  _getAutorunInfo(e) {
    const n = this._instanceInfos.get(e);
    if (!n) {
      se(new K("No info found"));
      return;
    }
    return n;
  }
  _getInfo(e, n) {
    if (e instanceof Y) {
      const s = [...e.debugGetObservers()];
      for (const u of s)
        n(u);
      const i = this._getObservableInfo(e);
      if (!i)
        return;
      const r = e.debugGetState(), o = { name: e.debugName, instanceId: i.instanceId, updateCount: r.updateCount }, a = [...i.changedObservables].map((u) => this._instanceInfos.get(u)?.instanceId).filter(Me);
      if (r.isComputing)
        return { ...o, type: "observable/derived", state: "updating", changedDependencies: a, initialComputation: !1 };
      switch (r.state) {
        case 0:
          return { ...o, type: "observable/derived", state: "noValue" };
        case 3:
          return { ...o, type: "observable/derived", state: "upToDate" };
        case 2:
          return { ...o, type: "observable/derived", state: "stale", changedDependencies: a };
        case 1:
          return { ...o, type: "observable/derived", state: "possiblyStale" };
      }
    } else if (e instanceof Ge) {
      const s = this._getAutorunInfo(e);
      if (!s)
        return;
      const i = { name: e.debugName, instanceId: s.instanceId, updateCount: s.updateCount }, r = [...s.changedObservables].map((o) => this._instanceInfos.get(o).instanceId);
      if (e.debugGetState().isRunning)
        return { ...i, type: "autorun", state: "updating", changedDependencies: r };
      switch (e.debugGetState().state) {
        case 3:
          return { ...i, type: "autorun", state: "upToDate" };
        case 2:
          return { ...i, type: "autorun", state: "stale", changedDependencies: r };
        case 1:
          return { ...i, type: "autorun", state: "possiblyStale" };
      }
    }
  }
  _formatObservable(e) {
    const n = this._getObservableInfo(e);
    if (n)
      return { name: e.debugName, instanceId: n.instanceId };
  }
  _formatObserver(e) {
    if (e instanceof Y)
      return { name: e.toString(), instanceId: this._getObservableInfo(e)?.instanceId };
    const n = this._getAutorunInfo(e);
    if (n)
      return { name: e.toString(), instanceId: n.instanceId };
  }
  constructor() {
    this._declarationId = 0, this._instanceId = 0, this._declarations = /* @__PURE__ */ new Map(), this._instanceInfos = /* @__PURE__ */ new WeakMap(), this._aliveInstances = /* @__PURE__ */ new Map(), this._activeTransactions = /* @__PURE__ */ new Set(), this._channel = Us("observableDevTools", () => ({
      notifications: {
        setDeclarationIdFilter: (e) => {
        },
        logObservableValue: (e) => {
          console.log("logObservableValue", e);
        },
        flushUpdates: () => {
          this._flushUpdates();
        },
        resetUpdates: () => {
          this._pendingChanges = null, this._channel.api.notifications.handleChange(this._fullState, !0);
        }
      },
      requests: {
        getDeclarations: () => {
          const e = {};
          for (const n of this._declarations.values())
            e[n.id] = n;
          return { decls: e };
        },
        getSummarizedInstances: () => null,
        getObservableValueInfo: (e) => ({
          observers: [...this._aliveInstances.get(e).debugGetObservers()].map((s) => this._formatObserver(s)).filter(Me)
        }),
        getDerivedInfo: (e) => {
          const n = this._aliveInstances.get(e);
          return {
            dependencies: [...n.debugGetState().dependencies].map((s) => this._formatObservable(s)).filter(Me),
            observers: [...n.debugGetObservers()].map((s) => this._formatObserver(s)).filter(Me)
          };
        },
        getAutorunInfo: (e) => ({
          dependencies: [...this._aliveInstances.get(e).debugGetState().dependencies].map((s) => this._formatObservable(s)).filter(Me)
        }),
        getTransactionState: () => this.getTransactionState(),
        setValue: (e, n) => {
          const s = this._aliveInstances.get(e);
          if (s instanceof Y)
            s.debugSetValue(n);
          else if (s instanceof mt)
            s.debugSetValue(n);
          else if (s instanceof le)
            s.debugSetValue(n);
          else
            throw new K("Observable is not supported");
          const i = [...s.debugGetObservers()];
          for (const r of i)
            r.beginUpdate(s);
          for (const r of i)
            r.handleChange(s, void 0);
          for (const r of i)
            r.endUpdate(s);
        },
        getValue: (e) => {
          const n = this._aliveInstances.get(e);
          if (n instanceof Y)
            return Te(n.debugGetState().value, 200);
          if (n instanceof mt)
            return Te(n.debugGetState().value, 200);
        },
        logValue: (e) => {
          const n = this._aliveInstances.get(e);
          if (n && "get" in n)
            console.log("Logged Value:", n.get());
          else
            throw new K("Observable is not supported");
        },
        rerun: (e) => {
          const n = this._aliveInstances.get(e);
          if (n instanceof Y)
            n.debugRecompute();
          else if (n instanceof Ge)
            n.debugRerun();
          else
            throw new K("Observable is not supported");
        }
      }
    })), this._pendingChanges = null, this._changeThrottler = new Ws(), this._fullState = {}, this._flushUpdates = () => {
      this._pendingChanges !== null && (this._channel.api.notifications.handleChange(this._pendingChanges, !1), this._pendingChanges = null);
    }, B.enable();
  }
  _handleChange(e) {
    cn(this._fullState, e), this._pendingChanges === null ? this._pendingChanges = e : ln(this._pendingChanges, e), this._changeThrottler.throttle(this._flushUpdates, 10);
  }
  _getDeclarationId(e, n) {
    if (!n)
      return -1;
    let s = this._declarations.get(n.id);
    return s === void 0 && (s = {
      id: this._declarationId++,
      type: e,
      url: n.fileName,
      line: n.line,
      column: n.column
    }, this._declarations.set(n.id, s), this._handleChange({ decls: { [s.id]: s } })), s.id;
  }
  handleObservableCreated(e, n) {
    const i = {
      declarationId: this._getDeclarationId("observable/value", n),
      instanceId: this._instanceId++,
      listenerCount: 0,
      lastValue: void 0,
      updateCount: 0,
      changedObservables: /* @__PURE__ */ new Set()
    };
    this._instanceInfos.set(e, i);
  }
  handleOnListenerCountChanged(e, n) {
    const s = this._getObservableInfo(e);
    if (s) {
      if (s.listenerCount === 0 && n > 0) {
        const i = e instanceof Y ? "observable/derived" : "observable/value";
        this._aliveInstances.set(s.instanceId, e), this._handleChange({
          instances: {
            [s.instanceId]: {
              instanceId: s.instanceId,
              declarationId: s.declarationId,
              formattedValue: s.lastValue,
              type: i,
              name: e.debugName
            }
          }
        });
      } else s.listenerCount > 0 && n === 0 && (this._handleChange({
        instances: { [s.instanceId]: null }
      }), this._aliveInstances.delete(s.instanceId));
      s.listenerCount = n;
    }
  }
  handleObservableUpdated(e, n) {
    if (e instanceof Y) {
      this._handleDerivedRecomputed(e, n);
      return;
    }
    const s = this._getObservableInfo(e);
    s && n.didChange && (s.lastValue = Te(n.newValue, 30), s.listenerCount > 0 && this._handleChange({
      instances: { [s.instanceId]: { formattedValue: s.lastValue } }
    }));
  }
  handleAutorunCreated(e, n) {
    const i = {
      declarationId: this._getDeclarationId("autorun", n),
      instanceId: this._instanceId++,
      updateCount: 0,
      changedObservables: /* @__PURE__ */ new Set()
    };
    this._instanceInfos.set(e, i), this._aliveInstances.set(i.instanceId, e), i && this._handleChange({
      instances: {
        [i.instanceId]: {
          instanceId: i.instanceId,
          declarationId: i.declarationId,
          runCount: 0,
          type: "autorun",
          name: e.debugName
        }
      }
    });
  }
  handleAutorunDisposed(e) {
    const n = this._getAutorunInfo(e);
    n && (this._handleChange({
      instances: { [n.instanceId]: null }
    }), this._instanceInfos.delete(e), this._aliveInstances.delete(n.instanceId));
  }
  handleAutorunDependencyChanged(e, n, s) {
    const i = this._getAutorunInfo(e);
    i && i.changedObservables.add(n);
  }
  handleAutorunStarted(e) {
  }
  handleAutorunFinished(e) {
    const n = this._getAutorunInfo(e);
    n && (n.changedObservables.clear(), n.updateCount++, this._handleChange({
      instances: { [n.instanceId]: { runCount: n.updateCount } }
    }));
  }
  handleDerivedDependencyChanged(e, n, s) {
    const i = this._getObservableInfo(e);
    i && i.changedObservables.add(n);
  }
  _handleDerivedRecomputed(e, n) {
    const s = this._getObservableInfo(e);
    if (!s)
      return;
    const i = Te(n.newValue, 30);
    s.updateCount++, s.changedObservables.clear(), s.lastValue = i, s.listenerCount > 0 && this._handleChange({
      instances: { [s.instanceId]: { formattedValue: i, recomputationCount: s.updateCount } }
    });
  }
  handleDerivedCleared(e) {
    const n = this._getObservableInfo(e);
    n && (n.lastValue = void 0, n.changedObservables.clear(), n.listenerCount > 0 && this._handleChange({
      instances: {
        [n.instanceId]: {
          formattedValue: void 0
        }
      }
    }));
  }
  handleBeginTransaction(e) {
    this._activeTransactions.add(e);
  }
  handleEndTransaction(e) {
    this._activeTransactions.delete(e);
  }
}
function Hs() {
  return globalThis._VSCODE_NLS_MESSAGES;
}
function dn() {
  return globalThis._VSCODE_NLS_LANGUAGE;
}
const qs = dn() === "pseudo" || typeof document < "u" && document.location && typeof document.location.hash == "string" && document.location.hash.indexOf("pseudo=true") >= 0;
function _t(t, e) {
  let n;
  return e.length === 0 ? n = t : n = t.replace(/\{(\d+)\}/g, (s, i) => {
    const r = i[0], o = e[r];
    let a = s;
    return typeof o == "string" ? a = o : (typeof o == "number" || typeof o == "boolean" || o === void 0 || o === null) && (a = String(o)), a;
  }), qs && (n = "［" + n.replace(/[aouei]/g, "$&$&") + "］"), n;
}
function i0(t, e, ...n) {
  return _t(typeof t == "number" ? fn(t, e) : e, n);
}
function fn(t, e) {
  const n = Hs()?.[t];
  if (typeof n != "string") {
    if (typeof e == "string")
      return e;
    throw new Error(`!!! NLS MISSING: ${t} !!!`);
  }
  return n;
}
function r0(t, e, ...n) {
  let s;
  typeof t == "number" ? s = fn(t, e) : s = e;
  const i = _t(s, n);
  return {
    value: i,
    original: e === s ? i : _t(e, n)
  };
}
const Ke = "en";
let je = !1, ze = !1, Be = !1, hn = !1, c1 = !1, d1 = !1, pn = !1, nt, at = Ke, N1 = Ke, Gs, ue;
const de = globalThis;
let z;
typeof de.vscode < "u" && typeof de.vscode.process < "u" ? z = de.vscode.process : typeof process < "u" && typeof process?.versions?.node == "string" && (z = process);
const js = typeof z?.versions?.electron == "string", zs = js && z?.type === "renderer";
if (typeof z == "object") {
  je = z.platform === "win32", ze = z.platform === "darwin", Be = z.platform === "linux", Be && z.env.SNAP && z.env.SNAP_REVISION, z.env.CI || z.env.BUILD_ARTIFACTSTAGINGDIRECTORY || z.env.GITHUB_WORKSPACE, nt = Ke, at = Ke;
  const t = z.env.VSCODE_NLS_CONFIG;
  if (t)
    try {
      const e = JSON.parse(t);
      nt = e.userLocale, N1 = e.osLocale, at = e.resolvedLanguage || Ke, Gs = e.languagePack?.translationsConfigFile;
    } catch {
    }
  hn = !0;
} else typeof navigator == "object" && !zs ? (ue = navigator.userAgent, je = ue.indexOf("Windows") >= 0, ze = ue.indexOf("Macintosh") >= 0, d1 = (ue.indexOf("Macintosh") >= 0 || ue.indexOf("iPad") >= 0 || ue.indexOf("iPhone") >= 0) && !!navigator.maxTouchPoints && navigator.maxTouchPoints > 0, Be = ue.indexOf("Linux") >= 0, pn = ue?.indexOf("Mobi") >= 0, c1 = !0, at = dn() || Ke, nt = navigator.language.toLowerCase(), N1 = nt) : console.error("Unable to resolve platform.");
let ut = 0;
ze ? ut = 1 : je ? ut = 3 : Be && (ut = 2);
const Ne = je, pe = ze, Qs = Be, qt = hn, Ys = c1, Xs = c1 && typeof de.importScripts == "function", Zs = Xs ? de.origin : void 0, St = d1, o0 = pn, a0 = ut, ie = ue, u0 = at, Js = typeof de.postMessage == "function" && !de.importScripts, ei = (() => {
  if (Js) {
    const t = [];
    de.addEventListener("message", (n) => {
      if (n.data && n.data.vscodeScheduleAsyncWork)
        for (let s = 0, i = t.length; s < i; s++) {
          const r = t[s];
          if (r.id === n.data.vscodeScheduleAsyncWork) {
            t.splice(s, 1), r.callback();
            return;
          }
        }
    });
    let e = 0;
    return (n) => {
      const s = ++e;
      t.push({
        id: s,
        callback: n
      }), de.postMessage({ vscodeScheduleAsyncWork: s }, "*");
    };
  }
  return (t) => setTimeout(t);
})(), l0 = ze || d1 ? 2 : je ? 1 : 3;
let I1 = !0, F1 = !1;
function c0() {
  if (!F1) {
    F1 = !0;
    const t = new Uint8Array(2);
    t[0] = 1, t[1] = 2, I1 = new Uint16Array(t.buffer)[0] === 513;
  }
  return I1;
}
const ti = !!(ie && ie.indexOf("Chrome") >= 0), d0 = !!(ie && ie.indexOf("Firefox") >= 0), f0 = !!(!ti && ie && ie.indexOf("Safari") >= 0), h0 = !!(ie && ie.indexOf("Edg/") >= 0), p0 = !!(ie && ie.indexOf("Android") >= 0);
let ke;
const Lt = globalThis.vscode;
if (typeof Lt < "u" && typeof Lt.process < "u") {
  const t = Lt.process;
  ke = {
    get platform() {
      return t.platform;
    },
    get arch() {
      return t.arch;
    },
    get env() {
      return t.env;
    },
    cwd() {
      return t.cwd();
    }
  };
} else typeof process < "u" && typeof process?.versions?.node == "string" ? ke = {
  get platform() {
    return process.platform;
  },
  get arch() {
    return process.arch;
  },
  get env() {
    return process.env;
  },
  cwd() {
    return process.env.VSCODE_CWD || process.cwd();
  }
} : ke = {
  // Supported
  get platform() {
    return Ne ? "win32" : pe ? "darwin" : "linux";
  },
  get arch() {
  },
  // Unsupported
  get env() {
    return {};
  },
  cwd() {
    return "/";
  }
};
const yt = ke.cwd, Gt = ke.env, ni = ke.platform;
Gt && Gt.VSCODE_DEV_DEBUG_OBSERVABLES && ws(Re.getInstance());
function si(t, e) {
  const n = t;
  typeof n.vscodeWindowId != "number" && Object.defineProperty(n, "vscodeWindowId", {
    get: () => e
  });
}
const k = window;
class f1 {
  constructor() {
    this.mapWindowIdToZoomFactor = /* @__PURE__ */ new Map();
  }
  static {
    this.INSTANCE = new f1();
  }
  getZoomFactor(e) {
    return this.mapWindowIdToZoomFactor.get(this.getWindowId(e)) ?? 1;
  }
  getWindowId(e) {
    return e.vscodeWindowId;
  }
}
function ii(t, e, n) {
  typeof e == "string" && (e = t.matchMedia(e)), e.addEventListener("change", n);
}
function m0(t) {
  return f1.INSTANCE.getZoomFactor(t);
}
const Ie = navigator.userAgent, Qe = Ie.indexOf("Firefox") >= 0, mn = Ie.indexOf("AppleWebKit") >= 0, h1 = Ie.indexOf("Chrome") >= 0, _n = !h1 && Ie.indexOf("Safari") >= 0, _0 = !h1 && !_n && mn;
Ie.indexOf("Electron/") >= 0;
const y0 = Ie.indexOf("Android") >= 0;
let Nt = !1;
if (typeof k.matchMedia == "function") {
  const t = k.matchMedia("(display-mode: standalone) or (display-mode: window-controls-overlay)"), e = k.matchMedia("(display-mode: fullscreen)");
  Nt = t.matches, ii(k, t, ({ matches: n }) => {
    Nt && e.matches || (Nt = n);
  });
}
function g0() {
  return globalThis.MonacoEnvironment;
}
const p1 = {
  clipboard: {
    writeText: qt || document.queryCommandSupported && document.queryCommandSupported("copy") || !!(navigator && navigator.clipboard && navigator.clipboard.writeText),
    readText: qt || !!(navigator && navigator.clipboard && navigator.clipboard.readText)
  },
  pointerEvents: k.PointerEvent && ("ontouchstart" in k || navigator.maxTouchPoints > 0)
};
class m1 {
  constructor() {
    this._keyCodeToStr = [], this._strToKeyCode = /* @__PURE__ */ Object.create(null);
  }
  define(e, n) {
    this._keyCodeToStr[e] = n, this._strToKeyCode[n.toLowerCase()] = e;
  }
  keyCodeToStr(e) {
    return this._keyCodeToStr[e];
  }
  strToKeyCode(e) {
    return this._strToKeyCode[e.toLowerCase()] || 0;
  }
}
const lt = new m1(), jt = new m1(), zt = new m1(), yn = new Array(230), ri = /* @__PURE__ */ Object.create(null), oi = /* @__PURE__ */ Object.create(null), gn = [];
for (let t = 0; t <= 193; t++)
  gn[t] = -1;
(function() {
  const e = [
    // immutable, scanCode, scanCodeStr, keyCode, keyCodeStr, eventKeyCode, vkey, usUserSettingsLabel, generalUserSettingsLabel
    [1, 0, "None", 0, "unknown", 0, "VK_UNKNOWN", "", ""],
    [1, 1, "Hyper", 0, "", 0, "", "", ""],
    [1, 2, "Super", 0, "", 0, "", "", ""],
    [1, 3, "Fn", 0, "", 0, "", "", ""],
    [1, 4, "FnLock", 0, "", 0, "", "", ""],
    [1, 5, "Suspend", 0, "", 0, "", "", ""],
    [1, 6, "Resume", 0, "", 0, "", "", ""],
    [1, 7, "Turbo", 0, "", 0, "", "", ""],
    [1, 8, "Sleep", 0, "", 0, "VK_SLEEP", "", ""],
    [1, 9, "WakeUp", 0, "", 0, "", "", ""],
    [0, 10, "KeyA", 31, "A", 65, "VK_A", "", ""],
    [0, 11, "KeyB", 32, "B", 66, "VK_B", "", ""],
    [0, 12, "KeyC", 33, "C", 67, "VK_C", "", ""],
    [0, 13, "KeyD", 34, "D", 68, "VK_D", "", ""],
    [0, 14, "KeyE", 35, "E", 69, "VK_E", "", ""],
    [0, 15, "KeyF", 36, "F", 70, "VK_F", "", ""],
    [0, 16, "KeyG", 37, "G", 71, "VK_G", "", ""],
    [0, 17, "KeyH", 38, "H", 72, "VK_H", "", ""],
    [0, 18, "KeyI", 39, "I", 73, "VK_I", "", ""],
    [0, 19, "KeyJ", 40, "J", 74, "VK_J", "", ""],
    [0, 20, "KeyK", 41, "K", 75, "VK_K", "", ""],
    [0, 21, "KeyL", 42, "L", 76, "VK_L", "", ""],
    [0, 22, "KeyM", 43, "M", 77, "VK_M", "", ""],
    [0, 23, "KeyN", 44, "N", 78, "VK_N", "", ""],
    [0, 24, "KeyO", 45, "O", 79, "VK_O", "", ""],
    [0, 25, "KeyP", 46, "P", 80, "VK_P", "", ""],
    [0, 26, "KeyQ", 47, "Q", 81, "VK_Q", "", ""],
    [0, 27, "KeyR", 48, "R", 82, "VK_R", "", ""],
    [0, 28, "KeyS", 49, "S", 83, "VK_S", "", ""],
    [0, 29, "KeyT", 50, "T", 84, "VK_T", "", ""],
    [0, 30, "KeyU", 51, "U", 85, "VK_U", "", ""],
    [0, 31, "KeyV", 52, "V", 86, "VK_V", "", ""],
    [0, 32, "KeyW", 53, "W", 87, "VK_W", "", ""],
    [0, 33, "KeyX", 54, "X", 88, "VK_X", "", ""],
    [0, 34, "KeyY", 55, "Y", 89, "VK_Y", "", ""],
    [0, 35, "KeyZ", 56, "Z", 90, "VK_Z", "", ""],
    [0, 36, "Digit1", 22, "1", 49, "VK_1", "", ""],
    [0, 37, "Digit2", 23, "2", 50, "VK_2", "", ""],
    [0, 38, "Digit3", 24, "3", 51, "VK_3", "", ""],
    [0, 39, "Digit4", 25, "4", 52, "VK_4", "", ""],
    [0, 40, "Digit5", 26, "5", 53, "VK_5", "", ""],
    [0, 41, "Digit6", 27, "6", 54, "VK_6", "", ""],
    [0, 42, "Digit7", 28, "7", 55, "VK_7", "", ""],
    [0, 43, "Digit8", 29, "8", 56, "VK_8", "", ""],
    [0, 44, "Digit9", 30, "9", 57, "VK_9", "", ""],
    [0, 45, "Digit0", 21, "0", 48, "VK_0", "", ""],
    [1, 46, "Enter", 3, "Enter", 13, "VK_RETURN", "", ""],
    [1, 47, "Escape", 9, "Escape", 27, "VK_ESCAPE", "", ""],
    [1, 48, "Backspace", 1, "Backspace", 8, "VK_BACK", "", ""],
    [1, 49, "Tab", 2, "Tab", 9, "VK_TAB", "", ""],
    [1, 50, "Space", 10, "Space", 32, "VK_SPACE", "", ""],
    [0, 51, "Minus", 88, "-", 189, "VK_OEM_MINUS", "-", "OEM_MINUS"],
    [0, 52, "Equal", 86, "=", 187, "VK_OEM_PLUS", "=", "OEM_PLUS"],
    [0, 53, "BracketLeft", 92, "[", 219, "VK_OEM_4", "[", "OEM_4"],
    [0, 54, "BracketRight", 94, "]", 221, "VK_OEM_6", "]", "OEM_6"],
    [0, 55, "Backslash", 93, "\\", 220, "VK_OEM_5", "\\", "OEM_5"],
    [0, 56, "IntlHash", 0, "", 0, "", "", ""],
    // has been dropped from the w3c spec
    [0, 57, "Semicolon", 85, ";", 186, "VK_OEM_1", ";", "OEM_1"],
    [0, 58, "Quote", 95, "'", 222, "VK_OEM_7", "'", "OEM_7"],
    [0, 59, "Backquote", 91, "`", 192, "VK_OEM_3", "`", "OEM_3"],
    [0, 60, "Comma", 87, ",", 188, "VK_OEM_COMMA", ",", "OEM_COMMA"],
    [0, 61, "Period", 89, ".", 190, "VK_OEM_PERIOD", ".", "OEM_PERIOD"],
    [0, 62, "Slash", 90, "/", 191, "VK_OEM_2", "/", "OEM_2"],
    [1, 63, "CapsLock", 8, "CapsLock", 20, "VK_CAPITAL", "", ""],
    [1, 64, "F1", 59, "F1", 112, "VK_F1", "", ""],
    [1, 65, "F2", 60, "F2", 113, "VK_F2", "", ""],
    [1, 66, "F3", 61, "F3", 114, "VK_F3", "", ""],
    [1, 67, "F4", 62, "F4", 115, "VK_F4", "", ""],
    [1, 68, "F5", 63, "F5", 116, "VK_F5", "", ""],
    [1, 69, "F6", 64, "F6", 117, "VK_F6", "", ""],
    [1, 70, "F7", 65, "F7", 118, "VK_F7", "", ""],
    [1, 71, "F8", 66, "F8", 119, "VK_F8", "", ""],
    [1, 72, "F9", 67, "F9", 120, "VK_F9", "", ""],
    [1, 73, "F10", 68, "F10", 121, "VK_F10", "", ""],
    [1, 74, "F11", 69, "F11", 122, "VK_F11", "", ""],
    [1, 75, "F12", 70, "F12", 123, "VK_F12", "", ""],
    [1, 76, "PrintScreen", 0, "", 0, "", "", ""],
    [1, 77, "ScrollLock", 84, "ScrollLock", 145, "VK_SCROLL", "", ""],
    [1, 78, "Pause", 7, "PauseBreak", 19, "VK_PAUSE", "", ""],
    [1, 79, "Insert", 19, "Insert", 45, "VK_INSERT", "", ""],
    [1, 80, "Home", 14, "Home", 36, "VK_HOME", "", ""],
    [1, 81, "PageUp", 11, "PageUp", 33, "VK_PRIOR", "", ""],
    [1, 82, "Delete", 20, "Delete", 46, "VK_DELETE", "", ""],
    [1, 83, "End", 13, "End", 35, "VK_END", "", ""],
    [1, 84, "PageDown", 12, "PageDown", 34, "VK_NEXT", "", ""],
    [1, 85, "ArrowRight", 17, "RightArrow", 39, "VK_RIGHT", "Right", ""],
    [1, 86, "ArrowLeft", 15, "LeftArrow", 37, "VK_LEFT", "Left", ""],
    [1, 87, "ArrowDown", 18, "DownArrow", 40, "VK_DOWN", "Down", ""],
    [1, 88, "ArrowUp", 16, "UpArrow", 38, "VK_UP", "Up", ""],
    [1, 89, "NumLock", 83, "NumLock", 144, "VK_NUMLOCK", "", ""],
    [1, 90, "NumpadDivide", 113, "NumPad_Divide", 111, "VK_DIVIDE", "", ""],
    [1, 91, "NumpadMultiply", 108, "NumPad_Multiply", 106, "VK_MULTIPLY", "", ""],
    [1, 92, "NumpadSubtract", 111, "NumPad_Subtract", 109, "VK_SUBTRACT", "", ""],
    [1, 93, "NumpadAdd", 109, "NumPad_Add", 107, "VK_ADD", "", ""],
    [1, 94, "NumpadEnter", 3, "", 0, "", "", ""],
    [1, 95, "Numpad1", 99, "NumPad1", 97, "VK_NUMPAD1", "", ""],
    [1, 96, "Numpad2", 100, "NumPad2", 98, "VK_NUMPAD2", "", ""],
    [1, 97, "Numpad3", 101, "NumPad3", 99, "VK_NUMPAD3", "", ""],
    [1, 98, "Numpad4", 102, "NumPad4", 100, "VK_NUMPAD4", "", ""],
    [1, 99, "Numpad5", 103, "NumPad5", 101, "VK_NUMPAD5", "", ""],
    [1, 100, "Numpad6", 104, "NumPad6", 102, "VK_NUMPAD6", "", ""],
    [1, 101, "Numpad7", 105, "NumPad7", 103, "VK_NUMPAD7", "", ""],
    [1, 102, "Numpad8", 106, "NumPad8", 104, "VK_NUMPAD8", "", ""],
    [1, 103, "Numpad9", 107, "NumPad9", 105, "VK_NUMPAD9", "", ""],
    [1, 104, "Numpad0", 98, "NumPad0", 96, "VK_NUMPAD0", "", ""],
    [1, 105, "NumpadDecimal", 112, "NumPad_Decimal", 110, "VK_DECIMAL", "", ""],
    [0, 106, "IntlBackslash", 97, "OEM_102", 226, "VK_OEM_102", "", ""],
    [1, 107, "ContextMenu", 58, "ContextMenu", 93, "", "", ""],
    [1, 108, "Power", 0, "", 0, "", "", ""],
    [1, 109, "NumpadEqual", 0, "", 0, "", "", ""],
    [1, 110, "F13", 71, "F13", 124, "VK_F13", "", ""],
    [1, 111, "F14", 72, "F14", 125, "VK_F14", "", ""],
    [1, 112, "F15", 73, "F15", 126, "VK_F15", "", ""],
    [1, 113, "F16", 74, "F16", 127, "VK_F16", "", ""],
    [1, 114, "F17", 75, "F17", 128, "VK_F17", "", ""],
    [1, 115, "F18", 76, "F18", 129, "VK_F18", "", ""],
    [1, 116, "F19", 77, "F19", 130, "VK_F19", "", ""],
    [1, 117, "F20", 78, "F20", 131, "VK_F20", "", ""],
    [1, 118, "F21", 79, "F21", 132, "VK_F21", "", ""],
    [1, 119, "F22", 80, "F22", 133, "VK_F22", "", ""],
    [1, 120, "F23", 81, "F23", 134, "VK_F23", "", ""],
    [1, 121, "F24", 82, "F24", 135, "VK_F24", "", ""],
    [1, 122, "Open", 0, "", 0, "", "", ""],
    [1, 123, "Help", 0, "", 0, "", "", ""],
    [1, 124, "Select", 0, "", 0, "", "", ""],
    [1, 125, "Again", 0, "", 0, "", "", ""],
    [1, 126, "Undo", 0, "", 0, "", "", ""],
    [1, 127, "Cut", 0, "", 0, "", "", ""],
    [1, 128, "Copy", 0, "", 0, "", "", ""],
    [1, 129, "Paste", 0, "", 0, "", "", ""],
    [1, 130, "Find", 0, "", 0, "", "", ""],
    [1, 131, "AudioVolumeMute", 117, "AudioVolumeMute", 173, "VK_VOLUME_MUTE", "", ""],
    [1, 132, "AudioVolumeUp", 118, "AudioVolumeUp", 175, "VK_VOLUME_UP", "", ""],
    [1, 133, "AudioVolumeDown", 119, "AudioVolumeDown", 174, "VK_VOLUME_DOWN", "", ""],
    [1, 134, "NumpadComma", 110, "NumPad_Separator", 108, "VK_SEPARATOR", "", ""],
    [0, 135, "IntlRo", 115, "ABNT_C1", 193, "VK_ABNT_C1", "", ""],
    [1, 136, "KanaMode", 0, "", 0, "", "", ""],
    [0, 137, "IntlYen", 0, "", 0, "", "", ""],
    [1, 138, "Convert", 0, "", 0, "", "", ""],
    [1, 139, "NonConvert", 0, "", 0, "", "", ""],
    [1, 140, "Lang1", 0, "", 0, "", "", ""],
    [1, 141, "Lang2", 0, "", 0, "", "", ""],
    [1, 142, "Lang3", 0, "", 0, "", "", ""],
    [1, 143, "Lang4", 0, "", 0, "", "", ""],
    [1, 144, "Lang5", 0, "", 0, "", "", ""],
    [1, 145, "Abort", 0, "", 0, "", "", ""],
    [1, 146, "Props", 0, "", 0, "", "", ""],
    [1, 147, "NumpadParenLeft", 0, "", 0, "", "", ""],
    [1, 148, "NumpadParenRight", 0, "", 0, "", "", ""],
    [1, 149, "NumpadBackspace", 0, "", 0, "", "", ""],
    [1, 150, "NumpadMemoryStore", 0, "", 0, "", "", ""],
    [1, 151, "NumpadMemoryRecall", 0, "", 0, "", "", ""],
    [1, 152, "NumpadMemoryClear", 0, "", 0, "", "", ""],
    [1, 153, "NumpadMemoryAdd", 0, "", 0, "", "", ""],
    [1, 154, "NumpadMemorySubtract", 0, "", 0, "", "", ""],
    [1, 155, "NumpadClear", 131, "Clear", 12, "VK_CLEAR", "", ""],
    [1, 156, "NumpadClearEntry", 0, "", 0, "", "", ""],
    [1, 0, "", 5, "Ctrl", 17, "VK_CONTROL", "", ""],
    [1, 0, "", 4, "Shift", 16, "VK_SHIFT", "", ""],
    [1, 0, "", 6, "Alt", 18, "VK_MENU", "", ""],
    [1, 0, "", 57, "Meta", 91, "VK_COMMAND", "", ""],
    [1, 157, "ControlLeft", 5, "", 0, "VK_LCONTROL", "", ""],
    [1, 158, "ShiftLeft", 4, "", 0, "VK_LSHIFT", "", ""],
    [1, 159, "AltLeft", 6, "", 0, "VK_LMENU", "", ""],
    [1, 160, "MetaLeft", 57, "", 0, "VK_LWIN", "", ""],
    [1, 161, "ControlRight", 5, "", 0, "VK_RCONTROL", "", ""],
    [1, 162, "ShiftRight", 4, "", 0, "VK_RSHIFT", "", ""],
    [1, 163, "AltRight", 6, "", 0, "VK_RMENU", "", ""],
    [1, 164, "MetaRight", 57, "", 0, "VK_RWIN", "", ""],
    [1, 165, "BrightnessUp", 0, "", 0, "", "", ""],
    [1, 166, "BrightnessDown", 0, "", 0, "", "", ""],
    [1, 167, "MediaPlay", 0, "", 0, "", "", ""],
    [1, 168, "MediaRecord", 0, "", 0, "", "", ""],
    [1, 169, "MediaFastForward", 0, "", 0, "", "", ""],
    [1, 170, "MediaRewind", 0, "", 0, "", "", ""],
    [1, 171, "MediaTrackNext", 124, "MediaTrackNext", 176, "VK_MEDIA_NEXT_TRACK", "", ""],
    [1, 172, "MediaTrackPrevious", 125, "MediaTrackPrevious", 177, "VK_MEDIA_PREV_TRACK", "", ""],
    [1, 173, "MediaStop", 126, "MediaStop", 178, "VK_MEDIA_STOP", "", ""],
    [1, 174, "Eject", 0, "", 0, "", "", ""],
    [1, 175, "MediaPlayPause", 127, "MediaPlayPause", 179, "VK_MEDIA_PLAY_PAUSE", "", ""],
    [1, 176, "MediaSelect", 128, "LaunchMediaPlayer", 181, "VK_MEDIA_LAUNCH_MEDIA_SELECT", "", ""],
    [1, 177, "LaunchMail", 129, "LaunchMail", 180, "VK_MEDIA_LAUNCH_MAIL", "", ""],
    [1, 178, "LaunchApp2", 130, "LaunchApp2", 183, "VK_MEDIA_LAUNCH_APP2", "", ""],
    [1, 179, "LaunchApp1", 0, "", 0, "VK_MEDIA_LAUNCH_APP1", "", ""],
    [1, 180, "SelectTask", 0, "", 0, "", "", ""],
    [1, 181, "LaunchScreenSaver", 0, "", 0, "", "", ""],
    [1, 182, "BrowserSearch", 120, "BrowserSearch", 170, "VK_BROWSER_SEARCH", "", ""],
    [1, 183, "BrowserHome", 121, "BrowserHome", 172, "VK_BROWSER_HOME", "", ""],
    [1, 184, "BrowserBack", 122, "BrowserBack", 166, "VK_BROWSER_BACK", "", ""],
    [1, 185, "BrowserForward", 123, "BrowserForward", 167, "VK_BROWSER_FORWARD", "", ""],
    [1, 186, "BrowserStop", 0, "", 0, "VK_BROWSER_STOP", "", ""],
    [1, 187, "BrowserRefresh", 0, "", 0, "VK_BROWSER_REFRESH", "", ""],
    [1, 188, "BrowserFavorites", 0, "", 0, "VK_BROWSER_FAVORITES", "", ""],
    [1, 189, "ZoomToggle", 0, "", 0, "", "", ""],
    [1, 190, "MailReply", 0, "", 0, "", "", ""],
    [1, 191, "MailForward", 0, "", 0, "", "", ""],
    [1, 192, "MailSend", 0, "", 0, "", "", ""],
    // See https://lists.w3.org/Archives/Public/www-dom/2010JulSep/att-0182/keyCode-spec.html
    // If an Input Method Editor is processing key input and the event is keydown, return 229.
    [1, 0, "", 114, "KeyInComposition", 229, "", "", ""],
    [1, 0, "", 116, "ABNT_C2", 194, "VK_ABNT_C2", "", ""],
    [1, 0, "", 96, "OEM_8", 223, "VK_OEM_8", "", ""],
    [1, 0, "", 0, "", 0, "VK_KANA", "", ""],
    [1, 0, "", 0, "", 0, "VK_HANGUL", "", ""],
    [1, 0, "", 0, "", 0, "VK_JUNJA", "", ""],
    [1, 0, "", 0, "", 0, "VK_FINAL", "", ""],
    [1, 0, "", 0, "", 0, "VK_HANJA", "", ""],
    [1, 0, "", 0, "", 0, "VK_KANJI", "", ""],
    [1, 0, "", 0, "", 0, "VK_CONVERT", "", ""],
    [1, 0, "", 0, "", 0, "VK_NONCONVERT", "", ""],
    [1, 0, "", 0, "", 0, "VK_ACCEPT", "", ""],
    [1, 0, "", 0, "", 0, "VK_MODECHANGE", "", ""],
    [1, 0, "", 0, "", 0, "VK_SELECT", "", ""],
    [1, 0, "", 0, "", 0, "VK_PRINT", "", ""],
    [1, 0, "", 0, "", 0, "VK_EXECUTE", "", ""],
    [1, 0, "", 0, "", 0, "VK_SNAPSHOT", "", ""],
    [1, 0, "", 0, "", 0, "VK_HELP", "", ""],
    [1, 0, "", 0, "", 0, "VK_APPS", "", ""],
    [1, 0, "", 0, "", 0, "VK_PROCESSKEY", "", ""],
    [1, 0, "", 0, "", 0, "VK_PACKET", "", ""],
    [1, 0, "", 0, "", 0, "VK_DBE_SBCSCHAR", "", ""],
    [1, 0, "", 0, "", 0, "VK_DBE_DBCSCHAR", "", ""],
    [1, 0, "", 0, "", 0, "VK_ATTN", "", ""],
    [1, 0, "", 0, "", 0, "VK_CRSEL", "", ""],
    [1, 0, "", 0, "", 0, "VK_EXSEL", "", ""],
    [1, 0, "", 0, "", 0, "VK_EREOF", "", ""],
    [1, 0, "", 0, "", 0, "VK_PLAY", "", ""],
    [1, 0, "", 0, "", 0, "VK_ZOOM", "", ""],
    [1, 0, "", 0, "", 0, "VK_NONAME", "", ""],
    [1, 0, "", 0, "", 0, "VK_PA1", "", ""],
    [1, 0, "", 0, "", 0, "VK_OEM_CLEAR", "", ""]
  ], n = [], s = [];
  for (const i of e) {
    const [r, o, a, u, l, d, c, p, O] = i;
    if (s[o] || (s[o] = !0, ri[a] = o, oi[a.toLowerCase()] = o, r && (gn[o] = u)), !n[u]) {
      if (n[u] = !0, !l)
        throw new Error(`String representation missing for key code ${u} around scan code ${a}`);
      lt.define(u, l), jt.define(u, p || l), zt.define(u, O || p || l);
    }
    d && (yn[d] = u);
  }
})();
var Qt;
(function(t) {
  function e(a) {
    return lt.keyCodeToStr(a);
  }
  t.toString = e;
  function n(a) {
    return lt.strToKeyCode(a);
  }
  t.fromString = n;
  function s(a) {
    return jt.keyCodeToStr(a);
  }
  t.toUserSettingsUS = s;
  function i(a) {
    return zt.keyCodeToStr(a);
  }
  t.toUserSettingsGeneral = i;
  function r(a) {
    return jt.strToKeyCode(a) || zt.strToKeyCode(a);
  }
  t.fromUserSettings = r;
  function o(a) {
    if (a >= 98 && a <= 113)
      return null;
    switch (a) {
      case 16:
        return "Up";
      case 18:
        return "Down";
      case 15:
        return "Left";
      case 17:
        return "Right";
    }
    return lt.keyCodeToStr(a);
  }
  t.toElectronAccelerator = o;
})(Qt || (Qt = {}));
function b0(t, e) {
  const n = (e & 65535) << 16 >>> 0;
  return (t | n) >>> 0;
}
function C0(t, e) {
  if (typeof t == "number") {
    if (t === 0)
      return null;
    const n = (t & 65535) >>> 0, s = (t & 4294901760) >>> 16;
    return s !== 0 ? new It([
      st(n, e),
      st(s, e)
    ]) : new It([st(n, e)]);
  } else {
    const n = [];
    for (let s = 0; s < t.length; s++)
      n.push(st(t[s], e));
    return new It(n);
  }
}
function st(t, e) {
  const n = !!(t & 2048), s = !!(t & 256), i = e === 2 ? s : n, r = !!(t & 1024), o = !!(t & 512), a = e === 2 ? n : s, u = t & 255;
  return new Dt(i, r, o, a, u);
}
class Dt {
  constructor(e, n, s, i, r) {
    this.ctrlKey = e, this.shiftKey = n, this.altKey = s, this.metaKey = i, this.keyCode = r;
  }
  equals(e) {
    return e instanceof Dt && this.ctrlKey === e.ctrlKey && this.shiftKey === e.shiftKey && this.altKey === e.altKey && this.metaKey === e.metaKey && this.keyCode === e.keyCode;
  }
  isModifierKey() {
    return this.keyCode === 0 || this.keyCode === 5 || this.keyCode === 57 || this.keyCode === 6 || this.keyCode === 4;
  }
  /**
   * Does this keybinding refer to the key code of a modifier and it also has the modifier flag?
   */
  isDuplicateModifierCase() {
    return this.ctrlKey && this.keyCode === 5 || this.shiftKey && this.keyCode === 4 || this.altKey && this.keyCode === 6 || this.metaKey && this.keyCode === 57;
  }
}
class It {
  constructor(e) {
    if (e.length === 0)
      throw es("chords");
    this.chords = e;
  }
}
class v0 {
  constructor(e, n, s, i, r, o) {
    this.ctrlKey = e, this.shiftKey = n, this.altKey = s, this.metaKey = i, this.keyLabel = r, this.keyAriaLabel = o;
  }
}
class w0 {
}
function ai(t) {
  if (t.charCode) {
    const n = String.fromCharCode(t.charCode).toUpperCase();
    return Qt.fromString(n);
  }
  const e = t.keyCode;
  if (e === 3)
    return 7;
  if (Qe)
    switch (e) {
      case 59:
        return 85;
      case 60:
        if (Qs)
          return 97;
        break;
      case 61:
        return 86;
      // based on: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/keyCode#numpad_keys
      case 107:
        return 109;
      case 109:
        return 111;
      case 173:
        return 88;
      case 224:
        if (pe)
          return 57;
        break;
    }
  else if (mn) {
    if (pe && e === 93)
      return 57;
    if (!pe && e === 92)
      return 57;
  }
  return yn[e] || 0;
}
const ui = pe ? 256 : 2048, li = 512, ci = 1024, di = pe ? 2048 : 256;
class bn {
  constructor(e) {
    this._standardKeyboardEventBrand = !0;
    const n = e;
    this.browserEvent = n, this.target = n.target, this.ctrlKey = n.ctrlKey, this.shiftKey = n.shiftKey, this.altKey = n.altKey, this.metaKey = n.metaKey, this.altGraphKey = n.getModifierState?.("AltGraph"), this.keyCode = ai(n), this.code = n.code, this.ctrlKey = this.ctrlKey || this.keyCode === 5, this.altKey = this.altKey || this.keyCode === 6, this.shiftKey = this.shiftKey || this.keyCode === 4, this.metaKey = this.metaKey || this.keyCode === 57, this._asKeybinding = this._computeKeybinding(), this._asKeyCodeChord = this._computeKeyCodeChord();
  }
  preventDefault() {
    this.browserEvent && this.browserEvent.preventDefault && this.browserEvent.preventDefault();
  }
  stopPropagation() {
    this.browserEvent && this.browserEvent.stopPropagation && this.browserEvent.stopPropagation();
  }
  toKeyCodeChord() {
    return this._asKeyCodeChord;
  }
  equals(e) {
    return this._asKeybinding === e;
  }
  _computeKeybinding() {
    let e = 0;
    this.keyCode !== 5 && this.keyCode !== 4 && this.keyCode !== 6 && this.keyCode !== 57 && (e = this.keyCode);
    let n = 0;
    return this.ctrlKey && (n |= ui), this.altKey && (n |= li), this.shiftKey && (n |= ci), this.metaKey && (n |= di), n |= e, n;
  }
  _computeKeyCodeChord() {
    let e = 0;
    return this.keyCode !== 5 && this.keyCode !== 4 && this.keyCode !== 6 && this.keyCode !== 57 && (e = this.keyCode), new Dt(this.ctrlKey, this.shiftKey, this.altKey, this.metaKey, e);
  }
}
const M1 = /* @__PURE__ */ new WeakMap();
function fi(t) {
  if (!t.parent || t.parent === t)
    return null;
  try {
    const e = t.location, n = t.parent.location;
    if (e.origin !== "null" && n.origin !== "null" && e.origin !== n.origin)
      return null;
  } catch {
    return null;
  }
  return t.parent;
}
class hi {
  /**
   * Returns a chain of embedded windows with the same origin (which can be accessed programmatically).
   * Having a chain of length 1 might mean that the current execution environment is running outside of an iframe or inside an iframe embedded in a window with a different origin.
   */
  static getSameOriginWindowChain(e) {
    let n = M1.get(e);
    if (!n) {
      n = [], M1.set(e, n);
      let s = e, i;
      do
        i = fi(s), i ? n.push({
          window: new WeakRef(s),
          iframeElement: s.frameElement || null
        }) : n.push({
          window: new WeakRef(s),
          iframeElement: null
        }), s = i;
      while (s);
    }
    return n.slice(0);
  }
  /**
   * Returns the position of `childWindow` relative to `ancestorWindow`
   */
  static getPositionOfChildWindowRelativeToAncestorWindow(e, n) {
    if (!n || e === n)
      return {
        top: 0,
        left: 0
      };
    let s = 0, i = 0;
    const r = this.getSameOriginWindowChain(e);
    for (const o of r) {
      const a = o.window.deref();
      if (s += a?.scrollY ?? 0, i += a?.scrollX ?? 0, a === n || !o.iframeElement)
        break;
      const u = o.iframeElement.getBoundingClientRect();
      s += u.top, i += u.left;
    }
    return {
      top: s,
      left: i
    };
  }
}
class pi {
  constructor(e, n) {
    this.timestamp = Date.now(), this.browserEvent = n, this.leftButton = n.button === 0, this.middleButton = n.button === 1, this.rightButton = n.button === 2, this.buttons = n.buttons, this.defaultPrevented = n.defaultPrevented, this.target = n.target, this.detail = n.detail || 1, n.type === "dblclick" && (this.detail = 2), this.ctrlKey = n.ctrlKey, this.shiftKey = n.shiftKey, this.altKey = n.altKey, this.metaKey = n.metaKey, typeof n.pageX == "number" ? (this.posx = n.pageX, this.posy = n.pageY) : (this.posx = n.clientX + this.target.ownerDocument.body.scrollLeft + this.target.ownerDocument.documentElement.scrollLeft, this.posy = n.clientY + this.target.ownerDocument.body.scrollTop + this.target.ownerDocument.documentElement.scrollTop);
    const s = hi.getPositionOfChildWindowRelativeToAncestorWindow(e, n.view);
    this.posx -= s.left, this.posy -= s.top;
  }
  preventDefault() {
    this.browserEvent.preventDefault();
  }
  stopPropagation() {
    this.browserEvent.stopPropagation();
  }
}
class E0 {
  constructor(e, n = 0, s = 0) {
    this.browserEvent = e || null, this.target = e ? e.target || e.targetNode || e.srcElement : null, this.deltaY = s, this.deltaX = n;
    let i = !1;
    if (h1) {
      const r = navigator.userAgent.match(/Chrome\/(\d+)/);
      i = (r ? parseInt(r[1]) : 123) <= 122;
    }
    if (e) {
      const r = e, o = e, a = e.view?.devicePixelRatio || 1;
      if (typeof r.wheelDeltaY < "u")
        i ? this.deltaY = r.wheelDeltaY / (120 * a) : this.deltaY = r.wheelDeltaY / 120;
      else if (typeof o.VERTICAL_AXIS < "u" && o.axis === o.VERTICAL_AXIS)
        this.deltaY = -o.detail / 3;
      else if (e.type === "wheel") {
        const u = e;
        u.deltaMode === u.DOM_DELTA_LINE ? Qe && !pe ? this.deltaY = -e.deltaY / 3 : this.deltaY = -e.deltaY : this.deltaY = -e.deltaY / 40;
      }
      if (typeof r.wheelDeltaX < "u")
        _n && Ne ? this.deltaX = -(r.wheelDeltaX / 120) : i ? this.deltaX = r.wheelDeltaX / (120 * a) : this.deltaX = r.wheelDeltaX / 120;
      else if (typeof o.HORIZONTAL_AXIS < "u" && o.axis === o.HORIZONTAL_AXIS)
        this.deltaX = -e.detail / 3;
      else if (e.type === "wheel") {
        const u = e;
        u.deltaMode === u.DOM_DELTA_LINE ? Qe && !pe ? this.deltaX = -e.deltaX / 3 : this.deltaX = -e.deltaX : this.deltaX = -e.deltaX / 40;
      }
      this.deltaY === 0 && this.deltaX === 0 && e.wheelDelta && (i ? this.deltaY = e.wheelDelta / (120 * a) : this.deltaY = e.wheelDelta / 120);
    }
  }
  preventDefault() {
    this.browserEvent?.preventDefault();
  }
  stopPropagation() {
    this.browserEvent?.stopPropagation();
  }
}
const mi = Symbol("MicrotaskDelay");
function A0(t) {
  return !!t && typeof t.then == "function";
}
function _i(t) {
  const e = new Et(), n = t(e.token);
  let s = !1;
  const i = new Promise((r, o) => {
    const a = e.token.onCancellationRequested(() => {
      s = !0, a.dispose(), o(new ye());
    });
    Promise.resolve(n).then((u) => {
      a.dispose(), e.dispose(), s ? as(u) && u.dispose() : r(u);
    }, (u) => {
      a.dispose(), e.dispose(), o(u);
    });
  });
  return new class {
    cancel() {
      e.cancel(), e.dispose();
    }
    then(r, o) {
      return i.then(r, o);
    }
    catch(r) {
      return this.then(void 0, r);
    }
    finally(r) {
      return i.finally(r);
    }
  }();
}
function S0(t, e, n) {
  return new Promise((s, i) => {
    const r = e.onCancellationRequested(() => {
      r.dispose(), s(n);
    });
    t.then(s, i).finally(() => r.dispose());
  });
}
function D0(t, e) {
  return new Promise((n, s) => {
    const i = e.onCancellationRequested(() => {
      i.dispose(), s(new ye());
    });
    t.then(n, s).finally(() => i.dispose());
  });
}
class yi {
  constructor() {
    this.activePromise = null, this.queuedPromise = null, this.queuedPromiseFactory = null, this.cancellationTokenSource = new Et();
  }
  queue(e) {
    if (this.cancellationTokenSource.token.isCancellationRequested)
      return Promise.reject(new Error("Throttler is disposed"));
    if (this.activePromise) {
      if (this.queuedPromiseFactory = e, !this.queuedPromise) {
        const n = () => {
          if (this.queuedPromise = null, this.cancellationTokenSource.token.isCancellationRequested)
            return;
          const s = this.queue(this.queuedPromiseFactory);
          return this.queuedPromiseFactory = null, s;
        };
        this.queuedPromise = new Promise((s) => {
          this.activePromise.then(n, n).then(s);
        });
      }
      return new Promise((n, s) => {
        this.queuedPromise.then(n, s);
      });
    }
    return this.activePromise = e(this.cancellationTokenSource.token), new Promise((n, s) => {
      this.activePromise.then((i) => {
        this.activePromise = null, n(i);
      }, (i) => {
        this.activePromise = null, s(i);
      });
    });
  }
  dispose() {
    this.cancellationTokenSource.cancel();
  }
}
const gi = (t, e) => {
  let n = !0;
  const s = setTimeout(() => {
    n = !1, e();
  }, t);
  return {
    isTriggered: () => n,
    dispose: () => {
      clearTimeout(s), n = !1;
    }
  };
}, bi = (t) => {
  let e = !0;
  return queueMicrotask(() => {
    e && (e = !1, t());
  }), {
    isTriggered: () => e,
    dispose: () => {
      e = !1;
    }
  };
};
class Ci {
  constructor(e) {
    this.defaultDelay = e, this.deferred = null, this.completionPromise = null, this.doResolve = null, this.doReject = null, this.task = null;
  }
  trigger(e, n = this.defaultDelay) {
    this.task = e, this.cancelTimeout(), this.completionPromise || (this.completionPromise = new Promise((i, r) => {
      this.doResolve = i, this.doReject = r;
    }).then(() => {
      if (this.completionPromise = null, this.doResolve = null, this.task) {
        const i = this.task;
        return this.task = null, i();
      }
    }));
    const s = () => {
      this.deferred = null, this.doResolve?.(null);
    };
    return this.deferred = n === mi ? bi(s) : gi(n, s), this.completionPromise;
  }
  isTriggered() {
    return !!this.deferred?.isTriggered();
  }
  cancel() {
    this.cancelTimeout(), this.completionPromise && (this.doReject?.(new ye()), this.completionPromise = null);
  }
  cancelTimeout() {
    this.deferred?.dispose(), this.deferred = null;
  }
  dispose() {
    this.cancel();
  }
}
class O0 {
  constructor(e) {
    this.delayer = new Ci(e), this.throttler = new yi();
  }
  trigger(e, n) {
    return this.delayer.trigger(() => this.throttler.queue(e), n);
  }
  cancel() {
    this.delayer.cancel();
  }
  dispose() {
    this.delayer.dispose(), this.throttler.dispose();
  }
}
function vi(t, e) {
  return e ? new Promise((n, s) => {
    const i = setTimeout(() => {
      r.dispose(), n();
    }, t), r = e.onCancellationRequested(() => {
      clearTimeout(i), r.dispose(), s(new ye());
    });
  }) : _i((n) => vi(t, n));
}
function T0(t, e = 0, n) {
  const s = setTimeout(() => {
    t(), n && i.dispose();
  }, e), i = q(() => {
    clearTimeout(s), n?.delete(i);
  });
  return n?.add(i), i;
}
function R0(t, e = (s) => !!s, n = null) {
  let s = 0;
  const i = t.length, r = () => {
    if (s >= i)
      return Promise.resolve(n);
    const o = t[s++];
    return Promise.resolve(o()).then((u) => e(u) ? Promise.resolve(u) : r());
  };
  return r();
}
class K0 {
  constructor() {
    this._runningTask = void 0, this._pendingTasks = [];
  }
  /**
   * Waits for the current and pending tasks to finish, then runs and awaits the given task.
   * If the task is skipped because of clearPending, the promise is rejected with a CancellationError.
  */
  schedule(e) {
    const n = new vn();
    return this._pendingTasks.push({ task: e, deferred: n, setUndefinedWhenCleared: !1 }), this._runIfNotRunning(), n.p;
  }
  _runIfNotRunning() {
    this._runningTask === void 0 && this._processQueue();
  }
  async _processQueue() {
    if (this._pendingTasks.length === 0)
      return;
    const e = this._pendingTasks.shift();
    if (e) {
      if (this._runningTask)
        throw new K();
      this._runningTask = e.task;
      try {
        const n = await e.task();
        e.deferred.complete(n);
      } catch (n) {
        e.deferred.error(n);
      } finally {
        this._runningTask = void 0, this._processQueue();
      }
    }
  }
  /**
   * Clears all pending tasks. Does not cancel the currently running task.
  */
  clearPending() {
    const e = this._pendingTasks;
    this._pendingTasks = [];
    for (const n of e)
      n.setUndefinedWhenCleared ? n.deferred.complete(void 0) : n.deferred.error(new ye());
  }
}
class k0 {
  constructor(e, n) {
    this._isDisposed = !1, this._token = void 0, typeof e == "function" && typeof n == "number" && this.setIfNotSet(e, n);
  }
  dispose() {
    this.cancel(), this._isDisposed = !0;
  }
  cancel() {
    this._token !== void 0 && (clearTimeout(this._token), this._token = void 0);
  }
  cancelAndSet(e, n) {
    if (this._isDisposed)
      throw new K("Calling 'cancelAndSet' on a disposed TimeoutTimer");
    this.cancel(), this._token = setTimeout(() => {
      this._token = void 0, e();
    }, n);
  }
  setIfNotSet(e, n) {
    if (this._isDisposed)
      throw new K("Calling 'setIfNotSet' on a disposed TimeoutTimer");
    this._token === void 0 && (this._token = setTimeout(() => {
      this._token = void 0, e();
    }, n));
  }
}
class wi {
  constructor() {
    this.disposable = void 0, this.isDisposed = !1;
  }
  cancel() {
    this.disposable?.dispose(), this.disposable = void 0;
  }
  cancelAndSet(e, n, s = globalThis) {
    if (this.isDisposed)
      throw new K("Calling 'cancelAndSet' on a disposed IntervalTimer");
    this.cancel();
    const i = s.setInterval(() => {
      e();
    }, n);
    this.disposable = q(() => {
      s.clearInterval(i), this.disposable = void 0;
    });
  }
  dispose() {
    this.cancel(), this.isDisposed = !0;
  }
}
class L0 {
  constructor(e, n) {
    this.timeoutToken = void 0, this.runner = e, this.timeout = n, this.timeoutHandler = this.onTimeout.bind(this);
  }
  /**
   * Dispose RunOnceScheduler
   */
  dispose() {
    this.cancel(), this.runner = null;
  }
  /**
   * Cancel current scheduled runner (if any).
   */
  cancel() {
    this.isScheduled() && (clearTimeout(this.timeoutToken), this.timeoutToken = void 0);
  }
  /**
   * Cancel previous runner (if any) & schedule a new runner.
   */
  schedule(e = this.timeout) {
    this.cancel(), this.timeoutToken = setTimeout(this.timeoutHandler, e);
  }
  get delay() {
    return this.timeout;
  }
  set delay(e) {
    this.timeout = e;
  }
  /**
   * Returns true if scheduled.
   */
  isScheduled() {
    return this.timeoutToken !== void 0;
  }
  onTimeout() {
    this.timeoutToken = void 0, this.runner && this.doRun();
  }
  doRun() {
    this.runner?.();
  }
}
let Ei, We;
(function() {
  const t = globalThis;
  typeof t.requestIdleCallback != "function" || typeof t.cancelIdleCallback != "function" ? We = (e, n, s) => {
    ei(() => {
      if (i)
        return;
      const r = Date.now() + 15;
      n(Object.freeze({
        didTimeout: !0,
        timeRemaining() {
          return Math.max(0, r - Date.now());
        }
      }));
    });
    let i = !1;
    return {
      dispose() {
        i || (i = !0);
      }
    };
  } : We = (e, n, s) => {
    const i = e.requestIdleCallback(n, typeof s == "number" ? { timeout: s } : void 0);
    let r = !1;
    return {
      dispose() {
        r || (r = !0, e.cancelIdleCallback(i));
      }
    };
  }, Ei = (e, n) => We(globalThis, e, n);
})();
class Cn {
  constructor(e, n) {
    this._didRun = !1, this._executor = () => {
      try {
        this._value = n();
      } catch (s) {
        this._error = s;
      } finally {
        this._didRun = !0;
      }
    }, this._handle = We(e, () => this._executor());
  }
  dispose() {
    this._handle.dispose();
  }
  get value() {
    if (this._didRun || (this._handle.dispose(), this._executor()), this._error)
      throw this._error;
    return this._value;
  }
  get isInitialized() {
    return this._didRun;
  }
}
class N0 extends Cn {
  constructor(e) {
    super(globalThis, e);
  }
}
class vn {
  get isRejected() {
    return this.outcome?.outcome === 1;
  }
  get isSettled() {
    return !!this.outcome;
  }
  constructor() {
    this.p = new Promise((e, n) => {
      this.completeCallback = e, this.errorCallback = n;
    });
  }
  complete(e) {
    return this.isSettled ? Promise.resolve() : new Promise((n) => {
      this.completeCallback(e), this.outcome = { outcome: 0, value: e }, n();
    });
  }
  error(e) {
    return this.isSettled ? Promise.resolve() : new Promise((n) => {
      this.errorCallback(e), this.outcome = { outcome: 1, value: e }, n();
    });
  }
  cancel() {
    return this.error(new ye());
  }
}
var P1;
(function(t) {
  async function e(s) {
    let i;
    const r = await Promise.all(s.map((o) => o.then((a) => a, (a) => {
      i || (i = a);
    })));
    if (typeof i < "u")
      throw i;
    return r;
  }
  t.settled = e;
  function n(s) {
    return new Promise(async (i, r) => {
      try {
        await s(i, r);
      } catch (o) {
        r(o);
      }
    });
  }
  t.withAsyncBody = n;
})(P1 || (P1 = {}));
function I0(t) {
  const e = new Et(), n = t(e.token);
  return new Si(e, async (s) => {
    const i = e.token.onCancellationRequested(() => {
      i.dispose(), e.dispose(), s.reject(new ye());
    });
    try {
      for await (const r of n) {
        if (e.token.isCancellationRequested)
          return;
        s.emitOne(r);
      }
      i.dispose(), e.dispose();
    } catch (r) {
      i.dispose(), e.dispose(), s.reject(r);
    }
  });
}
class Ai {
  constructor() {
    this._unsatisfiedConsumers = [], this._unconsumedValues = [];
  }
  get hasFinalValue() {
    return !!this._finalValue;
  }
  produce(e) {
    if (this._ensureNoFinalValue(), this._unsatisfiedConsumers.length > 0) {
      const n = this._unsatisfiedConsumers.shift();
      this._resolveOrRejectDeferred(n, e);
    } else
      this._unconsumedValues.push(e);
  }
  produceFinal(e) {
    this._ensureNoFinalValue(), this._finalValue = e;
    for (const n of this._unsatisfiedConsumers)
      this._resolveOrRejectDeferred(n, e);
    this._unsatisfiedConsumers.length = 0;
  }
  _ensureNoFinalValue() {
    if (this._finalValue)
      throw new K("ProducerConsumer: cannot produce after final value has been set");
  }
  _resolveOrRejectDeferred(e, n) {
    n.ok ? e.complete(n.value) : e.error(n.error);
  }
  consume() {
    if (this._unconsumedValues.length > 0 || this._finalValue) {
      const e = this._unconsumedValues.length > 0 ? this._unconsumedValues.shift() : this._finalValue;
      return e.ok ? Promise.resolve(e.value) : Promise.reject(e.error);
    } else {
      const e = new vn();
      return this._unsatisfiedConsumers.push(e), e.p;
    }
  }
}
class Q {
  constructor(e, n) {
    this._onReturn = n, this._producerConsumer = new Ai(), this._iterator = {
      next: () => this._producerConsumer.consume(),
      return: () => (this._onReturn?.(), Promise.resolve({ done: !0, value: void 0 })),
      throw: async (s) => (this._finishError(s), { done: !0, value: void 0 })
    }, queueMicrotask(async () => {
      const s = e({
        emitOne: (i) => this._producerConsumer.produce({ ok: !0, value: { done: !1, value: i } }),
        emitMany: (i) => {
          for (const r of i)
            this._producerConsumer.produce({ ok: !0, value: { done: !1, value: r } });
        },
        reject: (i) => this._finishError(i)
      });
      if (!this._producerConsumer.hasFinalValue)
        try {
          await s, this._finishOk();
        } catch (i) {
          this._finishError(i);
        }
    });
  }
  static fromArray(e) {
    return new Q((n) => {
      n.emitMany(e);
    });
  }
  static fromPromise(e) {
    return new Q(async (n) => {
      n.emitMany(await e);
    });
  }
  static fromPromisesResolveOrder(e) {
    return new Q(async (n) => {
      await Promise.all(e.map(async (s) => n.emitOne(await s)));
    });
  }
  static merge(e) {
    return new Q(async (n) => {
      await Promise.all(e.map(async (s) => {
        for await (const i of s)
          n.emitOne(i);
      }));
    });
  }
  static {
    this.EMPTY = Q.fromArray([]);
  }
  static map(e, n) {
    return new Q(async (s) => {
      for await (const i of e)
        s.emitOne(n(i));
    });
  }
  map(e) {
    return Q.map(this, e);
  }
  static coalesce(e) {
    return Q.filter(e, (n) => !!n);
  }
  coalesce() {
    return Q.coalesce(this);
  }
  static filter(e, n) {
    return new Q(async (s) => {
      for await (const i of e)
        n(i) && s.emitOne(i);
    });
  }
  filter(e) {
    return Q.filter(this, e);
  }
  _finishOk() {
    this._producerConsumer.hasFinalValue || this._producerConsumer.produceFinal({ ok: !0, value: { done: !0, value: void 0 } });
  }
  _finishError(e) {
    this._producerConsumer.hasFinalValue || this._producerConsumer.produceFinal({ ok: !1, error: e });
  }
  [Symbol.asyncIterator]() {
    return this._iterator;
  }
}
class Si extends Q {
  constructor(e, n) {
    super(n), this._source = e;
  }
  cancel() {
    this._source.cancel();
  }
}
function wn(t) {
  return t;
}
class Di {
  constructor(e, n) {
    this.lastCache = void 0, this.lastArgKey = void 0, typeof e == "function" ? (this._fn = e, this._computeKey = wn) : (this._fn = n, this._computeKey = e.getCacheKey);
  }
  get(e) {
    const n = this._computeKey(e);
    return this.lastArgKey !== n && (this.lastArgKey = n, this.lastCache = this._fn(e)), this.lastCache;
  }
}
class F0 {
  get cachedValues() {
    return this._map;
  }
  constructor(e, n) {
    this._map = /* @__PURE__ */ new Map(), this._map2 = /* @__PURE__ */ new Map(), typeof e == "function" ? (this._fn = e, this._computeKey = wn) : (this._fn = n, this._computeKey = e.getCacheKey);
  }
  get(e) {
    const n = this._computeKey(e);
    if (this._map2.has(n))
      return this._map2.get(n);
    const s = this._fn(e);
    return this._map.set(e, s), this._map2.set(n, s), s;
  }
}
var we;
(function(t) {
  t[t.Uninitialized = 0] = "Uninitialized", t[t.Running = 1] = "Running", t[t.Completed = 2] = "Completed";
})(we || (we = {}));
class Yt {
  constructor(e) {
    this.executor = e, this._state = we.Uninitialized;
  }
  /**
   * Get the wrapped value.
   *
   * This will force evaluation of the lazy value if it has not been resolved yet. Lazy values are only
   * resolved once. `getValue` will re-throw exceptions that are hit while resolving the value
   */
  get value() {
    if (this._state === we.Uninitialized) {
      this._state = we.Running;
      try {
        this._value = this.executor();
      } catch (e) {
        this._error = e;
      } finally {
        this._state = we.Completed;
      }
    } else if (this._state === we.Running)
      throw new Error("Cannot read the value of a lazy that is being initialized");
    if (this._error)
      throw this._error;
    return this._value;
  }
  /**
   * Get the wrapped value without forcing evaluation.
   */
  get rawValue() {
    return this._value;
  }
}
function M0(t) {
  return !t || typeof t != "string" ? !0 : t.trim().length === 0;
}
const Oi = /{(\d+)}/g;
function P0(t, ...e) {
  return e.length === 0 ? t : t.replace(Oi, function(n, s) {
    const i = parseInt(s, 10);
    return isNaN(i) || i < 0 || i >= e.length ? n : e[i];
  });
}
function V0(t) {
  return t.replace(/[<>"'&]/g, (e) => {
    switch (e) {
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      case '"':
        return "&quot;";
      case "'":
        return "&apos;";
      case "&":
        return "&amp;";
    }
    return e;
  });
}
function x0(t) {
  return t.replace(/[<>&]/g, function(e) {
    switch (e) {
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      case "&":
        return "&amp;";
      default:
        return e;
    }
  });
}
function Ti(t) {
  return t.replace(/[\\\{\}\*\+\?\|\^\$\.\[\]\(\)]/g, "\\$&");
}
function U0(t, e = " ") {
  const n = Ri(t, e);
  return Ki(n, e);
}
function Ri(t, e) {
  if (!t || !e)
    return t;
  const n = e.length;
  if (n === 0 || t.length === 0)
    return t;
  let s = 0;
  for (; t.indexOf(e, s) === s; )
    s = s + n;
  return t.substring(s);
}
function Ki(t, e) {
  if (!t || !e)
    return t;
  const n = e.length, s = t.length;
  if (n === 0 || s === 0)
    return t;
  let i = s, r = -1;
  for (; r = t.lastIndexOf(e, i - 1), !(r === -1 || r + n !== i); ) {
    if (r === 0)
      return "";
    i = r;
  }
  return t.substring(0, i);
}
function B0(t) {
  return t.replace(/[\-\\\{\}\+\?\|\^\$\.\,\[\]\(\)\#\s]/g, "\\$&").replace(/[\*]/g, ".*");
}
function W0(t, e, n = {}) {
  if (!t)
    throw new Error("Cannot create regex from empty string");
  e || (t = Ti(t)), n.wholeWord && (/\B/.test(t.charAt(0)) || (t = "\\b" + t), /\B/.test(t.charAt(t.length - 1)) || (t = t + "\\b"));
  let s = "";
  return n.global && (s += "g"), n.matchCase || (s += "i"), n.multiline && (s += "m"), n.unicode && (s += "u"), new RegExp(t, s);
}
function $0(t) {
  return t.source === "^" || t.source === "^$" || t.source === "$" || t.source === "^\\s*$" ? !1 : !!(t.exec("") && t.lastIndex === 0);
}
function H0(t) {
  return t.split(/\r\n|\r|\n/);
}
function q0(t) {
  for (let e = 0, n = t.length; e < n; e++) {
    const s = t.charCodeAt(e);
    if (s !== 32 && s !== 9)
      return e;
  }
  return -1;
}
function G0(t, e = 0, n = t.length) {
  for (let s = e; s < n; s++) {
    const i = t.charCodeAt(s);
    if (i !== 32 && i !== 9)
      return t.substring(e, s);
  }
  return t.substring(e, n);
}
function j0(t, e = t.length - 1) {
  for (let n = e; n >= 0; n--) {
    const s = t.charCodeAt(n);
    if (s !== 32 && s !== 9)
      return n;
  }
  return -1;
}
function z0(t, e) {
  return t < e ? -1 : t > e ? 1 : 0;
}
function ki(t, e, n = 0, s = t.length, i = 0, r = e.length) {
  for (; n < s && i < r; n++, i++) {
    const u = t.charCodeAt(n), l = e.charCodeAt(i);
    if (u < l)
      return -1;
    if (u > l)
      return 1;
  }
  const o = s - n, a = r - i;
  return o < a ? -1 : o > a ? 1 : 0;
}
function Q0(t, e) {
  return Ot(t, e, 0, t.length, 0, e.length);
}
function Ot(t, e, n = 0, s = t.length, i = 0, r = e.length) {
  for (; n < s && i < r; n++, i++) {
    let u = t.charCodeAt(n), l = e.charCodeAt(i);
    if (u === l)
      continue;
    if (u >= 128 || l >= 128)
      return ki(t.toLowerCase(), e.toLowerCase(), n, s, i, r);
    V1(u) && (u -= 32), V1(l) && (l -= 32);
    const d = u - l;
    if (d !== 0)
      return d;
  }
  const o = s - n, a = r - i;
  return o < a ? -1 : o > a ? 1 : 0;
}
function Y0(t) {
  return t >= 48 && t <= 57;
}
function V1(t) {
  return t >= 97 && t <= 122;
}
function X0(t) {
  return t >= 65 && t <= 90;
}
function Li(t, e) {
  return t.length === e.length && Ot(t, e) === 0;
}
function Ni(t, e) {
  const n = e.length;
  return n <= t.length && Ot(t, e, 0, n) === 0;
}
function Z0(t, e) {
  const n = t.length, s = n - e.length;
  return s >= 0 && Ot(t, e, s, n) === 0;
}
function J0(t, e) {
  const n = Math.min(t.length, e.length);
  let s;
  for (s = 0; s < n; s++)
    if (t.charCodeAt(s) !== e.charCodeAt(s))
      return s;
  return n;
}
function e2(t, e) {
  const n = Math.min(t.length, e.length);
  let s;
  const i = t.length - 1, r = e.length - 1;
  for (s = 0; s < n; s++)
    if (t.charCodeAt(i - s) !== e.charCodeAt(r - s))
      return s;
  return n;
}
function _1(t) {
  return 55296 <= t && t <= 56319;
}
function Ye(t) {
  return 56320 <= t && t <= 57343;
}
function y1(t, e) {
  return (t - 55296 << 10) + (e - 56320) + 65536;
}
function Ii(t, e, n) {
  const s = t.charCodeAt(n);
  if (_1(s) && n + 1 < e) {
    const i = t.charCodeAt(n + 1);
    if (Ye(i))
      return y1(s, i);
  }
  return s;
}
function Fi(t, e) {
  const n = t.charCodeAt(e - 1);
  if (Ye(n) && e > 1) {
    const s = t.charCodeAt(e - 2);
    if (_1(s))
      return y1(s, n);
  }
  return n;
}
class g1 {
  get offset() {
    return this._offset;
  }
  constructor(e, n = 0) {
    this._str = e, this._len = e.length, this._offset = n;
  }
  setOffset(e) {
    this._offset = e;
  }
  prevCodePoint() {
    const e = Fi(this._str, this._offset);
    return this._offset -= e >= 65536 ? 2 : 1, e;
  }
  nextCodePoint() {
    const e = Ii(this._str, this._len, this._offset);
    return this._offset += e >= 65536 ? 2 : 1, e;
  }
  eol() {
    return this._offset >= this._len;
  }
}
class En {
  get offset() {
    return this._iterator.offset;
  }
  constructor(e, n = 0) {
    this._iterator = new g1(e, n);
  }
  nextGraphemeLength() {
    const e = Ee.getInstance(), n = this._iterator, s = n.offset;
    let i = e.getGraphemeBreakType(n.nextCodePoint());
    for (; !n.eol(); ) {
      const r = n.offset, o = e.getGraphemeBreakType(n.nextCodePoint());
      if (x1(i, o)) {
        n.setOffset(r);
        break;
      }
      i = o;
    }
    return n.offset - s;
  }
  prevGraphemeLength() {
    const e = Ee.getInstance(), n = this._iterator, s = n.offset;
    let i = e.getGraphemeBreakType(n.prevCodePoint());
    for (; n.offset > 0; ) {
      const r = n.offset, o = e.getGraphemeBreakType(n.prevCodePoint());
      if (x1(o, i)) {
        n.setOffset(r);
        break;
      }
      i = o;
    }
    return s - n.offset;
  }
  eol() {
    return this._iterator.eol();
  }
}
function Mi(t, e) {
  return new En(t, e).nextGraphemeLength();
}
function Pi(t, e) {
  return new En(t, e).prevGraphemeLength();
}
function t2(t, e) {
  e > 0 && Ye(t.charCodeAt(e)) && e--;
  const n = e + Mi(t, e);
  return [n - Pi(t, n), n];
}
let Ft;
function Vi() {
  return /(?:[\u05BE\u05C0\u05C3\u05C6\u05D0-\u05F4\u0608\u060B\u060D\u061B-\u064A\u066D-\u066F\u0671-\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u0710\u0712-\u072F\u074D-\u07A5\u07B1-\u07EA\u07F4\u07F5\u07FA\u07FE-\u0815\u081A\u0824\u0828\u0830-\u0858\u085E-\u088E\u08A0-\u08C9\u200F\uFB1D\uFB1F-\uFB28\uFB2A-\uFD3D\uFD50-\uFDC7\uFDF0-\uFDFC\uFE70-\uFEFC]|\uD802[\uDC00-\uDD1B\uDD20-\uDE00\uDE10-\uDE35\uDE40-\uDEE4\uDEEB-\uDF35\uDF40-\uDFFF]|\uD803[\uDC00-\uDD23\uDE80-\uDEA9\uDEAD-\uDF45\uDF51-\uDF81\uDF86-\uDFF6]|\uD83A[\uDC00-\uDCCF\uDD00-\uDD43\uDD4B-\uDFFF]|\uD83B[\uDC00-\uDEBB])/;
}
function n2(t) {
  return Ft || (Ft = Vi()), Ft.test(t);
}
const xi = /^[\t\n\r\x20-\x7E]*$/;
function s2(t) {
  return xi.test(t);
}
const Ui = /[\u2028\u2029]/;
function i2(t) {
  return Ui.test(t);
}
function r2(t) {
  return t >= 11904 && t <= 55215 || t >= 63744 && t <= 64255 || t >= 65281 && t <= 65374;
}
function Bi(t) {
  return t >= 127462 && t <= 127487 || t === 8986 || t === 8987 || t === 9200 || t === 9203 || t >= 9728 && t <= 10175 || t === 11088 || t === 11093 || t >= 127744 && t <= 128591 || t >= 128640 && t <= 128764 || t >= 128992 && t <= 129008 || t >= 129280 && t <= 129535 || t >= 129648 && t <= 129782;
}
const o2 = "\uFEFF";
function a2(t) {
  return !!(t && t.length > 0 && t.charCodeAt(0) === 65279);
}
function u2(t, e = !1) {
  return t ? (e && (t = t.replace(/\\./g, "")), t.toLowerCase() !== t) : !1;
}
function l2(t) {
  return t = t % 52, t < 26 ? String.fromCharCode(97 + t) : String.fromCharCode(65 + t - 26);
}
function x1(t, e) {
  return t === 0 ? e !== 5 && e !== 7 : t === 2 && e === 3 ? !1 : t === 4 || t === 2 || t === 3 || e === 4 || e === 2 || e === 3 ? !0 : !(t === 8 && (e === 8 || e === 9 || e === 11 || e === 12) || (t === 11 || t === 9) && (e === 9 || e === 10) || (t === 12 || t === 10) && e === 10 || e === 5 || e === 13 || e === 7 || t === 1 || t === 13 && e === 14 || t === 6 && e === 6);
}
class Ee {
  static {
    this._INSTANCE = null;
  }
  static getInstance() {
    return Ee._INSTANCE || (Ee._INSTANCE = new Ee()), Ee._INSTANCE;
  }
  constructor() {
    this._data = Wi();
  }
  getGraphemeBreakType(e) {
    if (e < 32)
      return e === 10 ? 3 : e === 13 ? 2 : 4;
    if (e < 127)
      return 0;
    const n = this._data, s = n.length / 3;
    let i = 1;
    for (; i <= s; )
      if (e < n[3 * i])
        i = 2 * i;
      else if (e > n[3 * i + 1])
        i = 2 * i + 1;
      else
        return n[3 * i + 2];
    return 0;
  }
}
function Wi() {
  return JSON.parse("[0,0,0,51229,51255,12,44061,44087,12,127462,127487,6,7083,7085,5,47645,47671,12,54813,54839,12,128678,128678,14,3270,3270,5,9919,9923,14,45853,45879,12,49437,49463,12,53021,53047,12,71216,71218,7,128398,128399,14,129360,129374,14,2519,2519,5,4448,4519,9,9742,9742,14,12336,12336,14,44957,44983,12,46749,46775,12,48541,48567,12,50333,50359,12,52125,52151,12,53917,53943,12,69888,69890,5,73018,73018,5,127990,127990,14,128558,128559,14,128759,128760,14,129653,129655,14,2027,2035,5,2891,2892,7,3761,3761,5,6683,6683,5,8293,8293,4,9825,9826,14,9999,9999,14,43452,43453,5,44509,44535,12,45405,45431,12,46301,46327,12,47197,47223,12,48093,48119,12,48989,49015,12,49885,49911,12,50781,50807,12,51677,51703,12,52573,52599,12,53469,53495,12,54365,54391,12,65279,65279,4,70471,70472,7,72145,72147,7,119173,119179,5,127799,127818,14,128240,128244,14,128512,128512,14,128652,128652,14,128721,128722,14,129292,129292,14,129445,129450,14,129734,129743,14,1476,1477,5,2366,2368,7,2750,2752,7,3076,3076,5,3415,3415,5,4141,4144,5,6109,6109,5,6964,6964,5,7394,7400,5,9197,9198,14,9770,9770,14,9877,9877,14,9968,9969,14,10084,10084,14,43052,43052,5,43713,43713,5,44285,44311,12,44733,44759,12,45181,45207,12,45629,45655,12,46077,46103,12,46525,46551,12,46973,46999,12,47421,47447,12,47869,47895,12,48317,48343,12,48765,48791,12,49213,49239,12,49661,49687,12,50109,50135,12,50557,50583,12,51005,51031,12,51453,51479,12,51901,51927,12,52349,52375,12,52797,52823,12,53245,53271,12,53693,53719,12,54141,54167,12,54589,54615,12,55037,55063,12,69506,69509,5,70191,70193,5,70841,70841,7,71463,71467,5,72330,72342,5,94031,94031,5,123628,123631,5,127763,127765,14,127941,127941,14,128043,128062,14,128302,128317,14,128465,128467,14,128539,128539,14,128640,128640,14,128662,128662,14,128703,128703,14,128745,128745,14,129004,129007,14,129329,129330,14,129402,129402,14,129483,129483,14,129686,129704,14,130048,131069,14,173,173,4,1757,1757,1,2200,2207,5,2434,2435,7,2631,2632,5,2817,2817,5,3008,3008,5,3201,3201,5,3387,3388,5,3542,3542,5,3902,3903,7,4190,4192,5,6002,6003,5,6439,6440,5,6765,6770,7,7019,7027,5,7154,7155,7,8205,8205,13,8505,8505,14,9654,9654,14,9757,9757,14,9792,9792,14,9852,9853,14,9890,9894,14,9937,9937,14,9981,9981,14,10035,10036,14,11035,11036,14,42654,42655,5,43346,43347,7,43587,43587,5,44006,44007,7,44173,44199,12,44397,44423,12,44621,44647,12,44845,44871,12,45069,45095,12,45293,45319,12,45517,45543,12,45741,45767,12,45965,45991,12,46189,46215,12,46413,46439,12,46637,46663,12,46861,46887,12,47085,47111,12,47309,47335,12,47533,47559,12,47757,47783,12,47981,48007,12,48205,48231,12,48429,48455,12,48653,48679,12,48877,48903,12,49101,49127,12,49325,49351,12,49549,49575,12,49773,49799,12,49997,50023,12,50221,50247,12,50445,50471,12,50669,50695,12,50893,50919,12,51117,51143,12,51341,51367,12,51565,51591,12,51789,51815,12,52013,52039,12,52237,52263,12,52461,52487,12,52685,52711,12,52909,52935,12,53133,53159,12,53357,53383,12,53581,53607,12,53805,53831,12,54029,54055,12,54253,54279,12,54477,54503,12,54701,54727,12,54925,54951,12,55149,55175,12,68101,68102,5,69762,69762,7,70067,70069,7,70371,70378,5,70720,70721,7,71087,71087,5,71341,71341,5,71995,71996,5,72249,72249,7,72850,72871,5,73109,73109,5,118576,118598,5,121505,121519,5,127245,127247,14,127568,127569,14,127777,127777,14,127872,127891,14,127956,127967,14,128015,128016,14,128110,128172,14,128259,128259,14,128367,128368,14,128424,128424,14,128488,128488,14,128530,128532,14,128550,128551,14,128566,128566,14,128647,128647,14,128656,128656,14,128667,128673,14,128691,128693,14,128715,128715,14,128728,128732,14,128752,128752,14,128765,128767,14,129096,129103,14,129311,129311,14,129344,129349,14,129394,129394,14,129413,129425,14,129466,129471,14,129511,129535,14,129664,129666,14,129719,129722,14,129760,129767,14,917536,917631,5,13,13,2,1160,1161,5,1564,1564,4,1807,1807,1,2085,2087,5,2307,2307,7,2382,2383,7,2497,2500,5,2563,2563,7,2677,2677,5,2763,2764,7,2879,2879,5,2914,2915,5,3021,3021,5,3142,3144,5,3263,3263,5,3285,3286,5,3398,3400,7,3530,3530,5,3633,3633,5,3864,3865,5,3974,3975,5,4155,4156,7,4229,4230,5,5909,5909,7,6078,6085,7,6277,6278,5,6451,6456,7,6744,6750,5,6846,6846,5,6972,6972,5,7074,7077,5,7146,7148,7,7222,7223,5,7416,7417,5,8234,8238,4,8417,8417,5,9000,9000,14,9203,9203,14,9730,9731,14,9748,9749,14,9762,9763,14,9776,9783,14,9800,9811,14,9831,9831,14,9872,9873,14,9882,9882,14,9900,9903,14,9929,9933,14,9941,9960,14,9974,9974,14,9989,9989,14,10006,10006,14,10062,10062,14,10160,10160,14,11647,11647,5,12953,12953,14,43019,43019,5,43232,43249,5,43443,43443,5,43567,43568,7,43696,43696,5,43765,43765,7,44013,44013,5,44117,44143,12,44229,44255,12,44341,44367,12,44453,44479,12,44565,44591,12,44677,44703,12,44789,44815,12,44901,44927,12,45013,45039,12,45125,45151,12,45237,45263,12,45349,45375,12,45461,45487,12,45573,45599,12,45685,45711,12,45797,45823,12,45909,45935,12,46021,46047,12,46133,46159,12,46245,46271,12,46357,46383,12,46469,46495,12,46581,46607,12,46693,46719,12,46805,46831,12,46917,46943,12,47029,47055,12,47141,47167,12,47253,47279,12,47365,47391,12,47477,47503,12,47589,47615,12,47701,47727,12,47813,47839,12,47925,47951,12,48037,48063,12,48149,48175,12,48261,48287,12,48373,48399,12,48485,48511,12,48597,48623,12,48709,48735,12,48821,48847,12,48933,48959,12,49045,49071,12,49157,49183,12,49269,49295,12,49381,49407,12,49493,49519,12,49605,49631,12,49717,49743,12,49829,49855,12,49941,49967,12,50053,50079,12,50165,50191,12,50277,50303,12,50389,50415,12,50501,50527,12,50613,50639,12,50725,50751,12,50837,50863,12,50949,50975,12,51061,51087,12,51173,51199,12,51285,51311,12,51397,51423,12,51509,51535,12,51621,51647,12,51733,51759,12,51845,51871,12,51957,51983,12,52069,52095,12,52181,52207,12,52293,52319,12,52405,52431,12,52517,52543,12,52629,52655,12,52741,52767,12,52853,52879,12,52965,52991,12,53077,53103,12,53189,53215,12,53301,53327,12,53413,53439,12,53525,53551,12,53637,53663,12,53749,53775,12,53861,53887,12,53973,53999,12,54085,54111,12,54197,54223,12,54309,54335,12,54421,54447,12,54533,54559,12,54645,54671,12,54757,54783,12,54869,54895,12,54981,55007,12,55093,55119,12,55243,55291,10,66045,66045,5,68325,68326,5,69688,69702,5,69817,69818,5,69957,69958,7,70089,70092,5,70198,70199,5,70462,70462,5,70502,70508,5,70750,70750,5,70846,70846,7,71100,71101,5,71230,71230,7,71351,71351,5,71737,71738,5,72000,72000,7,72160,72160,5,72273,72278,5,72752,72758,5,72882,72883,5,73031,73031,5,73461,73462,7,94192,94193,7,119149,119149,7,121403,121452,5,122915,122916,5,126980,126980,14,127358,127359,14,127535,127535,14,127759,127759,14,127771,127771,14,127792,127793,14,127825,127867,14,127897,127899,14,127945,127945,14,127985,127986,14,128000,128007,14,128021,128021,14,128066,128100,14,128184,128235,14,128249,128252,14,128266,128276,14,128335,128335,14,128379,128390,14,128407,128419,14,128444,128444,14,128481,128481,14,128499,128499,14,128526,128526,14,128536,128536,14,128543,128543,14,128556,128556,14,128564,128564,14,128577,128580,14,128643,128645,14,128649,128649,14,128654,128654,14,128660,128660,14,128664,128664,14,128675,128675,14,128686,128689,14,128695,128696,14,128705,128709,14,128717,128719,14,128725,128725,14,128736,128741,14,128747,128748,14,128755,128755,14,128762,128762,14,128981,128991,14,129009,129023,14,129160,129167,14,129296,129304,14,129320,129327,14,129340,129342,14,129356,129356,14,129388,129392,14,129399,129400,14,129404,129407,14,129432,129442,14,129454,129455,14,129473,129474,14,129485,129487,14,129648,129651,14,129659,129660,14,129671,129679,14,129709,129711,14,129728,129730,14,129751,129753,14,129776,129782,14,917505,917505,4,917760,917999,5,10,10,3,127,159,4,768,879,5,1471,1471,5,1536,1541,1,1648,1648,5,1767,1768,5,1840,1866,5,2070,2073,5,2137,2139,5,2274,2274,1,2363,2363,7,2377,2380,7,2402,2403,5,2494,2494,5,2507,2508,7,2558,2558,5,2622,2624,7,2641,2641,5,2691,2691,7,2759,2760,5,2786,2787,5,2876,2876,5,2881,2884,5,2901,2902,5,3006,3006,5,3014,3016,7,3072,3072,5,3134,3136,5,3157,3158,5,3260,3260,5,3266,3266,5,3274,3275,7,3328,3329,5,3391,3392,7,3405,3405,5,3457,3457,5,3536,3537,7,3551,3551,5,3636,3642,5,3764,3772,5,3895,3895,5,3967,3967,7,3993,4028,5,4146,4151,5,4182,4183,7,4226,4226,5,4253,4253,5,4957,4959,5,5940,5940,7,6070,6070,7,6087,6088,7,6158,6158,4,6432,6434,5,6448,6449,7,6679,6680,5,6742,6742,5,6754,6754,5,6783,6783,5,6912,6915,5,6966,6970,5,6978,6978,5,7042,7042,7,7080,7081,5,7143,7143,7,7150,7150,7,7212,7219,5,7380,7392,5,7412,7412,5,8203,8203,4,8232,8232,4,8265,8265,14,8400,8412,5,8421,8432,5,8617,8618,14,9167,9167,14,9200,9200,14,9410,9410,14,9723,9726,14,9733,9733,14,9745,9745,14,9752,9752,14,9760,9760,14,9766,9766,14,9774,9774,14,9786,9786,14,9794,9794,14,9823,9823,14,9828,9828,14,9833,9850,14,9855,9855,14,9875,9875,14,9880,9880,14,9885,9887,14,9896,9897,14,9906,9916,14,9926,9927,14,9935,9935,14,9939,9939,14,9962,9962,14,9972,9972,14,9978,9978,14,9986,9986,14,9997,9997,14,10002,10002,14,10017,10017,14,10055,10055,14,10071,10071,14,10133,10135,14,10548,10549,14,11093,11093,14,12330,12333,5,12441,12442,5,42608,42610,5,43010,43010,5,43045,43046,5,43188,43203,7,43302,43309,5,43392,43394,5,43446,43449,5,43493,43493,5,43571,43572,7,43597,43597,7,43703,43704,5,43756,43757,5,44003,44004,7,44009,44010,7,44033,44059,12,44089,44115,12,44145,44171,12,44201,44227,12,44257,44283,12,44313,44339,12,44369,44395,12,44425,44451,12,44481,44507,12,44537,44563,12,44593,44619,12,44649,44675,12,44705,44731,12,44761,44787,12,44817,44843,12,44873,44899,12,44929,44955,12,44985,45011,12,45041,45067,12,45097,45123,12,45153,45179,12,45209,45235,12,45265,45291,12,45321,45347,12,45377,45403,12,45433,45459,12,45489,45515,12,45545,45571,12,45601,45627,12,45657,45683,12,45713,45739,12,45769,45795,12,45825,45851,12,45881,45907,12,45937,45963,12,45993,46019,12,46049,46075,12,46105,46131,12,46161,46187,12,46217,46243,12,46273,46299,12,46329,46355,12,46385,46411,12,46441,46467,12,46497,46523,12,46553,46579,12,46609,46635,12,46665,46691,12,46721,46747,12,46777,46803,12,46833,46859,12,46889,46915,12,46945,46971,12,47001,47027,12,47057,47083,12,47113,47139,12,47169,47195,12,47225,47251,12,47281,47307,12,47337,47363,12,47393,47419,12,47449,47475,12,47505,47531,12,47561,47587,12,47617,47643,12,47673,47699,12,47729,47755,12,47785,47811,12,47841,47867,12,47897,47923,12,47953,47979,12,48009,48035,12,48065,48091,12,48121,48147,12,48177,48203,12,48233,48259,12,48289,48315,12,48345,48371,12,48401,48427,12,48457,48483,12,48513,48539,12,48569,48595,12,48625,48651,12,48681,48707,12,48737,48763,12,48793,48819,12,48849,48875,12,48905,48931,12,48961,48987,12,49017,49043,12,49073,49099,12,49129,49155,12,49185,49211,12,49241,49267,12,49297,49323,12,49353,49379,12,49409,49435,12,49465,49491,12,49521,49547,12,49577,49603,12,49633,49659,12,49689,49715,12,49745,49771,12,49801,49827,12,49857,49883,12,49913,49939,12,49969,49995,12,50025,50051,12,50081,50107,12,50137,50163,12,50193,50219,12,50249,50275,12,50305,50331,12,50361,50387,12,50417,50443,12,50473,50499,12,50529,50555,12,50585,50611,12,50641,50667,12,50697,50723,12,50753,50779,12,50809,50835,12,50865,50891,12,50921,50947,12,50977,51003,12,51033,51059,12,51089,51115,12,51145,51171,12,51201,51227,12,51257,51283,12,51313,51339,12,51369,51395,12,51425,51451,12,51481,51507,12,51537,51563,12,51593,51619,12,51649,51675,12,51705,51731,12,51761,51787,12,51817,51843,12,51873,51899,12,51929,51955,12,51985,52011,12,52041,52067,12,52097,52123,12,52153,52179,12,52209,52235,12,52265,52291,12,52321,52347,12,52377,52403,12,52433,52459,12,52489,52515,12,52545,52571,12,52601,52627,12,52657,52683,12,52713,52739,12,52769,52795,12,52825,52851,12,52881,52907,12,52937,52963,12,52993,53019,12,53049,53075,12,53105,53131,12,53161,53187,12,53217,53243,12,53273,53299,12,53329,53355,12,53385,53411,12,53441,53467,12,53497,53523,12,53553,53579,12,53609,53635,12,53665,53691,12,53721,53747,12,53777,53803,12,53833,53859,12,53889,53915,12,53945,53971,12,54001,54027,12,54057,54083,12,54113,54139,12,54169,54195,12,54225,54251,12,54281,54307,12,54337,54363,12,54393,54419,12,54449,54475,12,54505,54531,12,54561,54587,12,54617,54643,12,54673,54699,12,54729,54755,12,54785,54811,12,54841,54867,12,54897,54923,12,54953,54979,12,55009,55035,12,55065,55091,12,55121,55147,12,55177,55203,12,65024,65039,5,65520,65528,4,66422,66426,5,68152,68154,5,69291,69292,5,69633,69633,5,69747,69748,5,69811,69814,5,69826,69826,5,69932,69932,7,70016,70017,5,70079,70080,7,70095,70095,5,70196,70196,5,70367,70367,5,70402,70403,7,70464,70464,5,70487,70487,5,70709,70711,7,70725,70725,7,70833,70834,7,70843,70844,7,70849,70849,7,71090,71093,5,71103,71104,5,71227,71228,7,71339,71339,5,71344,71349,5,71458,71461,5,71727,71735,5,71985,71989,7,71998,71998,5,72002,72002,7,72154,72155,5,72193,72202,5,72251,72254,5,72281,72283,5,72344,72345,5,72766,72766,7,72874,72880,5,72885,72886,5,73023,73029,5,73104,73105,5,73111,73111,5,92912,92916,5,94095,94098,5,113824,113827,4,119142,119142,7,119155,119162,4,119362,119364,5,121476,121476,5,122888,122904,5,123184,123190,5,125252,125258,5,127183,127183,14,127340,127343,14,127377,127386,14,127491,127503,14,127548,127551,14,127744,127756,14,127761,127761,14,127769,127769,14,127773,127774,14,127780,127788,14,127796,127797,14,127820,127823,14,127869,127869,14,127894,127895,14,127902,127903,14,127943,127943,14,127947,127950,14,127972,127972,14,127988,127988,14,127992,127994,14,128009,128011,14,128019,128019,14,128023,128041,14,128064,128064,14,128102,128107,14,128174,128181,14,128238,128238,14,128246,128247,14,128254,128254,14,128264,128264,14,128278,128299,14,128329,128330,14,128348,128359,14,128371,128377,14,128392,128393,14,128401,128404,14,128421,128421,14,128433,128434,14,128450,128452,14,128476,128478,14,128483,128483,14,128495,128495,14,128506,128506,14,128519,128520,14,128528,128528,14,128534,128534,14,128538,128538,14,128540,128542,14,128544,128549,14,128552,128555,14,128557,128557,14,128560,128563,14,128565,128565,14,128567,128576,14,128581,128591,14,128641,128642,14,128646,128646,14,128648,128648,14,128650,128651,14,128653,128653,14,128655,128655,14,128657,128659,14,128661,128661,14,128663,128663,14,128665,128666,14,128674,128674,14,128676,128677,14,128679,128685,14,128690,128690,14,128694,128694,14,128697,128702,14,128704,128704,14,128710,128714,14,128716,128716,14,128720,128720,14,128723,128724,14,128726,128727,14,128733,128735,14,128742,128744,14,128746,128746,14,128749,128751,14,128753,128754,14,128756,128758,14,128761,128761,14,128763,128764,14,128884,128895,14,128992,129003,14,129008,129008,14,129036,129039,14,129114,129119,14,129198,129279,14,129293,129295,14,129305,129310,14,129312,129319,14,129328,129328,14,129331,129338,14,129343,129343,14,129351,129355,14,129357,129359,14,129375,129387,14,129393,129393,14,129395,129398,14,129401,129401,14,129403,129403,14,129408,129412,14,129426,129431,14,129443,129444,14,129451,129453,14,129456,129465,14,129472,129472,14,129475,129482,14,129484,129484,14,129488,129510,14,129536,129647,14,129652,129652,14,129656,129658,14,129661,129663,14,129667,129670,14,129680,129685,14,129705,129708,14,129712,129718,14,129723,129727,14,129731,129733,14,129744,129750,14,129754,129759,14,129768,129775,14,129783,129791,14,917504,917504,4,917506,917535,4,917632,917759,4,918000,921599,4,0,9,4,11,12,4,14,31,4,169,169,14,174,174,14,1155,1159,5,1425,1469,5,1473,1474,5,1479,1479,5,1552,1562,5,1611,1631,5,1750,1756,5,1759,1764,5,1770,1773,5,1809,1809,5,1958,1968,5,2045,2045,5,2075,2083,5,2089,2093,5,2192,2193,1,2250,2273,5,2275,2306,5,2362,2362,5,2364,2364,5,2369,2376,5,2381,2381,5,2385,2391,5,2433,2433,5,2492,2492,5,2495,2496,7,2503,2504,7,2509,2509,5,2530,2531,5,2561,2562,5,2620,2620,5,2625,2626,5,2635,2637,5,2672,2673,5,2689,2690,5,2748,2748,5,2753,2757,5,2761,2761,7,2765,2765,5,2810,2815,5,2818,2819,7,2878,2878,5,2880,2880,7,2887,2888,7,2893,2893,5,2903,2903,5,2946,2946,5,3007,3007,7,3009,3010,7,3018,3020,7,3031,3031,5,3073,3075,7,3132,3132,5,3137,3140,7,3146,3149,5,3170,3171,5,3202,3203,7,3262,3262,7,3264,3265,7,3267,3268,7,3271,3272,7,3276,3277,5,3298,3299,5,3330,3331,7,3390,3390,5,3393,3396,5,3402,3404,7,3406,3406,1,3426,3427,5,3458,3459,7,3535,3535,5,3538,3540,5,3544,3550,7,3570,3571,7,3635,3635,7,3655,3662,5,3763,3763,7,3784,3789,5,3893,3893,5,3897,3897,5,3953,3966,5,3968,3972,5,3981,3991,5,4038,4038,5,4145,4145,7,4153,4154,5,4157,4158,5,4184,4185,5,4209,4212,5,4228,4228,7,4237,4237,5,4352,4447,8,4520,4607,10,5906,5908,5,5938,5939,5,5970,5971,5,6068,6069,5,6071,6077,5,6086,6086,5,6089,6099,5,6155,6157,5,6159,6159,5,6313,6313,5,6435,6438,7,6441,6443,7,6450,6450,5,6457,6459,5,6681,6682,7,6741,6741,7,6743,6743,7,6752,6752,5,6757,6764,5,6771,6780,5,6832,6845,5,6847,6862,5,6916,6916,7,6965,6965,5,6971,6971,7,6973,6977,7,6979,6980,7,7040,7041,5,7073,7073,7,7078,7079,7,7082,7082,7,7142,7142,5,7144,7145,5,7149,7149,5,7151,7153,5,7204,7211,7,7220,7221,7,7376,7378,5,7393,7393,7,7405,7405,5,7415,7415,7,7616,7679,5,8204,8204,5,8206,8207,4,8233,8233,4,8252,8252,14,8288,8292,4,8294,8303,4,8413,8416,5,8418,8420,5,8482,8482,14,8596,8601,14,8986,8987,14,9096,9096,14,9193,9196,14,9199,9199,14,9201,9202,14,9208,9210,14,9642,9643,14,9664,9664,14,9728,9729,14,9732,9732,14,9735,9741,14,9743,9744,14,9746,9746,14,9750,9751,14,9753,9756,14,9758,9759,14,9761,9761,14,9764,9765,14,9767,9769,14,9771,9773,14,9775,9775,14,9784,9785,14,9787,9791,14,9793,9793,14,9795,9799,14,9812,9822,14,9824,9824,14,9827,9827,14,9829,9830,14,9832,9832,14,9851,9851,14,9854,9854,14,9856,9861,14,9874,9874,14,9876,9876,14,9878,9879,14,9881,9881,14,9883,9884,14,9888,9889,14,9895,9895,14,9898,9899,14,9904,9905,14,9917,9918,14,9924,9925,14,9928,9928,14,9934,9934,14,9936,9936,14,9938,9938,14,9940,9940,14,9961,9961,14,9963,9967,14,9970,9971,14,9973,9973,14,9975,9977,14,9979,9980,14,9982,9985,14,9987,9988,14,9992,9996,14,9998,9998,14,10000,10001,14,10004,10004,14,10013,10013,14,10024,10024,14,10052,10052,14,10060,10060,14,10067,10069,14,10083,10083,14,10085,10087,14,10145,10145,14,10175,10175,14,11013,11015,14,11088,11088,14,11503,11505,5,11744,11775,5,12334,12335,5,12349,12349,14,12951,12951,14,42607,42607,5,42612,42621,5,42736,42737,5,43014,43014,5,43043,43044,7,43047,43047,7,43136,43137,7,43204,43205,5,43263,43263,5,43335,43345,5,43360,43388,8,43395,43395,7,43444,43445,7,43450,43451,7,43454,43456,7,43561,43566,5,43569,43570,5,43573,43574,5,43596,43596,5,43644,43644,5,43698,43700,5,43710,43711,5,43755,43755,7,43758,43759,7,43766,43766,5,44005,44005,5,44008,44008,5,44012,44012,7,44032,44032,11,44060,44060,11,44088,44088,11,44116,44116,11,44144,44144,11,44172,44172,11,44200,44200,11,44228,44228,11,44256,44256,11,44284,44284,11,44312,44312,11,44340,44340,11,44368,44368,11,44396,44396,11,44424,44424,11,44452,44452,11,44480,44480,11,44508,44508,11,44536,44536,11,44564,44564,11,44592,44592,11,44620,44620,11,44648,44648,11,44676,44676,11,44704,44704,11,44732,44732,11,44760,44760,11,44788,44788,11,44816,44816,11,44844,44844,11,44872,44872,11,44900,44900,11,44928,44928,11,44956,44956,11,44984,44984,11,45012,45012,11,45040,45040,11,45068,45068,11,45096,45096,11,45124,45124,11,45152,45152,11,45180,45180,11,45208,45208,11,45236,45236,11,45264,45264,11,45292,45292,11,45320,45320,11,45348,45348,11,45376,45376,11,45404,45404,11,45432,45432,11,45460,45460,11,45488,45488,11,45516,45516,11,45544,45544,11,45572,45572,11,45600,45600,11,45628,45628,11,45656,45656,11,45684,45684,11,45712,45712,11,45740,45740,11,45768,45768,11,45796,45796,11,45824,45824,11,45852,45852,11,45880,45880,11,45908,45908,11,45936,45936,11,45964,45964,11,45992,45992,11,46020,46020,11,46048,46048,11,46076,46076,11,46104,46104,11,46132,46132,11,46160,46160,11,46188,46188,11,46216,46216,11,46244,46244,11,46272,46272,11,46300,46300,11,46328,46328,11,46356,46356,11,46384,46384,11,46412,46412,11,46440,46440,11,46468,46468,11,46496,46496,11,46524,46524,11,46552,46552,11,46580,46580,11,46608,46608,11,46636,46636,11,46664,46664,11,46692,46692,11,46720,46720,11,46748,46748,11,46776,46776,11,46804,46804,11,46832,46832,11,46860,46860,11,46888,46888,11,46916,46916,11,46944,46944,11,46972,46972,11,47000,47000,11,47028,47028,11,47056,47056,11,47084,47084,11,47112,47112,11,47140,47140,11,47168,47168,11,47196,47196,11,47224,47224,11,47252,47252,11,47280,47280,11,47308,47308,11,47336,47336,11,47364,47364,11,47392,47392,11,47420,47420,11,47448,47448,11,47476,47476,11,47504,47504,11,47532,47532,11,47560,47560,11,47588,47588,11,47616,47616,11,47644,47644,11,47672,47672,11,47700,47700,11,47728,47728,11,47756,47756,11,47784,47784,11,47812,47812,11,47840,47840,11,47868,47868,11,47896,47896,11,47924,47924,11,47952,47952,11,47980,47980,11,48008,48008,11,48036,48036,11,48064,48064,11,48092,48092,11,48120,48120,11,48148,48148,11,48176,48176,11,48204,48204,11,48232,48232,11,48260,48260,11,48288,48288,11,48316,48316,11,48344,48344,11,48372,48372,11,48400,48400,11,48428,48428,11,48456,48456,11,48484,48484,11,48512,48512,11,48540,48540,11,48568,48568,11,48596,48596,11,48624,48624,11,48652,48652,11,48680,48680,11,48708,48708,11,48736,48736,11,48764,48764,11,48792,48792,11,48820,48820,11,48848,48848,11,48876,48876,11,48904,48904,11,48932,48932,11,48960,48960,11,48988,48988,11,49016,49016,11,49044,49044,11,49072,49072,11,49100,49100,11,49128,49128,11,49156,49156,11,49184,49184,11,49212,49212,11,49240,49240,11,49268,49268,11,49296,49296,11,49324,49324,11,49352,49352,11,49380,49380,11,49408,49408,11,49436,49436,11,49464,49464,11,49492,49492,11,49520,49520,11,49548,49548,11,49576,49576,11,49604,49604,11,49632,49632,11,49660,49660,11,49688,49688,11,49716,49716,11,49744,49744,11,49772,49772,11,49800,49800,11,49828,49828,11,49856,49856,11,49884,49884,11,49912,49912,11,49940,49940,11,49968,49968,11,49996,49996,11,50024,50024,11,50052,50052,11,50080,50080,11,50108,50108,11,50136,50136,11,50164,50164,11,50192,50192,11,50220,50220,11,50248,50248,11,50276,50276,11,50304,50304,11,50332,50332,11,50360,50360,11,50388,50388,11,50416,50416,11,50444,50444,11,50472,50472,11,50500,50500,11,50528,50528,11,50556,50556,11,50584,50584,11,50612,50612,11,50640,50640,11,50668,50668,11,50696,50696,11,50724,50724,11,50752,50752,11,50780,50780,11,50808,50808,11,50836,50836,11,50864,50864,11,50892,50892,11,50920,50920,11,50948,50948,11,50976,50976,11,51004,51004,11,51032,51032,11,51060,51060,11,51088,51088,11,51116,51116,11,51144,51144,11,51172,51172,11,51200,51200,11,51228,51228,11,51256,51256,11,51284,51284,11,51312,51312,11,51340,51340,11,51368,51368,11,51396,51396,11,51424,51424,11,51452,51452,11,51480,51480,11,51508,51508,11,51536,51536,11,51564,51564,11,51592,51592,11,51620,51620,11,51648,51648,11,51676,51676,11,51704,51704,11,51732,51732,11,51760,51760,11,51788,51788,11,51816,51816,11,51844,51844,11,51872,51872,11,51900,51900,11,51928,51928,11,51956,51956,11,51984,51984,11,52012,52012,11,52040,52040,11,52068,52068,11,52096,52096,11,52124,52124,11,52152,52152,11,52180,52180,11,52208,52208,11,52236,52236,11,52264,52264,11,52292,52292,11,52320,52320,11,52348,52348,11,52376,52376,11,52404,52404,11,52432,52432,11,52460,52460,11,52488,52488,11,52516,52516,11,52544,52544,11,52572,52572,11,52600,52600,11,52628,52628,11,52656,52656,11,52684,52684,11,52712,52712,11,52740,52740,11,52768,52768,11,52796,52796,11,52824,52824,11,52852,52852,11,52880,52880,11,52908,52908,11,52936,52936,11,52964,52964,11,52992,52992,11,53020,53020,11,53048,53048,11,53076,53076,11,53104,53104,11,53132,53132,11,53160,53160,11,53188,53188,11,53216,53216,11,53244,53244,11,53272,53272,11,53300,53300,11,53328,53328,11,53356,53356,11,53384,53384,11,53412,53412,11,53440,53440,11,53468,53468,11,53496,53496,11,53524,53524,11,53552,53552,11,53580,53580,11,53608,53608,11,53636,53636,11,53664,53664,11,53692,53692,11,53720,53720,11,53748,53748,11,53776,53776,11,53804,53804,11,53832,53832,11,53860,53860,11,53888,53888,11,53916,53916,11,53944,53944,11,53972,53972,11,54000,54000,11,54028,54028,11,54056,54056,11,54084,54084,11,54112,54112,11,54140,54140,11,54168,54168,11,54196,54196,11,54224,54224,11,54252,54252,11,54280,54280,11,54308,54308,11,54336,54336,11,54364,54364,11,54392,54392,11,54420,54420,11,54448,54448,11,54476,54476,11,54504,54504,11,54532,54532,11,54560,54560,11,54588,54588,11,54616,54616,11,54644,54644,11,54672,54672,11,54700,54700,11,54728,54728,11,54756,54756,11,54784,54784,11,54812,54812,11,54840,54840,11,54868,54868,11,54896,54896,11,54924,54924,11,54952,54952,11,54980,54980,11,55008,55008,11,55036,55036,11,55064,55064,11,55092,55092,11,55120,55120,11,55148,55148,11,55176,55176,11,55216,55238,9,64286,64286,5,65056,65071,5,65438,65439,5,65529,65531,4,66272,66272,5,68097,68099,5,68108,68111,5,68159,68159,5,68900,68903,5,69446,69456,5,69632,69632,7,69634,69634,7,69744,69744,5,69759,69761,5,69808,69810,7,69815,69816,7,69821,69821,1,69837,69837,1,69927,69931,5,69933,69940,5,70003,70003,5,70018,70018,7,70070,70078,5,70082,70083,1,70094,70094,7,70188,70190,7,70194,70195,7,70197,70197,7,70206,70206,5,70368,70370,7,70400,70401,5,70459,70460,5,70463,70463,7,70465,70468,7,70475,70477,7,70498,70499,7,70512,70516,5,70712,70719,5,70722,70724,5,70726,70726,5,70832,70832,5,70835,70840,5,70842,70842,5,70845,70845,5,70847,70848,5,70850,70851,5,71088,71089,7,71096,71099,7,71102,71102,7,71132,71133,5,71219,71226,5,71229,71229,5,71231,71232,5,71340,71340,7,71342,71343,7,71350,71350,7,71453,71455,5,71462,71462,7,71724,71726,7,71736,71736,7,71984,71984,5,71991,71992,7,71997,71997,7,71999,71999,1,72001,72001,1,72003,72003,5,72148,72151,5,72156,72159,7,72164,72164,7,72243,72248,5,72250,72250,1,72263,72263,5,72279,72280,7,72324,72329,1,72343,72343,7,72751,72751,7,72760,72765,5,72767,72767,5,72873,72873,7,72881,72881,7,72884,72884,7,73009,73014,5,73020,73021,5,73030,73030,1,73098,73102,7,73107,73108,7,73110,73110,7,73459,73460,5,78896,78904,4,92976,92982,5,94033,94087,7,94180,94180,5,113821,113822,5,118528,118573,5,119141,119141,5,119143,119145,5,119150,119154,5,119163,119170,5,119210,119213,5,121344,121398,5,121461,121461,5,121499,121503,5,122880,122886,5,122907,122913,5,122918,122922,5,123566,123566,5,125136,125142,5,126976,126979,14,126981,127182,14,127184,127231,14,127279,127279,14,127344,127345,14,127374,127374,14,127405,127461,14,127489,127490,14,127514,127514,14,127538,127546,14,127561,127567,14,127570,127743,14,127757,127758,14,127760,127760,14,127762,127762,14,127766,127768,14,127770,127770,14,127772,127772,14,127775,127776,14,127778,127779,14,127789,127791,14,127794,127795,14,127798,127798,14,127819,127819,14,127824,127824,14,127868,127868,14,127870,127871,14,127892,127893,14,127896,127896,14,127900,127901,14,127904,127940,14,127942,127942,14,127944,127944,14,127946,127946,14,127951,127955,14,127968,127971,14,127973,127984,14,127987,127987,14,127989,127989,14,127991,127991,14,127995,127999,5,128008,128008,14,128012,128014,14,128017,128018,14,128020,128020,14,128022,128022,14,128042,128042,14,128063,128063,14,128065,128065,14,128101,128101,14,128108,128109,14,128173,128173,14,128182,128183,14,128236,128237,14,128239,128239,14,128245,128245,14,128248,128248,14,128253,128253,14,128255,128258,14,128260,128263,14,128265,128265,14,128277,128277,14,128300,128301,14,128326,128328,14,128331,128334,14,128336,128347,14,128360,128366,14,128369,128370,14,128378,128378,14,128391,128391,14,128394,128397,14,128400,128400,14,128405,128406,14,128420,128420,14,128422,128423,14,128425,128432,14,128435,128443,14,128445,128449,14,128453,128464,14,128468,128475,14,128479,128480,14,128482,128482,14,128484,128487,14,128489,128494,14,128496,128498,14,128500,128505,14,128507,128511,14,128513,128518,14,128521,128525,14,128527,128527,14,128529,128529,14,128533,128533,14,128535,128535,14,128537,128537,14]");
}
function c2(t, e) {
  if (t === 0)
    return 0;
  const n = $i(t, e);
  if (n !== void 0)
    return n;
  const s = new g1(e, t);
  return s.prevCodePoint(), s.offset;
}
function $i(t, e) {
  const n = new g1(e, t);
  let s = n.prevCodePoint();
  for (; Hi(s) || s === 65039 || s === 8419; ) {
    if (n.offset === 0)
      return;
    s = n.prevCodePoint();
  }
  if (!Bi(s))
    return;
  let i = n.offset;
  return i > 0 && n.prevCodePoint() === 8205 && (i = n.offset), i;
}
function Hi(t) {
  return 127995 <= t && t <= 127999;
}
const d2 = " ";
class xe {
  static {
    this.ambiguousCharacterData = new Yt(() => JSON.parse('{"_common":[8232,32,8233,32,5760,32,8192,32,8193,32,8194,32,8195,32,8196,32,8197,32,8198,32,8200,32,8201,32,8202,32,8287,32,8199,32,8239,32,2042,95,65101,95,65102,95,65103,95,8208,45,8209,45,8210,45,65112,45,1748,45,8259,45,727,45,8722,45,10134,45,11450,45,1549,44,1643,44,184,44,42233,44,894,59,2307,58,2691,58,1417,58,1795,58,1796,58,5868,58,65072,58,6147,58,6153,58,8282,58,1475,58,760,58,42889,58,8758,58,720,58,42237,58,451,33,11601,33,660,63,577,63,2429,63,5038,63,42731,63,119149,46,8228,46,1793,46,1794,46,42510,46,68176,46,1632,46,1776,46,42232,46,1373,96,65287,96,8219,96,1523,96,8242,96,1370,96,8175,96,65344,96,900,96,8189,96,8125,96,8127,96,8190,96,697,96,884,96,712,96,714,96,715,96,756,96,699,96,701,96,700,96,702,96,42892,96,1497,96,2036,96,2037,96,5194,96,5836,96,94033,96,94034,96,65339,91,10088,40,10098,40,12308,40,64830,40,65341,93,10089,41,10099,41,12309,41,64831,41,10100,123,119060,123,10101,125,65342,94,8270,42,1645,42,8727,42,66335,42,5941,47,8257,47,8725,47,8260,47,9585,47,10187,47,10744,47,119354,47,12755,47,12339,47,11462,47,20031,47,12035,47,65340,92,65128,92,8726,92,10189,92,10741,92,10745,92,119311,92,119355,92,12756,92,20022,92,12034,92,42872,38,708,94,710,94,5869,43,10133,43,66203,43,8249,60,10094,60,706,60,119350,60,5176,60,5810,60,5120,61,11840,61,12448,61,42239,61,8250,62,10095,62,707,62,119351,62,5171,62,94015,62,8275,126,732,126,8128,126,8764,126,65372,124,65293,45,118002,50,120784,50,120794,50,120804,50,120814,50,120824,50,130034,50,42842,50,423,50,1000,50,42564,50,5311,50,42735,50,119302,51,118003,51,120785,51,120795,51,120805,51,120815,51,120825,51,130035,51,42923,51,540,51,439,51,42858,51,11468,51,1248,51,94011,51,71882,51,118004,52,120786,52,120796,52,120806,52,120816,52,120826,52,130036,52,5070,52,71855,52,118005,53,120787,53,120797,53,120807,53,120817,53,120827,53,130037,53,444,53,71867,53,118006,54,120788,54,120798,54,120808,54,120818,54,120828,54,130038,54,11474,54,5102,54,71893,54,119314,55,118007,55,120789,55,120799,55,120809,55,120819,55,120829,55,130039,55,66770,55,71878,55,2819,56,2538,56,2666,56,125131,56,118008,56,120790,56,120800,56,120810,56,120820,56,120830,56,130040,56,547,56,546,56,66330,56,2663,57,2920,57,2541,57,3437,57,118009,57,120791,57,120801,57,120811,57,120821,57,120831,57,130041,57,42862,57,11466,57,71884,57,71852,57,71894,57,9082,97,65345,97,119834,97,119886,97,119938,97,119990,97,120042,97,120094,97,120146,97,120198,97,120250,97,120302,97,120354,97,120406,97,120458,97,593,97,945,97,120514,97,120572,97,120630,97,120688,97,120746,97,65313,65,117974,65,119808,65,119860,65,119912,65,119964,65,120016,65,120068,65,120120,65,120172,65,120224,65,120276,65,120328,65,120380,65,120432,65,913,65,120488,65,120546,65,120604,65,120662,65,120720,65,5034,65,5573,65,42222,65,94016,65,66208,65,119835,98,119887,98,119939,98,119991,98,120043,98,120095,98,120147,98,120199,98,120251,98,120303,98,120355,98,120407,98,120459,98,388,98,5071,98,5234,98,5551,98,65314,66,8492,66,117975,66,119809,66,119861,66,119913,66,120017,66,120069,66,120121,66,120173,66,120225,66,120277,66,120329,66,120381,66,120433,66,42932,66,914,66,120489,66,120547,66,120605,66,120663,66,120721,66,5108,66,5623,66,42192,66,66178,66,66209,66,66305,66,65347,99,8573,99,119836,99,119888,99,119940,99,119992,99,120044,99,120096,99,120148,99,120200,99,120252,99,120304,99,120356,99,120408,99,120460,99,7428,99,1010,99,11429,99,43951,99,66621,99,128844,67,71913,67,71922,67,65315,67,8557,67,8450,67,8493,67,117976,67,119810,67,119862,67,119914,67,119966,67,120018,67,120174,67,120226,67,120278,67,120330,67,120382,67,120434,67,1017,67,11428,67,5087,67,42202,67,66210,67,66306,67,66581,67,66844,67,8574,100,8518,100,119837,100,119889,100,119941,100,119993,100,120045,100,120097,100,120149,100,120201,100,120253,100,120305,100,120357,100,120409,100,120461,100,1281,100,5095,100,5231,100,42194,100,8558,68,8517,68,117977,68,119811,68,119863,68,119915,68,119967,68,120019,68,120071,68,120123,68,120175,68,120227,68,120279,68,120331,68,120383,68,120435,68,5024,68,5598,68,5610,68,42195,68,8494,101,65349,101,8495,101,8519,101,119838,101,119890,101,119942,101,120046,101,120098,101,120150,101,120202,101,120254,101,120306,101,120358,101,120410,101,120462,101,43826,101,1213,101,8959,69,65317,69,8496,69,117978,69,119812,69,119864,69,119916,69,120020,69,120072,69,120124,69,120176,69,120228,69,120280,69,120332,69,120384,69,120436,69,917,69,120492,69,120550,69,120608,69,120666,69,120724,69,11577,69,5036,69,42224,69,71846,69,71854,69,66182,69,119839,102,119891,102,119943,102,119995,102,120047,102,120099,102,120151,102,120203,102,120255,102,120307,102,120359,102,120411,102,120463,102,43829,102,42905,102,383,102,7837,102,1412,102,119315,70,8497,70,117979,70,119813,70,119865,70,119917,70,120021,70,120073,70,120125,70,120177,70,120229,70,120281,70,120333,70,120385,70,120437,70,42904,70,988,70,120778,70,5556,70,42205,70,71874,70,71842,70,66183,70,66213,70,66853,70,65351,103,8458,103,119840,103,119892,103,119944,103,120048,103,120100,103,120152,103,120204,103,120256,103,120308,103,120360,103,120412,103,120464,103,609,103,7555,103,397,103,1409,103,117980,71,119814,71,119866,71,119918,71,119970,71,120022,71,120074,71,120126,71,120178,71,120230,71,120282,71,120334,71,120386,71,120438,71,1292,71,5056,71,5107,71,42198,71,65352,104,8462,104,119841,104,119945,104,119997,104,120049,104,120101,104,120153,104,120205,104,120257,104,120309,104,120361,104,120413,104,120465,104,1211,104,1392,104,5058,104,65320,72,8459,72,8460,72,8461,72,117981,72,119815,72,119867,72,119919,72,120023,72,120179,72,120231,72,120283,72,120335,72,120387,72,120439,72,919,72,120494,72,120552,72,120610,72,120668,72,120726,72,11406,72,5051,72,5500,72,42215,72,66255,72,731,105,9075,105,65353,105,8560,105,8505,105,8520,105,119842,105,119894,105,119946,105,119998,105,120050,105,120102,105,120154,105,120206,105,120258,105,120310,105,120362,105,120414,105,120466,105,120484,105,618,105,617,105,953,105,8126,105,890,105,120522,105,120580,105,120638,105,120696,105,120754,105,1110,105,42567,105,1231,105,43893,105,5029,105,71875,105,65354,106,8521,106,119843,106,119895,106,119947,106,119999,106,120051,106,120103,106,120155,106,120207,106,120259,106,120311,106,120363,106,120415,106,120467,106,1011,106,1112,106,65322,74,117983,74,119817,74,119869,74,119921,74,119973,74,120025,74,120077,74,120129,74,120181,74,120233,74,120285,74,120337,74,120389,74,120441,74,42930,74,895,74,1032,74,5035,74,5261,74,42201,74,119844,107,119896,107,119948,107,120000,107,120052,107,120104,107,120156,107,120208,107,120260,107,120312,107,120364,107,120416,107,120468,107,8490,75,65323,75,117984,75,119818,75,119870,75,119922,75,119974,75,120026,75,120078,75,120130,75,120182,75,120234,75,120286,75,120338,75,120390,75,120442,75,922,75,120497,75,120555,75,120613,75,120671,75,120729,75,11412,75,5094,75,5845,75,42199,75,66840,75,1472,108,8739,73,9213,73,65512,73,1633,108,1777,73,66336,108,125127,108,118001,108,120783,73,120793,73,120803,73,120813,73,120823,73,130033,73,65321,73,8544,73,8464,73,8465,73,117982,108,119816,73,119868,73,119920,73,120024,73,120128,73,120180,73,120232,73,120284,73,120336,73,120388,73,120440,73,65356,108,8572,73,8467,108,119845,108,119897,108,119949,108,120001,108,120053,108,120105,73,120157,73,120209,73,120261,73,120313,73,120365,73,120417,73,120469,73,448,73,120496,73,120554,73,120612,73,120670,73,120728,73,11410,73,1030,73,1216,73,1493,108,1503,108,1575,108,126464,108,126592,108,65166,108,65165,108,1994,108,11599,73,5825,73,42226,73,93992,73,66186,124,66313,124,119338,76,8556,76,8466,76,117985,76,119819,76,119871,76,119923,76,120027,76,120079,76,120131,76,120183,76,120235,76,120287,76,120339,76,120391,76,120443,76,11472,76,5086,76,5290,76,42209,76,93974,76,71843,76,71858,76,66587,76,66854,76,65325,77,8559,77,8499,77,117986,77,119820,77,119872,77,119924,77,120028,77,120080,77,120132,77,120184,77,120236,77,120288,77,120340,77,120392,77,120444,77,924,77,120499,77,120557,77,120615,77,120673,77,120731,77,1018,77,11416,77,5047,77,5616,77,5846,77,42207,77,66224,77,66321,77,119847,110,119899,110,119951,110,120003,110,120055,110,120107,110,120159,110,120211,110,120263,110,120315,110,120367,110,120419,110,120471,110,1400,110,1404,110,65326,78,8469,78,117987,78,119821,78,119873,78,119925,78,119977,78,120029,78,120081,78,120185,78,120237,78,120289,78,120341,78,120393,78,120445,78,925,78,120500,78,120558,78,120616,78,120674,78,120732,78,11418,78,42208,78,66835,78,3074,111,3202,111,3330,111,3458,111,2406,111,2662,111,2790,111,3046,111,3174,111,3302,111,3430,111,3664,111,3792,111,4160,111,1637,111,1781,111,65359,111,8500,111,119848,111,119900,111,119952,111,120056,111,120108,111,120160,111,120212,111,120264,111,120316,111,120368,111,120420,111,120472,111,7439,111,7441,111,43837,111,959,111,120528,111,120586,111,120644,111,120702,111,120760,111,963,111,120532,111,120590,111,120648,111,120706,111,120764,111,11423,111,4351,111,1413,111,1505,111,1607,111,126500,111,126564,111,126596,111,65259,111,65260,111,65258,111,65257,111,1726,111,64428,111,64429,111,64427,111,64426,111,1729,111,64424,111,64425,111,64423,111,64422,111,1749,111,3360,111,4125,111,66794,111,71880,111,71895,111,66604,111,1984,79,2534,79,2918,79,12295,79,70864,79,71904,79,118000,79,120782,79,120792,79,120802,79,120812,79,120822,79,130032,79,65327,79,117988,79,119822,79,119874,79,119926,79,119978,79,120030,79,120082,79,120134,79,120186,79,120238,79,120290,79,120342,79,120394,79,120446,79,927,79,120502,79,120560,79,120618,79,120676,79,120734,79,11422,79,1365,79,11604,79,4816,79,2848,79,66754,79,42227,79,71861,79,66194,79,66219,79,66564,79,66838,79,9076,112,65360,112,119849,112,119901,112,119953,112,120005,112,120057,112,120109,112,120161,112,120213,112,120265,112,120317,112,120369,112,120421,112,120473,112,961,112,120530,112,120544,112,120588,112,120602,112,120646,112,120660,112,120704,112,120718,112,120762,112,120776,112,11427,112,65328,80,8473,80,117989,80,119823,80,119875,80,119927,80,119979,80,120031,80,120083,80,120187,80,120239,80,120291,80,120343,80,120395,80,120447,80,929,80,120504,80,120562,80,120620,80,120678,80,120736,80,11426,80,5090,80,5229,80,42193,80,66197,80,119850,113,119902,113,119954,113,120006,113,120058,113,120110,113,120162,113,120214,113,120266,113,120318,113,120370,113,120422,113,120474,113,1307,113,1379,113,1382,113,8474,81,117990,81,119824,81,119876,81,119928,81,119980,81,120032,81,120084,81,120188,81,120240,81,120292,81,120344,81,120396,81,120448,81,11605,81,119851,114,119903,114,119955,114,120007,114,120059,114,120111,114,120163,114,120215,114,120267,114,120319,114,120371,114,120423,114,120475,114,43847,114,43848,114,7462,114,11397,114,43905,114,119318,82,8475,82,8476,82,8477,82,117991,82,119825,82,119877,82,119929,82,120033,82,120189,82,120241,82,120293,82,120345,82,120397,82,120449,82,422,82,5025,82,5074,82,66740,82,5511,82,42211,82,94005,82,65363,115,119852,115,119904,115,119956,115,120008,115,120060,115,120112,115,120164,115,120216,115,120268,115,120320,115,120372,115,120424,115,120476,115,42801,115,445,115,1109,115,43946,115,71873,115,66632,115,65331,83,117992,83,119826,83,119878,83,119930,83,119982,83,120034,83,120086,83,120138,83,120190,83,120242,83,120294,83,120346,83,120398,83,120450,83,1029,83,1359,83,5077,83,5082,83,42210,83,94010,83,66198,83,66592,83,119853,116,119905,116,119957,116,120009,116,120061,116,120113,116,120165,116,120217,116,120269,116,120321,116,120373,116,120425,116,120477,116,8868,84,10201,84,128872,84,65332,84,117993,84,119827,84,119879,84,119931,84,119983,84,120035,84,120087,84,120139,84,120191,84,120243,84,120295,84,120347,84,120399,84,120451,84,932,84,120507,84,120565,84,120623,84,120681,84,120739,84,11430,84,5026,84,42196,84,93962,84,71868,84,66199,84,66225,84,66325,84,119854,117,119906,117,119958,117,120010,117,120062,117,120114,117,120166,117,120218,117,120270,117,120322,117,120374,117,120426,117,120478,117,42911,117,7452,117,43854,117,43858,117,651,117,965,117,120534,117,120592,117,120650,117,120708,117,120766,117,1405,117,66806,117,71896,117,8746,85,8899,85,117994,85,119828,85,119880,85,119932,85,119984,85,120036,85,120088,85,120140,85,120192,85,120244,85,120296,85,120348,85,120400,85,120452,85,1357,85,4608,85,66766,85,5196,85,42228,85,94018,85,71864,85,8744,118,8897,118,65366,118,8564,118,119855,118,119907,118,119959,118,120011,118,120063,118,120115,118,120167,118,120219,118,120271,118,120323,118,120375,118,120427,118,120479,118,7456,118,957,118,120526,118,120584,118,120642,118,120700,118,120758,118,1141,118,1496,118,71430,118,43945,118,71872,118,119309,86,1639,86,1783,86,8548,86,117995,86,119829,86,119881,86,119933,86,119985,86,120037,86,120089,86,120141,86,120193,86,120245,86,120297,86,120349,86,120401,86,120453,86,1140,86,11576,86,5081,86,5167,86,42719,86,42214,86,93960,86,71840,86,66845,86,623,119,119856,119,119908,119,119960,119,120012,119,120064,119,120116,119,120168,119,120220,119,120272,119,120324,119,120376,119,120428,119,120480,119,7457,119,1121,119,1309,119,1377,119,71434,119,71438,119,71439,119,43907,119,71910,87,71919,87,117996,87,119830,87,119882,87,119934,87,119986,87,120038,87,120090,87,120142,87,120194,87,120246,87,120298,87,120350,87,120402,87,120454,87,1308,87,5043,87,5076,87,42218,87,5742,120,10539,120,10540,120,10799,120,65368,120,8569,120,119857,120,119909,120,119961,120,120013,120,120065,120,120117,120,120169,120,120221,120,120273,120,120325,120,120377,120,120429,120,120481,120,5441,120,5501,120,5741,88,9587,88,66338,88,71916,88,65336,88,8553,88,117997,88,119831,88,119883,88,119935,88,119987,88,120039,88,120091,88,120143,88,120195,88,120247,88,120299,88,120351,88,120403,88,120455,88,42931,88,935,88,120510,88,120568,88,120626,88,120684,88,120742,88,11436,88,11613,88,5815,88,42219,88,66192,88,66228,88,66327,88,66855,88,611,121,7564,121,65369,121,119858,121,119910,121,119962,121,120014,121,120066,121,120118,121,120170,121,120222,121,120274,121,120326,121,120378,121,120430,121,120482,121,655,121,7935,121,43866,121,947,121,8509,121,120516,121,120574,121,120632,121,120690,121,120748,121,1199,121,4327,121,71900,121,65337,89,117998,89,119832,89,119884,89,119936,89,119988,89,120040,89,120092,89,120144,89,120196,89,120248,89,120300,89,120352,89,120404,89,120456,89,933,89,978,89,120508,89,120566,89,120624,89,120682,89,120740,89,11432,89,1198,89,5033,89,5053,89,42220,89,94019,89,71844,89,66226,89,119859,122,119911,122,119963,122,120015,122,120067,122,120119,122,120171,122,120223,122,120275,122,120327,122,120379,122,120431,122,120483,122,7458,122,43923,122,71876,122,71909,90,66293,90,65338,90,8484,90,8488,90,117999,90,119833,90,119885,90,119937,90,119989,90,120041,90,120197,90,120249,90,120301,90,120353,90,120405,90,120457,90,918,90,120493,90,120551,90,120609,90,120667,90,120725,90,5059,90,42204,90,71849,90,65282,34,65283,35,65284,36,65285,37,65286,38,65290,42,65291,43,65294,46,65295,47,65296,48,65298,50,65299,51,65300,52,65301,53,65302,54,65303,55,65304,56,65305,57,65308,60,65309,61,65310,62,65312,64,65316,68,65318,70,65319,71,65324,76,65329,81,65330,82,65333,85,65334,86,65335,87,65343,95,65346,98,65348,100,65350,102,65355,107,65357,109,65358,110,65361,113,65362,114,65364,116,65365,117,65367,119,65370,122,65371,123,65373,125,119846,109],"_default":[160,32,8211,45,65374,126,8218,44,65306,58,65281,33,8216,96,8217,96,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"cs":[65374,126,8218,44,65306,58,65281,33,8216,96,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"de":[65374,126,65306,58,65281,33,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"es":[8211,45,65374,126,8218,44,65306,58,65281,33,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"fr":[65374,126,8218,44,65306,58,65281,33,8216,96,8245,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"it":[160,32,8211,45,65374,126,8218,44,65306,58,65281,33,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"ja":[8211,45,8218,44,65281,33,8216,96,8245,96,180,96,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65292,44,65297,49,65307,59],"ko":[8211,45,65374,126,8218,44,65306,58,65281,33,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"pl":[65374,126,65306,58,65281,33,8216,96,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"pt-BR":[65374,126,8218,44,65306,58,65281,33,8216,96,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"qps-ploc":[160,32,8211,45,65374,126,8218,44,65306,58,65281,33,8216,96,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"ru":[65374,126,8218,44,65306,58,65281,33,8216,96,8245,96,180,96,12494,47,305,105,921,73,1009,112,215,120,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"tr":[160,32,8211,45,65374,126,8218,44,65306,58,65281,33,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65288,40,65289,41,65292,44,65297,49,65307,59,65311,63],"zh-hans":[160,32,65374,126,8218,44,8245,96,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89,65297,49],"zh-hant":[8211,45,65374,126,8218,44,180,96,12494,47,1047,51,1073,54,1072,97,1040,65,1068,98,1042,66,1089,99,1057,67,1077,101,1045,69,1053,72,305,105,1050,75,921,73,1052,77,1086,111,1054,79,1009,112,1088,112,1056,80,1075,114,1058,84,215,120,1093,120,1061,88,1091,121,1059,89]}'));
  }
  static {
    this.cache = new Di({ getCacheKey: JSON.stringify }, (e) => {
      function n(d) {
        const c = /* @__PURE__ */ new Map();
        for (let p = 0; p < d.length; p += 2)
          c.set(d[p], d[p + 1]);
        return c;
      }
      function s(d, c) {
        const p = new Map(d);
        for (const [O, V] of c)
          p.set(O, V);
        return p;
      }
      function i(d, c) {
        if (!d)
          return c;
        const p = /* @__PURE__ */ new Map();
        for (const [O, V] of d)
          c.has(O) && p.set(O, V);
        return p;
      }
      const r = this.ambiguousCharacterData.value;
      let o = e.filter((d) => !d.startsWith("_") && Object.hasOwn(r, d));
      o.length === 0 && (o = ["_default"]);
      let a;
      for (const d of o) {
        const c = n(r[d]);
        a = i(a, c);
      }
      const u = n(r._common), l = s(u, a);
      return new xe(l);
    });
  }
  static getInstance(e) {
    return xe.cache.get(Array.from(e));
  }
  static {
    this._locales = new Yt(() => Object.keys(xe.ambiguousCharacterData.value).filter((e) => !e.startsWith("_")));
  }
  static getLocales() {
    return xe._locales.value;
  }
  constructor(e) {
    this.confusableDictionary = e;
  }
  isAmbiguous(e) {
    return this.confusableDictionary.has(e);
  }
  /**
   * Returns the non basic ASCII code point that the given code point can be confused,
   * or undefined if such code point does note exist.
   */
  getPrimaryConfusable(e) {
    return this.confusableDictionary.get(e);
  }
  getConfusableCodePoints() {
    return new Set(this.confusableDictionary.keys());
  }
}
class ct {
  static getRawData() {
    return JSON.parse('{"_common":[11,12,13,127,847,1564,4447,4448,6068,6069,6155,6156,6157,6158,7355,7356,8192,8193,8194,8195,8196,8197,8198,8199,8200,8201,8202,8204,8205,8206,8207,8234,8235,8236,8237,8238,8239,8287,8288,8289,8290,8291,8292,8293,8294,8295,8296,8297,8298,8299,8300,8301,8302,8303,10240,12644,65024,65025,65026,65027,65028,65029,65030,65031,65032,65033,65034,65035,65036,65037,65038,65039,65279,65440,65520,65521,65522,65523,65524,65525,65526,65527,65528,65532,78844,119155,119156,119157,119158,119159,119160,119161,119162,917504,917505,917506,917507,917508,917509,917510,917511,917512,917513,917514,917515,917516,917517,917518,917519,917520,917521,917522,917523,917524,917525,917526,917527,917528,917529,917530,917531,917532,917533,917534,917535,917536,917537,917538,917539,917540,917541,917542,917543,917544,917545,917546,917547,917548,917549,917550,917551,917552,917553,917554,917555,917556,917557,917558,917559,917560,917561,917562,917563,917564,917565,917566,917567,917568,917569,917570,917571,917572,917573,917574,917575,917576,917577,917578,917579,917580,917581,917582,917583,917584,917585,917586,917587,917588,917589,917590,917591,917592,917593,917594,917595,917596,917597,917598,917599,917600,917601,917602,917603,917604,917605,917606,917607,917608,917609,917610,917611,917612,917613,917614,917615,917616,917617,917618,917619,917620,917621,917622,917623,917624,917625,917626,917627,917628,917629,917630,917631,917760,917761,917762,917763,917764,917765,917766,917767,917768,917769,917770,917771,917772,917773,917774,917775,917776,917777,917778,917779,917780,917781,917782,917783,917784,917785,917786,917787,917788,917789,917790,917791,917792,917793,917794,917795,917796,917797,917798,917799,917800,917801,917802,917803,917804,917805,917806,917807,917808,917809,917810,917811,917812,917813,917814,917815,917816,917817,917818,917819,917820,917821,917822,917823,917824,917825,917826,917827,917828,917829,917830,917831,917832,917833,917834,917835,917836,917837,917838,917839,917840,917841,917842,917843,917844,917845,917846,917847,917848,917849,917850,917851,917852,917853,917854,917855,917856,917857,917858,917859,917860,917861,917862,917863,917864,917865,917866,917867,917868,917869,917870,917871,917872,917873,917874,917875,917876,917877,917878,917879,917880,917881,917882,917883,917884,917885,917886,917887,917888,917889,917890,917891,917892,917893,917894,917895,917896,917897,917898,917899,917900,917901,917902,917903,917904,917905,917906,917907,917908,917909,917910,917911,917912,917913,917914,917915,917916,917917,917918,917919,917920,917921,917922,917923,917924,917925,917926,917927,917928,917929,917930,917931,917932,917933,917934,917935,917936,917937,917938,917939,917940,917941,917942,917943,917944,917945,917946,917947,917948,917949,917950,917951,917952,917953,917954,917955,917956,917957,917958,917959,917960,917961,917962,917963,917964,917965,917966,917967,917968,917969,917970,917971,917972,917973,917974,917975,917976,917977,917978,917979,917980,917981,917982,917983,917984,917985,917986,917987,917988,917989,917990,917991,917992,917993,917994,917995,917996,917997,917998,917999],"cs":[173,8203,12288],"de":[173,8203,12288],"es":[8203,12288],"fr":[173,8203,12288],"it":[160,173,12288],"ja":[173],"ko":[173,12288],"pl":[173,8203,12288],"pt-BR":[173,8203,12288],"qps-ploc":[160,173,8203,12288],"ru":[173,12288],"tr":[160,173,8203,12288],"zh-hans":[160,173,8203,12288],"zh-hant":[173,12288]}');
  }
  static {
    this._data = void 0;
  }
  static getData() {
    return this._data || (this._data = new Set([...Object.values(ct.getRawData())].flat())), this._data;
  }
  static isInvisibleCharacter(e) {
    return ct.getData().has(e);
  }
  static get codePoints() {
    return ct.getData();
  }
}
const qi = 65, Gi = 97, ji = 90, zi = 122, Se = 46, N = 47, j = 92, oe = 58, Qi = 63;
class An extends Error {
  constructor(e, n, s) {
    let i;
    typeof n == "string" && n.indexOf("not ") === 0 ? (i = "must not be", n = n.replace(/^not /, "")) : i = "must be";
    const r = e.indexOf(".") !== -1 ? "property" : "argument";
    let o = `The "${e}" ${r} ${i} of type ${n}`;
    o += `. Received type ${typeof s}`, super(o), this.code = "ERR_INVALID_ARG_TYPE";
  }
}
function Yi(t, e) {
  if (t === null || typeof t != "object")
    throw new An(e, "Object", t);
}
function T(t, e) {
  if (typeof t != "string")
    throw new An(e, "string", t);
}
const ge = ni === "win32";
function C(t) {
  return t === N || t === j;
}
function Xt(t) {
  return t === N;
}
function ae(t) {
  return t >= qi && t <= ji || t >= Gi && t <= zi;
}
function gt(t, e, n, s) {
  let i = "", r = 0, o = -1, a = 0, u = 0;
  for (let l = 0; l <= t.length; ++l) {
    if (l < t.length)
      u = t.charCodeAt(l);
    else {
      if (s(u))
        break;
      u = N;
    }
    if (s(u)) {
      if (!(o === l - 1 || a === 1)) if (a === 2) {
        if (i.length < 2 || r !== 2 || i.charCodeAt(i.length - 1) !== Se || i.charCodeAt(i.length - 2) !== Se) {
          if (i.length > 2) {
            const d = i.lastIndexOf(n);
            d === -1 ? (i = "", r = 0) : (i = i.slice(0, d), r = i.length - 1 - i.lastIndexOf(n)), o = l, a = 0;
            continue;
          } else if (i.length !== 0) {
            i = "", r = 0, o = l, a = 0;
            continue;
          }
        }
        e && (i += i.length > 0 ? `${n}..` : "..", r = 2);
      } else
        i.length > 0 ? i += `${n}${t.slice(o + 1, l)}` : i = t.slice(o + 1, l), r = l - o - 1;
      o = l, a = 0;
    } else u === Se && a !== -1 ? ++a : a = -1;
  }
  return i;
}
function Xi(t) {
  return t ? `${t[0] === "." ? "" : "."}${t}` : "";
}
function Sn(t, e) {
  Yi(e, "pathObject");
  const n = e.dir || e.root, s = e.base || `${e.name || ""}${Xi(e.ext)}`;
  return n ? n === e.root ? `${n}${s}` : `${n}${t}${s}` : s;
}
const $ = {
  // path.resolve([from ...], to)
  resolve(...t) {
    let e = "", n = "", s = !1;
    for (let i = t.length - 1; i >= -1; i--) {
      let r;
      if (i >= 0) {
        if (r = t[i], T(r, `paths[${i}]`), r.length === 0)
          continue;
      } else e.length === 0 ? r = yt() : (r = Gt[`=${e}`] || yt(), (r === void 0 || r.slice(0, 2).toLowerCase() !== e.toLowerCase() && r.charCodeAt(2) === j) && (r = `${e}\\`));
      const o = r.length;
      let a = 0, u = "", l = !1;
      const d = r.charCodeAt(0);
      if (o === 1)
        C(d) && (a = 1, l = !0);
      else if (C(d))
        if (l = !0, C(r.charCodeAt(1))) {
          let c = 2, p = c;
          for (; c < o && !C(r.charCodeAt(c)); )
            c++;
          if (c < o && c !== p) {
            const O = r.slice(p, c);
            for (p = c; c < o && C(r.charCodeAt(c)); )
              c++;
            if (c < o && c !== p) {
              for (p = c; c < o && !C(r.charCodeAt(c)); )
                c++;
              (c === o || c !== p) && (u = `\\\\${O}\\${r.slice(p, c)}`, a = c);
            }
          }
        } else
          a = 1;
      else ae(d) && r.charCodeAt(1) === oe && (u = r.slice(0, 2), a = 2, o > 2 && C(r.charCodeAt(2)) && (l = !0, a = 3));
      if (u.length > 0)
        if (e.length > 0) {
          if (u.toLowerCase() !== e.toLowerCase())
            continue;
        } else
          e = u;
      if (s) {
        if (e.length > 0)
          break;
      } else if (n = `${r.slice(a)}\\${n}`, s = l, l && e.length > 0)
        break;
    }
    return n = gt(n, !s, "\\", C), s ? `${e}\\${n}` : `${e}${n}` || ".";
  },
  normalize(t) {
    T(t, "path");
    const e = t.length;
    if (e === 0)
      return ".";
    let n = 0, s, i = !1;
    const r = t.charCodeAt(0);
    if (e === 1)
      return Xt(r) ? "\\" : t;
    if (C(r))
      if (i = !0, C(t.charCodeAt(1))) {
        let a = 2, u = a;
        for (; a < e && !C(t.charCodeAt(a)); )
          a++;
        if (a < e && a !== u) {
          const l = t.slice(u, a);
          for (u = a; a < e && C(t.charCodeAt(a)); )
            a++;
          if (a < e && a !== u) {
            for (u = a; a < e && !C(t.charCodeAt(a)); )
              a++;
            if (a === e)
              return `\\\\${l}\\${t.slice(u)}\\`;
            a !== u && (s = `\\\\${l}\\${t.slice(u, a)}`, n = a);
          }
        }
      } else
        n = 1;
    else ae(r) && t.charCodeAt(1) === oe && (s = t.slice(0, 2), n = 2, e > 2 && C(t.charCodeAt(2)) && (i = !0, n = 3));
    let o = n < e ? gt(t.slice(n), !i, "\\", C) : "";
    if (o.length === 0 && !i && (o = "."), o.length > 0 && C(t.charCodeAt(e - 1)) && (o += "\\"), !i && s === void 0 && t.includes(":")) {
      if (o.length >= 2 && ae(o.charCodeAt(0)) && o.charCodeAt(1) === oe)
        return `.\\${o}`;
      let a = t.indexOf(":");
      do
        if (a === e - 1 || C(t.charCodeAt(a + 1)))
          return `.\\${o}`;
      while ((a = t.indexOf(":", a + 1)) !== -1);
    }
    return s === void 0 ? i ? `\\${o}` : o : i ? `${s}\\${o}` : `${s}${o}`;
  },
  isAbsolute(t) {
    T(t, "path");
    const e = t.length;
    if (e === 0)
      return !1;
    const n = t.charCodeAt(0);
    return C(n) || // Possible device root
    e > 2 && ae(n) && t.charCodeAt(1) === oe && C(t.charCodeAt(2));
  },
  join(...t) {
    if (t.length === 0)
      return ".";
    let e, n;
    for (let r = 0; r < t.length; ++r) {
      const o = t[r];
      T(o, "path"), o.length > 0 && (e === void 0 ? e = n = o : e += `\\${o}`);
    }
    if (e === void 0)
      return ".";
    let s = !0, i = 0;
    if (typeof n == "string" && C(n.charCodeAt(0))) {
      ++i;
      const r = n.length;
      r > 1 && C(n.charCodeAt(1)) && (++i, r > 2 && (C(n.charCodeAt(2)) ? ++i : s = !1));
    }
    if (s) {
      for (; i < e.length && C(e.charCodeAt(i)); )
        i++;
      i >= 2 && (e = `\\${e.slice(i)}`);
    }
    return $.normalize(e);
  },
  // It will solve the relative path from `from` to `to`, for instance:
  //  from = 'C:\\orandea\\test\\aaa'
  //  to = 'C:\\orandea\\impl\\bbb'
  // The output of the function should be: '..\\..\\impl\\bbb'
  relative(t, e) {
    if (T(t, "from"), T(e, "to"), t === e)
      return "";
    const n = $.resolve(t), s = $.resolve(e);
    if (n === s || (t = n.toLowerCase(), e = s.toLowerCase(), t === e))
      return "";
    if (n.length !== t.length || s.length !== e.length) {
      const V = n.split("\\"), Z = s.split("\\");
      V[V.length - 1] === "" && V.pop(), Z[Z.length - 1] === "" && Z.pop();
      const re = V.length, be = Z.length, J = re < be ? re : be;
      let W;
      for (W = 0; W < J && V[W].toLowerCase() === Z[W].toLowerCase(); W++)
        ;
      return W === 0 ? s : W === J ? be > J ? Z.slice(W).join("\\") : re > J ? "..\\".repeat(re - 1 - W) + ".." : "" : "..\\".repeat(re - W) + Z.slice(W).join("\\");
    }
    let i = 0;
    for (; i < t.length && t.charCodeAt(i) === j; )
      i++;
    let r = t.length;
    for (; r - 1 > i && t.charCodeAt(r - 1) === j; )
      r--;
    const o = r - i;
    let a = 0;
    for (; a < e.length && e.charCodeAt(a) === j; )
      a++;
    let u = e.length;
    for (; u - 1 > a && e.charCodeAt(u - 1) === j; )
      u--;
    const l = u - a, d = o < l ? o : l;
    let c = -1, p = 0;
    for (; p < d; p++) {
      const V = t.charCodeAt(i + p);
      if (V !== e.charCodeAt(a + p))
        break;
      V === j && (c = p);
    }
    if (p !== d) {
      if (c === -1)
        return s;
    } else {
      if (l > d) {
        if (e.charCodeAt(a + p) === j)
          return s.slice(a + p + 1);
        if (p === 2)
          return s.slice(a + p);
      }
      o > d && (t.charCodeAt(i + p) === j ? c = p : p === 2 && (c = 3)), c === -1 && (c = 0);
    }
    let O = "";
    for (p = i + c + 1; p <= r; ++p)
      (p === r || t.charCodeAt(p) === j) && (O += O.length === 0 ? ".." : "\\..");
    return a += c, O.length > 0 ? `${O}${s.slice(a, u)}` : (s.charCodeAt(a) === j && ++a, s.slice(a, u));
  },
  toNamespacedPath(t) {
    if (typeof t != "string" || t.length === 0)
      return t;
    const e = $.resolve(t);
    if (e.length <= 2)
      return t;
    if (e.charCodeAt(0) === j) {
      if (e.charCodeAt(1) === j) {
        const n = e.charCodeAt(2);
        if (n !== Qi && n !== Se)
          return `\\\\?\\UNC\\${e.slice(2)}`;
      }
    } else if (ae(e.charCodeAt(0)) && e.charCodeAt(1) === oe && e.charCodeAt(2) === j)
      return `\\\\?\\${e}`;
    return e;
  },
  dirname(t) {
    T(t, "path");
    const e = t.length;
    if (e === 0)
      return ".";
    let n = -1, s = 0;
    const i = t.charCodeAt(0);
    if (e === 1)
      return C(i) ? t : ".";
    if (C(i)) {
      if (n = s = 1, C(t.charCodeAt(1))) {
        let a = 2, u = a;
        for (; a < e && !C(t.charCodeAt(a)); )
          a++;
        if (a < e && a !== u) {
          for (u = a; a < e && C(t.charCodeAt(a)); )
            a++;
          if (a < e && a !== u) {
            for (u = a; a < e && !C(t.charCodeAt(a)); )
              a++;
            if (a === e)
              return t;
            a !== u && (n = s = a + 1);
          }
        }
      }
    } else ae(i) && t.charCodeAt(1) === oe && (n = e > 2 && C(t.charCodeAt(2)) ? 3 : 2, s = n);
    let r = -1, o = !0;
    for (let a = e - 1; a >= s; --a)
      if (C(t.charCodeAt(a))) {
        if (!o) {
          r = a;
          break;
        }
      } else
        o = !1;
    if (r === -1) {
      if (n === -1)
        return ".";
      r = n;
    }
    return t.slice(0, r);
  },
  basename(t, e) {
    e !== void 0 && T(e, "suffix"), T(t, "path");
    let n = 0, s = -1, i = !0, r;
    if (t.length >= 2 && ae(t.charCodeAt(0)) && t.charCodeAt(1) === oe && (n = 2), e !== void 0 && e.length > 0 && e.length <= t.length) {
      if (e === t)
        return "";
      let o = e.length - 1, a = -1;
      for (r = t.length - 1; r >= n; --r) {
        const u = t.charCodeAt(r);
        if (C(u)) {
          if (!i) {
            n = r + 1;
            break;
          }
        } else
          a === -1 && (i = !1, a = r + 1), o >= 0 && (u === e.charCodeAt(o) ? --o === -1 && (s = r) : (o = -1, s = a));
      }
      return n === s ? s = a : s === -1 && (s = t.length), t.slice(n, s);
    }
    for (r = t.length - 1; r >= n; --r)
      if (C(t.charCodeAt(r))) {
        if (!i) {
          n = r + 1;
          break;
        }
      } else s === -1 && (i = !1, s = r + 1);
    return s === -1 ? "" : t.slice(n, s);
  },
  extname(t) {
    T(t, "path");
    let e = 0, n = -1, s = 0, i = -1, r = !0, o = 0;
    t.length >= 2 && t.charCodeAt(1) === oe && ae(t.charCodeAt(0)) && (e = s = 2);
    for (let a = t.length - 1; a >= e; --a) {
      const u = t.charCodeAt(a);
      if (C(u)) {
        if (!r) {
          s = a + 1;
          break;
        }
        continue;
      }
      i === -1 && (r = !1, i = a + 1), u === Se ? n === -1 ? n = a : o !== 1 && (o = 1) : n !== -1 && (o = -1);
    }
    return n === -1 || i === -1 || // We saw a non-dot character immediately before the dot
    o === 0 || // The (right-most) trimmed path component is exactly '..'
    o === 1 && n === i - 1 && n === s + 1 ? "" : t.slice(n, i);
  },
  format: Sn.bind(null, "\\"),
  parse(t) {
    T(t, "path");
    const e = { root: "", dir: "", base: "", ext: "", name: "" };
    if (t.length === 0)
      return e;
    const n = t.length;
    let s = 0, i = t.charCodeAt(0);
    if (n === 1)
      return C(i) ? (e.root = e.dir = t, e) : (e.base = e.name = t, e);
    if (C(i)) {
      if (s = 1, C(t.charCodeAt(1))) {
        let c = 2, p = c;
        for (; c < n && !C(t.charCodeAt(c)); )
          c++;
        if (c < n && c !== p) {
          for (p = c; c < n && C(t.charCodeAt(c)); )
            c++;
          if (c < n && c !== p) {
            for (p = c; c < n && !C(t.charCodeAt(c)); )
              c++;
            c === n ? s = c : c !== p && (s = c + 1);
          }
        }
      }
    } else if (ae(i) && t.charCodeAt(1) === oe) {
      if (n <= 2)
        return e.root = e.dir = t, e;
      if (s = 2, C(t.charCodeAt(2))) {
        if (n === 3)
          return e.root = e.dir = t, e;
        s = 3;
      }
    }
    s > 0 && (e.root = t.slice(0, s));
    let r = -1, o = s, a = -1, u = !0, l = t.length - 1, d = 0;
    for (; l >= s; --l) {
      if (i = t.charCodeAt(l), C(i)) {
        if (!u) {
          o = l + 1;
          break;
        }
        continue;
      }
      a === -1 && (u = !1, a = l + 1), i === Se ? r === -1 ? r = l : d !== 1 && (d = 1) : r !== -1 && (d = -1);
    }
    return a !== -1 && (r === -1 || // We saw a non-dot character immediately before the dot
    d === 0 || // The (right-most) trimmed path component is exactly '..'
    d === 1 && r === a - 1 && r === o + 1 ? e.base = e.name = t.slice(o, a) : (e.name = t.slice(o, r), e.base = t.slice(o, a), e.ext = t.slice(r, a))), o > 0 && o !== s ? e.dir = t.slice(0, o - 1) : e.dir = e.root, e;
  },
  sep: "\\",
  delimiter: ";",
  win32: null,
  posix: null
}, Zi = (() => {
  if (ge) {
    const t = /\\/g;
    return () => {
      const e = yt().replace(t, "/");
      return e.slice(e.indexOf("/"));
    };
  }
  return () => yt();
})(), H = {
  // path.resolve([from ...], to)
  resolve(...t) {
    let e = "", n = !1;
    for (let s = t.length - 1; s >= 0 && !n; s--) {
      const i = t[s];
      T(i, `paths[${s}]`), i.length !== 0 && (e = `${i}/${e}`, n = i.charCodeAt(0) === N);
    }
    if (!n) {
      const s = Zi();
      e = `${s}/${e}`, n = s.charCodeAt(0) === N;
    }
    return e = gt(e, !n, "/", Xt), n ? `/${e}` : e.length > 0 ? e : ".";
  },
  normalize(t) {
    if (T(t, "path"), t.length === 0)
      return ".";
    const e = t.charCodeAt(0) === N, n = t.charCodeAt(t.length - 1) === N;
    return t = gt(t, !e, "/", Xt), t.length === 0 ? e ? "/" : n ? "./" : "." : (n && (t += "/"), e ? `/${t}` : t);
  },
  isAbsolute(t) {
    return T(t, "path"), t.length > 0 && t.charCodeAt(0) === N;
  },
  join(...t) {
    if (t.length === 0)
      return ".";
    const e = [];
    for (let n = 0; n < t.length; ++n) {
      const s = t[n];
      T(s, "path"), s.length > 0 && e.push(s);
    }
    return e.length === 0 ? "." : H.normalize(e.join("/"));
  },
  relative(t, e) {
    if (T(t, "from"), T(e, "to"), t === e || (t = H.resolve(t), e = H.resolve(e), t === e))
      return "";
    const n = 1, s = t.length, i = s - n, r = 1, o = e.length - r, a = i < o ? i : o;
    let u = -1, l = 0;
    for (; l < a; l++) {
      const c = t.charCodeAt(n + l);
      if (c !== e.charCodeAt(r + l))
        break;
      c === N && (u = l);
    }
    if (l === a)
      if (o > a) {
        if (e.charCodeAt(r + l) === N)
          return e.slice(r + l + 1);
        if (l === 0)
          return e.slice(r + l);
      } else i > a && (t.charCodeAt(n + l) === N ? u = l : l === 0 && (u = 0));
    let d = "";
    for (l = n + u + 1; l <= s; ++l)
      (l === s || t.charCodeAt(l) === N) && (d += d.length === 0 ? ".." : "/..");
    return `${d}${e.slice(r + u)}`;
  },
  toNamespacedPath(t) {
    return t;
  },
  dirname(t) {
    if (T(t, "path"), t.length === 0)
      return ".";
    const e = t.charCodeAt(0) === N;
    let n = -1, s = !0;
    for (let i = t.length - 1; i >= 1; --i)
      if (t.charCodeAt(i) === N) {
        if (!s) {
          n = i;
          break;
        }
      } else
        s = !1;
    return n === -1 ? e ? "/" : "." : e && n === 1 ? "//" : t.slice(0, n);
  },
  basename(t, e) {
    e !== void 0 && T(e, "suffix"), T(t, "path");
    let n = 0, s = -1, i = !0, r;
    if (e !== void 0 && e.length > 0 && e.length <= t.length) {
      if (e === t)
        return "";
      let o = e.length - 1, a = -1;
      for (r = t.length - 1; r >= 0; --r) {
        const u = t.charCodeAt(r);
        if (u === N) {
          if (!i) {
            n = r + 1;
            break;
          }
        } else
          a === -1 && (i = !1, a = r + 1), o >= 0 && (u === e.charCodeAt(o) ? --o === -1 && (s = r) : (o = -1, s = a));
      }
      return n === s ? s = a : s === -1 && (s = t.length), t.slice(n, s);
    }
    for (r = t.length - 1; r >= 0; --r)
      if (t.charCodeAt(r) === N) {
        if (!i) {
          n = r + 1;
          break;
        }
      } else s === -1 && (i = !1, s = r + 1);
    return s === -1 ? "" : t.slice(n, s);
  },
  extname(t) {
    T(t, "path");
    let e = -1, n = 0, s = -1, i = !0, r = 0;
    for (let o = t.length - 1; o >= 0; --o) {
      const a = t[o];
      if (a === "/") {
        if (!i) {
          n = o + 1;
          break;
        }
        continue;
      }
      s === -1 && (i = !1, s = o + 1), a === "." ? e === -1 ? e = o : r !== 1 && (r = 1) : e !== -1 && (r = -1);
    }
    return e === -1 || s === -1 || // We saw a non-dot character immediately before the dot
    r === 0 || // The (right-most) trimmed path component is exactly '..'
    r === 1 && e === s - 1 && e === n + 1 ? "" : t.slice(e, s);
  },
  format: Sn.bind(null, "/"),
  parse(t) {
    T(t, "path");
    const e = { root: "", dir: "", base: "", ext: "", name: "" };
    if (t.length === 0)
      return e;
    const n = t.charCodeAt(0) === N;
    let s;
    n ? (e.root = "/", s = 1) : s = 0;
    let i = -1, r = 0, o = -1, a = !0, u = t.length - 1, l = 0;
    for (; u >= s; --u) {
      const d = t.charCodeAt(u);
      if (d === N) {
        if (!a) {
          r = u + 1;
          break;
        }
        continue;
      }
      o === -1 && (a = !1, o = u + 1), d === Se ? i === -1 ? i = u : l !== 1 && (l = 1) : i !== -1 && (l = -1);
    }
    if (o !== -1) {
      const d = r === 0 && n ? 1 : r;
      i === -1 || // We saw a non-dot character immediately before the dot
      l === 0 || // The (right-most) trimmed path component is exactly '..'
      l === 1 && i === o - 1 && i === r + 1 ? e.base = e.name = t.slice(d, o) : (e.name = t.slice(d, i), e.base = t.slice(d, o), e.ext = t.slice(i, o));
    }
    return r > 0 ? e.dir = t.slice(0, r - 1) : n && (e.dir = "/"), e;
  },
  sep: "/",
  delimiter: ":",
  win32: null,
  posix: null
};
H.win32 = $.win32 = $;
H.posix = $.posix = H;
const f2 = ge ? $.normalize : H.normalize, h2 = ge ? $.resolve : H.resolve, p2 = ge ? $.relative : H.relative, m2 = ge ? $.dirname : H.dirname, _2 = ge ? $.basename : H.basename, y2 = ge ? $.extname : H.extname, g2 = ge ? $.sep : H.sep, Ji = /^\w[\w\d+.-]*$/, er = /^\//, tr = /^\/\//;
function nr(t, e) {
  if (!t.scheme && e)
    throw new Error(`[UriError]: Scheme is missing: {scheme: "", authority: "${t.authority}", path: "${t.path}", query: "${t.query}", fragment: "${t.fragment}"}`);
  if (t.scheme && !Ji.test(t.scheme))
    throw new Error("[UriError]: Scheme contains illegal characters.");
  if (t.path) {
    if (t.authority) {
      if (!er.test(t.path))
        throw new Error('[UriError]: If a URI contains an authority component, then the path component must either be empty or begin with a slash ("/") character');
    } else if (tr.test(t.path))
      throw new Error('[UriError]: If a URI does not contain an authority component, then the path cannot begin with two slash characters ("//")');
  }
}
function sr(t, e) {
  return !t && !e ? "file" : t;
}
function ir(t, e) {
  switch (t) {
    case "https":
    case "http":
    case "file":
      e ? e[0] !== ee && (e = ee + e) : e = ee;
      break;
  }
  return e;
}
const S = "", ee = "/", rr = /^(([^:/?#]+?):)?(\/\/([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/;
class me {
  static isUri(e) {
    return e instanceof me ? !0 : !e || typeof e != "object" ? !1 : typeof e.authority == "string" && typeof e.fragment == "string" && typeof e.path == "string" && typeof e.query == "string" && typeof e.scheme == "string" && typeof e.fsPath == "string" && typeof e.with == "function" && typeof e.toString == "function";
  }
  /**
   * @internal
   */
  constructor(e, n, s, i, r, o = !1) {
    typeof e == "object" ? (this.scheme = e.scheme || S, this.authority = e.authority || S, this.path = e.path || S, this.query = e.query || S, this.fragment = e.fragment || S) : (this.scheme = sr(e, o), this.authority = n || S, this.path = ir(this.scheme, s || S), this.query = i || S, this.fragment = r || S, nr(this, o));
  }
  // ---- filesystem path -----------------------
  /**
   * Returns a string representing the corresponding file system path of this URI.
   * Will handle UNC paths, normalizes windows drive letters to lower-case, and uses the
   * platform specific path separator.
   *
   * * Will *not* validate the path for invalid characters and semantics.
   * * Will *not* look at the scheme of this URI.
   * * The result shall *not* be used for display purposes but for accessing a file on disk.
   *
   *
   * The *difference* to `URI#path` is the use of the platform specific separator and the handling
   * of UNC paths. See the below sample of a file-uri with an authority (UNC path).
   *
   * ```ts
      const u = URI.parse('file://server/c$/folder/file.txt')
      u.authority === 'server'
      u.path === '/shares/c$/file.txt'
      u.fsPath === '\\server\c$\folder\file.txt'
  ```
   *
   * Using `URI#path` to read a file (using fs-apis) would not be enough because parts of the path,
   * namely the server name, would be missing. Therefore `URI#fsPath` exists - it's sugar to ease working
   * with URIs that represent files on disk (`file` scheme).
   */
  get fsPath() {
    return Zt(this, !1);
  }
  // ---- modify to new -------------------------
  with(e) {
    if (!e)
      return this;
    let { scheme: n, authority: s, path: i, query: r, fragment: o } = e;
    return n === void 0 ? n = this.scheme : n === null && (n = S), s === void 0 ? s = this.authority : s === null && (s = S), i === void 0 ? i = this.path : i === null && (i = S), r === void 0 ? r = this.query : r === null && (r = S), o === void 0 ? o = this.fragment : o === null && (o = S), n === this.scheme && s === this.authority && i === this.path && r === this.query && o === this.fragment ? this : new Oe(n, s, i, r, o);
  }
  // ---- parse & validate ------------------------
  /**
   * Creates a new URI from a string, e.g. `http://www.example.com/some/path`,
   * `file:///usr/home`, or `scheme:with/path`.
   *
   * @param value A string which represents an URI (see `URI#toString`).
   */
  static parse(e, n = !1) {
    const s = rr.exec(e);
    return s ? new Oe(s[2] || S, it(s[4] || S), it(s[5] || S), it(s[7] || S), it(s[9] || S), n) : new Oe(S, S, S, S, S);
  }
  /**
   * Creates a new URI from a file system path, e.g. `c:\my\files`,
   * `/usr/home`, or `\\server\share\some\path`.
   *
   * The *difference* between `URI#parse` and `URI#file` is that the latter treats the argument
   * as path, not as stringified-uri. E.g. `URI.file(path)` is **not the same as**
   * `URI.parse('file://' + path)` because the path might contain characters that are
   * interpreted (# and ?). See the following sample:
   * ```ts
  const good = URI.file('/coding/c#/project1');
  good.scheme === 'file';
  good.path === '/coding/c#/project1';
  good.fragment === '';
  const bad = URI.parse('file://' + '/coding/c#/project1');
  bad.scheme === 'file';
  bad.path === '/coding/c'; // path is now broken
  bad.fragment === '/project1';
  ```
   *
   * @param path A file system path (see `URI#fsPath`)
   */
  static file(e) {
    let n = S;
    if (Ne && (e = e.replace(/\\/g, ee)), e[0] === ee && e[1] === ee) {
      const s = e.indexOf(ee, 2);
      s === -1 ? (n = e.substring(2), e = ee) : (n = e.substring(2, s), e = e.substring(s) || ee);
    }
    return new Oe("file", n, e, S, S);
  }
  /**
   * Creates new URI from uri components.
   *
   * Unless `strict` is `true` the scheme is defaults to be `file`. This function performs
   * validation and should be used for untrusted uri components retrieved from storage,
   * user input, command arguments etc
   */
  static from(e, n) {
    return new Oe(e.scheme, e.authority, e.path, e.query, e.fragment, n);
  }
  /**
   * Join a URI path with path fragments and normalizes the resulting path.
   *
   * @param uri The input URI.
   * @param pathFragment The path fragment to add to the URI path.
   * @returns The resulting URI.
   */
  static joinPath(e, ...n) {
    if (!e.path)
      throw new Error("[UriError]: cannot call joinPath on URI without path");
    let s;
    return Ne && e.scheme === "file" ? s = me.file($.join(Zt(e, !0), ...n)).path : s = H.join(e.path, ...n), e.with({ path: s });
  }
  // ---- printing/externalize ---------------------------
  /**
   * Creates a string representation for this URI. It's guaranteed that calling
   * `URI.parse` with the result of this function creates an URI which is equal
   * to this URI.
   *
   * * The result shall *not* be used for display purposes but for externalization or transport.
   * * The result will be encoded using the percentage encoding and encoding happens mostly
   * ignore the scheme-specific encoding rules.
   *
   * @param skipEncoding Do not encode the result, default is `false`
   */
  toString(e = !1) {
    return Jt(this, e);
  }
  toJSON() {
    return this;
  }
  static revive(e) {
    if (e) {
      if (e instanceof me)
        return e;
      {
        const n = new Oe(e);
        return n._formatted = e.external ?? null, n._fsPath = e._sep === Dn ? e.fsPath ?? null : null, n;
      }
    } else return e;
  }
}
const Dn = Ne ? 1 : void 0;
class Oe extends me {
  constructor() {
    super(...arguments), this._formatted = null, this._fsPath = null;
  }
  get fsPath() {
    return this._fsPath || (this._fsPath = Zt(this, !1)), this._fsPath;
  }
  toString(e = !1) {
    return e ? Jt(this, !0) : (this._formatted || (this._formatted = Jt(this, !1)), this._formatted);
  }
  toJSON() {
    const e = {
      $mid: 1
      /* MarshalledId.Uri */
    };
    return this._fsPath && (e.fsPath = this._fsPath, e._sep = Dn), this._formatted && (e.external = this._formatted), this.path && (e.path = this.path), this.scheme && (e.scheme = this.scheme), this.authority && (e.authority = this.authority), this.query && (e.query = this.query), this.fragment && (e.fragment = this.fragment), e;
  }
}
const On = {
  58: "%3A",
  // gen-delims
  47: "%2F",
  63: "%3F",
  35: "%23",
  91: "%5B",
  93: "%5D",
  64: "%40",
  33: "%21",
  // sub-delims
  36: "%24",
  38: "%26",
  39: "%27",
  40: "%28",
  41: "%29",
  42: "%2A",
  43: "%2B",
  44: "%2C",
  59: "%3B",
  61: "%3D",
  32: "%20"
};
function U1(t, e, n) {
  let s, i = -1;
  for (let r = 0; r < t.length; r++) {
    const o = t.charCodeAt(r);
    if (o >= 97 && o <= 122 || o >= 65 && o <= 90 || o >= 48 && o <= 57 || o === 45 || o === 46 || o === 95 || o === 126 || e && o === 47 || n && o === 91 || n && o === 93 || n && o === 58)
      i !== -1 && (s += encodeURIComponent(t.substring(i, r)), i = -1), s !== void 0 && (s += t.charAt(r));
    else {
      s === void 0 && (s = t.substr(0, r));
      const a = On[o];
      a !== void 0 ? (i !== -1 && (s += encodeURIComponent(t.substring(i, r)), i = -1), s += a) : i === -1 && (i = r);
    }
  }
  return i !== -1 && (s += encodeURIComponent(t.substring(i))), s !== void 0 ? s : t;
}
function or(t) {
  let e;
  for (let n = 0; n < t.length; n++) {
    const s = t.charCodeAt(n);
    s === 35 || s === 63 ? (e === void 0 && (e = t.substr(0, n)), e += On[s]) : e !== void 0 && (e += t[n]);
  }
  return e !== void 0 ? e : t;
}
function Zt(t, e) {
  let n;
  return t.authority && t.path.length > 1 && t.scheme === "file" ? n = `//${t.authority}${t.path}` : t.path.charCodeAt(0) === 47 && (t.path.charCodeAt(1) >= 65 && t.path.charCodeAt(1) <= 90 || t.path.charCodeAt(1) >= 97 && t.path.charCodeAt(1) <= 122) && t.path.charCodeAt(2) === 58 ? e ? n = t.path.substr(1) : n = t.path[1].toLowerCase() + t.path.substr(2) : n = t.path, Ne && (n = n.replace(/\//g, "\\")), n;
}
function Jt(t, e) {
  const n = e ? or : U1;
  let s = "", { scheme: i, authority: r, path: o, query: a, fragment: u } = t;
  if (i && (s += i, s += ":"), (r || i === "file") && (s += ee, s += ee), r) {
    let l = r.indexOf("@");
    if (l !== -1) {
      const d = r.substr(0, l);
      r = r.substr(l + 1), l = d.lastIndexOf(":"), l === -1 ? s += n(d, !1, !1) : (s += n(d.substr(0, l), !1, !1), s += ":", s += n(d.substr(l + 1), !1, !0)), s += "@";
    }
    r = r.toLowerCase(), l = r.lastIndexOf(":"), l === -1 ? s += n(r, !1, !0) : (s += n(r.substr(0, l), !1, !0), s += r.substr(l));
  }
  if (o) {
    if (o.length >= 3 && o.charCodeAt(0) === 47 && o.charCodeAt(2) === 58) {
      const l = o.charCodeAt(1);
      l >= 65 && l <= 90 && (o = `/${String.fromCharCode(l + 32)}:${o.substr(3)}`);
    } else if (o.length >= 2 && o.charCodeAt(1) === 58) {
      const l = o.charCodeAt(0);
      l >= 65 && l <= 90 && (o = `${String.fromCharCode(l + 32)}:${o.substr(2)}`);
    }
    s += n(o, !0, !1);
  }
  return a && (s += "?", s += n(a, !1, !1)), u && (s += "#", s += e ? u : U1(u, !1, !1)), s;
}
function Tn(t) {
  try {
    return decodeURIComponent(t);
  } catch {
    return t.length > 3 ? t.substr(0, 3) + Tn(t.substr(3)) : t;
  }
}
const B1 = /(%[0-9A-Za-z][0-9A-Za-z])+/g;
function it(t) {
  return t.match(B1) ? t.replace(B1, (e) => Tn(e)) : t;
}
var fe;
(function(t) {
  t.inMemory = "inmemory", t.vscode = "vscode", t.internal = "private", t.walkThrough = "walkThrough", t.walkThroughSnippet = "walkThroughSnippet", t.http = "http", t.https = "https", t.file = "file", t.mailto = "mailto", t.untitled = "untitled", t.data = "data", t.command = "command", t.vscodeRemote = "vscode-remote", t.vscodeRemoteResource = "vscode-remote-resource", t.vscodeManagedRemoteResource = "vscode-managed-remote-resource", t.vscodeUserData = "vscode-userdata", t.vscodeCustomEditor = "vscode-custom-editor", t.vscodeNotebookCell = "vscode-notebook-cell", t.vscodeNotebookCellMetadata = "vscode-notebook-cell-metadata", t.vscodeNotebookCellMetadataDiff = "vscode-notebook-cell-metadata-diff", t.vscodeNotebookCellOutput = "vscode-notebook-cell-output", t.vscodeNotebookCellOutputDiff = "vscode-notebook-cell-output-diff", t.vscodeNotebookMetadata = "vscode-notebook-metadata", t.vscodeInteractiveInput = "vscode-interactive-input", t.vscodeSettings = "vscode-settings", t.vscodeWorkspaceTrust = "vscode-workspace-trust", t.vscodeTerminal = "vscode-terminal", t.vscodeChatCodeBlock = "vscode-chat-code-block", t.vscodeChatCodeCompareBlock = "vscode-chat-code-compare-block", t.vscodeChatEditor = "vscode-chat-editor", t.vscodeChatInput = "chatSessionInput", t.vscodeLocalChatSession = "vscode-chat-session", t.webviewPanel = "webview-panel", t.vscodeWebview = "vscode-webview", t.extension = "extension", t.vscodeFileResource = "vscode-file", t.tmp = "tmp", t.vsls = "vsls", t.vscodeSourceControl = "vscode-scm", t.commentsInput = "comment", t.codeSetting = "code-setting", t.outputChannel = "output", t.accessibleView = "accessible-view", t.chatEditingSnapshotScheme = "chat-editing-snapshot-text-model", t.chatEditingModel = "chat-editing-text-model", t.copilotPr = "copilot-pr";
})(fe || (fe = {}));
function ar(t, e) {
  return me.isUri(t) ? Li(t.scheme, e) : Ni(t, e + ":");
}
function b2(t, ...e) {
  return e.some((n) => ar(t, n));
}
const ur = "tkn";
class lr {
  constructor() {
    this._hosts = /* @__PURE__ */ Object.create(null), this._ports = /* @__PURE__ */ Object.create(null), this._connectionTokens = /* @__PURE__ */ Object.create(null), this._preferredWebSchema = "http", this._delegate = null, this._serverRootPath = "/";
  }
  setPreferredWebSchema(e) {
    this._preferredWebSchema = e;
  }
  get _remoteResourcesPath() {
    return H.join(this._serverRootPath, fe.vscodeRemoteResource);
  }
  rewrite(e) {
    if (this._delegate)
      try {
        return this._delegate(e);
      } catch (a) {
        return se(a), e;
      }
    const n = e.authority;
    let s = this._hosts[n];
    s && s.indexOf(":") !== -1 && s.indexOf("[") === -1 && (s = `[${s}]`);
    const i = this._ports[n], r = this._connectionTokens[n];
    let o = `path=${encodeURIComponent(e.path)}`;
    return typeof r == "string" && (o += `&${ur}=${encodeURIComponent(r)}`), me.from({
      scheme: Ys ? this._preferredWebSchema : fe.vscodeRemoteResource,
      authority: `${s}:${i}`,
      path: this._remoteResourcesPath,
      query: o
    });
  }
}
const Rn = new lr(), cr = "vscode-app";
class bt {
  static {
    this.FALLBACK_AUTHORITY = cr;
  }
  /**
   * Returns a URI to use in contexts where the browser is responsible
   * for loading (e.g. fetch()) or when used within the DOM.
   *
   * **Note:** use `dom.ts#asCSSUrl` whenever the URL is to be used in CSS context.
   */
  uriToBrowserUri(e) {
    return e.scheme === fe.vscodeRemote ? Rn.rewrite(e) : (
      // ...only ever for `file` resources
      e.scheme === fe.file && // ...and we run in native environments
      (qt || // ...or web worker extensions on desktop
      Zs === `${fe.vscodeFileResource}://${bt.FALLBACK_AUTHORITY}`) ? e.with({
        scheme: fe.vscodeFileResource,
        // We need to provide an authority here so that it can serve
        // as origin for network and loading matters in chromium.
        // If the URI is not coming with an authority already, we
        // add our own
        authority: e.authority || bt.FALLBACK_AUTHORITY,
        query: null,
        fragment: null
      }) : e
    );
  }
}
const C2 = new bt();
var W1;
(function(t) {
  const e = /* @__PURE__ */ new Map([
    ["1", { "Cross-Origin-Opener-Policy": "same-origin" }],
    ["2", { "Cross-Origin-Embedder-Policy": "require-corp" }],
    ["3", { "Cross-Origin-Opener-Policy": "same-origin", "Cross-Origin-Embedder-Policy": "require-corp" }]
  ]);
  t.CoopAndCoep = Object.freeze(e.get("3"));
  const n = "vscode-coi";
  function s(r) {
    let o;
    typeof r == "string" ? o = new URL(r).searchParams : r instanceof URL ? o = r.searchParams : me.isUri(r) && (o = new URL(r.toString(!0)).searchParams);
    const a = o?.get(n);
    if (a)
      return e.get(a);
  }
  t.getHeadersFromQuery = s;
  function i(r, o, a) {
    if (!globalThis.crossOriginIsolated)
      return;
    const u = o && a ? "3" : a ? "2" : "1";
    r instanceof URLSearchParams ? r.set(n, u) : r[n] = u;
  }
  t.addSearchParam = i;
})(W1 || (W1 = {}));
const $1 = typeof Buffer < "u";
new Yt(() => new Uint8Array(256));
let Mt;
class b1 {
  /**
   * When running in a nodejs context, if `actual` is not a nodejs Buffer, the backing store for
   * the returned `VSBuffer` instance might use a nodejs Buffer allocated from node's Buffer pool,
   * which is not transferrable.
   */
  static wrap(e) {
    return $1 && !Buffer.isBuffer(e) && (e = Buffer.from(e.buffer, e.byteOffset, e.byteLength)), new b1(e);
  }
  constructor(e) {
    this.buffer = e, this.byteLength = this.buffer.byteLength;
  }
  toString() {
    return $1 ? this.buffer.toString() : (Mt || (Mt = new TextDecoder()), Mt.decode(this.buffer));
  }
}
function v2(t, e) {
  return t[e + 0] << 0 >>> 0 | t[e + 1] << 8 >>> 0;
}
function w2(t, e, n) {
  t[n + 0] = e & 255, e = e >>> 8, t[n + 1] = e & 255;
}
function E2(t, e) {
  return t[e] * 2 ** 24 + t[e + 1] * 2 ** 16 + t[e + 2] * 2 ** 8 + t[e + 3];
}
function A2(t, e, n) {
  t[n + 3] = e, e = e >>> 8, t[n + 2] = e, e = e >>> 8, t[n + 1] = e, e = e >>> 8, t[n] = e;
}
function S2(t, e) {
  return t[e];
}
function D2(t, e, n) {
  t[n] = e;
}
const H1 = "0123456789abcdef";
function dr({ buffer: t }) {
  let e = "";
  for (let n = 0; n < t.length; n++) {
    const s = t[n];
    e += H1[s >>> 4], e += H1[s & 15];
  }
  return e;
}
function fr(t) {
  return C1(t, 0);
}
function C1(t, e) {
  switch (typeof t) {
    case "object":
      return t === null ? ce(349, e) : Array.isArray(t) ? pr(t, e) : mr(t, e);
    case "string":
      return Kn(t, e);
    case "boolean":
      return hr(t, e);
    case "number":
      return ce(t, e);
    case "undefined":
      return ce(937, e);
    default:
      return ce(617, e);
  }
}
function ce(t, e) {
  return (e << 5) - e + t | 0;
}
function hr(t, e) {
  return ce(t ? 433 : 863, e);
}
function Kn(t, e) {
  e = ce(149417, e);
  for (let n = 0, s = t.length; n < s; n++)
    e = ce(t.charCodeAt(n), e);
  return e;
}
function pr(t, e) {
  return e = ce(104579, e), t.reduce((n, s) => C1(s, n), e);
}
function mr(t, e) {
  return e = ce(181387, e), Object.keys(t).sort().reduce((n, s) => (n = Kn(s, n), C1(t[s], n)), e);
}
function Pt(t, e, n = 32) {
  const s = n - e, i = ~((1 << s) - 1);
  return (t << e | (i & t) >>> s) >>> 0;
}
function Ve(t, e = 32) {
  return t instanceof ArrayBuffer ? dr(b1.wrap(new Uint8Array(t))) : (t >>> 0).toString(16).padStart(e / 4, "0");
}
class kn {
  static {
    this._bigBlock32 = new DataView(new ArrayBuffer(320));
  }
  // 80 * 4 = 320
  constructor() {
    this._h0 = 1732584193, this._h1 = 4023233417, this._h2 = 2562383102, this._h3 = 271733878, this._h4 = 3285377520, this._buff = new Uint8Array(
      67
      /* to fit any utf-8 */
    ), this._buffDV = new DataView(this._buff.buffer), this._buffLen = 0, this._totalLen = 0, this._leftoverHighSurrogate = 0, this._finished = !1;
  }
  update(e) {
    const n = e.length;
    if (n === 0)
      return;
    const s = this._buff;
    let i = this._buffLen, r = this._leftoverHighSurrogate, o, a;
    for (r !== 0 ? (o = r, a = -1, r = 0) : (o = e.charCodeAt(0), a = 0); ; ) {
      let u = o;
      if (_1(o))
        if (a + 1 < n) {
          const l = e.charCodeAt(a + 1);
          Ye(l) ? (a++, u = y1(o, l)) : u = 65533;
        } else {
          r = o;
          break;
        }
      else Ye(o) && (u = 65533);
      if (i = this._push(s, i, u), a++, a < n)
        o = e.charCodeAt(a);
      else
        break;
    }
    this._buffLen = i, this._leftoverHighSurrogate = r;
  }
  _push(e, n, s) {
    return s < 128 ? e[n++] = s : s < 2048 ? (e[n++] = 192 | (s & 1984) >>> 6, e[n++] = 128 | (s & 63) >>> 0) : s < 65536 ? (e[n++] = 224 | (s & 61440) >>> 12, e[n++] = 128 | (s & 4032) >>> 6, e[n++] = 128 | (s & 63) >>> 0) : (e[n++] = 240 | (s & 1835008) >>> 18, e[n++] = 128 | (s & 258048) >>> 12, e[n++] = 128 | (s & 4032) >>> 6, e[n++] = 128 | (s & 63) >>> 0), n >= 64 && (this._step(), n -= 64, this._totalLen += 64, e[0] = e[64], e[1] = e[65], e[2] = e[66]), n;
  }
  digest() {
    return this._finished || (this._finished = !0, this._leftoverHighSurrogate && (this._leftoverHighSurrogate = 0, this._buffLen = this._push(
      this._buff,
      this._buffLen,
      65533
      /* SHA1Constant.UNICODE_REPLACEMENT */
    )), this._totalLen += this._buffLen, this._wrapUp()), Ve(this._h0) + Ve(this._h1) + Ve(this._h2) + Ve(this._h3) + Ve(this._h4);
  }
  _wrapUp() {
    this._buff[this._buffLen++] = 128, this._buff.subarray(this._buffLen).fill(0), this._buffLen > 56 && (this._step(), this._buff.fill(0));
    const e = 8 * this._totalLen;
    this._buffDV.setUint32(56, Math.floor(e / 4294967296), !1), this._buffDV.setUint32(60, e % 4294967296, !1), this._step();
  }
  _step() {
    const e = kn._bigBlock32, n = this._buffDV;
    for (let c = 0; c < 64; c += 4)
      e.setUint32(c, n.getUint32(c, !1), !1);
    for (let c = 64; c < 320; c += 4)
      e.setUint32(c, Pt(e.getUint32(c - 12, !1) ^ e.getUint32(c - 32, !1) ^ e.getUint32(c - 56, !1) ^ e.getUint32(c - 64, !1), 1), !1);
    let s = this._h0, i = this._h1, r = this._h2, o = this._h3, a = this._h4, u, l, d;
    for (let c = 0; c < 80; c++)
      c < 20 ? (u = i & r | ~i & o, l = 1518500249) : c < 40 ? (u = i ^ r ^ o, l = 1859775393) : c < 60 ? (u = i & r | i & o | r & o, l = 2400959708) : (u = i ^ r ^ o, l = 3395469782), d = Pt(s, 5) + u + a + l + e.getUint32(c * 4, !1) & 4294967295, a = o, o = r, r = Pt(i, 30), i = s, s = d;
    this._h0 = this._h0 + s & 4294967295, this._h1 = this._h1 + i & 4294967295, this._h2 = this._h2 + r & 4294967295, this._h3 = this._h3 + o & 4294967295, this._h4 = this._h4 + a & 4294967295;
  }
}
const { getWindow: X, getDocument: O2, getWindows: Ln, getWindowsCount: _r, getWindowId: q1, getWindowById: T2, onDidRegisterWindow: yr, onWillUnregisterWindow: R2, onDidUnregisterWindow: K2 } = (function() {
  const t = /* @__PURE__ */ new Map();
  si(k, 1);
  const e = { window: k, disposables: new M() };
  t.set(k.vscodeWindowId, e);
  const n = new F(), s = new F(), i = new F();
  function r(o, a) {
    return (typeof o == "number" ? t.get(o) : void 0) ?? (a ? e : void 0);
  }
  return {
    onDidRegisterWindow: n.event,
    onWillUnregisterWindow: i.event,
    onDidUnregisterWindow: s.event,
    registerWindow(o) {
      if (t.has(o.vscodeWindowId))
        return _e.None;
      const a = new M(), u = {
        window: o,
        disposables: a.add(new M())
      };
      return t.set(o.vscodeWindowId, u), a.add(q(() => {
        t.delete(o.vscodeWindowId), s.fire(o);
      })), a.add(R(o, I.BEFORE_UNLOAD, () => {
        i.fire(o);
      })), n.fire(u), a;
    },
    getWindows() {
      return t.values();
    },
    getWindowsCount() {
      return t.size;
    },
    getWindowId(o) {
      return o.vscodeWindowId;
    },
    hasWindow(o) {
      return t.has(o);
    },
    getWindowById: r,
    getWindow(o) {
      const a = o;
      if (a?.ownerDocument?.defaultView)
        return a.ownerDocument.defaultView.window;
      const u = o;
      return u?.view ? u.view.window : k;
    },
    getDocument(o) {
      return X(o).document;
    }
  };
})();
function k2(t) {
  for (; t.firstChild; )
    t.firstChild.remove();
}
class gr {
  constructor(e, n, s, i) {
    this._node = e, this._type = n, this._handler = s, this._options = i || !1, this._node.addEventListener(this._type, this._handler, this._options);
  }
  dispose() {
    this._handler && (this._node.removeEventListener(this._type, this._handler, this._options), this._node = null, this._handler = null);
  }
}
function R(t, e, n, s) {
  return new gr(t, e, n, s);
}
function Nn(t, e) {
  return function(n) {
    return e(new pi(t, n));
  };
}
function br(t) {
  return function(e) {
    return t(new bn(e));
  };
}
const L2 = function(e, n, s, i) {
  let r = s;
  return n === "click" || n === "mousedown" || n === "contextmenu" ? r = Nn(X(e), s) : (n === "keydown" || n === "keypress" || n === "keyup") && (r = br(s)), R(e, n, r, i);
}, N2 = function(e, n, s) {
  const i = Nn(X(e), n);
  return Cr(e, i, s);
};
function Cr(t, e, n) {
  return R(t, St && p1.pointerEvents ? I.POINTER_DOWN : I.MOUSE_DOWN, e, n);
}
function I2(t, e, n) {
  return R(t, St && p1.pointerEvents ? I.POINTER_MOVE : I.MOUSE_MOVE, e, n);
}
function F2(t, e, n) {
  return R(t, St && p1.pointerEvents ? I.POINTER_UP : I.MOUSE_UP, e, n);
}
function M2(t, e, n) {
  return We(t, e, n);
}
class P2 extends Cn {
  constructor(e, n) {
    super(e, n);
  }
}
let vr, Ct;
class V2 extends wi {
  /**
   *
   * @param node The optional node from which the target window is determined
   */
  constructor(e) {
    super(), this.defaultTarget = e && X(e);
  }
  cancelAndSet(e, n, s) {
    return super.cancelAndSet(e, n, s ?? this.defaultTarget);
  }
}
class Vt {
  constructor(e, n = 0) {
    this._runner = e, this.priority = n, this._canceled = !1;
  }
  dispose() {
    this._canceled = !0;
  }
  execute() {
    if (!this._canceled)
      try {
        this._runner();
      } catch (e) {
        se(e);
      }
  }
  // Sort by priority (largest to lowest)
  static sort(e, n) {
    return n.priority - e.priority;
  }
}
(function() {
  const t = /* @__PURE__ */ new Map(), e = /* @__PURE__ */ new Map(), n = /* @__PURE__ */ new Map(), s = /* @__PURE__ */ new Map(), i = (r) => {
    n.set(r, !1);
    const o = t.get(r) ?? [];
    for (e.set(r, o), t.set(r, []), s.set(r, !0); o.length > 0; )
      o.sort(Vt.sort), o.shift().execute();
    s.set(r, !1);
  };
  Ct = (r, o, a = 0) => {
    const u = q1(r), l = new Vt(o, a);
    let d = t.get(u);
    return d || (d = [], t.set(u, d)), d.push(l), n.get(u) || (n.set(u, !0), r.requestAnimationFrame(() => i(u))), l;
  }, vr = (r, o, a) => {
    const u = q1(r);
    if (s.get(u)) {
      const l = new Vt(o, a);
      let d = e.get(u);
      return d || (d = [], e.set(u, d)), d.push(l), l;
    } else
      return Ct(r, o, a);
  };
})();
function v1(t) {
  return X(t).getComputedStyle(t, null);
}
function x2(t, e, n) {
  const s = X(t), i = s.document;
  if (t !== i.body)
    return new ne(t.clientWidth, t.clientHeight);
  if (St && s?.visualViewport)
    return new ne(s.visualViewport.width, s.visualViewport.height);
  if (s?.innerWidth && s.innerHeight)
    return new ne(s.innerWidth, s.innerHeight);
  if (i.body && i.body.clientWidth && i.body.clientHeight)
    return new ne(i.body.clientWidth, i.body.clientHeight);
  if (i.documentElement && i.documentElement.clientWidth && i.documentElement.clientHeight)
    return new ne(i.documentElement.clientWidth, i.documentElement.clientHeight);
  throw new Error("Unable to figure out browser width and height");
}
class A {
  // Adapted from WinJS
  // Converts a CSS positioning string for the specified element to pixels.
  static convertToPixels(e, n) {
    return parseFloat(n) || 0;
  }
  static getDimension(e, n) {
    const s = v1(e), i = s ? s.getPropertyValue(n) : "0";
    return A.convertToPixels(e, i);
  }
  static getBorderLeftWidth(e) {
    return A.getDimension(e, "border-left-width");
  }
  static getBorderRightWidth(e) {
    return A.getDimension(e, "border-right-width");
  }
  static getBorderTopWidth(e) {
    return A.getDimension(e, "border-top-width");
  }
  static getBorderBottomWidth(e) {
    return A.getDimension(e, "border-bottom-width");
  }
  static getPaddingLeft(e) {
    return A.getDimension(e, "padding-left");
  }
  static getPaddingRight(e) {
    return A.getDimension(e, "padding-right");
  }
  static getPaddingTop(e) {
    return A.getDimension(e, "padding-top");
  }
  static getPaddingBottom(e) {
    return A.getDimension(e, "padding-bottom");
  }
  static getMarginLeft(e) {
    return A.getDimension(e, "margin-left");
  }
  static getMarginTop(e) {
    return A.getDimension(e, "margin-top");
  }
  static getMarginRight(e) {
    return A.getDimension(e, "margin-right");
  }
  static getMarginBottom(e) {
    return A.getDimension(e, "margin-bottom");
  }
}
class ne {
  static {
    this.None = new ne(0, 0);
  }
  constructor(e, n) {
    this.width = e, this.height = n;
  }
  with(e = this.width, n = this.height) {
    return e !== this.width || n !== this.height ? new ne(e, n) : this;
  }
  static is(e) {
    return typeof e == "object" && typeof e.height == "number" && typeof e.width == "number";
  }
  static lift(e) {
    return e instanceof ne ? e : new ne(e.width, e.height);
  }
  static equals(e, n) {
    return e === n ? !0 : !e || !n ? !1 : e.width === n.width && e.height === n.height;
  }
}
function U2(t) {
  let e = t.offsetParent, n = t.offsetTop, s = t.offsetLeft;
  for (; (t = t.parentNode) !== null && t !== t.ownerDocument.body && t !== t.ownerDocument.documentElement; ) {
    n -= t.scrollTop;
    const i = In(t) ? null : v1(t);
    i && (s -= i.direction !== "rtl" ? t.scrollLeft : -t.scrollLeft), t === e && (s += A.getBorderLeftWidth(t), n += A.getBorderTopWidth(t), n += t.offsetTop, s += t.offsetLeft, e = t.offsetParent);
  }
  return {
    left: s,
    top: n
  };
}
function B2(t, e, n) {
  typeof e == "number" && (t.style.width = `${e}px`), typeof n == "number" && (t.style.height = `${n}px`);
}
function W2(t) {
  const e = t.getBoundingClientRect(), n = X(t);
  return {
    left: e.left + n.scrollX,
    top: e.top + n.scrollY,
    width: e.width,
    height: e.height
  };
}
function $2(t) {
  let e = t, n = 1;
  do {
    const s = v1(e).zoom;
    s != null && s !== "1" && (n *= s), e = e.parentElement;
  } while (e !== null && e !== e.ownerDocument.documentElement);
  return n;
}
function H2(t) {
  const e = A.getMarginLeft(t) + A.getMarginRight(t);
  return t.offsetWidth + e;
}
function q2(t) {
  const e = A.getBorderLeftWidth(t) + A.getBorderRightWidth(t), n = A.getPaddingLeft(t) + A.getPaddingRight(t);
  return t.offsetWidth - e - n;
}
function G2(t) {
  const e = A.getBorderTopWidth(t) + A.getBorderBottomWidth(t), n = A.getPaddingTop(t) + A.getPaddingBottom(t);
  return t.offsetHeight - e - n;
}
function j2(t) {
  const e = A.getMarginTop(t) + A.getMarginBottom(t);
  return t.offsetHeight + e;
}
function e1(t, e) {
  return !!e?.contains(t);
}
function wr(t, e, n) {
  for (; t && t.nodeType === t.ELEMENT_NODE; ) {
    if (t.classList.contains(e))
      return t;
    if (n) {
      if (typeof n == "string") {
        if (t.classList.contains(n))
          return null;
      } else if (t === n)
        return null;
    }
    t = t.parentNode;
  }
  return null;
}
function z2(t, e, n) {
  return !!wr(t, e, n);
}
function In(t) {
  return t && !!t.host && !!t.mode;
}
function Q2(t) {
  return !!Fn(t);
}
function Fn(t) {
  for (; t.parentNode; ) {
    if (t === t.ownerDocument?.body)
      return null;
    t = t.parentNode;
  }
  return In(t) ? t : null;
}
function Mn() {
  let t = Pn().activeElement;
  for (; t?.shadowRoot; )
    t = t.shadowRoot.activeElement;
  return t;
}
function Y2(t) {
  return Mn() === t;
}
function X2(t) {
  return e1(Mn(), t);
}
function Pn() {
  return _r() <= 1 ? k.document : Array.from(Ln()).map(({ window: e }) => e.document).find((e) => e.hasFocus()) ?? k.document;
}
function Z2() {
  return Pn().defaultView?.window ?? k;
}
const Er = new class {
  constructor() {
    this.mutationObservers = /* @__PURE__ */ new Map();
  }
  observe(t, e, n) {
    let s = this.mutationObservers.get(t);
    s || (s = /* @__PURE__ */ new Map(), this.mutationObservers.set(t, s));
    const i = fr(n);
    let r = s.get(i);
    if (r)
      r.users += 1;
    else {
      const o = new F(), a = new MutationObserver((l) => o.fire(l));
      a.observe(t, n);
      const u = r = {
        users: 1,
        observer: a,
        onDidMutate: o.event
      };
      e.add(q(() => {
        u.users -= 1, u.users === 0 && (o.dispose(), a.disconnect(), s?.delete(i), s?.size === 0 && this.mutationObservers.delete(t));
      })), s.set(i, r);
    }
    return r.onDidMutate;
  }
}();
function $e(t) {
  return t instanceof HTMLElement || t instanceof X(t).HTMLElement;
}
function J2(t) {
  return t instanceof HTMLAnchorElement || t instanceof X(t).HTMLAnchorElement;
}
function Ar(t) {
  return t instanceof SVGElement || t instanceof X(t).SVGElement;
}
function ea(t) {
  return t instanceof MouseEvent || t instanceof X(t).MouseEvent;
}
function ta(t) {
  return t instanceof KeyboardEvent || t instanceof X(t).KeyboardEvent;
}
const I = {
  // Mouse
  CLICK: "click",
  AUXCLICK: "auxclick",
  DBLCLICK: "dblclick",
  MOUSE_UP: "mouseup",
  MOUSE_DOWN: "mousedown",
  MOUSE_OVER: "mouseover",
  MOUSE_MOVE: "mousemove",
  MOUSE_OUT: "mouseout",
  MOUSE_ENTER: "mouseenter",
  MOUSE_LEAVE: "mouseleave",
  MOUSE_WHEEL: "wheel",
  POINTER_UP: "pointerup",
  POINTER_DOWN: "pointerdown",
  POINTER_MOVE: "pointermove",
  POINTER_LEAVE: "pointerleave",
  CONTEXT_MENU: "contextmenu",
  // Keyboard
  KEY_DOWN: "keydown",
  KEY_UP: "keyup",
  BEFORE_UNLOAD: "beforeunload",
  FOCUS: "focus",
  FOCUS_IN: "focusin",
  FOCUS_OUT: "focusout",
  BLUR: "blur",
  INPUT: "input",
  // Drag
  DRAG_START: "dragstart",
  DRAG: "drag",
  DRAG_ENTER: "dragenter",
  DRAG_LEAVE: "dragleave",
  DRAG_OVER: "dragover",
  DROP: "drop",
  DRAG_END: "dragend"
};
function na(t) {
  const e = t;
  return !!(e && typeof e.preventDefault == "function" && typeof e.stopPropagation == "function");
}
const sa = {
  stop: (t, e) => (t.preventDefault(), e && t.stopPropagation(), t)
};
function ia(t) {
  const e = [];
  for (let n = 0; t && t.nodeType === t.ELEMENT_NODE; n++)
    e[n] = t.scrollTop, t = t.parentNode;
  return e;
}
function ra(t, e) {
  for (let n = 0; t && t.nodeType === t.ELEMENT_NODE; n++)
    t.scrollTop !== e[n] && (t.scrollTop = e[n]), t = t.parentNode;
}
class vt extends _e {
  get onDidFocus() {
    return this._onDidFocus.event;
  }
  get onDidBlur() {
    return this._onDidBlur.event;
  }
  static hasFocusWithin(e) {
    if ($e(e)) {
      const n = Fn(e), s = n ? n.activeElement : e.ownerDocument.activeElement;
      return e1(s, e);
    } else {
      const n = e;
      return e1(n.document.activeElement, n.document);
    }
  }
  constructor(e) {
    super(), this._onDidFocus = this._register(new F()), this._onDidBlur = this._register(new F());
    let n = vt.hasFocusWithin(e), s = !1;
    const i = () => {
      s = !1, n || (n = !0, this._onDidFocus.fire());
    }, r = () => {
      n && (s = !0, ($e(e) ? X(e) : e).setTimeout(() => {
        s && (s = !1, n = !1, this._onDidBlur.fire());
      }, 0));
    };
    this._refreshStateHandler = () => {
      vt.hasFocusWithin(e) !== n && (n ? r() : i());
    }, this._register(R(e, I.FOCUS, i, !0)), this._register(R(e, I.BLUR, r, !0)), $e(e) && (this._register(R(e, I.FOCUS_IN, () => this._refreshStateHandler())), this._register(R(e, I.FOCUS_OUT, () => this._refreshStateHandler())));
  }
}
function oa(t) {
  return new vt(t);
}
function aa(t, e) {
  return t.after(e), e;
}
function Sr(t, ...e) {
  if (t.append(...e), e.length === 1 && typeof e[0] != "string")
    return e[0];
}
function ua(t, e) {
  return t.insertBefore(e, t.firstChild), e;
}
function la(t, ...e) {
  t.textContent = "", Sr(t, ...e);
}
const Dr = /([\w\-]+)?(#([\w\-]+))?((\.([\w\-]+))*)/;
var Xe;
(function(t) {
  t.HTML = "http://www.w3.org/1999/xhtml", t.SVG = "http://www.w3.org/2000/svg";
})(Xe || (Xe = {}));
function Vn(t, e, n, ...s) {
  const i = Dr.exec(e);
  if (!i)
    throw new Error("Bad use of emmet");
  const r = i[1] || "div";
  let o;
  return t !== Xe.HTML ? o = document.createElementNS(t, r) : o = document.createElement(r), i[3] && (o.id = i[3]), i[4] && (o.className = i[4].replace(/\./g, " ").trim()), n && Object.entries(n).forEach(([a, u]) => {
    typeof u > "u" || (/^on\w+$/.test(a) ? o[a] = u : a === "selected" ? u && o.setAttribute(a, "true") : o.setAttribute(a, u));
  }), o.append(...s), o;
}
function Or(t, e, ...n) {
  return Vn(Xe.HTML, t, e, ...n);
}
Or.SVG = function(t, e, ...n) {
  return Vn(Xe.SVG, t, e, ...n);
};
function ca(t, ...e) {
  t ? Tr(...e) : Rr(...e);
}
function Tr(...t) {
  for (const e of t)
    e.style.display = "", e.removeAttribute("aria-hidden");
}
function Rr(...t) {
  for (const e of t)
    e.style.display = "none", e.setAttribute("aria-hidden", "true");
}
function da(t, e) {
  const n = t.devicePixelRatio * e;
  return Math.max(1, Math.floor(n)) / t.devicePixelRatio;
}
function fa(t) {
  k.open(t, "_blank", "noopener");
}
function ha(t, e) {
  const n = () => {
    e(), s = Ct(t, n);
  };
  let s = Ct(t, n);
  return q(() => s.dispose());
}
Rn.setPreferredWebSchema(/^https:/.test(k.location.href) ? "https" : "http");
class Ue extends F {
  constructor() {
    super(), this._subscriptions = new M(), this._keyStatus = {
      altKey: !1,
      shiftKey: !1,
      ctrlKey: !1,
      metaKey: !1
    }, this._subscriptions.add(He.runAndSubscribe(yr, ({ window: e, disposables: n }) => this.registerListeners(e, n), { window: k, disposables: this._subscriptions }));
  }
  registerListeners(e, n) {
    n.add(R(e, "keydown", (s) => {
      if (s.defaultPrevented)
        return;
      const i = new bn(s);
      if (!(i.keyCode === 6 && s.repeat)) {
        if (s.altKey && !this._keyStatus.altKey)
          this._keyStatus.lastKeyPressed = "alt";
        else if (s.ctrlKey && !this._keyStatus.ctrlKey)
          this._keyStatus.lastKeyPressed = "ctrl";
        else if (s.metaKey && !this._keyStatus.metaKey)
          this._keyStatus.lastKeyPressed = "meta";
        else if (s.shiftKey && !this._keyStatus.shiftKey)
          this._keyStatus.lastKeyPressed = "shift";
        else if (i.keyCode !== 6)
          this._keyStatus.lastKeyPressed = void 0;
        else
          return;
        this._keyStatus.altKey = s.altKey, this._keyStatus.ctrlKey = s.ctrlKey, this._keyStatus.metaKey = s.metaKey, this._keyStatus.shiftKey = s.shiftKey, this._keyStatus.lastKeyPressed && (this._keyStatus.event = s, this.fire(this._keyStatus));
      }
    }, !0)), n.add(R(e, "keyup", (s) => {
      s.defaultPrevented || (!s.altKey && this._keyStatus.altKey ? this._keyStatus.lastKeyReleased = "alt" : !s.ctrlKey && this._keyStatus.ctrlKey ? this._keyStatus.lastKeyReleased = "ctrl" : !s.metaKey && this._keyStatus.metaKey ? this._keyStatus.lastKeyReleased = "meta" : !s.shiftKey && this._keyStatus.shiftKey ? this._keyStatus.lastKeyReleased = "shift" : this._keyStatus.lastKeyReleased = void 0, this._keyStatus.lastKeyPressed !== this._keyStatus.lastKeyReleased && (this._keyStatus.lastKeyPressed = void 0), this._keyStatus.altKey = s.altKey, this._keyStatus.ctrlKey = s.ctrlKey, this._keyStatus.metaKey = s.metaKey, this._keyStatus.shiftKey = s.shiftKey, this._keyStatus.lastKeyReleased && (this._keyStatus.event = s, this.fire(this._keyStatus)));
    }, !0)), n.add(R(e.document.body, "mousedown", () => {
      this._keyStatus.lastKeyPressed = void 0;
    }, !0)), n.add(R(e.document.body, "mouseup", () => {
      this._keyStatus.lastKeyPressed = void 0;
    }, !0)), n.add(R(e.document.body, "mousemove", (s) => {
      s.buttons && (this._keyStatus.lastKeyPressed = void 0);
    }, !0)), n.add(R(e, "blur", () => {
      this.resetKeyStatus();
    }));
  }
  get keyStatus() {
    return this._keyStatus;
  }
  /**
   * Allows to explicitly reset the key status based on more knowledge (#109062)
   */
  resetKeyStatus() {
    this.doResetKeyStatus(), this.fire(this._keyStatus);
  }
  doResetKeyStatus() {
    this._keyStatus = {
      altKey: !1,
      shiftKey: !1,
      ctrlKey: !1,
      metaKey: !1
    };
  }
  static getInstance() {
    return Ue.instance || (Ue.instance = new Ue()), Ue.instance;
  }
  dispose() {
    super.dispose(), this._subscriptions.dispose();
  }
}
class pa extends _e {
  constructor(e, n) {
    super(), this.element = e, this.callbacks = n, this.counter = 0, this.dragStartTime = 0, this.registerListeners();
  }
  registerListeners() {
    this.callbacks.onDragStart && this._register(R(this.element, I.DRAG_START, (e) => {
      this.callbacks.onDragStart?.(e);
    })), this.callbacks.onDrag && this._register(R(this.element, I.DRAG, (e) => {
      this.callbacks.onDrag?.(e);
    })), this._register(R(this.element, I.DRAG_ENTER, (e) => {
      this.counter++, this.dragStartTime = e.timeStamp, this.callbacks.onDragEnter?.(e);
    })), this._register(R(this.element, I.DRAG_OVER, (e) => {
      e.preventDefault(), this.callbacks.onDragOver?.(e, e.timeStamp - this.dragStartTime);
    })), this._register(R(this.element, I.DRAG_LEAVE, (e) => {
      this.counter--, this.counter === 0 && (this.dragStartTime = 0, this.callbacks.onDragLeave?.(e));
    })), this._register(R(this.element, I.DRAG_END, (e) => {
      this.counter = 0, this.dragStartTime = 0, this.callbacks.onDragEnd?.(e);
    })), this._register(R(this.element, I.DROP, (e) => {
      this.counter = 0, this.dragStartTime = 0, this.callbacks.onDrop?.(e);
    }));
  }
}
const Kr = /(?<tag>[\w\-]+)?(?:#(?<id>[\w\-]+))?(?<class>(?:\.(?:[\w\-]+))*)(?:@(?<name>(?:[\w\_])+))?/;
function ma(t, ...e) {
  let n, s;
  Array.isArray(e[0]) ? (n = {}, s = e[0]) : (n = e[0] || {}, s = e[1]);
  const i = Kr.exec(t);
  if (!i || !i.groups)
    throw new Error("Bad use of h");
  const r = i.groups.tag || "div", o = document.createElement(r);
  i.groups.id && (o.id = i.groups.id);
  const a = [];
  if (i.groups.class)
    for (const l of i.groups.class.split("."))
      l !== "" && a.push(l);
  if (n.className !== void 0)
    for (const l of n.className.split("."))
      l !== "" && a.push(l);
  a.length > 0 && (o.className = a.join(" "));
  const u = {};
  if (i.groups.name && (u[i.groups.name] = o), s)
    for (const l of s)
      $e(l) ? o.appendChild(l) : typeof l == "string" ? o.append(l) : "root" in l && (Object.assign(u, l), o.appendChild(l.root));
  for (const [l, d] of Object.entries(n))
    if (l !== "className")
      if (l === "style")
        for (const [c, p] of Object.entries(d))
          o.style.setProperty(Ze(c), typeof p == "number" ? p + "px" : "" + p);
      else l === "tabIndex" ? o.tabIndex = d : o.setAttribute(Ze(l), d.toString());
  return u.root = o, u;
}
function Ze(t) {
  return t.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
}
function _a(t) {
  return t.tagName.toLowerCase() === "input" || t.tagName.toLowerCase() === "textarea" || $e(t) && !!t.editContext;
}
var G1;
(function(t) {
  function e(i = void 0) {
    return (r, o, a) => {
      const u = o.class;
      delete o.class;
      const l = o.ref;
      delete o.ref;
      const d = o.obsRef;
      return delete o.obsRef, new Lr(r, l, d, i, u, o, a);
    };
  }
  function n(i, r = void 0) {
    const o = e(r);
    return (a, u) => o(i, a, u);
  }
  t.div = n("div"), t.elem = e(void 0), t.svg = n("svg", "http://www.w3.org/2000/svg"), t.svgElem = e("http://www.w3.org/2000/svg");
  function s() {
    let i;
    const r = function(o) {
      i = o;
    };
    return Object.defineProperty(r, "element", {
      get() {
        if (!i)
          throw new K("Make sure the ref is set before accessing the element. Maybe wrong initialization order?");
        return i;
      }
    }), r;
  }
  t.ref = s;
})(G1 || (G1 = {}));
class w1 {
  constructor(e, n, s, i, r, o, a) {
    this._deriveds = [], this._element = i ? document.createElementNS(i, e) : document.createElement(e), n && n(this._element), s && this._deriveds.push(Pe((u) => {
      s(this), u.store.add({
        dispose: () => {
          s(null);
        }
      });
    })), r && (Un(r) ? this._deriveds.push(Pe(this, (u) => {
      j1(this._element, z1(r, u));
    })) : j1(this._element, z1(r, void 0)));
    for (const [u, l] of Object.entries(o))
      if (u === "style")
        for (const [d, c] of Object.entries(l)) {
          const p = Ze(d);
          Ae(c) ? this._deriveds.push(qe({ owner: this, debugName: () => `set.style.${p}` }, (O) => {
            this._element.style.setProperty(p, Q1(c.read(O)));
          })) : this._element.style.setProperty(p, Q1(c));
        }
      else u === "tabIndex" ? Ae(l) ? this._deriveds.push(Pe(this, (d) => {
        this._element.tabIndex = l.read(d);
      })) : this._element.tabIndex = l : u.startsWith("on") ? this._element[u] = l : Ae(l) ? this._deriveds.push(qe({ owner: this, debugName: () => `set.${u}` }, (d) => {
        Y1(this._element, u, l.read(d));
      })) : Y1(this._element, u, l);
    if (a) {
      let u = function(d, c) {
        return Ae(c) ? u(d, c.read(d)) : Array.isArray(c) ? c.flatMap((p) => u(d, p)) : c instanceof w1 ? (d && c.readEffect(d), [c._element]) : c ? [c] : [];
      };
      const l = Pe(this, (d) => {
        this._element.replaceChildren(...u(d, a));
      });
      this._deriveds.push(l), Bn(a) || l.get();
    }
  }
  readEffect(e) {
    for (const n of this._deriveds)
      n.read(e);
  }
  keepUpdated(e) {
    return Pe((n) => {
      this.readEffect(n);
    }).recomputeInitiallyAndOnChange(e), this;
  }
  /**
   * Creates a live element that will keep the element updated as long as the returned object is not disposed.
  */
  toDisposableLiveElement() {
    const e = new M();
    return this.keepUpdated(e), new kr(this._element, e);
  }
}
function j1(t, e) {
  Ar(t) ? t.setAttribute("class", e) : t.className = e;
}
function xn(t, e, n) {
  if (Ae(t)) {
    n(t.read(e));
    return;
  }
  if (Array.isArray(t)) {
    for (const s of t)
      xn(s, e, n);
    return;
  }
  n(t);
}
function z1(t, e) {
  let n = "";
  return xn(t, e, (s) => {
    s && (n.length === 0 ? n = s : n += " " + s);
  }), n;
}
function Un(t) {
  return Ae(t) ? !0 : Array.isArray(t) ? t.some((e) => Un(e)) : !1;
}
function Q1(t) {
  return typeof t == "number" ? t + "px" : t;
}
function Bn(t) {
  return Ae(t) ? !0 : Array.isArray(t) ? t.some((e) => Bn(e)) : !1;
}
class kr {
  constructor(e, n) {
    this.element = e, this._disposable = n;
  }
  dispose() {
    this._disposable.dispose();
  }
}
class Lr extends w1 {
  constructor() {
    super(...arguments), this._isHovered = void 0, this._didMouseMoveDuringHover = void 0;
  }
  get element() {
    return this._element;
  }
  get isHovered() {
    if (!this._isHovered) {
      const e = L1("hovered", !1);
      this._element.addEventListener("mouseenter", (n) => e.set(!0, void 0)), this._element.addEventListener("mouseleave", (n) => e.set(!1, void 0)), this._isHovered = e;
    }
    return this._isHovered;
  }
  get didMouseMoveDuringHover() {
    if (!this._didMouseMoveDuringHover) {
      let e = !1;
      const n = L1("didMouseMoveDuringHover", !1);
      this._element.addEventListener("mouseenter", (s) => {
        e = !0;
      }), this._element.addEventListener("mousemove", (s) => {
        e && n.set(!0, void 0);
      }), this._element.addEventListener("mouseleave", (s) => {
        e = !1, n.set(!1, void 0);
      }), this._didMouseMoveDuringHover = n;
    }
    return this._didMouseMoveDuringHover;
  }
}
function Y1(t, e, n) {
  n == null ? t.removeAttribute(Ze(e)) : t.setAttribute(Ze(e), String(n));
}
function Ae(t) {
  return !!t && t.read !== void 0 && t.reportChanges !== void 0;
}
const wt = /* @__PURE__ */ new Map();
let Wn = null;
function Nr(t) {
  Wn = t || null;
}
function $n() {
  return Wn || k.document.head;
}
function Hn() {
  return new Ir();
}
class Ir {
  constructor() {
    this._currentCssStyle = "", this._styleSheet = void 0;
  }
  setStyle(e) {
    e !== this._currentCssStyle && (this._currentCssStyle = e, this._styleSheet ? this._styleSheet.textContent = e : this._styleSheet = E1($n(), (n) => n.textContent = e));
  }
  dispose() {
    this._styleSheet && (this._styleSheet.remove(), this._styleSheet = void 0);
  }
}
function E1(t = $n(), e, n) {
  const s = document.createElement("style");
  if (s.type = "text/css", s.media = "screen", e?.(s), t.appendChild(s), n && n.add(q(() => s.remove())), t === k.document.head) {
    const i = /* @__PURE__ */ new Set();
    wt.set(s, i), n && n.add(q(() => wt.delete(s)));
    for (const { window: r, disposables: o } of Ln()) {
      if (r === k)
        continue;
      const a = o.add(Fr(s, i, r));
      n?.add(a);
    }
  }
  return s;
}
function Fr(t, e, n) {
  const s = new M(), i = t.cloneNode(!0);
  n.document.head.appendChild(i), s.add(q(() => i.remove()));
  for (const r of Gn(t))
    i.sheet?.insertRule(r.cssText, i.sheet?.cssRules.length);
  return s.add(Er.observe(t, s, { childList: !0, subtree: Qe, characterData: Qe })(() => {
    i.textContent = t.textContent;
  })), e.add(i), s.add(q(() => e.delete(i))), s;
}
let xt = null;
function qn() {
  return xt || (xt = E1()), xt;
}
function Gn(t) {
  return t?.sheet?.rules ? t.sheet.rules : t?.sheet?.cssRules ? t.sheet.cssRules : [];
}
function jn(t, e, n = qn()) {
  if (!(!n || !e)) {
    n.sheet?.insertRule(`${t} {${e}}`, 0);
    for (const s of wt.get(n) ?? [])
      jn(t, e, s);
  }
}
function zn(t, e = qn()) {
  if (!e)
    return;
  const n = Gn(e), s = [];
  for (let i = 0; i < n.length; i++) {
    const r = n[i];
    Mr(r) && r.selectorText.indexOf(t) !== -1 && s.push(i);
  }
  for (let i = s.length - 1; i >= 0; i--)
    e.sheet?.deleteRule(s[i]);
  for (const i of wt.get(e) ?? [])
    zn(t, i);
}
function Mr(t) {
  return typeof t.selectorText == "string";
}
function Pr(t) {
  const e = new M(), n = e.add(Hn());
  return e.add(on((s) => {
    n.setStyle(t.read(s));
  })), e;
}
const ya = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  createCSSRule: jn,
  createStyleSheet: E1,
  createStyleSheet2: Hn,
  createStyleSheetFromObservable: Pr,
  removeCSSRulesContainingSelector: zn,
  setDefaultStylesheetContainer: Nr
}, Symbol.toStringTag, { value: "Module" }));
export {
  X0 as $,
  h2 as A,
  Li as B,
  Zt as C,
  _e as D,
  F as E,
  ns as F,
  fr as G,
  Mn as H,
  Ut as I,
  Xr as J,
  r2 as K,
  ms as L,
  Mo as M,
  Bi as N,
  l0 as O,
  En as P,
  Ii as Q,
  q0 as R,
  fe as S,
  Pi as T,
  me as U,
  Mi as V,
  c2 as W,
  Yt as X,
  Ke as Y,
  V1 as Z,
  Y0 as _,
  pe as a,
  Lo as a$,
  j0 as a0,
  J1 as a1,
  jr as a2,
  zr as a3,
  is as a4,
  Yr as a5,
  Qr as a6,
  c0 as a7,
  _1 as a8,
  v2 as a9,
  L2 as aA,
  ro as aB,
  L0 as aC,
  Q2 as aD,
  E1 as aE,
  n2 as aF,
  Fn as aG,
  yr as aH,
  k as aI,
  bn as aJ,
  V2 as aK,
  k0 as aL,
  E0 as aM,
  h1 as aN,
  m0 as aO,
  ta as aP,
  J0 as aQ,
  e2 as aR,
  no as aS,
  ia as aT,
  ra as aU,
  p1 as aV,
  St as aW,
  p0 as aX,
  o0 as aY,
  g0 as aZ,
  x2 as a_,
  W0 as aa,
  Ti as ab,
  go as ac,
  se as ad,
  Gt as ae,
  F0 as af,
  G0 as ag,
  K as ah,
  H0 as ai,
  Qe as aj,
  _a as ak,
  Ct as al,
  X as am,
  q1 as an,
  He as ao,
  K2 as ap,
  qt as aq,
  cs as ar,
  mn as as,
  T2 as at,
  _n as au,
  _0 as av,
  R as aw,
  I as ax,
  pi as ay,
  W2 as az,
  Qs as b,
  pa as b$,
  Me as b0,
  ps as b1,
  s2 as b2,
  t2 as b3,
  da as b4,
  Z2 as b5,
  rs as b6,
  Or as b7,
  Pn as b8,
  jo as b9,
  B as bA,
  u1 as bB,
  G as bC,
  un as bD,
  P as bE,
  At as bF,
  te as bG,
  mt as bH,
  qe as bI,
  Uo as bJ,
  Bo as bK,
  Wo as bL,
  K0 as bM,
  ei as bN,
  Co as bO,
  Ei as bP,
  s1 as bQ,
  Is as bR,
  Pe as bS,
  l2 as bT,
  es as bU,
  Ui as bV,
  Eo as bW,
  V0 as bX,
  x0 as bY,
  ds as bZ,
  Io as b_,
  Go as ba,
  L1 as bb,
  on as bc,
  y0 as bd,
  $e as be,
  Oo as bf,
  hs as bg,
  ts as bh,
  Z1 as bi,
  qr as bj,
  Ye as bk,
  vr as bl,
  oa as bm,
  $r as bn,
  Zr as bo,
  M2 as bp,
  Br as bq,
  rt as br,
  A2 as bs,
  w2 as bt,
  E2 as bu,
  D2 as bv,
  S2 as bw,
  i2 as bx,
  a2 as by,
  o2 as bz,
  k2 as c,
  X1 as c$,
  Ks as c0,
  Zo as c1,
  B0 as c2,
  Ri as c3,
  b1 as c4,
  la as c5,
  C2 as c6,
  q2 as c7,
  Ci as c8,
  Do as c9,
  Ms as cA,
  ma as cB,
  Ro as cC,
  $o as cD,
  e0 as cE,
  Po as cF,
  vs as cG,
  O0 as cH,
  P1 as cI,
  Ue as cJ,
  ua as cK,
  ao as cL,
  Fo as cM,
  mo as cN,
  qo as cO,
  s0 as cP,
  r0 as cQ,
  b0 as cR,
  P0 as cS,
  d2 as cT,
  Q0 as cU,
  ki as cV,
  Ot as cW,
  _2 as cX,
  po as cY,
  ca as cZ,
  D0 as c_,
  G2 as ca,
  O2 as cb,
  T0 as cc,
  U2 as cd,
  ha as ce,
  Ar as cf,
  e1 as cg,
  uo as ch,
  bo as ci,
  sa as cj,
  Vo as ck,
  vi as cl,
  ea as cm,
  Sr as cn,
  H2 as co,
  Qt as cp,
  zo as cq,
  an as cr,
  Et as cs,
  co as ct,
  Fs as cu,
  fo as cv,
  ye as cw,
  Hr as cx,
  Ht as cy,
  To as cz,
  Ne as d,
  Z0 as d$,
  _i as d0,
  vn as d1,
  S0 as d2,
  eo as d3,
  Vr as d4,
  pt as d5,
  yo as d6,
  N2 as d7,
  as as d8,
  C1 as d9,
  lo as dA,
  Bt as dB,
  Ls as dC,
  Ko as dD,
  ho as dE,
  ko as dF,
  No as dG,
  Ho as dH,
  t0 as dI,
  _o as dJ,
  A1 as dK,
  B2 as dL,
  P2 as dM,
  Dt as dN,
  Jo as dO,
  Qo as dP,
  Pr as dQ,
  Xo as dR,
  R0 as dS,
  D1 as dT,
  Gr as dU,
  so as dV,
  xe as dW,
  ct as dX,
  u0 as dY,
  A0 as dZ,
  y2 as d_,
  ar as da,
  G1 as db,
  I0 as dc,
  ne as dd,
  j2 as de,
  Q as df,
  u2 as dg,
  Y2 as dh,
  v1 as di,
  So as dj,
  zn as dk,
  jn as dl,
  Tr as dm,
  Rr as dn,
  vo as dp,
  wo as dq,
  Kn as dr,
  mi as ds,
  oo as dt,
  xo as du,
  z2 as dv,
  ss as dw,
  aa as dx,
  b2 as dy,
  Ao as dz,
  Ys as e,
  U0 as e0,
  Jn as e1,
  W1 as e2,
  Hs as e3,
  dn as e4,
  $0 as e5,
  wi as e6,
  xr as e7,
  fa as e8,
  $2 as e9,
  X2 as ea,
  w0 as eb,
  v0 as ec,
  gn as ed,
  Ki as ee,
  kn as ef,
  na as eg,
  J2 as eh,
  R2 as ei,
  a0 as ej,
  F2 as ek,
  Cr as el,
  I2 as em,
  N0 as en,
  io as eo,
  Yo as ep,
  Wr as eq,
  ii as er,
  ya as es,
  h0 as f,
  d0 as g,
  ti as h,
  Ur as i,
  f0 as j,
  M0 as k,
  i0 as l,
  to as m,
  C0 as n,
  M as o,
  us as p,
  n1 as q,
  H as r,
  g2 as s,
  q as t,
  Ni as u,
  Jr as v,
  z0 as w,
  m2 as x,
  f2 as y,
  p2 as z
};
//# sourceMappingURL=domStylesheets-yftOQEzv.js.map
