# Security policy

This document defines the security posture and disclosure process for **Network Stealth Core**.

## Supported versions

| Version line | Status |
|---|---|
| `5.1.x` | supported |
| `<5.1` | unsupported in this repository |

## Reporting vulnerabilities

Use responsible disclosure:

1. do not open public issues for security bugs
2. use GitHub private vulnerability reporting
3. include impact, reproduction steps, affected version or commit, and an optional patch proposal

Target response windows:

- initial triage: up to 48 hours
- critical patch target: up to 7 days

## Practical threat model

| Threat | Mitigation |
|---|---|
| bootstrap and download tampering | pinned bootstrap support, SHA256 checks, optional strict minisign mode |
| command or path injection | strict validators and safe path guards |
| partial write corruption | atomic writes and staged validation |
| failed update, repair, or migration | rollback stack and runtime reconciliation |
| service over-privilege | dedicated `xray` user and restrictive `systemd` settings |
| stale client artifact exposure | strict permissions plus full artifact rebuild from managed config |

## Security controls

### Integrity and download surface

- https-only download flows with strict validation
- allowlisted critical hosts (`DOWNLOAD_HOST_ALLOWLIST`)
- artifact integrity checks (`sha256`, optional strict `REQUIRE_MINISIGN=true`)
- pinned minisign trust anchor with fingerprint check (`MINISIGN_KEY`)
- bootstrap pin control via `XRAY_REPO_COMMIT`
- wrapper code-source trust boundary for `XRAY_DATA_DIR` with explicit opt-in (`XRAY_ALLOW_CUSTOM_DATA_DIR=true`)

Current pinned minisign key fingerprint (`sha256` of `MINISIGN_KEY` content):

- `294701ab7f6e18646e45b5093033d9e64f3ca181f74c0cf232627628f3d8293e`

### Privilege separation

- service runs under dedicated non-root account (`xray`)
- minimal capability set for low-port binding

### Systemd hardening

Project unit applies controls such as:

- `NoNewPrivileges=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `PrivateTmp=true`
- `ProtectKernelTunables=true`
- `ProtectKernelModules=true`
- `ProtectControlGroups=true`
- syscall filtering and restricted address families

### Input and runtime validation

Validation coverage includes:

- domain, port, IPv4, IPv6 formats
- gRPC service names and xhttp path normalization
- destructive operation path safety
- URL and schedule format checks
- runtime range constraints

### Artifact safety

- `clients.json` is schema v2 and remains permission-restricted
- xhttp-first installs generate per-config variants instead of one ambiguous client link
- raw xray exports are rebuilt from managed config and stored under restricted paths

### Rollback safety

- pre-change backup snapshot
- automatic rollback on failure paths
- firewall rollback records
- runtime reconciliation after restore

## Sensitive paths and intended permissions

| Path | Owner | Mode | Purpose |
|---|---|---:|---|
| `/usr/local/bin/xray` | `root:root` | `0755` | Xray binary |
| `/etc/xray/config.json` | `root:xray` | `0640` | server config |
| `/etc/xray-reality/config.env` | `root:root` | `0600` | runtime snapshot |
| `/etc/xray/private` | `root:xray` | `0750` | sensitive root directory |
| `/etc/xray/private/keys/keys.txt` | `root:root` | `0400` | private key material |
| `/etc/xray/private/keys/clients.txt` | `root:xray` | `0640` | human-readable client summary |
| `/etc/xray/private/keys/clients.json` | `root:xray` | `0640` | structured client metadata (`schema_version: 2`) |
| `/etc/xray/private/keys/export/raw-xray/*.json` | `root:xray` | `0640` | raw xray client artifacts |
| `/var/backups/xray` | `root:root` | `0700` | rollback sessions |

## Risky overrides

These flags weaken default guarantees and should be temporary:

- `ALLOW_INSECURE_SHA256=true`
- `ALLOW_UNVERIFIED_MINISIGN_BOOTSTRAP=true`
- `ALLOW_NO_SYSTEMD=true`
- `GEO_VERIFY_HASH=false`
- `XRAY_ALLOW_CUSTOM_DATA_DIR=true` (only for trusted, non-world-writable module source paths)

## Operational recommendations

1. prefer tagged releases for production-like deployments
2. keep legacy `grpc/http2` installs on a short migration window
3. monitor `journalctl -u xray` and health logs
4. restrict shell and admin access to the host
5. rotate or redeploy when compromise is suspected

## Security testing signals

Security-sensitive behavior is covered by:

- validator tests
- path safety tests
- rollback and lifecycle tests
- export schema validation
- CI audit gates and docs command contract checks

For operations-side incident response, see [../docs/en/OPERATIONS.md](../docs/en/OPERATIONS.md).
