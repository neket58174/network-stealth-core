# Changelog

All notable changes are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- Normalized operations commands to use installed `xray-reality.sh` invocation form.
- Aligned docs wording around Ubuntu 24.04 LTS support scope and repository-supported version line.

### Fixed

- Install now neutralizes conflicting `systemd` drop-ins in `xray.service.d` that override runtime-critical fields (for example `ExecStart`, `User`, `Group`), preventing false startup/listening failures.

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
