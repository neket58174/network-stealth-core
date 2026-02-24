# Changelog

All notable changes are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- CI and docs now use Ubuntu 24.04 as the primary supported and validated platform.
- Workflow run names were clarified for cleaner Actions history.

## [4.1.7] - 2026-02-22

### Changed

- Reworked docs and workflow guidance for public repository operation.
- Expanded CI safety gates (audits, policy checks, matrix validation).
- Refactored runtime modules and validation paths for clearer contracts.
- Improved rollback and lifecycle reliability under failure scenarios.
- Stabilized bootstrap behavior and release/tag consistency checks.

### Fixed

- Prevented bootstrap pin mismatches in edge cases.
- Improved reliability of health probe parsing and runtime diagnostics.
- Hardened shell flow around cleanup, logging, and fallback paths.

## [4.1.6] - 2026-02-20

### Added

- New operations runbook and refreshed architecture documentation.
- Additional lifecycle and rollback coverage in CI/e2e checks.

### Changed

- Extended modularization across `modules/*` and runtime flows.
- Improved release pipeline hardening and package workflow behavior.
- Updated tested OS matrix and smoke scenarios.

### Fixed

- Improved non-interactive and no-TTY handling for lifecycle commands.
- Hardened artifact consistency checks in `add-clients`/repair paths.

## [4.1.5] - 2026-02-16

### Changed

- Removed legacy/unused download helper paths and aligned tests to active helpers.
- Simplified validation conditionals and lint profile alignment.

### Fixed

- Improved compatibility of HTTP/2 path handling in Git Bash/MSYS contexts.
- Corrected navigation anchors and docs structure in Russian README.

## [4.1.4] - 2026-02-16

### Added

- Expanded RU domain pool and full map coverage checks.
- Domain quarantine controls and no-repeat planning coverage.

### Changed

- Deterministic domain planner integration for install and add-clients paths.
- Strict map-coverage behavior for active tier/domain inputs.

### Fixed

- Normalized map/tier file formatting and encoding issues.

## [4.1.3] - 2026-02-16

### Added

- Transport/schema export validation for SingBox, Nekoray, and v2rayN templates.
- Additional domain health controls and runtime tuning knobs.

### Changed

- Better CLI parsing flexibility and improved runtime UX output consistency.

### Fixed

- More robust minisign fallback behavior when signatures are missing.
- Improved service restart/listening-port verification flow.

## [4.1.2] - 2026-02-15

### Fixed

- Stabilized CI shell/lint behavior for environment-specific include paths.
- Improved reliability of tests involving domain ranking and noisy output.

## [4.1.1] - 2026-02-15

### Added

- Domain health ranking with score file integration.
- Release consistency checks across script version, docs badges, and changelog.

### Fixed

- Improved update path behavior for not-installed/unknown version states.
- Persisted health-related runtime settings in generated environment files.

## [4.1.0] - 2026-02-15

### Added

- Optional `http2` transport mode alongside default `grpc`.
- Extended export templates and runtime validation helpers.
- New runtime and security controls for update/install flows.

### Changed

- Expanded domain/SNI/service pools and adjusted runtime defaults.
- Strengthened non-interactive handling and lifecycle checks.

### Security

- Hardened random generation and bootstrap/install verification behavior.
- Strengthened firewall and temp-file safety in core flows.

## [4.0.0] - 2026-02-12

### Added

- Major architecture revision around Reality-focused transport strategy.
- Consolidated automation flows for install, monitoring, and exports.
- Stronger validation and hardening defaults across service lifecycle.

### Removed

- Legacy GoodbyeDPI integration and outdated transport modes.
- Obsolete interactive and legacy export paths.

## [3.5.1] - 2026-01-23

### Added

- CI matrix validation and expanded BATS coverage foundations.

### Fixed

- Stability issues in coverage/test execution environments.

## [3.5.0] - 2025-02-14

### Added

- Initial modular script architecture.
- Update automation, health monitoring, and rollback framework.
- Multi-client export capability and service hardening base.
