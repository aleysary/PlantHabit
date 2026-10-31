// Plant species for Verdant. Each species draws itself for a growth amount
// t (0..1) and a `bloom` flag (final stage). Seed and sprout stages are shared.
import {
  CX, SOIL_Y, f, rad, lerp, clamp, leaf, quad, stem, limb, circle, ellipse, widthAt, blossom,
} from './lib.mjs';

const B = [CX, SOIL_Y];
const dir = (a) => [Math.cos(rad(a)), Math.sin(rad(a))];
const leafFill = (doc, a, b, c) => doc.lin([[0, a], [0.55, b], [1, c]], { x1: 0.3, y1: 0, x2: 0.7, y2: 1 });
const along = (doc, stops) => doc.lin(stops, { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });

// ---------------------------------------------------------------------------
function monstera(doc, t, bloom, r) {
  const fill = leafFill(doc, '#6dbb78', '#2f7d47', '#13502b');
  const n = Math.round(2 + t * 5);
  const items = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = lerp(-118, -62, fr) + r.range(-4, 4);
    const plen = (50 + 72 * t) * r.range(0.82, 1.04) * (1 - 0.22 * Math.abs(fr - 0.5) * 2);
    const p0 = [CX + (fr - 0.5) * 10, SOIL_Y];
    const d = dir(ang);
    const p2 = [CX + d[0] * plen, SOIL_Y + d[1] * plen];
    const p1 = [p0[0] + (p2[0] - p0[0]) * 0.12, lerp(SOIL_Y, p2[1], 0.78)];
    const c = Math.cos(rad(ang));
    const lang = ang + Math.sign(c) * 46 * Math.abs(c) + r.range(-6, 6);
    const len = (30 + 42 * t) * r.range(0.88, 1.03);
    const holes = [];
    if (t > 0.5) {
      const m = t > 0.8 ? 4 : 2;
      for (let k = 0; k < m; k++) {
        const hx = 30 + k * (52 / m);
        const wa = widthAt('heart', 40, hx);
        holes.push([hx + 4, -wa * 0.58, 8 - k, 2.4, -32]);
        holes.push([hx + 4, wa * 0.58, 8 - k, 2.4, 32]);
      }
    }
    items.push({ fr, s: stem(quad(p0, p1, p2), 2.6 + t * 1.6, '#3f7a3c'), l: leaf({ x: p2[0], y: p2[1], ang: lang, len, w: 40, shape: 'heart', fill, veins: 6, veinOp: 0.22, gloss: 0.16, holes, shadeOp: 0.22 }) });
  }
  items.sort((a, b) => Math.abs(a.fr - 0.5) - Math.abs(b.fr - 0.5));
  for (const it of items) doc.add(it.s + it.l);
  if (bloom) {
    // a fresh, unfurling leaf
    const p2 = [CX + 6, SOIL_Y - 120];
    doc.add(stem(quad([CX, SOIL_Y], [CX + 2, SOIL_Y - 70], p2), 3, '#5c9a4a'));
    doc.add(leaf({ x: p2[0], y: p2[1], ang: -84, len: 34, w: 13, shape: 'narrow', fill: leafFill(doc, '#d8f2a6', '#a8d877', '#6fae4e'), ribOp: 0.4 }));
  }
}

// ---------------------------------------------------------------------------
function snake(doc, t, bloom, r) {
  const fill = doc.lin([[0, '#3d7247'], [0.5, '#2a5b36'], [1, '#173c22']], { x1: 0, y1: 0, x2: 0, y2: 1 });
  const n = 3 + Math.round(t * 6);
  const items = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = -90 + lerp(-20, 20, fr) + r.range(-5, 5);
    const len = (58 + 125 * t) * r.range(0.68, 1) * (1 - Math.abs(fr - 0.5) * 0.35);
    const x = CX + (fr - 0.5) * 34 + r.range(-3, 3);
    items.push({ len, svg: leaf({
      x, y: SOIL_Y + 2, ang, len, w: 10, shape: 'sword', fill, shadeOp: 0.14, ribOp: 0,
      edge: '#d6c766', edgeW: 1.9, flip: i % 2 === 0,
      extra: (s, w, sw) => {
        let d = '';
        for (let xb = 6; xb < 92; xb += 6.5) {
          const wa = widthAt('sword', 10, xb) * 0.86;
          d += `M${f(xb)},${f(-wa)} L${f(xb + 2.6)},${f(-wa * 0.45)} L${f(xb)},0 L${f(xb + 2.6)},${f(wa * 0.45)} L${f(xb)},${f(wa)} `;
        }
        return `<path d="${d}" fill="none" stroke="#a7d18c" stroke-opacity="0.42" stroke-width="${sw(1.5)}" stroke-linejoin="round"/>`;
      },
    }) });
  }
  items.sort((a, b) => b.len - a.len);
  for (const it of items) doc.add(it.svg);
  if (bloom) {
    const c = quad([CX + 12, SOIL_Y], [CX + 22, SOIL_Y - 60], [CX + 30, SOIL_Y - 110]);
    doc.add(stem(c, 2.2, '#8a9a5a'));
    for (let k = 0; k < 14; k++) {
      const p = c.at(0.45 + k * 0.04);
      doc.add(leaf({ x: p.x, y: p.y, ang: k % 2 ? -30 : -150, len: 9, w: 14, shape: 'narrow', fill: '#f6efd6', shadeOp: 0.1, ribOp: 0 }));
    }
  }
}

// ---------------------------------------------------------------------------
function fiddle(doc, t, bloom, r) {
  const H = 34 + 122 * t;
  const top = [CX + r.range(-6, 6), SOIL_Y - H];
  const trunk = quad([CX, SOIL_Y + 2], [CX - 8, SOIL_Y - H * 0.5], top);
  doc.add(limb(trunk, 4 + t * 6, 2.5, doc.lin([[0, '#9a7b5c'], [0.5, '#6f533b'], [1, '#4a3626']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 })));
  const fill = leafFill(doc, '#5fa457', '#2d6c36', '#143f20');
  const newFill = leafFill(doc, '#b6e07a', '#7ab84a', '#4c8a33');
  const n = 2 + Math.round(t * 6);
  for (let i = 0; i < n; i++) {
    const u = lerp(0.3, 1, n === 1 ? 1 : i / (n - 1));
    const p = trunk.at(u);
    const right = i % 2 === 0;
    let ang = right ? lerp(-2, -58, u) : lerp(-178, -122, u);
    if (i === n - 1) ang = -92;
    ang += r.range(-8, 8);
    const len = (30 + 44 * t) * (1.05 - u * 0.2) * r.range(0.9, 1.08);
    const isNew = bloom && i >= n - 2;
    doc.add(leaf({ x: p.x, y: p.y, ang, len, w: 36, shape: 'fiddle', fill: isNew ? newFill : fill, veins: 5, veinColor: '#d9ecb0', veinOp: 0.32, gloss: 0.22, shadeOp: 0.24 }));
  }
}

