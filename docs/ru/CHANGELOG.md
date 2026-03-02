# Changelog

Здесь фиксируются изменения **Network Stealth Core**.

Формат: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Версионирование: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- Документация переведена в двуязычную структуру `docs/en` и `docs/ru`.
- Публичное имя проекта унифицировано как `Network Stealth Core`.

## [4.2.0] - 2026-02-26

### Changed

- Нормализованы операционные команды под установленный `xray-reality.sh`.
- Уточнён поддерживаемый контур: Ubuntu 24.04 LTS.
- Добавлены явные compatibility-флаги: `--allow-no-systemd`, `--require-minisign`.
- Документирована политика trust-anchor для minisign.
- Пул `tier_global_ms10` расширен с 10 до 50 доменов.

### Fixed

- Install теперь нейтрализует конфликтующие systemd drop-in файлы.
- `install`, `update`, `repair` корректно прекращают выполнение без systemd, если не включён compatibility-режим.
- В strict minisign режиме реализован fail-closed.
- Исправлено распределение доменов, исключены соседние дубли.
- Исправлен аварийный diagnostic-путь (`journalctl --no-pager`).

## [4.1.8] - 2026-02-24

### Changed

- CI и документация сфокусированы на Ubuntu 24.04.
- Уточнены названия workflow-run и метаданные пакетов.
- Обновлена формулировка документации для публичного репозитория.
- Добавлен release-checklist для Ubuntu 24.04.

### Fixed

- Исправлена обработка BBR sysctl значений.
- Улучшено поведение в isolated root окружениях.

## [4.1.7] - 2026-02-22

### Note

- Базовый релиз, с которого начата история в этом репозитории.

## [<4.1.7]

### Note

- Старые релизы до миграции в новый репозиторий здесь не публикуются.
- История до 4.1.7 намеренно свернута.
