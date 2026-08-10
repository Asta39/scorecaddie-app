#!/usr/bin/env python3
"""
Validator for scraped Kenyan golf course scorecard data.

The data this replaces was synthetic: seed_courses.dart set the stroke index
to the hole number (SI 1,2,3...18 in play order) and its own header admitted
the yardages were estimates. Because this data feeds WHS handicap maths, a
scraped replacement is only an improvement if it is actually verified — so
nothing enters the app without passing every HARD check below.

Sources disagree in practice (18Birdies had Muthaiga's blue tee at 7228 yds,
Golfshake at 7143), which is exactly what these checks exist to surface.

Usage:
    python3 validate_courses.py courses.json
Exit code 0 = every course passed and is safe to import.
"""

import json
import sys
from typing import Any

# A hole outside these bounds is almost certainly a parse error or a
# metres/yards mix-up rather than a real hole.
PAR_BOUNDS = {3: (100, 260), 4: (230, 500), 5: (420, 660)}
MIN_TOTAL_YARDS, MAX_TOTAL_YARDS = 4500, 7800


class Issue:
    def __init__(self, course: str, level: str, message: str):
        self.course, self.level, self.message = course, level, message

    def __str__(self) -> str:
        return f"[{self.level}] {self.course}: {self.message}"


def validate_course(c: dict[str, Any]) -> list[Issue]:
    name = c.get("name", "<unnamed>")
    issues: list[Issue] = []

    def hard(msg: str) -> None:
        issues.append(Issue(name, "HARD", msg))

    def warn(msg: str) -> None:
        issues.append(Issue(name, "WARN", msg))

    holes = c.get("holes") or []
    expected = c.get("total_holes", 18)

    if len(holes) != expected:
        hard(f"expected {expected} holes, got {len(holes)}")
        return issues

    # ── Hole numbering ──────────────────────────────────────────
    numbers = [h.get("hole") for h in holes]
    if sorted(numbers) != list(range(1, expected + 1)):
        hard(f"hole numbers are not exactly 1..{expected}: {numbers}")

    # ── Par ─────────────────────────────────────────────────────
    pars = [h.get("par") for h in holes]
    if any(p not in (3, 4, 5, 6) for p in pars):
        hard(f"par values outside 3-6: {pars}")
    total_par = sum(p for p in pars if isinstance(p, int))
    declared_par = c.get("par")
    if declared_par is not None and total_par != declared_par:
        hard(f"hole pars sum to {total_par} but course par is {declared_par}")

    # ── Stroke index ────────────────────────────────────────────
    # This is the check that would have caught the old data outright:
    # SI == hole number is a placeholder, never a real allocation.
    sis = [h.get("si") for h in holes]
    if sorted(sis) != list(range(1, expected + 1)):
        hard(f"stroke indices are not a permutation of 1..{expected}: {sis}")
    elif sis == list(range(1, expected + 1)):
        hard("stroke index equals hole number for every hole — placeholder data, not a real allocation")

    if expected == 18 and sorted(sis) == list(range(1, 19)):
        front_odd = sum(1 for s in sis[:9] if s % 2 == 1)
        # Convention (not a rule): one nine takes the odds, the other evens.
        # 9/0 or 0/9 is normal; anything near an even split is suspicious.
        if front_odd not in (0, 9):
            warn(f"stroke indices not split odd/even across the nines (front nine has {front_odd} odd) — verify against the official card")

    # ── Tees / yardages ─────────────────────────────────────────
    tees = c.get("tees") or []
    if not tees:
        hard("no tees defined")

    for tee in tees:
        tname = tee.get("name", "<unnamed tee>")
        yards = tee.get("yardages") or []
        if len(yards) != expected:
            hard(f"tee '{tname}' has {len(yards)} yardages, expected {expected}")
            continue
        if any(not isinstance(y, int) or y <= 0 for y in yards):
            hard(f"tee '{tname}' has non-positive or non-integer yardages")
            continue

        total = sum(yards)
        if not (MIN_TOTAL_YARDS <= total <= MAX_TOTAL_YARDS):
            hard(f"tee '{tname}' totals {total} yds — outside plausible range")

        declared_total = tee.get("total")
        if declared_total and abs(total - declared_total) > 25:
            hard(f"tee '{tname}' hole yardages sum to {total} but card states {declared_total}")

        for h, y in zip(holes, yards):
            par = h.get("par")
            if par in PAR_BOUNDS:
                lo, hi = PAR_BOUNDS[par]
                if not (lo <= y <= hi):
                    warn(f"tee '{tname}' hole {h.get('hole')}: par {par} at {y} yds is outside typical {lo}-{hi} — verify (possible metres/yards mix-up)")

    # ── Provenance ──────────────────────────────────────────────
    # Anything without at least two agreeing sources stays unverified and is
    # excluded from official handicap posting by the app.
    sources = c.get("sources") or []
    if len(sources) < 2:
        warn(f"only {len(sources)} source(s) — needs a second corroborating source before it can be marked verified")

    return issues


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    with open(sys.argv[1]) as f:
        data = json.load(f)

    courses = data if isinstance(data, list) else data.get("courses", [])
    all_issues: list[Issue] = []
    for c in courses:
        all_issues.extend(validate_course(c))

    hard = [i for i in all_issues if i.level == "HARD"]
    warns = [i for i in all_issues if i.level == "WARN"]

    for i in all_issues:
        print(i)

    passed = len(courses) - len({i.course for i in hard})
    print(f"\n{len(courses)} course(s): {passed} passed, "
          f"{len({i.course for i in hard})} failed, "
          f"{len(hard)} hard error(s), {len(warns)} warning(s)")

    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
