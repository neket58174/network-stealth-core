# Глоссарий

## xhttp-only install

Дефолтный install-контракт. `install` выбирает минимальный strongest-default путь с xhttp и сокращенным количеством вопросов.

## Advanced mode

`install --advanced`. Включает ручные prompt’ы выбора профиля и числа конфигов.

## Migrate-stealth

Managed-действие, которое переводит legacy `grpc/http2` install на xhttp и пересобирает артефакты.

## Tier

Предопределенный пул доменов для генерации destination и SNI-комбинаций.

## Profile

Пользовательский выбор, который мапится на внутренний tier и лимиты конфигов: `ru`, `ru-auto`, `global-50` и т.д.

## Legacy transport

Managed-config, который всё ещё использует `grpc` или `http2`. `status` помечает его как legacy, а mutating-действия сначала требуют миграции.

## Client variant

Профиль клиента внутри `clients.json` `variants[]`.

## Recommended variant

Основной xhttp client artifact с `mode=auto`.

## Rescue variant

Fallback xhttp client artifact с `mode=packet-up`.

## Raw xray export

Per-variant client json files в `export/raw-xray/`.

## Capability matrix

`export/capabilities.json` — machine-readable карта поддержки native, link-only и unsupported export targets.

## Self-check state

`/var/lib/xray/self-check.json` — последний transport-aware verdict после mutating-действия.

## Measurement harness

`scripts/measure-stealth.sh` — локальный probe-tool, использующий тот же engine, что и runtime self-check.

## SNI fallback

Автоматический выбор другого валидного server name, когда preferred SNI недоступен.

## Domain planner

Модуль, который выбирает домены через ranking, quarantine и no-repeat sequencing.

## Health file

`DOMAIN_HEALTH_FILE` — runtime-state для ranking и quarantine решений.

## Strict minisign mode

Поведение `--require-minisign`, при котором отсутствие verifier или signature ломает install/update.

## Compatibility mode (no systemd)

Режим `--allow-no-systemd` для ограниченных окружений, где полный service-management недоступен.

## Artifact consistency

Состояние, в котором `config.json`, `keys.txt`, `clients.txt`, `clients.json`, export files и self-check state отражают один согласованный конфиг.
