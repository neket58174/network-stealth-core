# Глоссарий

## xhttp-first install

Дефолтный install-контракт. `install` выбирает минимальный strongest-default путь на xhttp с минимумом вопросов.

## Advanced mode

`install --advanced`. Включает ручной выбор профиля и числа конфигов.

## Migrate-stealth

Managed-действие, которое переводит legacy `grpc/http2` install на xhttp и пересобирает артефакты.

## Tier

Предопределенный пул доменов для генерации destination и SNI-комбинаций.

## Profile

Публичный выбор пользователя, который маппится на внутренний tier и лимиты, например `ru`, `ru-auto` или `global-50`.

## Legacy transport

Managed-конфиг, который все еще использует `grpc` или `http2`. В `status` он помечается как legacy и рекомендуется к миграции.

## Client variant

Отдельный клиентский профиль внутри `clients.json` `variants[]`.

## Recommended variant

Основной xhttp-клиентский артефакт с `mode=auto`.

## Rescue variant

Fallback xhttp-клиентский артефакт с `mode=packet-up`.

## Raw xray export

Файлы клиентского json, которые пишутся по вариантам в `export/raw-xray/`.

## SNI fallback

Автоматический выбор другого валидного server name, если приоритетный SNI недоступен.

## Domain planner

Модуль выбора доменов с учетом ranking, quarantine и no-repeat последовательности.

## Health file

`DOMAIN_HEALTH_FILE` — runtime-состояние для ранжирования и карантина доменов.

## Strict minisign mode

Поведение `--require-minisign`, при котором отсутствие verifier или подписи ломает install или update.

## Compatibility mode (без systemd)

Режим `--allow-no-systemd` для ограниченных окружений без полноценного systemd management.

## Консистентность артефактов

Состояние, при котором `config.json`, `keys.txt`, `clients.txt`, `clients.json` и export-файлы соответствуют одному набору конфигурации.
