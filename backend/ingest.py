#!/usr/bin/env python3
"""
CLI script to download and ingest CricSheets data.

Usage:
    python ingest.py                  # download last 7 days
    python ingest.py ipl              # download IPL matches
    python ingest.py t20s             # all T20 internationals
    python ingest.py odis
    python ingest.py tests
    python ingest.py psl
    python ingest.py bbl
    python ingest.py all              # everything (21 000+ matches, slow)
"""

import asyncio
import sys
from app.database import init_db, SessionLocal
from app import downloader, parser


async def main(source: str = "recent7"):
    print(f"[ingest] Initialising database...")
    await init_db()

    print(f"[ingest] Downloading '{source}' from cricsheet.org...")
    paths = await downloader.download_and_extract(source)
    print(f"[ingest] Extracted {len(paths)} JSON files.")

    new = skipped = errors = 0
    async with SessionLocal() as session:
        for i, path in enumerate(paths, 1):
            if i % 100 == 0:
                print(f"[ingest]   {i}/{len(paths)} processed...")
            try:
                is_new = await parser.parse_match_file(path, session)
                if is_new:
                    new += 1
                else:
                    skipped += 1
            except Exception as exc:
                errors += 1
                print(f"[ingest] ERROR {path}: {exc}")

    print(f"\n[ingest] Complete — {new} new | {skipped} skipped | {errors} errors")


if __name__ == "__main__":
    source = sys.argv[1] if len(sys.argv) > 1 else "recent7"
    asyncio.run(main(source))
