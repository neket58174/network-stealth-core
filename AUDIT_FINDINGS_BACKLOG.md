# Audit Findings Backlog

Date: 2026-03-05  
Scope: full shell audit (43 files)

## Prioritized items

## P2

### F-001 — Harden module source trust boundary (`XRAY_DATA_DIR`)

- Status: Closed
- Files:
  - [xray-reality.sh](D:\Project\network-stealth-core\xray-reality.sh)
- Resolution:
  - `XRAY_DATA_DIR` trust validation executes before any `source`.
  - Non-default path requires explicit opt-in: `XRAY_ALLOW_CUSTOM_DATA_DIR=true`.
  - Custom path is blocked if directory permissions are unsafe (group/other writable).
  - BATS coverage includes reject/allow/unsafe/default-path scenarios.

## P3

### F-002 — Unify lint policy between `make lint` and `tests/lint.sh`

- Status: Closed
- Files:
  - [Makefile](D:\Project\network-stealth-core\Makefile)
  - [tests/lint.sh](D:\Project\network-stealth-core\tests\lint.sh)
- Resolution:
  - `make lint` and `tests/lint.sh` both enforce `bashate` with identical ignored rules.
  - Lint policy is aligned between local and CI entry points.

### F-003 — Improve dead-function check precision

- Status: Closed
- File:
  - [scripts/check-dead-functions.sh](D:\Project\network-stealth-core\scripts\check-dead-functions.sh)
- Resolution:
  - Checker strips shell literals/comments before matching call sites.
  - Regression tests confirm comment/string mentions are not treated as executable calls.

## Deferred / no action now

- No P0/P1 findings in current pass.
- No mandatory runtime bugfix required for `4.2.1` stability based on this audit.
