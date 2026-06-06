#!/bin/bash
# Використання: play_radio.sh <жанр/радіо> [кімната]
# Кімнати: кухня (default) | спальня | обидві
# Приклади:
#   play_radio.sh стрій
#   play_radio.sh стрій спальня
#   play_radio.sh стрій обидві

GENRE="${1:-стрій}"
ROOM="${2:-кухня}"

HA_TOKEN="${HA_TOKEN:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI2OGE4YTY0ZTZkODk0ZTc1YmVjOGVjYThkODQxNTBlYyIsImlhdCI6MTc3MTc3MzI3MCwiZXhwIjoyMDg3MTMzMjcwfQ.SEWUItHBiNit1Bwpm1GjeVkPfHrKVZnMcBizdw4FQ3g}"
HA_URL="${HA_URL:-http://100.85.118.55:8123}"

KITCHEN="media_player.nestmini0954"
BEDROOM="media_player.spalnia_3"

declare -A URLS=(
  # Хіт FM — робочий потік (знайдено 2026-03-16)
  ["хіт"]="https://tavr.tvstitch.com/HitFM"
  ["хит"]="https://tavr.tvstitch.com/HitFM"
  ["hit"]="https://tavr.tvstitch.com/HitFM"
  ["hitfm"]="https://tavr.tvstitch.com/HitFM"
  # Стрий FM — потоки (beta.telelan мертвий, потрібен новий)
  ["стрій"]="https://beta.telelan.com.ua/stryi-fm_mp3"
  ["stryi"]="https://beta.telelan.com.ua/stryi-fm_mp3"
  ["стрий"]="https://beta.telelan.com.ua/stryi-fm_mp3"
  # Промінь (робочий: 2026-03-16)
  ["промінь"]="http://radio.ukr.radio:8000/ur2-mp3"
  ["promin"]="http://radio.ukr.radio:8000/ur2-mp3"
  # Музичні жанри (FluxFM)
  ["jazz"]="https://streams.fluxfm.de/Jazz/mp3-320"
  ["chill"]="https://streams.fluxfm.de/Chill/mp3-320"
  ["pop"]="https://streams.fluxfm.de/Pop/mp3-320"
  ["rock"]="https://streams.fluxfm.de/Rock/mp3-320"
  ["lounge"]="https://streams.fluxfm.de/Lounge/mp3-320"
  ["hiphop"]="https://streams.fluxfm.de/Hiphop/mp3-320"
  ["sleep"]="https://streams.fluxfm.de/Chill/mp3-320"
  ["ambient"]="https://streams.fluxfm.de/Chillout/mp3-320"
  # English learning radio
  ["bbc"]="https://stream.live.vc.bbcmedia.co.uk/bbc_world_service"
  ["voa"]="https://stream.revma.ihrhls.com/zc1965"
  ["learn"]="https://media-ice.musicradio.com/LBCUKMP3"
  ["npr"]="https://npr-ice.streamguys1.com/live.mp3"
)

URL="${URLS[$GENRE]:-${URLS[стрій]}}"

play_on() {
  local PLAYER="$1"
  curl -s -X POST -H "Authorization: Bearer ${HA_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"entity_id\": \"$PLAYER\"}" "${HA_URL}/api/services/media_player/media_stop" > /dev/null
  sleep 2
  curl -s -X POST -H "Authorization: Bearer ${HA_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"entity_id\": \"$PLAYER\", \"media_content_id\": \"$URL\", \"media_content_type\": \"music\"}" \
    "${HA_URL}/api/services/media_player/play_media" > /dev/null
  echo "✅ $GENRE → $PLAYER"
}

case "${ROOM}" in
  спальня|bedroom|spalnia)
    play_on "$BEDROOM"
    ;;
  обидві|both|all|скрізь)
    play_on "$KITCHEN"
    play_on "$BEDROOM"
    ;;
  *)
    play_on "$KITCHEN"
    ;;
esac
