#!/bin/bash
# TTS на колонку в спальні
# Використання: bash tts_spalnia.sh "Текст для озвучення"

HA_URL="http://100.85.118.55:8123"
HA_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI2OGE4YTY0ZTZkODk0ZTc1YmVjOGVjYThkODQxNTBlYyIsImlhdCI6MTc3MTc3MzI3MCwiZXhwIjoyMDg3MTMzMjcwfQ.SEWUItHBiNit1Bwpm1GjeVkPfHrKVZnMcBizdw4FQ3g"
SPEAKER="media_player.spalnia_3"
TTS_ENGINE="tts.google_translate_en_com"

MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
  echo "Помилка: вкажи текст для озвучення"
  exit 1
fi

curl -s -X POST \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  "$HA_URL/api/services/tts/speak" \
  -d "{\"entity_id\": \"$TTS_ENGINE\", \"media_player_entity_id\": \"$SPEAKER\", \"message\": \"$MESSAGE\"}" > /dev/null

echo "✅ Озвучено на колонці в спальні"
