# audit findings backlog

date: 2026-03-11
baseline snapshot: `ubuntu` working tree after service runtime extraction

## prioritized open items

### p3

#### f-003 — continue decomposing oversized root entrypoints

- type: maintainability
- files:
  - `lib.sh`
  - `config.sh`
- problem:
  - core orchestration files are still large and blend multiple responsibilities.
  - `config.sh`, `service.sh`, and `install.sh` were already reduced by focused module extraction, but `lib.sh` remains the biggest orchestration hotspot and `config.sh` still carries a broad apply/build surface.
- recommended fix direction:
  - keep moving behavior into modules by subsystem, not by arbitrary helper dumping.
  - prefer smaller action-focused files with explicit contracts.
- acceptance:
  - root files mostly dispatch and compose, while behavior lives in focused modules.

## not confirmed as open bugs in this pass

- no p0/p1 runtime defect was proven
- no active dead runtime function was proven
- no release-blocking security regression was found in the audited baseline

## resolved since the older audit baseline

these older items are no longer open:

- xhttp planner dependency on a grpc-named active data contract
- workflow lint coverage mismatch between `make lint` and `tests/lint.sh`
- hardening `xray_data_dir` trust boundary
- bashate policy mismatch between `make lint` and `tests/lint.sh`
- dead-function checker false negatives from comment/string matches
