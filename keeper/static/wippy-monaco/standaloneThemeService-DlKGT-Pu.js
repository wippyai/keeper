import { F as de, E as j, t as pe, D as V, l as n, U as vt, eq as Ce, b6 as Zt, a2 as Xt, bn as Yt, aC as Ft, c6 as er, o as tr, er as rr, aD as or, aE as We, aI as Ue } from "./domStylesheets-yftOQEzv.js";
function U(r, e) {
  const o = Math.pow(10, e);
  return Math.round(r * o) / o;
}
class c {
  constructor(e, o, a, s = 1) {
    this._rgbaBrand = void 0, this.r = Math.min(255, Math.max(0, e)) | 0, this.g = Math.min(255, Math.max(0, o)) | 0, this.b = Math.min(255, Math.max(0, a)) | 0, this.a = U(Math.max(Math.min(1, s), 0), 3);
  }
  static equals(e, o) {
    return e.r === o.r && e.g === o.g && e.b === o.b && e.a === o.a;
  }
}
class _ {
  constructor(e, o, a, s) {
    this._hslaBrand = void 0, this.h = Math.max(Math.min(360, e), 0) | 0, this.s = U(Math.max(Math.min(1, o), 0), 3), this.l = U(Math.max(Math.min(1, a), 0), 3), this.a = U(Math.max(Math.min(1, s), 0), 3);
  }
  static equals(e, o) {
    return e.h === o.h && e.s === o.s && e.l === o.l && e.a === o.a;
  }
  /**
   * Converts an RGB color value to HSL. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
   * Assumes r, g, and b are contained in the set [0, 255] and
   * returns h in the set [0, 360], s, and l in the set [0, 1].
   */
  static fromRGBA(e) {
    const o = e.r / 255, a = e.g / 255, s = e.b / 255, l = e.a, u = Math.max(o, a, s), g = Math.min(o, a, s);
    let b = 0, k = 0;
    const m = (g + u) / 2, F = u - g;
    if (F > 0) {
      switch (k = Math.min(m <= 0.5 ? F / (2 * m) : F / (2 - 2 * m), 1), u) {
        case o:
          b = (a - s) / F + (a < s ? 6 : 0);
          break;
        case a:
          b = (s - o) / F + 2;
          break;
        case s:
          b = (o - a) / F + 4;
          break;
      }
      b *= 60, b = Math.round(b);
    }
    return new _(b, k, m, l);
  }
  static _hue2rgb(e, o, a) {
    return a < 0 && (a += 1), a > 1 && (a -= 1), a < 1 / 6 ? e + (o - e) * 6 * a : a < 1 / 2 ? o : a < 2 / 3 ? e + (o - e) * (2 / 3 - a) * 6 : e;
  }
  /**
   * Converts an HSL color value to RGB. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
   * Assumes h in the set [0, 360] s, and l are contained in the set [0, 1] and
   * returns r, g, and b in the set [0, 255].
   */
  static toRGBA(e) {
    const o = e.h / 360, { s: a, l: s, a: l } = e;
    let u, g, b;
    if (a === 0)
      u = g = b = s;
    else {
      const k = s < 0.5 ? s * (1 + a) : s + a - s * a, m = 2 * s - k;
      u = _._hue2rgb(m, k, o + 1 / 3), g = _._hue2rgb(m, k, o), b = _._hue2rgb(m, k, o - 1 / 3);
    }
    return new c(Math.round(u * 255), Math.round(g * 255), Math.round(b * 255), l);
  }
}
class re {
  constructor(e, o, a, s) {
    this._hsvaBrand = void 0, this.h = Math.max(Math.min(360, e), 0) | 0, this.s = U(Math.max(Math.min(1, o), 0), 3), this.v = U(Math.max(Math.min(1, a), 0), 3), this.a = U(Math.max(Math.min(1, s), 0), 3);
  }
  static equals(e, o) {
    return e.h === o.h && e.s === o.s && e.v === o.v && e.a === o.a;
  }
  // from http://www.rapidtables.com/convert/color/rgb-to-hsv.htm
  static fromRGBA(e) {
    const o = e.r / 255, a = e.g / 255, s = e.b / 255, l = Math.max(o, a, s), u = Math.min(o, a, s), g = l - u, b = l === 0 ? 0 : g / l;
    let k;
    return g === 0 ? k = 0 : l === o ? k = ((a - s) / g % 6 + 6) % 6 : l === a ? k = (s - o) / g + 2 : k = (o - a) / g + 4, new re(Math.round(k * 60), b, l, e.a);
  }
  // from http://www.rapidtables.com/convert/color/hsv-to-rgb.htm
  static toRGBA(e) {
    const { h: o, s: a, v: s, a: l } = e, u = s * a, g = u * (1 - Math.abs(o / 60 % 2 - 1)), b = s - u;
    let [k, m, F] = [0, 0, 0];
    return o < 60 ? (k = u, m = g) : o < 120 ? (k = g, m = u) : o < 180 ? (m = u, F = g) : o < 240 ? (m = g, F = u) : o < 300 ? (k = g, F = u) : o <= 360 && (k = u, F = g), k = Math.round((k + b) * 255), m = Math.round((m + b) * 255), F = Math.round((F + b) * 255), new c(k, m, F, l);
  }
}
class d {
  static fromHex(e) {
    return d.Format.CSS.parseHex(e) || d.red;
  }
  static equals(e, o) {
    return !e && !o ? !0 : !e || !o ? !1 : e.equals(o);
  }
  get hsla() {
    return this._hsla ? this._hsla : _.fromRGBA(this.rgba);
  }
  get hsva() {
    return this._hsva ? this._hsva : re.fromRGBA(this.rgba);
  }
  constructor(e) {
    if (e)
      if (e instanceof c)
        this.rgba = e;
      else if (e instanceof _)
        this._hsla = e, this.rgba = _.toRGBA(e);
      else if (e instanceof re)
        this._hsva = e, this.rgba = re.toRGBA(e);
      else
        throw new Error("Invalid color ctor argument");
    else throw new Error("Color needs a value");
  }
  equals(e) {
    return !!e && c.equals(this.rgba, e.rgba) && _.equals(this.hsla, e.hsla) && re.equals(this.hsva, e.hsva);
  }
  /**
   * http://www.w3.org/TR/WCAG20/#relativeluminancedef
   * Returns the number in the set [0, 1]. O => Darkest Black. 1 => Lightest white.
   */
  getRelativeLuminance() {
    const e = d._relativeLuminanceForComponent(this.rgba.r), o = d._relativeLuminanceForComponent(this.rgba.g), a = d._relativeLuminanceForComponent(this.rgba.b), s = 0.2126 * e + 0.7152 * o + 0.0722 * a;
    return U(s, 4);
  }
  static _relativeLuminanceForComponent(e) {
    const o = e / 255;
    return o <= 0.03928 ? o / 12.92 : Math.pow((o + 0.055) / 1.055, 2.4);
  }
  /**
   *	http://24ways.org/2010/calculating-color-contrast
   *  Return 'true' if lighter color otherwise 'false'
   */
  isLighter() {
    return (this.rgba.r * 299 + this.rgba.g * 587 + this.rgba.b * 114) / 1e3 >= 128;
  }
  isLighterThan(e) {
    const o = this.getRelativeLuminance(), a = e.getRelativeLuminance();
    return o > a;
  }
  isDarkerThan(e) {
    const o = this.getRelativeLuminance(), a = e.getRelativeLuminance();
    return o < a;
  }
  lighten(e) {
    return new d(new _(this.hsla.h, this.hsla.s, this.hsla.l + this.hsla.l * e, this.hsla.a));
  }
  darken(e) {
    return new d(new _(this.hsla.h, this.hsla.s, this.hsla.l - this.hsla.l * e, this.hsla.a));
  }
  transparent(e) {
    const { r: o, g: a, b: s, a: l } = this.rgba;
    return new d(new c(o, a, s, l * e));
  }
  isTransparent() {
    return this.rgba.a === 0;
  }
  isOpaque() {
    return this.rgba.a === 1;
  }
  opposite() {
    return new d(new c(255 - this.rgba.r, 255 - this.rgba.g, 255 - this.rgba.b, this.rgba.a));
  }
  /**
   * Mixes the current color with the provided color based on the given factor.
   * @param color The color to mix with
   * @param factor The factor of mixing (0 means this color, 1 means the input color, 0.5 means equal mix)
   * @returns A new color representing the mix
   */
  mix(e, o = 0.5) {
    const a = Math.min(Math.max(o, 0), 1), s = this.rgba, l = e.rgba, u = s.r + (l.r - s.r) * a, g = s.g + (l.g - s.g) * a, b = s.b + (l.b - s.b) * a, k = s.a + (l.a - s.a) * a;
    return new d(new c(u, g, b, k));
  }
  makeOpaque(e) {
    if (this.isOpaque() || e.rgba.a !== 1)
      return this;
    const { r: o, g: a, b: s, a: l } = this.rgba;
    return new d(new c(e.rgba.r - l * (e.rgba.r - o), e.rgba.g - l * (e.rgba.g - a), e.rgba.b - l * (e.rgba.b - s), 1));
  }
  toString() {
    return this._toString || (this._toString = d.Format.CSS.format(this)), this._toString;
  }
  toNumber32Bit() {
    return this._toNumber32Bit || (this._toNumber32Bit = (this.rgba.r << 24 | this.rgba.g << 16 | this.rgba.b << 8 | this.rgba.a * 255 << 0) >>> 0), this._toNumber32Bit;
  }
  static getLighterColor(e, o, a) {
    if (e.isLighterThan(o))
      return e;
    a = a || 0.5;
    const s = e.getRelativeLuminance(), l = o.getRelativeLuminance();
    return a = a * (l - s) / l, e.lighten(a);
  }
  static getDarkerColor(e, o, a) {
    if (e.isDarkerThan(o))
      return e;
    a = a || 0.5;
    const s = e.getRelativeLuminance(), l = o.getRelativeLuminance();
    return a = a * (s - l) / s, e.darken(a);
  }
  static {
    this.white = new d(new c(255, 255, 255, 1));
  }
  static {
    this.black = new d(new c(0, 0, 0, 1));
  }
  static {
    this.red = new d(new c(255, 0, 0, 1));
  }
  static {
    this.blue = new d(new c(0, 0, 255, 1));
  }
  static {
    this.green = new d(new c(0, 255, 0, 1));
  }
  static {
    this.cyan = new d(new c(0, 255, 255, 1));
  }
  static {
    this.lightgrey = new d(new c(211, 211, 211, 1));
  }
  static {
    this.transparent = new d(new c(0, 0, 0, 0));
  }
}
(function(r) {
  (function(e) {
    (function(o) {
      function a(h) {
        return h.rgba.a === 1 ? `rgb(${h.rgba.r}, ${h.rgba.g}, ${h.rgba.b})` : r.Format.CSS.formatRGBA(h);
      }
      o.formatRGB = a;
      function s(h) {
        return `rgba(${h.rgba.r}, ${h.rgba.g}, ${h.rgba.b}, ${+h.rgba.a.toFixed(2)})`;
      }
      o.formatRGBA = s;
      function l(h) {
        return h.hsla.a === 1 ? `hsl(${h.hsla.h}, ${Math.round(h.hsla.s * 100)}%, ${Math.round(h.hsla.l * 100)}%)` : r.Format.CSS.formatHSLA(h);
      }
      o.formatHSL = l;
      function u(h) {
        return `hsla(${h.hsla.h}, ${Math.round(h.hsla.s * 100)}%, ${Math.round(h.hsla.l * 100)}%, ${h.hsla.a.toFixed(2)})`;
      }
      o.formatHSLA = u;
      function g(h) {
        const v = h.toString(16);
        return v.length !== 2 ? "0" + v : v;
      }
      function b(h) {
        return `#${g(h.rgba.r)}${g(h.rgba.g)}${g(h.rgba.b)}`;
      }
      o.formatHex = b;
      function k(h, v = !1) {
        return v && h.rgba.a === 1 ? r.Format.CSS.formatHex(h) : `#${g(h.rgba.r)}${g(h.rgba.g)}${g(h.rgba.b)}${g(Math.round(h.rgba.a * 255))}`;
      }
      o.formatHexA = k;
      function m(h) {
        return h.isOpaque() ? r.Format.CSS.formatHex(h) : r.Format.CSS.formatRGBA(h);
      }
      o.format = m;
      function F(h) {
        if (h === "transparent")
          return r.transparent;
        if (h.startsWith("#"))
          return K(h);
        if (h.startsWith("rgba(")) {
          const v = h.match(/rgba\((?<r>(?:\+|-)?\d+), *(?<g>(?:\+|-)?\d+), *(?<b>(?:\+|-)?\d+), *(?<a>(?:\+|-)?\d+(\.\d+)?)\)/);
          if (!v)
            throw new Error("Invalid color format " + h);
          const L = parseInt(v.groups?.r ?? "0"), S = parseInt(v.groups?.g ?? "0"), T = parseInt(v.groups?.b ?? "0"), te = parseFloat(v.groups?.a ?? "0");
          return new r(new c(L, S, T, te));
        }
        if (h.startsWith("rgb(")) {
          const v = h.match(/rgb\((?<r>(?:\+|-)?\d+), *(?<g>(?:\+|-)?\d+), *(?<b>(?:\+|-)?\d+)\)/);
          if (!v)
            throw new Error("Invalid color format " + h);
          const L = parseInt(v.groups?.r ?? "0"), S = parseInt(v.groups?.g ?? "0"), T = parseInt(v.groups?.b ?? "0");
          return new r(new c(L, S, T));
        }
        return D(h);
      }
      o.parse = F;
      function D(h) {
        switch (h) {
          case "aliceblue":
            return new r(new c(240, 248, 255, 1));
          case "antiquewhite":
            return new r(new c(250, 235, 215, 1));
          case "aqua":
            return new r(new c(0, 255, 255, 1));
          case "aquamarine":
            return new r(new c(127, 255, 212, 1));
          case "azure":
            return new r(new c(240, 255, 255, 1));
          case "beige":
            return new r(new c(245, 245, 220, 1));
          case "bisque":
            return new r(new c(255, 228, 196, 1));
          case "black":
            return new r(new c(0, 0, 0, 1));
          case "blanchedalmond":
            return new r(new c(255, 235, 205, 1));
          case "blue":
            return new r(new c(0, 0, 255, 1));
          case "blueviolet":
            return new r(new c(138, 43, 226, 1));
          case "brown":
            return new r(new c(165, 42, 42, 1));
          case "burlywood":
            return new r(new c(222, 184, 135, 1));
          case "cadetblue":
            return new r(new c(95, 158, 160, 1));
          case "chartreuse":
            return new r(new c(127, 255, 0, 1));
          case "chocolate":
            return new r(new c(210, 105, 30, 1));
          case "coral":
            return new r(new c(255, 127, 80, 1));
          case "cornflowerblue":
            return new r(new c(100, 149, 237, 1));
          case "cornsilk":
            return new r(new c(255, 248, 220, 1));
          case "crimson":
            return new r(new c(220, 20, 60, 1));
          case "cyan":
            return new r(new c(0, 255, 255, 1));
          case "darkblue":
            return new r(new c(0, 0, 139, 1));
          case "darkcyan":
            return new r(new c(0, 139, 139, 1));
          case "darkgoldenrod":
            return new r(new c(184, 134, 11, 1));
          case "darkgray":
            return new r(new c(169, 169, 169, 1));
          case "darkgreen":
            return new r(new c(0, 100, 0, 1));
          case "darkgrey":
            return new r(new c(169, 169, 169, 1));
          case "darkkhaki":
            return new r(new c(189, 183, 107, 1));
          case "darkmagenta":
            return new r(new c(139, 0, 139, 1));
          case "darkolivegreen":
            return new r(new c(85, 107, 47, 1));
          case "darkorange":
            return new r(new c(255, 140, 0, 1));
          case "darkorchid":
            return new r(new c(153, 50, 204, 1));
          case "darkred":
            return new r(new c(139, 0, 0, 1));
          case "darksalmon":
            return new r(new c(233, 150, 122, 1));
          case "darkseagreen":
            return new r(new c(143, 188, 143, 1));
          case "darkslateblue":
            return new r(new c(72, 61, 139, 1));
          case "darkslategray":
            return new r(new c(47, 79, 79, 1));
          case "darkslategrey":
            return new r(new c(47, 79, 79, 1));
          case "darkturquoise":
            return new r(new c(0, 206, 209, 1));
          case "darkviolet":
            return new r(new c(148, 0, 211, 1));
          case "deeppink":
            return new r(new c(255, 20, 147, 1));
          case "deepskyblue":
            return new r(new c(0, 191, 255, 1));
          case "dimgray":
            return new r(new c(105, 105, 105, 1));
          case "dimgrey":
            return new r(new c(105, 105, 105, 1));
          case "dodgerblue":
            return new r(new c(30, 144, 255, 1));
          case "firebrick":
            return new r(new c(178, 34, 34, 1));
          case "floralwhite":
            return new r(new c(255, 250, 240, 1));
          case "forestgreen":
            return new r(new c(34, 139, 34, 1));
          case "fuchsia":
            return new r(new c(255, 0, 255, 1));
          case "gainsboro":
            return new r(new c(220, 220, 220, 1));
          case "ghostwhite":
            return new r(new c(248, 248, 255, 1));
          case "gold":
            return new r(new c(255, 215, 0, 1));
          case "goldenrod":
            return new r(new c(218, 165, 32, 1));
          case "gray":
            return new r(new c(128, 128, 128, 1));
          case "green":
            return new r(new c(0, 128, 0, 1));
          case "greenyellow":
            return new r(new c(173, 255, 47, 1));
          case "grey":
            return new r(new c(128, 128, 128, 1));
          case "honeydew":
            return new r(new c(240, 255, 240, 1));
          case "hotpink":
            return new r(new c(255, 105, 180, 1));
          case "indianred":
            return new r(new c(205, 92, 92, 1));
          case "indigo":
            return new r(new c(75, 0, 130, 1));
          case "ivory":
            return new r(new c(255, 255, 240, 1));
          case "khaki":
            return new r(new c(240, 230, 140, 1));
          case "lavender":
            return new r(new c(230, 230, 250, 1));
          case "lavenderblush":
            return new r(new c(255, 240, 245, 1));
          case "lawngreen":
            return new r(new c(124, 252, 0, 1));
          case "lemonchiffon":
            return new r(new c(255, 250, 205, 1));
          case "lightblue":
            return new r(new c(173, 216, 230, 1));
          case "lightcoral":
            return new r(new c(240, 128, 128, 1));
          case "lightcyan":
            return new r(new c(224, 255, 255, 1));
          case "lightgoldenrodyellow":
            return new r(new c(250, 250, 210, 1));
          case "lightgray":
            return new r(new c(211, 211, 211, 1));
          case "lightgreen":
            return new r(new c(144, 238, 144, 1));
          case "lightgrey":
            return new r(new c(211, 211, 211, 1));
          case "lightpink":
            return new r(new c(255, 182, 193, 1));
          case "lightsalmon":
            return new r(new c(255, 160, 122, 1));
          case "lightseagreen":
            return new r(new c(32, 178, 170, 1));
          case "lightskyblue":
            return new r(new c(135, 206, 250, 1));
          case "lightslategray":
            return new r(new c(119, 136, 153, 1));
          case "lightslategrey":
            return new r(new c(119, 136, 153, 1));
          case "lightsteelblue":
            return new r(new c(176, 196, 222, 1));
          case "lightyellow":
            return new r(new c(255, 255, 224, 1));
          case "lime":
            return new r(new c(0, 255, 0, 1));
          case "limegreen":
            return new r(new c(50, 205, 50, 1));
          case "linen":
            return new r(new c(250, 240, 230, 1));
          case "magenta":
            return new r(new c(255, 0, 255, 1));
          case "maroon":
            return new r(new c(128, 0, 0, 1));
          case "mediumaquamarine":
            return new r(new c(102, 205, 170, 1));
          case "mediumblue":
            return new r(new c(0, 0, 205, 1));
          case "mediumorchid":
            return new r(new c(186, 85, 211, 1));
          case "mediumpurple":
            return new r(new c(147, 112, 219, 1));
          case "mediumseagreen":
            return new r(new c(60, 179, 113, 1));
          case "mediumslateblue":
            return new r(new c(123, 104, 238, 1));
          case "mediumspringgreen":
            return new r(new c(0, 250, 154, 1));
          case "mediumturquoise":
            return new r(new c(72, 209, 204, 1));
          case "mediumvioletred":
            return new r(new c(199, 21, 133, 1));
          case "midnightblue":
            return new r(new c(25, 25, 112, 1));
          case "mintcream":
            return new r(new c(245, 255, 250, 1));
          case "mistyrose":
            return new r(new c(255, 228, 225, 1));
          case "moccasin":
            return new r(new c(255, 228, 181, 1));
          case "navajowhite":
            return new r(new c(255, 222, 173, 1));
          case "navy":
            return new r(new c(0, 0, 128, 1));
          case "oldlace":
            return new r(new c(253, 245, 230, 1));
          case "olive":
            return new r(new c(128, 128, 0, 1));
          case "olivedrab":
            return new r(new c(107, 142, 35, 1));
          case "orange":
            return new r(new c(255, 165, 0, 1));
          case "orangered":
            return new r(new c(255, 69, 0, 1));
          case "orchid":
            return new r(new c(218, 112, 214, 1));
          case "palegoldenrod":
            return new r(new c(238, 232, 170, 1));
          case "palegreen":
            return new r(new c(152, 251, 152, 1));
          case "paleturquoise":
            return new r(new c(175, 238, 238, 1));
          case "palevioletred":
            return new r(new c(219, 112, 147, 1));
          case "papayawhip":
            return new r(new c(255, 239, 213, 1));
          case "peachpuff":
            return new r(new c(255, 218, 185, 1));
          case "peru":
            return new r(new c(205, 133, 63, 1));
          case "pink":
            return new r(new c(255, 192, 203, 1));
          case "plum":
            return new r(new c(221, 160, 221, 1));
          case "powderblue":
            return new r(new c(176, 224, 230, 1));
          case "purple":
            return new r(new c(128, 0, 128, 1));
          case "rebeccapurple":
            return new r(new c(102, 51, 153, 1));
          case "red":
            return new r(new c(255, 0, 0, 1));
          case "rosybrown":
            return new r(new c(188, 143, 143, 1));
          case "royalblue":
            return new r(new c(65, 105, 225, 1));
          case "saddlebrown":
            return new r(new c(139, 69, 19, 1));
          case "salmon":
            return new r(new c(250, 128, 114, 1));
          case "sandybrown":
            return new r(new c(244, 164, 96, 1));
          case "seagreen":
            return new r(new c(46, 139, 87, 1));
          case "seashell":
            return new r(new c(255, 245, 238, 1));
          case "sienna":
            return new r(new c(160, 82, 45, 1));
          case "silver":
            return new r(new c(192, 192, 192, 1));
          case "skyblue":
            return new r(new c(135, 206, 235, 1));
          case "slateblue":
            return new r(new c(106, 90, 205, 1));
          case "slategray":
            return new r(new c(112, 128, 144, 1));
          case "slategrey":
            return new r(new c(112, 128, 144, 1));
          case "snow":
            return new r(new c(255, 250, 250, 1));
          case "springgreen":
            return new r(new c(0, 255, 127, 1));
          case "steelblue":
            return new r(new c(70, 130, 180, 1));
          case "tan":
            return new r(new c(210, 180, 140, 1));
          case "teal":
            return new r(new c(0, 128, 128, 1));
          case "thistle":
            return new r(new c(216, 191, 216, 1));
          case "tomato":
            return new r(new c(255, 99, 71, 1));
          case "turquoise":
            return new r(new c(64, 224, 208, 1));
          case "violet":
            return new r(new c(238, 130, 238, 1));
          case "wheat":
            return new r(new c(245, 222, 179, 1));
          case "white":
            return new r(new c(255, 255, 255, 1));
          case "whitesmoke":
            return new r(new c(245, 245, 245, 1));
          case "yellow":
            return new r(new c(255, 255, 0, 1));
          case "yellowgreen":
            return new r(new c(154, 205, 50, 1));
          default:
            return null;
        }
      }
      function K(h) {
        const v = h.length;
        if (v === 0 || h.charCodeAt(0) !== 35)
          return null;
        if (v === 7) {
          const L = 16 * w(h.charCodeAt(1)) + w(h.charCodeAt(2)), S = 16 * w(h.charCodeAt(3)) + w(h.charCodeAt(4)), T = 16 * w(h.charCodeAt(5)) + w(h.charCodeAt(6));
          return new r(new c(L, S, T, 1));
        }
        if (v === 9) {
          const L = 16 * w(h.charCodeAt(1)) + w(h.charCodeAt(2)), S = 16 * w(h.charCodeAt(3)) + w(h.charCodeAt(4)), T = 16 * w(h.charCodeAt(5)) + w(h.charCodeAt(6)), te = 16 * w(h.charCodeAt(7)) + w(h.charCodeAt(8));
          return new r(new c(L, S, T, te / 255));
        }
        if (v === 4) {
          const L = w(h.charCodeAt(1)), S = w(h.charCodeAt(2)), T = w(h.charCodeAt(3));
          return new r(new c(16 * L + L, 16 * S + S, 16 * T + T));
        }
        if (v === 5) {
          const L = w(h.charCodeAt(1)), S = w(h.charCodeAt(2)), T = w(h.charCodeAt(3)), te = w(h.charCodeAt(4));
          return new r(new c(16 * L + L, 16 * S + S, 16 * T + T, (16 * te + te) / 255));
        }
        return null;
      }
      o.parseHex = K;
      function w(h) {
        switch (h) {
          case 48:
            return 0;
          case 49:
            return 1;
          case 50:
            return 2;
          case 51:
            return 3;
          case 52:
            return 4;
          case 53:
            return 5;
          case 54:
            return 6;
          case 55:
            return 7;
          case 56:
            return 8;
          case 57:
            return 9;
          case 97:
            return 10;
          case 65:
            return 10;
          case 98:
            return 11;
          case 66:
            return 11;
          case 99:
            return 12;
          case 67:
            return 12;
          case 100:
            return 13;
          case 68:
            return 13;
          case 101:
            return 14;
          case 69:
            return 14;
          case 102:
            return 15;
          case 70:
            return 15;
        }
        return 0;
      }
    })(e.CSS || (e.CSS = {}));
  })(r.Format || (r.Format = {}));
})(d || (d = {}));
const Se = /* @__PURE__ */ Object.create(null);
function t(r, e) {
  if (de(e)) {
    const o = Se[e];
    if (o === void 0)
      throw new Error(`${r} references an unknown codicon: ${e}`);
    e = o;
  }
  return Se[r] = e, { id: r };
}
function nr() {
  return Se;
}
const ir = {
  add: t("add", 6e4),
  plus: t("plus", 6e4),
  gistNew: t("gist-new", 6e4),
  repoCreate: t("repo-create", 6e4),
  lightbulb: t("lightbulb", 60001),
  lightBulb: t("light-bulb", 60001),
  repo: t("repo", 60002),
  repoDelete: t("repo-delete", 60002),
  gistFork: t("gist-fork", 60003),
  repoForked: t("repo-forked", 60003),
  gitPullRequest: t("git-pull-request", 60004),
  gitPullRequestAbandoned: t("git-pull-request-abandoned", 60004),
  recordKeys: t("record-keys", 60005),
  keyboard: t("keyboard", 60005),
  tag: t("tag", 60006),
  gitPullRequestLabel: t("git-pull-request-label", 60006),
  tagAdd: t("tag-add", 60006),
  tagRemove: t("tag-remove", 60006),
  person: t("person", 60007),
  personFollow: t("person-follow", 60007),
  personOutline: t("person-outline", 60007),
  personFilled: t("person-filled", 60007),
  sourceControl: t("source-control", 60008),
  mirror: t("mirror", 60009),
  mirrorPublic: t("mirror-public", 60009),
  star: t("star", 60010),
  starAdd: t("star-add", 60010),
  starDelete: t("star-delete", 60010),
  starEmpty: t("star-empty", 60010),
  comment: t("comment", 60011),
  commentAdd: t("comment-add", 60011),
  alert: t("alert", 60012),
  warning: t("warning", 60012),
  search: t("search", 60013),
  searchSave: t("search-save", 60013),
  logOut: t("log-out", 60014),
  signOut: t("sign-out", 60014),
  logIn: t("log-in", 60015),
  signIn: t("sign-in", 60015),
  eye: t("eye", 60016),
  eyeUnwatch: t("eye-unwatch", 60016),
  eyeWatch: t("eye-watch", 60016),
  circleFilled: t("circle-filled", 60017),
  primitiveDot: t("primitive-dot", 60017),
  closeDirty: t("close-dirty", 60017),
  debugBreakpoint: t("debug-breakpoint", 60017),
  debugBreakpointDisabled: t("debug-breakpoint-disabled", 60017),
  debugHint: t("debug-hint", 60017),
  terminalDecorationSuccess: t("terminal-decoration-success", 60017),
  primitiveSquare: t("primitive-square", 60018),
  edit: t("edit", 60019),
  pencil: t("pencil", 60019),
  info: t("info", 60020),
  issueOpened: t("issue-opened", 60020),
  gistPrivate: t("gist-private", 60021),
  gitForkPrivate: t("git-fork-private", 60021),
  lock: t("lock", 60021),
  mirrorPrivate: t("mirror-private", 60021),
  close: t("close", 60022),
  removeClose: t("remove-close", 60022),
  x: t("x", 60022),
  repoSync: t("repo-sync", 60023),
  sync: t("sync", 60023),
  clone: t("clone", 60024),
  desktopDownload: t("desktop-download", 60024),
  beaker: t("beaker", 60025),
  microscope: t("microscope", 60025),
  vm: t("vm", 60026),
  deviceDesktop: t("device-desktop", 60026),
  file: t("file", 60027),
  more: t("more", 60028),
  ellipsis: t("ellipsis", 60028),
  kebabHorizontal: t("kebab-horizontal", 60028),
  mailReply: t("mail-reply", 60029),
  reply: t("reply", 60029),
  organization: t("organization", 60030),
  organizationFilled: t("organization-filled", 60030),
  organizationOutline: t("organization-outline", 60030),
  newFile: t("new-file", 60031),
  fileAdd: t("file-add", 60031),
  newFolder: t("new-folder", 60032),
  fileDirectoryCreate: t("file-directory-create", 60032),
  trash: t("trash", 60033),
  trashcan: t("trashcan", 60033),
  history: t("history", 60034),
  clock: t("clock", 60034),
  folder: t("folder", 60035),
  fileDirectory: t("file-directory", 60035),
  symbolFolder: t("symbol-folder", 60035),
  logoGithub: t("logo-github", 60036),
  markGithub: t("mark-github", 60036),
  github: t("github", 60036),
  terminal: t("terminal", 60037),
  console: t("console", 60037),
  repl: t("repl", 60037),
  zap: t("zap", 60038),
  symbolEvent: t("symbol-event", 60038),
  error: t("error", 60039),
  stop: t("stop", 60039),
  variable: t("variable", 60040),
  symbolVariable: t("symbol-variable", 60040),
  array: t("array", 60042),
  symbolArray: t("symbol-array", 60042),
  symbolModule: t("symbol-module", 60043),
  symbolPackage: t("symbol-package", 60043),
  symbolNamespace: t("symbol-namespace", 60043),
  symbolObject: t("symbol-object", 60043),
  symbolMethod: t("symbol-method", 60044),
  symbolFunction: t("symbol-function", 60044),
  symbolConstructor: t("symbol-constructor", 60044),
  symbolBoolean: t("symbol-boolean", 60047),
  symbolNull: t("symbol-null", 60047),
  symbolNumeric: t("symbol-numeric", 60048),
  symbolNumber: t("symbol-number", 60048),
  symbolStructure: t("symbol-structure", 60049),
  symbolStruct: t("symbol-struct", 60049),
  symbolParameter: t("symbol-parameter", 60050),
  symbolTypeParameter: t("symbol-type-parameter", 60050),
  symbolKey: t("symbol-key", 60051),
  symbolText: t("symbol-text", 60051),
  symbolReference: t("symbol-reference", 60052),
  goToFile: t("go-to-file", 60052),
  symbolEnum: t("symbol-enum", 60053),
  symbolValue: t("symbol-value", 60053),
  symbolRuler: t("symbol-ruler", 60054),
  symbolUnit: t("symbol-unit", 60054),
  activateBreakpoints: t("activate-breakpoints", 60055),
  archive: t("archive", 60056),
  arrowBoth: t("arrow-both", 60057),
  arrowDown: t("arrow-down", 60058),
  arrowLeft: t("arrow-left", 60059),
  arrowRight: t("arrow-right", 60060),
  arrowSmallDown: t("arrow-small-down", 60061),
  arrowSmallLeft: t("arrow-small-left", 60062),
  arrowSmallRight: t("arrow-small-right", 60063),
  arrowSmallUp: t("arrow-small-up", 60064),
  arrowUp: t("arrow-up", 60065),
  bell: t("bell", 60066),
  bold: t("bold", 60067),
  book: t("book", 60068),
  bookmark: t("bookmark", 60069),
  debugBreakpointConditionalUnverified: t("debug-breakpoint-conditional-unverified", 60070),
  debugBreakpointConditional: t("debug-breakpoint-conditional", 60071),
  debugBreakpointConditionalDisabled: t("debug-breakpoint-conditional-disabled", 60071),
  debugBreakpointDataUnverified: t("debug-breakpoint-data-unverified", 60072),
  debugBreakpointData: t("debug-breakpoint-data", 60073),
  debugBreakpointDataDisabled: t("debug-breakpoint-data-disabled", 60073),
  debugBreakpointLogUnverified: t("debug-breakpoint-log-unverified", 60074),
  debugBreakpointLog: t("debug-breakpoint-log", 60075),
  debugBreakpointLogDisabled: t("debug-breakpoint-log-disabled", 60075),
  briefcase: t("briefcase", 60076),
  broadcast: t("broadcast", 60077),
  browser: t("browser", 60078),
  bug: t("bug", 60079),
  calendar: t("calendar", 60080),
  caseSensitive: t("case-sensitive", 60081),
  check: t("check", 60082),
  checklist: t("checklist", 60083),
  chevronDown: t("chevron-down", 60084),
  chevronLeft: t("chevron-left", 60085),
  chevronRight: t("chevron-right", 60086),
  chevronUp: t("chevron-up", 60087),
  chromeClose: t("chrome-close", 60088),
  chromeMaximize: t("chrome-maximize", 60089),
  chromeMinimize: t("chrome-minimize", 60090),
  chromeRestore: t("chrome-restore", 60091),
  circleOutline: t("circle-outline", 60092),
  circle: t("circle", 60092),
  debugBreakpointUnverified: t("debug-breakpoint-unverified", 60092),
  terminalDecorationIncomplete: t("terminal-decoration-incomplete", 60092),
  circleSlash: t("circle-slash", 60093),
  circuitBoard: t("circuit-board", 60094),
  clearAll: t("clear-all", 60095),
  clippy: t("clippy", 60096),
  closeAll: t("close-all", 60097),
  cloudDownload: t("cloud-download", 60098),
  cloudUpload: t("cloud-upload", 60099),
  code: t("code", 60100),
  collapseAll: t("collapse-all", 60101),
  colorMode: t("color-mode", 60102),
  commentDiscussion: t("comment-discussion", 60103),
  creditCard: t("credit-card", 60105),
  dash: t("dash", 60108),
  dashboard: t("dashboard", 60109),
  database: t("database", 60110),
  debugContinue: t("debug-continue", 60111),
  debugDisconnect: t("debug-disconnect", 60112),
  debugPause: t("debug-pause", 60113),
  debugRestart: t("debug-restart", 60114),
  debugStart: t("debug-start", 60115),
  debugStepInto: t("debug-step-into", 60116),
  debugStepOut: t("debug-step-out", 60117),
  debugStepOver: t("debug-step-over", 60118),
  debugStop: t("debug-stop", 60119),
  debug: t("debug", 60120),
  deviceCameraVideo: t("device-camera-video", 60121),
  deviceCamera: t("device-camera", 60122),
  deviceMobile: t("device-mobile", 60123),
  diffAdded: t("diff-added", 60124),
  diffIgnored: t("diff-ignored", 60125),
  diffModified: t("diff-modified", 60126),
  diffRemoved: t("diff-removed", 60127),
  diffRenamed: t("diff-renamed", 60128),
  diff: t("diff", 60129),
  diffSidebyside: t("diff-sidebyside", 60129),
  discard: t("discard", 60130),
  editorLayout: t("editor-layout", 60131),
  emptyWindow: t("empty-window", 60132),
  exclude: t("exclude", 60133),
  extensions: t("extensions", 60134),
  eyeClosed: t("eye-closed", 60135),
  fileBinary: t("file-binary", 60136),
  fileCode: t("file-code", 60137),
  fileMedia: t("file-media", 60138),
  filePdf: t("file-pdf", 60139),
  fileSubmodule: t("file-submodule", 60140),
  fileSymlinkDirectory: t("file-symlink-directory", 60141),
  fileSymlinkFile: t("file-symlink-file", 60142),
  fileZip: t("file-zip", 60143),
  files: t("files", 60144),
  filter: t("filter", 60145),
  flame: t("flame", 60146),
  foldDown: t("fold-down", 60147),
  foldUp: t("fold-up", 60148),
  fold: t("fold", 60149),
  folderActive: t("folder-active", 60150),
  folderOpened: t("folder-opened", 60151),
  gear: t("gear", 60152),
  gift: t("gift", 60153),
  gistSecret: t("gist-secret", 60154),
  gist: t("gist", 60155),
  gitCommit: t("git-commit", 60156),
  gitCompare: t("git-compare", 60157),
  compareChanges: t("compare-changes", 60157),
  gitMerge: t("git-merge", 60158),
  githubAction: t("github-action", 60159),
  githubAlt: t("github-alt", 60160),
  globe: t("globe", 60161),
  grabber: t("grabber", 60162),
  graph: t("graph", 60163),
  gripper: t("gripper", 60164),
  heart: t("heart", 60165),
  home: t("home", 60166),
  horizontalRule: t("horizontal-rule", 60167),
  hubot: t("hubot", 60168),
  inbox: t("inbox", 60169),
  issueReopened: t("issue-reopened", 60171),
  issues: t("issues", 60172),
  italic: t("italic", 60173),
  jersey: t("jersey", 60174),
  json: t("json", 60175),
  kebabVertical: t("kebab-vertical", 60176),
  key: t("key", 60177),
  law: t("law", 60178),
  lightbulbAutofix: t("lightbulb-autofix", 60179),
  linkExternal: t("link-external", 60180),
  link: t("link", 60181),
  listOrdered: t("list-ordered", 60182),
  listUnordered: t("list-unordered", 60183),
  liveShare: t("live-share", 60184),
  loading: t("loading", 60185),
  location: t("location", 60186),
  mailRead: t("mail-read", 60187),
  mail: t("mail", 60188),
  markdown: t("markdown", 60189),
  megaphone: t("megaphone", 60190),
  mention: t("mention", 60191),
  milestone: t("milestone", 60192),
  gitPullRequestMilestone: t("git-pull-request-milestone", 60192),
  mortarBoard: t("mortar-board", 60193),
  move: t("move", 60194),
  multipleWindows: t("multiple-windows", 60195),
  mute: t("mute", 60196),
  noNewline: t("no-newline", 60197),
  note: t("note", 60198),
  octoface: t("octoface", 60199),
  openPreview: t("open-preview", 60200),
  package: t("package", 60201),
  paintcan: t("paintcan", 60202),
  pin: t("pin", 60203),
  play: t("play", 60204),
  run: t("run", 60204),
  plug: t("plug", 60205),
  preserveCase: t("preserve-case", 60206),
  preview: t("preview", 60207),
  project: t("project", 60208),
  pulse: t("pulse", 60209),
  question: t("question", 60210),
  quote: t("quote", 60211),
  radioTower: t("radio-tower", 60212),
  reactions: t("reactions", 60213),
  references: t("references", 60214),
  refresh: t("refresh", 60215),
  regex: t("regex", 60216),
  remoteExplorer: t("remote-explorer", 60217),
  remote: t("remote", 60218),
  remove: t("remove", 60219),
  replaceAll: t("replace-all", 60220),
  replace: t("replace", 60221),
  repoClone: t("repo-clone", 60222),
  repoForcePush: t("repo-force-push", 60223),
  repoPull: t("repo-pull", 60224),
  repoPush: t("repo-push", 60225),
  report: t("report", 60226),
  requestChanges: t("request-changes", 60227),
  rocket: t("rocket", 60228),
  rootFolderOpened: t("root-folder-opened", 60229),
  rootFolder: t("root-folder", 60230),
  rss: t("rss", 60231),
  ruby: t("ruby", 60232),
  saveAll: t("save-all", 60233),
  saveAs: t("save-as", 60234),
  save: t("save", 60235),
  screenFull: t("screen-full", 60236),
  screenNormal: t("screen-normal", 60237),
  searchStop: t("search-stop", 60238),
  server: t("server", 60240),
  settingsGear: t("settings-gear", 60241),
  settings: t("settings", 60242),
  shield: t("shield", 60243),
  smiley: t("smiley", 60244),
  sortPrecedence: t("sort-precedence", 60245),
  splitHorizontal: t("split-horizontal", 60246),
  splitVertical: t("split-vertical", 60247),
  squirrel: t("squirrel", 60248),
  starFull: t("star-full", 60249),
  starHalf: t("star-half", 60250),
  symbolClass: t("symbol-class", 60251),
  symbolColor: t("symbol-color", 60252),
  symbolConstant: t("symbol-constant", 60253),
  symbolEnumMember: t("symbol-enum-member", 60254),
  symbolField: t("symbol-field", 60255),
  symbolFile: t("symbol-file", 60256),
  symbolInterface: t("symbol-interface", 60257),
  symbolKeyword: t("symbol-keyword", 60258),
  symbolMisc: t("symbol-misc", 60259),
  symbolOperator: t("symbol-operator", 60260),
  symbolProperty: t("symbol-property", 60261),
  wrench: t("wrench", 60261),
  wrenchSubaction: t("wrench-subaction", 60261),
  symbolSnippet: t("symbol-snippet", 60262),
  tasklist: t("tasklist", 60263),
  telescope: t("telescope", 60264),
  textSize: t("text-size", 60265),
  threeBars: t("three-bars", 60266),
  thumbsdown: t("thumbsdown", 60267),
  thumbsup: t("thumbsup", 60268),
  tools: t("tools", 60269),
  triangleDown: t("triangle-down", 60270),
  triangleLeft: t("triangle-left", 60271),
  triangleRight: t("triangle-right", 60272),
  triangleUp: t("triangle-up", 60273),
  twitter: t("twitter", 60274),
  unfold: t("unfold", 60275),
  unlock: t("unlock", 60276),
  unmute: t("unmute", 60277),
  unverified: t("unverified", 60278),
  verified: t("verified", 60279),
  versions: t("versions", 60280),
  vmActive: t("vm-active", 60281),
  vmOutline: t("vm-outline", 60282),
  vmRunning: t("vm-running", 60283),
  watch: t("watch", 60284),
  whitespace: t("whitespace", 60285),
  wholeWord: t("whole-word", 60286),
  window: t("window", 60287),
  wordWrap: t("word-wrap", 60288),
  zoomIn: t("zoom-in", 60289),
  zoomOut: t("zoom-out", 60290),
  listFilter: t("list-filter", 60291),
  listFlat: t("list-flat", 60292),
  listSelection: t("list-selection", 60293),
  selection: t("selection", 60293),
  listTree: t("list-tree", 60294),
  debugBreakpointFunctionUnverified: t("debug-breakpoint-function-unverified", 60295),
  debugBreakpointFunction: t("debug-breakpoint-function", 60296),
  debugBreakpointFunctionDisabled: t("debug-breakpoint-function-disabled", 60296),
  debugStackframeActive: t("debug-stackframe-active", 60297),
  circleSmallFilled: t("circle-small-filled", 60298),
  debugStackframeDot: t("debug-stackframe-dot", 60298),
  terminalDecorationMark: t("terminal-decoration-mark", 60298),
  debugStackframe: t("debug-stackframe", 60299),
  debugStackframeFocused: t("debug-stackframe-focused", 60299),
  debugBreakpointUnsupported: t("debug-breakpoint-unsupported", 60300),
  symbolString: t("symbol-string", 60301),
  debugReverseContinue: t("debug-reverse-continue", 60302),
  debugStepBack: t("debug-step-back", 60303),
  debugRestartFrame: t("debug-restart-frame", 60304),
  debugAlt: t("debug-alt", 60305),
  callIncoming: t("call-incoming", 60306),
  callOutgoing: t("call-outgoing", 60307),
  menu: t("menu", 60308),
  expandAll: t("expand-all", 60309),
  feedback: t("feedback", 60310),
  gitPullRequestReviewer: t("git-pull-request-reviewer", 60310),
  groupByRefType: t("group-by-ref-type", 60311),
  ungroupByRefType: t("ungroup-by-ref-type", 60312),
  account: t("account", 60313),
  gitPullRequestAssignee: t("git-pull-request-assignee", 60313),
  bellDot: t("bell-dot", 60314),
  debugConsole: t("debug-console", 60315),
  library: t("library", 60316),
  output: t("output", 60317),
  runAll: t("run-all", 60318),
  syncIgnored: t("sync-ignored", 60319),
  pinned: t("pinned", 60320),
  githubInverted: t("github-inverted", 60321),
  serverProcess: t("server-process", 60322),
  serverEnvironment: t("server-environment", 60323),
  pass: t("pass", 60324),
  issueClosed: t("issue-closed", 60324),
  stopCircle: t("stop-circle", 60325),
  playCircle: t("play-circle", 60326),
  record: t("record", 60327),
  debugAltSmall: t("debug-alt-small", 60328),
  vmConnect: t("vm-connect", 60329),
  cloud: t("cloud", 60330),
  merge: t("merge", 60331),
  export: t("export", 60332),
  graphLeft: t("graph-left", 60333),
  magnet: t("magnet", 60334),
  notebook: t("notebook", 60335),
  redo: t("redo", 60336),
  checkAll: t("check-all", 60337),
  pinnedDirty: t("pinned-dirty", 60338),
  passFilled: t("pass-filled", 60339),
  circleLargeFilled: t("circle-large-filled", 60340),
  circleLarge: t("circle-large", 60341),
  circleLargeOutline: t("circle-large-outline", 60341),
  combine: t("combine", 60342),
  gather: t("gather", 60342),
  table: t("table", 60343),
  variableGroup: t("variable-group", 60344),
  typeHierarchy: t("type-hierarchy", 60345),
  typeHierarchySub: t("type-hierarchy-sub", 60346),
  typeHierarchySuper: t("type-hierarchy-super", 60347),
  gitPullRequestCreate: t("git-pull-request-create", 60348),
  runAbove: t("run-above", 60349),
  runBelow: t("run-below", 60350),
  notebookTemplate: t("notebook-template", 60351),
  debugRerun: t("debug-rerun", 60352),
  workspaceTrusted: t("workspace-trusted", 60353),
  workspaceUntrusted: t("workspace-untrusted", 60354),
  workspaceUnknown: t("workspace-unknown", 60355),
  terminalCmd: t("terminal-cmd", 60356),
  terminalDebian: t("terminal-debian", 60357),
  terminalLinux: t("terminal-linux", 60358),
  terminalPowershell: t("terminal-powershell", 60359),
  terminalTmux: t("terminal-tmux", 60360),
  terminalUbuntu: t("terminal-ubuntu", 60361),
  terminalBash: t("terminal-bash", 60362),
  arrowSwap: t("arrow-swap", 60363),
  copy: t("copy", 60364),
  personAdd: t("person-add", 60365),
  filterFilled: t("filter-filled", 60366),
  wand: t("wand", 60367),
  debugLineByLine: t("debug-line-by-line", 60368),
  inspect: t("inspect", 60369),
  layers: t("layers", 60370),
  layersDot: t("layers-dot", 60371),
  layersActive: t("layers-active", 60372),
  compass: t("compass", 60373),
  compassDot: t("compass-dot", 60374),
  compassActive: t("compass-active", 60375),
  azure: t("azure", 60376),
  issueDraft: t("issue-draft", 60377),
  gitPullRequestClosed: t("git-pull-request-closed", 60378),
  gitPullRequestDraft: t("git-pull-request-draft", 60379),
  debugAll: t("debug-all", 60380),
  debugCoverage: t("debug-coverage", 60381),
  runErrors: t("run-errors", 60382),
  folderLibrary: t("folder-library", 60383),
  debugContinueSmall: t("debug-continue-small", 60384),
  beakerStop: t("beaker-stop", 60385),
  graphLine: t("graph-line", 60386),
  graphScatter: t("graph-scatter", 60387),
  pieChart: t("pie-chart", 60388),
  bracket: t("bracket", 60175),
  bracketDot: t("bracket-dot", 60389),
  bracketError: t("bracket-error", 60390),
  lockSmall: t("lock-small", 60391),
  azureDevops: t("azure-devops", 60392),
  verifiedFilled: t("verified-filled", 60393),
  newline: t("newline", 60394),
  layout: t("layout", 60395),
  layoutActivitybarLeft: t("layout-activitybar-left", 60396),
  layoutActivitybarRight: t("layout-activitybar-right", 60397),
  layoutPanelLeft: t("layout-panel-left", 60398),
  layoutPanelCenter: t("layout-panel-center", 60399),
  layoutPanelJustify: t("layout-panel-justify", 60400),
  layoutPanelRight: t("layout-panel-right", 60401),
  layoutPanel: t("layout-panel", 60402),
  layoutSidebarLeft: t("layout-sidebar-left", 60403),
  layoutSidebarRight: t("layout-sidebar-right", 60404),
  layoutStatusbar: t("layout-statusbar", 60405),
  layoutMenubar: t("layout-menubar", 60406),
  layoutCentered: t("layout-centered", 60407),
  target: t("target", 60408),
  indent: t("indent", 60409),
  recordSmall: t("record-small", 60410),
  errorSmall: t("error-small", 60411),
  terminalDecorationError: t("terminal-decoration-error", 60411),
  arrowCircleDown: t("arrow-circle-down", 60412),
  arrowCircleLeft: t("arrow-circle-left", 60413),
  arrowCircleRight: t("arrow-circle-right", 60414),
  arrowCircleUp: t("arrow-circle-up", 60415),
  layoutSidebarRightOff: t("layout-sidebar-right-off", 60416),
  layoutPanelOff: t("layout-panel-off", 60417),
  layoutSidebarLeftOff: t("layout-sidebar-left-off", 60418),
  blank: t("blank", 60419),
  heartFilled: t("heart-filled", 60420),
  map: t("map", 60421),
  mapHorizontal: t("map-horizontal", 60421),
  foldHorizontal: t("fold-horizontal", 60421),
  mapFilled: t("map-filled", 60422),
  mapHorizontalFilled: t("map-horizontal-filled", 60422),
  foldHorizontalFilled: t("fold-horizontal-filled", 60422),
  circleSmall: t("circle-small", 60423),
  bellSlash: t("bell-slash", 60424),
  bellSlashDot: t("bell-slash-dot", 60425),
  commentUnresolved: t("comment-unresolved", 60426),
  gitPullRequestGoToChanges: t("git-pull-request-go-to-changes", 60427),
  gitPullRequestNewChanges: t("git-pull-request-new-changes", 60428),
  searchFuzzy: t("search-fuzzy", 60429),
  commentDraft: t("comment-draft", 60430),
  send: t("send", 60431),
  sparkle: t("sparkle", 60432),
  insert: t("insert", 60433),
  mic: t("mic", 60434),
  thumbsdownFilled: t("thumbsdown-filled", 60435),
  thumbsupFilled: t("thumbsup-filled", 60436),
  coffee: t("coffee", 60437),
  snake: t("snake", 60438),
  game: t("game", 60439),
  vr: t("vr", 60440),
  chip: t("chip", 60441),
  piano: t("piano", 60442),
  music: t("music", 60443),
  micFilled: t("mic-filled", 60444),
  repoFetch: t("repo-fetch", 60445),
  copilot: t("copilot", 60446),
  lightbulbSparkle: t("lightbulb-sparkle", 60447),
  robot: t("robot", 60448),
  sparkleFilled: t("sparkle-filled", 60449),
  diffSingle: t("diff-single", 60450),
  diffMultiple: t("diff-multiple", 60451),
  surroundWith: t("surround-with", 60452),
  share: t("share", 60453),
  gitStash: t("git-stash", 60454),
  gitStashApply: t("git-stash-apply", 60455),
  gitStashPop: t("git-stash-pop", 60456),
  vscode: t("vscode", 60457),
  vscodeInsiders: t("vscode-insiders", 60458),
  codeOss: t("code-oss", 60459),
  runCoverage: t("run-coverage", 60460),
  runAllCoverage: t("run-all-coverage", 60461),
  coverage: t("coverage", 60462),
  githubProject: t("github-project", 60463),
  mapVertical: t("map-vertical", 60464),
  foldVertical: t("fold-vertical", 60464),
  mapVerticalFilled: t("map-vertical-filled", 60465),
  foldVerticalFilled: t("fold-vertical-filled", 60465),
  goToSearch: t("go-to-search", 60466),
  percentage: t("percentage", 60467),
  sortPercentage: t("sort-percentage", 60467),
  attach: t("attach", 60468),
  goToEditingSession: t("go-to-editing-session", 60469),
  editSession: t("edit-session", 60470),
  codeReview: t("code-review", 60471),
  copilotWarning: t("copilot-warning", 60472),
  python: t("python", 60473),
  copilotLarge: t("copilot-large", 60474),
  copilotWarningLarge: t("copilot-warning-large", 60475),
  keyboardTab: t("keyboard-tab", 60476),
  copilotBlocked: t("copilot-blocked", 60477),
  copilotNotConnected: t("copilot-not-connected", 60478),
  flag: t("flag", 60479),
  lightbulbEmpty: t("lightbulb-empty", 60480),
  symbolMethodArrow: t("symbol-method-arrow", 60481),
  copilotUnavailable: t("copilot-unavailable", 60482),
  repoPinned: t("repo-pinned", 60483),
  keyboardTabAbove: t("keyboard-tab-above", 60484),
  keyboardTabBelow: t("keyboard-tab-below", 60485),
  gitPullRequestDone: t("git-pull-request-done", 60486),
  mcp: t("mcp", 60487),
  extensionsLarge: t("extensions-large", 60488),
  layoutPanelDock: t("layout-panel-dock", 60489),
  layoutSidebarLeftDock: t("layout-sidebar-left-dock", 60490),
  layoutSidebarRightDock: t("layout-sidebar-right-dock", 60491),
  copilotInProgress: t("copilot-in-progress", 60492),
  copilotError: t("copilot-error", 60493),
  copilotSuccess: t("copilot-success", 60494),
  chatSparkle: t("chat-sparkle", 60495),
  searchSparkle: t("search-sparkle", 60496),
  editSparkle: t("edit-sparkle", 60497),
  copilotSnooze: t("copilot-snooze", 60498),
  sendToRemoteAgent: t("send-to-remote-agent", 60499),
  commentDiscussionSparkle: t("comment-discussion-sparkle", 60500),
  chatSparkleWarning: t("chat-sparkle-warning", 60501),
  chatSparkleError: t("chat-sparkle-error", 60502),
  collection: t("collection", 60503),
  newCollection: t("new-collection", 60504),
  thinking: t("thinking", 60505),
  build: t("build", 60506),
  commentDiscussionQuote: t("comment-discussion-quote", 60507),
  cursor: t("cursor", 60508),
  eraser: t("eraser", 60509),
  fileText: t("file-text", 60510),
  gitLens: t("git-lens", 60511),
  quotes: t("quotes", 60512),
  rename: t("rename", 60513),
  runWithDeps: t("run-with-deps", 60514),
  debugConnected: t("debug-connected", 60515),
  strikethrough: t("strikethrough", 60516),
  openInProduct: t("open-in-product", 60517),
  indexZero: t("index-zero", 60518),
  agent: t("agent", 60519),
  editCode: t("edit-code", 60520),
  repoSelected: t("repo-selected", 60521),
  skip: t("skip", 60522),
  mergeInto: t("merge-into", 60523),
  gitBranchChanges: t("git-branch-changes", 60524),
  gitBranchStagedChanges: t("git-branch-staged-changes", 60525),
  gitBranchConflicts: t("git-branch-conflicts", 60526),
  gitBranch: t("git-branch", 60527),
  gitBranchCreate: t("git-branch-create", 60527),
  gitBranchDelete: t("git-branch-delete", 60527),
  searchLarge: t("search-large", 60528),
  terminalGitBash: t("terminal-git-bash", 60529)
}, ar = {
  dialogError: t("dialog-error", "error"),
  dialogWarning: t("dialog-warning", "warning"),
  dialogInfo: t("dialog-info", "info"),
  dialogClose: t("dialog-close", "close"),
  treeItemExpanded: t("tree-item-expanded", "chevron-down"),
  // collapsed is done with rotation
  treeFilterOnTypeOn: t("tree-filter-on-type-on", "list-filter"),
  treeFilterOnTypeOff: t("tree-filter-on-type-off", "list-selection"),
  treeFilterClear: t("tree-filter-clear", "close"),
  treeItemLoading: t("tree-item-loading", "loading"),
  menuSelection: t("menu-selection", "check"),
  menuSubmenu: t("menu-submenu", "chevron-right"),
  menuBarMore: t("menubar-more", "more"),
  scrollbarButtonLeft: t("scrollbar-button-left", "triangle-left"),
  scrollbarButtonRight: t("scrollbar-button-right", "triangle-right"),
  scrollbarButtonUp: t("scrollbar-button-up", "triangle-up"),
  scrollbarButtonDown: t("scrollbar-button-down", "triangle-down"),
  toolBarMore: t("toolbar-more", "more"),
  quickInputBack: t("quick-input-back", "arrow-left"),
  dropDownButton: t("drop-down-button", 60084),
  symbolCustomColor: t("symbol-customcolor", 60252),
  exportIcon: t("export", 60332),
  workspaceUnspecified: t("workspace-unspecified", 60355),
  newLine: t("newline", 60394),
  thumbsDownFilled: t("thumbsdown-filled", 60435),
  thumbsUpFilled: t("thumbsup-filled", 60436),
  gitFetch: t("git-fetch", 60445),
  lightbulbSparkleAutofix: t("lightbulb-sparkle-autofix", 60447),
  debugBreakpointPending: t("debug-breakpoint-pending", 60377)
}, f = {
  ...ir,
  ...ar
};
class O {
  constructor(e, o) {
    this.lineNumber = e, this.column = o;
  }
  /**
   * Create a new position from this position.
   *
   * @param newLineNumber new line number
   * @param newColumn new column
   */
  with(e = this.lineNumber, o = this.column) {
    return e === this.lineNumber && o === this.column ? this : new O(e, o);
  }
  /**
   * Derive a new position from this position.
   *
   * @param deltaLineNumber line number delta
   * @param deltaColumn column delta
   */
  delta(e = 0, o = 0) {
    return this.with(Math.max(1, this.lineNumber + e), Math.max(1, this.column + o));
  }
  /**
   * Test if this position equals other position
   */
  equals(e) {
    return O.equals(this, e);
  }
  /**
   * Test if position `a` equals position `b`
   */
  static equals(e, o) {
    return !e && !o ? !0 : !!e && !!o && e.lineNumber === o.lineNumber && e.column === o.column;
  }
  /**
   * Test if this position is before other position.
   * If the two positions are equal, the result will be false.
   */
  isBefore(e) {
    return O.isBefore(this, e);
  }
  /**
   * Test if position `a` is before position `b`.
   * If the two positions are equal, the result will be false.
   */
  static isBefore(e, o) {
    return e.lineNumber < o.lineNumber ? !0 : o.lineNumber < e.lineNumber ? !1 : e.column < o.column;
  }
  /**
   * Test if this position is before other position.
   * If the two positions are equal, the result will be true.
   */
  isBeforeOrEqual(e) {
    return O.isBeforeOrEqual(this, e);
  }
  /**
   * Test if position `a` is before position `b`.
   * If the two positions are equal, the result will be true.
   */
  static isBeforeOrEqual(e, o) {
    return e.lineNumber < o.lineNumber ? !0 : o.lineNumber < e.lineNumber ? !1 : e.column <= o.column;
  }
  /**
   * A function that compares positions, useful for sorting
   */
  static compare(e, o) {
    const a = e.lineNumber | 0, s = o.lineNumber | 0;
    if (a === s) {
      const l = e.column | 0, u = o.column | 0;
      return l - u;
    }
    return a - s;
  }
  /**
   * Clone this position.
   */
  clone() {
    return new O(this.lineNumber, this.column);
  }
  /**
   * Convert to a human-readable representation.
   */
  toString() {
    return "(" + this.lineNumber + "," + this.column + ")";
  }
  // ---
  /**
   * Create a `Position` from an `IPosition`.
   */
  static lift(e) {
    return new O(e.lineNumber, e.column);
  }
  /**
   * Test if `obj` is an `IPosition`.
   */
  static isIPosition(e) {
    return !!e && typeof e.lineNumber == "number" && typeof e.column == "number";
  }
  toJSON() {
    return {
      lineNumber: this.lineNumber,
      column: this.column
    };
  }
}
class B {
  constructor(e, o, a, s) {
    e > a || e === a && o > s ? (this.startLineNumber = a, this.startColumn = s, this.endLineNumber = e, this.endColumn = o) : (this.startLineNumber = e, this.startColumn = o, this.endLineNumber = a, this.endColumn = s);
  }
  /**
   * Test if this range is empty.
   */
  isEmpty() {
    return B.isEmpty(this);
  }
  /**
   * Test if `range` is empty.
   */
  static isEmpty(e) {
    return e.startLineNumber === e.endLineNumber && e.startColumn === e.endColumn;
  }
  /**
   * Test if position is in this range. If the position is at the edges, will return true.
   */
  containsPosition(e) {
    return B.containsPosition(this, e);
  }
  /**
   * Test if `position` is in `range`. If the position is at the edges, will return true.
   */
  static containsPosition(e, o) {
    return !(o.lineNumber < e.startLineNumber || o.lineNumber > e.endLineNumber || o.lineNumber === e.startLineNumber && o.column < e.startColumn || o.lineNumber === e.endLineNumber && o.column > e.endColumn);
  }
  /**
   * Test if `position` is in `range`. If the position is at the edges, will return false.
   * @internal
   */
  static strictContainsPosition(e, o) {
    return !(o.lineNumber < e.startLineNumber || o.lineNumber > e.endLineNumber || o.lineNumber === e.startLineNumber && o.column <= e.startColumn || o.lineNumber === e.endLineNumber && o.column >= e.endColumn);
  }
  /**
   * Test if range is in this range. If the range is equal to this range, will return true.
   */
  containsRange(e) {
    return B.containsRange(this, e);
  }
  /**
   * Test if `otherRange` is in `range`. If the ranges are equal, will return true.
   */
  static containsRange(e, o) {
    return !(o.startLineNumber < e.startLineNumber || o.endLineNumber < e.startLineNumber || o.startLineNumber > e.endLineNumber || o.endLineNumber > e.endLineNumber || o.startLineNumber === e.startLineNumber && o.startColumn < e.startColumn || o.endLineNumber === e.endLineNumber && o.endColumn > e.endColumn);
  }
  /**
   * Test if `range` is strictly in this range. `range` must start after and end before this range for the result to be true.
   */
  strictContainsRange(e) {
    return B.strictContainsRange(this, e);
  }
  /**
   * Test if `otherRange` is strictly in `range` (must start after, and end before). If the ranges are equal, will return false.
   */
  static strictContainsRange(e, o) {
    return !(o.startLineNumber < e.startLineNumber || o.endLineNumber < e.startLineNumber || o.startLineNumber > e.endLineNumber || o.endLineNumber > e.endLineNumber || o.startLineNumber === e.startLineNumber && o.startColumn <= e.startColumn || o.endLineNumber === e.endLineNumber && o.endColumn >= e.endColumn);
  }
  /**
   * A reunion of the two ranges.
   * The smallest position will be used as the start point, and the largest one as the end point.
   */
  plusRange(e) {
    return B.plusRange(this, e);
  }
  /**
   * A reunion of the two ranges.
   * The smallest position will be used as the start point, and the largest one as the end point.
   */
  static plusRange(e, o) {
    let a, s, l, u;
    return o.startLineNumber < e.startLineNumber ? (a = o.startLineNumber, s = o.startColumn) : o.startLineNumber === e.startLineNumber ? (a = o.startLineNumber, s = Math.min(o.startColumn, e.startColumn)) : (a = e.startLineNumber, s = e.startColumn), o.endLineNumber > e.endLineNumber ? (l = o.endLineNumber, u = o.endColumn) : o.endLineNumber === e.endLineNumber ? (l = o.endLineNumber, u = Math.max(o.endColumn, e.endColumn)) : (l = e.endLineNumber, u = e.endColumn), new B(a, s, l, u);
  }
  /**
   * A intersection of the two ranges.
   */
  intersectRanges(e) {
    return B.intersectRanges(this, e);
  }
  /**
   * A intersection of the two ranges.
   */
  static intersectRanges(e, o) {
    let a = e.startLineNumber, s = e.startColumn, l = e.endLineNumber, u = e.endColumn;
    const g = o.startLineNumber, b = o.startColumn, k = o.endLineNumber, m = o.endColumn;
    return a < g ? (a = g, s = b) : a === g && (s = Math.max(s, b)), l > k ? (l = k, u = m) : l === k && (u = Math.min(u, m)), a > l || a === l && s > u ? null : new B(a, s, l, u);
  }
  /**
   * Test if this range equals other.
   */
  equalsRange(e) {
    return B.equalsRange(this, e);
  }
  /**
   * Test if range `a` equals `b`.
   */
  static equalsRange(e, o) {
    return !e && !o ? !0 : !!e && !!o && e.startLineNumber === o.startLineNumber && e.startColumn === o.startColumn && e.endLineNumber === o.endLineNumber && e.endColumn === o.endColumn;
  }
  /**
   * Return the end position (which will be after or equal to the start position)
   */
  getEndPosition() {
    return B.getEndPosition(this);
  }
  /**
   * Return the end position (which will be after or equal to the start position)
   */
  static getEndPosition(e) {
    return new O(e.endLineNumber, e.endColumn);
  }
  /**
   * Return the start position (which will be before or equal to the end position)
   */
  getStartPosition() {
    return B.getStartPosition(this);
  }
  /**
   * Return the start position (which will be before or equal to the end position)
   */
  static getStartPosition(e) {
    return new O(e.startLineNumber, e.startColumn);
  }
  /**
   * Transform to a user presentable string representation.
   */
  toString() {
    return "[" + this.startLineNumber + "," + this.startColumn + " -> " + this.endLineNumber + "," + this.endColumn + "]";
  }
  /**
   * Create a new range using this range's start position, and using endLineNumber and endColumn as the end position.
   */
  setEndPosition(e, o) {
    return new B(this.startLineNumber, this.startColumn, e, o);
  }
  /**
   * Create a new range using this range's end position, and using startLineNumber and startColumn as the start position.
   */
  setStartPosition(e, o) {
    return new B(e, o, this.endLineNumber, this.endColumn);
  }
  /**
   * Create a new empty range using this range's start position.
   */
  collapseToStart() {
    return B.collapseToStart(this);
  }
  /**
   * Create a new empty range using this range's start position.
   */
  static collapseToStart(e) {
    return new B(e.startLineNumber, e.startColumn, e.startLineNumber, e.startColumn);
  }
  /**
   * Create a new empty range using this range's end position.
   */
  collapseToEnd() {
    return B.collapseToEnd(this);
  }
  /**
   * Create a new empty range using this range's end position.
   */
  static collapseToEnd(e) {
    return new B(e.endLineNumber, e.endColumn, e.endLineNumber, e.endColumn);
  }
  /**
   * Moves the range by the given amount of lines.
   */
  delta(e) {
    return new B(this.startLineNumber + e, this.startColumn, this.endLineNumber + e, this.endColumn);
  }
  isSingleLine() {
    return this.startLineNumber === this.endLineNumber;
  }
  // ---
  static fromPositions(e, o = e) {
    return new B(e.lineNumber, e.column, o.lineNumber, o.column);
  }
  static lift(e) {
    return e ? new B(e.startLineNumber, e.startColumn, e.endLineNumber, e.endColumn) : null;
  }
  /**
   * Test if `obj` is an `IRange`.
   */
  static isIRange(e) {
    return !!e && typeof e.startLineNumber == "number" && typeof e.startColumn == "number" && typeof e.endLineNumber == "number" && typeof e.endColumn == "number";
  }
  /**
   * Test if the two ranges are touching in any way.
   */
  static areIntersectingOrTouching(e, o) {
    return !(e.endLineNumber < o.startLineNumber || e.endLineNumber === o.startLineNumber && e.endColumn < o.startColumn || o.endLineNumber < e.startLineNumber || o.endLineNumber === e.startLineNumber && o.endColumn < e.startColumn);
  }
  /**
   * Test if the two ranges are intersecting. If the ranges are touching it returns true.
   */
  static areIntersecting(e, o) {
    return !(e.endLineNumber < o.startLineNumber || e.endLineNumber === o.startLineNumber && e.endColumn <= o.startColumn || o.endLineNumber < e.startLineNumber || o.endLineNumber === e.startLineNumber && o.endColumn <= e.startColumn);
  }
  /**
   * Test if the two ranges are intersecting, but not touching at all.
   */
  static areOnlyIntersecting(e, o) {
    return !(e.endLineNumber < o.startLineNumber - 1 || e.endLineNumber === o.startLineNumber && e.endColumn < o.startColumn - 1 || o.endLineNumber < e.startLineNumber - 1 || o.endLineNumber === e.startLineNumber && o.endColumn < e.startColumn - 1);
  }
  /**
   * A function that compares ranges, useful for sorting ranges
   * It will first compare ranges on the startPosition and then on the endPosition
   */
  static compareRangesUsingStarts(e, o) {
    if (e && o) {
      const l = e.startLineNumber | 0, u = o.startLineNumber | 0;
      if (l === u) {
        const g = e.startColumn | 0, b = o.startColumn | 0;
        if (g === b) {
          const k = e.endLineNumber | 0, m = o.endLineNumber | 0;
          if (k === m) {
            const F = e.endColumn | 0, D = o.endColumn | 0;
            return F - D;
          }
          return k - m;
        }
        return g - b;
      }
      return l - u;
    }
    return (e ? 1 : 0) - (o ? 1 : 0);
  }
  /**
   * A function that compares ranges, useful for sorting ranges
   * It will first compare ranges on the endPosition and then on the startPosition
   */
  static compareRangesUsingEnds(e, o) {
    return e.endLineNumber === o.endLineNumber ? e.endColumn === o.endColumn ? e.startLineNumber === o.startLineNumber ? e.startColumn - o.startColumn : e.startLineNumber - o.startLineNumber : e.endColumn - o.endColumn : e.endLineNumber - o.endLineNumber;
  }
  /**
   * Test if the range spans multiple lines.
   */
  static spansMultipleLines(e) {
    return e.endLineNumber > e.startLineNumber;
  }
  toJSON() {
    return this;
  }
}
let sr = class {
  constructor() {
    this._tokenizationSupports = /* @__PURE__ */ new Map(), this._factories = /* @__PURE__ */ new Map(), this._onDidChange = new j(), this.onDidChange = this._onDidChange.event, this._colorMap = null;
  }
  handleChange(e) {
    this._onDidChange.fire({
      changedLanguages: e,
      changedColorMap: !1
    });
  }
  register(e, o) {
    return this._tokenizationSupports.set(e, o), this.handleChange([e]), pe(() => {
      this._tokenizationSupports.get(e) === o && (this._tokenizationSupports.delete(e), this.handleChange([e]));
    });
  }
  get(e) {
    return this._tokenizationSupports.get(e) || null;
  }
  registerFactory(e, o) {
    this._factories.get(e)?.dispose();
    const a = new cr(this, e, o);
    return this._factories.set(e, a), pe(() => {
      const s = this._factories.get(e);
      !s || s !== a || (this._factories.delete(e), s.dispose());
    });
  }
  async getOrCreate(e) {
    const o = this.get(e);
    if (o)
      return o;
    const a = this._factories.get(e);
    return !a || a.isResolved ? null : (await a.resolve(), this.get(e));
  }
  isResolved(e) {
    if (this.get(e))
      return !0;
    const a = this._factories.get(e);
    return !!(!a || a.isResolved);
  }
  setColorMap(e) {
    this._colorMap = e, this._onDidChange.fire({
      changedLanguages: Array.from(this._tokenizationSupports.keys()),
      changedColorMap: !0
    });
  }
  getColorMap() {
    return this._colorMap;
  }
  getDefaultBackground() {
    return this._colorMap && this._colorMap.length > 2 ? this._colorMap[
      2
      /* ColorId.DefaultBackground */
    ] : null;
  }
};
class cr extends V {
  get isResolved() {
    return this._isResolved;
  }
  constructor(e, o, a) {
    super(), this._registry = e, this._languageId = o, this._factory = a, this._isDisposed = !1, this._resolvePromise = null, this._isResolved = !1;
  }
  dispose() {
    this._isDisposed = !0, super.dispose();
  }
  async resolve() {
    return this._resolvePromise || (this._resolvePromise = this._create()), this._resolvePromise;
  }
  async _create() {
    const e = await this._factory.tokenizationSupport;
    this._isResolved = !0, e && !this._isDisposed && this._register(this._registry.register(this._languageId, e));
  }
}
class xo {
  constructor(e, o, a) {
    this.offset = e, this.type = o, this.language = a, this._tokenBrand = void 0;
  }
  toString() {
    return "(" + this.offset + ", " + this.type + ")";
  }
}
class yo {
  constructor(e, o) {
    this.tokens = e, this.endState = o, this._tokenizationResultBrand = void 0;
  }
}
class vo {
  constructor(e, o) {
    this.tokens = e, this.endState = o, this._encodedTokenizationResultBrand = void 0;
  }
}
var je;
(function(r) {
  r[r.Increase = 0] = "Increase", r[r.Decrease = 1] = "Decrease";
})(je || (je = {}));
var Ve;
(function(r) {
  const e = /* @__PURE__ */ new Map();
  e.set(0, f.symbolMethod), e.set(1, f.symbolFunction), e.set(2, f.symbolConstructor), e.set(3, f.symbolField), e.set(4, f.symbolVariable), e.set(5, f.symbolClass), e.set(6, f.symbolStruct), e.set(7, f.symbolInterface), e.set(8, f.symbolModule), e.set(9, f.symbolProperty), e.set(10, f.symbolEvent), e.set(11, f.symbolOperator), e.set(12, f.symbolUnit), e.set(13, f.symbolValue), e.set(15, f.symbolEnum), e.set(14, f.symbolConstant), e.set(15, f.symbolEnum), e.set(16, f.symbolEnumMember), e.set(17, f.symbolKeyword), e.set(28, f.symbolSnippet), e.set(18, f.symbolText), e.set(19, f.symbolColor), e.set(20, f.symbolFile), e.set(21, f.symbolReference), e.set(22, f.symbolCustomColor), e.set(23, f.symbolFolder), e.set(24, f.symbolTypeParameter), e.set(25, f.account), e.set(26, f.issues), e.set(27, f.tools);
  function o(u) {
    let g = e.get(u);
    return g || (console.info("No codicon found for CompletionItemKind " + u), g = f.symbolProperty), g;
  }
  r.toIcon = o;
  function a(u) {
    switch (u) {
      case 0:
        return n(728, "Method");
      case 1:
        return n(729, "Function");
      case 2:
        return n(730, "Constructor");
      case 3:
        return n(731, "Field");
      case 4:
        return n(732, "Variable");
      case 5:
        return n(733, "Class");
      case 6:
        return n(734, "Struct");
      case 7:
        return n(735, "Interface");
      case 8:
        return n(736, "Module");
      case 9:
        return n(737, "Property");
      case 10:
        return n(738, "Event");
      case 11:
        return n(739, "Operator");
      case 12:
        return n(740, "Unit");
      case 13:
        return n(741, "Value");
      case 14:
        return n(742, "Constant");
      case 15:
        return n(743, "Enum");
      case 16:
        return n(744, "Enum Member");
      case 17:
        return n(745, "Keyword");
      case 18:
        return n(746, "Text");
      case 19:
        return n(747, "Color");
      case 20:
        return n(748, "File");
      case 21:
        return n(749, "Reference");
      case 22:
        return n(750, "Custom Color");
      case 23:
        return n(751, "Folder");
      case 24:
        return n(752, "Type Parameter");
      case 25:
        return n(753, "User");
      case 26:
        return n(754, "Issue");
      case 27:
        return n(755, "Tool");
      case 28:
        return n(756, "Snippet");
      default:
        return "";
    }
  }
  r.toLabel = a;
  const s = /* @__PURE__ */ new Map();
  s.set(
    "method",
    0
    /* CompletionItemKind.Method */
  ), s.set(
    "function",
    1
    /* CompletionItemKind.Function */
  ), s.set(
    "constructor",
    2
    /* CompletionItemKind.Constructor */
  ), s.set(
    "field",
    3
    /* CompletionItemKind.Field */
  ), s.set(
    "variable",
    4
    /* CompletionItemKind.Variable */
  ), s.set(
    "class",
    5
    /* CompletionItemKind.Class */
  ), s.set(
    "struct",
    6
    /* CompletionItemKind.Struct */
  ), s.set(
    "interface",
    7
    /* CompletionItemKind.Interface */
  ), s.set(
    "module",
    8
    /* CompletionItemKind.Module */
  ), s.set(
    "property",
    9
    /* CompletionItemKind.Property */
  ), s.set(
    "event",
    10
    /* CompletionItemKind.Event */
  ), s.set(
    "operator",
    11
    /* CompletionItemKind.Operator */
  ), s.set(
    "unit",
    12
    /* CompletionItemKind.Unit */
  ), s.set(
    "value",
    13
    /* CompletionItemKind.Value */
  ), s.set(
    "constant",
    14
    /* CompletionItemKind.Constant */
  ), s.set(
    "enum",
    15
    /* CompletionItemKind.Enum */
  ), s.set(
    "enum-member",
    16
    /* CompletionItemKind.EnumMember */
  ), s.set(
    "enumMember",
    16
    /* CompletionItemKind.EnumMember */
  ), s.set(
    "keyword",
    17
    /* CompletionItemKind.Keyword */
  ), s.set(
    "snippet",
    28
    /* CompletionItemKind.Snippet */
  ), s.set(
    "text",
    18
    /* CompletionItemKind.Text */
  ), s.set(
    "color",
    19
    /* CompletionItemKind.Color */
  ), s.set(
    "file",
    20
    /* CompletionItemKind.File */
  ), s.set(
    "reference",
    21
    /* CompletionItemKind.Reference */
  ), s.set(
    "customcolor",
    22
    /* CompletionItemKind.Customcolor */
  ), s.set(
    "folder",
    23
    /* CompletionItemKind.Folder */
  ), s.set(
    "type-parameter",
    24
    /* CompletionItemKind.TypeParameter */
  ), s.set(
    "typeParameter",
    24
    /* CompletionItemKind.TypeParameter */
  ), s.set(
    "account",
    25
    /* CompletionItemKind.User */
  ), s.set(
    "issue",
    26
    /* CompletionItemKind.Issue */
  ), s.set(
    "tool",
    27
    /* CompletionItemKind.Tool */
  );
  function l(u, g) {
    let b = s.get(u);
    return typeof b > "u" && !g && (b = 9), b;
  }
  r.fromString = l;
})(Ve || (Ve = {}));
var Je;
(function(r) {
  r[r.Automatic = 0] = "Automatic", r[r.Explicit = 1] = "Explicit";
})(Je || (Je = {}));
class Fo {
  constructor(e, o, a, s) {
    this.range = e, this.text = o, this.completionKind = a, this.isSnippetText = s;
  }
  equals(e) {
    return B.lift(this.range).equalsRange(e.range) && this.text === e.text && this.completionKind === e.completionKind && this.isSnippetText === e.isSnippetText;
  }
}
var Ke;
(function(r) {
  r[r.Code = 1] = "Code", r[r.Label = 2] = "Label";
})(Ke || (Ke = {}));
class Bt {
  static fromExtensionId(e) {
    return new Bt(e, void 0, void 0);
  }
  constructor(e, o, a) {
    this.extensionId = e, this.extensionVersion = o, this.providerId = a;
  }
  toString() {
    let e = "";
    return this.extensionId && (e += this.extensionId), this.extensionVersion && (e += `@${this.extensionVersion}`), this.providerId && (e += `:${this.providerId}`), e.length === 0 && (e = "unknown"), e;
  }
  toStringWithoutVersion() {
    let e = "";
    return this.extensionId && (e += this.extensionId), this.providerId && (e += `:${this.providerId}`), e;
  }
}
var Qe;
(function(r) {
  r[r.Accepted = 0] = "Accepted", r[r.Rejected = 1] = "Rejected", r[r.Ignored = 2] = "Ignored";
})(Qe || (Qe = {}));
var Ze;
(function(r) {
  r[r.Automatic = 0] = "Automatic", r[r.PasteAs = 1] = "PasteAs";
})(Ze || (Ze = {}));
var Xe;
(function(r) {
  r[r.Invoke = 1] = "Invoke", r[r.TriggerCharacter = 2] = "TriggerCharacter", r[r.ContentChange = 3] = "ContentChange";
})(Xe || (Xe = {}));
var Ye;
(function(r) {
  r[r.Text = 0] = "Text", r[r.Read = 1] = "Read", r[r.Write = 2] = "Write";
})(Ye || (Ye = {}));
function Bo(r) {
  return !!r && vt.isUri(r.uri) && B.isIRange(r.range) && (B.isIRange(r.originSelectionRange) || B.isIRange(r.targetSelectionRange));
}
const lr = {
  17: n(757, "array"),
  16: n(758, "boolean"),
  4: n(759, "class"),
  13: n(760, "constant"),
  8: n(761, "constructor"),
  9: n(762, "enumeration"),
  21: n(763, "enumeration member"),
  23: n(764, "event"),
  7: n(765, "field"),
  0: n(766, "file"),
  11: n(767, "function"),
  10: n(768, "interface"),
  19: n(769, "key"),
  5: n(770, "method"),
  1: n(771, "module"),
  2: n(772, "namespace"),
  20: n(773, "null"),
  15: n(774, "number"),
  18: n(775, "object"),
  24: n(776, "operator"),
  3: n(777, "package"),
  6: n(778, "property"),
  14: n(779, "string"),
  22: n(780, "struct"),
  25: n(781, "type parameter"),
  12: n(782, "variable")
};
function Co(r, e) {
  return n(783, "{0} ({1})", r, lr[e]);
}
var et;
(function(r) {
  const e = /* @__PURE__ */ new Map();
  e.set(0, f.symbolFile), e.set(1, f.symbolModule), e.set(2, f.symbolNamespace), e.set(3, f.symbolPackage), e.set(4, f.symbolClass), e.set(5, f.symbolMethod), e.set(6, f.symbolProperty), e.set(7, f.symbolField), e.set(8, f.symbolConstructor), e.set(9, f.symbolEnum), e.set(10, f.symbolInterface), e.set(11, f.symbolFunction), e.set(12, f.symbolVariable), e.set(13, f.symbolConstant), e.set(14, f.symbolString), e.set(15, f.symbolNumber), e.set(16, f.symbolBoolean), e.set(17, f.symbolArray), e.set(18, f.symbolObject), e.set(19, f.symbolKey), e.set(20, f.symbolNull), e.set(21, f.symbolEnumMember), e.set(22, f.symbolStruct), e.set(23, f.symbolEvent), e.set(24, f.symbolOperator), e.set(25, f.symbolTypeParameter);
  function o(l) {
    let u = e.get(l);
    return u || (console.info("No codicon found for SymbolKind " + l), u = f.symbolProperty), u;
  }
  r.toIcon = o;
  const a = /* @__PURE__ */ new Map();
  a.set(
    0,
    20
    /* CompletionItemKind.File */
  ), a.set(
    1,
    8
    /* CompletionItemKind.Module */
  ), a.set(
    2,
    8
    /* CompletionItemKind.Module */
  ), a.set(
    3,
    8
    /* CompletionItemKind.Module */
  ), a.set(
    4,
    5
    /* CompletionItemKind.Class */
  ), a.set(
    5,
    0
    /* CompletionItemKind.Method */
  ), a.set(
    6,
    9
    /* CompletionItemKind.Property */
  ), a.set(
    7,
    3
    /* CompletionItemKind.Field */
  ), a.set(
    8,
    2
    /* CompletionItemKind.Constructor */
  ), a.set(
    9,
    15
    /* CompletionItemKind.Enum */
  ), a.set(
    10,
    7
    /* CompletionItemKind.Interface */
  ), a.set(
    11,
    1
    /* CompletionItemKind.Function */
  ), a.set(
    12,
    4
    /* CompletionItemKind.Variable */
  ), a.set(
    13,
    14
    /* CompletionItemKind.Constant */
  ), a.set(
    14,
    18
    /* CompletionItemKind.Text */
  ), a.set(
    15,
    13
    /* CompletionItemKind.Value */
  ), a.set(
    16,
    13
    /* CompletionItemKind.Value */
  ), a.set(
    17,
    13
    /* CompletionItemKind.Value */
  ), a.set(
    18,
    13
    /* CompletionItemKind.Value */
  ), a.set(
    19,
    17
    /* CompletionItemKind.Keyword */
  ), a.set(
    20,
    13
    /* CompletionItemKind.Value */
  ), a.set(
    21,
    16
    /* CompletionItemKind.EnumMember */
  ), a.set(
    22,
    6
    /* CompletionItemKind.Struct */
  ), a.set(
    23,
    10
    /* CompletionItemKind.Event */
  ), a.set(
    24,
    11
    /* CompletionItemKind.Operator */
  ), a.set(
    25,
    24
    /* CompletionItemKind.TypeParameter */
  );
  function s(l) {
    let u = a.get(l);
    return u === void 0 && (console.info("No completion kind found for SymbolKind " + l), u = 20), u;
  }
  r.toCompletionKind = s;
})(et || (et = {}));
class z {
  static {
    this.Comment = new z("comment");
  }
  static {
    this.Imports = new z("imports");
  }
  static {
    this.Region = new z("region");
  }
  /**
   * Returns a {@link FoldingRangeKind} for the given value.
   *
   * @param value of the kind.
   */
  static fromValue(e) {
    switch (e) {
      case "comment":
        return z.Comment;
      case "imports":
        return z.Imports;
      case "region":
        return z.Region;
    }
    return new z(e);
  }
  /**
   * Creates a new {@link FoldingRangeKind}.
   *
   * @param value of the kind.
   */
  constructor(e) {
    this.value = e;
  }
}
var tt;
(function(r) {
  r[r.AIGenerated = 1] = "AIGenerated";
})(tt || (tt = {}));
var rt;
(function(r) {
  r[r.Invoke = 0] = "Invoke", r[r.Automatic = 1] = "Automatic";
})(rt || (rt = {}));
var ot;
(function(r) {
  function e(o) {
    return !o || typeof o != "object" ? !1 : typeof o.id == "string" && typeof o.title == "string";
  }
  r.is = e;
})(ot || (ot = {}));
var nt;
(function(r) {
  r[r.Type = 1] = "Type", r[r.Parameter = 2] = "Parameter";
})(nt || (nt = {}));
class Do {
  constructor(e) {
    this.createSupport = e, this._tokenizationSupport = null;
  }
  dispose() {
    this._tokenizationSupport && this._tokenizationSupport.then((e) => {
      e && e.dispose();
    });
  }
  get tokenizationSupport() {
    return this._tokenizationSupport || (this._tokenizationSupport = this.createSupport()), this._tokenizationSupport;
  }
}
const dr = new sr();
class it {
  static getLanguageId(e) {
    return (e & 255) >>> 0;
  }
  static getTokenType(e) {
    return (e & 768) >>> 8;
  }
  static containsBalancedBrackets(e) {
    return (e & 1024) !== 0;
  }
  static getFontStyle(e) {
    return (e & 30720) >>> 11;
  }
  static getForeground(e) {
    return (e & 16744448) >>> 15;
  }
  static getBackground(e) {
    return (e & 4278190080) >>> 24;
  }
  static getClassNameFromMetadata(e) {
    let a = "mtk" + this.getForeground(e);
    const s = this.getFontStyle(e);
    return s & 1 && (a += " mtki"), s & 2 && (a += " mtkb"), s & 4 && (a += " mtku"), s & 8 && (a += " mtks"), a;
  }
  static getInlineStyleFromMetadata(e, o) {
    const a = this.getForeground(e), s = this.getFontStyle(e);
    let l = `color: ${o[a]};`;
    s & 1 && (l += "font-style: italic;"), s & 2 && (l += "font-weight: bold;");
    let u = "";
    return s & 4 && (u += " underline"), s & 8 && (u += " line-through"), u && (l += `text-decoration:${u};`), l;
  }
  static getPresentationFromMetadata(e) {
    const o = this.getForeground(e), a = this.getFontStyle(e);
    return {
      foreground: o,
      italic: !!(a & 1),
      bold: !!(a & 2),
      underline: !!(a & 4),
      strikethrough: !!(a & 8)
    };
  }
}
class ur {
  constructor(e, o, a, s, l) {
    this._parsedThemeRuleBrand = void 0, this.token = e, this.index = o, this.fontStyle = a, this.foreground = s, this.background = l;
  }
}
function hr(r) {
  if (!r || !Array.isArray(r))
    return [];
  const e = [];
  let o = 0;
  for (let a = 0, s = r.length; a < s; a++) {
    const l = r[a];
    let u = -1;
    if (typeof l.fontStyle == "string") {
      u = 0;
      const k = l.fontStyle.split(" ");
      for (let m = 0, F = k.length; m < F; m++)
        switch (k[m]) {
          case "italic":
            u = u | 1;
            break;
          case "bold":
            u = u | 2;
            break;
          case "underline":
            u = u | 4;
            break;
          case "strikethrough":
            u = u | 8;
            break;
        }
    }
    let g = null;
    typeof l.foreground == "string" && (g = l.foreground);
    let b = null;
    typeof l.background == "string" && (b = l.background), e[o++] = new ur(l.token || "", a, u, g, b);
  }
  return e;
}
function gr(r, e) {
  r.sort((m, F) => {
    const D = pr(m.token, F.token);
    return D !== 0 ? D : m.index - F.index;
  });
  let o = 0, a = "000000", s = "ffffff";
  for (; r.length >= 1 && r[0].token === ""; ) {
    const m = r.shift();
    m.fontStyle !== -1 && (o = m.fontStyle), m.foreground !== null && (a = m.foreground), m.background !== null && (s = m.background);
  }
  const l = new br();
  for (const m of e)
    l.getId(m);
  const u = l.getId(a), g = l.getId(s), b = new He(o, u, g), k = new Re(b);
  for (let m = 0, F = r.length; m < F; m++) {
    const D = r[m];
    k.insert(D.token, D.fontStyle, l.getId(D.foreground), l.getId(D.background));
  }
  return new Ct(l, k);
}
const fr = /^#?([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?$/;
class br {
  constructor() {
    this._lastColorId = 0, this._id2color = [], this._color2id = /* @__PURE__ */ new Map();
  }
  getId(e) {
    if (e === null)
      return 0;
    const o = e.match(fr);
    if (!o)
      throw new Error("Illegal value for token color: " + e);
    e = o[1].toUpperCase();
    let a = this._color2id.get(e);
    return a || (a = ++this._lastColorId, this._color2id.set(e, a), this._id2color[a] = d.fromHex("#" + e), a);
  }
  getColorMap() {
    return this._id2color.slice(0);
  }
}
class Ct {
  static createFromRawTokenTheme(e, o) {
    return this.createFromParsedTokenTheme(hr(e), o);
  }
  static createFromParsedTokenTheme(e, o) {
    return gr(e, o);
  }
  constructor(e, o) {
    this._colorMap = e, this._root = o, this._cache = /* @__PURE__ */ new Map();
  }
  getColorMap() {
    return this._colorMap.getColorMap();
  }
  _match(e) {
    return this._root.match(e);
  }
  match(e, o) {
    let a = this._cache.get(o);
    if (typeof a > "u") {
      const s = this._match(o), l = kr(o);
      a = (s.metadata | l << 8) >>> 0, this._cache.set(o, a);
    }
    return (a | e << 0) >>> 0;
  }
}
const mr = /\b(comment|string|regex|regexp)\b/;
function kr(r) {
  const e = r.match(mr);
  if (!e)
    return 0;
  switch (e[1]) {
    case "comment":
      return 1;
    case "string":
      return 2;
    case "regex":
      return 3;
    case "regexp":
      return 3;
  }
  throw new Error("Unexpected match for standard token type!");
}
function pr(r, e) {
  return r < e ? -1 : r > e ? 1 : 0;
}
class He {
  constructor(e, o, a) {
    this._themeTrieElementRuleBrand = void 0, this._fontStyle = e, this._foreground = o, this._background = a, this.metadata = (this._fontStyle << 11 | this._foreground << 15 | this._background << 24) >>> 0;
  }
  clone() {
    return new He(this._fontStyle, this._foreground, this._background);
  }
  acceptOverwrite(e, o, a) {
    e !== -1 && (this._fontStyle = e), o !== 0 && (this._foreground = o), a !== 0 && (this._background = a), this.metadata = (this._fontStyle << 11 | this._foreground << 15 | this._background << 24) >>> 0;
  }
}
class Re {
  constructor(e) {
    this._themeTrieElementBrand = void 0, this._mainRule = e, this._children = /* @__PURE__ */ new Map();
  }
  match(e) {
    if (e === "")
      return this._mainRule;
    const o = e.indexOf(".");
    let a, s;
    o === -1 ? (a = e, s = "") : (a = e.substring(0, o), s = e.substring(o + 1));
    const l = this._children.get(a);
    return typeof l < "u" ? l.match(s) : this._mainRule;
  }
  insert(e, o, a, s) {
    if (e === "") {
      this._mainRule.acceptOverwrite(o, a, s);
      return;
    }
    const l = e.indexOf(".");
    let u, g;
    l === -1 ? (u = e, g = "") : (u = e.substring(0, l), g = e.substring(l + 1));
    let b = this._children.get(u);
    typeof b > "u" && (b = new Re(this._mainRule.clone()), this._children.set(u, b)), b.insert(g, o, a, s);
  }
}
function wr(r) {
  const e = [];
  for (let o = 1, a = r.length; o < a; o++) {
    const s = r[o];
    e[o] = `.mtk${o} { color: ${s}; }`;
  }
  return e.push(".mtki { font-style: italic; }"), e.push(".mtkb { font-weight: bold; }"), e.push(".mtku { text-decoration: underline; text-underline-position: under; }"), e.push(".mtks { text-decoration: line-through; }"), e.push(".mtks.mtku { text-decoration: underline line-through; text-underline-position: under; }"), e.join(`
`);
}
class xr {
  constructor() {
    this.data = /* @__PURE__ */ new Map();
  }
  add(e, o) {
    Ce(de(e)), Ce(Xt(o)), Ce(!this.data.has(e), "There is already an extension with this id"), this.data.set(e, o);
  }
  as(e) {
    return this.data.get(e) || null;
  }
  dispose() {
    this.data.forEach((e) => {
      Zt(e.dispose) && e.dispose();
    }), this.data.clear();
  }
}
const J = new xr(), Me = {
  JSONContribution: "base.contributions.json"
};
function yr(r) {
  return r.length > 0 && r.charAt(r.length - 1) === "#" ? r.substring(0, r.length - 1) : r;
}
class vr extends V {
  constructor() {
    super(...arguments), this.schemasById = {}, this._onDidChangeSchema = this._register(new j());
  }
  registerSchema(e, o, a) {
    const s = yr(e);
    this.schemasById[s] = o, this._onDidChangeSchema.fire(e), a && a.add(pe(() => {
      delete this.schemasById[s], this._onDidChangeSchema.fire(e);
    }));
  }
  notifySchemaChanged(e) {
    this._onDidChangeSchema.fire(e);
  }
}
const Fr = new vr();
J.add(Me.JSONContribution, Fr);
function Oe(r) {
  return `--vscode-${r.replace(/\./g, "-")}`;
}
function Lo(r) {
  return `var(${Oe(r)})`;
}
function So(r, e) {
  return `var(${Oe(r)}, ${e})`;
}
function Br(r) {
  return r !== null && typeof r == "object" && "light" in r && "dark" in r;
}
const Dt = {
  ColorContribution: "base.contributions.colors"
}, Cr = "default";
class Dr extends V {
  constructor() {
    super(), this._onDidChangeSchema = this._register(new j()), this.onDidChangeSchema = this._onDidChangeSchema.event, this.colorSchema = { type: "object", properties: {} }, this.colorReferenceSchema = { type: "string", enum: [], enumDescriptions: [] }, this.colorsById = {};
  }
  registerColor(e, o, a, s = !1, l) {
    const u = { id: e, description: a, defaults: o, needsTransparency: s, deprecationMessage: l };
    this.colorsById[e] = u;
    const g = { type: "string", format: "color-hex", defaultSnippets: [{ body: "${1:#ff0000}" }] };
    return l && (g.deprecationMessage = l), s && (g.pattern = "^#(?:(?<rgba>[0-9a-fA-f]{3}[0-9a-eA-E])|(?:[0-9a-fA-F]{6}(?:(?![fF]{2})(?:[0-9a-fA-F]{2}))))?$", g.patternErrorMessage = n(2022, "This color must be transparent or it will obscure content")), this.colorSchema.properties[e] = {
      description: a,
      oneOf: [
        g,
        { type: "string", const: Cr, description: n(2023, "Use the default color.") }
      ]
    }, this.colorReferenceSchema.enum.push(e), this.colorReferenceSchema.enumDescriptions.push(a), this._onDidChangeSchema.fire(), e;
  }
  getColors() {
    return Object.keys(this.colorsById).map((e) => this.colorsById[e]);
  }
  resolveDefaultColor(e, o) {
    const a = this.colorsById[e];
    if (a?.defaults) {
      const s = Br(a.defaults) ? a.defaults[o.type] : a.defaults;
      return I(s, o);
    }
  }
  getColorSchema() {
    return this.colorSchema;
  }
  toString() {
    const e = (o, a) => {
      const s = o.indexOf(".") === -1 ? 0 : 1, l = a.indexOf(".") === -1 ? 0 : 1;
      return s !== l ? s - l : o.localeCompare(a);
    };
    return Object.keys(this.colorsById).sort(e).map((o) => `- \`${o}\`: ${this.colorsById[o].description}`).join(`
`);
  }
}
const ye = new Dr();
J.add(Dt.ColorContribution, ye);
function i(r, e, o, a, s) {
  return ye.registerColor(r, e, o, a, s);
}
function Lr(r, e) {
  switch (r.op) {
    case 0:
      return I(r.value, e)?.darken(r.factor);
    case 1:
      return I(r.value, e)?.lighten(r.factor);
    case 2:
      return I(r.value, e)?.transparent(r.factor);
    case 7: {
      const o = I(r.color, e) || d.transparent, a = I(r.with, e) || d.transparent;
      return o.mix(a, r.ratio);
    }
    case 3: {
      const o = I(r.background, e);
      return o ? I(r.value, e)?.makeOpaque(o) : I(r.value, e);
    }
    case 4:
      for (const o of r.values) {
        const a = I(o, e);
        if (a)
          return a;
      }
      return;
    case 6:
      return I(e.defines(r.if) ? r.then : r.else, e);
    case 5: {
      const o = I(r.value, e);
      if (!o)
        return;
      const a = I(r.background, e);
      return a ? o.isDarkerThan(a) ? d.getLighterColor(o, a, r.factor).transparent(r.transparency) : d.getDarkerColor(o, a, r.factor).transparent(r.transparency) : o.transparent(r.factor * r.transparency);
    }
    default:
      throw Yt();
  }
}
function Y(r, e) {
  return { op: 0, value: r, factor: e };
}
function H(r, e) {
  return { op: 1, value: r, factor: e };
}
function p(r, e) {
  return { op: 2, value: r, factor: e };
}
function at(...r) {
  return { op: 4, values: r };
}
function Sr(r, e, o) {
  return { op: 6, if: r, then: e, else: o };
}
function st(r, e, o, a) {
  return { op: 5, value: r, background: e, factor: o, transparency: a };
}
function I(r, e) {
  if (r !== null) {
    if (typeof r == "string")
      return r[0] === "#" ? d.fromHex(r) : e.getColor(r);
    if (r instanceof d)
      return r;
    if (typeof r == "object")
      return Lr(r, e);
  }
}
const Lt = "vscode://schemas/workbench-colors", St = J.as(Me.JSONContribution);
St.registerSchema(Lt, ye.getColorSchema());
const ct = new Ft(() => St.notifySchemaChanged(Lt), 200);
ye.onDidChangeSchema(() => {
  ct.isScheduled() || ct.schedule();
});
const y = i("foreground", { dark: "#CCCCCC", light: "#616161", hcDark: "#FFFFFF", hcLight: "#292929" }, n(1773, "Overall foreground color. This color is only used if not overridden by a component."));
i("disabledForeground", { dark: "#CCCCCC80", light: "#61616180", hcDark: "#A5A5A5", hcLight: "#7F7F7F" }, n(1774, "Overall foreground for disabled elements. This color is only used if not overridden by a component."));
i("errorForeground", { dark: "#F48771", light: "#A1260D", hcDark: "#F48771", hcLight: "#B5200D" }, n(1775, "Overall foreground color for error messages. This color is only used if not overridden by a component."));
const Ao = i("descriptionForeground", { light: "#717171", dark: p(y, 0.7), hcDark: p(y, 0.7), hcLight: p(y, 0.7) }, n(1776, "Foreground color for description text providing additional information, for example for a label.")), Ae = i("icon.foreground", { dark: "#C5C5C5", light: "#424242", hcDark: "#FFFFFF", hcLight: "#292929" }, n(1777, "The default color for icons in the workbench.")), G = i("focusBorder", { dark: "#007FD4", light: "#0090F1", hcDark: "#F38518", hcLight: "#006BBD" }, n(1778, "Overall border color for focused elements. This color is only used if not overridden by a component.")), x = i("contrastBorder", { light: null, dark: null, hcDark: "#6FC3DF", hcLight: "#0F4A85" }, n(1779, "An extra border around elements to separate them from others for greater contrast.")), C = i("contrastActiveBorder", { light: null, dark: null, hcDark: G, hcLight: G }, n(1780, "An extra border around active elements to separate them from others for greater contrast."));
i("selection.background", null, n(1781, "The background color of text selections in the workbench (e.g. for input fields or text areas). Note that this does not apply to selections within the editor."));
const To = i("textLink.foreground", { light: "#006AB1", dark: "#3794FF", hcDark: "#21A6FF", hcLight: "#0F4A85" }, n(1782, "Foreground color for links in text."));
i("textLink.activeForeground", { light: "#006AB1", dark: "#3794FF", hcDark: "#21A6FF", hcLight: "#0F4A85" }, n(1783, "Foreground color for links in text when clicked on and on mouse hover."));
i("textSeparator.foreground", { light: "#0000002e", dark: "#ffffff2e", hcDark: d.black, hcLight: "#292929" }, n(1784, "Color for text separators."));
i("textPreformat.foreground", { light: "#A31515", dark: "#D7BA7D", hcDark: "#000000", hcLight: "#FFFFFF" }, n(1785, "Foreground color for preformatted text segments."));
i("textPreformat.background", { light: "#0000001A", dark: "#FFFFFF1A", hcDark: "#FFFFFF", hcLight: "#09345f" }, n(1786, "Background color for preformatted text segments."));
i("textBlockQuote.background", { light: "#f2f2f2", dark: "#222222", hcDark: null, hcLight: "#F2F2F2" }, n(1787, "Background color for block quotes in text."));
i("textBlockQuote.border", { light: "#007acc80", dark: "#007acc80", hcDark: d.white, hcLight: "#292929" }, n(1788, "Border color for block quotes in text."));
i("textCodeBlock.background", { light: "#dcdcdc66", dark: "#0a0a0a66", hcDark: d.black, hcLight: "#F2F2F2" }, n(1789, "Background color for code blocks in text."));
i("sash.hoverBorder", G, n(1994, "Border color of active sashes."));
const De = i("badge.background", { dark: "#4D4D4D", light: "#C4C4C4", hcDark: d.black, hcLight: "#0F4A85" }, n(1995, "Badge background color. Badges are small information labels, e.g. for search results count.")), Io = i("badge.foreground", { dark: d.white, light: "#333", hcDark: d.white, hcLight: d.white }, n(1996, "Badge foreground color. Badges are small information labels, e.g. for search results count."));
i("activityWarningBadge.foreground", { dark: d.black.lighten(0.2), light: d.white, hcDark: null, hcLight: d.black.lighten(0.2) }, n(1997, "Foreground color of the warning activity badge"));
i("activityWarningBadge.background", { dark: "#CCA700", light: "#BF8803", hcDark: null, hcLight: "#CCA700" }, n(1998, "Background color of the warning activity badge"));
i("activityErrorBadge.foreground", { dark: d.black.lighten(0.2), light: d.white, hcDark: null, hcLight: d.black.lighten(0.2) }, n(1999, "Foreground color of the error activity badge"));
i("activityErrorBadge.background", { dark: "#F14C4C", light: "#E51400", hcDark: null, hcLight: "#F14C4C" }, n(2e3, "Background color of the error activity badge"));
const Ar = i("scrollbar.shadow", { dark: "#000000", light: "#DDDDDD", hcDark: null, hcLight: null }, n(2001, "Scrollbar shadow to indicate that the view is scrolled.")), Tr = i("scrollbarSlider.background", { dark: d.fromHex("#797979").transparent(0.4), light: d.fromHex("#646464").transparent(0.4), hcDark: p(x, 0.6), hcLight: p(x, 0.4) }, n(2002, "Scrollbar slider background color.")), Ir = i("scrollbarSlider.hoverBackground", { dark: d.fromHex("#646464").transparent(0.7), light: d.fromHex("#646464").transparent(0.7), hcDark: p(x, 0.8), hcLight: p(x, 0.8) }, n(2003, "Scrollbar slider background color when hovering.")), Er = i("scrollbarSlider.activeBackground", { dark: d.fromHex("#BFBFBF").transparent(0.4), light: d.fromHex("#000000").transparent(0.6), hcDark: x, hcLight: x }, n(2004, "Scrollbar slider background color when clicked on."));
i("scrollbar.background", null, n(2005, "Scrollbar track background color."));
const Eo = i("progressBar.background", { dark: d.fromHex("#0E70C0"), light: d.fromHex("#0E70C0"), hcDark: x, hcLight: x }, n(2006, "Background color of the progress bar that can show for long running operations."));
i("chart.line", { dark: "#236B8E", light: "#236B8E", hcDark: "#236B8E", hcLight: "#236B8E" }, n(2007, "Line color for the chart."));
i("chart.axis", { dark: d.fromHex("#BFBFBF").transparent(0.4), light: d.fromHex("#000000").transparent(0.6), hcDark: x, hcLight: x }, n(2008, "Axis color for the chart."));
i("chart.guide", { dark: d.fromHex("#BFBFBF").transparent(0.2), light: d.fromHex("#000000").transparent(0.2), hcDark: x, hcLight: x }, n(2009, "Guide line for the chart."));
const R = i("editor.background", { light: "#ffffff", dark: "#1E1E1E", hcDark: d.black, hcLight: d.white }, n(1798, "Editor background color.")), ve = i("editor.foreground", { light: "#333333", dark: "#BBBBBB", hcDark: d.white, hcLight: y }, n(1799, "Editor default foreground color."));
i("editorStickyScroll.background", R, n(1800, "Background color of sticky scroll in the editor"));
i("editorStickyScrollGutter.background", R, n(1801, "Background color of the gutter part of sticky scroll in the editor"));
i("editorStickyScrollHover.background", { dark: "#2A2D2E", light: "#F0F0F0", hcDark: null, hcLight: d.fromHex("#0F4A85").transparent(0.1) }, n(1802, "Background color of sticky scroll on hover in the editor"));
i("editorStickyScroll.border", { dark: null, light: null, hcDark: x, hcLight: x }, n(1803, "Border color of sticky scroll in the editor"));
i("editorStickyScroll.shadow", Ar, n(1804, " Shadow color of sticky scroll in the editor"));
const N = i("editorWidget.background", { dark: "#252526", light: "#F3F3F3", hcDark: "#0C141F", hcLight: d.white }, n(1805, "Background color of editor widgets, such as find/replace.")), qe = i("editorWidget.foreground", y, n(1806, "Foreground color of editor widgets, such as find/replace.")), _r = i("editorWidget.border", { dark: "#454545", light: "#C8C8C8", hcDark: x, hcLight: x }, n(1807, "Border color of editor widgets. The color is only used if the widget chooses to have a border and if the color is not overridden by a widget."));
i("editorWidget.resizeBorder", null, n(1808, "Border color of the resize bar of editor widgets. The color is only used if the widget chooses to have a resize border and if the color is not overridden by a widget."));
i("editorError.background", null, n(1809, "Background color of error text in the editor. The color must not be opaque so as not to hide underlying decorations."), !0);
const At = i("editorError.foreground", { dark: "#F14C4C", light: "#E51400", hcDark: "#F48771", hcLight: "#B5200D" }, n(1810, "Foreground color of error squigglies in the editor.")), _o = i("editorError.border", { dark: null, light: null, hcDark: d.fromHex("#E47777").transparent(0.8), hcLight: "#B5200D" }, n(1811, "If set, color of double underlines for errors in the editor.")), Nr = i("editorWarning.background", null, n(1812, "Background color of warning text in the editor. The color must not be opaque so as not to hide underlying decorations."), !0), X = i("editorWarning.foreground", { dark: "#CCA700", light: "#BF8803", hcDark: "#FFD370", hcLight: "#895503" }, n(1813, "Foreground color of warning squigglies in the editor.")), we = i("editorWarning.border", { dark: null, light: null, hcDark: d.fromHex("#FFCC00").transparent(0.8), hcLight: d.fromHex("#FFCC00").transparent(0.8) }, n(1814, "If set, color of double underlines for warnings in the editor."));
i("editorInfo.background", null, n(1815, "Background color of info text in the editor. The color must not be opaque so as not to hide underlying decorations."), !0);
const se = i("editorInfo.foreground", { dark: "#3794FF", light: "#1a85ff", hcDark: "#3794FF", hcLight: "#1a85ff" }, n(1816, "Foreground color of info squigglies in the editor.")), xe = i("editorInfo.border", { dark: null, light: null, hcDark: d.fromHex("#3794FF").transparent(0.8), hcLight: "#292929" }, n(1817, "If set, color of double underlines for infos in the editor.")), No = i("editorHint.foreground", { dark: d.fromHex("#eeeeee").transparent(0.7), light: "#6c6c6c", hcDark: null, hcLight: null }, n(1818, "Foreground color of hint squigglies in the editor."));
i("editorHint.border", { dark: null, light: null, hcDark: d.fromHex("#eeeeee").transparent(0.8), hcLight: "#292929" }, n(1819, "If set, color of double underlines for hints in the editor."));
const Ho = i("editorLink.activeForeground", { dark: "#4E94CE", light: d.blue, hcDark: d.cyan, hcLight: "#292929" }, n(1820, "Color of active links.")), oe = i("editor.selectionBackground", { light: "#ADD6FF", dark: "#264F78", hcDark: "#f3f518", hcLight: "#0F4A85" }, n(1821, "Color of the editor selection.")), Ro = i("editor.selectionForeground", { light: null, dark: null, hcDark: "#000000", hcLight: d.white }, n(1822, "Color of the selected text for high contrast.")), Tt = i("editor.inactiveSelectionBackground", { light: p(oe, 0.5), dark: p(oe, 0.5), hcDark: p(oe, 0.7), hcLight: p(oe, 0.5) }, n(1823, "Color of the selection in an inactive editor. The color must not be opaque so as not to hide underlying decorations."), !0), It = i("editor.selectionHighlightBackground", { light: st(oe, R, 0.3, 0.6), dark: st(oe, R, 0.3, 0.6), hcDark: null, hcLight: null }, n(1824, "Color for regions with the same content as the selection. The color must not be opaque so as not to hide underlying decorations."), !0);
i("editor.selectionHighlightBorder", { light: null, dark: null, hcDark: C, hcLight: C }, n(1825, "Border color for regions with the same content as the selection."));
i("editor.compositionBorder", { light: "#000000", dark: "#ffffff", hcLight: "#000000", hcDark: "#ffffff" }, n(1826, "The border color for an IME composition."));
i("editor.findMatchBackground", { light: "#A8AC94", dark: "#515C6A", hcDark: null, hcLight: null }, n(1827, "Color of the current search match."));
const Mo = i("editor.findMatchForeground", null, n(1828, "Text color of the current search match.")), W = i("editor.findMatchHighlightBackground", { light: "#EA5C0055", dark: "#EA5C0055", hcDark: null, hcLight: null }, n(1829, "Color of the other search matches. The color must not be opaque so as not to hide underlying decorations."), !0), Oo = i("editor.findMatchHighlightForeground", null, n(1830, "Foreground color of the other search matches."), !0);
i("editor.findRangeHighlightBackground", { dark: "#3a3d4166", light: "#b4b4b44d", hcDark: null, hcLight: null }, n(1831, "Color of the range limiting the search. The color must not be opaque so as not to hide underlying decorations."), !0);
i("editor.findMatchBorder", { light: null, dark: null, hcDark: C, hcLight: C }, n(1832, "Border color of the current search match."));
const ne = i("editor.findMatchHighlightBorder", { light: null, dark: null, hcDark: C, hcLight: C }, n(1833, "Border color of the other search matches.")), qo = i("editor.findRangeHighlightBorder", { dark: null, light: null, hcDark: p(C, 0.4), hcLight: p(C, 0.4) }, n(1834, "Border color of the range limiting the search. The color must not be opaque so as not to hide underlying decorations."), !0);
i("editor.hoverHighlightBackground", { light: "#ADD6FF26", dark: "#264f7840", hcDark: "#ADD6FF26", hcLight: null }, n(1835, "Highlight below the word for which a hover is shown. The color must not be opaque so as not to hide underlying decorations."), !0);
const lt = i("editorHoverWidget.background", N, n(1836, "Background color of the editor hover.")), Po = i("editorHoverWidget.foreground", qe, n(1837, "Foreground color of the editor hover.")), Go = i("editorHoverWidget.border", _r, n(1838, "Border color of the editor hover."));
i("editorHoverWidget.statusBarBackground", { dark: H(lt, 0.2), light: Y(lt, 0.05), hcDark: N, hcLight: N }, n(1839, "Background color of the editor hover status bar."));
const Et = i("editorInlayHint.foreground", { dark: "#969696", light: "#969696", hcDark: d.white, hcLight: d.black }, n(1840, "Foreground color of inline hints")), _t = i("editorInlayHint.background", { dark: p(De, 0.1), light: p(De, 0.1), hcDark: p(d.white, 0.1), hcLight: p(De, 0.1) }, n(1841, "Background color of inline hints")), $o = i("editorInlayHint.typeForeground", Et, n(1842, "Foreground color of inline hints for types")), zo = i("editorInlayHint.typeBackground", _t, n(1843, "Background color of inline hints for types")), Wo = i("editorInlayHint.parameterForeground", Et, n(1844, "Foreground color of inline hints for parameters")), Uo = i("editorInlayHint.parameterBackground", _t, n(1845, "Background color of inline hints for parameters")), Hr = i("editorLightBulb.foreground", { dark: "#FFCC00", light: "#DDB100", hcDark: "#FFCC00", hcLight: "#007ACC" }, n(1846, "The color used for the lightbulb actions icon."));
i("editorLightBulbAutoFix.foreground", { dark: "#75BEFF", light: "#007ACC", hcDark: "#75BEFF", hcLight: "#007ACC" }, n(1847, "The color used for the lightbulb auto fix actions icon."));
i("editorLightBulbAi.foreground", Hr, n(1848, "The color used for the lightbulb AI icon."));
i("editor.snippetTabstopHighlightBackground", { dark: new d(new c(124, 124, 124, 0.3)), light: new d(new c(10, 50, 100, 0.2)), hcDark: new d(new c(124, 124, 124, 0.3)), hcLight: new d(new c(10, 50, 100, 0.2)) }, n(1849, "Highlight background color of a snippet tabstop."));
i("editor.snippetTabstopHighlightBorder", null, n(1850, "Highlight border color of a snippet tabstop."));
i("editor.snippetFinalTabstopHighlightBackground", null, n(1851, "Highlight background color of the final tabstop of a snippet."));
i("editor.snippetFinalTabstopHighlightBorder", { dark: "#525252", light: new d(new c(10, 50, 100, 0.5)), hcDark: "#525252", hcLight: "#292929" }, n(1852, "Highlight border color of the final tabstop of a snippet."));
const dt = new d(new c(155, 185, 85, 0.2)), ut = new d(new c(255, 0, 0, 0.2)), jo = i("diffEditor.insertedTextBackground", { dark: "#9ccc2c33", light: "#9ccc2c40", hcDark: null, hcLight: null }, n(1853, "Background color for text that got inserted. The color must not be opaque so as not to hide underlying decorations."), !0), Vo = i("diffEditor.removedTextBackground", { dark: "#ff000033", light: "#ff000033", hcDark: null, hcLight: null }, n(1854, "Background color for text that got removed. The color must not be opaque so as not to hide underlying decorations."), !0), Jo = i("diffEditor.insertedLineBackground", { dark: dt, light: dt, hcDark: null, hcLight: null }, n(1855, "Background color for lines that got inserted. The color must not be opaque so as not to hide underlying decorations."), !0);
i("diffEditor.removedLineBackground", { dark: ut, light: ut, hcDark: null, hcLight: null }, n(1856, "Background color for lines that got removed. The color must not be opaque so as not to hide underlying decorations."), !0);
i("diffEditorGutter.insertedLineBackground", null, n(1857, "Background color for the margin where lines got inserted."));
i("diffEditorGutter.removedLineBackground", null, n(1858, "Background color for the margin where lines got removed."));
const Ko = i("diffEditorOverview.insertedForeground", null, n(1859, "Diff overview ruler foreground for inserted content.")), Qo = i("diffEditorOverview.removedForeground", null, n(1860, "Diff overview ruler foreground for removed content."));
i("diffEditor.insertedTextBorder", { dark: null, light: null, hcDark: "#33ff2eff", hcLight: "#374E06" }, n(1861, "Outline color for the text that got inserted."));
i("diffEditor.removedTextBorder", { dark: null, light: null, hcDark: "#FF008F", hcLight: "#AD0707" }, n(1862, "Outline color for text that got removed."));
i("diffEditor.border", { dark: null, light: null, hcDark: x, hcLight: x }, n(1863, "Border color between the two text editors."));
i("diffEditor.diagonalFill", { dark: "#cccccc33", light: "#22222233", hcDark: null, hcLight: null }, n(1864, "Color of the diff editor's diagonal fill. The diagonal fill is used in side-by-side diff views."));
i("diffEditor.unchangedRegionBackground", "sideBar.background", n(1865, "The background color of unchanged blocks in the diff editor."));
i("diffEditor.unchangedRegionForeground", "foreground", n(1866, "The foreground color of unchanged blocks in the diff editor."));
i("diffEditor.unchangedCodeBackground", { dark: "#74747429", light: "#b8b8b829", hcDark: null, hcLight: null }, n(1867, "The background color of unchanged code in the diff editor."));
const Rr = i("widget.shadow", { dark: p(d.black, 0.36), light: p(d.black, 0.16), hcDark: null, hcLight: null }, n(1868, "Shadow color of widgets such as find/replace inside the editor.")), Zo = i("widget.border", { dark: null, light: null, hcDark: x, hcLight: x }, n(1869, "Border color of widgets such as find/replace inside the editor.")), ht = i("toolbar.hoverBackground", { dark: "#5a5d5e50", light: "#b8b8b850", hcDark: null, hcLight: null }, n(1870, "Toolbar background when hovering over actions using the mouse"));
i("toolbar.hoverOutline", { dark: null, light: null, hcDark: C, hcLight: C }, n(1871, "Toolbar outline when hovering over actions using the mouse"));
i("toolbar.activeBackground", { dark: H(ht, 0.1), light: Y(ht, 0.1), hcDark: null, hcLight: null }, n(1872, "Toolbar background when holding the mouse over actions"));
const Xo = i("breadcrumb.foreground", p(y, 0.8), n(1873, "Color of focused breadcrumb items.")), Yo = i("breadcrumb.background", R, n(1874, "Background color of breadcrumb items.")), en = i("breadcrumb.focusForeground", { light: Y(y, 0.2), dark: H(y, 0.1), hcDark: H(y, 0.1), hcLight: H(y, 0.1) }, n(1875, "Color of focused breadcrumb items.")), tn = i("breadcrumb.activeSelectionForeground", { light: Y(y, 0.2), dark: H(y, 0.1), hcDark: H(y, 0.1), hcLight: H(y, 0.1) }, n(1876, "Color of selected breadcrumb items."));
i("breadcrumbPicker.background", N, n(1877, "Background color of breadcrumb item picker."));
const Nt = 0.5, gt = d.fromHex("#40C8AE").transparent(Nt), ft = d.fromHex("#40A6FF").transparent(Nt), bt = d.fromHex("#606060").transparent(0.4), Pe = 0.4, ce = 1, Te = i("merge.currentHeaderBackground", { dark: gt, light: gt, hcDark: null, hcLight: null }, n(1878, "Current header background in inline merge-conflicts. The color must not be opaque so as not to hide underlying decorations."), !0);
i("merge.currentContentBackground", p(Te, Pe), n(1879, "Current content background in inline merge-conflicts. The color must not be opaque so as not to hide underlying decorations."), !0);
const Ie = i("merge.incomingHeaderBackground", { dark: ft, light: ft, hcDark: null, hcLight: null }, n(1880, "Incoming header background in inline merge-conflicts. The color must not be opaque so as not to hide underlying decorations."), !0);
i("merge.incomingContentBackground", p(Ie, Pe), n(1881, "Incoming content background in inline merge-conflicts. The color must not be opaque so as not to hide underlying decorations."), !0);
const Ee = i("merge.commonHeaderBackground", { dark: bt, light: bt, hcDark: null, hcLight: null }, n(1882, "Common ancestor header background in inline merge-conflicts. The color must not be opaque so as not to hide underlying decorations."), !0);
i("merge.commonContentBackground", p(Ee, Pe), n(1883, "Common ancestor content background in inline merge-conflicts. The color must not be opaque so as not to hide underlying decorations."), !0);
const le = i("merge.border", { dark: null, light: null, hcDark: "#C3DF6F", hcLight: "#007ACC" }, n(1884, "Border color on headers and the splitter in inline merge-conflicts."));
i("editorOverviewRuler.currentContentForeground", { dark: p(Te, ce), light: p(Te, ce), hcDark: le, hcLight: le }, n(1885, "Current overview ruler foreground for inline merge-conflicts."));
i("editorOverviewRuler.incomingContentForeground", { dark: p(Ie, ce), light: p(Ie, ce), hcDark: le, hcLight: le }, n(1886, "Incoming overview ruler foreground for inline merge-conflicts."));
i("editorOverviewRuler.commonContentForeground", { dark: p(Ee, ce), light: p(Ee, ce), hcDark: le, hcLight: le }, n(1887, "Common ancestor overview ruler foreground for inline merge-conflicts."));
const rn = i("editorOverviewRuler.findMatchForeground", { dark: "#d186167e", light: "#d186167e", hcDark: "#AB5A00", hcLight: "#AB5A00" }, n(1888, "Overview ruler marker color for find matches. The color must not be opaque so as not to hide underlying decorations."), !0), on = i("editorOverviewRuler.selectionHighlightForeground", "#A0A0A0CC", n(1889, "Overview ruler marker color for selection highlights. The color must not be opaque so as not to hide underlying decorations."), !0), nn = i("problemsErrorIcon.foreground", At, n(1890, "The color used for the problems error icon.")), an = i("problemsWarningIcon.foreground", X, n(1891, "The color used for the problems warning icon.")), sn = i("problemsInfoIcon.foreground", se, n(1892, "The color used for the problems info icon.")), Mr = i("minimap.findMatchHighlight", { light: "#d18616", dark: "#d18616", hcDark: "#AB5A00", hcLight: "#0F4A85" }, n(1983, "Minimap marker color for find matches."), !0), cn = i("minimap.selectionOccurrenceHighlight", { light: "#c9c9c9", dark: "#676767", hcDark: "#ffffff", hcLight: "#0F4A85" }, n(1984, "Minimap marker color for repeating editor selections."), !0), ln = i("minimap.selectionHighlight", { light: "#ADD6FF", dark: "#264F78", hcDark: "#ffffff", hcLight: "#0F4A85" }, n(1985, "Minimap marker color for the editor selection."), !0), dn = i("minimap.infoHighlight", { dark: se, light: se, hcDark: xe, hcLight: xe }, n(1986, "Minimap marker color for infos.")), un = i("minimap.warningHighlight", { dark: X, light: X, hcDark: we, hcLight: we }, n(1987, "Minimap marker color for warnings.")), hn = i("minimap.errorHighlight", { dark: new d(new c(255, 18, 18, 0.7)), light: new d(new c(255, 18, 18, 0.7)), hcDark: new d(new c(255, 50, 50, 1)), hcLight: "#B5200D" }, n(1988, "Minimap marker color for errors.")), gn = i("minimap.background", null, n(1989, "Minimap background color.")), fn = i("minimap.foregroundOpacity", d.fromHex("#000f"), n(1990, 'Opacity of foreground elements rendered in the minimap. For example, "#000000c0" will render the elements with 75% opacity.'));
i("minimapSlider.background", p(Tr, 0.5), n(1991, "Minimap slider background color."));
i("minimapSlider.hoverBackground", p(Ir, 0.5), n(1992, "Minimap slider background color when hovering."));
i("minimapSlider.activeBackground", p(Er, 0.5), n(1993, "Minimap slider background color when clicked on."));
i("charts.foreground", y, n(1790, "The foreground color used in charts."));
i("charts.lines", p(y, 0.5), n(1791, "The color used for horizontal lines in charts."));
i("charts.red", At, n(1792, "The red color used in chart visualizations."));
i("charts.blue", se, n(1793, "The blue color used in chart visualizations."));
i("charts.yellow", X, n(1794, "The yellow color used in chart visualizations."));
i("charts.orange", Mr, n(1795, "The orange color used in chart visualizations."));
i("charts.green", { dark: "#89D185", light: "#388A34", hcDark: "#89D185", hcLight: "#374e06" }, n(1796, "The green color used in chart visualizations."));
i("charts.purple", { dark: "#B180D7", light: "#652D90", hcDark: "#B180D7", hcLight: "#652D90" }, n(1797, "The purple color used in chart visualizations."));
const bn = i("input.background", { dark: "#3C3C3C", light: d.white, hcDark: d.black, hcLight: d.white }, n(1893, "Input box background.")), mn = i("input.foreground", y, n(1894, "Input box foreground.")), kn = i("input.border", { dark: null, light: null, hcDark: x, hcLight: x }, n(1895, "Input box border.")), Or = i("inputOption.activeBorder", { dark: "#007ACC", light: "#007ACC", hcDark: x, hcLight: x }, n(1896, "Border color of activated options in input fields.")), qr = i("inputOption.hoverBackground", { dark: "#5a5d5e80", light: "#b8b8b850", hcDark: null, hcLight: null }, n(1897, "Background color of activated options in input fields.")), Pr = i("inputOption.activeBackground", { dark: p(G, 0.4), light: p(G, 0.2), hcDark: d.transparent, hcLight: d.transparent }, n(1898, "Background hover color of options in input fields.")), Gr = i("inputOption.activeForeground", { dark: d.white, light: d.black, hcDark: y, hcLight: y }, n(1899, "Foreground color of activated options in input fields."));
i("input.placeholderForeground", { light: p(y, 0.5), dark: p(y, 0.5), hcDark: p(y, 0.7), hcLight: p(y, 0.7) }, n(1900, "Input box foreground color for placeholder text."));
const pn = i("inputValidation.infoBackground", { dark: "#063B49", light: "#D6ECF2", hcDark: d.black, hcLight: d.white }, n(1901, "Input validation background color for information severity.")), wn = i("inputValidation.infoForeground", { dark: null, light: null, hcDark: null, hcLight: y }, n(1902, "Input validation foreground color for information severity.")), xn = i("inputValidation.infoBorder", { dark: "#007acc", light: "#007acc", hcDark: x, hcLight: x }, n(1903, "Input validation border color for information severity.")), yn = i("inputValidation.warningBackground", { dark: "#352A05", light: "#F6F5D2", hcDark: d.black, hcLight: d.white }, n(1904, "Input validation background color for warning severity.")), vn = i("inputValidation.warningForeground", { dark: null, light: null, hcDark: null, hcLight: y }, n(1905, "Input validation foreground color for warning severity.")), Fn = i("inputValidation.warningBorder", { dark: "#B89500", light: "#B89500", hcDark: x, hcLight: x }, n(1906, "Input validation border color for warning severity.")), Bn = i("inputValidation.errorBackground", { dark: "#5A1D1D", light: "#F2DEDE", hcDark: d.black, hcLight: d.white }, n(1907, "Input validation background color for error severity.")), Cn = i("inputValidation.errorForeground", { dark: null, light: null, hcDark: null, hcLight: y }, n(1908, "Input validation foreground color for error severity.")), Dn = i("inputValidation.errorBorder", { dark: "#BE1100", light: "#BE1100", hcDark: x, hcLight: x }, n(1909, "Input validation border color for error severity.")), Ge = i("dropdown.background", { dark: "#3C3C3C", light: d.white, hcDark: d.black, hcLight: d.white }, n(1910, "Dropdown background.")), Ln = i("dropdown.listBackground", { dark: null, light: null, hcDark: d.black, hcLight: d.white }, n(1911, "Dropdown list background.")), Ht = i("dropdown.foreground", { dark: "#F0F0F0", light: y, hcDark: d.white, hcLight: y }, n(1912, "Dropdown foreground.")), $r = i("dropdown.border", { dark: Ge, light: "#CECECE", hcDark: x, hcLight: x }, n(1913, "Dropdown border.")), zr = i("button.foreground", d.white, n(1914, "Button foreground color.")), Sn = i("button.separator", p(zr, 0.4), n(1915, "Button separator color.")), he = i("button.background", { dark: "#0E639C", light: "#007ACC", hcDark: d.black, hcLight: "#0F4A85" }, n(1916, "Button background color.")), An = i("button.hoverBackground", { dark: H(he, 0.2), light: Y(he, 0.2), hcDark: he, hcLight: he }, n(1917, "Button background color when hovering.")), Tn = i("button.border", x, n(1918, "Button border color.")), In = i("button.secondaryForeground", { dark: d.white, light: d.white, hcDark: d.white, hcLight: y }, n(1919, "Secondary button foreground color.")), mt = i("button.secondaryBackground", { dark: "#3A3D41", light: "#5F6A79", hcDark: null, hcLight: d.white }, n(1920, "Secondary button background color.")), En = i("button.secondaryHoverBackground", { dark: H(mt, 0.2), light: Y(mt, 0.2), hcDark: null, hcLight: null }, n(1921, "Secondary button background color when hovering.")), ge = i("radio.activeForeground", Gr, n(1922, "Foreground color of active radio option.")), _n = i("radio.activeBackground", Pr, n(1923, "Background color of active radio option.")), Nn = i("radio.activeBorder", Or, n(1924, "Border color of the active radio option.")), Hn = i("radio.inactiveForeground", null, n(1925, "Foreground color of inactive radio option.")), Rn = i("radio.inactiveBackground", null, n(1926, "Background color of inactive radio option.")), Mn = i("radio.inactiveBorder", { light: p(ge, 0.2), dark: p(ge, 0.2), hcDark: p(ge, 0.4), hcLight: p(ge, 0.2) }, n(1927, "Border color of the inactive radio option.")), On = i("radio.inactiveHoverBackground", qr, n(1928, "Background color of inactive active radio option when hovering.")), Rt = i("checkbox.background", Ge, n(1929, "Background color of checkbox widget."));
i("checkbox.selectBackground", N, n(1930, "Background color of checkbox widget when the element it's in is selected."));
const Mt = i("checkbox.foreground", Ht, n(1931, "Foreground color of checkbox widget.")), qn = i("checkbox.border", $r, n(1932, "Border color of checkbox widget."));
i("checkbox.selectBorder", Ae, n(1933, "Border color of checkbox widget when the element it's in is selected."));
const Pn = i("checkbox.disabled.background", { op: 7, color: Rt, with: Mt, ratio: 0.33 }, n(1934, "Background of a disabled checkbox.")), Gn = i("checkbox.disabled.foreground", { op: 7, color: Mt, with: Rt, ratio: 0.33 }, n(1935, "Foreground of a disabled checkbox.")), $n = i("keybindingLabel.background", { dark: new d(new c(128, 128, 128, 0.17)), light: new d(new c(221, 221, 221, 0.4)), hcDark: d.transparent, hcLight: d.transparent }, n(1936, "Keybinding label background color. The keybinding label is used to represent a keyboard shortcut.")), zn = i("keybindingLabel.foreground", { dark: d.fromHex("#CCCCCC"), light: d.fromHex("#555555"), hcDark: d.white, hcLight: y }, n(1937, "Keybinding label foreground color. The keybinding label is used to represent a keyboard shortcut.")), Wn = i("keybindingLabel.border", { dark: new d(new c(51, 51, 51, 0.6)), light: new d(new c(204, 204, 204, 0.4)), hcDark: new d(new c(111, 195, 223)), hcLight: x }, n(1938, "Keybinding label border color. The keybinding label is used to represent a keyboard shortcut.")), Un = i("keybindingLabel.bottomBorder", { dark: new d(new c(68, 68, 68, 0.6)), light: new d(new c(187, 187, 187, 0.4)), hcDark: new d(new c(111, 195, 223)), hcLight: y }, n(1939, "Keybinding label border bottom color. The keybinding label is used to represent a keyboard shortcut.")), jn = i("list.focusBackground", null, n(1940, "List/Tree background color for the focused item when the list/tree is active. An active list/tree has keyboard focus, an inactive does not.")), Vn = i("list.focusForeground", null, n(1941, "List/Tree foreground color for the focused item when the list/tree is active. An active list/tree has keyboard focus, an inactive does not.")), Jn = i("list.focusOutline", { dark: G, light: G, hcDark: C, hcLight: C }, n(1942, "List/Tree outline color for the focused item when the list/tree is active. An active list/tree has keyboard focus, an inactive does not.")), Kn = i("list.focusAndSelectionOutline", null, n(1943, "List/Tree outline color for the focused item when the list/tree is active and selected. An active list/tree has keyboard focus, an inactive does not.")), ue = i("list.activeSelectionBackground", { dark: "#04395E", light: "#0060C0", hcDark: null, hcLight: d.fromHex("#0F4A85").transparent(0.1) }, n(1944, "List/Tree background color for the selected item when the list/tree is active. An active list/tree has keyboard focus, an inactive does not.")), $e = i("list.activeSelectionForeground", { dark: d.white, light: d.white, hcDark: null, hcLight: null }, n(1945, "List/Tree foreground color for the selected item when the list/tree is active. An active list/tree has keyboard focus, an inactive does not.")), Wr = i("list.activeSelectionIconForeground", null, n(1946, "List/Tree icon foreground color for the selected item when the list/tree is active. An active list/tree has keyboard focus, an inactive does not.")), Qn = i("list.inactiveSelectionBackground", { dark: "#37373D", light: "#E4E6F1", hcDark: null, hcLight: d.fromHex("#0F4A85").transparent(0.1) }, n(1947, "List/Tree background color for the selected item when the list/tree is inactive. An active list/tree has keyboard focus, an inactive does not.")), Zn = i("list.inactiveSelectionForeground", null, n(1948, "List/Tree foreground color for the selected item when the list/tree is inactive. An active list/tree has keyboard focus, an inactive does not.")), Xn = i("list.inactiveSelectionIconForeground", null, n(1949, "List/Tree icon foreground color for the selected item when the list/tree is inactive. An active list/tree has keyboard focus, an inactive does not.")), Yn = i("list.inactiveFocusBackground", null, n(1950, "List/Tree background color for the focused item when the list/tree is inactive. An active list/tree has keyboard focus, an inactive does not.")), ei = i("list.inactiveFocusOutline", null, n(1951, "List/Tree outline color for the focused item when the list/tree is inactive. An active list/tree has keyboard focus, an inactive does not.")), ti = i("list.hoverBackground", { dark: "#2A2D2E", light: "#F0F0F0", hcDark: d.white.transparent(0.1), hcLight: d.fromHex("#0F4A85").transparent(0.1) }, n(1952, "List/Tree background when hovering over items using the mouse.")), ri = i("list.hoverForeground", null, n(1953, "List/Tree foreground when hovering over items using the mouse.")), oi = i("list.dropBackground", { dark: "#062F4A", light: "#D6EBFF", hcDark: null, hcLight: null }, n(1954, "List/Tree drag and drop background when moving items over other items when using the mouse.")), ni = i("list.dropBetweenBackground", { dark: Ae, light: Ae, hcDark: null, hcLight: null }, n(1955, "List/Tree drag and drop border color when moving items between items when using the mouse.")), fe = i("list.highlightForeground", { dark: "#2AAAFF", light: "#0066BF", hcDark: G, hcLight: G }, n(1956, "List/Tree foreground color of the match highlights when searching inside the list/tree.")), ii = i("list.focusHighlightForeground", { dark: fe, light: Sr(ue, fe, "#BBE7FF"), hcDark: fe, hcLight: fe }, n(1957, "List/Tree foreground color of the match highlights on actively focused items when searching inside the list/tree."));
i("list.invalidItemForeground", { dark: "#B89500", light: "#B89500", hcDark: "#B89500", hcLight: "#B5200D" }, n(1958, "List/Tree foreground color for invalid items, for example an unresolved root in explorer."));
i("list.errorForeground", { dark: "#F88070", light: "#B01011", hcDark: null, hcLight: null }, n(1959, "Foreground color of list items containing errors."));
i("list.warningForeground", { dark: "#CCA700", light: "#855F00", hcDark: null, hcLight: null }, n(1960, "Foreground color of list items containing warnings."));
const ai = i("listFilterWidget.background", { light: Y(N, 0), dark: H(N, 0), hcDark: N, hcLight: N }, n(1961, "Background color of the type filter widget in lists and trees.")), si = i("listFilterWidget.outline", { dark: d.transparent, light: d.transparent, hcDark: "#f38518", hcLight: "#007ACC" }, n(1962, "Outline color of the type filter widget in lists and trees.")), ci = i("listFilterWidget.noMatchesOutline", { dark: "#BE1100", light: "#BE1100", hcDark: x, hcLight: x }, n(1963, "Outline color of the type filter widget in lists and trees, when there are no matches.")), li = i("listFilterWidget.shadow", Rr, n(1964, "Shadow color of the type filter widget in lists and trees."));
i("list.filterMatchBackground", { dark: W, light: W, hcDark: null, hcLight: null }, n(1965, "Background color of the filtered match."));
i("list.filterMatchBorder", { dark: ne, light: ne, hcDark: x, hcLight: C }, n(1966, "Border color of the filtered match."));
i("list.deemphasizedForeground", { dark: "#8C8C8C", light: "#8E8E90", hcDark: "#A7A8A9", hcLight: "#666666" }, n(1967, "List/Tree foreground color for items that are deemphasized."));
const Ur = i("tree.indentGuidesStroke", { dark: "#585858", light: "#a9a9a9", hcDark: "#a9a9a9", hcLight: "#a5a5a5" }, n(1968, "Tree stroke color for the indentation guides.")), di = i("tree.inactiveIndentGuidesStroke", p(Ur, 0.4), n(1969, "Tree stroke color for the indentation guides that are not active.")), ui = i("tree.tableColumnsBorder", { dark: "#CCCCCC20", light: "#61616120", hcDark: null, hcLight: null }, n(1970, "Table border color between columns.")), hi = i("tree.tableOddRowsBackground", { dark: p(y, 0.04), light: p(y, 0.04), hcDark: null, hcLight: null }, n(1971, "Background color for odd table rows."));
i("editorActionList.background", N, n(1972, "Action List background color."));
const gi = i("editorActionList.foreground", qe, n(1973, "Action List foreground color."));
i("editorActionList.focusForeground", $e, n(1974, "Action List foreground color for the focused item."));
i("editorActionList.focusBackground", ue, n(1975, "Action List background color for the focused item."));
const fi = i("menu.border", { dark: null, light: null, hcDark: x, hcLight: x }, n(1976, "Border color of menus.")), bi = i("menu.foreground", Ht, n(1977, "Foreground color of menu items.")), mi = i("menu.background", Ge, n(1978, "Background color of menu items.")), ki = i("menu.selectionForeground", $e, n(1979, "Foreground color of the selected menu item in menus.")), pi = i("menu.selectionBackground", ue, n(1980, "Background color of the selected menu item in menus.")), wi = i("menu.selectionBorder", { dark: null, light: null, hcDark: C, hcLight: C }, n(1981, "Border color of the selected menu item in menus.")), xi = i("menu.separatorBackground", { dark: "#606060", light: "#D4D4D4", hcDark: x, hcLight: x }, n(1982, "Color of a separator menu item in menus.")), yi = i("quickInput.background", N, n(2010, "Quick picker background color. The quick picker widget is the container for pickers like the command palette.")), vi = i("quickInput.foreground", qe, n(2011, "Quick picker foreground color. The quick picker widget is the container for pickers like the command palette.")), Fi = i("quickInputTitle.background", { dark: new d(new c(255, 255, 255, 0.105)), light: new d(new c(0, 0, 0, 0.06)), hcDark: "#000000", hcLight: d.white }, n(2012, "Quick picker title background color. The quick picker widget is the container for pickers like the command palette.")), Bi = i("pickerGroup.foreground", { dark: "#3794FF", light: "#0066BF", hcDark: d.white, hcLight: "#0F4A85" }, n(2013, "Quick picker color for grouping labels.")), Ci = i("pickerGroup.border", { dark: "#3F3F46", light: "#CCCEDB", hcDark: d.white, hcLight: "#0F4A85" }, n(2014, "Quick picker color for grouping borders.")), kt = i("quickInput.list.focusBackground", null, "", void 0, n(2015, "Please use quickInputList.focusBackground instead")), Di = i("quickInputList.focusForeground", $e, n(2016, "Quick picker foreground color for the focused item.")), Li = i("quickInputList.focusIconForeground", Wr, n(2017, "Quick picker icon foreground color for the focused item.")), Si = i("quickInputList.focusBackground", { dark: at(kt, ue), light: at(kt, ue), hcDark: null, hcLight: null }, n(2018, "Quick picker background color for the focused item."));
i("search.resultsInfoForeground", { light: y, dark: p(y, 0.65), hcDark: y, hcLight: y }, n(2019, "Color of the text in the search viewlet's completion message."));
i("searchEditor.findMatchBackground", { light: p(W, 0.66), dark: p(W, 0.66), hcDark: W, hcLight: W }, n(2020, "Color of the Search Editor query matches."));
i("searchEditor.findMatchBorder", { light: p(ne, 0.66), dark: p(ne, 0.66), hcDark: ne, hcLight: ne }, n(2021, "Border color of the Search Editor query matches."));
var P;
(function(r) {
  r.serviceIds = /* @__PURE__ */ new Map(), r.DI_TARGET = "$di$target", r.DI_DEPENDENCIES = "$di$dependencies";
  function e(o) {
    return o[r.DI_DEPENDENCIES] || [];
  }
  r.getServiceDependencies = e;
})(P || (P = {}));
const Ai = Ot("instantiationService");
function jr(r, e, o) {
  e[P.DI_TARGET] === e ? e[P.DI_DEPENDENCIES].push({ id: r, index: o }) : (e[P.DI_DEPENDENCIES] = [{ id: r, index: o }], e[P.DI_TARGET] = e);
}
function Ot(r) {
  if (P.serviceIds.has(r))
    return P.serviceIds.get(r);
  const e = function(o, a, s) {
    if (arguments.length !== 3)
      throw new Error("@IServiceName-decorator can only be used to decorate a parameter");
    jr(e, o, s);
  };
  return e.toString = () => r, P.serviceIds.set(r, e), e;
}
var E;
(function(r) {
  r.DARK = "dark", r.LIGHT = "light", r.HIGH_CONTRAST_DARK = "hcDark", r.HIGH_CONTRAST_LIGHT = "hcLight";
})(E || (E = {}));
var ie;
(function(r) {
  r.VS = "vs", r.VS_DARK = "vs-dark", r.HC_BLACK = "hc-black", r.HC_LIGHT = "hc-light";
})(ie || (ie = {}));
function Vr(r) {
  return r === E.HIGH_CONTRAST_DARK || r === E.HIGH_CONTRAST_LIGHT;
}
function Jr(r) {
  return r === E.DARK || r === E.HIGH_CONTRAST_DARK;
}
const Ti = Ot("themeService");
function Ii(r) {
  return { id: r };
}
function Ei(r) {
  switch (r) {
    case E.DARK:
      return ie.VS_DARK;
    case E.HIGH_CONTRAST_DARK:
      return ie.HC_BLACK;
    case E.HIGH_CONTRAST_LIGHT:
      return ie.HC_LIGHT;
    default:
      return ie.VS;
  }
}
const qt = {
  ThemingContribution: "base.contributions.theming"
};
class Kr extends V {
  constructor() {
    super(), this.themingParticipants = [], this.themingParticipants = [], this.onThemingParticipantAddedEmitter = this._register(new j());
  }
  onColorThemeChange(e) {
    return this.themingParticipants.push(e), this.onThemingParticipantAddedEmitter.fire(e), pe(() => {
      const o = this.themingParticipants.indexOf(e);
      this.themingParticipants.splice(o, 1);
    });
  }
  getThemingParticipants() {
    return this.themingParticipants;
  }
}
const Pt = new Kr();
J.add(qt.ThemingContribution, Pt);
function Qr(r) {
  return Pt.onColorThemeChange(r);
}
class _i extends V {
  constructor(e) {
    super(), this.themeService = e, this.theme = e.getColorTheme(), this._register(this.themeService.onDidColorThemeChange((o) => this.onThemeChange(o)));
  }
  onThemeChange(e) {
    this.theme = e, this.updateStyles();
  }
  updateStyles() {
  }
}
const Zr = i("editor.lineHighlightBackground", null, n(610, "Background color for the highlight of line at the cursor position.")), Ni = i("editor.lineHighlightBorder", { dark: "#282828", light: "#eeeeee", hcDark: "#f38518", hcLight: x }, n(611, "Background color for the border around the line at the cursor position."));
i("editor.rangeHighlightBackground", { dark: "#ffffff0b", light: "#fdff0033", hcDark: null, hcLight: null }, n(612, "Background color of highlighted ranges, like by quick open and find features. The color must not be opaque so as not to hide underlying decorations."), !0);
i("editor.rangeHighlightBorder", { dark: null, light: null, hcDark: C, hcLight: C }, n(613, "Background color of the border around highlighted ranges."));
i("editor.symbolHighlightBackground", { dark: W, light: W, hcDark: null, hcLight: null }, n(614, "Background color of highlighted symbol, like for go to definition or go next/previous symbol. The color must not be opaque so as not to hide underlying decorations."), !0);
i("editor.symbolHighlightBorder", { dark: null, light: null, hcDark: C, hcLight: C }, n(615, "Background color of the border around highlighted symbols."));
const Gt = i("editorCursor.foreground", { dark: "#AEAFAD", light: d.black, hcDark: d.white, hcLight: "#0F4A85" }, n(616, "Color of the editor cursor.")), $t = i("editorCursor.background", null, n(617, "The background color of the editor cursor. Allows customizing the color of a character overlapped by a block cursor.")), Hi = i("editorMultiCursor.primary.foreground", Gt, n(618, "Color of the primary editor cursor when multiple cursors are present.")), Ri = i("editorMultiCursor.primary.background", $t, n(619, "The background color of the primary editor cursor when multiple cursors are present. Allows customizing the color of a character overlapped by a block cursor.")), Mi = i("editorMultiCursor.secondary.foreground", Gt, n(620, "Color of secondary editor cursors when multiple cursors are present.")), Oi = i("editorMultiCursor.secondary.background", $t, n(621, "The background color of secondary editor cursors when multiple cursors are present. Allows customizing the color of a character overlapped by a block cursor.")), zt = i("editorWhitespace.foreground", { dark: "#e3e4e229", light: "#33333333", hcDark: "#e3e4e229", hcLight: "#CCCCCC" }, n(622, "Color of whitespace characters in the editor.")), qi = i("editorLineNumber.foreground", { dark: "#858585", light: "#237893", hcDark: d.white, hcLight: "#292929" }, n(623, "Color of editor line numbers.")), Xr = i("editorIndentGuide.background", zt, n(624, "Color of the editor indentation guides."), !1, n(625, "'editorIndentGuide.background' is deprecated. Use 'editorIndentGuide.background1' instead.")), Yr = i("editorIndentGuide.activeBackground", zt, n(626, "Color of the active editor indentation guides."), !1, n(627, "'editorIndentGuide.activeBackground' is deprecated. Use 'editorIndentGuide.activeBackground1' instead.")), Fe = i("editorIndentGuide.background1", Xr, n(628, "Color of the editor indentation guides (1).")), Pi = i("editorIndentGuide.background2", "#00000000", n(629, "Color of the editor indentation guides (2).")), Gi = i("editorIndentGuide.background3", "#00000000", n(630, "Color of the editor indentation guides (3).")), $i = i("editorIndentGuide.background4", "#00000000", n(631, "Color of the editor indentation guides (4).")), zi = i("editorIndentGuide.background5", "#00000000", n(632, "Color of the editor indentation guides (5).")), Wi = i("editorIndentGuide.background6", "#00000000", n(633, "Color of the editor indentation guides (6).")), Be = i("editorIndentGuide.activeBackground1", Yr, n(634, "Color of the active editor indentation guides (1).")), Ui = i("editorIndentGuide.activeBackground2", "#00000000", n(635, "Color of the active editor indentation guides (2).")), ji = i("editorIndentGuide.activeBackground3", "#00000000", n(636, "Color of the active editor indentation guides (3).")), Vi = i("editorIndentGuide.activeBackground4", "#00000000", n(637, "Color of the active editor indentation guides (4).")), Ji = i("editorIndentGuide.activeBackground5", "#00000000", n(638, "Color of the active editor indentation guides (5).")), Ki = i("editorIndentGuide.activeBackground6", "#00000000", n(639, "Color of the active editor indentation guides (6).")), eo = i("editorActiveLineNumber.foreground", { dark: "#c6c6c6", light: "#0B216F", hcDark: C, hcLight: C }, n(640, "Color of editor active line number"), !1, n(641, "Id is deprecated. Use 'editorLineNumber.activeForeground' instead."));
i("editorLineNumber.activeForeground", eo, n(642, "Color of editor active line number"));
const Qi = i("editorLineNumber.dimmedForeground", null, n(643, "Color of the final editor line when editor.renderFinalNewline is set to dimmed.")), Zi = i("editorRuler.foreground", { dark: "#5A5A5A", light: d.lightgrey, hcDark: d.white, hcLight: "#292929" }, n(644, "Color of the editor rulers."));
i("editorCodeLens.foreground", { dark: "#999999", light: "#919191", hcDark: "#999999", hcLight: "#292929" }, n(645, "Foreground color of editor CodeLens"));
i("editorBracketMatch.background", { dark: "#0064001a", light: "#0064001a", hcDark: "#0064001a", hcLight: "#0000" }, n(646, "Background color behind matching brackets"));
i("editorBracketMatch.border", { dark: "#888", light: "#B9B9B9", hcDark: x, hcLight: x }, n(647, "Color for matching brackets boxes"));
const Xi = i("editorOverviewRuler.border", { dark: "#7f7f7f4d", light: "#7f7f7f4d", hcDark: "#7f7f7f4d", hcLight: "#666666" }, n(648, "Color of the overview ruler border.")), Yi = i("editorOverviewRuler.background", null, n(649, "Background color of the editor overview ruler."));
i("editorGutter.background", R, n(650, "Background color of the editor gutter. The gutter contains the glyph margins and the line numbers."));
i("editorUnnecessaryCode.border", { dark: null, light: null, hcDark: d.fromHex("#fff").transparent(0.8), hcLight: x }, n(651, "Border color of unnecessary (unused) source code in the editor."));
const ea = i("editorUnnecessaryCode.opacity", { dark: d.fromHex("#000a"), light: d.fromHex("#0007"), hcDark: null, hcLight: null }, n(652, `Opacity of unnecessary (unused) source code in the editor. For example, "#000000c0" will render the code with 75% opacity. For high contrast themes, use the  'editorUnnecessaryCode.border' theme color to underline unnecessary code instead of fading it out.`));
i("editorGhostText.border", { dark: null, light: null, hcDark: d.fromHex("#fff").transparent(0.8), hcLight: d.fromHex("#292929").transparent(0.8) }, n(653, "Border color of ghost text in the editor."));
const ta = i("editorGhostText.foreground", { dark: d.fromHex("#ffffff56"), light: d.fromHex("#0007"), hcDark: null, hcLight: null }, n(654, "Foreground color of the ghost text in the editor."));
i("editorGhostText.background", null, n(655, "Background color of the ghost text in the editor."));
const to = new d(new c(0, 122, 204, 0.6)), ra = i("editorOverviewRuler.rangeHighlightForeground", to, n(656, "Overview ruler marker color for range highlights. The color must not be opaque so as not to hide underlying decorations."), !0), oa = i("editorOverviewRuler.errorForeground", { dark: new d(new c(255, 18, 18, 0.7)), light: new d(new c(255, 18, 18, 0.7)), hcDark: new d(new c(255, 50, 50, 1)), hcLight: "#B5200D" }, n(657, "Overview ruler marker color for errors.")), na = i("editorOverviewRuler.warningForeground", { dark: X, light: X, hcDark: we, hcLight: we }, n(658, "Overview ruler marker color for warnings.")), ia = i("editorOverviewRuler.infoForeground", { dark: se, light: se, hcDark: xe, hcLight: xe }, n(659, "Overview ruler marker color for infos.")), aa = i("editorBracketHighlight.foreground1", { dark: "#FFD700", light: "#0431FAFF", hcDark: "#FFD700", hcLight: "#0431FAFF" }, n(660, "Foreground color of brackets (1). Requires enabling bracket pair colorization.")), sa = i("editorBracketHighlight.foreground2", { dark: "#DA70D6", light: "#319331FF", hcDark: "#DA70D6", hcLight: "#319331FF" }, n(661, "Foreground color of brackets (2). Requires enabling bracket pair colorization.")), ca = i("editorBracketHighlight.foreground3", { dark: "#179FFF", light: "#7B3814FF", hcDark: "#87CEFA", hcLight: "#7B3814FF" }, n(662, "Foreground color of brackets (3). Requires enabling bracket pair colorization.")), la = i("editorBracketHighlight.foreground4", "#00000000", n(663, "Foreground color of brackets (4). Requires enabling bracket pair colorization.")), da = i("editorBracketHighlight.foreground5", "#00000000", n(664, "Foreground color of brackets (5). Requires enabling bracket pair colorization.")), ua = i("editorBracketHighlight.foreground6", "#00000000", n(665, "Foreground color of brackets (6). Requires enabling bracket pair colorization.")), ha = i("editorBracketHighlight.unexpectedBracket.foreground", { dark: new d(new c(255, 18, 18, 0.8)), light: new d(new c(255, 18, 18, 0.8)), hcDark: new d(new c(255, 50, 50, 1)), hcLight: "#B5200D" }, n(666, "Foreground color of unexpected brackets.")), ga = i("editorBracketPairGuide.background1", "#00000000", n(667, "Background color of inactive bracket pair guides (1). Requires enabling bracket pair guides.")), fa = i("editorBracketPairGuide.background2", "#00000000", n(668, "Background color of inactive bracket pair guides (2). Requires enabling bracket pair guides.")), ba = i("editorBracketPairGuide.background3", "#00000000", n(669, "Background color of inactive bracket pair guides (3). Requires enabling bracket pair guides.")), ma = i("editorBracketPairGuide.background4", "#00000000", n(670, "Background color of inactive bracket pair guides (4). Requires enabling bracket pair guides.")), ka = i("editorBracketPairGuide.background5", "#00000000", n(671, "Background color of inactive bracket pair guides (5). Requires enabling bracket pair guides.")), pa = i("editorBracketPairGuide.background6", "#00000000", n(672, "Background color of inactive bracket pair guides (6). Requires enabling bracket pair guides.")), wa = i("editorBracketPairGuide.activeBackground1", "#00000000", n(673, "Background color of active bracket pair guides (1). Requires enabling bracket pair guides.")), xa = i("editorBracketPairGuide.activeBackground2", "#00000000", n(674, "Background color of active bracket pair guides (2). Requires enabling bracket pair guides.")), ya = i("editorBracketPairGuide.activeBackground3", "#00000000", n(675, "Background color of active bracket pair guides (3). Requires enabling bracket pair guides.")), va = i("editorBracketPairGuide.activeBackground4", "#00000000", n(676, "Background color of active bracket pair guides (4). Requires enabling bracket pair guides.")), Fa = i("editorBracketPairGuide.activeBackground5", "#00000000", n(677, "Background color of active bracket pair guides (5). Requires enabling bracket pair guides.")), Ba = i("editorBracketPairGuide.activeBackground6", "#00000000", n(678, "Background color of active bracket pair guides (6). Requires enabling bracket pair guides."));
i("editorUnicodeHighlight.border", X, n(679, "Border color used to highlight unicode characters."));
i("editorUnicodeHighlight.background", Nr, n(680, "Background color used to highlight unicode characters."));
Qr((r, e) => {
  const o = r.getColor(R), a = r.getColor(Zr), s = a && !a.isTransparent() ? a : o;
  s && e.addRule(`.monaco-editor .inputarea.ime-input { background-color: ${s}; }`);
});
const ro = {
  base: "vs",
  inherit: !1,
  rules: [
    { token: "", foreground: "000000", background: "fffffe" },
    { token: "invalid", foreground: "cd3131" },
    { token: "emphasis", fontStyle: "italic" },
    { token: "strong", fontStyle: "bold" },
    { token: "variable", foreground: "001188" },
    { token: "variable.predefined", foreground: "4864AA" },
    { token: "constant", foreground: "dd0000" },
    { token: "comment", foreground: "008000" },
    { token: "number", foreground: "098658" },
    { token: "number.hex", foreground: "3030c0" },
    { token: "regexp", foreground: "800000" },
    { token: "annotation", foreground: "808080" },
    { token: "type", foreground: "008080" },
    { token: "delimiter", foreground: "000000" },
    { token: "delimiter.html", foreground: "383838" },
    { token: "delimiter.xml", foreground: "0000FF" },
    { token: "tag", foreground: "800000" },
    { token: "tag.id.pug", foreground: "4F76AC" },
    { token: "tag.class.pug", foreground: "4F76AC" },
    { token: "meta.scss", foreground: "800000" },
    { token: "metatag", foreground: "e00000" },
    { token: "metatag.content.html", foreground: "FF0000" },
    { token: "metatag.html", foreground: "808080" },
    { token: "metatag.xml", foreground: "808080" },
    { token: "metatag.php", fontStyle: "bold" },
    { token: "key", foreground: "863B00" },
    { token: "string.key.json", foreground: "A31515" },
    { token: "string.value.json", foreground: "0451A5" },
    { token: "attribute.name", foreground: "FF0000" },
    { token: "attribute.value", foreground: "0451A5" },
    { token: "attribute.value.number", foreground: "098658" },
    { token: "attribute.value.unit", foreground: "098658" },
    { token: "attribute.value.html", foreground: "0000FF" },
    { token: "attribute.value.xml", foreground: "0000FF" },
    { token: "string", foreground: "A31515" },
    { token: "string.html", foreground: "0000FF" },
    { token: "string.sql", foreground: "FF0000" },
    { token: "string.yaml", foreground: "0451A5" },
    { token: "keyword", foreground: "0000FF" },
    { token: "keyword.json", foreground: "0451A5" },
    { token: "keyword.flow", foreground: "AF00DB" },
    { token: "keyword.flow.scss", foreground: "0000FF" },
    { token: "operator.scss", foreground: "666666" },
    { token: "operator.sql", foreground: "778899" },
    { token: "operator.swift", foreground: "666666" },
    { token: "predefined.sql", foreground: "C700C7" }
  ],
  colors: {
    [R]: "#FFFFFE",
    [ve]: "#000000",
    [Tt]: "#E5EBF1",
    [Fe]: "#D3D3D3",
    [Be]: "#939393",
    [It]: "#ADD6FF4D"
  }
}, oo = {
  base: "vs-dark",
  inherit: !1,
  rules: [
    { token: "", foreground: "D4D4D4", background: "1E1E1E" },
    { token: "invalid", foreground: "f44747" },
    { token: "emphasis", fontStyle: "italic" },
    { token: "strong", fontStyle: "bold" },
    { token: "variable", foreground: "74B0DF" },
    { token: "variable.predefined", foreground: "4864AA" },
    { token: "variable.parameter", foreground: "9CDCFE" },
    { token: "constant", foreground: "569CD6" },
    { token: "comment", foreground: "608B4E" },
    { token: "number", foreground: "B5CEA8" },
    { token: "number.hex", foreground: "5BB498" },
    { token: "regexp", foreground: "B46695" },
    { token: "annotation", foreground: "cc6666" },
    { token: "type", foreground: "3DC9B0" },
    { token: "delimiter", foreground: "DCDCDC" },
    { token: "delimiter.html", foreground: "808080" },
    { token: "delimiter.xml", foreground: "808080" },
    { token: "tag", foreground: "569CD6" },
    { token: "tag.id.pug", foreground: "4F76AC" },
    { token: "tag.class.pug", foreground: "4F76AC" },
    { token: "meta.scss", foreground: "A79873" },
    { token: "meta.tag", foreground: "CE9178" },
    { token: "metatag", foreground: "DD6A6F" },
    { token: "metatag.content.html", foreground: "9CDCFE" },
    { token: "metatag.html", foreground: "569CD6" },
    { token: "metatag.xml", foreground: "569CD6" },
    { token: "metatag.php", fontStyle: "bold" },
    { token: "key", foreground: "9CDCFE" },
    { token: "string.key.json", foreground: "9CDCFE" },
    { token: "string.value.json", foreground: "CE9178" },
    { token: "attribute.name", foreground: "9CDCFE" },
    { token: "attribute.value", foreground: "CE9178" },
    { token: "attribute.value.number.css", foreground: "B5CEA8" },
    { token: "attribute.value.unit.css", foreground: "B5CEA8" },
    { token: "attribute.value.hex.css", foreground: "D4D4D4" },
    { token: "string", foreground: "CE9178" },
    { token: "string.sql", foreground: "FF0000" },
    { token: "keyword", foreground: "569CD6" },
    { token: "keyword.flow", foreground: "C586C0" },
    { token: "keyword.json", foreground: "CE9178" },
    { token: "keyword.flow.scss", foreground: "569CD6" },
    { token: "operator.scss", foreground: "909090" },
    { token: "operator.sql", foreground: "778899" },
    { token: "operator.swift", foreground: "909090" },
    { token: "predefined.sql", foreground: "FF00FF" }
  ],
  colors: {
    [R]: "#1E1E1E",
    [ve]: "#D4D4D4",
    [Tt]: "#3A3D41",
    [Fe]: "#404040",
    [Be]: "#707070",
    [It]: "#ADD6FF26"
  }
}, no = {
  base: "hc-black",
  inherit: !1,
  rules: [
    { token: "", foreground: "FFFFFF", background: "000000" },
    { token: "invalid", foreground: "f44747" },
    { token: "emphasis", fontStyle: "italic" },
    { token: "strong", fontStyle: "bold" },
    { token: "variable", foreground: "1AEBFF" },
    { token: "variable.parameter", foreground: "9CDCFE" },
    { token: "constant", foreground: "569CD6" },
    { token: "comment", foreground: "608B4E" },
    { token: "number", foreground: "FFFFFF" },
    { token: "regexp", foreground: "C0C0C0" },
    { token: "annotation", foreground: "569CD6" },
    { token: "type", foreground: "3DC9B0" },
    { token: "delimiter", foreground: "FFFF00" },
    { token: "delimiter.html", foreground: "FFFF00" },
    { token: "tag", foreground: "569CD6" },
    { token: "tag.id.pug", foreground: "4F76AC" },
    { token: "tag.class.pug", foreground: "4F76AC" },
    { token: "meta", foreground: "D4D4D4" },
    { token: "meta.tag", foreground: "CE9178" },
    { token: "metatag", foreground: "569CD6" },
    { token: "metatag.content.html", foreground: "1AEBFF" },
    { token: "metatag.html", foreground: "569CD6" },
    { token: "metatag.xml", foreground: "569CD6" },
    { token: "metatag.php", fontStyle: "bold" },
    { token: "key", foreground: "9CDCFE" },
    { token: "string.key", foreground: "9CDCFE" },
    { token: "string.value", foreground: "CE9178" },
    { token: "attribute.name", foreground: "569CD6" },
    { token: "attribute.value", foreground: "3FF23F" },
    { token: "string", foreground: "CE9178" },
    { token: "string.sql", foreground: "FF0000" },
    { token: "keyword", foreground: "569CD6" },
    { token: "keyword.flow", foreground: "C586C0" },
    { token: "operator.sql", foreground: "778899" },
    { token: "operator.swift", foreground: "909090" },
    { token: "predefined.sql", foreground: "FF00FF" }
  ],
  colors: {
    [R]: "#000000",
    [ve]: "#FFFFFF",
    [Fe]: "#FFFFFF",
    [Be]: "#FFFFFF"
  }
}, io = {
  base: "hc-light",
  inherit: !1,
  rules: [
    { token: "", foreground: "292929", background: "FFFFFF" },
    { token: "invalid", foreground: "B5200D" },
    { token: "emphasis", fontStyle: "italic" },
    { token: "strong", fontStyle: "bold" },
    { token: "variable", foreground: "264F70" },
    { token: "variable.predefined", foreground: "4864AA" },
    { token: "constant", foreground: "dd0000" },
    { token: "comment", foreground: "008000" },
    { token: "number", foreground: "098658" },
    { token: "number.hex", foreground: "3030c0" },
    { token: "regexp", foreground: "800000" },
    { token: "annotation", foreground: "808080" },
    { token: "type", foreground: "008080" },
    { token: "delimiter", foreground: "000000" },
    { token: "delimiter.html", foreground: "383838" },
    { token: "tag", foreground: "800000" },
    { token: "tag.id.pug", foreground: "4F76AC" },
    { token: "tag.class.pug", foreground: "4F76AC" },
    { token: "meta.scss", foreground: "800000" },
    { token: "metatag", foreground: "e00000" },
    { token: "metatag.content.html", foreground: "B5200D" },
    { token: "metatag.html", foreground: "808080" },
    { token: "metatag.xml", foreground: "808080" },
    { token: "metatag.php", fontStyle: "bold" },
    { token: "key", foreground: "863B00" },
    { token: "string.key.json", foreground: "A31515" },
    { token: "string.value.json", foreground: "0451A5" },
    { token: "attribute.name", foreground: "264F78" },
    { token: "attribute.value", foreground: "0451A5" },
    { token: "string", foreground: "A31515" },
    { token: "string.sql", foreground: "B5200D" },
    { token: "keyword", foreground: "0000FF" },
    { token: "keyword.flow", foreground: "AF00DB" },
    { token: "operator.sql", foreground: "778899" },
    { token: "operator.swift", foreground: "666666" },
    { token: "predefined.sql", foreground: "C700C7" }
  ],
  colors: {
    [R]: "#FFFFFF",
    [ve]: "#292929",
    [Fe]: "#292929",
    [Be]: "#292929"
  }
};
function ao(r, e) {
  if (r !== void 0) {
    const o = r.match(/^\s*var\((.+)\)$/);
    if (o) {
      const a = o[1].split(",", 2);
      return a.length === 2 && (e = ao(a[1].trim(), e)), `var(${a[0]}, ${e})`;
    }
    return r;
  }
  return e;
}
function pt(r) {
  const e = r.replaceAll(/[^_\-a-z0-9]/gi, "");
  return e !== r && console.warn(`CSS ident value ${r} modified to ${e} to be safe for CSS`), e;
}
function $(r) {
  return `'${r.replaceAll(/'/g, "\\000027")}'`;
}
function so(r) {
  return r ? A`url('${CSS.escape(er.uriToBrowserUri(r).toString(!0))}')` : "url('')";
}
function be(r, e = !1) {
  const o = CSS.escape(r);
  return !e && o !== r && console.warn(`CSS class name ${r} modified to ${o} to be safe for CSS`), o;
}
function A(r, ...e) {
  return r.reduce((o, a, s) => {
    const l = e[s] || "";
    return o + a + l;
  }, "");
}
class Le {
  constructor() {
    this._parts = [];
  }
  push(...e) {
    this._parts.push(...e);
  }
  join(e = `
`) {
    return this._parts.join(e);
  }
}
var _e;
(function(r) {
  function e(o) {
    return !!o && typeof o == "object" && typeof o.id == "string";
  }
  r.isThemeColor = e;
})(_e || (_e = {}));
var M;
(function(r) {
  r.iconNameSegment = "[A-Za-z0-9]+", r.iconNameExpression = "[A-Za-z0-9-]+", r.iconModifierExpression = "~[A-Za-z]+", r.iconNameCharacter = "[A-Za-z0-9~-]";
  const e = new RegExp(`^(${r.iconNameExpression})(${r.iconModifierExpression})?$`);
  function o(w) {
    const h = e.exec(w.id);
    if (!h)
      return o(f.error);
    const [, v, L] = h, S = ["codicon", "codicon-" + v];
    return L && S.push("codicon-modifier-" + L.substring(1)), S;
  }
  r.asClassNameArray = o;
  function a(w) {
    return o(w).join(" ");
  }
  r.asClassName = a;
  function s(w) {
    return "." + o(w).join(".");
  }
  r.asCSSSelector = s;
  function l(w) {
    return !!w && typeof w == "object" && typeof w.id == "string" && (typeof w.color > "u" || _e.isThemeColor(w.color));
  }
  r.isThemeIcon = l;
  const u = new RegExp(`^\\$\\((${r.iconNameExpression}(?:${r.iconModifierExpression})?)\\)$`);
  function g(w) {
    const h = u.exec(w);
    if (!h)
      return;
    const [, v] = h;
    return { id: v };
  }
  r.fromString = g;
  function b(w) {
    return { id: w };
  }
  r.fromId = b;
  function k(w, h) {
    let v = w.id;
    const L = v.lastIndexOf("~");
    return L !== -1 && (v = v.substring(0, L)), h && (v = `${v}~${h}`), { id: v };
  }
  r.modify = k;
  function m(w) {
    const h = w.id.lastIndexOf("~");
    if (h !== -1)
      return w.id.substring(h + 1);
  }
  r.getModifier = m;
  function F(w, h) {
    return w.id === h.id && w.color?.id === h.color?.id;
  }
  r.isEqual = F;
  function D(w) {
    return w?.id === f.file.id;
  }
  r.isFile = D;
  function K(w) {
    return w?.id === f.folder.id;
  }
  r.isFolder = K;
})(M || (M = {}));
const co = {
  IconContribution: "base.contributions.icons"
};
var wt;
(function(r) {
  function e(o, a) {
    let s = o.defaults;
    for (; M.isThemeIcon(s); ) {
      const l = ee.getIcon(s.id);
      if (!l)
        return;
      s = l.defaults;
    }
    return s;
  }
  r.getDefinition = e;
})(wt || (wt = {}));
var xt;
(function(r) {
  function e(a) {
    return {
      weight: a.weight,
      style: a.style,
      src: a.src.map((s) => ({ format: s.format, location: s.location.toString() }))
    };
  }
  r.toJSONObject = e;
  function o(a) {
    const s = (l) => de(l) ? l : void 0;
    if (a && Array.isArray(a.src) && a.src.every((l) => de(l.format) && de(l.location)))
      return {
        weight: s(a.weight),
        style: s(a.style),
        src: a.src.map((l) => ({ format: l.format, location: vt.parse(l.location) }))
      };
  }
  r.fromJSONObject = o;
})(xt || (xt = {}));
const lo = /^([\w_-]+)$/, uo = n(2024, "The font ID must only contain letters, numbers, underscores and dashes.");
class ho extends V {
  constructor() {
    super(), this._onDidChange = this._register(new j()), this.onDidChange = this._onDidChange.event, this.iconSchema = {
      definitions: {
        icons: {
          type: "object",
          properties: {
            fontId: { type: "string", description: n(2025, "The id of the font to use. If not set, the font that is defined first is used."), pattern: lo.source, patternErrorMessage: uo },
            fontCharacter: { type: "string", description: n(2026, "The font character associated with the icon definition.") }
          },
          additionalProperties: !1,
          defaultSnippets: [{ body: { fontCharacter: "\\\\e030" } }]
        }
      },
      type: "object",
      properties: {}
    }, this.iconReferenceSchema = { type: "string", pattern: `^${M.iconNameExpression}$`, enum: [], enumDescriptions: [] }, this.iconsById = {}, this.iconFontsById = {};
  }
  registerIcon(e, o, a, s) {
    const l = this.iconsById[e];
    if (l) {
      if (a && !l.description) {
        l.description = a, this.iconSchema.properties[e].markdownDescription = `${a} $(${e})`;
        const b = this.iconReferenceSchema.enum.indexOf(e);
        b !== -1 && (this.iconReferenceSchema.enumDescriptions[b] = a), this._onDidChange.fire();
      }
      return l;
    }
    const u = { id: e, description: a, defaults: o, deprecationMessage: s };
    this.iconsById[e] = u;
    const g = { $ref: "#/definitions/icons" };
    return s && (g.deprecationMessage = s), a && (g.markdownDescription = `${a}: $(${e})`), this.iconSchema.properties[e] = g, this.iconReferenceSchema.enum.push(e), this.iconReferenceSchema.enumDescriptions.push(a || ""), this._onDidChange.fire(), { id: e };
  }
  getIcons() {
    return Object.keys(this.iconsById).map((e) => this.iconsById[e]);
  }
  getIcon(e) {
    return this.iconsById[e];
  }
  getIconSchema() {
    return this.iconSchema;
  }
  toString() {
    const e = (l, u) => l.id.localeCompare(u.id), o = (l) => {
      for (; M.isThemeIcon(l.defaults); )
        l = this.iconsById[l.defaults.id];
      return `codicon codicon-${l ? l.id : ""}`;
    }, a = [];
    a.push("| preview     | identifier                        | default codicon ID                | description"), a.push("| ----------- | --------------------------------- | --------------------------------- | --------------------------------- |");
    const s = Object.keys(this.iconsById).map((l) => this.iconsById[l]);
    for (const l of s.filter((u) => !!u.description).sort(e))
      a.push(`|<i class="${o(l)}"></i>|${l.id}|${M.isThemeIcon(l.defaults) ? l.defaults.id : l.id}|${l.description || ""}|`);
    a.push("| preview     | identifier                        "), a.push("| ----------- | --------------------------------- |");
    for (const l of s.filter((u) => !M.isThemeIcon(u.defaults)).sort(e))
      a.push(`|<i class="${o(l)}"></i>|${l.id}|`);
    return a.join(`
`);
  }
}
const ee = new ho();
J.add(co.IconContribution, ee);
function ze(r, e, o, a) {
  return ee.registerIcon(r, e, o, a);
}
function Wt() {
  return ee;
}
function go() {
  const r = nr();
  for (const e in r) {
    const o = "\\" + r[e].toString(16);
    ee.registerIcon(e, { fontCharacter: o });
  }
}
go();
const Ut = "vscode://schemas/icons", jt = J.as(Me.JSONContribution);
jt.registerSchema(Ut, ee.getIconSchema());
const yt = new Ft(() => jt.notifySchemaChanged(Ut), 200);
ee.onDidChange(() => {
  yt.isScheduled() || yt.schedule();
});
const Ca = ze("widget-close", f.close, n(2027, "Icon for the close action in widgets."));
ze("goto-previous-location", f.arrowUp, n(2028, "Icon for goto previous editor location."));
ze("goto-next-location", f.arrowDown, n(2029, "Icon for goto next editor location."));
M.modify(f.sync, "spin");
M.modify(f.loading, "spin");
function fo(r) {
  const e = new tr(), o = e.add(new j()), a = Wt();
  return e.add(a.onDidChange(() => o.fire())), r && e.add(r.onDidProductIconThemeChange(() => o.fire())), {
    dispose: () => e.dispose(),
    onDidChange: o.event,
    getCSS() {
      const s = r ? r.getProductIconTheme() : new Vt(), l = {}, u = new Le(), g = new Le();
      for (const b of a.getIcons()) {
        const k = s.getIcon(b);
        if (!k)
          continue;
        const m = k.font, F = A`--vscode-icon-${be(b.id)}-font-family`, D = A`--vscode-icon-${be(b.id)}-content`;
        m ? (l[m.id] = m.definition, g.push(A`${F}: ${$(m.id)};`, A`${D}: ${$(k.fontCharacter)};`), u.push(A`.codicon-${be(b.id)}:before { content: ${$(k.fontCharacter)}; font-family: ${$(m.id)}; }`)) : (g.push(A`${D}: ${$(k.fontCharacter)}; ${F}: 'codicon';`), u.push(A`.codicon-${be(b.id)}:before { content: ${$(k.fontCharacter)}; }`));
      }
      for (const b in l) {
        const k = l[b], m = k.weight ? A`font-weight: ${pt(k.weight)};` : A``, F = k.style ? A`font-style: ${pt(k.style)};` : A``, D = new Le();
        for (const K of k.src)
          D.push(A`${so(K.location)} format(${$(K.format)})`);
        u.push(A`@font-face { src: ${D.join(", ")}; font-family: ${$(b)};${m}${F} font-display: block; }`);
      }
      return u.push(A`:root { ${g.join(" ")} }`), u.join(`
`);
    }
  };
}
class Vt {
  getIcon(e) {
    const o = Wt();
    let a = e.defaults;
    for (; M.isThemeIcon(a); ) {
      const s = o.getIcon(a.id);
      if (!s)
        return;
      a = s.defaults;
    }
    return a;
  }
}
const q = "vs", ae = "vs-dark", Q = "hc-black", Z = "hc-light", Jt = J.as(Dt.ColorContribution), bo = J.as(qt.ThemingContribution);
class Kt {
  constructor(e, o) {
    this.semanticHighlighting = !1, this.themeData = o;
    const a = o.base;
    e.length > 0 ? (ke(e) ? this.id = e : this.id = a + " " + e, this.themeName = e) : (this.id = a, this.themeName = a), this.colors = null, this.defaultColors = /* @__PURE__ */ Object.create(null), this._tokenTheme = null;
  }
  get base() {
    return this.themeData.base;
  }
  notifyBaseUpdated() {
    this.themeData.inherit && (this.colors = null, this._tokenTheme = null);
  }
  getColors() {
    if (!this.colors) {
      const e = /* @__PURE__ */ new Map();
      for (const o in this.themeData.colors)
        e.set(o, d.fromHex(this.themeData.colors[o]));
      if (this.themeData.inherit) {
        const o = Ne(this.themeData.base);
        for (const a in o.colors)
          e.has(a) || e.set(a, d.fromHex(o.colors[a]));
      }
      this.colors = e;
    }
    return this.colors;
  }
  getColor(e, o) {
    const a = this.getColors().get(e);
    if (a)
      return a;
    if (o !== !1)
      return this.getDefault(e);
  }
  getDefault(e) {
    let o = this.defaultColors[e];
    return o || (o = Jt.resolveDefaultColor(e, this), this.defaultColors[e] = o, o);
  }
  defines(e) {
    return this.getColors().has(e);
  }
  get type() {
    switch (this.base) {
      case q:
        return E.LIGHT;
      case Q:
        return E.HIGH_CONTRAST_DARK;
      case Z:
        return E.HIGH_CONTRAST_LIGHT;
      default:
        return E.DARK;
    }
  }
  get tokenTheme() {
    if (!this._tokenTheme) {
      let e = [], o = [];
      if (this.themeData.inherit) {
        const l = Ne(this.themeData.base);
        e = l.rules, l.encodedTokensColors && (o = l.encodedTokensColors);
      }
      const a = this.themeData.colors["editor.foreground"], s = this.themeData.colors["editor.background"];
      if (a || s) {
        const l = { token: "" };
        a && (l.foreground = a), s && (l.background = s), e.push(l);
      }
      e = e.concat(this.themeData.rules), this.themeData.encodedTokensColors && (o = this.themeData.encodedTokensColors), this._tokenTheme = Ct.createFromRawTokenTheme(e, o);
    }
    return this._tokenTheme;
  }
  getTokenStyleMetadata(e, o, a) {
    const l = this.tokenTheme._match([e].concat(o).join(".")).metadata, u = it.getForeground(l), g = it.getFontStyle(l);
    return {
      foreground: u,
      italic: !!(g & 1),
      bold: !!(g & 2),
      underline: !!(g & 4),
      strikethrough: !!(g & 8)
    };
  }
  get tokenColorMap() {
    return [];
  }
}
function ke(r) {
  return r === q || r === ae || r === Q || r === Z;
}
function Ne(r) {
  switch (r) {
    case q:
      return ro;
    case ae:
      return oo;
    case Q:
      return no;
    case Z:
      return io;
  }
}
function me(r) {
  const e = Ne(r);
  return new Kt(r, e);
}
let Qt = null;
function mo(r, e) {
  Qt?.setHostTheme(r, e);
}
class ko extends V {
  constructor() {
    super(), Qt = this, this._themeByHost = /* @__PURE__ */ new WeakMap(), this._currentRenderHost = null, this._onColorThemeChange = this._register(new j()), this.onDidColorThemeChange = this._onColorThemeChange.event, this._onProductIconThemeChange = this._register(new j()), this.onDidProductIconThemeChange = this._onProductIconThemeChange.event, this._environment = /* @__PURE__ */ Object.create(null), this._builtInProductIconTheme = new Vt(), this._autoDetectHighContrast = !0, this._knownThemes = /* @__PURE__ */ new Map(), this._knownThemes.set(q, me(q)), this._knownThemes.set(ae, me(ae)), this._knownThemes.set(Q, me(Q)), this._knownThemes.set(Z, me(Z));
    const e = this._register(fo(this));
    this._codiconCSS = e.getCSS(), this._themeCSS = "", this._allCSS = `${this._codiconCSS}
${this._themeCSS}`, this._globalStyleElement = null, this._styleElements = [], this._colorMapOverride = null, this.setTheme(q), this._onOSSchemeChanged(), this._register(e.onDidChange(() => {
      this._codiconCSS = e.getCSS(), this._updateCSS();
    })), rr(Ue, "(forced-colors: active)", () => {
      this._onOSSchemeChanged();
    });
  }
  registerEditorContainer(e) {
    return or(e) ? this._registerShadowDomContainer(e) : this._registerRegularEditorContainer();
  }
  _registerRegularEditorContainer() {
    return this._globalStyleElement || (this._globalStyleElement = We(void 0, (e) => {
      e.className = "monaco-colors", e.textContent = this._allCSS;
    }), this._styleElements.push({ element: this._globalStyleElement, host: null })), V.None;
  }
  _registerShadowDomContainer(e) {
    const o = e.getRootNode(), a = o && o instanceof ShadowRoot ? o.host : null, s = We(e, (l) => {
      l.className = "monaco-colors", this._currentRenderHost = a;
      try {
        l.textContent = this._buildAllCss();
      } finally {
        this._currentRenderHost = null;
      }
    });
    return this._styleElements.push({ element: s, host: a }), {
      dispose: () => {
        for (let l = 0; l < this._styleElements.length; l++) {
          const u = this._styleElements[l];
          if ((u && u.element ? u.element : u) === s) {
            this._styleElements.splice(l, 1);
            return;
          }
        }
      }
    };
  }
  defineTheme(e, o) {
    if (!/^[a-z0-9\-]+$/i.test(e))
      throw new Error("Illegal theme name!");
    if (!ke(o.base) && !ke(e))
      throw new Error("Illegal theme base!");
    this._knownThemes.set(e, new Kt(e, o)), ke(e) && this._knownThemes.forEach((a) => {
      a.base === e && a.notifyBaseUpdated();
    }), this._globalTheme && this._globalTheme.themeName === e && this.setTheme(e);
  }
  getColorTheme() {
    return this._globalTheme;
  }
  setColorMapOverride(e) {
    this._colorMapOverride = e, this._updateThemeOrColorMap();
  }
  setTheme(e) {
    let o;
    this._knownThemes.has(e) ? o = this._knownThemes.get(e) : o = this._knownThemes.get(q), this._updateActualTheme(o);
  }
  _updateActualTheme(e) {
    !e || this._globalTheme === e || (this._globalTheme = e, this._updateThemeOrColorMap());
  }
  _onOSSchemeChanged() {
    if (this._autoDetectHighContrast) {
      const e = Ue.matchMedia("(forced-colors: active)").matches;
      if (e !== Vr(this._globalTheme.type)) {
        let o;
        Jr(this._globalTheme.type) ? o = e ? Q : ae : o = e ? Z : q, this._updateActualTheme(this._knownThemes.get(o));
      }
    }
  }
  setAutoDetectHighContrast(e) {
    this._autoDetectHighContrast = e, this._onOSSchemeChanged();
  }
  _updateThemeOrColorMap() {
    this._updateCSS();
    const e = this._colorMapOverride || this._globalTheme.tokenTheme.getColorMap();
    dr.setColorMap(e), this._onColorThemeChange.fire(this._globalTheme);
  }
  /**
   * wippy-monaco multi-theme patch — resolve the effective theme for a host.
   * Returns the per-host override from `_themeByHost` if present, else falls
   * back to the global theme (the one set via `monaco.editor.setTheme`).
   */
  _resolveThemeForHost(e) {
    return e && this._themeByHost.has(e) ? this._themeByHost.get(e) : this._globalTheme;
  }
  /**
   * wippy-monaco multi-theme patch — build the full editor CSS string for
   * the currently-bound `_currentRenderHost`'s theme. The theming-registry
   * participants and color variables read `_theme`, which the constructor's
   * getter resolves via `_currentRenderHost`. Caller is responsible for
   * setting/clearing `_currentRenderHost` around the call.
   */
  _buildAllCss() {
    const e = this._resolveThemeForHost(this._currentRenderHost), o = [], a = {}, s = {
      addRule: (g) => {
        a[g] || (o.push(g), a[g] = !0);
      }
    };
    bo.getThemingParticipants().forEach((g) => g(e, s, this._environment));
    const l = [];
    for (const g of Jt.getColors()) {
      const b = e.getColor(g.id, !0);
      b && l.push(`${Oe(g.id)}: ${b.toString()};`);
    }
    s.addRule(`.monaco-editor, .monaco-diff-editor, .monaco-component { ${l.join(`
`)} }`);
    const u = this._colorMapOverride || e.tokenTheme.getColorMap();
    return s.addRule(wr(u)), s.addRule(".monaco-editor, .monaco-diff-editor, .monaco-component { forced-color-adjust: none; }"), `${this._codiconCSS}
${o.join(`
`)}`;
  }
  /**
   * wippy-monaco multi-theme patch — write a single host's theme override.
   * `host` is the shadow-DOM host element; `themeName` must be a theme
   * registered via `defineTheme` (or null to clear the override and fall
   * back to the global theme). Only the style element belonging to that
   * host is rewritten — other editors are untouched.
   */
  setHostTheme(e, o) {
    if (e) {
      if (o) {
        const a = this._knownThemes.get(o);
        a && this._themeByHost.set(e, a);
      } else
        this._themeByHost.delete(e);
      for (const a of this._styleElements)
        if (a && a.host === e) {
          this._currentRenderHost = e;
          try {
            a.element.textContent = this._buildAllCss();
          } finally {
            this._currentRenderHost = null;
          }
        }
    }
  }
  _updateCSS() {
    for (const e of this._styleElements) {
      const o = e && e.element !== void 0, a = o ? e.element : e, s = o ? e.host : null;
      this._currentRenderHost = s;
      try {
        a.textContent = this._buildAllCss();
      } finally {
        this._currentRenderHost = null;
      }
    }
    this._currentRenderHost = null, this._allCSS = this._buildAllCss();
  }
  getFileIconTheme() {
    return {
      hasFileIcons: !1,
      hasFolderIcons: !1,
      hidesExplorerArrows: !1
    };
  }
  getProductIconTheme() {
    return this._builtInProductIconTheme;
  }
}
const Da = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  HC_BLACK_THEME_NAME: Q,
  HC_LIGHT_THEME_NAME: Z,
  StandaloneThemeService: ko,
  VS_DARK_THEME_NAME: ae,
  VS_LIGHT_THEME_NAME: q,
  setHostTheme: mo
}, Symbol.toStringTag, { value: "Module" }));
export {
  Xi as $,
  ua as A,
  Be as B,
  f as C,
  Fe as D,
  Me as E,
  Ui as F,
  Pi as G,
  ji as H,
  Ai as I,
  Gi as J,
  Vi as K,
  $i as L,
  Ji as M,
  zi as N,
  Ki as O,
  O as P,
  Wi as Q,
  J as R,
  qi as S,
  M as T,
  Qi as U,
  dr as V,
  gn as W,
  fn as X,
  ve as Y,
  ln as Z,
  d as _,
  B as a,
  Pr as a$,
  Gt as a0,
  Hi as a1,
  Mi as a2,
  Yi as a3,
  Ro as a4,
  $t as a5,
  Ri as a6,
  Oi as a7,
  zt as a8,
  Ti as a9,
  Li as aA,
  Si as aB,
  G as aC,
  $r as aD,
  Bi as aE,
  Ht as aF,
  Ln as aG,
  Ge as aH,
  hi as aI,
  ui as aJ,
  Ar as aK,
  di as aL,
  Ur as aM,
  ni as aN,
  oi as aO,
  ei as aP,
  Yn as aQ,
  Zn as aR,
  Xn as aS,
  Qn as aT,
  $e as aU,
  ue as aV,
  Kn as aW,
  Wr as aX,
  Jn as aY,
  Vn as aZ,
  jn as a_,
  Zi as aa,
  ha as ab,
  vo as ac,
  yo as ad,
  xo as ae,
  Jr as af,
  At as ag,
  X as ah,
  se as ai,
  No as aj,
  ea as ak,
  ao as al,
  ze as am,
  i as an,
  Ko as ao,
  dt as ap,
  jo as aq,
  Qo as ar,
  ut as as,
  Vo as at,
  So as au,
  C as av,
  _r as aw,
  ri as ax,
  ti as ay,
  Di as az,
  it as b,
  N as b$,
  Gr as b0,
  Or as b1,
  Cn as b2,
  Bn as b3,
  Dn as b4,
  vn as b5,
  yn as b6,
  Fn as b7,
  wn as b8,
  pn as b9,
  Gn as bA,
  Pn as bB,
  Mt as bC,
  qn as bD,
  Rt as bE,
  Eo as bF,
  Tn as bG,
  En as bH,
  mt as bI,
  In as bJ,
  An as bK,
  he as bL,
  Sn as bM,
  zr as bN,
  On as bO,
  Mn as bP,
  Rn as bQ,
  Hn as bR,
  Nn as bS,
  _n as bT,
  ge as bU,
  To as bV,
  sn as bW,
  an as bX,
  nn as bY,
  Zo as bZ,
  qe as b_,
  xn as ba,
  kn as bb,
  mn as bc,
  bn as bd,
  li as be,
  ci as bf,
  si as bg,
  ai as bh,
  x as bi,
  Io as bj,
  De as bk,
  Rr as bl,
  Un as bm,
  Wn as bn,
  zn as bo,
  $n as bp,
  Er as bq,
  Ir as br,
  Tr as bs,
  xi as bt,
  wi as bu,
  pi as bv,
  ki as bw,
  mi as bx,
  bi as by,
  fi as bz,
  Ot as c,
  Co as c$,
  tn as c0,
  en as c1,
  Xo as c2,
  Yo as c3,
  so as c4,
  et as c5,
  Ii as c6,
  Ze as c7,
  Bt as c8,
  y as c9,
  xe as cA,
  p as cB,
  R as cC,
  ra as cD,
  oe as cE,
  Ae as cF,
  z as cG,
  Qe as cH,
  Ve as cI,
  fe as cJ,
  ii as cK,
  Fo as cL,
  Jo as cM,
  Y as cN,
  Ao as cO,
  gi as cP,
  Go as cQ,
  Ke as cR,
  Po as cS,
  on as cT,
  cn as cU,
  It as cV,
  Ye as cW,
  Xe as cX,
  ta as cY,
  rt as cZ,
  tt as c_,
  W as ca,
  ne as cb,
  c as cc,
  Je as cd,
  Mr as ce,
  rn as cf,
  Ca as cg,
  qo as ch,
  Mo as ci,
  Oo as cj,
  je as ck,
  re as cl,
  lt as cm,
  Bo as cn,
  ot as co,
  Ho as cp,
  nt as cq,
  Uo as cr,
  Wo as cs,
  zo as ct,
  $o as cu,
  _t as cv,
  Et as cw,
  at as cx,
  _o as cy,
  we as cz,
  Lo as d,
  ae as d0,
  q as d1,
  Q as d2,
  Z as d3,
  _ as d4,
  nr as d5,
  oa as d6,
  hn as d7,
  na as d8,
  un as d9,
  ia as da,
  dn as db,
  _i as dc,
  Ci as dd,
  Fi as de,
  vi as df,
  yi as dg,
  P as dh,
  ko as di,
  Do as dj,
  Da as dk,
  Zr as e,
  Ni as f,
  Ei as g,
  wa as h,
  Vr as i,
  ga as j,
  aa as k,
  xa as l,
  fa as m,
  sa as n,
  ya as o,
  ba as p,
  ca as q,
  Qr as r,
  va as s,
  ma as t,
  la as u,
  Fa as v,
  ka as w,
  da as x,
  Ba as y,
  pa as z
};
//# sourceMappingURL=standaloneThemeService-DlKGT-Pu.js.map
