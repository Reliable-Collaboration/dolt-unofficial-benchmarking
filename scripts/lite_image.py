#!/usr/bin/env python3
"""The DoltLite image for the versions this run names, built by dolt-megasamples.

  python3 scripts/lite_image.py [--record]          (make lite-image; make new-run records)

dolt-megasamples builds it (doltsamples/lite_image.py, docker/doltlite/Dockerfile): DoltLite's two
release packages and sqlite.org's source tarball, each checked against the SHA-256 recorded here,
with the sqlite3 shell -- the SQLite baseline of the pair -- built from source with the features the
corpus's files use. The versions are this repository's versions.json, so the image is the one the
run measures; with `--record`, the shell the image carries is recorded here.
"""
import argparse, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import VERSIONS, VERSIONS_PATH  # noqa: E402
from doltsamples import lite_image  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--record", action="store_true", help="record the sqlite3 shell the image carries in versions.json")
    a = ap.parse_args()
    lite_image.build(v=VERSIONS, record=a.record, versions_path=VERSIONS_PATH)
    return 0


if __name__ == "__main__":
    sys.exit(main())
