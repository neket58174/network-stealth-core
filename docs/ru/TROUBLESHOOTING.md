# Troubleshooting

Этот документ помогает диагностировать сбои установки, миграции и рантайма.

## 1. Установка прервалась

### Проверки

```bash
sudo tail -n 200 /var/log/xray-install.log
sudo xray-reality.sh diagnose
```

### Частые причины

- не установлены зависимости или сломан пакетный mirror
- нет прав на запись в целевые пути
- существующие runtime-файлы не проходят safety-валидацию

## 2. Во время install появились неожиданные ручные prompt’ы

Обычный `install` должен идти по минимальному xhttp-first пути.

Если нужен ручной выбор профиля и числа конфигов, запускайте:

```bash
sudo xray-reality.sh install --advanced
```

Если автоматизация неожиданно блокируется на prompt’ах, добавьте:

```bash
--yes --non-interactive
```

## 3. В `status` показан `legacy transport`

### Что это значит

Managed-установка все еще использует `grpc` или `http2`.

### Рекомендуемое действие

```bash
sudo xray-reality.sh status --verbose
sudo xray-reality.sh migrate-stealth --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Ожидаемое состояние после миграции:

- `Transport: xhttp`
- нет предупреждения `legacy transport`
- артефакты и raw xray exports пересобраны

## 4. Сервис active, но нужные порты не слушаются

### Проверки

```bash
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo ss -tlnp | grep xray
```

### Частые причины

- конфликтующие systemd drop-in меняют `ExecStart` или runtime user
- `config.json` рассинхронизирован с клиентскими артефактами
- после внешних изменений произошел дрейф firewall

### Восстановление

```bash
sudo xray-reality.sh repair --non-interactive --yes
```

## 5. Клиентские артефакты выглядят неконсистентно

### Симптомы

- `clients.txt` и `clients.json` не совпадают
- пропали варианты `recommended` / `rescue`
- отсутствуют или устарели файлы в `export/raw-xray/`

### Восстановление

```bash
sudo xray-reality.sh repair --non-interactive --yes
sudo xray-reality.sh status --verbose
```

Проверьте:

- `/etc/xray/private/keys/clients.txt`
- `/etc/xray/private/keys/clients.json`
- `/etc/xray/private/keys/export/raw-xray/`

## 6. `migrate-stealth` завершился ошибкой

### Проверки

```bash
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo xray-reality.sh diagnose
```

### Типовые причины

- managed-конфиг уже сломан до миграции
- локальные артефакты были вручную изменены вне managed flow
- systemd или firewall уже находятся в неконсистентном состоянии

### Безопасный fallback

```bash
sudo xray-reality.sh rollback
```

## 7. Появилось предупреждение про minisign

### Что это значит

В релизе нет minisign-подписи или verifier недоступен локально.

### Что делать

- для строгого контура используйте `--require-minisign`
- иначе продолжайте только если SHA256-only режим допустим в вашей threat model

## 8. DNS timeout в логах клиента

### Симптомы

Повторяются ошибки вида:

- `dns: exchange failed`
- `context deadline exceeded`

### Checklist

- протестировать другой сгенерированный конфиг или `rescue` вариант
- проверить доступность сервера из клиентской сети
- проверить локальную DNS-стратегию клиента и outbound rules
- убедиться, что сеть не блокирует выбранный DNS-путь

Быстрая серверная проверка:

```bash
sudo xray-reality.sh status
sudo journalctl -u xray -n 200 --no-pager
```

## 9. Подтверждение uninstall ведет себя странно

Если подтверждение не принимается:

- вводите только `yes` или `no`
- не вставляйте текст со скрытыми символами
- для автоматизации используйте:

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

## 10. Аварийное восстановление

```bash
sudo xray-reality.sh rollback
sudo xray-reality.sh status
sudo xray-reality.sh diagnose
```

Если rollback не помогает, откройте issue и приложите очищенные логи и точные команды.