// ---------------------------------------------------------------------------
function echeveria(doc, t, bloom, r) {
  const fill = along(doc, [[0, '#4f8579'], [0.55, '#8fbfb1'], [0.86, '#cfe0cf'], [0.95, '#e9a2b1'], [1, '#c4607a']]);
  const cy = SOIL_Y - 4;
  if (bloom) {
    const bell = along(doc, [[0, '#e8735a'], [0.7, '#ff9f7a'], [1, '#ffd9a0']]);
    for (const [ex, ey, cx2] of [[CX + 58, cy - 118, CX + 30], [CX - 46, cy - 96, CX - 22]]) {
      const c = quad([CX + (ex > CX ? 8 : -8), cy - 10], [cx2, cy - 80], [ex, ey]);
      doc.add(stem(c, 2.8, '#c99484', { hlOp: 0.2 }));
      for (let k = 0; k < 6; k++) {
        const p = c.at(0.3 + k * 0.1);
        doc.add(leaf({ x: p.x, y: p.y, ang: p.ang + (k % 2 ? 70 : -70), len: 7, w: 30, shape: 'fleshy', fill: '#d9a090', shadeOp: 0, ribOp: 0 }));
      }
      for (let k = 0; k < 6; k++) {
        const p = c.at(0.72 + k * 0.055);
        const side = k % 2 ? 1 : -1;
        doc.add(leaf({ x: p.x, y: p.y, ang: p.ang + side * 70 + 30 * (ex > CX ? 1 : -1), len: 11, w: 34, shape: 'petal', fill: bell, shadeOp: 0.12, ribOp: 0, flip: false }));
      }
    }
  }
  const rings = 1 + Math.round(t * 3);
  const leaves = [];
  for (let i = 0; i < rings; i++) {
    const k = 9 - i;
    const e = 12 + i * 20 + (rings === 1 ? 25 : 0);
    const len = (20 + 54 * t) * (1 - i * 0.17);
    for (let j = 0; j < k; j++) {
      const phi = (j / k) * 360 + i * 20 + r.range(-6, 6);
      const ce = Math.cos(rad(e));
      const dx = Math.cos(rad(phi)) * ce;
      const dy = -Math.sin(rad(e)) + Math.sin(rad(phi)) * ce * 0.36;
      const pl = Math.hypot(dx, dy);
      leaves.push({ depth: Math.sin(rad(phi)) * ce - i * 0.05, svg: leaf({ x: CX + dx * 3, y: cy + dy * 3, ang: (Math.atan2(dy, dx) * 180) / Math.PI, len: len * clamp(pl, 0.45, 1), w: 34, shape: 'fleshy', fill, shadeOp: 0.16, ribOp: 0.12, gloss: 0.18, flip: false }) });
    }
  }
  // innermost bud
  leaves.push({ depth: 0.5, svg: ellipse(CX, cy - 4 - t * 3, 5 + t * 3, 4 + t * 2, '#a9d1c2') });
  leaves.sort((a, b) => a.depth - b.depth);
  for (const l of leaves) doc.add(l.svg);
}

// ---------------------------------------------------------------------------
function cactusBody(doc, x0, x1, top, bottom, fill) {
  const w = x1 - x0;
  const rr = w / 2;
  const tY = Math.min(top + rr, bottom);
  let s = `<path d="M${f(x0)},${f(bottom)} L${f(x0)},${f(tY)} A${f(rr)},${f(rr)} 0 0 1 ${f(x1)},${f(tY)} L${f(x1)},${f(bottom)} Z" fill="${fill}"/>`;
  // ribs
  const ribs = 5;
  let dk = '';
  let lt = '';
  let sp = '';
  for (let i = 1; i < ribs; i++) {
    const fx = i / ribs;
    const x = x0 + w * fx;
    const off = (fx - 0.5) * 2;
    const yTop = tY - Math.sqrt(Math.max(0, 1 - off * off)) * rr + 3;
    dk += `M${f(x)},${f(bottom)} L${f(x)},${f(tY)} Q${f(x)},${f(yTop)} ${f(lerp(x, x0 + rr, 0.6))},${f(yTop - 1)} `;
    lt += `M${f(x + 2)},${f(bottom)} L${f(x + 2)},${f(tY)} `;
    for (let y = bottom - 8; y > tY; y -= 10) {
      sp += `M${f(x - 2.4)},${f(y - 1)} L${f(x)},${f(y)} L${f(x + 2.4)},${f(y - 1.2)} M${f(x)},${f(y)} L${f(x - 0.3)},${f(y - 3)} `;
    }
  }
  s += `<path d="${dk}" fill="none" stroke="#173d22" stroke-opacity="0.32" stroke-width="1.1"/>`;
  s += `<path d="${lt}" fill="none" stroke="#c6e7a6" stroke-opacity="0.25" stroke-width="1"/>`;
  s += `<path d="${sp}" fill="none" stroke="#fbf5df" stroke-opacity="0.85" stroke-width="0.6" stroke-linecap="round"/>`;
  return s;
}
function cactus(doc, t, bloom, r) {
  const fill = doc.lin([[0, '#2d6038'], [0.3, '#6caa63'], [0.55, '#4e8b51'], [1, '#1f4a29']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });
  const cw = 24 + 16 * t;
  const h = 26 + 140 * t;
  const x0 = CX - cw / 2;
  const top = SOIL_Y - h;
  const tips = [[CX, top]];
  // arms
  if (t > 0.5) {
    const ay = SOIL_Y - h * 0.48;
    const ah = 26 + 40 * t;
    const aw = cw * 0.62;
    const ax = CX + cw / 2 - 4;
    doc.add(`<path d="M${f(ax)},${f(ay + aw / 2)} L${f(ax + 18)},${f(ay + aw / 2)} Q${f(ax + 18 + aw)},${f(ay + aw / 2)} ${f(ax + 18 + aw)},${f(ay - 4)} L${f(ax + 18 + aw)},${f(ay - ah)} A${f(aw / 2)},${f(aw / 2)} 0 0 0 ${f(ax + 18)},${f(ay - ah)} L${f(ax + 18)},${f(ay - aw / 2)} L${f(ax)},${f(ay - aw / 2)} Z" fill="${fill}"/>`);
    doc.add(cactusBody(doc, ax + 18, ax + 18 + aw, ay - ah - aw / 2, ay - 6, fill));
    tips.push([ax + 18 + aw / 2, ay - ah - aw / 2]);
  }
  if (t > 0.75) {
    const ay = SOIL_Y - h * 0.62;
    const ah = 18 + 30 * t;
    const aw = cw * 0.55;
    const ax = CX - cw / 2 + 4;
    doc.add(`<path d="M${f(ax)},${f(ay + aw / 2)} L${f(ax - 16)},${f(ay + aw / 2)} Q${f(ax - 16 - aw)},${f(ay + aw / 2)} ${f(ax - 16 - aw)},${f(ay - 4)} L${f(ax - 16 - aw)},${f(ay - ah)} A${f(aw / 2)},${f(aw / 2)} 0 0 1 ${f(ax - 16)},${f(ay - ah)} L${f(ax - 16)},${f(ay - aw / 2)} L${f(ax)},${f(ay - aw / 2)} Z" fill="${fill}"/>`);
    doc.add(cactusBody(doc, ax - 16 - aw, ax - 16, ay - ah - aw / 2, ay - 6, fill));
    tips.push([ax - 16 - aw / 2, ay - ah - aw / 2]);
  }
  doc.add(cactusBody(doc, x0, x0 + cw, top, SOIL_Y + 4, fill));
  if (bloom) {
    const pf = doc.lin([[0, '#ffd1e6'], [0.4, '#ff6fa8'], [1, '#c2185b']], { x1: 1, y1: 0.5, x2: 0, y2: 0.5 });
    for (const [x, y] of tips) {
      for (let i = 0; i < 9; i++) {
        doc.add(leaf({ x, y: y + 3, ang: -180 + i * 22.5, len: 15, w: 34, shape: 'petal', fill: pf, shadeOp: 0.12, ribOp: 0.15, flip: false }));
      }
      doc.add(circle(x, y + 1, 3.4, '#ffe48a'));
    }
  }
}

