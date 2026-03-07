# Operations runbook

This runbook is the operations reference for **Network Stealth Core**.

## Installation entry points

### Universal install (recommended)

```bash
curl -fL https://raw.githubusercontent.com/neket371/network-stealth-core/ubuntu/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

### One-line install

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/neket371/network-stealth-core/ubuntu/xray-reality.sh) install
```

If `/dev/fd` is unavailable, use universal install.

Migration note: legacy `main` is supported as a temporary alias for one release cycle; canonical branch is `ubuntu`.

Install contract note:

- `install` uses the minimal xhttp-only path (`ru-auto`, auto count, strongest default)
- `install --advanced` enables manual profile/count prompts
- `--transport grpc|http2` is rejected in v6

## Runtime assumptions

- default `install`, `update`, and `repair` expect working `systemd`
- for constrained environments, use `--allow-no-systemd`
- for fail-closed signature policy, use `--require-minisign`
- custom wrapper source path requires explicit opt-in:
  `XRAY_ALLOW_CUSTOM_DATA_DIR=true XRAY_DATA_DIR=/secure/path`

## Public release sanity checklist (Ubuntu 24.04 LTS)

Supported and validated target for this checklist: **Ubuntu 24.04 LTS**.

### Local quality gate (must pass)

```bash
make ci
```

### Fresh host smoke (must pass)

On clean Ubuntu 24.04:

```bash
curl -fL https://raw.githubusercontent.com/neket371/network-stealth-core/ubuntu/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
sudo xray-reality.sh status --verbose
sudo xray -test -c /etc/xray/config.json
sudo xray-reality.sh add-clients 1 --non-interactive --yes
sudo xray-reality.sh repair --non-interactive --yes
sudo xray-reality.sh update --non-interactive --yes
sudo xray-reality.sh uninstall --non-interactive --yes
```

Expected:

- service is `active` after install/update/repair
- `xray -test` exits `0`
- self-check verdict is `ok` or `warning`, never `broken`
- `clients.json`, `export/raw-xray/`, and `export/capabilities.json` are present
- uninstall removes managed files and systemd units

## Daily health check

```bash
sudo xray-reality.sh status --verbose
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo xray-reality.sh diagnose
```

Review in verbose status:

- transport
- last self-check verdict
- selected variant and latency
- export capability summary

## Safe maintenance cycle

### Update

```bash
sudo xray-reality.sh check-update
sudo xray-reality.sh update
sudo xray-reality.sh status --verbose
```

### Add client configurations

```bash
sudo xray-reality.sh add-clients 2
sudo xray-reality.sh status --verbose
```

Expected artifact set:

- `/etc/xray/private/keys/keys.txt`
- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json` (`schema_version: 2`, per-config `variants[]`)
- `/etc/xray/private/keys/export/raw-xray/*`
- `/etc/xray/private/keys/export/capabilities.json`
- `/etc/xray/private/keys/export/compatibility-notes.txt`
- `/var/lib/xray/self-check.json`

### Migrate managed legacy transport

```bash
sudo xray-reality.sh status --verbose
sudo xray-reality.sh migrate-stealth --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Expected:

- pre-migration status may show `legacy transport`
- post-migration status shows `Transport: xhttp`
- `clients.json`, `export/raw-xray/`, and `export/capabilities.json` are rebuilt for xhttp variants
- blocked mutating actions (`update`, `repair`, `add-clients`) become available again

## Capability-driven exports

Read the machine-readable export matrix:

```bash
sudo jq . /etc/xray/private/keys/export/capabilities.json
```

Expected baseline:

- `raw-xray` = `native`
- `clients.txt` / `clients.json` = `native`
- `v2rayn-links` / `nekoray-template` = `link-only`
- `sing-box` / `clash-meta` = `unsupported`

## Measurement harness

Run the local probe harness against managed artifacts:

```bash
sudo bash scripts/measure-stealth.sh --output /tmp/measure-stealth.json
```

Optional variant selection:

```bash
sudo bash scripts/measure-stealth.sh --variants recommended,rescue
```

Use the report to compare reachability and latency for real networks.

## Incident matrix

| Incident | Immediate action | Verify |
|---|---|---|
| `xray` not active | `sudo systemctl restart xray` | `systemctl is-active xray` |
| config test fails | `xray -test -c /etc/xray/config.json`, then rollback | config test exits `0` |
| self-check `warning` | inspect selected variant and probe results | `status --verbose` / state file |
| self-check `broken` | `sudo xray-reality.sh rollback` | service active + verdict recovers |
| failed update | `sudo xray-reality.sh rollback` | service active + artifacts consistent |
| domain instability | inspect `/var/lib/xray/domain-health.json` | fail trend improves |
| firewall drift | `sudo xray-reality.sh repair` | expected ports are open/listening |

## Rollback playbook

### Latest backup

```bash
sudo xray-reality.sh rollback
```

### Specific backup

```bash
sudo xray-reality.sh rollback /var/backups/xray/<session-dir>
```

### Post-rollback verification

```bash
sudo xray-reality.sh status --verbose
sudo journalctl -u xray -n 100 --no-pager
```

## Runtime tuning knobs

| Variable | Effect |
|---|---|
| `DOMAIN_HEALTH_PROBE_TIMEOUT` | probe timeout per domain |
| `DOMAIN_HEALTH_RATE_LIMIT_MS` | delay between probes |
| `DOMAIN_HEALTH_MAX_PROBES` | maximum probes per cycle |
| `DOMAIN_QUARANTINE_FAIL_STREAK` | quarantine trigger |
| `DOMAIN_QUARANTINE_COOLDOWN_MIN` | quarantine duration |
| `PRIMARY_DOMAIN_MODE` | first-domain strategy |
| `PROGRESS_MODE` | `auto`, `bar`, `plain`, `none` |
| `SELF_CHECK_ENABLED` | enable or disable transport-aware self-check |
| `SELF_CHECK_URLS` | comma-separated HTTPS probe URLs |
| `SELF_CHECK_TIMEOUT_SEC` | curl timeout per self-check probe |

Example:

```bash
sudo env DOMAIN_HEALTH_PROBE_TIMEOUT=3 \
  DOMAIN_HEALTH_MAX_PROBES=12 \
  SELF_CHECK_TIMEOUT_SEC=10 \
  PROGRESS_MODE=plain \
  xray-reality.sh repair
```

## Uninstall procedure

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

Post-uninstall checks:

- `id xray` should fail
- `/etc/xray`, `/etc/xray-reality`, `/usr/local/bin/xray` should be removed
- `/var/lib/xray/self-check.json` should be removed
- previously used service ports should not listen

## Escalation package

Collect before opening an issue:

- `sudo xray-reality.sh diagnose`
- `sudo journalctl -u xray -n 500 --no-pager`
- `/etc/xray/config.json` with secrets redacted
- `/etc/xray/private/keys/clients.json` if artifact mismatch is involved
- `/var/lib/xray/self-check.json` if verdict/debug context is relevant
- `scripts/measure-stealth.sh` output when comparing real-network behavior
