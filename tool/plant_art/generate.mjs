// Generates every plant + pot SVG used by the Verdant app.
//   node tool/plant_art/generate.mjs            -> writes into assets/
// Re-run after tweaking species.mjs; output is deterministic.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { Doc, CX, SOIL_Y, f, leaf, quad, stem, ellipse, circle, rng } from './lib.mjs';
import { SPECIES } from './species.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../..');
const OUT = path.join(root, 'assets');

export const STAGES = [
  { name: 'Seed', t: 0 },
  { name: 'Sprout', t: 0.12 },
  { name: 'Seedling', t: 0.32 },
  { name: 'Growing', t: 0.58 },
  { name: 'Mature', t: 0.82 },
  { name: 'Final', t: 1 },
];

function seedStage(doc) {
  // little mound + seed with a split and a peeking root tip
  doc.add(ellipse(CX, SOIL_Y + 1, 18, 5, '#3a2618', ' fill-opacity="0.55"'));
  const g = doc.radial([[0, '#c89a6a'], [0.6, '#8a5e3a'], [1, '#5b3a22']], { cx: 0.35, cy: 0.3, r: 0.75 });
  doc.add(`<g transform="rotate(-18 ${CX} ${SOIL_Y - 4})">${ellipse(CX, SOIL_Y - 4, 9, 6, g)}<path d="M${CX - 6},${SOIL_Y - 4} Q${CX},${SOIL_Y - 6} ${CX + 7},${SOIL_Y - 3}" fill="none" stroke="#3b2414" stroke-opacity="0.5" stroke-width="0.9"/></g>`);
  doc.add(`<path d="M${CX + 6},${SOIL_Y - 9} q4,-5 9,-4" fill="none" stroke="#a8d877" stroke-width="2" stroke-linecap="round"/>`);
}

function sproutStage(doc, sp) {
  const [light, dark] = sp.sprout;
  const fill = doc.lin([[0, light], [1, dark]], { x1: 0.3, y1: 0, x2: 0.7, y2: 1 });
  const c = quad([CX, SOIL_Y], [CX - 6, SOIL_Y - 14], [CX + 1, SOIL_Y - 26]);
  doc.add(stem(c, 2.4, dark, { hlOp: 0.25 }));
  doc.add(leaf({ x: CX + 1, y: SOIL_Y - 26, ang: -150, len: 15, w: 40, shape: 'ovate', fill, shadeOp: 0.18, ribOp: 0.3 }));
  doc.add(leaf({ x: CX + 1, y: SOIL_Y - 26, ang: -28, len: 16, w: 40, shape: 'ovate', fill, shadeOp: 0.18, ribOp: 0.3 }));
  doc.add(leaf({ x: CX + 1, y: SOIL_Y - 27, ang: -88, len: 7, w: 30, shape: 'lance', fill: light, shadeOp: 0.1, ribOp: 0 }));
}

function hash(s) {
  let h = 2166136261;
  for (const ch of s) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return h >>> 0;
}

function plantSvgs(sp, stageIdx) {
  const doc = new Doc();
  const st = STAGES[stageIdx];
  if (stageIdx === 0) seedStage(doc);
  else if (stageIdx === 1) sproutStage(doc, sp);
  else sp.draw(doc, st.t, stageIdx === 5, rng(hash(sp.id + stageIdx)));
  let front = null;
  if (sp.front && stageIdx >= 2) {
    const fd = new Doc();
    sp.front(fd, st.t, stageIdx === 5, rng(hash(sp.id + 'front' + stageIdx)));
    if (fd.els.length) front = fd.toString();
  }
  return { main: doc.toString(), front };
}

// ---------------------------------------------------------------------------
// Pots (each produces a back + front layer)
export const POTS = [
  { id: 'terracotta', name: 'Terracotta', rim: '#e09468', side: ['#e08c5c', '#c96a3c', '#8c4222'], body: ['#a9532c', '#df8b5b', '#c46a3e', '#7e3a1d'] },
  { id: 'ivory', name: 'Ivory Ceramic', rim: '#fbf8f1', side: ['#f6f2e9', '#e3ddd0', '#bdb5a6'], body: ['#d2cbbd', '#fbf8f2', '#ece6da', '#b3ab9c'] },
  { id: 'stone', name: 'Concrete', rim: '#c9c6bf', side: ['#c4c1ba', '#a9a59d', '#7c7870'], body: ['#8e8a82', '#c9c5bd', '#aaa69e', '#6f6b64'], speckle: true },
  { id: 'sage', name: 'Sage Glaze', rim: '#b9cdb4', side: ['#b2c8ac', '#93ad8d', '#647d60'], body: ['#6f8a6a', '#b6cdb0', '#97b291', '#58704f'], glaze: true },
  { id: 'midnight', name: 'Midnight', rim: '#3b4660', side: ['#3a455e', '#2a3348', '#151b28'], body: ['#1c2333', '#4a5675', '#2c3549', '#121722'], glaze: true },
  { id: 'blush', name: 'Blush', rim: '#f4cfc4', side: ['#efc6ba', '#dfa999', '#b67c6d'], body: ['#c98f80', '#f3cfc4', '#e3ad9e', '#a96f61'] },
];