// ---------------------------------------------------------------------------
function fern(doc, t, bloom, r) {
  const fill = leafFill(doc, '#b6e07c', '#62aa40', '#2d6b23');
  const n = 3 + Math.round(t * 9) + (bloom ? 2 : 0);
  const fronds = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = lerp(-160, -20, fr) + r.range(-6, 6);
    const L = (40 + 96 * t) * r.range(0.82, 1.02) * (1 - Math.abs(fr - 0.5) * 0.25);
    fronds.push({ fr, ang, L });
  }
  fronds.sort((a, b) => Math.abs(a.fr - 0.5) - Math.abs(b.fr - 0.5));
  for (const fd of fronds) {
    const p0 = [CX + (fd.fr - 0.5) * 8, SOIL_Y];
    const d1 = dir(lerp(fd.ang, -90, 0.55));
    const d2 = dir(fd.ang);
    const droop = fd.L * 0.42 * Math.abs(Math.cos(rad(fd.ang)));
    const p1 = [p0[0] + d1[0] * fd.L * 0.62, p0[1] + d1[1] * fd.L * 0.62];
    const p2 = [p0[0] + d2[0] * fd.L, p0[1] + d2[1] * fd.L + droop];
    const c = quad(p0, p1, p2);
    let s = stem(c, 1.7, '#4d7a2c', { hlOp: 0 });
    const pairs = 16;
    for (let k = 1; k <= pairs; k++) {
      const u = 0.1 + (k / pairs) * 0.88;
      const p = c.at(u);
      const pl = (5 + 15 * t) * Math.pow(Math.sin(Math.PI * clamp(u * 0.9 + 0.05, 0, 1)), 0.7) * (1.15 - u * 0.5);
      s += leaf({ x: p.x, y: p.y, ang: p.ang - 62, len: pl, w: 22, shape: 'narrow', fill, shadeOp: 0.16, ribOp: 0.18 });
      s += leaf({ x: p.x, y: p.y, ang: p.ang + 62, len: pl, w: 22, shape: 'narrow', fill, shadeOp: 0.16, ribOp: 0.18 });
    }
    doc.add(s);
  }
  if (bloom) {
    // fiddleheads
    for (const dx of [-8, 9]) {
      const x = CX + dx;
      doc.add(stem(quad([x, SOIL_Y], [x, SOIL_Y - 22], [x + 3, SOIL_Y - 36]), 2, '#7fb24a', { hlOp: 0 }));
      doc.add(`<path d="M${f(x + 3)},${f(SOIL_Y - 36)} a5,5 0 1 1 6,-6 a3,3 0 1 1 -3,3" fill="none" stroke="#9fd06a" stroke-width="2.4" stroke-linecap="round"/>`);
    }
  }
}

// ---------------------------------------------------------------------------
function pad(doc, cx, cy, rx, ry, r, fill, dark) {
  let s = ellipse(cx, cy + ry * 0.35, rx * 1.02, ry * 0.75, dark, ' fill-opacity="0.85"');
  const n = Math.max(6, Math.round(rx * 0.55));
  const blobs = [];
  for (let i = 0; i < n; i++) {
    const a = r.range(0, Math.PI * 2);
    const d = Math.sqrt(r());
    blobs.push([cx + Math.cos(a) * rx * 0.75 * d, cy + Math.sin(a) * ry * 0.55 * d - ry * 0.15, r.range(ry * 0.5, ry * 0.85)]);
  }
  blobs.sort((a, b) => a[1] - b[1]);
  for (const [x, y, rr] of blobs) s += circle(x, y, rr, fill);
  let dots = '';
  for (let i = 0; i < n * 2; i++) {
    const a = r.range(0, Math.PI * 2);
    const d = Math.sqrt(r());
    dots += `M${f(cx + Math.cos(a) * rx * 0.85 * d)},${f(cy + Math.sin(a) * ry * 0.6 * d - ry * 0.25)} l1.6,-1.2 `;
  }
  s += `<path d="${dots}" fill="none" stroke="#d9f0a8" stroke-opacity="0.5" stroke-width="1.1" stroke-linecap="round"/>`;
  return s;
}
function bonsai(doc, t, bloom, r) {
  const bark = doc.lin([[0, '#a07f62'], [0.45, '#6d4f39'], [1, '#3d2a1d']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });
  const fill = doc.radial([[0, '#a6d36a'], [0.6, '#5c9a3f'], [1, '#2f6a2c']], { cx: 0.4, cy: 0.3, r: 0.75 });
  const dark = '#1f4a22';
  const H = 30 + 100 * t;
  const w0 = 5 + 13 * t;
  const a = [CX + 2, SOIL_Y + 2];
  const b = [CX - 12 * t, SOIL_Y - H * 0.5];
  const c = [CX + 14 * t, SOIL_Y - H];
  const t1 = quad(a, [CX - 26 * t, SOIL_Y - H * 0.2], b);
  const t2 = quad(b, [CX + 18 * t, SOIL_Y - H * 0.72], c);
  // branches
  const pads = [];
  const br = [];
  if (t > 0.45) {
    const p = t2.at(0.15);
    const end = [p.x + 48 * t, p.y - 4];
    br.push(limb(quad([p.x, p.y], [p.x + 30 * t, p.y + 6], end), w0 * 0.45, 2, bark));
    pads.push([end[0] + 4, end[1] - 4, 20 + 14 * t, 9 + 4 * t]);
  }
  if (t > 0.7) {
    const p = t1.at(0.85);
    const end = [p.x - 46 * t, p.y - 14];
    br.push(limb(quad([p.x, p.y], [p.x - 26 * t, p.y + 4], end), w0 * 0.42, 2, bark));
    pads.push([end[0] - 4, end[1] - 4, 18 + 14 * t, 8 + 4 * t]);
  }
  pads.push([c[0], c[1] - 6, 22 + 22 * t, 11 + 6 * t]);
  if (bloom) pads.push([c[0] - 30, c[1] + 18, 16, 8]);
  for (const s of br) doc.add(s);
  doc.add(limb(t1, w0, w0 * 0.7, bark));
  doc.add(limb(t2, w0 * 0.7, 3, bark));
  // bark lines
  let lines = '';
  for (let i = 0; i < 4; i++) {
    const o = (i - 1.5) * w0 * 0.18;
    lines += `M${f(a[0] + o)},${f(a[1] - 4)} Q${f(CX - 22 * t + o)},${f(SOIL_Y - H * 0.25)} ${f(b[0] + o)},${f(b[1])} `;
  }
  doc.add(`<path d="${lines}" fill="none" stroke="#c9a888" stroke-opacity="0.28" stroke-width="0.9"/>`);
  for (const [x, y, rx, ry] of pads) doc.add(pad(doc, x, y, rx, ry, r, fill, dark));
  if (bloom) {
    let tips = '';
    for (let i = 0; i < 26; i++) {
      const p = r.pick(pads);
      tips += `M${f(p[0] + r.range(-p[2], p[2]) * 0.8)},${f(p[1] - r.range(0, p[3]) * 0.9)} l0.1,0 `;
    }
    doc.add(`<path d="${tips}" stroke="#e6f7b5" stroke-width="2.6" stroke-linecap="round" fill="none"/>`);
  }
}

// ---------------------------------------------------------------------------
function sunflower(doc, t, bloom, r) {
  const H = 50 + 140 * t;
  const top = [CX + 6, SOIL_Y - H];
  const c = quad([CX, SOIL_Y], [CX - 10, SOIL_Y - H * 0.55], top);
  doc.add(stem(c, 3 + 3 * t, '#5f8f3a'));
  const fill = leafFill(doc, '#93c45a', '#4e8a31', '#2a5a1c');
  const n = 2 + Math.round(t * 3);
  for (let i = 0; i < n; i++) {
    const u = 0.12 + (i / n) * 0.62;
    const p = c.at(u);
    const right = i % 2 === 0;
    const ang = right ? r.range(-34, 4) : r.range(-184, -146);
    doc.add(leaf({ x: p.x, y: p.y, ang, len: (20 + 28 * t) * (1.1 - u * 0.5), w: 40, shape: 'heart', fill, veins: 5, veinOp: 0.25, shadeOp: 0.22 }));
  }
  const [hx, hy] = top;
  if (bloom) {
    const R = 36;
    const pf = along(doc, [[0, '#e08a0c'], [0.35, '#f7b322'], [1, '#ffe066']]);
    for (let i = 0; i < 22; i++) doc.add(leaf({ x: hx, y: hy, ang: i * (360 / 22) + 8, len: R * 1.02, w: 24, shape: 'lance', fill: pf, shadeOp: 0.12, ribOp: 0.2, rib: '#fff6c4', flip: false }));
    for (let i = 0; i < 22; i++) doc.add(leaf({ x: hx, y: hy, ang: i * (360 / 22), len: R * 0.92, w: 24, shape: 'lance', fill: pf, shadeOp: 0.18, ribOp: 0.25, rib: '#fff6c4', flip: false }));
    doc.add(circle(hx, hy, R * 0.5, doc.radial([[0, '#8a5a2b'], [0.6, '#4a2c14'], [1, '#2b190b']], { cx: 0.45, cy: 0.4, r: 0.6 })));
    let dots = '';
    const golden = 137.508;
    for (let i = 1; i < 120; i++) {
      const rr = Math.sqrt(i / 120) * R * 0.46;
      const a = rad(i * golden);
      dots += `M${f(hx + Math.cos(a) * rr)},${f(hy + Math.sin(a) * rr)} l0.1,0 `;
    }
    doc.add(`<path d="${dots}" stroke="#c48a4a" stroke-opacity="0.75" stroke-width="1.4" stroke-linecap="round" fill="none"/>`);
  } else if (t > 0.5) {
    const R = 6 + 12 * t;
    for (let i = 0; i < 14; i++) doc.add(leaf({ x: hx, y: hy, ang: i * (360 / 14), len: R, w: 22, shape: 'lance', fill: '#6aa543', shadeOp: 0.2, ribOp: 0 }));
    if (t > 0.75) for (let i = 0; i < 10; i++) doc.add(leaf({ x: hx, y: hy, ang: -90 + (i - 4.5) * 14, len: R * 0.75, w: 26, shape: 'lance', fill: '#ffcf33', shadeOp: 0.1, ribOp: 0 }));
    doc.add(circle(hx, hy, R * 0.55, '#4f8a2f'));
  }
}

