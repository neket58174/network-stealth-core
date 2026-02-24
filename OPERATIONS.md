# Operations runbook

This runbook is the production operations reference for `Xray Reality Ultimate`.

## Installation entry points

### Universal install (recommended)

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

### One-line install

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh) install
```

If `/dev/fd` is unavailable, switch to universal install.

## Daily health check

```bash
sudo bash xray-reality.sh status
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo bash xray-reality.sh diagnose
```

## Safe maintenance cycle

### Update

```bash
sudo bash xray-reality.sh check-update
sudo bash xray-reality.sh update
sudo bash xray-reality.sh status
```

### Add client configs

```bash
sudo bash xray-reality.sh add-clients 2
sudo bash xray-reality.sh status
```

Expected artifact set after `add-clients`:

- `/etc/xray/private/keys/keys.txt`
- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json`
- `/etc/xray/private/keys/export/*`

## Incident matrix

| Incident | Immediate Action | Verify |
|---|---|---|
| `xray` not active | `sudo systemctl restart xray` | `systemctl is-active xray` |
| config test fails | `xray -test -c /etc/xray/config.json` then rollback | config test exits `0` |
| failed update | `sudo bash xray-reality.sh rollback` | service active + artifacts consistent |
| domain instability | inspect `/var/lib/xray/domain-health.json` and tuning vars | fail streak trend improves |
| firewall drift | `sudo bash xray-reality.sh repair` | expected ports are listening/open |

## Rollback playbook

### Latest session

```bash
sudo bash xray-reality.sh rollback
```

### Specific session

```bash
sudo bash xray-reality.sh rollback /var/backups/xray/<session-dir>
```

### Post-rollback verification

```bash
sudo bash xray-reality.sh status
sudo journalctl -u xray -n 100 --no-pager
```

## Runtime tuning knobs

| Variable | Practical Effect |
|---|---|
| `DOMAIN_HEALTH_PROBE_TIMEOUT` | probe timeout per domain |
| `DOMAIN_HEALTH_RATE_LIMIT_MS` | spacing between probes |
| `DOMAIN_HEALTH_MAX_PROBES` | max probes per cycle |
| `DOMAIN_QUARANTINE_FAIL_STREAK` | quarantine trigger threshold |
| `DOMAIN_QUARANTINE_COOLDOWN_MIN` | quarantine duration |
| `PRIMARY_DOMAIN_MODE` | first domain selection strategy |
| `PROGRESS_MODE` | progress rendering (`auto`, `bar`, `plain`, `none`) |

Example:

```bash
sudo DOMAIN_HEALTH_PROBE_TIMEOUT=3 \
DOMAIN_HEALTH_MAX_PROBES=12 \
PROGRESS_MODE=plain \
bash xray-reality.sh repair
```

## Uninstall procedure

```bash
sudo bash xray-reality.sh uninstall --yes --non-interactive
```

Post-uninstall checks:

- `id xray` should fail
- `/etc/xray`, `/etc/xray-reality`, `/usr/local/bin/xray` should be removed
- previously used service ports should not be listening

## Data collection for escalation

When escalating incidents, collect:

- `sudo bash xray-reality.sh diagnose`
- `sudo journalctl -u xray -n 500 --no-pager`
- `/etc/xray/config.json` (with secrets redacted)
- `/etc/xray/private/keys/clients.json` (if artifact consistency is involved)

## QA before production changes

```bash
make lint
make test
make release-check
make ci
```

Only deploy from green commits.
