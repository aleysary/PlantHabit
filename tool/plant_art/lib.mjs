// Shared drawing primitives for the Verdant plant art generator.
// Everything is emitted as plain SVG that flutter_svg can render:
// paths, ellipses, circles, linear/radial gradients, transforms, evenodd fills.
// No filters, masks or CSS.

export const W = 240;
export const H = 300;
export const CX = 120;
export const SOIL_Y = 240; // where stems meet the soil

export const f = (n) => +(+n).toFixed(2);
export const rad = (d) => (d * Math.PI) / 180;
export const deg = (r) => (r * 180) / Math.PI;
export const lerp = (a, b, t) => a + (b - a) * t;
export const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

export function rng(seed) {
  let s = seed >>> 0 || 1;
  const next = () => {
    s ^= s << 13; s >>>= 0;
    s ^= s >> 17;
    s ^= s << 5; s >>>= 0;
    return s / 4294967296;
  };
  next.range = (a, b) => a + (b - a) * next();
  next.pick = (arr) => arr[Math.floor(next() * arr.length)];
  return next;
}

export class Doc {
  constructor() {
    this.defs = [];
    this.els = [];
    this.n = 0;
  }
  uid(p = 'g') { return `${p}${this.n++}`; }
  add(s) { this.els.push(s); return this; }
  stops(stops) {
    return stops
      .map(([o, c, a]) => `<stop offset="${o}" stop-color="${c}"${a != null ? ` stop-opacity="${a}"` : ''}/>`)
      .join('');
  }
  /** Linear gradient. Defaults to objectBoundingBox top→bottom. */
  lin(stops, { x1 = 0, y1 = 0, x2 = 0, y2 = 1, user = false } = {}) {
    const id = this.uid('l');
    this.defs.push(
      `<linearGradient id="${id}" x1="${f(x1)}" y1="${f(y1)}" x2="${f(x2)}" y2="${f(y2)}"${user ? ' gradientUnits="userSpaceOnUse"' : ''}>${this.stops(stops)}</linearGradient>`,
    );
    return `url(#${id})`;
  }
  radial(stops, { cx = 0.5, cy = 0.5, r = 0.5, fx, fy, user = false } = {}) {
    const id = this.uid('r');
    this.defs.push(
      `<radialGradient id="${id}" cx="${f(cx)}" cy="${f(cy)}" r="${f(r)}"${fx != null ? ` fx="${f(fx)}" fy="${f(fy)}"` : ''}${user ? ' gradientUnits="userSpaceOnUse"' : ''}>${this.stops(stops)}</radialGradient>`,
    );
    return `url(#${id})`;
  }
  toString() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}"><defs>${this.defs.join('')}</defs>${this.els.join('')}</svg>`;
  }
}

// ---------------------------------------------------------------------------
// Leaf shapes. Each returns the UPPER half as cubic segments from base (0,0)
// to tip (100,0). Lower half is mirrored automatically.
export const SHAPES = {
  lance: (w) => [[18, -w * 1.15, 62, -w * 1.0, 100, 0]],
  narrow: (w) => [[25, -w * 1.25, 70, -w * 0.7, 100, 0]],
  ovate: (w) => [[4, -w * 1.3, 58, -w * 1.25, 100, 0]],
  elliptic: (w) => [[6, -w * 1.32, 84, -w * 1.32, 100, 0]],
  heart: (w) => [
    [-16, -w * 0.7, 8, -w * 1.38, 46, -w * 1.08],
    [74, -w * 0.82, 93, -w * 0.32, 100, 0],
  ],
  sword: (w) => [
    [0, -w * 0.4, 0, -w * 0.8, 0, -w],
    [42, -w * 1.1, 80, -w * 0.62, 100, 0],
  ],
  spear: (w) => [
    [0, -w * 0.5, 0, -w, 2, -w],
    [40, -w * 0.98, 78, -w * 0.45, 100, 0],
  ],
  fiddle: (w) => [
    [10, -w * 0.32, 24, -w * 0.52, 40, -w * 0.62],
    [56, -w * 0.72, 60, -w * 1.08, 80, -w * 1.02],
    [96, -w * 0.96, 101, -w * 0.4, 100, 0],
  ],
  paddle: (w) => [
    [3, -w * 0.9, 14, -w * 1.04, 40, -w * 1.05],
    [74, -w * 1.06, 95, -w * 0.72, 100, 0],
  ],
  petal: (w) => [
    [14, -w * 0.9, 62, -w * 1.32, 92, -w * 0.62],
    [100, -w * 0.25, 100, -w * 0.04, 100, 0],
  ],
  fleshy: (w) => [
    [0, -w * 0.7, 36, -w * 1.25, 76, -w * 0.86],
    [90, -w * 0.52, 97, -w * 0.2, 100, 0],
  ],
  round: (w) => [
    [0, -w * 1.15, 72, -w * 1.5, 100, 0],
  ],
};