// ---------------------------------------------------------------------------
function tulipHead(doc, x, y, ang, sz, pal, open) {
  const [a, b, c] = pal;
  const pf = doc.lin([[0, a], [0.5, b], [1, c]], { x1: 0.5, y1: 0, x2: 0.5, y2: 1 });
  const back = doc.lin([[0, c], [1, b]], { x1: 0.5, y1: 0, x2: 0.5, y2: 1 });
  const spread = open ? 16 : 6;
  let s = '';
  s += leaf({ x, y, ang: ang, len: sz * 1.05, w: 36, shape: 'petal', fill: back, shadeOp: 0.1, ribOp: 0, flip: false });
  s += leaf({ x: x - 1, y, ang: ang - spread, len: sz, w: 40, shape: 'petal', fill: pf, shadeOp: 0.2, ribOp: 0.15, flip: true });
  s += leaf({ x: x + 1, y, ang: ang + spread, len: sz, w: 40, shape: 'petal', fill: pf, shadeOp: 0.2, ribOp: 0.15, flip: false });
  s += leaf({ x, y: y + 1, ang, len: sz * 0.92, w: 30, shape: 'petal', fill: pf, shadeOp: 0.12, ribOp: 0.25, rib: '#ffffff', flip: false });
  return s;
}
function tulip(doc, t, bloom, r) {
  const lf = leafFill(doc, '#a5cf98', '#5c9467', '#2f5a3e');
  const heads = bloom ? 3 : t > 0.7 ? 1 : 0;
  const pals = [['#ff8c8c', '#e03a4a', '#8e1426'], ['#ffd1e8', '#f27db3', '#b83a7a'], ['#fff1a8', '#ffcc33', '#d48a0c']];
  const leaves = [-122, -58, -140, -40].slice(0, 2 + Math.round(t * 2));
  const stems = [];
  for (let i = 0; i < Math.max(1, heads); i++) {
    const dx = heads > 1 ? (i - 1) * 22 : 0;
    const H = (40 + 120 * t) * (heads > 1 ? [0.88, 1, 0.8][i] : 1);
    const top = [CX + dx * 1.5, SOIL_Y - H];
    stems.push({ c: quad([CX + dx * 0.3, SOIL_Y], [CX + dx * 0.6, SOIL_Y - H * 0.5], top), top, i });
  }
  for (const s of stems) doc.add(stem(s.c, 3, '#6d9c5c'));
  for (const a of leaves) {
    const len = (34 + 62 * t) * r.range(0.85, 1.05);
    doc.add(leaf({ x: CX + Math.cos(rad(a)) * 4, y: SOIL_Y + 2, ang: a + (a < -90 ? 6 : -6), len, w: 20, shape: 'lance', fill: lf, shadeOp: 0.22, ribOp: 0.2, gloss: 0.12 }));
  }
  if (heads === 0 && t > 0.4) {
    const s = stems[0];
    doc.add(leaf({ x: s.top[0], y: s.top[1] + 3, ang: -90, len: 10 + 6 * t, w: 30, shape: 'petal', fill: '#8fbf6a', shadeOp: 0.2, ribOp: 0 }));
  }
  if (heads > 0) {
    for (const s of stems) doc.add(tulipHead(doc, s.top[0], s.top[1] + 4, -90 + (s.i - 1) * 4, bloom ? 36 : 20, bloom ? pals[s.i % 3] : ['#c9e39a', '#e88b8b', '#a54050'], bloom));
  }
}

// ---------------------------------------------------------------------------
function lavender(doc, t, bloom, r) {
  const lf = leafFill(doc, '#c3d6bd', '#86a487', '#56705a');
  const n = 4 + Math.round(t * 12);
  const spikeFill = doc.lin([[0, '#c8b4f2'], [0.5, '#8a68d4'], [1, '#4b3192']], { x1: 0.3, y1: 0, x2: 0.7, y2: 1 });
  const budFill = doc.lin([[0, '#bfcfb8'], [1, '#8e88a8']], { x1: 0.3, y1: 0, x2: 0.7, y2: 1 });
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = -90 + lerp(-30, 30, fr) + r.range(-5, 5);
    const L = (34 + 116 * t) * r.range(0.78, 1);
    const p0 = [CX + (fr - 0.5) * 16, SOIL_Y];
    const d = dir(ang);
    const p2 = [p0[0] + d[0] * L, p0[1] + d[1] * L];
    const c = quad(p0, [lerp(p0[0], p2[0], 0.3), lerp(p0[1], p2[1], 0.6)], p2);
    doc.add(stem(c, 1.4, '#7d9a6a', { hlOp: 0 }));
    if (t > 0.6) {
      const fill = bloom ? spikeFill : budFill;
      for (let k = 0; k < 9; k++) {
        const u = 0.72 + k * 0.034;
        const p = c.at(u);
        const sz = (bloom ? 6.5 : 5) * (1 - k * 0.05);
        doc.add(leaf({ x: p.x, y: p.y, ang: p.ang - 70, len: sz, w: 50, shape: 'round', fill, shadeOp: 0.15, ribOp: 0 }));
        doc.add(leaf({ x: p.x, y: p.y, ang: p.ang + 70, len: sz, w: 50, shape: 'round', fill, shadeOp: 0.15, ribOp: 0 }));
      }
    }
  }
  const m = 8 + Math.round(t * 10);
  for (let i = 0; i < m; i++) {
    const ang = lerp(-172, -8, i / (m - 1)) + r.range(-6, 6);
    doc.add(leaf({ x: CX + r.range(-10, 10), y: SOIL_Y, ang, len: (12 + 22 * t) * r.range(0.7, 1), w: 12, shape: 'narrow', fill: lf, shadeOp: 0.15, ribOp: 0.2 }));
  }
}

