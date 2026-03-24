"""
Download and extract CricSheets ZIP files into data/cricsheet/.
"""

import io
import zipfile
from pathlib import Path

import httpx

BASE_URL  = "https://cricsheet.org/downloads/"
MATCH_DIR = Path(__file__).parent.parent / "data" / "cricsheet"

# Friendly source names → CricSheets filenames
SOURCES: dict[str, str] = {
    "recent7":  "recently_added_json.zip",   # matches added in last 7 days
    "t20s":     "t20s_json.zip",
    "odis":     "odis_json.zip",
    "tests":    "tests_json.zip",
    "ipl":      "ipl_json.zip",
    "psl":      "psl_json.zip",
    "bbl":      "bbl_json.zip",
    "cpl":      "cpl_json.zip",
    "all":      "all_json.zip",              # 21 000+ matches — large download
}


async def download_and_extract(source: str = "recent7") -> list[str]:
    """
    Download a CricSheets ZIP and extract JSON files to data/cricsheet/.
    Returns a list of absolute paths to extracted .json files.
    """
    filename = SOURCES.get(source, source)   # allow raw filename as fallback
    url      = BASE_URL + filename

    MATCH_DIR.mkdir(parents=True, exist_ok=True)

    async with httpx.AsyncClient(timeout=600, follow_redirects=True) as client:
        resp = await client.get(url)
        resp.raise_for_status()

    extracted: list[str] = []
    with zipfile.ZipFile(io.BytesIO(resp.content)) as zf:
        for name in zf.namelist():
            if not name.endswith(".json"):
                continue
            dest = MATCH_DIR / Path(name).name
            dest.write_bytes(zf.read(name))
            extracted.append(str(dest))

    return extracted
