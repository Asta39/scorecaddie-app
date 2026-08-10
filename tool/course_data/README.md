# Course scorecard data pipeline

## Why this exists

The scorecard data originally shipped in `lib/core/database/seed_courses.dart`
was synthetic:

- `handicapIndex` was set to the hole number, so every course read
  SI `1,2,3…18` in play order. A real stroke index is allocated by hole
  difficulty (conventionally odds on one nine, evens on the other), so this was
  wrong for **every** course.
- The file header stated outright: *"Uses verified data where available,
  estimates where not."* The yardages were the estimates — each tee was a
  uniform offset from the next, a pattern no surveyed course produces.
- Pars were wrong too. Seeded Muthaiga front nine was `[4,4,3,5,4,3,4,4,4]`;
  the real card is `[4,3,4,5,3,4,5,4,4]`.

Because this data feeds WHS handicap maths, replacing it is only an
improvement if the replacement is actually verified. Hence this pipeline.

## Sourcing

The Kenya Golf Union does **not** publish scorecard data. Its
[golf courses page](https://kenyagolfunion.org/golf-courses/) lists 48 clubs
with names and website links only; the sole numeric downloads are WHS
conversion charts. There is no KGU dataset to scrape.

Availability of the third-party sources actually tested:

| Source | Hole-level data? | Notes |
|---|---|---|
| 18Birdies | Yes | Full 18 holes with par + SI; only one tee's per-hole yardages exposed |
| Golfshake | No | Tee totals and SSS only |
| mScorecard | No | HTTP 403 |
| ProVisualizer | No | Data sits behind interactive planners |

Sources disagree: 18Birdies puts Muthaiga's blue tee at 7228 yds, Golfshake at
7143. **Two corroborating sources are required before a course is marked
verified.**

Scraping these sites is the project owner's decision; their terms generally
restrict bulk extraction and redistribution. Be conservative: rate-limit,
don't hammer, and prefer official club cards where obtainable.

## Format

`courses.json` — one entry per course:

```jsonc
{
  "name": "Muthaiga Golf Club",
  "total_holes": 18,
  "par": 71,
  "verified": false,          // only true with >=2 agreeing sources
  "sources": ["https://..."],
  "holes": [ {"hole": 1, "par": 4, "si": 3}, ... ],
  "tees":  [ {"name": "Blue", "gender": "men", "total": 7228,
              "yardages": [442, 220, ...]} ]
}
```

## Validating

```bash
python3 validate_courses.py courses.json
```

Exit code 0 means every course passed and is safe to import.

**HARD** failures block import:
- hole numbers not exactly 1..N
- pars outside 3–6, or not summing to the course par
- stroke indices not a permutation of 1..N
- **stroke index equal to hole number on every hole** (catches the original bug)
- yardage count mismatch, non-positive yardages, implausible tee totals,
  or hole yardages not summing to the stated tee total (±25)

**WARN** flags need a human look but don't block:
- SI not split odd/even across the nines
- a hole's yardage far outside the typical range for its par (usually a
  metres/yards mix-up)
- fewer than two sources

The file ships with a deliberate control entry containing the *old* seed data.
It must always fail. If it ever passes, the validator is broken.

## Importing

Nothing is deleted. New data is written alongside and only rows that pass
validation flip `Course.dataVerified` to true, with `Course.dataSource`
recording provenance (`official-card`, `scraped:18birdies`, `estimated`).
Courses left unverified keep a null `handicapIndex` rather than a fabricated
one — an honest "unknown" beats a plausible-looking wrong number.
