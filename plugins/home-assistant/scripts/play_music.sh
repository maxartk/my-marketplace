#!/bin/bash
set -e
HA_URL="http://100.85.118.55:8123"
HA_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI2OGE4YTY0ZTZkODk0ZTc1YmVjOGVjYThkODQxNTBlYyIsImlhdCI6MTc3MTc3MzI3MCwiZXhwIjoyMDg3MTMzMjcwfQ.SEWUItHBiNit1Bwpm1GjeVkPfHrKVZnMcBizdw4FQ3g"
PLAYER="media_player.nestmini0954"

case "${1:-romantic}" in
  стрій|стрий|stryi) STREAM="http://online.fm.stryi.com:8000/stryi-fm_mp3";;  # Радіо Стрий FM
  romantic) STREAM="https://ice1.somafm.com/romantic-128-mp3";;  # SomaFM Romantic (USA)
  jazz) STREAM="https://live.jazzradio.com/jazzradio_128mp3";;     # JazzRadio (USA)
  pop) STREAM="https://stream.radioparadise.com/mp3-128";;         # Radio Paradise (USA)
  chill) STREAM="https://ice1.somafm.com/chill-128-mp3";;          # SomaFM Chill (USA)
  lounge) STREAM="https://ice1.somafm.com/lounge-128-mp3";;        # SomaFM Lounge (USA)
  rap) STREAM="https://hiphop.stream.laut.fm/hiphop";;                # Laut.fm HipHop
  hiphop|hip-hop|hip_hop|2000s) STREAM="https://hiphop.stream.laut.fm/hiphop";;  # Laut.fm HipHop (Germany)
  rnb|rb) STREAM="http://listen.181fm.com/181-oldschool_128k.mp3";; # 181.FM Old School HipHop/RnB
  *) STREAM="https://ice1.somafm.com/romantic-128-mp3";;
esac

# Ensure player is on
curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  --max-time 5 "$HA_URL/api/services/media_player/turn_on" \
  -d "{\"entity_id\": \"$PLAYER\"}" > /dev/null 2>&1

sleep 2

curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  --max-time 5 "$HA_URL/api/services/media_player/media_stop" \
  -d "{\"entity_id\": \"$PLAYER\"}" > /dev/null 2>&1

sleep 1

curl -s -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  --max-time 5 "$HA_URL/api/services/media_player/play_media" \
  -d "{\"entity_id\": \"$PLAYER\", \"media_content_id\": \"$STREAM\", \"media_content_type\": \"music\"}" > /dev/null &

echo "✓ Музика запущена"
