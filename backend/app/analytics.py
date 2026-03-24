"""
Compute rich analytics from ball-by-ball Delivery rows.

All functions accept an innings_id (primary key) and an async SQLAlchemy session.
"""

import random
from collections import defaultdict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Delivery


# ── Batting Scorecard ─────────────────────────────────────────────────────────

async def batting_scorecard(innings_id: int, session: AsyncSession) -> list[dict]:
    rows = (await session.execute(
        select(Delivery)
        .where(Delivery.innings_id == innings_id)
        .order_by(Delivery.over_number, Delivery.ball_number)
    )).scalars().all()

    batters: dict[str, dict] = {}
    order: list[str] = []

    for d in rows:
        if d.batter not in batters:
            batters[d.batter] = {"runs": 0, "balls": 0, "fours": 0, "sixes": 0, "dismissal": None}
            order.append(d.batter)
        b = batters[d.batter]
        if d.extra_type not in ("wide", "noball"):
            b["balls"] += 1
        b["runs"]  += d.runs_batter
        if d.runs_batter == 4:  b["fours"] += 1
        if d.runs_batter == 6:  b["sixes"] += 1
        if d.is_wicket and d.player_out == d.batter:
            b["dismissal"] = d.wicket_kind

    return [
        {
            "batsman":      name,
            "runs":         s["runs"],
            "balls":        s["balls"],
            "fours":        s["fours"],
            "sixes":        s["sixes"],
            "strike_rate":  round(s["runs"] / s["balls"] * 100, 1) if s["balls"] else 0.0,
            "dismissal":    s["dismissal"],   # None = not out
        }
        for name in order
        for s in [batters[name]]
    ]


# ── Bowling Scorecard ─────────────────────────────────────────────────────────

# Dismissals that don't credit the bowler
_NOT_BOWLER_WICKET = {"run out", "retired hurt", "obstructing the field", "handled the ball"}

async def bowling_scorecard(innings_id: int, session: AsyncSession) -> list[dict]:
    rows = (await session.execute(
        select(Delivery)
        .where(Delivery.innings_id == innings_id)
        .order_by(Delivery.over_number, Delivery.ball_number)
    )).scalars().all()

    bowlers: dict[str, dict] = {}
    order: list[str] = []

    for d in rows:
        if d.bowler not in bowlers:
            bowlers[d.bowler] = {"balls": 0, "runs": 0, "wickets": 0, "over_runs": defaultdict(int)}
            order.append(d.bowler)
        b = bowlers[d.bowler]
        if d.extra_type not in ("wide", "noball"):
            b["balls"] += 1
        b["runs"] += d.runs_total
        b["over_runs"][d.over_number] += d.runs_total
        if d.is_wicket and d.wicket_kind not in _NOT_BOWLER_WICKET:
            b["wickets"] += 1

    return [
        {
            "bowler":   name,
            "overs":    f"{s['balls'] // 6}.{s['balls'] % 6}",
            "maidens":  sum(1 for r in s["over_runs"].values() if r == 0),
            "runs":     s["runs"],
            "wickets":  s["wickets"],
            "economy":  round(s["runs"] / (s["balls"] / 6), 2) if s["balls"] else 0.0,
        }
        for name in order
        for s in [bowlers[name]]
    ]


# ── Over-by-Over Run Chart ────────────────────────────────────────────────────

async def over_data(innings_id: int, session: AsyncSession) -> list[dict]:
    rows = (await session.execute(
        select(Delivery)
        .where(Delivery.innings_id == innings_id)
        .order_by(Delivery.over_number, Delivery.ball_number)
    )).scalars().all()

    by_over: dict[int, dict] = defaultdict(lambda: {"runs": 0, "wickets": 0})
    for d in rows:
        by_over[d.over_number]["runs"]    += d.runs_total
        if d.is_wicket:
            by_over[d.over_number]["wickets"] += 1

    cumulative = 0
    result = []
    for over_num in sorted(by_over):
        o = by_over[over_num]
        cumulative += o["runs"]
        result.append({
            "over":             over_num + 1,
            "runs":             o["runs"],
            "wickets":          o["wickets"],
            "cumulative_runs":  cumulative,
        })
    return result


# ── Wagon Wheel ───────────────────────────────────────────────────────────────
#
# CricSheets gives us the EXACT runs per delivery (which ball was a 4, which a 6,
# which a single) — far superior to CricAPI's aggregate totals.
# Angles remain synthetic but are more informed: we use over position, run value,
# and a deterministic seed per delivery for reproducibility.