// ---------------------------------------------------------------------------
function cherry(doc, t, bloom, r) {
  const bark = doc.lin([[0, '#8a6658'], [0.5, '#5b3d33'], [1, '#33211b']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });
  const maxDepth = 1 + Math.round(t * 3);
  const tips = [];
  const branches = [];
  const grow = (p, ang, len, w, depth) => {
    const d = dir(ang);
    const end = [p[0] + d[0] * len, p[1] + d[1] * len];
    const bend = r.range(-0.18, 0.18) * len;
    const mid = [lerp(p[0], end[0], 0.5) + bend, lerp(p[1], end[1], 0.5)];
    branches.push(limb(quad(p, mid, end), w, w * 0.62, bark, { n: 10 }));
    if (depth >= maxDepth) { tips.push(end); return; }
    const k = depth === 0 ? 2 : r() < 0.35 ? 3 : 2;
    for (let i = 0; i < k; i++) {
      const spread = k === 2 ? (i ? 1 : -1) * r.range(20, 34) : (i - 1) * 30;
      grow(end, ang + spread, len * r.range(0.66, 0.78), w * 0.62, depth + 1);
    }
    if (depth >= 1) tips.push([lerp(p[0], end[0], 0.6), lerp(p[1], end[1], 0.6)]);
  };
  grow([CX, SOIL_Y + 3], -90 + r.range(-3, 3), 32 + 30 * t, 5 + 9 * t, 0);
  for (const b of branches) doc.add(b);
  if (bloom) {
    const petal = doc.radial([[0, '#fff3f7'], [0.6, '#ffc2d6'], [1, '#f08bb0']], { cx: 0.2, cy: 0.5, r: 0.9 });
    const petal2 = doc.radial([[0, '#ffffff'], [0.6, '#ffe0ea'], [1, '#f7a9c4']], { cx: 0.2, cy: 0.5, r: 0.9 });
    for (const [x, y] of tips) {
      const k = 4 + Math.floor(r() * 3);
      for (let j = 0; j < k; j++) {
        const bx = clamp(x + r.range(-12, 12), 14, 226);
        const by = y + r.range(-11, 7);
        doc.add(blossom(doc, bx, by, r.range(4.2, 6), { petal: r() < 0.5 ? petal : petal2, center: '#c2416e', rot: r.range(0, 72), w: 58 }));
      }
    }
    for (let i = 0; i < 9; i++) {
      const x = r.range(46, 194);
      const y = r.range(120, 226);
      doc.add(leaf({ x, y, ang: r.range(0, 360), len: 4.5, w: 55, shape: 'petal', fill: '#f7b6cc', shadeOp: 0, ribOp: 0, opacity: 0.85 }));
    }
  } else if (t > 0.3) {
    const lf = leafFill(doc, '#a8d67a', '#5f9e45', '#356b2a');
    for (const [x, y] of tips) {
      for (let j = 0; j < 4; j++) {
        doc.add(leaf({ x: x + r.range(-4, 4), y: y + r.range(-4, 2), ang: r.range(-170, -10), len: 7 + 6 * t, w: 30, shape: 'ovate', fill: lf, shadeOp: 0.2, ribOp: 0.2 }));
      }
    }
  }
}

// ---------------------------------------------------------------------------
function peaceLily(doc, t, bloom, r) {
  const fill = leafFill(doc, '#4f9d5c', '#1f5e35', '#0d361d');
  const n = 3 + Math.round(t * 7);
  const items = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = lerp(-138, -42, fr) + r.range(-7, 7);
    const plen = (30 + 52 * t) * r.range(0.8, 1.05);
    const p0 = [CX + (fr - 0.5) * 6, SOIL_Y];
    const d = dir(lerp(ang, -90, 0.35));
    const p2 = [p0[0] + d[0] * plen, p0[1] + d[1] * plen];
    const c = quad(p0, [lerp(p0[0], p2[0], 0.15), lerp(p0[1], p2[1], 0.75)], p2);
    const end = c.at(1);
    const lang = end.ang + (Math.cos(rad(ang)) > 0 ? 28 : -28) * Math.abs(Math.cos(rad(ang)));
    items.push({ fr, svg: stem(c, 2, '#2f6a3a', { hlOp: 0.12 }) + leaf({ x: p2[0], y: p2[1], ang: lang, len: (26 + 34 * t) * r.range(0.9, 1.05), w: 26, shape: 'elliptic', fill, veins: 7, veinOp: 0.2, veinColor: '#cfe8c5', gloss: 0.24, shadeOp: 0.25 }) });
  }
  items.sort((a, b) => Math.abs(b.fr - 0.5) - Math.abs(a.fr - 0.5));
  const spathe = doc.lin([[0, '#ffffff'], [0.6, '#eef2e6'], [1, '#c9d6bf']], { x1: 0.3, y1: 0, x2: 0.7, y2: 1 });
  const flowers = bloom ? [[-18, 0.92], [16, 1.0], [2, 0.8]] : t > 0.7 ? [[8, 0.8]] : [];
  for (const [dx, hh] of flowers) {
    const H = (60 + 96 * t) * hh;
    const top = [CX + dx, SOIL_Y - H];
    doc.add(stem(quad([CX + dx * 0.2, SOIL_Y], [CX + dx * 0.4, SOIL_Y - H * 0.5], top), 1.8, '#3f7a44', { hlOp: 0.1 }));
    const green = !bloom;
    doc.add(leaf({ x: top[0], y: top[1] + 2, ang: -90 + dx * 0.3, len: green ? 20 : 34, w: green ? 22 : 36, shape: 'ovate', fill: green ? leafFill(doc, '#e3f0d0', '#b9d9a2', '#7fae6c') : spathe, shadeOp: 0.12, ribOp: 0.4, rib: '#c9d6bf', flip: false }));
    if (!green) doc.add(`<path d="M${f(top[0] + 3)},${f(top[1] - 2)} L${f(top[0] + 6)},${f(top[1] - 15)}" stroke="#f3e2a2" stroke-width="4.2" stroke-linecap="round"/>`);
  }
  for (const it of items) doc.add(it.svg);
}

// ---------------------------------------------------------------------------
function aloe(doc, t, bloom, r) {
  const fill = leafFill(doc, '#b6d9a8', '#73a970', '#3d6d45');
  const n = 3 + Math.round(t * 8);
  const items = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = lerp(-155, -25, fr) + r.range(-5, 5);
    const up = 1 - Math.abs(fr - 0.5) * 0.6;
    const len = (28 + 88 * t) * up * r.range(0.85, 1.05);
    const seed = Math.floor(r() * 1000);
    items.push({ len, svg: leaf({
      x: CX + (fr - 0.5) * 10, y: SOIL_Y, ang: lerp(ang, -90, 0.25), len, w: 13, shape: 'spear', fill, shadeOp: 0.24, ribOp: 0.15, gloss: 0.1,
      extra: (s, w, sw) => {
        let dots = '';
        let teeth = '';
        let k = seed;
        for (let x = 10; x < 82; x += 5) {
          k = (k * 9301 + 49297) % 233280;
          const yy = ((k / 233280) - 0.5) * widthAt('spear', 13, x) * 1.4;
          dots += `M${f(x)},${f(yy)} l${f(sw(1.6))},0 `;
          const wa = widthAt('spear', 13, x);
          teeth += `M${f(x)},${f(-wa)} l${f(sw(1.4))},${f(-sw(1.6))} l${f(sw(0.6))},${f(sw(1.6))} M${f(x + 2.5)},${f(wa)} l${f(sw(1.4))},${f(sw(1.6))} l${f(sw(0.6))},${f(-sw(1.6))} `;
        }
        return `<path d="${dots}" stroke="#eef6df" stroke-opacity="0.55" stroke-width="${sw(1.5)}" stroke-linecap="round" fill="none"/><path d="${teeth}" fill="#e9e2bf" fill-opacity="0.8"/>`;
      },
    }) });
  }
  if (bloom) {
    const c = quad([CX + 4, SOIL_Y], [CX + 18, SOIL_Y - 100], [CX + 24, SOIL_Y - 196]);
    doc.add(stem(c, 2.4, '#8aa36a'));
    const tf = along(doc, [[0, '#d6402a'], [0.6, '#ff8a3c'], [1, '#ffd36a']]);
    for (let k = 0; k < 22; k++) {
      const u = 0.62 + k * 0.017;
      const p = c.at(u);
      const side = k % 2 ? 1 : -1;
      doc.add(leaf({ x: p.x, y: p.y, ang: 90 + side * (40 - k * 1.4), len: 13 - k * 0.3, w: 16, shape: 'narrow', fill: tf, shadeOp: 0.12, ribOp: 0, flip: false }));
    }
  }
  items.sort((a, b) => b.len - a.len);
  for (const it of items) doc.add(it.svg);
}

