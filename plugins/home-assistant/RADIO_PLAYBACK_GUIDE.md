# Інструкція з відтворення радіо в Home Assistant

## Загальний алгоритм

1. **Вибір джерела:**
   - Використовувати попередньо налаштований скрипт `play_radio.sh`
   - Скрипт знаходиться за шляхом: 
     `/home/ubuntu/.openclaw/workspace/skills/home-assistant/scripts/play_radio.sh`

2. **Виклик скрипту:**
   ```bash
   bash ~/.openclaw/workspace/skills/home-assistant/scripts/play_radio.sh ЖАНР
   ```
   Де ЖАНР може бути:
   - `jazz`
   - `chill`
   - `pop`
   - `hiphop`
   - `hitfm` (українське радіо)

## Якщо скрипт не працює - ручний варіант

### Крок 1: Вимкнення плеєра
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/turn_off" \
-d '{"entity_id": "media_player.spalnia_3"}'
```

### Крок 2: Увімкнення плеєра
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/turn_on" \
-d '{"entity_id": "media_player.spalnia_3"}'
```

### Крок 3: Відтворення радіо
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/play_media" \
-d '{
    "entity_id": "media_player.spalnia_3", 
    "media_content_id": "https://online.hitfm.ua/HitFM", 
    "media_content_type": "audio/mpeg"
}'
```

## Керування гучністю

### Перевірка поточної гучності
```bash
curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states/media_player.spalnia_3" | jq '.attributes.volume_level'
```

### Встановлення гучності (0.0 - 1.0)
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/volume_set" \
-d '{
    "entity_id": "media_player.spalnia_3", 
    "volume_level": 0.5
}'
```

## Корисні URL

1. Хіт ФМ: `https://online.hitfm.ua/HitFM`
2. Резервний Jazz: `http://jazz.streamr.ru/jazz-64.mp3`
3. FluxFM Hip Hop: `https://streams.fluxfm.de/Hiphop/mp3-320`

## Діагностика

Якщо щось не працює:
1. Перевірте `$HA_TOKEN`
2. Перевірте `$HA_URL`
3. Перевірте доступність плеєра
4. Перевірте мережеве підключення

## Змінні середовища

Встановіть перед використанням:
```bash
export HA_URL="http://100.85.118.55:8123"
export HA_TOKEN="ваш_токен"
```