# FAQ

## Проект готов для production?

Это публичный automation-toolkit с CI и release gates.
Используй его со своей operational responsibility и нормальным host hardening.

## Какая ОС официально поддерживается?

Текущая валидируемая платформа:

- Ubuntu 24.04 LTS

Другие Linux-дистрибутивы могут работать, но не входят в активный CI-контракт.

## Почему install теперь задаёт меньше вопросов?

В v6 дефолтный путь специально сделан opinionated.
`install` автоматически выбирает xhttp, `ru-auto` и default count.
`install --advanced` нужен только для ручных prompt’ов.

## Можно ли всё ещё выбрать `grpc` или `http2` при install?

Нет.
В v6 mutating product paths работают только с xhttp.
Если у тебя уже есть managed legacy install, выполни:

```bash
sudo xray-reality.sh migrate-stealth --non-interactive --yes
```

## Что значит `legacy transport` в status?

Это означает, что managed server config всё ещё использует `grpc` или `http2`.
`status`, `logs`, `diagnose`, `rollback` и `uninstall` продолжают работать, но mutating-действия вроде `update`, `repair` и `add-clients` сначала требуют миграции.

## В чём разница между `recommended` и `rescue`?

- `recommended` = xhttp `mode=auto`
- `rescue` = xhttp `mode=packet-up`

Mutating-flows сначала тестируют `recommended`, а при необходимости падают на `rescue`.

## Для чего нужен `capabilities.json`?

Это machine-readable capability matrix экспортов.
Она показывает, какие форматы являются:

- `native`
- `link-only`
- `unsupported`

Для xhttp canonical client artifact — raw xray json.

## Что хранится в `self-check.json`?

Последний transport-aware verdict:

- имя действия
- verdict (`ok`, `warning`, `broken`)
- выбранный variant
- результаты probe
- причины для оператора

## Что означает self-check `warning`?

Сервер остался рабочим, но `recommended` не прошел, а `rescue` прошел.
Это деградация, но не поломка.
Смотри `status --verbose`, `diagnose` и сохраненный state file.

## Для чего нужен `scripts/measure-stealth.sh`?

Это локальный measurement harness.
Он использует тот же probe-engine, что и runtime self-check, и пишет JSON-report для сравнения `recommended` / `rescue`.

## Проект привязан к одному человеку или серверу?

Нет. Содержимое репозитория, документация и defaults рассчитаны на публичное универсальное использование.

## Где можно задать вопросы?

- GitHub Discussions
- GitHub Issues (для воспроизводимых багов)
- Контакт в X: [x.com/neket371](https://x.com/neket371)
