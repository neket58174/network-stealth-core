# Changelog

All notable changes are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- Expanded `tier_global_ms10` domain pool from 10 to 50 domains with full SNI and gRPC map coverage.

## [4.2.0] - 2026-02-26

### Changed

- Normalized operations commands to use installed `xray-reality.sh` invocation form.
- Aligned docs wording around Ubuntu 24.04 LTS support scope and repository-supported version line.
- Added explicit compatibility flags: `--allow-no-systemd` and `--require-minisign`.
- Documented pinned minisign trust-anchor fingerprint policy in security docs.

### Fixed

- Install now neutralizes conflicting `systemd` drop-ins in `xray.service.d` that override runtime-critical fields (for example `ExecStart`, `User`, `Group`), preventing false startup/listening failures.
- `install` / `update` / `repair` now fail fast when `systemd` is unavailable (unless explicit compatibility mode is enabled).
- Strict minisign mode now fails closed when minisign/signature is unavailable, with explicit unsafe bypass only via `ALLOW_INSECURE_SHA256=true`.
- Domain planning now avoids adjacent duplicate domains across shuffled cycles when pool size is greater than one.
- Corrected emergency diagnostics command to use `journalctl --no-pager` (fixed invalid `--no-page` flag path).

## [4.1.8] - 2026-02-24

### Changed

- Focused CI and documentation on Ubuntu 24.04 as the validated target platform.
- Clarified workflow run naming and release/package metadata in GitHub Actions.
- Refreshed public docs wording to remove overstatements and host-specific language.
- Added Ubuntu 24.04 release checklist and maintenance notes.
- Removed non-essential shell comments to keep scripts easier to audit.

### Fixed

- Corrected BBR sysctl value handling in runtime tuning paths.
- Improved behavior in isolated root environments without explicit chroot wording.

## [4.1.7] - 2026-02-22

### Note

- Baseline release imported into this repository.

## [<4.1.7]

### Note

- Older release artifacts are not published in this repository after migration.
- Historical details for these versions were intentionally collapsed for clarity.
