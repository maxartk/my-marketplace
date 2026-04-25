---
name: reddit-monitor
description: Моніторинг Reddit — відслідковує нові пости в особистих спільнотах, надсилає дайджест у Telegram
version: 1.4.0
author: Max
category: monitoring
triggers: [reddit, що пишуть про openclaw, що пишуть про hermes, моніторинг reddit, новини openclaw, новини hermes, reddit дайджест]
---

# Reddit Monitor — web_search (без блокування)

Моніторинг нових постів через вбудований web_search інструмент Hermes.
Працює з будь-якого IP, не потребує API ключів.

## Конфігурація спільнот

```yaml
subreddits:
  - AIToolsPerformance
  - AskClaw
  - clawdbot
  - hermesagent
  - homeassistant
  - n8nbusinessautomation
  - openclaw
  - openclawsetup
  - PLC
```

### Як додати нову спільноту
Скажи агенту: "Додай r/назва до reddit-monitor"

## Пошук через web_search

```bash
# Використовуй web_search для пошуку Reddit постів
web_search("site:reddit.com/r/openclaw new posts", limit=5)
web_search("site:reddit.com/r/hermesagent new posts", limit=5)
web_search("site:reddit.com/r/homeassistant new posts", limit=5)
```

## Маршрутизація між агентами

```
@hermes   — запускає моніторинг за розкладом або на запит
@hermes   — виконує web_search запити, збирає пости
@hermes   — аналізує результати, складає дайджест
@hermes   — надсилає дайджест у Telegram
```

## Формат Telegram дайджесту

```
📡 Reddit Дайджест
🕐 25 Apr 2026, 09:00

🤖 r/openclaw (2 нових):
• "OpenClaw v2.1 released"
  → reddit.com/r/openclaw/...
• "How to set up marketplace?"
  → reddit.com/r/openclaw/...

🧠 r/hermesagent (1 новий):
• "Hermes memory system deep dive"
  → reddit.com/r/hermesagent/...

🏠 r/homeassistant (1 новий):
• "Zigbee mesh optimization tips"
  → reddit.com/r/homeassistant/...

— r/AskClaw, r/clawdbot, r/n8nbusinessautomation,
  r/AIToolsPerformance, r/openclawsetup, r/PLC: нових постів немає
```

## Розклад

```bash
cronjob create \
  --schedule "0 9,21 * * *" \
  --prompt "Виконай reddit-monitor скіл. Використовуй web_search для пошуку нових постів в усіх subreddits з конфігу. Знайди пости за останні 12г. Склади дайджест і відправ у Telegram тільки якщо є хоча б 1 новий пост."
```

## Telegram сповіщення

```bash
curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id=1839631296 \
  -d parse_mode=HTML \
  -d disable_web_page_preview=true \
  -d text="<повідомлення>"
```

## Встановлення / оновлення

```bash
cp -r /tmp/marketplace/plugins/reddit-monitor ~/.openclaw/skills/
cp -r /tmp/marketplace/plugins/reddit-monitor ~/.hermes/skills/
```
