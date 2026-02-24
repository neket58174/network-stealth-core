<h1 align="center">Xray Reality Ultimate</h1>

<p align="center">
  Безопасная и предсказуемая автоматизация Xray Reality для Linux-серверов.
</p>

<p align="center">
  <a href="https://github.com/neket58174/network-stealth-core/releases"><img alt="release" src="https://img.shields.io/badge/release-v4.1.7-0f766e"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-97ca00"></a>
  <a href="OPERATIONS.md"><img alt="platform" src="https://img.shields.io/badge/platform-linux%20server-1d4ed8"></a>
  <a href="Makefile"><img alt="qa" src="https://img.shields.io/badge/qa-make%20ci-334155"></a>
</p>

## Что это за проект

`Xray Reality Ultimate` — набор Bash-скриптов для установки, сопровождения и обновления Xray Reality.

Базовые принципы:

- воспроизводимый install/update процесс
- строгие проверки входных параметров и путей
- безопасный откат при сбоях
- готовые клиентские экспорты и понятная эксплуатация

## Официальный источник

Используйте только каноничный репозиторий:

- `https://github.com/neket58174/network-stealth-core`

Если команды взяты из зеркала/форка, проверяйте их вручную до запуска.

## Документация

| Файл | Назначение |
|---|---|
| `README.md` | Английская версия |
| `ARCHITECTURE.md` | Архитектура, контракты модулей, потоки выполнения |
| `OPERATIONS.md` | Runbook эксплуатации, инциденты, rollback |
| `SECURITY.md` | Модель угроз и меры защиты |
| `CONTRIBUTING.md` | Правила контрибьюта и локальная разработка |
| `CHANGELOG.md` | История релизов |

## Быстрый старт

### Рекомендуемый способ: universal install

Работает стабильно даже в ограниченных окружениях (`chroot`, проблемы с `/dev/fd`).

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

### One-line install

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh) install
```

Если видите `/dev/fd/...: no such file or directory`, переходите на universal install.

### Усиленный bootstrap с pin по commit

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo XRAY_REPO_COMMIT=<full_commit_sha> bash /tmp/xray-reality.sh install
```

### Выбор источника bootstrap

По умолчанию bootstrap использует ветку `main` (самые свежие фиксы).

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

Если нужен именно последний релизный тег:

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo XRAY_BOOTSTRAP_DEFAULT_REF=release bash /tmp/xray-reality.sh install
```

## Основные команды

| Команда | Что делает |
|---|---|
| `install` | Полная установка |
| `add-clients [N]` | Добавляет `N` клиентских конфигов |
| `add-keys [N]` | Алиас `add-clients` |
| `update` | Обновляет Xray core |
| `repair` | Восстанавливает unit/firewall/monitoring и артефакты |
| `status` | Показывает состояние сервиса и конфигурации |
| `logs [xray\|health\|all]` | Выводит логи |
| `diagnose` | Собирает диагностику |
| `rollback [dir]` | Откат к резервной сессии |
| `uninstall` | Полное удаление |
| `check-update` | Проверка доступности обновления |

Пример:

```bash
sudo bash xray-reality.sh status
sudo bash xray-reality.sh diagnose
sudo bash xray-reality.sh logs
```

## Профили и лимиты

| Профиль | Внутренний tier | Лимит конфигов | Сценарий |
|---|---|---:|---|
| `ru` | `tier_ru` | 100 | Основной RU-пул |
| `ru-auto` | `tier_ru` | auto 5 | Быстрый старт |
| `global-ms10` | `tier_global_ms10` | 10 | Компактный глобальный профиль |
| `global-ms10-auto` | `tier_global_ms10` | auto 10 | Быстрый global-ms10 |
| `custom` | `custom` | 100 | Пользовательский список доменов |

## Ключевые флаги

```bash
--domain-profile ru|ru-auto|global-ms10|global-ms10-auto|custom
--transport grpc|http2
--progress-mode auto|bar|plain|none
--num-configs N
--start-port N
--server-ip IPV4 --server-ip6 IPV6
--yes --non-interactive
--verbose
```

## Безопасность

- строгая валидация runtime-параметров
- allowlist для критичных загрузок
- проверка целостности Xray (`sha256` + optional `minisign`)
- атомарные записи + rollback при ошибках
- запуск сервиса от непривилегированного пользователя с hardening `systemd`

Подробно: [SECURITY.md](SECURITY.md).

## Экспорт клиентских шаблонов

Формируются после `install`, `add-clients`, `repair`:

- `/etc/xray/private/keys/export/clashmeta.yaml`
- `/etc/xray/private/keys/export/singbox.json`
- `/etc/xray/private/keys/export/nekoray-fragment.json`
- `/etc/xray/private/keys/export/v2rayn-fragment.json`

## Поддерживаемая платформа

Основная и проверяемая в CI платформа:

- `ubuntu-24.04` (LTS)

Другие Linux-дистрибутивы могут работать, но сейчас не входят в активный CI-контракт.
Ubuntu 22.04 обычно совместим, а Ubuntu 18.04 считается устаревшим и не рекомендуется.

## Локальная проверка

```bash
make lint
make test
make release-check
make ci
```

Windows-утилиты:

```powershell
pwsh ./scripts/markdownlint.ps1
pwsh ./scripts/windows/run-validation.ps1
```

## Docker

```bash
docker pull ghcr.io/neket58174/network-stealth-core:vX.Y.Z
docker run --rm ghcr.io/neket58174/network-stealth-core:vX.Y.Z --help
```

## Лицензия

MIT License. См. [LICENSE](LICENSE).
