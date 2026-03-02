# Changelog

All notable changes in **Network Stealth Core** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- Documentation moved to bilingual structure: `docs/en` and `docs/ru`.
- Public naming unified to `Network Stealth Core` across scripts and docs.

## [4.2.0] - 2026-02-26

### Changed

- Normalized operations commands to use installed `xray-reality.sh`.
- Aligned docs wording around Ubuntu 24.04 LTS support scope.
- Added explicit compatibility flags: `--allow-no-systemd` and `--require-minisign`.
- Documented minisign trust-anchor fingerprint policy.
- Expanded `tier_global_ms10` domain pool from 10 to 50 domains.

### Fixed

- Install now neutralizes conflicting `systemd` drop-ins that override runtime-critical fields.
- `install`, `update`, and `repair` now fail fast when `systemd` is unavailable unless compatibility mode is enabled.
- Strict minisign mode now fails closed when signature verification cannot be completed.
- Domain planning avoids adjacent duplicate domains when pool size allows.
- Corrected diagnostics command to use `journalctl --no-pager`.

## [4.1.8] - 2026-02-24

### Changed

- Focused CI and documentation on Ubuntu 24.04 as the validated target.
- Clarified workflow run naming and package metadata in GitHub Actions.
- Refreshed docs language for public repository operation.
- Added Ubuntu 24.04 release checklist and maintenance notes.

### Fixed

- Corrected BBR sysctl value handling in runtime tuning paths.
- Improved behavior in isolated root environments.

## [4.1.7] - 2026-02-22

### Note

- Baseline release imported into this repository.

## [<4.1.7]

### Note

- Older release artifacts are not published in this repository after migration.
- Historical details for these versions are intentionally collapsed.
