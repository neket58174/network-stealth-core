# Политика безопасности

Этот документ фиксирует security-подход проекта **Network Stealth Core** и порядок disclosure.

## Поддерживаемые версии

| Линейка версий | Статус |
|---|---|
| `5.1.x` | поддерживается |
| `<5.1` | не поддерживается в этом репозитории |

## Как сообщать об уязвимостях

1. не публикуйте security-баги в открытых issue
2. используйте GitHub private vulnerability reporting
3. прикладывайте impact, шаги воспроизведения, версию или commit и, при наличии, патч

Ожидаемые окна реакции:

- первичный triage: до 48 часов
- цель по критичному патчу: до 7 дней

## Практическая модель угроз

| Угроза | Защита |
|---|---|
| подмена bootstrap/download | pin по commit, SHA256 и optional strict minisign |
| command/path injection | строгая валидация и safe path guards |
| порча частично записанных файлов | атомарные записи и staged validation |
| неуспешный update, repair или migration | backup stack и runtime reconciliation |
| избыточные привилегии сервиса | отдельный `xray`-пользователь и hardened `systemd` unit |
| устаревшие клиентские артефакты | строгие права доступа и полная пересборка из managed config |

## Основные security-контроли

### Целостность и поверхность загрузок

- только https в критичных загрузках
- allowlist для хостов загрузки (`DOWNLOAD_HOST_ALLOWLIST`)
- проверка целостности артефактов (`sha256`, optional strict `REQUIRE_MINISIGN=true`)
- закрепленный minisign trust anchor с fingerprint-check (`MINISIGN_KEY`)
- bootstrap pin через `XRAY_REPO_COMMIT`
- trust-boundary для source-кода wrapper по `XRAY_DATA_DIR` с явным opt-in (`XRAY_ALLOW_CUSTOM_DATA_DIR=true`)

Текущий fingerprint trust anchor (`sha256` контента `MINISIGN_KEY`):

- `294701ab7f6e18646e45b5093033d9e64f3ca181f74c0cf232627628f3d8293e`

### Разделение привилегий

- runtime работает от непривилегированного пользователя `xray`
- используется минимальный capability-набор для низких портов

### Жесткий профиль systemd

Используются параметры:

- `NoNewPrivileges=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `PrivateTmp=true`
- `ProtectKernelTunables=true`
- `ProtectKernelModules=true`
- `ProtectControlGroups=true`
- syscall filtering и ограниченные address families

### Валидация входов и runtime

Покрываются:

- домены, порты, IPv4, IPv6
- gRPC service names и нормализация xhttp path
- безопасные пути для destructive-операций
- URL и schedule-параметры
- числовые диапазоны runtime-настроек

### Безопасность артефактов

- `clients.json` использует schema v2 и остается под ограниченными правами
- xhttp-first install создает варианты по конфигу вместо одной неявной клиентской ссылки
- raw xray exports пересобираются из managed config и лежат в ограниченных путях

### Безопасность rollback

- backup до мутаций
- автоматический rollback при ошибках
- журнал rollback для firewall
- runtime reconciliation после восстановления

## Критичные пути и права

| Путь | Владелец | Режим | Назначение |
|---|---|---:|---|
| `/usr/local/bin/xray` | `root:root` | `0755` | бинарник Xray |
| `/etc/xray/config.json` | `root:xray` | `0640` | серверный конфиг |
| `/etc/xray-reality/config.env` | `root:root` | `0600` | runtime snapshot |
| `/etc/xray/private` | `root:xray` | `0750` | корневая директория чувствительных данных |
| `/etc/xray/private/keys/keys.txt` | `root:root` | `0400` | приватные ключи |
| `/etc/xray/private/keys/clients.txt` | `root:xray` | `0640` | человекочитаемая сводка клиентов |
| `/etc/xray/private/keys/clients.json` | `root:xray` | `0640` | структурированный экспорт (`schema_version: 2`) |
| `/etc/xray/private/keys/export/raw-xray/*.json` | `root:xray` | `0640` | raw xray клиентские артефакты |
| `/var/backups/xray` | `root:root` | `0700` | rollback-сессии |

## Рискованные override-переменные

Эти флаги ослабляют базовые гарантии:

- `ALLOW_INSECURE_SHA256=true`
- `ALLOW_UNVERIFIED_MINISIGN_BOOTSTRAP=true`
- `ALLOW_NO_SYSTEMD=true`
- `GEO_VERIFY_HASH=false`
- `XRAY_ALLOW_CUSTOM_DATA_DIR=true` (только для доверенного каталога модулей без group/other writable)

## Рекомендации эксплуатации

1. для стабильного контура используйте релизные теги
2. не держите legacy `grpc/http2` install дольше нужного compatibility-окна
3. мониторьте `journalctl -u xray` и health-логи
4. ограничивайте доступ к shell и админ-правам
5. при подозрении на компрометацию выполняйте ротацию или redeploy

## Сигналы security-тестирования

Security-sensitive поведение покрывается:

- validator tests
- path safety tests
- rollback и lifecycle tests
- export schema validation
- CI audit gates и docs command contract checks

Для операционной части реагирования см. [../docs/ru/OPERATIONS.md](../docs/ru/OPERATIONS.md).