function potBack(p) {
  const d = new Doc();
  d.add(ellipse(CX, 297, 64, 5, '#000000', ' fill-opacity="0.16"'));
  d.add(ellipse(CX, 238, 64, 11, p.rim));
  d.add(ellipse(CX, 239, 57, 8.5, d.lin([[0, '#1b120c'], [1, '#3a2a1f']])));
  d.add(ellipse(CX, 241, 55, 7, d.radial([[0, '#6b4a33'], [0.7, '#4a3222'], [1, '#2e1f15']], { cx: 0.45, cy: 0.35, r: 0.7 })));
  const r = rng(hash(p.id));
  let peb = '';
  for (let i = 0; i < 26; i++) {
    const a = r.range(0, Math.PI * 2);
    const rr = Math.sqrt(r());
    peb += `M${f(CX + Math.cos(a) * 48 * rr)},${f(241 + Math.sin(a) * 5.5 * rr)} l0.1,0 `;
  }
  d.add(`<path d="${peb}" stroke="#8c6a4f" stroke-opacity="0.8" stroke-width="1.5" stroke-linecap="round"/>`);
  return d.toString();
}

function potFront(p) {
  const d = new Doc();
  const body = d.lin(p.body.map((c, i) => [[0, 0.28, 0.55, 1][i], c]), { x1: 58, y1: 0, x2: 182, y2: 0, user: true });
  const side = d.lin(p.side.map((c, i) => [[0, 0.5, 1][i], c]), { x1: 0.5, y1: 0, x2: 0.5, y2: 1 });
  d.add(`<path d="M60,249 L69,291 Q70.5,297 77,297 L163,297 Q169.5,297 171,291 L180,249 Z" fill="${body}"/>`);
  if (p.speckle) {
    const r = rng(7);
    let s = '';
    for (let i = 0; i < 90; i++) s += `M${f(r.range(66, 174))},${f(r.range(254, 294))} l0.1,0 `;
    d.add(`<path d="${s}" stroke="#4d4a44" stroke-opacity="0.35" stroke-width="1.2" stroke-linecap="round"/>`);
  }
  if (p.glaze) {
    d.add(`<path d="M62,262 Q90,270 120,266 T178,262 L176,276 Q150,282 120,278 T65,276 Z" fill="#ffffff" fill-opacity="0.07"/>`);
  }
  // subtle bottom shade + vertical highlight
  d.add(`<path d="M66,282 L69,291 Q70.5,297 77,297 L163,297 Q169.5,297 171,291 L174,282 Z" fill="#000000" fill-opacity="0.12"/>`);
  d.add(`<rect x="82" y="254" width="5" height="38" rx="2.5" fill="#ffffff" fill-opacity="0.16"/>`);
  // rim band + front crescent
  d.add(`<path d="M56,238 A64,11 0 0 0 184,238 L184,250 A64,11 0 0 1 56,250 Z" fill="${side}"/>`);
  d.add(`<path d="M56,238 A64,11 0 0 0 184,238 L177,239 A57,8.5 0 0 1 63,239 Z" fill="${p.rim}"/>`);
  d.add(`<path d="M60,252 A64,11 0 0 0 180,252" fill="none" stroke="#000000" stroke-opacity="0.18" stroke-width="2"/>`);
  d.add(`<path d="M70,244 A60,9 0 0 0 110,249.6" fill="none" stroke="#ffffff" stroke-opacity="0.3" stroke-width="1.4" stroke-linecap="round"/>`);
  return d.toString();
}

// ---------------------------------------------------------------------------
function main() {
  const plantsDir = path.join(OUT, 'plants');
  const potsDir = path.join(OUT, 'pots');
  fs.rmSync(plantsDir, { recursive: true, force: true });
  fs.rmSync(potsDir, { recursive: true, force: true });
  fs.mkdirSync(plantsDir, { recursive: true });
  fs.mkdirSync(potsDir, { recursive: true });
  let bytes = 0;
  const manifest = { species: [], pots: [] };
  for (const sp of SPECIES) {
    const dir = path.join(plantsDir, sp.id);
    fs.mkdirSync(dir, { recursive: true });
    let hasFront = false;
    for (let i = 0; i < STAGES.length; i++) {
      const { main: m, front } = plantSvgs(sp, i);
      fs.writeFileSync(path.join(dir, `stage_${i}.svg`), m);
      bytes += m.length;
      if (front) {
        fs.writeFileSync(path.join(dir, `stage_${i}_front.svg`), front);
        hasFront = true;
      }
    }
    manifest.species.push({ id: sp.id, name: sp.name, latin: sp.latin, final: sp.final, care: sp.care, vibe: sp.vibe, hasFront });
  }
  for (const p of POTS) {
    fs.writeFileSync(path.join(potsDir, `${p.id}_back.svg`), potBack(p));
    fs.writeFileSync(path.join(potsDir, `${p.id}_front.svg`), potFront(p));
    manifest.pots.push({ id: p.id, name: p.name });
  }
  fs.writeFileSync(path.join(here, 'manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(`species=${SPECIES.length} stages=${STAGES.length} totalPlantBytes=${(bytes / 1024).toFixed(0)}KB`);
}
main();
