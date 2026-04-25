---
name: reddit-monitor
description: Моніторинг Reddit — відслідковує нові пости про OpenClaw та Hermes через web_search, надсилає дайджест у Telegram
version: 1.1.0
author: Max
category: monitoring
triggers: [reddit, що пишуть про openclaw, що пишуть про hermes, моніторинг reddit, новини openclaw, новини hermes]
---

# Reddit Monitor — OpenClaw & Hermes

Відслідковує нові пости та обговорення про OpenClaw і Hermes на Reddit.
Використовує web_search (Google) замість прямого Reddit API — працює без OAuth.

## Пошукові запити

Виконай ці пошуки через web_search:

```
site:reddit.com "OpenClaw" after:2026-01-01
site:reddit.com "Hermes agent" after:2026-01-01
site:reddit.com "openclaw agent" 
site:reddit.com "hermes AI"
```

## Маршрутизація між агентами

```
@hermes   — запускає моніторинг за розкладом або на запит
@claude   — виконує web_search, аналізує результати, складає дайджест
@openclaw — надсилає дайджест у Telegram
```

## Алгоритм

1. Виконай 4 пошуки через web_search
2. Відфільтруй тільки посилання з reddit.com
3. Видали дублікати
4. Відсортуй по даті (нові спочатку)
5. Склади дайджест (максимум 5 постів)
6. Відправ у Telegram

## Формат Telegram дайджесту

### Є нові пости:
```
📡 Reddit Monitor — OpenClaw & Hermes
🕐 25 Apr 2026, 09:00

🔴 OpenClaw (2 нових):
1. "OpenClaw vs Claude Code — which is better?"
   r/LocalLLaMA → reddit.com/r/...

2. "Anyone using OpenClaw for automation?"
   r/artificial → reddit.com/r/...

🟡 Hermes (1 новий):
1. "Hermes agent memory system"
   r/MachineLearning → reddit.com/r/...

💡 Висновок: [коротко що обговорюють]
```

### Нічого нового:
```
📡 Reddit Monitor
Нових постів за 24г не знайдено.
```

## Telegram відправка

```bash
curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id=1839631296 \
  -d parse_mode=HTML \
  -d disable_web_page_preview=true \
  -d text="<повідомлення>"
```

## Розклад

```bash
cronjob create \
  --schedule "0 9 * * *" \
  --prompt "Виконай reddit-monitor скіл, знайди нові пости за 24г про OpenClaw і Hermes, відправ дайджест у Telegram тільки якщо є результати"
```

## Встановлення

```bash
cp -r /tmp/marketplace/plugins/reddit-monitor ~/.openclaw/skills/
cp -r /tmp/marketplace/plugins/reddit-monitor ~/.hermes/skills/
```
