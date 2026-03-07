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
- self-check could not validate either `recommended` or `rescue`

## 2. Unexpected manual prompts during install

Default `install` should follow the minimal xhttp-only path.

If you need manual profile or config-count prompts, run:

```bash
sudo xray-reality.sh install --advanced
```

If automation must stay non-interactive, add:

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
- rebuilt client artifacts, raw xray exports, and capability matrix

## 4. Mutating action is blocked on a legacy install

Typical message:

- `action 'update' is blocked in v6`
- `first run: xray-reality.sh migrate-stealth --non-interactive --yes`

### Fix

Run migration first, then retry the mutating command.

## 5. Service is active but self-check is `warning`

### Meaning

`recommended` failed but `rescue` passed.

### Checks

```bash
sudo xray-reality.sh status --verbose
sudo jq . /var/lib/xray/self-check.json
sudo xray-reality.sh diagnose
```

### Recovery

- inspect the selected variant and latency
- compare `recommended` and `rescue` with `scripts/measure-stealth.sh`
- if degradation persists, run `repair` or rotate the host

## 6. Self-check is `broken`

### Checks

```bash
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo jq . /var/lib/xray/self-check.json
sudo xray-reality.sh diagnose
```

### Safe fallback

```bash
sudo xray-reality.sh rollback
```

If the last mutating action failed, the project should already have rolled back automatically.

## 7. Client artifacts look inconsistent

### Symptoms

- `clients.txt` and `clients.json` disagree
- expected `recommended` / `rescue` variants are missing
- `export/raw-xray/` files are absent or stale
- `export/capabilities.json` does not match actual artifacts

### Recovery

```bash
sudo xray-reality.sh repair --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Then inspect:

- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json`
- `/etc/xray/private/keys/export/raw-xray/`
- `/etc/xray/private/keys/export/capabilities.json`

## 8. `migrate-stealth` fails

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

## 9. Minisign warning appears

### Meaning

Release did not expose a minisign signature or local verifier was unavailable.

### What to do

- for strict environments, use `--require-minisign`
- otherwise continue only if SHA256-only mode is acceptable in your threat model

## 10. Local measurement report shows no successful variants

### Checks

```bash
sudo bash scripts/measure-stealth.sh --output /tmp/measure-stealth.json
jq . /tmp/measure-stealth.json
```

### Meaning

Neither `recommended` nor `rescue` succeeded for at least one managed config on the current network.

### Next steps

- compare from another client network
- inspect server health and self-check state
- redeploy or rotate if the node appears burned

## 11. Uninstall confirmation behaves unexpectedly

If confirmation input is not accepted:

- type plain `yes` or `no`
- avoid pasted text with hidden characters
- use automation-safe mode when appropriate:

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

## 12. Last-resort recovery

```bash
sudo xray-reality.sh rollback
sudo xray-reality.sh status --verbose
sudo xray-reality.sh diagnose
```

If rollback does not restore service behavior, open an issue with sanitized logs and exact commands.