// ---------------------------------------------------------------------------
function roseHead(doc, x, y, R) {
  // side-view rose: (x, y) is where the bloom meets the stem
  const deep = doc.lin([[0, '#c81d3c'], [1, '#6e0a1b']]);
  const mid = doc.lin([[0, '#ff5a74'], [0.6, '#d9203f'], [1, '#8e0f26']], { x1: 0.2, y1: 0, x2: 0.8, y2: 1 });
  const lite = doc.lin([[0, '#ff8fa1'], [0.5, '#ec3a57'], [1, '#a3122f']], { x1: 0.2, y1: 0, x2: 0.8, y2: 1 });
  let s = '';
  for (const a of [-58, -122]) s += leaf({ x, y: y + 2, ang: a + 180 - 180, len: R * 0.8, w: 26, shape: 'lance', fill: '#3f6a2a', shadeOp: 0.2, ribOp: 0 });
  s += leaf({ x: x - 2, y, ang: -112, len: R * 1.25, w: 52, shape: 'petal', fill: deep, shadeOp: 0.1, ribOp: 0, flip: true });
  s += leaf({ x: x + 2, y, ang: -68, len: R * 1.25, w: 52, shape: 'petal', fill: deep, shadeOp: 0.1, ribOp: 0, flip: false });
  s += leaf({ x, y, ang: -90, len: R * 1.3, w: 46, shape: 'petal', fill: mid, shadeOp: 0.12, ribOp: 0, flip: false });
  s += `<path d="M${f(x - R * 0.28)},${f(y - R * 1.05)} Q${f(x)},${f(y - R * 1.32)} ${f(x + R * 0.3)},${f(y - R * 1.02)} M${f(x - R * 0.16)},${f(y - R * 0.95)} Q${f(x + R * 0.05)},${f(y - R * 1.12)} ${f(x + R * 0.18)},${f(y - R * 0.9)}" fill="none" stroke="#6e0a1b" stroke-opacity="0.7" stroke-width="1.2" stroke-linecap="round"/>`;
  s += leaf({ x: x - 1, y: y + 1, ang: -132, len: R * 1.1, w: 58, shape: 'petal', fill: lite, shadeOp: 0.14, ribOp: 0, flip: true });
  s += leaf({ x: x + 1, y: y + 1, ang: -48, len: R * 1.1, w: 58, shape: 'petal', fill: lite, shadeOp: 0.14, ribOp: 0, flip: false });
  s += leaf({ x, y: y + 2, ang: -90, len: R * 0.82, w: 74, shape: 'round', fill: lite, shadeOp: 0.1, ribOp: 0, flip: false });
  s += `<path d="M${f(x - R * 0.55)},${f(y - R * 0.62)} Q${f(x)},${f(y - R * 0.95)} ${f(x + R * 0.55)},${f(y - R * 0.62)}" fill="none" stroke="#ffc2cc" stroke-opacity="0.75" stroke-width="1.1" stroke-linecap="round"/>`;
  return s;
}
function rose(doc, t, bloom, r) {
  const lf = leafFill(doc, '#7fb85a', '#3b6d2c', '#1d4317');
  const canes = 2 + Math.round(t * 2);
  const tops = [];
  for (let i = 0; i < canes; i++) {
    const fr = canes === 1 ? 0.5 : i / (canes - 1);
    const ang = -90 + lerp(-28, 28, fr);
    const H = (36 + 120 * t) * r.range(0.78, 1);
    const p0 = [CX + (fr - 0.5) * 10, SOIL_Y];
    const d = dir(ang);
    const p2 = [p0[0] + d[0] * H, p0[1] + d[1] * H];
    const c = quad(p0, [lerp(p0[0], p2[0], 0.2) + r.range(-10, 10), lerp(p0[1], p2[1], 0.55)], p2);
    doc.add(stem(c, 2.8, '#4a6a2c'));
    // thorns
    let th = '';
    for (let u = 0.15; u < 0.9; u += 0.14) {
      const p = c.at(u);
      th += `M${f(p.x + 1)},${f(p.y)} l3,-1.5 l-2,3 Z `;
    }
    doc.add(`<path d="${th}" fill="#6a3a2a"/>`);
    // compound leaves
    const m = 1 + Math.round(t * 3);
    for (let k = 0; k < m; k++) {
      const u = 0.25 + k * (0.6 / m);
      const p = c.at(u);
      const side = (k + i) % 2 ? 1 : -1;
      const la = p.ang + side * 55;
      const ld = dir(la);
      const L = 10 + 10 * t;
      const e = [p.x + ld[0] * L, p.y + ld[1] * L];
      doc.add(stem(quad([p.x, p.y], [p.x + ld[0] * L * 0.5, p.y + ld[1] * L * 0.5 - 2], e), 1.2, '#4a6a2c', { hlOp: 0 }));
      const sz = 8 + 7 * t;
      doc.add(leaf({ x: e[0], y: e[1], ang: la, len: sz, w: 34, shape: 'ovate', fill: lf, veins: 3, shadeOp: 0.22, ribOp: 0.25, gloss: 0.15 }));
      for (const o of [0.45, 0.8]) {
        const q = [p.x + ld[0] * L * o, p.y + ld[1] * L * o];
        doc.add(leaf({ x: q[0], y: q[1], ang: la - 55, len: sz * 0.8, w: 34, shape: 'ovate', fill: lf, shadeOp: 0.22, ribOp: 0.25 }));
        doc.add(leaf({ x: q[0], y: q[1], ang: la + 55, len: sz * 0.8, w: 34, shape: 'ovate', fill: lf, shadeOp: 0.22, ribOp: 0.25 }));
      }
    }
    tops.push(p2);
  }
  for (const [x, y] of tops) {
    if (bloom) doc.add(roseHead(doc, x, y + 2, 15));
    else if (t > 0.5) {
      for (const a of [-130, -50, -90]) doc.add(leaf({ x, y, ang: a, len: 9, w: 20, shape: 'narrow', fill: '#4f7f34', shadeOp: 0.2, ribOp: 0 }));
      if (t > 0.75) doc.add(leaf({ x, y: y + 1, ang: -90, len: 12, w: 34, shape: 'petal', fill: doc.lin([[0, '#ff6b81'], [1, '#a3122f']]), shadeOp: 0.2, ribOp: 0, flip: false }));
    }
  }
}

// ---------------------------------------------------------------------------
function birdOfParadise(doc, t, bloom, r) {
  const fill = leafFill(doc, '#9cc9a2', '#4f8c66', '#244f39');
  const n = 2 + Math.round(t * 5);
  const items = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = -90 + lerp(-27, 27, fr) + r.range(-4, 4);
    const plen = (36 + 90 * t) * r.range(0.82, 1.04) * (1 - Math.abs(fr - 0.5) * 0.4);
    const p0 = [CX + (fr - 0.5) * 8, SOIL_Y];
    const d = dir(ang);
    const p2 = [p0[0] + d[0] * plen, p0[1] + d[1] * plen];
    const c = quad(p0, [lerp(p0[0], p2[0], 0.2), lerp(p0[1], p2[1], 0.65)], p2);
    const e = c.at(1);
    const lang = e.ang + (Math.cos(rad(ang)) >= 0 ? 12 : -12);
    items.push({ fr, svg: stem(c, 2.4, '#5b8a5c', { hlOp: 0.15 }) + leaf({ x: p2[0], y: p2[1], ang: lang, len: (28 + 38 * t) * r.range(0.9, 1.05), w: 24, shape: 'paddle', fill, veins: 10, veinOp: 0.16, rib: '#f1f0c0', ribOp: 0.55, ribW: 1.4, shadeOp: 0.2, gloss: 0.1 }) });
  }
  items.sort((a, b) => Math.abs(b.fr - 0.5) - Math.abs(a.fr - 0.5));
  for (const it of items) doc.add(it.svg);
  if (bloom || t > 0.75) {
    const H = 120 + 40 * t;
    const top = [CX + 18, SOIL_Y - H];
    doc.add(stem(quad([CX + 3, SOIL_Y], [CX + 8, SOIL_Y - H * 0.5], top), 2.6, '#6a8f5c'));
    const bract = doc.lin([[0, '#7aa063'], [0.6, '#6b5b86'], [1, '#c9506a']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });
    if (bloom) {
      const of = along(doc, [[0, '#f07c11'], [0.6, '#ffa431'], [1, '#ffd36a']]);
      for (const [a, l] of [[-118, 36], [-100, 42], [-82, 38], [-64, 32]]) doc.add(leaf({ x: top[0] + 22, y: top[1] - 3, ang: a, len: l, w: 16, shape: 'narrow', fill: of, shadeOp: 0.15, ribOp: 0.2 }));
      doc.add(leaf({ x: top[0] + 26, y: top[1] - 4, ang: -46, len: 30, w: 12, shape: 'narrow', fill: along(doc, [[0, '#2a3f9e'], [1, '#5f7fe8']]), shadeOp: 0.15, ribOp: 0 }));
    }
    doc.add(leaf({ x: top[0] - 6, y: top[1] + 2, ang: -6, len: 58, w: 17, shape: 'narrow', fill: bract, shadeOp: 0.25, ribOp: 0.2, flip: false }));
  }
}

