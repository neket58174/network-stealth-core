# Troubleshooting

Используй этот гайд, если установка, миграция или runtime-поведение идут не так, как ожидается.

## 1. Install завершился ошибкой

### Проверки

```bash
sudo tail -n 200 /var/log/xray-install.log
sudo xray-reality.sh diagnose
```

### Типичные причины

- не хватает зависимостей или сломаны package mirrors
- нет writable target path
- существующие runtime-файлы не проходят safety validation
- self-check не смог подтвердить ни `recommended`, ни `rescue`

## 2. Во время install появились неожиданные ручные prompt’ы

Обычный `install` должен идти по минимальному xhttp-only пути.

Если нужны ручные prompt’ы профиля и числа конфигов, запускай:

```bash
sudo xray-reality.sh install --advanced
```

Если automation должен быть строго non-interactive, добавь:

```bash
--yes --non-interactive
```

## 3. В status показан `legacy transport`

### Что это значит

Managed-установка всё ещё использует legacy `grpc` или `http2`.

### Рекомендуемое действие

```bash
sudo xray-reality.sh status --verbose
sudo xray-reality.sh migrate-stealth --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Ожидаемое состояние после:

- `Transport: xhttp`
- нет предупреждения `legacy transport`
- пересобраны client artifacts, raw xray exports и capability matrix

## 4. Mutating-действие заблокировано на legacy install

Типичное сообщение:

- `action 'update' is blocked in v6`
- `first run: xray-reality.sh migrate-stealth --non-interactive --yes`

### Исправление

Сначала выполни миграцию, потом повтори mutating-команду.

## 5. Service active, но self-check = `warning`

### Что это значит

`recommended` не прошел, но `rescue` прошел.

### Проверки

```bash
sudo xray-reality.sh status --verbose
sudo jq . /var/lib/xray/self-check.json
sudo xray-reality.sh diagnose
```

### Восстановление

- проверь selected variant и latency
- сравни `recommended` и `rescue` через `scripts/measure-stealth.sh`
- если деградация держится, запусти `repair` или ротируй хост

## 6. Self-check = `broken`

### Проверки

```bash
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo jq . /var/lib/xray/self-check.json
sudo xray-reality.sh diagnose
```

### Безопасный fallback

```bash
sudo xray-reality.sh rollback
```

Если последнее mutating-действие упало, проект должен был уже сделать автоматический rollback.

## 7. Клиентские артефакты выглядят несогласованно

### Симптомы

- `clients.txt` и `clients.json` расходятся
- нет ожидаемых вариантов `recommended` / `rescue`
- отсутствуют или устарели файлы в `export/raw-xray/`
- `export/capabilities.json` не соответствует реальным артефактам

### Восстановление

```bash
sudo xray-reality.sh repair --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Потом проверь:

- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json`
- `/etc/xray/private/keys/export/raw-xray/`
- `/etc/xray/private/keys/export/capabilities.json`

## 8. `migrate-stealth` завершился ошибкой

### Проверки

```bash
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo xray-reality.sh diagnose
```

### Частые причины

- managed config был сломан ещё до миграции
- локальные артефакты менялись вручную вне managed-flow
- systemd или firewall уже в несогласованном состоянии

### Безопасный fallback

```bash
sudo xray-reality.sh rollback
```

## 9. Появляется предупреждение minisign

### Что это значит

В релизе нет minisign-подписи или локальный verifier недоступен.

### Что делать

- для strict-окружений используй `--require-minisign`
- иначе продолжай только если SHA256-only режим допустим в твоей threat model

## 10. Локальный measurement-report показывает отсутствие успешных вариантов

### Проверки

```bash
sudo bash scripts/measure-stealth.sh --output /tmp/measure-stealth.json
jq . /tmp/measure-stealth.json
```

### Что это значит

Ни `recommended`, ни `rescue` не сработали хотя бы для одного managed-конфига в текущей сети.

### Что делать дальше

- сравни с другой клиентской сетью
- проверь здоровье сервера и self-check state
- redeploy/rotate, если узел выглядит burned

## 11. Подтверждение uninstall ведёт себя странно

Если подтверждение не принимается:

- вводи обычное `yes` или `no`
- не вставляй текст со скрытыми символами
- при необходимости используй automation-safe режим:

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

## 12. Recovery последней инстанции

```bash
sudo xray-reality.sh rollback
sudo xray-reality.sh status --verbose
sudo xray-reality.sh diagnose
```

Если rollback не восстановил рабочее состояние, открой issue с очищенными логами и точными командами.
