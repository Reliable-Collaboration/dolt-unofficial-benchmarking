#!/usr/bin/env python3
"""Every database out of the corpus, through dolt-megasamples, into build/dumps/.

  python3 scripts/export.py [--only sakila ...] [--force]        (make export)

dolt-megasamples owns the exports (`python3 -m doltsamples export --all` in its checkout): mysqldump
in both statement styles, pg_dump three ways, the SQLite files and their dumps, and the reference every
load is checked against, read from sql-megasamples' images or running servers. This runs that, then
links each file into the layout the runners read -- hard links where both checkouts share a filesystem,
copies where they do not -- so the experiment loads exactly the files the hosted stores are built from:

  exports/mysql/<db>.sql            -> build/dumps/<db>.sql
  exports/mysql/per-row/<db>.sql    -> build/dumps/rowwise/<db>.sql
  exports/postgres/<db>.*           -> build/dumps/postgres/
  exports/sqlite/<db>.*             -> build/dumps/sqlite/
"""
import argparse, os, shutil, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import DOLT_MEGASAMPLES_DIR, DUMPS, MEGASAMPLES_DIR, human  # noqa: E402

EXPORTS = os.path.join(DOLT_MEGASAMPLES_DIR, "build", "exports")


def link(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst):
        if os.path.samefile(src, dst):
            return 0
        os.remove(dst)
    try:
        os.link(src, dst)
    except OSError:
        shutil.copyfile(src, dst)
    return os.path.getsize(dst)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--only", nargs="*")
    ap.add_argument("--force", action="store_true", help="export again even what dolt-megasamples has exported")
    a = ap.parse_args()
    py = os.path.join(DOLT_MEGASAMPLES_DIR, ".venv", "bin", "python")
    cmd = [py if os.path.exists(py) else sys.executable, "-m", "doltsamples", "export", "--all"]
    cmd += (["--only", *a.only] if a.only else []) + (["--force"] if a.force else [])
    env = {**os.environ, "PYTHONPATH": DOLT_MEGASAMPLES_DIR, "MEGASAMPLES_DIR": MEGASAMPLES_DIR}
    print(f"  . {' '.join(cmd[1:])}  (in {DOLT_MEGASAMPLES_DIR})", flush=True)
    if subprocess.run(cmd, cwd=DOLT_MEGASAMPLES_DIR, env=env).returncode != 0:
        sys.exit("dolt-megasamples' export failed; nothing linked")
    total, files = 0, 0
    plan = [(os.path.join(EXPORTS, "mysql"), DUMPS, lambda f: f.endswith(".sql")),
            (os.path.join(EXPORTS, "mysql", "per-row"), os.path.join(DUMPS, "rowwise"), lambda f: f.endswith(".sql")),
            (os.path.join(EXPORTS, "postgres"), os.path.join(DUMPS, "postgres"), lambda f: not f.startswith(".")),
            (os.path.join(EXPORTS, "sqlite"), os.path.join(DUMPS, "sqlite"), lambda f: not f.startswith("."))]
    for src_dir, dst_dir, keep in plan:
        if not os.path.isdir(src_dir):
            continue
        for f in sorted(os.listdir(src_dir)):
            src = os.path.join(src_dir, f)
            if os.path.isfile(src) and keep(f) and (not a.only or f.split(".")[0] in a.only):
                total += link(src, os.path.join(dst_dir, f))
                files += 1
    print(f"\n{files} files in {os.path.relpath(DUMPS, os.getcwd())} ({human(total)} newly linked or copied)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
