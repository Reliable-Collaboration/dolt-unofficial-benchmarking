---
type: Open Question
title: What does `dolt gc` need for a large chunk journal, and does collecting during the load bound it?
description: Raised on 2026-10-08 by employees' per-row-commit stores, whose `dolt gc` was OOM-killed at 16 and at 18 GiB after the commit had landed, leaving 57-61 GiB journals that take more than 10 GiB just to open.
resource: /questions/dolt-gc-memory-large-journal.md
tags:
- dolt
- question
- memory
status: draft
trust: open
generated:
  by: claude-code/claude-opus-5-5
  at: "2026-10-08T23:40:00Z"
sources:
- resource: /tools/dolt-2-4-0.md
  title: Dolt 2.4.0, the observations the question comes from
---

# Question

Two things the release-3 run could not settle:

1. How much memory does `dolt gc` need to collect a chunk journal the size of employees' per-row-commit history (3,919,018 commits, 57.4 GiB), and does `--shallow` or `--archive-level=0` need less? The run shows only that it needs more than 16 and more than 18 GiB.
2. Does running `dolt gc` every few chunks of the load -- which moves the journal into `oldgen` archives as it goes -- keep the load, the final collection and the finished store's opening within a modest cap? dolt-megasamples does this (every 10 chunks of 50,000 statements) and has only tried it on sakila.

# Cheapest experiment

1. On a copy of the store (`data/oom-investigation/employees-copy`), run `dolt gc`, `dolt gc --shallow` and `dolt gc --archive-level=0` under rising caps with `data/oom-investigation/gc-try.sh`, reading `memory.peak` and `memory.events`. Needs more memory than this host can spare beside its other services (about 14 GiB available on 2026-10-08, swap full), so only caps up to 10 GiB were tried: none can even open the store there.
2. Build employees' per-row-commit history with dolt-megasamples under a 10 GiB cap, sampling the build container's `memory.current` and `memory.peak` every 10 s, and confirm the store ends with its data in `oldgen` and opens under a small cap. Run 2026-10-08 22:59 to 2026-10-09 01:43 UTC: the load stayed near 3 GiB of anonymous memory between collections and ended with 17 archives in `oldgen`, but the final commit and gc passed 8.2 GiB and were killed by the host's out-of-memory killer at 8.4 GiB (the host short of memory, not the container at its cap), and the resulting store could not be opened under 2 GiB. So collecting during the load bounds the load, not the final collection or the opening; part 1 still needs a host with memory to spare.

# Resolves

Whether the benchmark should keep its naive per-row-commit load and report such stores as uncollected, or whether a load that collects as it goes is the realistic shape for Dolt's command line; and whether dolt-megasamples can offer the per-row history of its largest databases at its default build cap.
