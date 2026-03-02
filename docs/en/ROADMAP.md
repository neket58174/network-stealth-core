# Roadmap

This roadmap is a directional public plan, not a strict delivery promise.

## Current priorities

1. Reliability of install/update/repair flows
2. Deterministic rollback under edge-case failures
3. Better operator observability and diagnostics
4. Documentation quality for public onboarding

## Near-term work

- Improve domain health telemetry readability
- Expand targeted tests around lifecycle edge cases
- Keep CI fast while preserving release safety gates
- Refine prompts and UX for interactive and non-interactive modes

## Mid-term work

- Improve profile-level flexibility without breaking safe defaults
- Add more structured diagnostics export formats
- Better separation of policy config vs generated runtime artifacts

## Out of scope (for now)

- broad multi-OS support claims without CI validation
- enterprise orchestration features without clear maintenance budget
- opaque behavior changes without changelog and migration notes

## How to influence roadmap

- open a Discussion with concrete use case and expected behavior
- provide reproducible issue data for reliability gaps
- submit PRs that include tests and docs
