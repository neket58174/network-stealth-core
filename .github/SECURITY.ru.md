# Политика безопасности

Этот документ описывает security posture и disclosure process для **Network Stealth Core**.

## Поддерживаемые версии

| Линейка версий | Статус |
|---|---|
| `6.0.x` | поддерживается |
| `<6.0` | не поддерживается в этом репозитории |

## Сообщение об уязвимостях

Используй responsible disclosure:

1. не открывай публичные issue для security-багов
2. используй GitHub private vulnerability reporting
3. приложи impact, шаги воспроизведения, затронутую версию или commit и, по желанию, patch proposal

Целевые сроки ответа:

- первичный triage: до 48 часов
- критический patch: до 7 дней

## Практическая threat model

| Угроза | Митигация |
|---|---|
| tampering bootstrap и downloads | pinned bootstrap, SHA256 checks, optional strict minisign mode |
| command или path injection | strict validators и safe path guards |
| повреждение при partial write | atomic writes и staged validation |
| неудачный update, repair или migration | rollback stack и runtime reconciliation |
| избыточные привилегии service | выделенный пользователь `xray` и restrictive `systemd` settings |
| stale или misleading client exports | capability matrix и canonical raw xray artifacts |
| тихая транспортная деградация | transport-aware self-check и persisted verdict state |

## Security controls

### Целостность и поверхность загрузок

- https-only download flows со strict validation
- allowlist для критичных host (`DOWNLOAD_HOST_ALLOWLIST`)
- проверки целостности артефактов (`sha256`, optional strict `REQUIRE_MINISIGN=true`)
- pinned minisign trust anchor с проверкой fingerprint (`MINISIGN_KEY`)
- bootstrap pin control через `XRAY_REPO_COMMIT`
- trust boundary wrapper для `XRAY_DATA_DIR` с явным opt-in (`XRAY_ALLOW_CUSTOM_DATA_DIR=true`)

Текущий pinned minisign key fingerprint (`sha256` содержимого `MINISIGN_KEY`):

- `294701ab7f6e18646e45b5093033d9e64f3ca181f74c0cf232627628f3d8293e`

### Разделение привилегий

- service работает под отдельным non-root аккаунтом (`xray`)
- минимальный набор capability для bind low ports

### Systemd hardening

Project unit применяет такие controls, как:

- `NoNewPrivileges=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `PrivateTmp=true`
- `ProtectKernelTunables=true`
- `ProtectKernelModules=true`
- `ProtectControlGroups=true`
- syscall filtering и restricted address families

### Валидация входов и runtime

Покрытие валидации включает:

- форматы доменов, портов, IPv4, IPv6
- нормализацию xhttp path
- безопасные пути destructive-операций
- проверки URL и расписаний
- валидацию self-check URL и границ timeout
- runtime range constraints

### Безопасность артефактов

- `clients.json` — schema v2 и остается permission-restricted
- raw xray exports — canonical xhttp client artifacts
- `export/capabilities.json` явно помечает unsupported targets
- `self-check.json` сохраняет последний transport-aware verdict для операторов

### Безопасность rollback

- pre-change backup snapshot
- automatic rollback на failure-path
- rollback при broken transport-aware verdict
- firewall rollback records
- runtime reconciliation после restore

## Чувствительные пути и ожидаемые права

| Путь | Владелец | Mode | Назначение |
|---|---|---:|---|
| `/usr/local/bin/xray` | `root:root` | `0755` | бинарник Xray |
| `/etc/xray/config.json` | `root:xray` | `0640` | server config |
| `/etc/xray-reality/config.env` | `root:root` | `0600` | runtime snapshot |
| `/etc/xray/private` | `root:xray` | `0750` | корневая директория чувствительных данных |
| `/etc/xray/private/keys/keys.txt` | `root:root` | `0400` | private key material |
| `/etc/xray/private/keys/clients.txt` | `root:xray` | `0640` | читаемый summary клиентов |
| `/etc/xray/private/keys/clients.json` | `root:xray` | `0640` | структурированные client metadata (`schema_version: 2`) |
| `/etc/xray/private/keys/export/raw-xray/*.json` | `root:xray` | `0640` | raw xray client artifacts |
| `/etc/xray/private/keys/export/capabilities.json` | `root:xray` | `0640` | export capability matrix |
| `/var/lib/xray/self-check.json` | `root:xray` | `0640` | последний self-check verdict |
| `/var/backups/xray` | `root:root` | `0700` | rollback sessions |

## Рискованные overrides

Эти флаги ослабляют default-гарантии и должны быть временными:

- `ALLOW_INSECURE_SHA256=true`
- `ALLOW_UNVERIFIED_MINISIGN_BOOTSTRAP=true`
- `ALLOW_NO_SYSTEMD=true`
- `GEO_VERIFY_HASH=false`
- `SELF_CHECK_ENABLED=false`
- `XRAY_ALLOW_CUSTOM_DATA_DIR=true` (только для trusted и non-world-writable module source paths)

## Операционные рекомендации

1. для production-like deployment предпочитай tagged releases
2. managed legacy `grpc/http2` install мигрируй как можно быстрее через `migrate-stealth`
3. мониторь `journalctl -u xray`, health logs и self-check verdicts
4. используй `scripts/measure-stealth.sh` для сравнения поведения на реальных сетях
5. ротируй или переустанавливай узел при подозрении на compromise или burn

## Сигналы security-testing

Security-sensitive поведение покрывается через:

- validator tests
- path safety tests
- rollback и lifecycle tests
- export schema validation
- покрытие self-check и measurement
- CI audit gates и docs command contract checks

Для operations-side incident response см. [../docs/ru/OPERATIONS.md](../docs/ru/OPERATIONS.md).
