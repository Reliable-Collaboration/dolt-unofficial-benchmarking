# dolt-unofficial-benchmarking: each Dolt engine against the database it stands in for, on the sql-megasamples data.
# Every target is a thin shim over a script in scripts/, so the experiment can be run without make.
PY ?= python3

# Every target is phony. `docs` is the one that made this matter: a directory named docs/
# exists, so Make considered the target satisfied and silently skipped it -- both directly
# and as a prerequisite of `report`, which is why the documents stayed stale while every
# other step ran. Generated from the targets themselves so a new one cannot be forgotten.
.PHONY: all audit charts check clean clean-data collect docs environment estimate experiment export help load measure measure-all method-checks preflight progress report run summary trace watch \
        lite-image preflight-pairs run-pg run-lite okf-check clean-pairs memory-pairs catalogue new-run memory clean-run versions

help:
	@echo "make run        the whole experiment, timed: 5 loads x every database (hours)"
	@echo "make progress   what the run has done, is doing, and has left"
	@echo "make watch      the same, redrawn every minute"
	@echo "make all        the size-only pipeline: export -> load -> measure -> report"
	@echo "make export     every database out of the corpus through ../dolt-megasamples, all three sources, into build/dumps/"
	@echo "make load       load those dumps into Dolt, commit and gc"
	@echo "make measure    size both engines and check they hold the same rows"
	@echo "make report     regenerate REPORT.md, the README tables and the figures"
	@echo "make charts     regenerate the figures only (matplotlib, in .venv)"
	@echo "make collect    fold the timed run into build/results.json (make report does this)"
	@echo "make measure-all  row counts and index parity for every mode that was loaded"
	@echo "make preflight  load every schema into both engines before running the loads"
	@echo ""
	@echo "The PostgreSQL/DoltgreSQL and SQLite/DoltLite pairs (scripts/pairs.py):"
	@echo "make lite-image     build the DoltLite image from the .deb packages versions.json names (checksummed)"
	@echo "make preflight-pairs  every schema into PostgreSQL, DoltgreSQL, SQLite and DoltLite; what each refuses"
	@echo "make run-pg | run-lite  the five timed loads of a pair (ARGS=\"--only sakila --indexes inline\")"
	@echo "make memory-pairs   what DoltgreSQL and DoltLite need to open each database in each shape (build/memory_pairs.json)"
	@echo "make okf-check      validate the knowledge bundle (knowledge/)"
	@echo "make versions       each engine's version here beside the newest release upstream"
	@echo "make new-run        start a new run: every Dolt engine to its newest release, the old run's units dropped"
	@echo "make catalogue      copy each database's one-line description from the corpus checkout (build/catalogue.json)"
	@echo "make memory         what Dolt needs to open each database in each shape (build/memory.json)"
	@echo "make clean-run      remove every measured artefact (results, studies, machine record, figures, run state) for a fresh run"
	@echo "make audit      check the measurements against invariants that must hold"
	@echo "make docs       regenerate README.md and JOURNAL.md from docs/templates and build/"
	@echo "make trace      what the per-row-commit loads cost in memory as history accumulated"
	@echo "make estimate   project how long a full run takes, from measured rates"
	@echo "make summary    the whole experiment as labelled tables: disk, time, memory, progress"
	@echo "make experiment the row-INSERT and per-row-commit loads, then the report"
	@echo "make check      fail if the report, the README table or a prose number is stale"
	@echo "make clean-data delete the Dolt data directory (written as root inside the container)"
	@echo "make clean-pairs delete the PostgreSQL, DoltgreSQL, SQLite and DoltLite stores of every shape (keeps the exports)"

all: export load measure report

# dolt-megasamples exports every database from the corpus -- mysqldump both statement styles (the
# extended INSERTs the bulk load uses, one INSERT per row for the row-by-row loads), pg_dump three
# ways, the SQLite files and their dumps, the references -- and the files are linked into build/dumps/
export:
	@$(PY) scripts/export.py $(ARGS)
load:
	@$(PY) scripts/load_dolt.py
measure:
	@$(PY) scripts/measure.py

# Row counts and index parity for every mode that has a data directory, not just the one-shot load.
# run_all.py verifies row counts as each unit finishes; this is what puts the index comparison for
# each mode into results.json, including both index policies.
MEASURE_MODES = oneshot rowinsert rowcommit rowinsert_inline rowcommit_inline
measure-all:
	@for m in $(MEASURE_MODES); do \
	  test -d data/dolt$$(test $$m = oneshot || echo -$$m) && \
	    $(PY) scripts/measure.py --mode $$m || true; \
	done
# collect folds build/progress.json -- what the timed run actually did -- into build/results.json,
# which is what the report and the figures read. Nothing called it, so the documented path of
# `make run` then `make report` built the report from whatever results.json happened to hold, which
# after a `make clean-data` is nothing at all.
collect:
	@$(PY) scripts/collect.py
	@$(PY) scripts/collect_pairs.py

report: environment method-checks collect charts docs

# The figures. matplotlib lives in .venv because it is this repository's only dependency; the rest
# of the pipeline runs on the system python and shells out to docker.
environment:
	@$(PY) scripts/environment.py >/dev/null && echo "  . recorded the machine into build/environment.json"
method-checks:
	@$(PY) scripts/method_checks.py

charts: .venv/.deps-matplotlib-pyyaml
	@.venv/bin/python scripts/charts.py

