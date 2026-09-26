from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

DAT_DIR = Path(os.environ.get(
    "FTL_DATA", Path.home() / ".steam/steam/steamapps/common/FTL Faster Than Light/data"))


def vanilla_data() -> tuple[Path | None, str]:
    """Extract the unmodded ftl.dat once and share it between the checks.

    Returns (folder, "") on success, or (None, reason) so the caller can print an honest
    SKIPPED line. The cache is keyed on the archive's size and mtime, and only a finished
    extraction is renamed into place, so an interrupted run is never trusted.
    """
    source = DAT_DIR / "ftl.dat.vanilla"
    if not source.exists():
        source = DAT_DIR / "ftl.dat"
    if not source.exists():
        return None, f"no ftl.dat in {DAT_DIR}"
    stat = source.stat()
    root = Path(tempfile.gettempdir()) / "ftlap_vanilla"
    cache = root / f"{stat.st_size}-{int(stat.st_mtime)}"
    if (cache / "data").is_dir():
        return cache / "data", ""
    if shutil.which(os.environ.get("FTLMAN", "ftlman")) is None:
        return None, "ftlman not found"
    root.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(dir=root, prefix="partial-"))
    result = subprocess.run([os.environ.get("FTLMAN", "ftlman"), "extract", str(work), str(source)],
                            capture_output=True, text=True)
    if result.returncode != 0 or not (work / "data").is_dir():
        shutil.rmtree(work, ignore_errors=True)
        return None, f"ftlman extract failed on {source.name}"
    try:
        work.rename(cache)
    except OSError:
        shutil.rmtree(work, ignore_errors=True)
    return cache / "data", ""
