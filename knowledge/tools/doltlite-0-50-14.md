---
type: Tool
title: DoltLite v0.50.14
description: The DoltLite release release 3 measured the SQLite pair on (2026-10-06 to 2026-10-08; v0.50.10 before), built into an image from its two checksummed Debian packages, with what the 168 units showed -- every store opens in 64 MiB, and `VACUUM` of a one-commit-per-row history rereads the file many times over before it writes, and reclaims much less of it when the indexes were kept inline.
resource: https://github.com/dolthub/doltlite
tags:
- engine
- doltlite
- version
status: stable
trust: verified
generated:
  by: claude-code/claude-opus-5-5
  at: "2026-10-08T23:50:00Z"
verified:
- by: claude-code/claude-opus-5-5
  at: "2026-10-08T23:50:00Z"
sources:
- resource: /tools/doltlite-0-50-10.md
  title: DoltLite v0.50.10, the version measured before
- resource: /decisions/engine-versions-one-per-result-set.md
  title: The rule under which the version moved
stale_after: "2027-04-01"
---

# Facts

Everything below was observed on the image built from `libdoltlite0_0.50.14_amd64.deb` (SHA-256 `d452573a3284c838191c7d640ef1a468bce4aee2ee05ded5cadcaca966198049`) and `doltlite_0.50.14_amd64.deb` (`13f407d1fc4c351cecbfd283ae8054a304d962e866e7ec7d594595c4aa0b321a`), between 2026-10-06 and 2026-10-08.

* **Nothing was refused, and every store opens in 64 MiB.** No unit of the 168 recorded a refused object or index (`build/results.json`); every DoltLite store, of every shape, answered a count of its largest table at the study's smallest cap, 64 MB (`make memory-pairs`, 2026-10-08).
* **`VACUUM` reclaims about two fifths of a one-commit-per-row history, and less with the indexes inline.** With the secondary indexes deferred it shrank the stores by 34.0 to 50.6% (employees 47.3 to 26.4 GiB); with them inline, by 13.4 to 41.8% -- computed from each unit's `bytes_before_settle` and `disk_bytes` (`build/results.json`, 2026-10-08).
* **`VACUUM` of a large history reads for hours before it writes.** On oracle_sh's inline per-row-commit store (64.4 GiB) the `doltlite` process read 42 TB over about four hours -- almost all from the page cache, its `wchar` flat and its 855 MB temporary file not growing -- and then wrote a new 51.5 GiB file beside the old one (`/proc/<pid>/io`, sampled hourly, 2026-10-07). employees' deferred-index `VACUUM` read 21 TB in about two and a half hours, then wrote for about a quarter of an hour (2026-10-06). It held under 400 MiB of memory throughout.
* **The longest settle steps** were employees' deferred-index per-row-commit `VACUUM`, 167 minutes, and oracle_sh's inline one, 284 minutes (`settle_seconds`, `build/results.json`).

# Limits

* Keeping the indexes inline on a one-commit-per-row load costs DoltLite far more than it costs the other engines: every commit keeps its own versions of every index, the history is larger, and `VACUUM` both takes longer and reclaims less. The whole-unit times and sizes are in the generated documents.
* Inferred: the rereading is a walk of every commit's trees during `VACUUM`'s marking pass; the source was not read for this release.