function pathFromUpper(segs, half = 'both') {
  let d = 'M0,0';
  const starts = [[0, 0]];
  for (const s of segs) {
    d += ` C${f(s[0])},${f(s[1])} ${f(s[2])},${f(s[3])} ${f(s[4])},${f(s[5])}`;
    starts.push([s[4], s[5]]);
  }
  if (half === 'upper') return d + ' Z';
  if (half === 'lower') {
    // start at base, go along midrib to tip, then follow lower edge back
    d = 'M0,0 L100,0';
  }
  for (let i = segs.length - 1; i >= 0; i--) {
    const s = segs[i];
    const st = starts[i];
    d += ` C${f(s[2])},${f(-s[3])} ${f(s[0])},${f(-s[1])} ${f(st[0])},${f(-st[1])}`;
  }
  return d + ' Z';
}

export function leafPath(shape, w) {
  return pathFromUpper(SHAPES[shape](w));
}

/** Approximate half-width of a leaf at normalized x (0..100). */
export function widthAt(shape, w, x) {
  // sample the upper curve
  const segs = SHAPES[shape](w);
  let best = 0;
  let prev = [0, 0];
  for (const s of segs) {
    for (let i = 0; i <= 20; i++) {
      const t = i / 20;
      const mt = 1 - t;
      const px = mt ** 3 * prev[0] + 3 * mt * mt * t * s[0] + 3 * mt * t * t * s[2] + t ** 3 * s[4];
      const py = mt ** 3 * prev[1] + 3 * mt * mt * t * s[1] + 3 * mt * t * t * s[3] + t ** 3 * s[5];
      if (Math.abs(px - x) < 3) best = Math.max(best, -py);
    }
    prev = [s[4], s[5]];
  }
  return best;
}

/** Rotated ellipse as a closed subpath (for evenodd holes). */
export function ellipseSub(cx, cy, rx, ry, rot) {
  const c = Math.cos(rad(rot));
  const s = Math.sin(rad(rot));
  const p1 = [cx + rx * c, cy + rx * s];
  const p2 = [cx - rx * c, cy - rx * s];
  return ` M${f(p1[0])},${f(p1[1])} A${f(rx)},${f(ry)} ${f(rot)} 1 0 ${f(p2[0])},${f(p2[1])} A${f(rx)},${f(ry)} ${f(rot)} 1 0 ${f(p1[0])},${f(p1[1])} Z`;
}

/**
 * Draw a leaf.
 * o: {x,y,ang,len,w,shape,fill,shade,shadeOp,rib,ribOp,ribW,veins,veinOp,veinColor,
 *     holes:[[x,y,rx,ry,rot]], edge, edgeW, gloss, flip, extra(fn(s,w) -> svg in leaf space)}
 */
export function leaf(o) {
  const {
    x, y, ang, len,
    w = 30, shape = 'lance', fill,
    shade = '#0b2a1a', shadeOp = 0.2,
    rib = '#ffffff', ribOp = 0.28, ribW = 1.1,
    veins = 0, veinOp = 0.16, veinColor,
    holes = null, edge = null, edgeW = 1, edgeOp = 1,
    gloss = 0, extra = null, opacity = 1,
  } = o;
  const s = len / 100;
  const flip = o.flip ?? Math.cos(rad(ang)) < -0.05;
  const sw = (px) => f(px / s);
  let holesUp = '';
  let holesLow = '';
  let holesAll = '';
  if (holes) {
    for (const h of holes) {
      const sub = ellipseSub(...h);
      holesAll += sub;
      if (h[1] > 0) holesLow += sub;
    }
  }
  let out = `<g transform="translate(${f(x)},${f(y)}) rotate(${f(ang)}) scale(${f(s)},${f(flip ? -s : s)})"${opacity < 1 ? ` opacity="${opacity}"` : ''}>`;
  out += `<path d="${leafPath(shape, w)}${holesAll}" fill="${fill}" fill-rule="evenodd"/>`;
  if (shadeOp > 0) {
    out += `<path d="${pathFromUpper(SHAPES[shape](w), 'lower')}${holesLow}" fill="${shade}" fill-opacity="${shadeOp}" fill-rule="evenodd"/>`;
  }
  if (veins > 0) {
    const vc = veinColor || rib;
    let vd = '';
    for (let k = 1; k <= veins; k++) {
      const xv = 6 + (k * 84) / (veins + 1);
      const wv = widthAt(shape, w, xv + 12) * 0.82;
      vd += `M${f(xv)},0 Q${f(xv + 9)},${f(-wv * 0.45)} ${f(xv + 18)},${f(-wv * 0.9)} `;
      vd += `M${f(xv)},0 Q${f(xv + 9)},${f(wv * 0.45)} ${f(xv + 18)},${f(wv * 0.9)} `;
    }
    out += `<path d="${vd}" fill="none" stroke="${vc}" stroke-opacity="${veinOp}" stroke-width="${sw(0.8)}" stroke-linecap="round"/>`;
  }
  if (ribOp > 0) {
    out += `<path d="M1,0 Q50,${f(-w * 0.04)} 96,0" fill="none" stroke="${rib}" stroke-opacity="${ribOp}" stroke-width="${sw(ribW)}" stroke-linecap="round"/>`;
  }
  if (gloss > 0) {
    out += `<path d="M14,${f(-w * 0.45)} Q46,${f(-w * 0.95)} 80,${f(-w * 0.42)}" fill="none" stroke="#ffffff" stroke-opacity="${gloss}" stroke-width="${sw(1.6)}" stroke-linecap="round"/>`;
  }
  if (extra) out += extra(s, w, sw);
  if (edge) {
    out += `<path d="${leafPath(shape, w)}" fill="none" stroke="${edge}" stroke-opacity="${edgeOp}" stroke-width="${sw(edgeW)}"/>`;
  }
  out += '</g>';
  return out;
}

