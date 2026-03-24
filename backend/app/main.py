from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, Query
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app import analytics, downloader, parser
from app.database import SessionLocal, get_db, init_db
from app.models import Delivery, Innings, Match


# ── App lifecycle ──────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(_: FastAPI):
    await init_db()
    yield

app = FastAPI(title="CricPulse API", version="1.0.0", lifespan=lifespan)


# ── Match list ─────────────────────────────────────────────────────────────────

@app.get("/matches")
async def list_matches(
    format:     str | None = None,
    team:       str | None = None,
    tournament: str | None = None,
    year:       str | None = None,
    limit:  int = Query(20, le=100),
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
):
    q = select(Match).order_by(desc(Match.date))
    if format:
        q = q.where(Match.match_type == format.upper())
    if tournament:
        q = q.where(Match.tournament.ilike(f"%{tournament}%"))
    if team:
        q = q.where(Match.teams.cast(str).ilike(f"%{team}%"))
    if year:
        q = q.where(Match.date.startswith(year))

    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar()
    matches = (await db.execute(q.offset(offset).limit(limit))).scalars().all()

    # Batch-load innings so list items include scores
    match_ids = [m.id for m in matches]
    innings_rows = (await db.execute(
        select(Innings).where(Innings.match_id.in_(match_ids)).order_by(Innings.innings_number)
    )).scalars().all()
    innings_by_match: dict[str, list] = {}
    for i in innings_rows:
        innings_by_match.setdefault(i.match_id, []).append(i)

    return {
        "total": total,
        "matches": [_match_summary(m, innings_by_match.get(m.id)) for m in matches],
    }


# ── Available years ───────────────────────────────────────────────────────────

@app.get("/matches/years")
async def list_years(db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(
        select(func.substr(Match.date, 1, 4))
        .distinct()
        .order_by(desc(func.substr(Match.date, 1, 4)))
    )).scalars().all()
    return {"years": [r for r in rows if r]}


# ── Match search (fuzzy: teams + date → CricSheets ID) ───────────────────────
# IMPORTANT: must be declared before /matches/{match_id} so FastAPI doesn't
# interpret the string "search" as a match_id.

