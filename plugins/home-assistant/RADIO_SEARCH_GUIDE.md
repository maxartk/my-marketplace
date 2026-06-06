# Інструкція з пошуку та включення радіо

## Алгоритм пошуку радіостанції

### Крок 1: Пошук URL
1. Використати Google/Brave пошук
2. Шукати фрази:
   - "назва радіо direct stream URL"
   - "назва радіо live stream"
   - "назва радіо online radio"

### Крок 2: Перевірка URL
1. Відкрити посилання в браузері
2. Перевірити:
   - Чи грає аудіо
   - Чи не є це плейлист (.m3u, .pls)
   - Чи direct MP3/AAC stream

### Крок 3: Тест URL
```bash
curl -I "ПОСИЛАННЯ_НА_СТРІМ"
```
- Має бути статус 200 OK
- Content-Type: audio/mpeg або audio/aac

### Крок 4: Включення в Home Assistant
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/play_media" \
-d '{
    "entity_id": "media_player.spalnia_3", 
    "media_content_id": "ПЕРЕВІРЕНИЙ_URL", 
    "media_content_type": "audio/mpeg"
}'
```

## Корисні tips
- Шукати на спеціалізованих сайтах:
  1. radio.net
  2. tunein.com
  3. listenlive.eu
- Уникати посилань з невідомих джерел
- Перевіряти легальність стріму

## Перевірка працездатності
1. Відкрити URL у VLC/браузері
2. Якщо грає - можна включати
3. Якщо не грає - шукати інший URL

## Обережно!
- Деякі радіо мають геоблокування
- Не всі стріми працюють цілодобово
- Мати запасні варіанти URL