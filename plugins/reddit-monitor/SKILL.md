---
name: reddit-monitor
description: Моніторинг Reddit — відслідковує нові пости про OpenClaw та Hermes, надсилає дайджест у Telegram
version: 1.0.0
author: Max
category: monitoring
triggers: [reddit, що пишуть про openclaw, що пишуть про hermes, моніторинг reddit, новини openclaw, новини hermes]
---

# Reddit Monitor — OpenClaw & Hermes

Відслідковує нові пости та обговорення про OpenClaw і Hermes на Reddit.
Надсилає дайджест у Telegram коли є щось цікаве.

## Що моніторити

### Subreddits
```
r/MachineLearning
r/artificial
r/AIAssistants
r/LocalLLaMA
r/ChatGPTPromptEngineering
r/ClaudeAI
r/singularity
```

### Пошукові запити
```
"OpenClaw" site:reddit.com
"Hermes agent" site:reddit.com
"openclaw agent"
"hermes AI agent"
```

## API запити

### Пошук постів через DuckDuckGo HTML (працює без токена, стабільно)
```bash
# Пошук Reddit постів через DuckDuckGo
curl -s -L -A "Mozilla/5.0" \
  "https://html.duckduckgo.com/html/?q=site:reddit.com+OpenClaw+agent" \
  | python3 -c "
import re, sys
from html import unescape
html = sys.stdin.read()
titles = re.findall(r'class=\"result__a\"[^>]*>(.*?)</a>', html, re.DOTALL)
urls = re.findall(r'class=\"result__url\"[^>]*>(.*?)</a>', html, re.DOTALL)
for i, (t, u) in enumerate(zip(titles, urls)):
    print(f\"{i+1}. {unescape(re.sub(r'<[^>]+>', '', t))[:80]}\")
    print(f\"   {unescape(re.sub(r'<[^>]+>', '', u))[:100]}\")
"
```

### Моніторинг конкретного subreddit (якщо працює API)
```bash
curl -s -A "reddit-monitor-bot/1.0" \
  "https://www.reddit.com/r/LocalLLaMA/search.json?q=OpenClaw&sort=new&restrict_sr=1&limit=5" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
posts = data['data']['children']
if not posts:
    print('No new posts')
else:
    for post in posts:
        p = post['data']
        print(f\"{p['title']} | {p['score']} pts | reddit.com{p['permalink']}\")
"
```

## Маршрутизація між агентами

```
@hermes   — запускає моніторинг за розкладом або на запит
@openclaw — виконує curl запити до Reddit API
@claude   — аналізує пости, виділяє найцікавіше, складає дайджест
@openclaw — надсилає дайджест у Telegram
```

## Формат Telegram дайджесту

### Є нові пости:
```
📡 Reddit Monitor — OpenClaw & Hermes
🕐 25 Apr 2026, 09:00

🔴 OpenClaw (3 нових пости):

1. "OpenClaw vs Claude Code — which is better?"
   r/LocalLLaMA | ⬆️ 142 | 47 коментарів
   → reddit.com/r/LocalLLaMA/...

2. "Anyone using OpenClaw for automation?"
   r/artificial | ⬆️ 38 | 12 коментарів
   → reddit.com/r/artificial/...

🟡 Hermes (1 новий пост):

1. "Hermes agent memory system is impressive"
   r/MachineLearning | ⬆️ 89 | 23 коментарі
   → reddit.com/r/MachineLearning/...

💡 Висновок (Claude): Основна тема — порівняння з Claude Code...
```

### Немає нічого нового:
```
📡 Reddit Monitor
Нових постів за останні 24г не знайдено.
```

## Розклад

```bash
# Щоденний дайджест о 9:00
cronjob create \
  --schedule "0 9 * * *" \
  --prompt "Виконай reddit-monitor скіл. Використовуй DuckDuckGo для пошуку 'site:reddit.com OpenClaw' та 'site:reddit.com Hermes'. Знайди нові пости за останні 24г, відправ дайджест у Telegram"

# Або кожні 6 годин якщо хочеш частіше
cronjob create \
  --schedule "0 */6 * * *" \
  --prompt "Виконай reddit-monitor скіл. DuckDuckGo 'site:reddit.com OpenClaw OR Hermes'. Відправ дайджест тільки якщо є нові пости"
```

## Telegram сповіщення

```bash
curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id=1839631296 \
  -d parse_mode=HTML \
  -d disable_web_page_preview=true \
  -d text="<повідомлення>"
```

## Встановлення

```bash
cp -r /tmp/marketplace/plugins/reddit-monitor ~/.openclaw/skills/
cp -r /tmp/marketplace/plugins/reddit-monitor ~/.hermes/skills/
```