@app.get("/matches/search")
async def search_match(
    team1:  str,
    team2:  str,
    date:   str,            # YYYY-MM-DD
    format: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    """
    Find a CricSheets match by fuzzy team names + date (±1 day).
    Used by the iOS app to map a CricAPI match UUID to a CricSheets match ID.
    """
    from datetime import date as dt, timedelta
    try:
        target = dt.fromisoformat(date[:10])
    except ValueError:
        raise HTTPException(400, "date must be YYYY-MM-DD")

    date_range = [
        (target - timedelta(days=1)).isoformat(),
        target.isoformat(),
        (target + timedelta(days=1)).isoformat(),
    ]

    q = select(Match).where(Match.date.in_(date_range))
    if format:
        q = q.where(Match.match_type == format.upper())

    rows = (await db.execute(q)).scalars().all()

    t1 = team1.lower()
    t2 = team2.lower()

    for m in rows:
        teams = [t.lower() for t in (m.teams or [])]
        t1_hit = any(t1[:6] in t or t[:6] in t1 for t in teams)
        t2_hit = any(t2[:6] in t or t[:6] in t2 for t in teams)
        if t1_hit and t2_hit:
            return _match_summary(m)

    raise HTTPException(404, "No CricSheets match found for these teams and date")


# ── Match detail ──────────────────────────────────────────────────────────────

@app.get("/matches/{match_id}")
async def get_match(match_id: str, db: AsyncSession = Depends(get_db)):
    match = await db.get(Match, match_id)
    if not match:
        raise HTTPException(404, "Match not found")
    inns = (await db.execute(
        select(Innings)
        .where(Innings.match_id == match_id)
        .order_by(Innings.innings_number)
    )).scalars().all()
    return {**_match_summary(match), "innings": [_innings_summary(i) for i in inns]}


# ── Scorecard ─────────────────────────────────────────────────────────────────

@app.get("/matches/{match_id}/innings/{n}/scorecard")
async def get_scorecard(match_id: str, n: int, db: AsyncSession = Depends(get_db)):
    innings = await _get_innings(match_id, n, db)
    return {
        "batting": await analytics.batting_scorecard(innings.id, db),
        "bowling": await analytics.bowling_scorecard(innings.id, db),
    }


# ── Over-by-over chart ────────────────────────────────────────────────────────

@app.get("/matches/{match_id}/innings/{n}/overs")
async def get_overs(match_id: str, n: int, db: AsyncSession = Depends(get_db)):
    innings = await _get_innings(match_id, n, db)
    return await analytics.over_data(innings.id, db)


# ── Wagon wheel ───────────────────────────────────────────────────────────────

@app.get("/matches/{match_id}/innings/{n}/wagonwheel")
async def get_wagon_wheel(
    match_id: str,
    n:       int,
    batter:  str | None = None,
    db: AsyncSession = Depends(get_db),
):
    innings = await _get_innings(match_id, n, db)
    return await analytics.wagon_wheel(innings.id, db, batter=batter)


# ── Partnerships ──────────────────────────────────────────────────────────────

@app.get("/matches/{match_id}/innings/{n}/partnerships")
async def get_partnerships(match_id: str, n: int, db: AsyncSession = Depends(get_db)):
    innings = await _get_innings(match_id, n, db)
    return await analytics.partnerships(innings.id, db)


# ── Fall of wickets ───────────────────────────────────────────────────────────

@app.get("/matches/{match_id}/innings/{n}/fow")
async def get_fow(match_id: str, n: int, db: AsyncSession = Depends(get_db)):
    innings = await _get_innings(match_id, n, db)
    return await analytics.fall_of_wickets(innings.id, db)


# ── Admin / ingestion ─────────────────────────────────────────────────────────

@app.post("/admin/ingest")
async def ingest(
    source: str = "recent7",
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    """Download a CricSheets ZIP and parse all new matches in the background."""
    async def _run():
        paths = await downloader.download_and_extract(source)
        new_count = 0
        async with SessionLocal() as session:
            for path in paths:
                try:
                    if await parser.parse_match_file(path, session):
                        new_count += 1
                except Exception as exc:
                    print(f"[ingest] Error parsing {path}: {exc}")
        print(f"[ingest] Done — {new_count} new matches from '{source}'")

    background_tasks.add_task(_run)
    return {"status": "started", "source": source}


@app.get("/admin/stats")
async def admin_stats(db: AsyncSession = Depends(get_db)):
    return {
        "matches":    (await db.execute(select(func.count()).select_from(Match))).scalar(),
        "innings":    (await db.execute(select(func.count()).select_from(Innings))).scalar(),
        "deliveries": (await db.execute(select(func.count()).select_from(Delivery))).scalar(),
    }


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _get_innings(match_id: str, n: int, db: AsyncSession) -> Innings:
    row = (await db.execute(
        select(Innings).where(Innings.match_id == match_id, Innings.innings_number == n)
    )).scalar_one_or_none()
    if not row:
        raise HTTPException(404, f"Innings {n} not found for match {match_id}")
    return row


def _match_summary(m: Match, innings: list | None = None) -> dict:
    result = ""
    if m.winner:
        if m.win_by_runs:
            result = f"{m.winner} won by {m.win_by_runs} runs"
        elif m.win_by_wickets:
            result = f"{m.winner} won by {m.win_by_wickets} wickets"
        else:
            result = f"{m.winner} won"

    return {
        "id":               m.id,
        "date":             m.date,
        "teams":            m.teams,
        "venue":            m.venue,
        "match_type":       m.match_type,
        "tournament":       m.tournament,
        "gender":           m.gender,
        "winner":           m.winner,
        "result":           result,
        "player_of_match":  m.player_of_match,
        "toss_winner":      m.toss_winner,
        "toss_decision":    m.toss_decision,
        **({"innings": [_innings_summary(i) for i in innings]} if innings is not None else {}),
    }


def _innings_summary(i: Innings) -> dict:
    return {
        "innings_number": i.innings_number,
        "team":           i.team,
        "runs":           i.total_runs,
        "wickets":        i.total_wickets,
        "overs":          i.total_overs,
        "display":        f"{i.total_runs}/{i.total_wickets} ({i.total_overs} ov)",
        "declared":       i.declared,
        "target_runs":    i.target_runs,
    }
