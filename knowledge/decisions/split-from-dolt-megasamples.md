---
type: Decision
title: The side-by-side tests leave dolt-megasamples for this repository, which depends on it
description: The maintainer's split of 2026-10-02 -- dolt-unofficial-benchmarking carries dolt-megasamples' history and every timed and comparative test; dolt-megasamples keeps the hosting and owns what both need (the exports from the corpus, the dialect rules, the DoltLite image), and this repository imports them from a dolt-megasamples checkout.
resource: /decisions/split-from-dolt-megasamples.md
tags:
- repository
- decision
status: stable
trust: verified
generated:
  by: claude-code/claude-opus-5-5
  at: "2026-10-02T20:00:00Z"
verified:
- by: claude-code/claude-opus-5-5
  at: "2026-10-02T20:00:00Z"
sources:
- resource: https://github.com/Reliable-Collaboration/dolt-megasamples
  title: dolt-megasamples, the hosting tool this repository depends on
  accessed: "2026-10-02"
- resource: /decisions/engine-versions-one-per-result-set.md
  title: The version rule, which this repository keeps for its runs
---

# Question

dolt-megasamples had become two things: databases a person can host, and an experiment measuring what each Dolt engine costs against the database it stands in for. The maintainer wanted the hosting to stand on its own, as sql-megasamples does. Where does the experiment go, and what does it share with the hosting?

# Options considered

* **A fresh repository with an import commit.** Lost: the commit trail behind every measurement, decision and bug report.
* **This repository with dolt-megasamples' history, keeping its own copies of the shared code.** Lost: the dialect rules -- each found by a refusal -- would exist twice and drift; a rule found by the measurements would not reach the databases people host.
* **This repository with dolt-megasamples' history, depending on a dolt-megasamples checkout for the shared code.** Chosen.

# Evidence

The maintainer's words, 2026-10-02: "I want to take this repository and split it into this one and that one. [...] The dolt-unofficial-benchmarking will be where we bring all of the 'side by side testing'. It's objective is less about leaving a fully operational instance, and more about looking at head-to-head performance and functionality statistics between each of the products that we're comparing." Asked the same day, the maintainer chose that the shared code lives in dolt-megasamples with this repository depending on it, that this repository carries the history, and that the partial release-3 run (163 units on Dolt 2.4.0 and MySQL 9.7.2 under a 12 GiB worker cap, employees' one-commit-per-row load killed for memory at 3,624,968 of 3,919,015 commits) is deleted rather than carried.

# Outcome

* This repository's history is dolt-megasamples' up to the split (its branch `release-3`), joined to this repository's first commit.
* `scripts/common.py` finds the dolt-megasamples checkout (`../dolt-megasamples`, or `DOLT_MEGASAMPLES_DIR`) and puts its package `doltsamples` on the path; the runners, the preflights and the spike import the dialect rules from `doltsamples.dialects`, and `scripts/dolt_dialect.py`, `scripts/doltgres_dialect.py` and `scripts/doltlite_dialect.py` are gone.
* `make export` (`scripts/export.py`) runs dolt-megasamples' export of every database the corpus holds and links the files into `build/dumps/` in the layout the runners read; `scripts/export_mysql.py`, `scripts/export_postgres.py`, `scripts/export_sqlite.py` and `make export-pairs` are gone. The exports now come from the corpus's images when its servers are not running.
* `make lite-image` builds the DoltLite image through dolt-megasamples for the versions this repository's `versions.json` names, which still names all six engines: a run here keeps its own versions, under [the version rule](/decisions/engine-versions-one-per-result-set.md).
* The served stack -- compose.yaml, the consoles' configuration, `scripts/stack_config.py`, `scripts/stack_settings.py`, `scripts/stack_check.py`, `scripts/console_page.py`, the screenshots -- is gone from here; [the served instance](/decisions/stood-up-instances.md) is dolt-megasamples' now. The README tells the experiment alone.

# Status

accepted (2026-10-02; the maintainer's decisions, quoted above).
