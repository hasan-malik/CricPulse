"""
Parse a single CricSheets JSON file and insert into the database.
Idempotent: skips matches already present by primary key.
"""

import json
from pathlib import Path
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Match, Innings, Delivery


async def parse_match_file(path: str, session: AsyncSession) -> bool:
    """Returns True if the match was newly inserted, False if already existed."""
    match_id = Path(path).stem

    # Idempotency check
    existing = await session.get(Match, match_id)
    if existing:
        return False

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    info    = data.get("info", {})
    outcome = info.get("outcome", {})
    win_by  = outcome.get("by", {})
    event   = info.get("event", {})
    tournament = event.get("name") or (info.get("series") or [None])[0]

    match = Match(
        id             = match_id,
        date           = (info.get("dates") or [""])[0],
        teams          = info.get("teams", []),
        venue          = info.get("venue"),
        match_type     = info.get("match_type", "").upper(),
        tournament     = tournament,
        gender         = info.get("gender", "male"),
        winner         = outcome.get("winner"),
        win_by_runs    = win_by.get("runs"),
        win_by_wickets = win_by.get("wickets"),
        player_of_match = info.get("player_of_match", []),
        toss_winner    = info.get("toss", {}).get("winner"),
        toss_decision  = info.get("toss", {}).get("decision"),
    )
    session.add(match)
    await session.flush()

    for idx, raw_inn in enumerate(data.get("innings", [])):
        target    = raw_inn.get("target", {})
        innings   = Innings(
            match_id       = match_id,
            innings_number = idx + 1,
            team           = raw_inn.get("team", ""),
            declared       = raw_inn.get("declared", False),
            target_runs    = target.get("runs"),
        )
        session.add(innings)
        await session.flush()

        total_runs = total_wickets = 0
        last_over_fraction = 0.0

        for raw_over in raw_inn.get("overs", []):
            over_num = raw_over.get("over", 0)
            for ball_idx, dlv in enumerate(raw_over.get("deliveries", [])):
                runs    = dlv.get("runs", {})
                extras  = dlv.get("extras", {})

                extra_type = None
                if extras.get("wides"):    extra_type = "wide"
                elif extras.get("noballs"): extra_type = "noball"
                elif extras.get("byes"):    extra_type = "bye"
                elif extras.get("legbyes"): extra_type = "legbye"

                wickets    = dlv.get("wickets", [])
                is_wicket  = bool(wickets)
                wkt        = wickets[0] if wickets else {}
                fielders   = [f.get("name", "") for f in wkt.get("fielders", [])]

                session.add(Delivery(
                    match_id       = match_id,
                    innings_id     = innings.id,
                    innings_number = idx + 1,
                    over_number    = over_num,
                    ball_number    = ball_idx,
                    batter         = dlv.get("batter", ""),
                    bowler         = dlv.get("bowler", ""),
                    non_striker    = dlv.get("non_striker", ""),
                    runs_batter    = runs.get("batter", 0),
                    runs_extras    = runs.get("extras", 0),
                    runs_total     = runs.get("total", 0),
                    extra_type     = extra_type,
                    is_wicket      = is_wicket,
                    wicket_kind    = wkt.get("kind"),
                    player_out     = wkt.get("player_out"),
                    fielders       = fielders,
                ))

                total_runs += runs.get("total", 0)
                if is_wicket:
                    total_wickets += 1
                if extra_type not in ("wide", "noball"):
                    last_over_fraction = over_num + (ball_idx + 1) / 6

        innings.total_runs     = total_runs
        innings.total_wickets  = total_wickets
        innings.total_overs    = round(last_over_fraction, 1)

    await session.commit()
    return True
