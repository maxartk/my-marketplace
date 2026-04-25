---
name: reddit-monitor
description: Моніторинг Reddit — відслідковує нові пости в особистих спільнотах, надсилає дайджест у Telegram
version: 1.2.0
author: Max
category: monitoring
triggers: [reddit, що пишуть про openclaw, що пишуть про hermes, моніторинг reddit, новини openclaw, новини hermes, reddit дайджест]
---

# Reddit Monitor — Особисті спільноти

Моніторинг нових постів у вибраних subreddits.
Надсилає дайджест у Telegram двічі на день.

## Конфігурація спільнот

Список subreddits для моніторингу (редагуй цей розділ щоб додати нові):

```yaml
subreddits:
  - r/AIToolsPerformance
  - r/AskClaw
  - r/clawdbot
  - r/hermesagent
  - r/homeassistant
  - r/n8nbusinessautomation
  - r/openclaw
  - r/openclawsetup
  - r/PLC
```

### Як додати нову спільноту
Просто скажи агенту:
> "Додай r/назва до reddit-monitor"

Або відредагуй цей файл вручну і запуши в маркетплейс.

## Пошук через DuckDuckGo

```bash
# Функція пошуку постів в одному subreddit
search_subreddit() {
  local sub=$1
  local query=$2
  curl -s -L -A "Mozilla/5.0" \
    "https://html.duckduckgo.com/html/?q=site:reddit.com/r/${sub}+${query}" \
    | python3 -c "
import re, sys
from html import unescape
html = sys.stdin.read()
titles = re.findall(r'class=\"result__a\"[^>]*>(.*?)</a>', html, re.DOTALL)
urls = re.findall(r'class=\"result__url\"[^>]*>(.*?)</a>', html, re.DOTALL)
for t, u in zip(titles[:3], urls[:3]):
    title = unescape(re.sub(r'<[^>]+>', '', t)).strip()[:80]
    url = unescape(re.sub(r'<[^>]+>', '', u)).strip()
    if 'reddit.com' in url:
        print(f'{title}|{url}')
"
}

# Пошук нових постів за добу в кожному subreddit
for sub in AIToolsPerformance AskClaw clawdbot hermesagent homeassistant n8nbusinessautomation openclaw openclawsetup PLC; do
  echo "=== r/$sub ==="
  search_subreddit "$sub" ""
done
```

## Маршрутизація між агентами

```
@hermes   — запускає моніторинг за розкладом або на запит
@openclaw — виконує curl запити через DuckDuckGo
@claude   — аналізує результати, виділяє топ пости, складає дайджест
@openclaw — надсилає дайджест у Telegram
```

## Формат Telegram дайджесту

```
📡 Reddit Дайджест
🕐 25 Apr 2026, 09:00

🤖 r/openclaw (2 нових):
• "OpenClaw v2.1 released — new skill system"
  → reddit.com/r/openclaw/...
• "How to set up marketplace?"
  → reddit.com/r/openclaw/...

🧠 r/hermesagent (1 новий):
• "Hermes memory system deep dive"
  → reddit.com/r/hermesagent/...

🏠 r/homeassistant (3 нових):
• "Zigbee mesh optimization tips"
  → reddit.com/r/homeassistant/...

⚙️ r/n8nbusinessautomation (1 новий):
• "n8n + Claude integration workflow"
  → reddit.com/r/n8nbusinessautomation/...

— r/AIToolsPerformance, r/AskClaw, r/clawdbot,
  r/openclawsetup, r/PLC: нових постів немає
```

## Розклад

```bash
# Двічі на день — 9:00 та 21:00
cronjob create \
  --schedule "0 9,21 * * *" \
  --prompt "Виконай reddit-monitor скіл. Перевір всі subreddits з конфігу. Знайди нові пости за останні 12г через DuckDuckGo. Склади дайджест і відправ у Telegram тільки якщо є хоча б 1 новий пост."
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