# matplotlib for the figures, PyYAML for the knowledge bundle's checker. The stamp names the
# dependencies, so adding one reaches a .venv that already exists.
.venv/.deps-matplotlib-pyyaml:
	@test -x .venv/bin/python || uv venv .venv >/dev/null 2>&1 || python3 -m venv .venv
	@(uv pip install -q --python .venv/bin/python matplotlib pyyaml >/dev/null 2>&1 || .venv/bin/pip install -q matplotlib pyyaml)
	@touch $@
	@echo "  . .venv has matplotlib and PyYAML"

# The whole experiment, timed: five loads of every database across both engines, resumable and
# observable. Expect many hours -- the per-row-commit phase alone is most of it.
# Two minutes that can save six hours: load every schema, without its rows, into both engines and
# report anything either refuses -- especially anything only one of them refuses.
preflight:
	@$(PY) scripts/preflight.py

run: preflight
	@$(PY) scripts/run_all.py $(ARGS)
progress:
	@$(PY) scripts/progress.py
watch:
	@$(PY) scripts/progress.py --watch

# The row-by-row loads used to run here over a hand-picked subset of the smallest databases, which
# is why earlier reports had holes in them. `make run` runs every phase over every database and
# records the timings as well, so that is the only supported way to produce the experiment now.
experiment:
	@echo "'make experiment' ran the row-by-row loads over a subset of the databases and left"
	@echo "the report with gaps in it. Use 'make run' instead -- every phase over every database,"
	@echo "timed and resumable -- and then 'make report'."
	@echo "For the index-maintenance comparison: python3 scripts/run_all.py --indexes inline"
	@false
# audit first: check_claims verifies the prose matches the measurements, but says nothing about
# whether the measurements are consistent with each other. The row count that broke this experiment
# passed every claim check, because the prose faithfully reported the wrong number.
# Every document is generated, so there is nothing hand-written left to pin to the measurements.
# audit.py checks the measurements against each other; render.py --check checks that the documents
# on disk are what those measurements produce.
docs:
	@$(PY) scripts/render.py

check:
	@$(PY) scripts/audit.py
	@$(PY) scripts/render.py --check
	@$(MAKE) --no-print-directory okf-check

# Dolt's container writes as root, so the host user cannot delete data/dolt directly -- `rm -rf`
# fails with "Permission denied" on every file and leaves the directory looking loaded. Removing it
# from inside a container is the only thing that works without sudo.
# Every mode has its own directory -- data/dolt, data/dolt-rowinsert, data/dolt-rowcommit and the
# two _inline variants -- so the wildcard matters: deleting data/dolt alone left the row-by-row
# results in place and the next run measured them again.
clean-data:
	@$(PY) scripts/clean_pairs.py --everything

# The two further pairs' stores, prepared dumps and recorded units (scripts/clean_pairs.py says why
# the records go too); the exports and the MySQL/Dolt measurements are kept.
clean-pairs:
	@$(PY) scripts/clean_pairs.py

clean: clean-data

audit:
	@$(PY) scripts/audit.py

trace:
	@$(PY) scripts/trace_report.py

estimate:
	@$(PY) scripts/estimate.py

summary:
	@$(PY) scripts/summary.py

# ---------------------------------------------------------------- the two further pairs ---
versions:
	@$(PY) scripts/versions.py --check
# the Dolt memory study, the pairs' counterpart of memory-pairs (scripts/memory_profile.py)
memory:
	@$(PY) scripts/memory_profile.py $(ARGS)

# A fresh run on a fresh machine: every artefact that records a measurement goes -- the folded results,
# the memory studies, the method checks, the machine record, the spike's results, the figures and the
# run state -- so nothing measured
# elsewhere can survive into the new run's documents. The stores (data/) and the exports (build/dumps/)
# are only named: they are large, and removing them is `make clean-data` and `make clean-pairs`.
clean-run:
	@rm -f build/results.json build/memory.json build/memory_pairs.json build/method.json build/environment.json \
	  build/progress.json build/results.json.previous \
	  docs/img/*.png build/spike-concurrent/*.json
	@echo "  . removed every measured artefact; versions.json and build/catalogue.json stay (make new-run and make catalogue rewrite them)"
	@test ! -d data || echo "  ! data/ still holds stores from the last run: make clean-data (Dolt) and make clean-pairs (the pairs) remove them"
	@test ! -d build/dumps || echo "  ! build/dumps/ still holds the last run's exports: rm -rf build/dumps to export afresh"

# a new run: every Dolt engine to its newest release, the old run's units dropped, the DoltLite image
# rebuilt with the sqlite3 shell it carries recorded
new-run:
	@$(PY) scripts/versions.py --latest
	@$(PY) scripts/lite_image.py --record

lite-image:
	@$(PY) scripts/lite_image.py
preflight-pairs:
	@$(PY) scripts/preflight_pairs.py $(ARGS)
run-pg:
	@$(PY) scripts/run_pairs.py --pair pg $(ARGS)
run-lite:
	@$(PY) scripts/run_pairs.py --pair lite $(ARGS)
# what each database is, in the corpus's own words; needs the sql-megasamples checkout (MEGASAMPLES_DIR)
catalogue:
	@$(PY) scripts/catalogue.py

memory-pairs:
	@$(PY) scripts/memory_profile_pairs.py $(ARGS)
okf-check: .venv/.deps-matplotlib-pyyaml
	@.venv/bin/python scripts/okf_check.py --bundle knowledge && .venv/bin/python scripts/okf_fix_quotes.py --bundle knowledge --check
