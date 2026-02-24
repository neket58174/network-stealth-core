# Security policy

This document defines the security posture and disclosure process for `Xray Reality Ultimate`.

## Supported versions

| Version Line | Status |
|---|---|
| `4.x` | supported |
| `<4.0` | unsupported |

## Reporting vulnerabilities

Use responsible disclosure:

1. do not open public issues for security bugs
2. use GitHub private vulnerability reporting
3. include impact, reproduction steps, affected version/commit, and optional fix suggestion

Target response windows:

- initial triage: up to 48 hours
- critical patch target: up to 7 days

## Practical threat model

| Threat | Mitigation |
|---|---|
| bootstrap/download tampering | pinned bootstrap support, SHA256 checks, optional minisign verification |
| command/path injection | strict validators, safe path guards, sanitized runtime values |
| partial write corruption | atomic writes + staged validation |
| failed updates/install | rollback stack + runtime reconciliation |
| service over-privilege | unprivileged `xray` user + hardened `systemd` unit |

## Security controls

### Integrity and download surface

- HTTPS-only download flows with strict validation
- allowlisted critical hosts (`DOWNLOAD_HOST_ALLOWLIST`)
- artifact integrity checks (`sha256`, optional `minisign`)
- bootstrap pin control via `XRAY_REPO_COMMIT`

### Privilege separation

- service runs under dedicated non-root account (`xray`)
- minimal required capabilities (including bind capability for low ports)

### Systemd hardening

Project-generated unit applies hardening controls such as:

- `NoNewPrivileges=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `PrivateTmp=true`
- `ProtectKernelTunables=true`
- `ProtectKernelModules=true`
- `ProtectControlGroups=true`
- syscall filtering and restricted address families

### Input and runtime validation

Validation layer covers:

- domains, ports, IPv4/IPv6
- gRPC service names
- file paths for destructive operations
- URL and schedule format checks
- runtime range constraints

### Rollback safety

- backup snapshot before mutating operations
- automatic rollback on error paths
- firewall rollback records for network changes
- runtime state reconciliation after restore

## Sensitive paths and intended permissions

| Path | Owner | Mode | Purpose |
|---|---|---:|---|
| `/usr/local/bin/xray` | `root:root` | `0755` | Xray binary |
| `/etc/xray/config.json` | `root:xray` | `0640` | server config |
| `/etc/xray-reality/config.env` | `root:root` | `0600` | runtime environment snapshot |
| `/etc/xray/private` | `root:xray` | `0750` | sensitive root directory |
| `/etc/xray/private/keys/keys.txt` | `root:root` | `0400` | private key material |
| `/etc/xray/private/keys/clients.txt` | `root:xray` | `0640` | client links |
| `/etc/xray/private/keys/clients.json` | `root:xray` | `0640` | structured client metadata |
| `/var/backups/xray` | `root:root` | `0700` | rollback sessions |

## Risky overrides

These flags reduce default security guarantees and should be temporary:

- `ALLOW_INSECURE_SHA256=true`
- `ALLOW_UNVERIFIED_MINISIGN_BOOTSTRAP=true`
- `GEO_VERIFY_HASH=false`

## Operational security recommendations

1. run production from tagged releases
2. update regularly via controlled maintenance windows
3. monitor `journalctl -u xray` and health logs
4. restrict shell/admin access on the host
5. rotate/redeploy on compromise suspicion

## Security testing signals

Security-sensitive behavior is covered by automated checks including:

- validator correctness tests
- path safety guard tests
- rollback and lifecycle integrity tests
- export schema validation
- CI audit gates and command contract checks

For operations-side response, use [OPERATIONS.md](OPERATIONS.md).
