# Troubleshooting

Use this guide when installation or runtime behavior is not as expected.

## 1. Install aborted

### Symptom

Install stops with `operation aborted` and points to install log.

### Checks

```bash
sudo tail -n 200 /var/log/xray-install.log
sudo xray-reality.sh diagnose
```

### Typical causes

- missing dependencies or broken package mirrors
- no writable target path
- invalid existing config that fails safety checks

## 2. Service is active but expected ports are not listening

### Checks

```bash
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo ss -tlnp | grep xray
```

### Typical causes

- conflicting systemd drop-ins overriding `ExecStart` or user/group
- stale config not matching generated client artifacts
- firewall mismatch after external changes

### Recovery

```bash
sudo xray-reality.sh repair --non-interactive --yes
```

## 3. Minisign warning appears

### Meaning

Release did not expose minisign signature or local verifier was unavailable.

### What to do

- for strict environments, run with `--require-minisign`
- otherwise allow SHA256-only flow explicitly

## 4. DNS timeout errors in client logs

### Symptom

Client shows repeated `dns: exchange failed ... context deadline exceeded`.

### Checklist

- validate server is reachable from client network
- test with another generated config/profile
- verify local client DNS strategy and outbound DNS rules
- check if local network blocks selected upstream DNS

Server-side quick check:

```bash
sudo xray-reality.sh status
sudo journalctl -u xray -n 200 --no-pager
```

## 5. Uninstall prompt behaves unexpectedly

If confirmation input is not accepted:

- type plain `yes` or `no` (without quotes)
- avoid pasted text with hidden characters
- use non-interactive mode for automation:

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

## 6. Last-resort recovery

```bash
sudo xray-reality.sh rollback
sudo xray-reality.sh status
```

If rollback does not restore service behavior, collect diagnostics and open an issue with sanitized logs/config.
