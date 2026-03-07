# Community

Этот репозиторий публичный и community-driven.

## Где взаимодействовать

- **Discussions** — архитектура, roadmap и вопросы операторов
- **Issues** — воспроизводимые баги и конкретные feature request’ы
- **Pull requests** — точечные изменения кода и документации с проходящими проверками

## Какие репорты помогают проекту больше всего

Полезный репорт обычно включает:

- точную команду
- данные о дистрибутиве и окружении
- очищенные логи
- ожидаемое и фактическое поведение
- произошло ли это на:
  - минимальном xhttp-only install
  - `install --advanced`
  - `migrate-stealth`
  - варианте `recommended` или `rescue`
  - runtime self-check или local measurement harness

## Полезные темы полевого фидбека

- reachability и reliability xhttp на реальных сетях
- поведение `packet-up` rescue на сложных провайдерах
- качество миграции с legacy `grpc/http2`
- корректность capability matrix для v2rayn, nekoray и raw xray clients
- качество self-check verdict и поведение rollback
- measurement reports из реальных сетей рф-операторов

## Чего лучше избегать

- скриншотов без текстовых логов
- расплывчатых сообщений "не работает"
- публикации private keys, `keys.txt` или чувствительных полных ссылок
- смешивания нескольких несвязанных багов в одном issue

## Ожидания от PR

- одно понятное изменение на PR
- тесты и документация обновлены в том же проходе
- rollback и security-поведение сохранены
- зеленый CI до запроса review

Полный workflow: [../../.github/CONTRIBUTING.ru.md](../../.github/CONTRIBUTING.ru.md).

## Контакт мейнтейнера

- X (Twitter): [x.com/neket371](https://x.com/neket371)

## Правила взаимодействия

- будь конкретным и техническим
- спорь с идеями, а не с людьми
- предпочитай факты, логи и repro-шаги
- disclosure по security держи приватным