// ---------------------------------------------------------------------------
function calathea(doc, t, bloom, r) {
  const fill = leafFill(doc, '#5d9064', '#2f5a3a', '#1a3a25');
  const n = 3 + Math.round(t * 6) + (bloom ? 1 : 0);
  const items = [];
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = -90 + lerp(-40, 40, fr) + r.range(-5, 5);
    const plen = (24 + 58 * t) * r.range(0.82, 1.05) * (1 - Math.abs(fr - 0.5) * 0.3);
    const p0 = [CX + (fr - 0.5) * 8, SOIL_Y];
    const d = dir(ang);
    const p2 = [p0[0] + d[0] * plen, p0[1] + d[1] * plen];
    const c = quad(p0, [lerp(p0[0], p2[0], 0.1), lerp(p0[1], p2[1], 0.7)], p2);
    const e = c.at(1);
    items.push({ fr, svg: stem(c, 1.8, '#6b3d5e', { hlOp: 0.1 }) + leaf({
      x: p2[0], y: p2[1], ang: e.ang + r.range(-6, 6), len: (24 + 28 * t) * r.range(0.9, 1.05), w: 30, shape: 'elliptic', fill, shadeOp: 0.2, ribOp: 0.45, rib: '#d8f0c8', edge: '#7a3a68', edgeW: 1.2, edgeOp: 0.7, gloss: 0.12,
      extra: () => {
        let s = `<path d="${'M10,0 C14,-26 70,-26 86,0 C70,26 14,26 10,0 Z'}" fill="#a6d79a" fill-opacity="0.38"/>`;
        s += `<path d="M18,0 C22,-15 60,-15 74,0 C60,15 22,15 18,0 Z" fill="#1d4029" fill-opacity="0.6"/>`;
        let fe = '';
        for (let x = 16; x < 80; x += 7) {
          const wa = widthAt('elliptic', 30, x + 6) * 0.62;
          fe += `M${x},0 Q${x + 4},${f(-wa * 0.5)} ${x + 7},${f(-wa)} M${x},0 Q${x + 4},${f(wa * 0.5)} ${x + 7},${f(wa)} `;
        }
        s += `<path d="${fe}" fill="none" stroke="#c4ecb0" stroke-opacity="0.45" stroke-width="1.8" stroke-linecap="round"/>`;
        return s;
      },
    }) });
  }
  items.sort((a, b) => Math.abs(b.fr - 0.5) - Math.abs(a.fr - 0.5));
  for (const it of items) doc.add(it.svg);
}

// ---------------------------------------------------------------------------
function pothos(doc, t, bloom, r) {
  // Trailing pothos. Vines that cascade over the rim are drawn on the "front"
  // layer by the caller (see `front` below) - here we draw the upright crown.
  const fill = leafFill(doc, '#a5d66b', '#4f9a3a', '#2a6224');
  const varieg = doc.lin([[0, '#fff8c9'], [1, '#e6dd8a']]);
  const n = 3 + Math.round(t * 6);
  for (let i = 0; i < n; i++) {
    const fr = n === 1 ? 0.5 : i / (n - 1);
    const ang = lerp(-140, -40, fr) + r.range(-8, 8);
    const plen = (18 + 70 * t) * r.range(0.7, 1.05) * (1 - Math.abs(fr - 0.5) * 0.6);
    const p0 = [CX + (fr - 0.5) * 20, SOIL_Y];
    const d = dir(ang);
    const p2 = [p0[0] + d[0] * plen, p0[1] + d[1] * plen];
    doc.add(stem(quad(p0, [lerp(p0[0], p2[0], 0.2), lerp(p0[1], p2[1], 0.7)], p2), 1.6, '#5f8f3a', { hlOp: 0 }));
    doc.add(leaf({ x: p2[0], y: p2[1], ang: ang + Math.sign(Math.cos(rad(ang))) * 30, len: 18 + 18 * t, w: 42, shape: 'heart', fill, veins: 3, gloss: 0.18, shadeOp: 0.2,
      extra: (s, w) => `<path d="M20,-8 Q40,-22 58,-14 Q44,-10 30,-4 Z" fill="${varieg}" fill-opacity="0.55"/>` }));
  }
}
function pothosFront(doc, t, bloom, r) {
  if (t < 0.5) return;
  const fill = leafFill(doc, '#a5d66b', '#4f9a3a', '#2a6224');
  const vines = t > 0.8 ? (bloom ? 3 : 2) : 1;
  const ends = [[62, 252 + 34 * t], [176, 250 + 40 * t], [92, 262 + 30 * t]];
  for (let v = 0; v < vines; v++) {
    const [ex, ey] = ends[v];
    const sx = v === 1 ? 168 : 72;
    const c = quad([sx, 240], [sx + (v === 1 ? 22 : -22), 236], [ex, Math.min(ey, 298)]);
    doc.add(stem(c, 1.5, '#5f8f3a', { hlOp: 0 }));
    for (let k = 1; k <= 5; k++) {
      const p = c.at(k / 5.2);
      const side = k % 2 ? 1 : -1;
      doc.add(leaf({ x: p.x, y: p.y, ang: p.ang + side * 55, len: 10 + 8 * t - k * 0.6, w: 42, shape: 'heart', fill, veins: 2, gloss: 0.15, shadeOp: 0.2 }));
    }
  }
}

// ---------------------------------------------------------------------------
function bamboo(doc, t, bloom, r) {
  // Lucky bamboo: segmented canes in a cluster with leafy tops
  const cane = doc.lin([[0, '#6f9e3c'], [0.35, '#b7d870'], [0.65, '#8ab84e'], [1, '#4a7a28']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });
  const lf = leafFill(doc, '#b4e07a', '#5ea23e', '#2f6a24');
  const canes = [[-14, 0.62], [0, 1], [14, 0.8]].slice(0, t > 0.5 ? 3 : 2);
  if (bloom) canes.push([28, 0.45], [-26, 0.4]);
  canes.sort((a, b) => b[1] - a[1]);
  for (const [dx, hh] of canes) {
    const H = (34 + 150 * t) * hh;
    const x = CX + dx;
    const w = 7 + 2 * t;
    doc.add(`<rect x="${f(x - w / 2)}" y="${f(SOIL_Y - H)}" width="${f(w)}" height="${f(H + 4)}" rx="${f(w / 2)}" fill="${cane}"/>`);
    let nodes = '';
    for (let y = SOIL_Y - 22; y > SOIL_Y - H + 6; y -= 24) nodes += `M${f(x - w / 2)},${f(y)} L${f(x + w / 2)},${f(y)} `;
    doc.add(`<path d="${nodes}" stroke="#3f6a22" stroke-width="2.2" stroke-opacity="0.55"/>`);
    doc.add(`<path d="${nodes}" stroke="#e2f3b5" stroke-width="0.8" stroke-opacity="0.7" transform="translate(0,2)"/>`);
    const k = 3 + Math.round(t * 2);
    for (let i = 0; i < k; i++) {
      const y = SOIL_Y - H + 4 + i * 5;
      const a = i % 2 ? -40 - i * 4 : -140 + i * 4;
      doc.add(stem(quad([x, y], [x + Math.cos(rad(a)) * 4, y - 4], [x + Math.cos(rad(a)) * 8, y - 6]), 1.4, '#6f9e3c', { hlOp: 0 }));
      doc.add(leaf({ x: x + Math.cos(rad(a)) * 8, y: y - 6, ang: a + (i % 2 ? 20 : -20), len: 20 + 16 * t, w: 18, shape: 'lance', fill: lf, shadeOp: 0.2, ribOp: 0.3, gloss: 0.15 }));
    }
  }
}

