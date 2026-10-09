---
type: Tool
title: DoltgreSQL 1.4.0
description: The DoltgreSQL release release 3 measured the PostgreSQL pair on (2026-10-04 to 2026-10-06; 1.3.3 was the newest when the run was prepared), named by image digest, with what the 168 units showed -- no object refused, and per-row-commit stores the server collected during the load, so the final `dolt_gc()` finds little left on the largest.
resource: https://github.com/dolthub/doltgresql
tags:
- engine
- doltgresql
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
- resource: /tools/doltgresql-1-3-2.md
  title: DoltgreSQL 1.3.2, an earlier result set's version, and the refusals recorded on it
- resource: /decisions/engine-versions-one-per-result-set.md
  title: The rule under which the version moved
- resource: /tools/dolt-2-4-0.md
  title: Dolt 2.4.0, whose command-line loads of the same histories were not collected during the load
stale_after: "2027-04-01"
---

# Facts

Everything below was observed against `dolthub/doltgresql@sha256:3a119bb6726a0be283cfda2a73fa9fbdff58df06c0b850f245cd1828f57281a6` (tag `1.4.0`), one server per unit, between 2026-10-04 and 2026-10-06, under the dialect rules in dolt-megasamples' `doltsamples/dialects/doltgres.py`.

* **Nothing was refused.** Across all 168 DoltgreSQL units (21 databases; one commit, one `INSERT` per row with one commit, one commit per row; the row-by-row loads under both index policies) no unit recorded a refused object or a refused index (`refused_objects` and `indexes_refused` empty for every unit in `build/results.json`, 2026-10-08), where 1.3.2 refused a set of views per load ([DoltgreSQL 1.3.2](/tools/doltgresql-1-3-2.md)).
* **The large per-row-commit stores were collected during the load.** employees' per-row-commit store holds 14 archives (`.darc`) in `.dolt/noms/oldgen`, 39 GiB, and adventureworks' 10, against one for sakila's (`ls -la`, 2026-10-08). An archive is what one collection writes.
* **So the settle step's `dolt_gc()` reclaims little on the largest.** On the one-commit-per-row stores, `SELECT dolt_gc()` after the final commit shrank the five largest but one by 0.9 to 6.8% (employees 39.0 to 38.4 GiB in 38 s), contoso by 19%, and the fifteen smaller stores by 27 to 72% -- computed from each unit's `bytes_before_settle` and `disk_bytes` (`build/results.json`, 2026-10-08).
* **Every store answers a count of its largest table within 2 GiB.** The largest need is employees' per-row-commit store, 2,048 MB under both index policies; the one-commit stores need 192 MB at most (`make memory-pairs`, 2026-10-08).

# Limits

* Inferred: the collections during the load are the server's own automatic garbage collection; the run did not keep the server log that would say when each ran. Their sizes are therefore collected sizes, comparable with Dolt's after `dolt gc` and DoltLite's after `VACUUM`, not uncollected footprints.
* Inferred: a collection limited to the new generation leaves whatever an earlier collection moved into `oldgen`; whether `dolt_gc('--full')` would shrink these stores further was not tried.
