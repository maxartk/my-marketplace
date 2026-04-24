---
name: wikipedia-search
description: Пошук інформації у Вікіпедії через API
---

# Wikipedia Search Plugin

Шукає інформацію у Вікіпедії та повертає релевантні результати.

## Використання

Команди:
- `шукай у Вікіпедії [тема]` — знайти статті
- `Вікіпедія [тема]` — те саме
- `що сталося в [тема] за [період]` — знайти події за період

## API Endpoint

```
https://uk.wikipedia.org/w/api.php?action=query&list=search&srsearch={QUERY}&format=json
```

Для англійської:
```
https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch={QUERY}&format=json
```

## Приклади запитів

- `шукай у Вікіпедії OpenClaw`
- `знайди на Вікіпедії новини AI за березень 2026`
- `Вікіпедія Golden State Warriors`

## Формат відповіді

Повертай:
1. Назву статті
2. Короткий уривок (snippet)
3. Посилання на статтю

## Мова

За замовчуванням — українська Вікіпедія. Якщо там немає інформації — шукай на англійській.
