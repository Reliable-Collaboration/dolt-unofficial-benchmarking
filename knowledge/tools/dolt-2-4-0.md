---
type: Tool
title: Dolt 2.4.0
description: The Dolt release release 3 measured the MySQL pair on (2026-10-02 to 2026-10-08), named by image digest, with what the run showed of its command line's garbage collection -- above all that a per-row-commit history loaded through `dolt sql` is never collected during the load, and that employees' 3.9 million commits left a 57 GiB chunk journal `dolt gc` could not collect within 18 GiB.
resource: https://github.com/dolthub/dolt
tags:
- engine
- dolt
- version
status: stable
trust: verified
generated:
  by: claude-code/claude-opus-5-5
  at: "2026-10-08T23:40:00Z"
verified:
- by: claude-code/claude-opus-5-5
  at: "2026-10-08T23:40:00Z"
sources:
- resource: /decisions/engine-versions-one-per-result-set.md
  title: The rule under which release 3 runs on the newest release of every engine
- resource: /questions/dolt-gc-memory-large-journal.md
  title: What `dolt gc` needs for a large chunk journal, and whether collecting during the load bounds it
stale_after: "2027-04-01"
---

# Facts

Everything below was observed on this machine (30 GiB of memory, rootless Podman) against `dolthub/dolt-sql-server@sha256:8771be743f1b81b1e9d8d12b9587798446fa0bf34c56ec5b7b14539f895daa0b` (tag `2.4.0`), run as the `dolt` command line inside the image, between 2026-10-02 and 2026-10-08.

* **The run.** 168 MySQL/Dolt units (21 databases; one commit, one `INSERT` per row with one commit, one commit per row; the row-by-row loads under both index policies) ended with every table's rows matching MySQL (`make run`, `make run ARGS=--indexes inline`; `make check`, 3,300 invariants, 2026-10-08).
* **The settle step's garbage collection did not complete on employees' per-row-commit stores.** Both were OOM-killed in the settle step that follows the load -- at the 16 GiB worker cap (deferred indexes, 16.6 GiB anonymous memory at the kill) and at the 18 GiB cap (inline indexes, 18.7 GiB), both recorded by the kernel (`journalctl -k`). The commit before it had landed: each store holds 3,919,018 commits for 3,919,015 rows (`make memory`, 2026-10-08). What remained was the store as the load left it: `.dolt/noms` one chunk journal of 57.4 GiB (61.3 GiB inline) with a 1.79 GiB `journal.idx`, and an empty `oldgen` (`ls -la`, 2026-10-08). Every one of the other 103 Dolt stores of the run has its data in `oldgen` archives (`.darc`), the mark of a completed `dolt gc`.
* **Opening that store takes more than 10 GiB.** `dolt log -n 1 --oneline` on a copy of the deferred-index store was killed at a 10 GiB cap after 19 s (`data/oom-investigation/gc-try.sh`, 2026-10-08); counting its largest table needs 12 GiB (`make memory`, killed at 3 and 11 GiB, answered at 12 to 16 GiB; the inline store the same). Every other Dolt store of the run answers the same count in 1,536 MiB or less (oracle_sh and wikipedia_simple per-row with indexes inline; 768 MiB or less with them deferred).
* **During the load, memory climbs in steps, not smoothly.** The worker's anonymous memory was 4.2, 7.1, 11.1 and 12.5 GiB by the time the store reached 12.6, 27.6, 53.7 and 59.2 GiB, and stayed nearly flat between those steps (`build/trace/rowcommit-employees.json`, sampled every 2 s, 2026-10-03; the inline load the same within 0.7 GiB).
* **`dolt gc` in 2.4.0** takes `--shallow`, `--full`, `--archive-level` (default 1; 0 disables archives) and `--incremental-file-size` (`dolt gc --help`, 2026-10-08). Without `--full` it visits only the new generation.

# Limits

* A per-row-commit history loaded through the command line accumulates in one chunk journal until something runs `dolt gc`; at employees' size neither opening the result nor collecting it fits in this run's caps. The benchmark's per-row-commit loads are naive by design and run no collection during the load, so these two stores are reported as uncollected footprints, marked †, and left out of the totals (`scripts/collect.py`, from 2026-10-08).
* Collecting during the load bounds the load but not the end. A build of employees' per-row-commit history through dolt-megasamples, `dolt gc` after every 10 chunks of 50,000 statements under a 10 GiB cap (2026-10-08 22:59 to 2026-10-09 01:43 UTC), replayed all 157 chunks with the worker's anonymous memory near 3 GiB between collections and the store's data moved into 17 `oldgen` archives; the final `dolt add -A && dolt commit && dolt gc` then climbed past 8.2 GiB and was killed at 8.4 GiB by the host's own out-of-memory killer, the host having run short beside its other services (`journalctl -k`: `global_oom`, not the container's limit). That store, with its data in archives, could not be opened under 2 GiB either (`dolt log -n 2`, killed).
* Inferred: what it takes to open a Dolt store grows with the number of chunks the store holds, whether in the journal or in archives -- an index of every chunk address held in memory, which also explains the stepwise growth during the load (a hash table doubling as it fills) -- and a collection holds a second set of the reachable addresses beside it. employees' per-row history has about 3.4 times the commits of the next largest. Not verified against Dolt's source.
* Inferred: DoltgreSQL avoided this on the same histories because it runs as a server, and its large per-row-commit stores show 10 to 14 archives in `oldgen` -- one per collection -- so they were collected during the load ([DoltgreSQL 1.4.0](/tools/doltgresql-1-4-0.md)).

# Open questions

* [What `dolt gc` needs for a large chunk journal](/questions/dolt-gc-memory-large-journal.md), and whether collecting every few chunks during the load, as dolt-megasamples does, keeps a per-row-commit history of employees' size within a 10 GiB cap.
