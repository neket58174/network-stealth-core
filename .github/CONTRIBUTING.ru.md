# Contributing

Спасибо за вклад в **Network Stealth Core**.

Этот гайд фиксирует ожидаемый workflow для безопасных и reviewable изменений.

## Базовые правила

- держи коммиты сфокусированными и небольшими
- сохраняй rollback и security-поведение
- обновляй тесты и docs при изменении поведения
- не допускай тихих compatibility-break

## Текущий product baseline

Перед изменением поведения считай публичными такие контракты:

- `install` = минимальный xhttp-only strongest-default путь
- `install --advanced` = ручной prompt-driven setup
- `migrate-stealth` = единственная supported managed-миграция с legacy `grpc/http2`
- `clients.json` = schema v2 с `variants[]` для каждого конфига
- `export/raw-xray/` = canonical per-variant xray client json artifacts
- `export/capabilities.json` = machine-readable capability matrix
- `/var/lib/xray/self-check.json` = последний transport-aware verdict
- `scripts/measure-stealth.sh` = local measurement harness

## Локальная настройка

### Prerequisites

- linux или wsl
- bash 4.3+
- git
- `shellcheck`, `shfmt`, `bats`, `actionlint`
- node.js (или `npx`) для markdown lint

### Клонирование и связь с upstream

```bash
git clone https://github.com/YOUR_USERNAME/network-stealth-core.git
cd network-stealth-core
git remote add upstream https://github.com/neket371/network-stealth-core.git
git fetch upstream
```

## Структура репозитория

| Путь | Назначение |
|---|---|
| `xray-reality.sh` | bootstrap wrapper |
| `lib.sh` | runtime core и dispatcher |
| `install.sh` | setup зависимостей и lifecycle entrypoints |
| `config.sh` | генерация config и client artifacts |
| `service.sh` | systemd, firewall и runtime status |
| `health.sh` | health monitor и diagnostics |
| `export.sh` | client export templates |
| `modules/` | вынесенные reusable modules |
| `tests/bats/` | shell unit и integration tests |
| `tests/e2e/` | lifecycle и migration scenarios |
| `docs/` | двуязычная документация |

## Обязательные локальные проверки

Запусти перед push:

```bash
make lint
make test
make release-check
make ci
```

Эквивалентные прямые команды:

```bash
bash tests/lint.sh
bats tests/bats
bash scripts/check-release-consistency.sh
```

## Coding standards

1. держи скрипты безопасными под `set -euo pipefail`
2. последовательно квоть переменные
3. не используй `eval` для user-controlled input
4. переиспользуй общие validators
5. используй atomic writes для критичных файлов
6. держи mutating-flows rollback-safe
7. предпочитай canonical raw xray exports вместо partial regenerated client templates

## High-risk areas

Изменения в этих зонах требуют дополнительного покрытия:

- bootstrap и download verification
- обработка permissions и путей
- генерация systemd units
- firewall apply и rollback
- backup stack и cleanup traps
- миграция между legacy transport и xhttp
- generated client artifacts и export paths
- self-check verdict и взаимодействие с rollback
- reporting в measurement harness

## Ожидания по тестам

- любое изменение поведения должно добавлять или обновлять bats coverage
- lifecycle-sensitive изменениям нужны e2e checks
- обновления docs обязаны проходить markdown lint и command-contract checks

Полезные таргетированные прогоны:

```bash
bats tests/bats/unit.bats
bats tests/bats/integration.bats
bats tests/bats/validation.bats
bats tests/bats/health.bats
```

## Область обновления документации

Изменения поведения обычно затрагивают:

- `README.md`
- `README.ru.md`
- `docs/en/*.md`
- `docs/ru/*.md`
- `.github/CONTRIBUTING.md`
- `.github/SECURITY.md`

Если изменение касается публичного install-поведения, migration, self-check или артефактов, обновляй оба языка в одном проходе.

## Ожидания по release metadata

Если готовишь релиз:

- подними `SCRIPT_VERSION`
- обнови marker’ы релиза в wrapper/readme
- добавь совпадающие секции в оба changelog
- не ставь tag, пока branch CI не зелёный

## Чеклист pull request

- [ ] локальные проверки зеленые (`make ci`)
- [ ] тесты покрывают измененное поведение
- [ ] docs обновлены для user-visible изменений
- [ ] оба changelog обновлены, если затронута release metadata
- [ ] в коммитах нет секретов
- [ ] rollback и security-поведение сохранены

## Сообщение о security-проблемах

Не открывай публичные issue для уязвимостей.

Используй GitHub private vulnerability reporting. См. [SECURITY.ru.md](SECURITY.ru.md).
