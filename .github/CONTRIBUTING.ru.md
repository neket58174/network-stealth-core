# Вклад в проект

Спасибо за вклад в **Network Stealth Core**.

Этот документ описывает рабочий процесс для безопасных и проверяемых изменений.

## Базовые правила

- коммиты должны быть узкими и понятными
- rollback и security-поведение нельзя ломать
- tests и docs нужно обновлять вместе с поведением
- скрытые compatibility-breaks недопустимы

## Текущий продуктовый baseline

Перед изменением поведения считайте публичными такие контракты:

- `install` = минимальный xhttp-first strongest-default путь
- `install --advanced` = ручная установка через prompt’ы
- `migrate-stealth` = штатная managed-миграция с legacy `grpc/http2`
- `clients.json` = schema v2 с `variants[]` для каждого конфига
- `export/raw-xray/` = raw xray client json по вариантам

## Локальная подготовка

### Что нужно

- linux или wsl
- bash 4.3+
- git
- `shellcheck`, `shfmt`, `bats`, `actionlint`
- node.js (или `npx`) для markdown lint

### Клонирование и upstream

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
| `install.sh` | dependency setup и lifecycle entrypoints |
| `config.sh` | генерация конфигурации и клиентских артефактов |
| `service.sh` | systemd, firewall и runtime status |
| `health.sh` | health monitor и diagnostics |
| `export.sh` | шаблоны клиентских export-файлов |
| `modules/` | переиспользуемые модули |
| `tests/bats/` | shell unit и integration tests |
| `tests/e2e/` | lifecycle и migration сценарии |
| `docs/` | двуязычная документация |

## Обязательные локальные проверки

Перед push:

```bash
make lint
make test
make release-check
make ci
```

Прямые эквиваленты:

```bash
bash tests/lint.sh
bats tests/bats
bash scripts/check-release-consistency.sh
```

## Стандарты кода

1. shell-код должен быть безопасен под `set -euo pipefail`
2. переменные должны быть корректно экранированы
3. нельзя использовать `eval` для пользовательского ввода
4. нужно переиспользовать общие валидаторы
5. критичные файлы нужно писать атомарно
6. мутирующие потоки обязаны оставаться rollback-safe

## Зоны повышенного риска

Изменения в этих местах требуют усиленного покрытия:

- bootstrap и download verification
- права доступа и пути
- генерация unit-файлов systemd
- применение и rollback firewall
- backup stack и cleanup traps
- миграция между legacy transport и xhttp
- клиентские артефакты и export-пути

## Ожидания по тестам

- каждое изменение поведения должно включать или обновлять bats-покрытие
- lifecycle-чувствительные изменения должны включать e2e-проверки
- docs update обязан проходить markdown lint и docs command contract checks

Полезные таргетированные прогоны:

```bash
bats tests/bats/unit.bats
bats tests/bats/integration.bats
bats tests/bats/transport.bats
```

## Обновление документации

Изменения поведения обычно затрагивают:

- `README.md`
- `README.ru.md`
- `docs/en/*.md`
- `docs/ru/*.md`
- `.github/CONTRIBUTING.md`
- `.github/SECURITY.md`

Если изменение касается install-контракта, миграции или артефактов, обновляйте обе языковые версии в том же проходе.

## Ожидания по release metadata

Если вы готовите релиз:

- обновите `SCRIPT_VERSION`
- обновите release markers в wrapper и readme
- добавьте совпадающие секции в оба changelog
- не ставьте тег, пока branch ci не зеленый

## Checklist для pull request

- [ ] локальные проверки зелёные (`make ci`)
- [ ] tests покрывают измененное поведение
- [ ] docs обновлены для пользовательских изменений
- [ ] оба changelog обновлены, если затронуты release metadata
- [ ] секреты не попали в коммит
- [ ] rollback и security-контракты сохранены

## Сообщение об уязвимостях

Публичные issue для уязвимостей не создаются.

Используйте GitHub private vulnerability reporting. См. [SECURITY.ru.md](SECURITY.ru.md).
