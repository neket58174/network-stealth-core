# Индекс документации (RU)

Добро пожаловать в документацию **Network Stealth Core**.

## С чего начать

- [../../README.ru.md](../../README.ru.md) — быстрый старт и карта команд
- [OPERATIONS.md](OPERATIONS.md) — установка, сопровождение, rollback и release-проверки
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — диагностика по симптомам

## Текущий baseline

- `install` = минимальный xhttp-first strongest-default путь
- `install --advanced` = ручной выбор профиля и числа конфигов
- `migrate-stealth` = managed-миграция с legacy `grpc/http2`
- `clients.json` = schema v2 с `variants[]` для каждого конфига
- `export/raw-xray/` = raw xray client json по вариантам

## Базовые документы

| Документ | Назначение |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | архитектура рантайма, контракты модулей, артефакты |
| [OPERATIONS.md](OPERATIONS.md) | day-2 runbook, миграция и обслуживание |
| [CHANGELOG.md](CHANGELOG.md) | релизные изменения и история версий |

## Документы для оператора

| Документ | Назначение |
|---|---|
| [FAQ.md](FAQ.md) | частые вопросы по профилям, prompt’ам и поведению рантайма |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | восстановление после install/migration/artifact ошибок |
| [GLOSSARY.md](GLOSSARY.md) | термины из логов, документации и скриптов |

## Документы проекта

| Документ | Назначение |
|---|---|
| [COMMUNITY.md](COMMUNITY.md) | discussions, качество issue и полевые отчёты |
| [ROADMAP.md](ROADMAP.md) | вектор после v5 и ближние приоритеты |
| [../../.github/CONTRIBUTING.ru.md](../../.github/CONTRIBUTING.ru.md) | процесс контрибьюта и quality-gates |
| [../../.github/SECURITY.ru.md](../../.github/SECURITY.ru.md) | поддерживаемые версии, threat model и disclosure |

## Переключение языков

- english docs: [../en/INDEX.md](../en/INDEX.md)
- english readme: [../../README.md](../../README.md)
