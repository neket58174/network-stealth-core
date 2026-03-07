# Эксплуатационный runbook

Этот runbook — основная операционная справка по **Network Stealth Core**.

## Точки входа для установки

### Universal install (recommended)

```bash
curl -fL https://raw.githubusercontent.com/neket371/network-stealth-core/ubuntu/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

### One-line install

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/neket371/network-stealth-core/ubuntu/xray-reality.sh) install
```

Если `/dev/fd` недоступен, используйте universal install.

Заметка по миграции: legacy `main` поддерживается как временный alias на один релизный цикл; canonical branch — `ubuntu`.

Заметка по install-контракту:

- `install` использует минимальный xhttp-only путь (`ru-auto`, auto count, strongest default)
- `install --advanced` включает ручные prompt’ы для профиля и числа конфигов
- `--transport grpc|http2` в v6 отклоняется

## Runtime assumptions

- `install`, `update` и `repair` по умолчанию ожидают рабочий `systemd`
- для ограниченных окружений используйте `--allow-no-systemd`
- для fail-closed политики подписи используйте `--require-minisign`
- custom wrapper source path требует явного opt-in:
  `XRAY_ALLOW_CUSTOM_DATA_DIR=true XRAY_DATA_DIR=/secure/path`

## Public release sanity checklist (Ubuntu 24.04 LTS)

Поддерживаемый и валидируемый target для этого чеклиста: **Ubuntu 24.04 LTS**.

### Local quality gate (must pass)

```bash
make ci
```

### Fresh host smoke (must pass)

На чистом Ubuntu 24.04:

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

Ожидается:

- service `active` после install/update/repair
- `xray -test` завершается с кодом `0`
- self-check verdict = `ok` или `warning`, но не `broken`
- присутствуют `clients.json`, `export/raw-xray/` и `export/capabilities.json`
- uninstall удаляет managed-файлы и systemd units

## Ежедневная проверка здоровья

```bash
sudo xray-reality.sh status --verbose
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo xray-reality.sh diagnose
```

В verbose status смотри:

- transport
- последний self-check verdict
- выбранный variant и latency
- summary по export capability

## Безопасный цикл обслуживания

### Update

```bash
sudo xray-reality.sh check-update
sudo xray-reality.sh update
sudo xray-reality.sh status --verbose
```

### Добавление клиентских конфигураций

```bash
sudo xray-reality.sh add-clients 2
sudo xray-reality.sh status --verbose
```

Ожидаемый набор артефактов:

- `/etc/xray/private/keys/keys.txt`
- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json` (`schema_version: 2`, `variants[]` для каждого конфига)
- `/etc/xray/private/keys/export/raw-xray/*`
- `/etc/xray/private/keys/export/capabilities.json`
- `/etc/xray/private/keys/export/compatibility-notes.txt`
- `/var/lib/xray/self-check.json`

### Миграция managed legacy transport

```bash
sudo xray-reality.sh status --verbose
sudo xray-reality.sh migrate-stealth --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Ожидается:

- до миграции статус может показывать `legacy transport`
- после миграции статус показывает `Transport: xhttp`
- `clients.json`, `export/raw-xray/` и `export/capabilities.json` пересобраны под xhttp variants
- заблокированные mutating-действия (`update`, `repair`, `add-clients`) снова доступны

## Capability-driven exports

Прочитай machine-readable export matrix:

```bash
sudo jq . /etc/xray/private/keys/export/capabilities.json
```

Ожидаемый baseline:

- `raw-xray` = `native`
- `clients.txt` / `clients.json` = `native`
- `v2rayn-links` / `nekoray-template` = `link-only`
- `sing-box` / `clash-meta` = `unsupported`

## Measurement harness

Запусти локальный probe harness по managed-артефактам:

```bash
sudo bash scripts/measure-stealth.sh --output /tmp/measure-stealth.json
```

Опциональный выбор variants:

```bash
sudo bash scripts/measure-stealth.sh --variants recommended,rescue
```

Используй report для сравнения reachability и latency на реальных сетях.

## Матрица инцидентов

| Инцидент | Немедленное действие | Проверка |
|---|---|---|
| `xray` не active | `sudo systemctl restart xray` | `systemctl is-active xray` |
| не проходит config test | `xray -test -c /etc/xray/config.json`, затем rollback | config test возвращает `0` |
| self-check = `warning` | проверить selected variant и probe results | `status --verbose` / state file |
| self-check = `broken` | `sudo xray-reality.sh rollback` | service active + verdict восстановился |
| неудачный update | `sudo xray-reality.sh rollback` | service active + артефакты согласованы |
| нестабильность доменов | проверить `/var/lib/xray/domain-health.json` | fail-trend уменьшается |
| дрейф firewall | `sudo xray-reality.sh repair` | нужные порты открыты и слушают |

## Rollback playbook

### Последний backup

```bash
sudo xray-reality.sh rollback
```

### Конкретный backup

```bash
sudo xray-reality.sh rollback /var/backups/xray/<session-dir>
```

### Проверка после rollback

```bash
sudo xray-reality.sh status --verbose
sudo journalctl -u xray -n 100 --no-pager
```

## Runtime tuning knobs

| Переменная | Эффект |
|---|---|
| `DOMAIN_HEALTH_PROBE_TIMEOUT` | timeout одного domain-probe |
| `DOMAIN_HEALTH_RATE_LIMIT_MS` | задержка между probe |
| `DOMAIN_HEALTH_MAX_PROBES` | максимум probe за цикл |
| `DOMAIN_QUARANTINE_FAIL_STREAK` | триггер quarantine |
| `DOMAIN_QUARANTINE_COOLDOWN_MIN` | длительность quarantine |
| `PRIMARY_DOMAIN_MODE` | стратегия первого домена |
| `PROGRESS_MODE` | `auto`, `bar`, `plain`, `none` |
| `SELF_CHECK_ENABLED` | включает или выключает transport-aware self-check |
| `SELF_CHECK_URLS` | comma-separated HTTPS probe URLs |
| `SELF_CHECK_TIMEOUT_SEC` | timeout curl для одного self-check probe |

Пример:

```bash
sudo env DOMAIN_HEALTH_PROBE_TIMEOUT=3 \
  DOMAIN_HEALTH_MAX_PROBES=12 \
  SELF_CHECK_TIMEOUT_SEC=10 \
  PROGRESS_MODE=plain \
  xray-reality.sh repair
```

## Процедура uninstall

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

Проверки после uninstall:

- `id xray` должен завершаться ошибкой
- `/etc/xray`, `/etc/xray-reality`, `/usr/local/bin/xray` должны быть удалены
- `/var/lib/xray/self-check.json` должен быть удален
- ранее использованные service-порты не должны слушать

## Пакет для эскалации

Собери перед открытием issue:

- `sudo xray-reality.sh diagnose`
- `sudo journalctl -u xray -n 500 --no-pager`
- `/etc/xray/config.json` с редактированными секретами
- `/etc/xray/private/keys/clients.json`, если проблема связана с артефактами
- `/var/lib/xray/self-check.json`, если важен verdict/debug-контекст
- output `scripts/measure-stealth.sh` при сравнении поведения на реальных сетях
