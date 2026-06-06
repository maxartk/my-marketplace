#!/bin/bash

STATION="${1,,}"  # Перетворення на нижній регістр

# Попередньо визначені URL
declare -A RADIO_URLS=(
    ["hit fm"]="https://cast.bitrix24.ua/stream/hit_fm_96_2.mp3"
    ["хіт фм"]="https://cast.bitrix24.ua/stream/hit_fm_96_2.mp3"
    ["радіо hit fm"]="https://cast.bitrix24.ua/stream/hit_fm_96_2.mp3"
    ["радіо хіт фм"]="https://cast.bitrix24.ua/stream/hit_fm_96_2.mp3"
)

# Пошук URL
URL="${RADIO_URLS[$STATION]}"

if [ -z "$URL" ]; then
    echo "❌ Радіостанцію не знайдено"
    exit 1
fi

# Включення радіо
curl -s -X POST -H "Authorization: Bearer ${HA_TOKEN}" -H "Content-Type: application/json" \
    "${HA_URL}/api/services/media_player/play_media" \
    -d "{\"entity_id\": \"media_player.spalnia_3\", \"media_content_id\": \"$URL\", \"media_content_type\": \"audio/mpeg\"}"

# Виведення повідомлення
echo "✅ Включаю $STATION"