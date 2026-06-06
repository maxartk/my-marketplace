# Голосові команди для включення радіо

## Основні команди
- "Включи Hit FM"
- "Включи радіо Hit FM"
- "Постав Hit FM"
- "Музика Hit FM"

## Що робити:
1. Почути команду
2. Виконати пошук stream
3. Включити радіо в Home Assistant
4. Підтвердити "Включаю Hit FM"

## Алгоритм дій
```bash
# Пошук stream
./find_radio_stream.sh "Hit FM"

# Включення першого придатного stream
curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
"$HA_URL/api/services/media_player/play_media" \
-d '{
    "entity_id": "media_player.spalnia_3", 
    "media_content_id": "ЗНАЙДЕНИЙ_URL", 
    "media_content_type": "audio/mpeg"
}'
```

## Варіанти відповіді
- "Включаю Hit FM"
- "Зараз грає Hit FM"
- "Musik увімкнено"