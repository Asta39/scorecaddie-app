# Achievement avatars

Every achievement has its own animated character, drawn by us and rendered with
the [bot-avatars](https://www.npmjs.com/package/bot-avatars) renderer (MIT; see
`assets/bots/bot-avatars-LICENSE.txt`). The app ships three files per
achievement in `assets/achievements/`:

| File | What it is |
|---|---|
| `<id>.webp` | Still, idle pose: the badge once earned |
| `<id>_locked.webp` | Still, asleep: the badge before it's earned (grey it out in the UI) |
| `<id>_win.webp` | Animated loop, hopping: the unlock celebration |

- `shapes.mjs`: the outlines, each in the renderer's 100×100 body box, with
  optional thin parts (handles, shafts) and where the face sits.
- `catalog.mjs`: every achievement with its copy, category, points, outline
  and colour. `bronze`, `silver` and `gold` give tiers of one outline.
- `lib/core/models/achievement_model.dart` mirrors the catalog; keep the ids
  in step.

## Adding an achievement

1. Add a row to `catalog.mjs`: reuse an outline in a new colour or tier, or
   draw a new one in `shapes.mjs` with `rpoly`, `blob`, `circle`, `capsule`.
2. `npm install`, then `npm run sheet` and check `contact-default.png`.
3. `npm run render` (needs `brew install webp`).
4. Add the achievement to `achievement_model.dart` and its rule to
   `AchievementService`.
