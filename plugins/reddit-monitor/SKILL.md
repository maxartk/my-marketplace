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

### Пошук постів через Reddit JSON API (без авторизації)
```bash
# Пошук по ключовому слову
curl -s -A "reddit-monitor-bot/1.0" \
  "https://www.reddit.com/search.json?q=OpenClaw+agent&sort=new&limit=10&t=day" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for post in data['data']['children']:
    p = post['data']
    print(f\"Title: {p['title']}\")
    print(f\"Sub: r/{p['subreddit']}\")
    print(f\"Score: {p['score']}\")
    print(f\"URL: https://reddit.com{p['permalink']}\")
    print('---')
"
```

### Моніторинг конкретного subreddit
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
  --prompt "Виконай reddit-monitor скіл, знайди нові пости за останні 24г про OpenClaw і Hermes, відправ дайджест у Telegram"

# Або кожні 6 годин якщо хочеш частіше
cronjob create \
  --schedule "0 */6 * * *" \
  --prompt "Виконай reddit-monitor скіл, відправ тільки якщо є нові пости"
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