// ---------------------------------------------------------------------------
// Curves

export function quad(p0, p1, p2) {
  return {
    d: `M${f(p0[0])},${f(p0[1])} Q${f(p1[0])},${f(p1[1])} ${f(p2[0])},${f(p2[1])}`,
    at(u) {
      const mu = 1 - u;
      const x = mu * mu * p0[0] + 2 * mu * u * p1[0] + u * u * p2[0];
      const y = mu * mu * p0[1] + 2 * mu * u * p1[1] + u * u * p2[1];
      const dx = 2 * mu * (p1[0] - p0[0]) + 2 * u * (p2[0] - p1[0]);
      const dy = 2 * mu * (p1[1] - p0[1]) + 2 * u * (p2[1] - p1[1]);
      return { x, y, ang: deg(Math.atan2(dy, dx)) };
    },
  };
}

export function stem(curve, width, color, { hl = '#ffffff', hlOp = 0.22, op = 1 } = {}) {
  let s = `<path d="${curve.d}" fill="none" stroke="${color}" stroke-width="${f(width)}" stroke-linecap="round"${op < 1 ? ` stroke-opacity="${op}"` : ''}/>`;
  if (hlOp > 0 && width > 1.6) {
    s += `<path d="${curve.d}" fill="none" stroke="${hl}" stroke-opacity="${hlOp}" stroke-width="${f(width * 0.32)}" stroke-linecap="round" transform="translate(${f(-width * 0.18)},0)"/>`;
  }
  return s;
}

/** Tapered filled limb along a quadratic curve (for trunks and branches). */
export function limb(curve, w0, w1, fill, { n = 18 } = {}) {
  const L = [];
  const R = [];
  for (let i = 0; i <= n; i++) {
    const u = i / n;
    const p = curve.at(u);
    const w = lerp(w0, w1, u) / 2;
    const a = rad(p.ang + 90);
    L.push([p.x + Math.cos(a) * w, p.y + Math.sin(a) * w]);
    R.push([p.x - Math.cos(a) * w, p.y - Math.sin(a) * w]);
  }
  const end = curve.at(1);
  let d = `M${f(L[0][0])},${f(L[0][1])}`;
  for (let i = 1; i < L.length; i++) d += ` L${f(L[i][0])},${f(L[i][1])}`;
  // rounded cap
  d += ` Q${f(end.x + Math.cos(rad(end.ang)) * w1 * 0.6)},${f(end.y + Math.sin(rad(end.ang)) * w1 * 0.6)} ${f(R[R.length - 1][0])},${f(R[R.length - 1][1])}`;
  for (let i = R.length - 2; i >= 0; i--) d += ` L${f(R[i][0])},${f(R[i][1])}`;
  d += ' Z';
  return `<path d="${d}" fill="${fill}"/>`;
}

export function circle(cx, cy, r, fill, extra = '') {
  return `<circle cx="${f(cx)}" cy="${f(cy)}" r="${f(r)}" fill="${fill}"${extra}/>`;
}
export function ellipse(cx, cy, rx, ry, fill, extra = '') {
  return `<ellipse cx="${f(cx)}" cy="${f(cy)}" rx="${f(rx)}" ry="${f(ry)}" fill="${fill}"${extra}/>`;
}

/** Generic 5-petal blossom. */
export function blossom(doc, cx, cy, r, { petal, center = '#f6c34a', petals = 5, rot = 0, shape = 'petal', w = 46, dark = '#7a1d3a' } = {}) {
  let s = '';
  for (let i = 0; i < petals; i++) {
    const a = rot + (i * 360) / petals;
    s += leaf({ x: cx, y: cy, ang: a, len: r, w, shape, fill: petal, shade: dark, shadeOp: 0.12, ribOp: 0, flip: false });
  }
  s += circle(cx, cy, r * 0.22, center);
  return s;
}
