#!/usr/bin/env bash
set -euo pipefail

# Set a simple one-shot radio alarm on a Home Assistant media_player.
# Usage:
#   set_alarm.sh now [media_player]
#   set_alarm.sh HH:MM [media_player]
#
# This is a foreground helper: for durable reminders/alarms prefer Hermes cronjob.

CONFIG_FILE="${HA_CONFIG:-$HOME/.config/home-assistant/config.json}"
if [[ -f "$CONFIG_FILE" ]]; then
  HA_URL="${HA_URL:-$(jq -r '.url // empty' "$CONFIG_FILE")}"
  HA_TOKEN="${HA_TOKEN:-$(jq -r '.token // empty' "$CONFIG_FILE")}"
fi
: "${HA_URL:?Set HA_URL or configure $CONFIG_FILE}"
: "${HA_TOKEN:?Set HA_TOKEN or configure $CONFIG_FILE}"

WHEN="${1:-}"
SPEAKER="${2:-media_player.spalnia_3}"
STREAM_URL="${ALARM_STREAM_URL:-https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one}"

if [[ -z "$WHEN" ]]; then
  echo "Usage: $0 now|HH:MM [media_player]" >&2
  exit 1
fi

sleep_until_time() {
  local target="$1"
  if [[ ! "$target" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
    echo "Invalid time '$target'. Use now or HH:MM" >&2
    exit 1
  fi
  local now_ts target_ts
  now_ts=$(date +%s)
  target_ts=$(date -d "today $target" +%s)
  if (( target_ts <= now_ts )); then
    target_ts=$(date -d "tomorrow $target" +%s)
  fi
  local wait=$((target_ts - now_ts))
  echo "⏰ Alarm scheduled for $target on $SPEAKER; waiting ${wait}s..."
  sleep "$wait"
}

if [[ "$WHEN" != "now" ]]; then
  sleep_until_time "$WHEN"
fi

curl -sS -X POST \
  -H "Authorization: Bearer ${HA_TOKEN}" \
  -H "Content-Type: application/json" \
  "$HA_URL/api/services/media_player/play_media" \
  -d "{\"entity_id\": \"$SPEAKER\", \"media_content_id\": \"$STREAM_URL\", \"media_content_type\": \"music\"}" >/dev/null

echo "✅ Alarm/radio started on $SPEAKER"
