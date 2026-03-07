# Glossary

## xhttp-only install

The default install contract. `install` chooses the minimal strongest-default path with xhttp and reduced questioning.

## Advanced mode

`install --advanced`. Enables manual profile and config-count prompts.

## Migrate-stealth

Managed action that converts a legacy `grpc/http2` install to xhttp and rebuilds artifacts.

## Tier

A predefined domain pool used to generate destination and SNI combinations.

## Profile

User-facing selection mapped to an internal tier and config limits such as `ru`, `ru-auto`, or `global-50`.

## Legacy transport

Managed config that still uses `grpc` or `http2`. `status` marks it as legacy and mutating actions require migration first.

## Client variant

A per-config client profile stored inside `clients.json` `variants[]`.

## Recommended variant

The primary xhttp client artifact that uses `mode=auto`.

## Rescue variant

The fallback xhttp client artifact that uses `mode=packet-up`.

## Raw xray export

Per-variant client json files written to `export/raw-xray/`.

## Capability matrix

`export/capabilities.json`, the machine-readable support map for native, link-only, and unsupported export targets.

## Self-check state

`/var/lib/xray/self-check.json`, the last transport-aware verdict recorded after a mutating action.

## Measurement harness

`scripts/measure-stealth.sh`, a local probe tool that reuses the runtime self-check engine.

## SNI fallback

Automatic selection of another valid server name when the preferred SNI is unavailable.

## Domain planner

Module that chooses domains using ranking, quarantine, and no-repeat sequencing.

## Health file

`DOMAIN_HEALTH_FILE` runtime state used for domain ranking and quarantine decisions.

## Strict minisign mode

`--require-minisign` behavior where missing verifier or signature fails install or update.

## Compatibility mode (no systemd)

`--allow-no-systemd` mode for constrained environments where full service management is unavailable.

## Artifact consistency

State where `config.json`, `keys.txt`, `clients.txt`, `clients.json`, export files, and self-check state reflect one coherent config set.