// ---------------------------------------------------------------------------
function olive(doc, t, bloom, r) {
  const bark = doc.lin([[0, '#a39784'], [0.5, '#6f6656'], [1, '#463f34']], { x1: 0, y1: 0.5, x2: 1, y2: 0.5 });
  const lf = doc.lin([[0, '#d3e0b8'], [0.5, '#8faa72'], [1, '#4e6a3c']], { x1: 0.3, y1: 0, x2: 0.7, y2: 1 });
  const H = 40 + 110 * t;
  const top = [CX + 4, SOIL_Y - H];
  const trunk = quad([CX, SOIL_Y + 2], [CX + 16 * t, SOIL_Y - H * 0.5], top);
  doc.add(limb(trunk, 5 + 8 * t, 3, bark));
  const tips = [top];
  if (t > 0.45) {
    for (const [u, dx, dy] of [[0.55, -40, -26], [0.7, 42, -20], [0.82, -22, -36]]) {
      const p = trunk.at(u);
      const e = [p.x + dx * t, p.y + dy * t];
      doc.add(limb(quad([p.x, p.y], [lerp(p.x, e[0], 0.5), p.y], e), 3 + 2 * t, 1.6, bark));
      tips.push(e);
    }
  }
  for (const [x, y] of tips) {
    const m = 14 + Math.round(t * 16);
    for (let i = 0; i < m; i++) {
      doc.add(leaf({ x: x + r.range(-16, 16) * t, y: y + r.range(-14, 10) * t, ang: r.range(-180, 0), len: 11 + 10 * t, w: 15, shape: 'lance', fill: lf, shadeOp: 0.18, ribOp: 0.2, rib: '#f2f6e8' }));
    }
    if (bloom) for (let i = 0; i < 5; i++) doc.add(ellipse(x + r.range(-14, 14), y + r.range(-6, 10), 2.8, 3.6, doc.radial([[0, '#7a8a4a'], [0.5, '#3b4a22'], [1, '#1d2410']], { cx: 0.35, cy: 0.3, r: 0.7 })));
  }
}

// ---------------------------------------------------------------------------
export const SPECIES = [
  { id: 'monstera', name: 'Monstera', latin: 'Monstera deliciosa', sprout: ['#7cc47e', '#3f8a4a'], final: 'Thriving', draw: monstera, care: 'Bright, indirect light', vibe: 'Bold & tropical' },
  { id: 'snake_plant', name: 'Snake Plant', latin: 'Dracaena trifasciata', sprout: ['#5f9a62', '#2a5b36'], final: 'Flowering', draw: snake, care: 'Thrives on neglect', vibe: 'Sharp & architectural' },
  { id: 'fiddle_leaf', name: 'Fiddle Leaf Fig', latin: 'Ficus lyrata', sprout: ['#6fb064', '#2d6c36'], final: 'Thriving', draw: fiddle, care: 'Steady light, no drafts', vibe: 'Statement tree' },
  { id: 'echeveria', name: 'Echeveria', latin: 'Echeveria elegans', sprout: ['#a6cfc2', '#5e8f86'], final: 'Flowering', draw: echeveria, care: 'Sun & sparse water', vibe: 'Soft geometry' },
  { id: 'cactus', name: 'Saguaro Cactus', latin: 'Carnegiea gigantea', sprout: ['#7cb56e', '#2d6038'], final: 'Flowering', draw: cactus, care: 'Full sun, very dry', vibe: 'Desert icon' },
  { id: 'fern', name: 'Boston Fern', latin: 'Nephrolepis exaltata', sprout: ['#b6e07c', '#4f9a35'], final: 'Lush', draw: fern, care: 'Humid & shaded', vibe: 'Feathery & lush' },
  { id: 'bonsai', name: 'Juniper Bonsai', latin: 'Juniperus procumbens', sprout: ['#8fc062', '#3f7a34'], final: 'Thriving', draw: bonsai, care: 'Patience, daily care', vibe: 'Calm & ancient' },
  { id: 'sunflower', name: 'Sunflower', latin: 'Helianthus annuus', sprout: ['#9fd06a', '#4e8a31'], final: 'Blooming', draw: sunflower, care: 'All the sun', vibe: 'Pure optimism' },
  { id: 'tulip', name: 'Tulip', latin: 'Tulipa gesneriana', sprout: ['#a5cf98', '#5c9467'], final: 'Blooming', draw: tulip, care: 'Cool spring light', vibe: 'Bright & cheerful' },
  { id: 'lavender', name: 'Lavender', latin: 'Lavandula angustifolia', sprout: ['#c3d6bd', '#6f8f72'], final: 'Blooming', draw: lavender, care: 'Sun & good drainage', vibe: 'Calm & fragrant' },
  { id: 'cherry_blossom', name: 'Cherry Blossom', latin: 'Prunus serrulata', sprout: ['#a8d67a', '#5f9e45'], final: 'Blooming', draw: cherry, care: 'Seasonal rhythm', vibe: 'Fleeting beauty' },
  { id: 'peace_lily', name: 'Peace Lily', latin: 'Spathiphyllum wallisii', sprout: ['#5fae6e', '#1f5e35'], final: 'Blooming', draw: peaceLily, care: 'Low light friendly', vibe: 'Serene & glossy' },
  { id: 'aloe', name: 'Aloe Vera', latin: 'Aloe barbadensis', sprout: ['#b6d9a8', '#5c8f5c'], final: 'Flowering', draw: aloe, care: 'Bright & dry', vibe: 'Healing spikes' },
  { id: 'rose', name: 'Garden Rose', latin: 'Rosa × hybrida', sprout: ['#7fb85a', '#3b6d2c'], final: 'Blooming', draw: rose, care: 'Sun & attention', vibe: 'Romantic classic' },
  { id: 'bird_of_paradise', name: 'Bird of Paradise', latin: 'Strelitzia reginae', sprout: ['#9cc9a2', '#4f8c66'], final: 'Blooming', draw: birdOfParadise, care: 'Bright light, warmth', vibe: 'Exotic flair' },
  { id: 'calathea', name: 'Calathea', latin: 'Goeppertia roseopicta', sprout: ['#7fb07f', '#2f5a3a'], final: 'Thriving', draw: calathea, care: 'Humidity & shade', vibe: 'Painted leaves' },
  { id: 'pothos', name: 'Golden Pothos', latin: 'Epipremnum aureum', sprout: ['#a5d66b', '#4f9a3a'], final: 'Cascading', draw: pothos, front: pothosFront, care: 'Any light, easy', vibe: 'Easygoing trailer' },
  { id: 'lucky_bamboo', name: 'Lucky Bamboo', latin: 'Dracaena sanderiana', sprout: ['#b4e07a', '#5ea23e'], final: 'Flourishing', draw: bamboo, care: 'Indirect light', vibe: 'Good fortune' },
  { id: 'olive', name: 'Olive Tree', latin: 'Olea europaea', sprout: ['#c9d6b0', '#7f9670'], final: 'Fruiting', draw: olive, care: 'Sun & warmth', vibe: 'Mediterranean calm' },
];
