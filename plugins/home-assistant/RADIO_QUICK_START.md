# Quick Start: Відтворення радіо

## Передумови
- Встановлений Home Assistant
- Налаштований media player
- Є токен API

## Команди

### 1. Включити Хіт ФМ
```bash
bash ~/.openclaw/workspace/skills/home-assistant/scripts/play_radio.sh hitfm
```

### 2. Змінити гучність (приклад 50%)
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/volume_set" \
-d '{
    "entity_id": "media_player.spalnia_3", 
    "volume_level": 0.5
}'
```

### 3. Вимкнути музику
```bash
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/turn_off" \
-d '{"entity_id": "media_player.spalnia_3"}'
```

## Troubleshooting
- Перевір токен
- Перевір URL
- Перевір підключення до мережі