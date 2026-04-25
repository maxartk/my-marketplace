---
name: reddit-monitor
description: Моніторинг Reddit — відслідковує нові пости в особистих спільнотах, надсилає дайджест у Telegram
version: 1.5.0
author: Max
category: monitoring
triggers: [reddit, що пишуть про openclaw, що пишуть про hermes, моніторинг reddit, новини openclaw, новини hermes, reddit дайджест]
---

# Reddit Monitor — terminal (без блокування)

Моніторинг нових постів через curl запити.
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

## Пошук через DuckDuckGo HTML

```bash
# Функція пошуку постів через DuckDuckGo
search_reddit() {
  local query=$1
  curl -s -L -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
    "https://html.duckduckgo.com/html/?q=${query}" \
    | python3 -c "
import re, sys
from html import unescape
html = sys.stdin.read()
titles = re.findall(r'class=\"result__a\"[^>]*>(.*?)</a>', html, re.DOTALL)
urls = re.findall(r'class=\"result__url\"[^>]*>(.*?)</a>', html, re.DOTALL)
for i, (t, u) in enumerate(zip(titles[:5], urls[:5])):
    title = unescape(re.sub(r'<[^>]+>', '', t)).strip()[:80]
    url = unescape(re.sub(r'<[^>]+>', '', u)).strip()
    print(f'{i+1}. {title}')
    print(f'   {url}')
    print()
"
}

# Приклад використання
search_reddit "site:reddit.com/r/openclaw new posts"
search_reddit "site:reddit.com/r/hermesagent new posts"
search_reddit "site:reddit.com/r/homeassistant new posts"
```

## Маршрутизація між агентами

```
@hermes   — запускає моніторинг за розкладом або на запит
@hermes   — виконує curl запити через DuckDuckGo, збирає пости
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
  --prompt "Виконай reddit-monitor скіл. Використовуй curl для пошуку нових постів в усіх subreddits з конфігу через DuckDuckGo. Знайди пости за останні 12г. Склади дайджест і відправ у Telegram тільки якщо є хоча б 1 новий пост."
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

## Cronjob налаштування

### КРИТИЧНО: toolsets для cronjob
Cronjob **не має доступу до web_search** навіть якщо він увімкнений для основного агента.
Потрібно явно вказати `enabled_toolsets`:

```bash
cronjob create \
  --schedule "0 9,21 * * *" \
  --enabled_toolsets "terminal,messaging" \
  --skills "reddit-monitor" \
  --prompt "Виконай reddit-monitor скіл. Використовуй curl для пошуку нових постів в усіх subreddits з конфігу через DuckDuckGo. Знайди пости за останні 12г. Склади дайджест і відправ у Telegram тільки якщо є хоча б 1 новий пост."
```

### Перевірка роботи
```bash
# Запуск тесту вручну
cronjob run --job_id <job_id>

# Перевірка результатів
ls -la ~/.hermes/cron/output/<job_id>/
cat ~/.hermes/cron/output/<job_id>/<date>.md
```

## Troubleshooting

### Чому не працюють інші методи

| Метод | Статус | Причина |
|-------|--------|---------|
| Reddit JSON API | ❌ 403 | Блокує хмарні IP (OCI ARM, AWS, GCP) |
| old.reddit.com RSS | ❌ 403 | Блокує хмарні IP |
| DuckDuckGo HTML | ✅ Працює | Не блокує автоматизовані запити |
| Google Search | ❌ Timeout | Блокує хмарні IP |
| web_search (Hermes) | ❌ Недоступний | Не працює в cronjob контексті |

### Помилка: "I don't have access to a web_search tool"
**Причина:** Cronjob запускається в ізольованому контексті без доступу до web_search.
**Рішення:** Додати `--enabled_toolsets "terminal,messaging"` при створенні cronjob.

### Помилка: "0 results" від DuckDuckGo
**Причина:** Занадто специфічний запит або DuckDuckGo тимчасово блокує IP.
**Рішення:** Спробувати інший User-Agent або додати затримку між запитами (`sleep 1`).

## Історія версій
- **v1.5.0** — switch to curl/DuckDuckGo via terminal toolset (fixes cronjob web_search issue)
- **v1.4.0** — switch to web_search (не працює в cronjob)
- **v1.3.0** — switch to RSS feeds (не працює з хмарних IP)
- **v1.2.0** — personal subreddits list
- **v1.1.0** — switch to web_search
- **v1.0.0** — initial version with Reddit JSON API
