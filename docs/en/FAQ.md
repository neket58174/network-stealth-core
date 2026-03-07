# FAQ

## Is this project production-ready?

The project is a public automation toolkit with CI and release gates.
Use it with your own operational responsibility and host hardening standards.

## Which OS is officially supported?

Current validated platform:

- Ubuntu 24.04 LTS

Other Linux distributions may work but are not under the active CI contract.

## Why does install ask fewer questions now?

v6 keeps the default path opinionated on purpose.
`install` chooses xhttp, `ru-auto`, and the default config count automatically.
Use `install --advanced` only when you need manual prompts.

## Can I still choose `grpc` or `http2` during install?

No.
v6 is xhttp-only for mutating product paths.
If you already manage a legacy install, run:

```bash
sudo xray-reality.sh migrate-stealth --non-interactive --yes
```

## What does `legacy transport` mean in status?

It means the managed server config still uses `grpc` or `http2`.
`status`, `logs`, `diagnose`, `rollback`, and `uninstall` still work, but mutating actions such as `update`, `repair`, and `add-clients` require migration first.

## What is the difference between `recommended` and `rescue`?

- `recommended` = xhttp `mode=auto`
- `rescue` = xhttp `mode=packet-up`

Mutating flows test `recommended` first and fall back to `rescue` if needed.

## What is `capabilities.json` for?

It is the machine-readable export capability matrix.
It tells you which output formats are:

- `native`
- `link-only`
- `unsupported`

For xhttp, raw xray json remains the canonical client artifact.

## What is stored in `self-check.json`?

The last transport-aware verdict:

- action name
- verdict (`ok`, `warning`, `broken`)
- selected variant
- attempted probe results
- operator-facing reasons

## What does a self-check `warning` mean?

The server stayed usable, but `recommended` failed and `rescue` passed.
That is degraded, not broken.
Review `status --verbose`, `diagnose`, and the saved state file.

## What is `scripts/measure-stealth.sh` for?

It is a local measurement harness.
It reuses the same probe engine as the runtime self-check and writes a JSON report for `recommended` / `rescue` comparisons.

## Is this tied to one person or one server?

No. Repository content, docs, and defaults are intended for public generic usage.

## Where can I ask questions?

- GitHub Discussions
- GitHub Issues (for actionable bugs)
- X contact: [x.com/neket371](https://x.com/neket371)
