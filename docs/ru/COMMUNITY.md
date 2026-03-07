# community

## где просить помощь

используй поверхности репозитория по назначению:

- **discussions** — для design-вопросов, идей roadmap и deployment trade-off’ов
- **issues** — для воспроизводимых багов и несовпадений контракта
- **security reporting** — только для уязвимостей и только через private disclosure

## что делает запрос на поддержку хорошим

приложи достаточно данных, чтобы проблему можно было воспроизвести, но не раскрывай секреты.

хороший запрос включает:

- точную команду, которую ты запускал
- текущую версию или commit
- вывод `sudo xray-reality.sh status --verbose`
- вывод `sudo xray-reality.sh diagnose`
- какой это узел: legacy, migrated или fresh strongest-direct
- релевантный вывод `scripts/measure-stealth.sh` для проблем на реальных сетях
- потребовался ли `emergency` на проверяемой сети

## что нужно редактировать перед публикацией

не публикуй:

- private keys
- полные client links
- raw xray client json
- приватные server addresses, если они идентифицируют твой узел

редактируй `uuid`, `short_id`, `private_key` и domain-specific secrets.

## ожидания от контрибьюта

если ты предлагаешь изменение managed-контракта, приложи:

- почему default path должен измениться или остаться прежним
- tests
- двуязычные updates в документации
- migration notes, если затрагиваются старые managed install

## направление проекта

проект намеренно предпочитает:

- меньше вопросов при установке
- один strongest safe default
- честную отчётность capability export’ов
- сохранённые operator-evidence вместо догадок

изменения, которые ослабляют эти цели, будут рассматриваться строже.
