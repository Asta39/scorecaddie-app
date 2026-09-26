// Renders every achievement: <id>.png (earned, idle still), <id>_locked.png
// (asleep still) and frames for <id>_win (hopping loop) into ./ach/.
import { createCanvas, Path2D, ImageData } from '@napi-rs/canvas';
import fs from 'node:fs';
globalThis.Path2D = Path2D; globalThis.ImageData = ImageData;
globalThis.OffscreenCanvas = class { constructor(w, h) { return createCanvas(w, h); } };
globalThis.document = { createElement: () => createCanvas(1, 1) };
const { BotAvatarSim, drawBotAvatarFrame, autoInk, BOT_AVATAR_OVERSCAN, warmBotAvatarPlastic } = await import('bot-avatars');
const { SHAPES } = await import('./shapes.mjs');
const { CATALOG } = await import('./catalog.mjs');
const only = process.argv[2];
fs.mkdirSync('ach', { recursive: true });
const cfgFor = (a, px, dpr) => {
  const sh = SHAPES[a.shape], key = 'sc-' + a.shape + '-' + px;
  const cfg = { path: new Path2D(sh.d), parts: sh.parts ? new Path2D(sh.parts) : undefined, partsDepth: 0.5, face: 'mouth',
    faceX: sh.faceX ?? 50, faceY: sh.faceY ?? 50, faceScale: sh.faceScale ?? 0.7, color: a.color, ink: autoInk(a.color),
    shading: 'plastic', dpr, sides: 'vector', typeKey: key, still: true };
  warmBotAvatarPlastic(key, cfg.path, px);
  return cfg;
};
const frame = (cfg, box, dpr, pose) => {
  const px = Math.round(box * BOT_AVATAR_OVERSCAN * dpr);
  const c = createCanvas(px, px); const ctx = c.getContext('2d'); ctx.scale(dpr, dpr);
  drawBotAvatarFrame(ctx, box, pose, cfg); return c.toBuffer('image/png');
};
CATALOG.filter((a) => !only || a.id === only).forEach((a, i) => {
  // Stills for the grid: 64pt box at 2x.
  const sBox = 64, sPx = Math.round(sBox * BOT_AVATAR_OVERSCAN * 2), sCfg = cfgFor(a, sPx, 2);
  let sim = new BotAvatarSim(0.37, 'default'); sim.setTurn?.(0.3);
  for (let k = 0; k < 26; k++) sim.update(1 / 24);
  fs.writeFileSync(`ach/${a.id}.png`, frame(sCfg, sBox, 2, sim.pose));
  sim = new BotAvatarSim(0.37, 'sleeping');
  for (let k = 0; k < 60; k++) sim.update(1 / 24);
  fs.writeFileSync(`ach/${a.id}_locked.png`, frame(sCfg, sBox, 2, sim.pose));
  // Celebration loop for the unlock sheet: 96pt box at 2x, 2.6 s at 15 fps.
  const wBox = 96, wPx = Math.round(wBox * BOT_AVATAR_OVERSCAN * 2), wCfg = cfgFor(a, wPx, 2);
  sim = new BotAvatarSim(0.2 + (i % 7) * 0.1, 'working');
  for (let k = 0; k < 20; k++) sim.update(1 / 15);
  const dir = `ach/${a.id}_win`; fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir);
  for (let k = 0; k < 39; k++) { sim.update(1 / 15); fs.writeFileSync(`${dir}/f${String(k).padStart(3, '0')}.png`, frame(wCfg, wBox, 2, sim.pose)); }
});
console.log('ok');
