---
name: reddit-monitor
description: Моніторинг Reddit через RSS — відслідковує нові пости в особистих спільнотах, надсилає дайджест у Telegram
version: 1.3.0
author: Max
category: monitoring
triggers: [reddit, що пишуть про openclaw, що пишуть про hermes, моніторинг reddit, новини openclaw, новини hermes, reddit дайджест]
---

# Reddit Monitor — RSS (без блокування)

Моніторинг нових постів через Reddit RSS фіди.
Працює з будь-якого IP включаючи OCI ARM сервери.

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

## RSS запити

```bash
# Отримати нові пости з одного subreddit
fetch_rss() {
  local sub=$1
  curl -s -A "Mozilla/5.0" \
    "https://www.reddit.com/r/${sub}/new/.rss" \
    | python3 -c "
import sys, re
from html import unescape
xml = sys.stdin.read()
items = re.findall(r'<entry>(.*?)</entry>', xml, re.DOTALL)
for item in items[:3]:
    title = re.search(r'<title[^>]*>(.*?)</title>', item, re.DOTALL)
    link  = re.search(r'<link[^>]*href=\"([^\"]+)\"', item)
    date  = re.search(r'<updated>(.*?)</updated>', item)
    if title and link:
        t = unescape(re.sub(r'<[^>]+>', '', title.group(1))).strip()[:80]
        l = link.group(1)
        d = date.group(1)[:10] if date else ''
        print(f'{d}|{t}|{l}')
"
}

# Перевірити всі subreddits
for sub in AIToolsPerformance AskClaw clawdbot hermesagent homeassistant n8nbusinessautomation openclaw openclawsetup PLC; do
  echo "=== r/$sub ==="
  fetch_rss "$sub"
  sleep 1
done
```

## Маршрутизація між агентами

```
@hermes   — запускає моніторинг за розкладом або на запит
@openclaw — виконує curl RSS запити, збирає пости
@claude   — аналізує результати, складає дайджест
@openclaw — надсилає дайджест у Telegram
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
  --prompt "Виконай reddit-monitor скіл. Отримай RSS фіди всіх subreddits з конфігу. Знайди пости за останні 12г. Склади дайджест і відправ у Telegram тільки якщо є хоча б 1 новий пост."
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
