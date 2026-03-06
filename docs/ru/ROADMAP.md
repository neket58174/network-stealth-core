# Roadmap

Этот roadmap отражает публичное направление развития, а не жесткие сроки.

## Текущий baseline

v5.1.0 закрепляет:

- минимальный xhttp-first install как strongest default
- `install --advanced` для ручной настройки через prompt’ы
- `migrate-stealth` для managed legacy-миграции
- schema v2 клиентских артефактов с вариантами по конфигу

## Ближние приоритеты

1. transport-aware health checks, а не только проверка listening-портов
2. более честная capability-матрица клиентских export-форматов
3. усиление migration и rollback покрытия для legacy install
4. дальнейшая синхронизация всей публичной документации

## Следующие улучшения

- повысить читаемость domain-health и operator verdicts
- сделать compatibility notes по каждому client/export target явнее
- усилить проверку артефактов после `update`, `repair` и миграции
- собрать measurement loop для реального поведения в рф-сетях

## Средний горизонт

- вывести legacy `grpc/http2` из активной продуктовой линии после compatibility window
- четче отделить policy inputs от generated runtime artifacts
- добавить optional experimental stealth tiers без ослабления дефолтного пути

## Пока вне scope

- широкие multi-os обещания без ci-валидации
- enterprise orchestration без понятного бюджета поддержки
- скрытые behavioral changes без changelog и migration notes

## Как влиять на roadmap

- открыть Discussion с конкретным use-case
- приложить воспроизводимую диагностику reliability-проблем
- присылать PR сразу с тестами и двуязычным docs update
