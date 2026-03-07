# Roadmap

Этот roadmap — публичный вектор развития, а не жёсткое обещание поставки.

## Текущий baseline

v6.0.0 закрепляет:

- xhttp-only strongest-default install
- явную блокировку mutating-действий на managed legacy transport до `migrate-stealth`
- transport-aware self-check на canonical raw xray client artifacts
- capability-driven export matrix
- local measurement harness для сравнения на реальных сетях

## Ближайшие приоритеты

1. усилить observability self-check и probe-diagnostics
2. улучшить feedback по domain-health и operator summaries
3. расширить measurement-reports и tooling для сравнения
4. держать двуязычную документацию и release metadata идеально синхронными

## Следующие улучшения

- более богатый summarize-and-compare output для `scripts/measure-stealth.sh`
- более точные capability notes для внешних клиентов
- более сильное e2e-покрытие degraded `warning` путей
- более заметные рекомендации по field-data для проверки на сетях рф

## Среднесрочное направление

- optional experimental stealth tiers без ослабления дефолтного пути
- более четкое разделение policy inputs и generated runtime artifacts
- лучшая operator-tooling для rotation/retire деградировавших узлов

## Пока вне scope

- широкие multi-os обещания без ci-валидации
- вводящие в заблуждение partial templates для unsupported xhttp targets
- тихие изменения поведения без changelog и migration notes

## Как повлиять на roadmap

- открой Discussion с конкретным use case
- приложи воспроизводимые diagnostics для reliability gaps
- по возможности добавляй self-check или measurement output
- отправляй PR с тестами и двуязычными docs updates
