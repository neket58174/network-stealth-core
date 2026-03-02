# Troubleshooting

Этот документ помогает диагностировать сбои установки и рантайма.

## 1. Установка прервалась

### Симптом

Install завершается с ошибкой и ссылкой на install log.

### Проверки

```bash
sudo tail -n 200 /var/log/xray-install.log
sudo xray-reality.sh diagnose
```

### Частые причины

- не установлены зависимости или проблемный mirror пакетов
- нет прав на запись в целевые пути
- существующий конфиг не проходит safety-проверки

## 2. Сервис active, но порты не слушаются

### Проверки

```bash
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 200 --no-pager
sudo xray -test -c /etc/xray/config.json
sudo ss -tlnp | grep xray
```

### Частые причины

- конфликтующие systemd drop-in, меняющие `ExecStart` или `User`
- рассинхрон между `config.json` и клиентскими артефактами
- дрейф firewall после внешних изменений

### Восстановление

```bash
sudo xray-reality.sh repair --non-interactive --yes
```

## 3. Предупреждение по minisign

### Что это значит

В релизе нет minisign-подписи или verifier недоступен локально.

### Что делать

- для строгого контура запускайте с `--require-minisign`
- либо явно подтверждайте SHA256-only режим

## 4. DNS timeout в логах клиента

### Симптом

Повторяются ошибки `dns: exchange failed ... context deadline exceeded`.

### Checklist

- проверить доступность сервера из клиентской сети
- протестировать другой сгенерированный конфиг/профиль
- проверить DNS-настройки клиента и стратегию резолва
- проверить, не блокируется ли выбранный upstream DNS

Быстрая проверка сервера:

```bash
sudo xray-reality.sh status
sudo journalctl -u xray -n 200 --no-pager
```

## 5. Проблемы с подтверждением uninstall

Если подтверждение не принимается:

- вводите только `yes` или `no`
- не вставляйте текст из буфера с скрытыми символами
- для автоматизации используйте non-interactive режим:

```bash
sudo xray-reality.sh uninstall --yes --non-interactive
```

## 6. Аварийное восстановление

```bash
sudo xray-reality.sh rollback
sudo xray-reality.sh status
```

Если rollback не помогает, соберите диагностику и откройте issue, приложив очищенные от секретов логи.
