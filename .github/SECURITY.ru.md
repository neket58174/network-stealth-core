# Политика безопасности

Этот документ фиксирует security-подход проекта **Network Stealth Core** и порядок disclosure.

## Поддерживаемые версии

| Линейка версий | Статус |
|---|---|
| `4.2.x` | поддерживается |
| `<4.2` | не поддерживается в этом репозитории |

## Как сообщать об уязвимостях

1. не публикуйте security-баги в открытых issue
2. используйте GitHub private vulnerability reporting
3. прикладывайте impact, шаги воспроизведения, версию/commit и, при наличии, патч

Ожидаемые окна реакции:

- первичный triage: до 48 часов
- цель по критичному патчу: до 7 дней

## Практическая модель угроз

| Угроза | Защита |
|---|---|
| подмена bootstrap/download | pin по commit, SHA256, optional strict minisign |
| command/path injection | строгая валидация и safe path guards |
| порча частично записанных файлов | атомарные записи и staged validation |
| неуспешный update/install | backup stack и rollback |
| избыточные привилегии сервиса | отдельный `xray`-пользователь и hardened `systemd` unit |

## Основные security-контроли

### Целостность и поверхность загрузок

- только HTTPS в критичных загрузках
- allowlist для хостов загрузки (`DOWNLOAD_HOST_ALLOWLIST`)
- проверка целостности артефактов (`sha256`, optional `REQUIRE_MINISIGN=true`)
- закреплённый minisign trust anchor с fingerprint-check (`MINISIGN_KEY`)
- bootstrap pin через `XRAY_REPO_COMMIT`

Текущий fingerprint trust anchor (`sha256` контента `MINISIGN_KEY`):

- `294701ab7f6e18646e45b5093033d9e64f3ca181f74c0cf232627628f3d8293e`

### Разделение привилегий

- runtime от непривилегированного пользователя `xray`
- минимальный capability-набор для низких портов

### Жёсткий профиль systemd

Используются параметры:

- `NoNewPrivileges=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `PrivateTmp=true`
- `ProtectKernelTunables=true`
- `ProtectKernelModules=true`
- `ProtectControlGroups=true`

### Валидация входов

Покрываются:

- домены, порты, IPv4, IPv6
- gRPC service names
- безопасные пути для destructive-операций
- URL и schedule-параметры
- числовые диапазоны runtime-настроек

### Безопасность rollback

- backup до мутаций
- автоматический rollback при ошибках
- журнал rollback для firewall
- runtime reconcilation после восстановления

## Критичные пути и права

| Путь | Владелец | Режим | Назначение |
|---|---|---:|---|
| `/usr/local/bin/xray` | `root:root` | `0755` | бинарник Xray |
| `/etc/xray/config.json` | `root:xray` | `0640` | серверный конфиг |
| `/etc/xray-reality/config.env` | `root:root` | `0600` | снимок runtime-переменных |
| `/etc/xray/private/keys/keys.txt` | `root:root` | `0400` | приватные ключи |
| `/etc/xray/private/keys/clients.txt` | `root:xray` | `0640` | клиентские ссылки |
| `/etc/xray/private/keys/clients.json` | `root:xray` | `0640` | структурированный экспорт |
| `/var/backups/xray` | `root:root` | `0700` | rollback-сессии |

## Рискованные override-переменные

Эти флаги ослабляют базовые гарантии:

- `ALLOW_INSECURE_SHA256=true`
- `ALLOW_UNVERIFIED_MINISIGN_BOOTSTRAP=true`
- `ALLOW_NO_SYSTEMD=true`
- `GEO_VERIFY_HASH=false`

## Рекомендации эксплуатации

1. для стабильного контура используйте релизные теги
2. обновляйте в контролируемых maintenance-окнах
3. мониторьте `journalctl -u xray` и health-логи
4. ограничивайте доступ к shell и админ-правам
5. при подозрении на компрометацию выполняйте ротацию

Для операционной части реагирования см. [docs/ru/OPERATIONS.md](../docs/ru/OPERATIONS.md).
