// Contact sheet: every achievement avatar, idle, labelled. node contact.mjs [state]
import { createCanvas, Path2D, ImageData } from '@napi-rs/canvas';
import fs from 'node:fs';
globalThis.Path2D = Path2D; globalThis.ImageData = ImageData;
globalThis.OffscreenCanvas = class { constructor(w, h) { return createCanvas(w, h); } };
globalThis.document = { createElement: () => createCanvas(1, 1) };
const { BotAvatarSim, drawBotAvatarFrame, autoInk, BOT_AVATAR_OVERSCAN, warmBotAvatarPlastic } = await import('bot-avatars');
const { SHAPES } = await import('./shapes.mjs');
const { CATALOG } = await import('./catalog.mjs');

const state = process.argv[2] || 'default';
const box = 90, dpr = 1, px = Math.round(box * BOT_AVATAR_OVERSCAN * dpr), cols = 10, cellH = px + 26;
const rows = Math.ceil(CATALOG.length / cols);
const sheet = createCanvas(px * cols, cellH * rows); const s = sheet.getContext('2d');
s.fillStyle = '#06110b'; s.fillRect(0, 0, sheet.width, sheet.height);
CATALOG.forEach((a, i) => {
  const sh = SHAPES[a.shape];
  if (!sh) throw new Error('no shape ' + a.shape);
  const key = 'sc-' + a.shape;
  const cfg = { path: new Path2D(sh.d), parts: sh.parts ? new Path2D(sh.parts) : undefined, partsDepth: 0.5, face: 'mouth',
    faceX: sh.faceX ?? 50, faceY: sh.faceY ?? 50, faceScale: sh.faceScale ?? 0.7, color: a.color, ink: autoInk(a.color),
    shading: 'plastic', dpr, sides: 'vector', typeKey: key, still: true };
  warmBotAvatarPlastic(key, cfg.path, px);
  const sim = new BotAvatarSim(0.37, state);
  sim.setTurn?.(0.3);
  for (let k = 0; k < 24 * 1.1; k++) sim.update(1 / 24);
  const c = createCanvas(px, px); const ctx = c.getContext('2d'); ctx.scale(dpr, dpr);
  drawBotAvatarFrame(ctx, box, sim.pose, cfg);
  const x = (i % cols) * px, y = Math.floor(i / cols) * cellH;
  s.drawImage(c, x, y);
  s.fillStyle = a.isNew ? '#a3e635' : 'rgba(244,247,242,.75)'; s.font = '600 11px sans-serif'; s.textAlign = 'center';
  s.fillText(a.title, x + px / 2, y + px + 14);
});
fs.writeFileSync(`contact-${state}.png`, sheet.toBuffer('image/png'));
console.log('ok', CATALOG.length);
