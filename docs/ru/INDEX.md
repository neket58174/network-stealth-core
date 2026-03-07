# Индекс документации (RU)

Добро пожаловать в документационный хаб **Network Stealth Core**.

## Начать отсюда

- [../../README.ru.md](../../README.ru.md) — быстрый старт и карта команд
- [OPERATIONS.md](OPERATIONS.md) — install, maintenance, migration, measurement и rollback
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — диагностика по симптомам

## Текущий baseline

- `install` = минимальный xhttp-only strongest-default путь
- `install --advanced` = ручные prompt’ы выбора профиля и числа конфигов
- `migrate-stealth` = единственный managed-мост с legacy `grpc/http2`
- `clients.json` = schema v2 с `variants[]` для каждого конфига
- `export/raw-xray/` = canonical raw xray client json по вариантам
- `export/capabilities.json` = machine-readable capability matrix экспортов
- `/var/lib/xray/self-check.json` = последний transport-aware verdict
- `scripts/measure-stealth.sh` = локальный measurement harness

## Основные документы

| Документ | Назначение |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | архитектура runtime, контракты модулей, генерируемые артефакты |
| [OPERATIONS.md](OPERATIONS.md) | эксплуатационный runbook, миграция, measurement, maintenance |
| [CHANGELOG.md](CHANGELOG.md) | история релизов и заметки по версиям |

## Документы оператора

| Документ | Назначение |
|---|---|
| [FAQ.md](FAQ.md) | частые вопросы про профили, prompt’ы и runtime-поведение |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | install, self-check, migration и восстановление артефактов |
| [GLOSSARY.md](GLOSSARY.md) | термины проекта из логов, документации и скриптов |

## Документы проекта

| Документ | Назначение |
|---|---|
| [COMMUNITY.md](COMMUNITY.md) | обсуждения, качество issue и полезные field-репорты |
| [ROADMAP.md](ROADMAP.md) | направление после v6 и ближайшие приоритеты |
| [../../.github/CONTRIBUTING.ru.md](../../.github/CONTRIBUTING.ru.md) | workflow для контрибьюторов и quality gates |
| [../../.github/SECURITY.ru.md](../../.github/SECURITY.ru.md) | поддерживаемые версии, threat model и disclosure process |

## Навигация по языкам

- английская документация: [../en/INDEX.md](../en/INDEX.md)
- английский readme: [../../README.md](../../README.md)