def _angle(runs: int, over: int, ball: int, seed: int) -> float:
    """Return a cricket-realistic angle (0 = straight/top, clockwise)."""
    rng = random.Random(seed)

    if runs == 6:
        # Sixes cluster toward mid-wicket (220-270°), long-on (250-290°),
        # long-off (60-100°), and over cover (40-80°)
        zones = [(220, 280), (60, 100), (280, 320), (30, 60)]
    elif runs == 4:
        # Fours: cover (40-80°), point (10-50°), mid-wicket (210-260°),
        # straight (320-360°), fine leg (150-180°)
        zones = [(40, 80), (10, 50), (210, 260), (320, 360), (150, 180)]
    elif runs in (2, 3):
        # Any direction, slight off-side bias
        zones = [(0, 160), (200, 360)]
    else:
        # Singles: any direction
        zones = [(0, 360)]

    lo, hi = rng.choice(zones)
    return rng.uniform(lo, hi) % 360


def _distance(runs: int, rng: random.Random) -> float:
    if runs == 6:   return rng.uniform(0.95, 1.0)
    if runs == 4:   return rng.uniform(0.78, 0.95)
    if runs in (2, 3): return rng.uniform(0.38, 0.68)
    return rng.uniform(0.15, 0.55)


async def wagon_wheel(
    innings_id: int,
    session: AsyncSession,
    batter: str | None = None,
) -> list[dict]:
    query = (
        select(Delivery)
        .where(Delivery.innings_id == innings_id, Delivery.runs_batter > 0)
    )
    if batter:
        query = query.where(Delivery.batter == batter)
    query = query.order_by(Delivery.over_number, Delivery.ball_number)

    rows = (await session.execute(query)).scalars().all()

    shots = []
    for i, d in enumerate(rows):
        seed = d.innings_id * 1000000 + d.over_number * 1000 + d.ball_number
        rng  = random.Random(seed)
        shots.append({
            "angle":    _angle(d.runs_batter, d.over_number, d.ball_number, seed),
            "distance": _distance(d.runs_batter, rng),
            "runs":     d.runs_batter,
            "batter":   d.batter,
            "bowler":   d.bowler,
            "over":     d.over_number + 1,
            "ball":     d.ball_number + 1,
        })
    return shots


# ── Partnerships ──────────────────────────────────────────────────────────────

async def partnerships(innings_id: int, session: AsyncSession) -> list[dict]:
    rows = (await session.execute(
        select(Delivery)
        .where(Delivery.innings_id == innings_id)
        .order_by(Delivery.over_number, Delivery.ball_number)
    )).scalars().all()

    parts: list[dict] = []
    current: dict | None = None

    for d in rows:
        pair = tuple(sorted([d.batter, d.non_striker]))
        if current is None or current["pair"] != pair:
            if current:
                parts.append(current)
            current = {
                "pair":        pair,
                "batter1":     d.batter,
                "batter2":     d.non_striker,
                "runs":        0,
                "balls":       0,
                "ended_by":    None,
            }
        current["runs"] += d.runs_batter
        if d.extra_type not in ("wide", "noball"):
            current["balls"] += 1
        if d.is_wicket:
            current["ended_by"] = d.wicket_kind

    if current:
        parts.append(current)

    return [
        {
            "batter1":  p["batter1"],
            "batter2":  p["batter2"],
            "runs":     p["runs"],
            "balls":    p["balls"],
            "ended_by": p["ended_by"],
        }
        for p in parts
    ]


# ── Fall of Wickets ───────────────────────────────────────────────────────────

async def fall_of_wickets(innings_id: int, session: AsyncSession) -> list[dict]:
    rows = (await session.execute(
        select(Delivery)
        .where(Delivery.innings_id == innings_id, Delivery.is_wicket == True)
        .order_by(Delivery.over_number, Delivery.ball_number)
    )).scalars().all()

    # We need cumulative runs at each wicket — fetch all deliveries once
    all_rows = (await session.execute(
        select(Delivery)
        .where(Delivery.innings_id == innings_id)
        .order_by(Delivery.over_number, Delivery.ball_number)
    )).scalars().all()

    cumulative = 0
    wicket_idx = 0
    wicket_ids = {d.id for d in rows}
    fow: list[dict] = []

    for d in all_rows:
        cumulative += d.runs_total
        if d.id in wicket_ids:
            wicket_idx += 1
            fow.append({
                "wicket":     wicket_idx,
                "player_out": d.player_out,
                "runs":       cumulative,
                "over":       f"{d.over_number}.{d.ball_number + 1}",
                "kind":       d.wicket_kind,
                "bowler":     d.bowler,
            })

    return fow
