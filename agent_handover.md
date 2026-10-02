# Agent handover: release 3 of the benchmark, after the split

Rewritten 2026-10-02. This repository is **dolt-unofficial-benchmarking**: until that day it was
dolt-megasamples, and its history is that repository's. On 2026-10-02 the maintainer split it: the
hosting stayed in dolt-megasamples, every side-by-side test came here
(`knowledge/decisions/split-from-dolt-megasamples.md`). Release 3's run had started on a new machine and was
stopped and deleted at the split, so nothing is measured yet on the current versions. Read this
file first, then `knowledge/index.md`, then the decision records it names.

## What this repository is, in one paragraph

An experiment: for the same data, what does a Dolt engine cost against the database it stands in
for, in disk, time and memory? The 21 sample databases of
[`sql-megasamples`](https://github.com/Reliable-Collaboration/sql-megasamples) are loaded five ways
into both sides of each pair -- Dolt against MySQL, DoltgreSQL against PostgreSQL, DoltLite against
SQLite -- and sized, timed and profiled the same way on both, plus three memory studies. It serves
nothing: hosting the databases is [`dolt-megasamples`](https://github.com/Reliable-Collaboration/dolt-megasamples),
which this repository depends on for the exports from the corpus, the dialect rules every Dolt engine
needs and the DoltLite image (`scripts/common.py` imports its package `doltsamples` from a checkout at
`../dolt-megasamples`). The README tells the story; REPORT.md carries every table and figure; JOURNAL.md the
method and history; `knowledge/` the research trail and the decisions. Every number in those documents is
generated from the measurement files in `build/` and `make check` fails if a document disagrees with them.

## The maintainer's standing instructions

These were given during release 2 and still hold. Quote them back when a decision rests on them.

- **Status updates.** "Report back at least every 1 hour with a status update. Be sure that status
  updates are complete with a full list of what needs to get done, what's left to do. Also provide a
  list of decisions that were made and things that I should know about, as well as if input is
  needed from me. Author status updates so that they are cumulative." A detached monitor that prints
  the state hourly is the reliable way; see *Things that went wrong before* below.
- **Never publish anything without explicit approval**: no GitHub issues, no comments on upstream
  repositories, no pull-request merges, no pushes to `main`. Pushing to this branch is fine.
- **Verified versus inferred.** Say which is which. A claim about an engine's behaviour is verified
  by running it, and the knowledge bundle records how. Never present an inference as a measurement.
- **No sudo workarounds.** If something needs root, say so and stop.
- **No number typed by hand into a generated document.** README.md, REPORT.md and JOURNAL.md are
  rendered from `docs/templates/` by `scripts/render.py`; a number reaches them as a fact
  (`scripts/facts.py`) or a block (`scripts/render.py`, `scripts/report_pairs.py`,
  `scripts/report.py`). Prose claims must be things the data makes; the code review of 2026-09-16
  found two that it did not, and they were replaced by computed text.
- **One version per run, no pins** (revised 2026-09-16): "lets not pin anything anymore - We'll want
  any new run to use the latest release version of everything out there. The only real requirement
  is that we want all of the experiments in a run to use the same latest version, we don't want to
  switch in the middle." And, the same day, on the baselines: "we want all tools to be the newest
  during a run. especially dolt, doltgres, and doltlite; but 'latest release' is what anyone is going
  to be interested in". `make new-run` is that rule in one command, for all six engines: the Dolt
  engines from their GitHub releases, MySQL and PostgreSQL from their official images on Docker Hub,
  the SQLite shell built from sqlite.org's newest release into the DoltLite image.
- **Present the current run, not a history**: "we don't want this to become a historical record -
  old commits can contain old data - we want to present what we know as current with most recent
  runs". A new run drops the old one's records; git history is the archive. Never build a
  historical table into the documents.
- **Commits**: end each message with the `Co-Authored-By:` line the harness gives for the model you are
  (and the `Claude-Session:` line, when it gives one); pull-request bodies end with the
  `🤖 Generated with [Claude Code]` line. Commit and push to a branch as work lands; open a pull request
  to `main` when the work is complete, and leave the merge to the maintainer.
- **The split** (2026-10-02): "The dolt-unofficial-benchmarking will be where we bring all of the 'side by
  side testing'. It's objective is less about leaving a fully operational instance, and more about
  looking at head-to-head performance and functionality statistics between each of the products that
  we're comparing." Nothing that serves belongs here; a dialect rule found here belongs in
  dolt-megasamples, so the databases people host carry it too.
- **Run alongside the machine's other services** (2026-10-02, for the Threadripper box): the machine is
  shared, so the documents say so (they do, from `build/environment.json`), and the worker's memory cap is
  set to what is free (`DOLTSAMPLES_MEM_WORKER`). The maintainer raised the cap to 16 GiB after the 12 GiB
  OOM below.
- **Knowledge bundle**: every finding, decision and verified engine behaviour is recorded under
  `knowledge/` in the form `knowledge/runbooks/knowledge-bundle-conventions.md` describes;
  `make okf-check` validates it and `scripts/okf_check.py --bundle knowledge --write-index`
  regenerates its indexes. Add a `log.md` entry for every session's work.

## What the previous run found, in brief

On the previous machine (an i9-14900KF, 32 threads, 19.5 GiB of memory under WSL2, 1.5 TB of
disk), on MySQL 9.7.2, Dolt 2.3.2, PostgreSQL 18.6, SQLite 3.46.1, DoltgreSQL 1.3.2 and DoltLite
0.50.10, every unit of every pair was measured, both index policies, plus the three memory studies.
The finding: loaded once with one commit, a Dolt engine's store is a fraction of MySQL's and
PostgreSQL's and somewhat larger than SQLite's; one commit per row costs tens of times the
baseline's disk and hundreds to thousands of times its time, in every engine, and what a Dolt
engine's store tracks is its commits. The numbers are in `main`'s README, REPORT.md and
`build/` (commit 6ff2ec2) and the story of how they were reached is in `knowledge/log.md`.
Expect the new run to differ in detail and, if the engines improved, in kind.

Upstream at the time of writing: Dolt 2.3.5 and DoltgreSQL 1.3.3 are newer than what was
measured; DoltLite 0.50.10 was the newest. `make versions` says what is newest now.

## What this branch starts with

Nothing measured: no `build/results.json`, memory studies, method checks or machine record, and the
documents show `[not measured]` wherever a fact has no measurement; `make check` passes in that state.
`versions.json` names the versions resolved for release 3 on 2026-10-01 -- MySQL 9.7.2 (the LTS track, the
maintainer's choice over the 26.7.0 Innovation release), Dolt 2.4.0, PostgreSQL 18.6, DoltgreSQL 1.3.3,
SQLite 3.53.4 (built from source), DoltLite 0.50.14 -- and `make versions` says whether anything is newer.

## The machine needs

- **Docker Engine** (Docker Desktop on WSL2 worked; every container carries a memory limit and
  swap is off inside them), **Python 3.11 or newer** with PyYAML importable by `python3` (the
  Makefile makes `.venv` with matplotlib and PyYAML for the figures and the bundle checker, using
  `uv` if present), `git`, `gh` (for the pull request), and `make`.
- **dolt-megasamples beside this checkout**: `../dolt-megasamples` (or `DOLT_MEGASAMPLES_DIR=...`), a clone
  of its `main`; nothing in it needs building -- `make export` here runs its export, and `make lite-image`
  here builds its DoltLite image for this repository's versions.
- **The corpus beside this checkout**: `../sql-megasamples` (or `MEGASAMPLES_DIR=...` in the
  environment), cloned and built for MySQL, PostgreSQL and SQLite with the 21 core databases (in
  that repository: `uv sync`, `make configure` or a copied `megasamples.yaml`, `make run`; hours; one
  dataset, `lahman`, must be downloaded by hand from the link its fetch prints and placed where it says,
  then `make run` again). The exports read its images
  (`sql-megasamples-mysql:dev` and the others) or its running servers, and its `build/sqlite/` tree.
- **Disk**: the previous run's stores and exports took several hundred gigabytes, most of it the
  per-row-commit loads of the largest databases, and the maintainer provided 1.5 TB. The runners
  stop before a unit that would take free space below `--floor-gb`.
- **Memory**: the worker cap defaults to 16 GiB (`DOLTSAMPLES_MEM_WORKER`); Dolt's garbage
  collection of the largest per-row-commit store ran at the top of that, and DoltgreSQL's largest
  loads needed 12 GiB (8 GiB was killed). More is better; the memory studies walk a ladder up to
  16 GiB by default, and `make memory-pairs ARGS="--top 12288"` caps the pairs' study on a smaller host.
- **Time**: the previous machine spent roughly two days on the MySQL/Dolt run (both policies),
  39 hours of loads on DoltgreSQL, 18 on DoltLite, and some hours on the three memory studies.
  `make estimate` projects from measured rates once a few units exist.

## The order of work

Nothing else may run on the machine while loads are timed (or, on a shared machine, nothing of this
work); the corpus's MySQL must be up for `make run` (the Dolt loads' rows are checked against it), and
its stack down for the pairs.

1. `make versions`; if anything is newer, **`make new-run`** (resolves the newest release of all six,
   writes `versions.json`, builds the DoltLite image and records the shell it carries). Commit `versions.json`.
2. **`make export`**: dolt-megasamples' export of every database, linked into `build/dumps/`. Then, in the
   corpus checkout, `make compose && docker compose up -d mysql`, and here `make preflight` (every schema
   into MySQL and Dolt, no rows; what each refuses).
3. **`make run`**, then **`make run ARGS="--indexes inline"`**: the MySQL/Dolt loads. `make progress` shows the state.
4. **`make preflight-pairs`**, then bring the corpus's stack down (`make down` there).
5. **`make run-pg`**, **`make run-pg ARGS="--indexes inline"`**, **`make run-lite`**,
   **`make run-lite ARGS="--indexes inline"`**.
6. **`make memory`** and **`make memory-pairs`**.
7. **`make report`**, then **`make check`**; also after every batch of units, so the documents fill in from the top.
8. Rewrite the README's *How far this has been tested* paragraph from what the run took.
9. Knowledge: a tool record per engine version measured (as `knowledge/tools/doltgresql-1-3-2.md` and
   `knowledge/tools/doltlite-0-50-10.md` do), the older ones deprecated; `log.md` entries; `make okf-check`.
   Then the pull request.

## Things that went wrong before, so they need not again

- **The harness kills background processes it started** when it decides memory is short, even
  with plenty free. Anything that must outlive a turn (a chain of runs, an hourly status monitor, a
  disk watchdog) is started with `setsid nohup ... > build/some.log 2>&1 &` from a shell so it is not
  the harness's child, and checked by reading its log. `build/run-*` and `build/*.log` are ignored
  by git.
- **Pausing and resuming a run**: stop the driver shell first, then send the runner SIGTERM, then
  `docker rm -f` its worker container (`doltsamples-dolt-runner`, `doltsamples-doltgres-runner`,
  `doltsamples-lite-runner`, `doltsamples-mysql-timing`, `doltsamples-postgres-timing`). The unit
  in flight is recorded `running` with no runner alive; the next run redoes it. Never edit
  `build/progress.json` while a runner is alive.
- **A zsh pipeline hides an exit code**: `make check | tail` reports `tail`'s status. Use
  `$pipestatus[1]` or redirect to a file and test `$?`.
- **DoltgreSQL's image gives the server 300 s to start**; a per-row-commit store of hundreds of
  thousands of commits takes longer, because the server scans every table on opening. The served
  stack and the memory probe set `DOLTGRES_SERVER_TIMEOUT` (1800 s, `common.DOLTGRES_START_LIMIT`).
- **DoltLite's `VACUUM` had a ceiling** at 0.50.10: its collector's allocations were capped at 2 GiB,
  so the largest per-row-commit store could not be collected (upstream issue dolthub/doltlite#2936,
  fix pull request 2944 in review on 2026-09-16). Such a unit is recorded `settled: false` at its
  working footprint and marked † in the tables. On a newer release, check whether the ceiling is
  gone; `knowledge/questions/doltlite-vacuum-memory.md` and `knowledge/tools/doltlite-0-50-10.md`
  record the finding.
- **The two largest DoltLite inline loads were skipped for disk** on the previous machine, because
  their working files before collection would not fit. With 1.5 TB free and a collector that works,
  run them.
- **DoltgreSQL refused nine views** (functions it lacks: `xpath`, `convert_from`; a `JSON_TABLE`
  view; a `GROUP BY` it rejects), and needed nine dialect rules (`scripts/doltgres_dialect.py`,
  `knowledge/decisions/pair-dialect-rules.md`), each found by refusal. The maintainer reported the
  defects upstream with reproduction repositories (`docs/upstream/`,
  `knowledge/sources/doltgresql-issues-filed-2026-09-11.md`); DoltHub merged fixes for eleven of them
  on 2026-09-16, after 1.3.3 shipped. On a release that carries them, some rules may no longer be
  needed: the preflight shows what is still refused, and a rule that fires without a refusal to
  justify it should be retired and the decision record updated.
- **DoltgreSQL prints a null ordering** (`nulls first`) in some index definitions that PostgreSQL
  does not; the parity check records it as `ordering_differs` rather than failing. Whether to report
  it upstream is an open question for the maintainer.
- **Memory caps**: `DOLTSAMPLES_MEM_WORKER=12g` was the smallest that finished every DoltgreSQL
  load; every unit records the cap it ran under.

## Known at handover: what the clean-room passes of 2026-09-17 established

Three passes on this machine, each from a fresh clone, restricted to `sakila`. The final one, on the
tooling this branch carries, went from `make new-run` to a served and checked stack in one hour with
every check green: MySQL 26.7.0 (the newest official image) loaded the corpus's 9.7.2 dumps without
complaint; the sqlite3 shell built from sqlite.org's 3.53.4 replayed the SQLite dumps once it was built
with Debian's feature set (FTS5 above all -- a plain build refused the corpus's full-text tables, and
`make lite-image` now checks the features); DoltgreSQL 1.3.3 still refuses the same nine views as
1.3.2; DoltLite 0.50.11 loaded and collected `sakila` as 0.50.10 did.

## Known at handover: the corpus's fetch on a fresh machine

Tested on 2026-09-16 by cloning sql-megasamples from GitHub and building it from nothing. Its fetch
crashed on every freshly downloaded artifact until the fix on its branch `fix/fetch-start-time`,
and `chicago_crimes`, a live feed whose extract the city amends, stopped the build on a pinned
digest. Both are settled on the corpus's branch `live-artifacts` (which includes the fetch fix):
a live feed is taken as served and its tests hold a build to floors and structure, by the
maintainer's decision ("we want the data to evolve"). Until that branch is in the corpus's `main`,
clone it by name. One artifact remains a hand download: `lahman`, behind a share link, which the
corpus's README explains; its `make run` builds the other 20, exits non-zero naming it, and builds
it once the file is placed.

## Known at handover: what release 3 found before it was stopped (2026-10-01 to 02)

* **The machine**: an AMD Ryzen Threadripper 3970X (64 threads), 30 GiB, 3.4 TB free, Ubuntu 26.04 on bare
  metal, shared with other services. No Docker Engine: the containers run on rootless Podman 5.7 through
  Docker's own client (29.8.2 in `~/.local/bin`, `docker context use podman`), the maintainer's choice. Memory
  limits, swap off and OOM kills behave as Docker's (verified). The corpus needed three changes to build
  there, on a local branch `rootless-podman` of `../sql-megasamples` (not pushed; the maintainer decides):
  MySQL Shell as container root on a rootless engine, BuildKit asked for only of Docker, and a `.dockerignore`
  Buildah reads as BuildKit does. Two corpus artifacts were re-pinned on content evidence: sakila (Oracle
  re-zipped it; its three files byte-identical to August's) and lahman (Box zips the folder per download;
  all 27 tables matched the corpus's checksums).
* **The run** reached 163 units before the split: every deferred-index MySQL/Dolt unit but one, and 59 of the
  63 inline ones. **employees' one-commit-per-row load on Dolt 2.4.0 was killed for memory under 12 GiB** at
  3,624,968 of 3,919,015 commits, anonymous memory climbing steadily (1.2 GiB at the start, 8.3 GiB at 3.3 M
  commits, about 3.4 GiB more over the last 300,000) with no collection during the load; Dolt 2.3.2 had
  finished it under 16 GiB. The maintainer raised the cap to 16 GiB; whether that suffices on 2.4.0 is not yet
  known. Every unit now records `memory_limit`.

## Open items the maintainer has not decided


- Whether to report the `nulls first` index-definition finding to DoltHub.
- Whether JOURNAL.md should be reframed the way the README was (story first); the maintainer's
  review of the README applies to it too.
- The presentation decision record (`knowledge/decisions/documents-story-first.md`) is pending the
  maintainer's review of the rendered documents.

## Where to look

- `knowledge/index.md`, then the decisions: `engine-versions-one-per-result-set.md` (the version
  rule, revised 2026-09-16), `documents-story-first.md` (how the documents are told),
  `pair-load-shapes-and-measurement.md` (what is measured and how), `pair-dialect-rules.md` (what
  each engine needed changed), `stood-up-instances.md` (the served stack, deprecated: it is dolt-megasamples' now),
  `engine-bugs-patch-or-work-around.md` (the defects and what DoltHub did).
- `knowledge/runbooks/pairs-run.md`: running the pairs, step by step, and the new-run procedure.
- `docs/upstream/`: the bug reports as filed, and their state.
- The README's *Layout* section: what every script is for. `make help` lists every target.
- `PLAN.md`: the plan for release 2, kept as written; this file is the plan for release 3.
