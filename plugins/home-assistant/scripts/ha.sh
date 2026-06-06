#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${HA_CONFIG:-$HOME/.config/home-assistant/config.json}"
if [[ -f "$CONFIG_FILE" ]]; then
  HA_URL="${HA_URL:-$(jq -r '.url // empty' "$CONFIG_FILE")}"
  HA_TOKEN="${HA_TOKEN:-$(jq -r '.token // empty' "$CONFIG_FILE")}"
fi
: "${HA_URL:?Set HA_URL or configure $CONFIG_FILE}"
: "${HA_TOKEN:?Set HA_TOKEN or configure $CONFIG_FILE}"

api() {
  curl -sS -H "Authorization: Bearer ${HA_TOKEN}" -H "Content-Type: application/json" "$@"
}

usage() {
  cat <<'USAGE'
Home Assistant CLI
Usage:
  ha.sh info
  ha.sh state <entity_id>                     # print only state
  ha.sh states <entity_id>                    # full state object
  ha.sh attr <entity_id> [attribute]          # full attributes or one attribute
  ha.sh list [domain|all]                     # entity ids
  ha.sh search <text>                         # search entity_id + friendly_name
  ha.sh humidity [room|all]                   # humidity sensors; room can be ванна/bathroom
  ha.sh on <entity_id> [brightness] [kelvin]
  ha.sh off <entity_id>
  ha.sh toggle <entity_id>
  ha.sh volume <0-100> [media_player]
  ha.sh call <domain> <service> [json_data]
  ha.sh history <entity_id> [start_iso]
USAGE
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  state|get)
    entity="${1:?Usage: ha.sh state <entity_id>}"
    api "$HA_URL/api/states/$entity" | jq -r '.state // "unknown"'
    ;;
  states)
    entity="${1:?Usage: ha.sh states <entity_id>}"
    api "$HA_URL/api/states/$entity" | jq
    ;;
  attr|attributes)
    entity="${1:?Usage: ha.sh attr <entity_id> [attribute]}"
    attr="${2:-}"
    if [[ -n "$attr" ]]; then
      api "$HA_URL/api/states/$entity" | jq -r --arg a "$attr" '.attributes[$a] // empty'
    else
      api "$HA_URL/api/states/$entity" | jq '.attributes'
    fi
    ;;
  list)
    filter="${1:-all}"
    if [[ "$filter" == "all" ]]; then
      api "$HA_URL/api/states" | jq -r '.[].entity_id' | sort
    else
      filter="${filter%s}"
      api "$HA_URL/api/states" | jq -r --arg d "$filter" '.[] | select(.entity_id | startswith($d + ".")) | .entity_id' | sort
    fi
    ;;
  search|find)
    q="${1:?Usage: ha.sh search <text>}"
    api "$HA_URL/api/states" | jq -r --arg q "${q,,}" '
      .[]
      | (.attributes.friendly_name // "") as $fn
      | select((.entity_id | ascii_downcase | contains($q)) or ($fn | ascii_downcase | contains($q)))
      | [.entity_id, .state, $fn] | @tsv' | sort
    ;;
  humidity)
    room="${1:-all}"
    # IMPORTANT: Maxim's bathroom humidity sensor is misnamed "tuja" in HA.
    if [[ "$room" =~ ^(ванна|vanna|bath|bathroom)$ ]]; then
      api "$HA_URL/api/states/sensor.datchik_vologosti_tuja_humidity" | jq -r '[.entity_id, .state + (.attributes.unit_of_measurement // ""), (.attributes.friendly_name // "")] | @tsv'
    else
      api "$HA_URL/api/states" | jq -r '
        .[] | select(.attributes.device_class == "humidity")
        | [.entity_id, (.state + (.attributes.unit_of_measurement // "")), (.attributes.friendly_name // "")] | @tsv' | sort
    fi
    ;;
  on|turn_on)
    entity="${1:?Usage: ha.sh on <entity_id> [brightness] [kelvin]}"
    domain="${entity%%.*}"
    brightness="${2:-}"
    kelvin="${3:-}"
    if [[ -n "$brightness" && -n "$kelvin" ]]; then
      api -X POST "$HA_URL/api/services/$domain/turn_on" -d "{\"entity_id\": \"$entity\", \"brightness\": $brightness, \"color_temp_kelvin\": $kelvin}" >/dev/null
    elif [[ -n "$brightness" ]]; then
      api -X POST "$HA_URL/api/services/$domain/turn_on" -d "{\"entity_id\": \"$entity\", \"brightness\": $brightness}" >/dev/null
    else
      api -X POST "$HA_URL/api/services/$domain/turn_on" -d "{\"entity_id\": \"$entity\"}" >/dev/null
    fi
    echo "✓ $entity turned on"
    ;;
  off|turn_off)
    entity="${1:?Usage: ha.sh off <entity_id>}"
    domain="${entity%%.*}"
    api -X POST "$HA_URL/api/services/$domain/turn_off" -d "{\"entity_id\": \"$entity\"}" >/dev/null
    echo "✓ $entity turned off"
    ;;
  toggle)
    entity="${1:?Usage: ha.sh toggle <entity_id>}"
    domain="${entity%%.*}"
    api -X POST "$HA_URL/api/services/$domain/toggle" -d "{\"entity_id\": \"$entity\"}" >/dev/null
    echo "✓ $entity toggled"
    ;;
  volume)
    vol_raw="${1:-50}"
    vol_entity="${2:-media_player.spalnia_3}"
    vol_level=$(awk "BEGIN {printf \"%.2f\", $vol_raw/100}")
    api -X POST "$HA_URL/api/services/media_player/volume_set" -d "{\"entity_id\": \"$vol_entity\", \"volume_level\": $vol_level}" >/dev/null
    echo "🔊 Volume set to ${vol_raw}% on $vol_entity"
    ;;
  call)
    domain="${1:?Usage: ha.sh call <domain> <service> [json_data]}"
    service="${2:?Usage: ha.sh call <domain> <service> [json_data]}"
    data="${3:-{}}"
    if [[ -z "$data" || "$data" == "{}" ]]; then
      api -X POST "$HA_URL/api/services/$domain/$service"
    else
      printf '%s' "$data" | api -X POST "$HA_URL/api/services/$domain/$service" -d @-
    fi
    ;;
  history)
    entity="${1:?Usage: ha.sh history <entity_id> [start_iso]}"
    start="${2:-$(date -Iseconds -d '24 hours ago')}"
    api "$HA_URL/api/history/period/$start?filter_entity_id=$entity" | jq
    ;;
  info)
    api "$HA_URL/api/" | jq
    ;;
  help|*)
    usage
    ;;
esac
