# Troubleshooting

Use this guide when installation, migration, or runtime behavior is not as expected.

## 1. Install aborted

### Checks

```bash
sudo tail -n 200 /var/log/xray-install.log
sudo xray-reality.sh diagnose
```

### Typical causes

- missing dependencies or broken package mirrors
- no writable target path
- existing runtime files that fail safety validation

## 2. Unexpected manual prompts during install

Default `install` should follow the minimal xhttp-first path.

If you need manual profile or config-count prompts, run:

```bash
sudo xray-reality.sh install --advanced
```

If automation unexpectedly blocks on prompts, add:

```bash
--yes --non-interactive
```

## 3. Status shows `legacy transport`

### Meaning

The managed install still uses legacy `grpc` or `http2`.

### Recommended action

```bash
sudo xray-reality.sh status --verbose
sudo xray-reality.sh migrate-stealth --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Expected post-state:

- `Transport: xhttp`
- no `legacy transport` warning
- rebuilt client artifacts and raw xray exports

## 4. Service is active but expected ports are not listening

### Checks

```bash
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo ss -tlnp | grep xray
```

### Typical causes

- conflicting systemd drop-ins overriding `ExecStart` or runtime user
- stale config not matching generated client artifacts
- firewall drift after external changes

### Recovery

```bash
sudo xray-reality.sh repair --non-interactive --yes
```

## 5. Client artifacts look inconsistent

### Symptoms

- `clients.txt` and `clients.json` disagree
- expected `recommended` / `rescue` variants are missing
- `export/raw-xray/` files are absent or stale

### Recovery

```bash
sudo xray-reality.sh repair --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Then inspect:

- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json`
- `/etc/xray/private/keys/export/raw-xray/`

## 6. `migrate-stealth` fails

### Checks

```bash
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo xray-reality.sh diagnose
```

### Common causes

- existing managed config is already broken before migration
- local artifacts were manually changed outside the managed flow
- systemd or firewall state is already inconsistent

### Safe fallback

```bash
sudo xray-reality.sh rollback
```

## 7. Minisign warning appears

### Meaning

Release did not expose minisign signature or local verifier was unavailable.

### What to do

- for strict environments, use `--require-minisign`
- otherwise continue only if SHA256-only mode is acceptable in your threat model

## 8. DNS timeout errors in client logs

### Symptoms

Repeated client-side errors like:

- `dns: exchange failed`
- `context deadline exceeded`

### Checklist

- test another generated config or the `rescue` variant
- verify the server is reachable from the client network
- review local client DNS strategy and outbound rules
- confirm local network does not block the chosen DNS path

Server-side quick check:

```bash
sudo xray-reality.sh status
sudo journalctl -u xray -n 200 --no-pager
```

## 9. Uninstall confirmation behaves unexpectedly

If confirmation input is not accepted:

- type plain `yes` or `no`
- avoid pasted text with hidden characters
- use automation-safe mode when appropriate:

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

## 10. Last-resort recovery

```bash
sudo xray-reality.sh rollback
sudo xray-reality.sh status
sudo xray-reality.sh diagnose
```

If rollback does not restore service behavior, open an issue with sanitized logs and exact commands.
