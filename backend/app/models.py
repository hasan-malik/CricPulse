from sqlalchemy import String, Integer, Float, Boolean, JSON, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[str]          = mapped_column(String, primary_key=True)   # cricsheet filename stem
    date: Mapped[str]        = mapped_column(String, index=True)
    teams: Mapped[list]      = mapped_column(JSON)
    venue: Mapped[str | None]       = mapped_column(String, nullable=True)
    match_type: Mapped[str]         = mapped_column(String, index=True)   # T20 | ODI | TEST
    tournament: Mapped[str | None]  = mapped_column(String, nullable=True, index=True)
    gender: Mapped[str]             = mapped_column(String, default="male")
    winner: Mapped[str | None]      = mapped_column(String, nullable=True)
    win_by_runs: Mapped[int | None]      = mapped_column(Integer, nullable=True)
    win_by_wickets: Mapped[int | None]   = mapped_column(Integer, nullable=True)
    player_of_match: Mapped[list]        = mapped_column(JSON, default=list)
    toss_winner: Mapped[str | None]      = mapped_column(String, nullable=True)
    toss_decision: Mapped[str | None]    = mapped_column(String, nullable=True)

    innings: Mapped[list["Innings"]] = relationship(
        "Innings", back_populates="match", order_by="Innings.innings_number"
    )


class Innings(Base):
    __tablename__ = "innings"
    __table_args__ = (UniqueConstraint("match_id", "innings_number"),)

    id: Mapped[int]               = mapped_column(Integer, primary_key=True, autoincrement=True)
    match_id: Mapped[str]         = mapped_column(String, ForeignKey("matches.id"), index=True)
    innings_number: Mapped[int]   = mapped_column(Integer)
    team: Mapped[str]             = mapped_column(String)
    total_runs: Mapped[int]       = mapped_column(Integer, default=0)
    total_wickets: Mapped[int]    = mapped_column(Integer, default=0)
    total_overs: Mapped[float]    = mapped_column(Float, default=0.0)
    declared: Mapped[bool]        = mapped_column(Boolean, default=False)
    target_runs: Mapped[int | None] = mapped_column(Integer, nullable=True)

    match: Mapped["Match"]             = relationship("Match", back_populates="innings")
    deliveries: Mapped[list["Delivery"]] = relationship(
        "Delivery", back_populates="innings_obj",
        order_by="[Delivery.over_number, Delivery.ball_number]"
    )


class Delivery(Base):
    __tablename__ = "deliveries"

    id: Mapped[int]            = mapped_column(Integer, primary_key=True, autoincrement=True)
    match_id: Mapped[str]      = mapped_column(String, ForeignKey("matches.id"), index=True)
    innings_id: Mapped[int]    = mapped_column(Integer, ForeignKey("innings.id"), index=True)
    innings_number: Mapped[int] = mapped_column(Integer)
    over_number: Mapped[int]   = mapped_column(Integer)
    ball_number: Mapped[int]   = mapped_column(Integer)

    batter: Mapped[str]       = mapped_column(String, index=True)
    bowler: Mapped[str]       = mapped_column(String, index=True)
    non_striker: Mapped[str]  = mapped_column(String)

    runs_batter: Mapped[int]  = mapped_column(Integer, default=0)
    runs_extras: Mapped[int]  = mapped_column(Integer, default=0)
    runs_total: Mapped[int]   = mapped_column(Integer, default=0)
    extra_type: Mapped[str | None] = mapped_column(String, nullable=True)  # wide|noball|bye|legbye

    is_wicket: Mapped[bool]          = mapped_column(Boolean, default=False)
    wicket_kind: Mapped[str | None]  = mapped_column(String, nullable=True)
    player_out: Mapped[str | None]   = mapped_column(String, nullable=True, index=True)
    fielders: Mapped[list]           = mapped_column(JSON, default=list)

    innings_obj: Mapped["Innings"] = relationship("Innings", back_populates="deliveries")
