#!/bin/bash
# Автоматизація: вимкнення світла на кухні після 15 хв без руху

HA_URL="http://100.85.118.55:8123"
HA_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI2OGE4YTY0ZTZkODk0ZTc1YmVjOGVjYThkODQxNTBlYyIsImlhdCI6MTc3MTc3MzI3MCwiZXhwIjoyMDg3MTMzMjcwfQ.SEWUItHBiNit1Bwpm1GjeVkPfHrKVZnMcBizdw4FQ3g"
MOTION_SENSOR="binary_sensor.datchik_rukhu_ploskii_motion"
KITCHEN_LIGHTS=("light.kukhnia" "light.kukhnia_2" "light.kukhnia_3" "light.kukhnia_4" "light.svitlo_kukhnia")

# Функція для перевірки стану датчика
get_motion_state() {
    curl -s -H "Authorization: Bearer $HA_TOKEN" \
        "$HA_URL/api/states/$MOTION_SENSOR" | jq -r '.state'
}

# Функція для перевірки чи увімкнене світло
is_light_on() {
    local light=$1
    local state=$(curl -s -H "Authorization: Bearer $HA_TOKEN" \
        "$HA_URL/api/states/$light" | jq -r '.state')
    [[ "$state" == "on" ]]
}

# Функція для вимкнення світла
turn_off_lights() {
    for light in "${KITCHEN_LIGHTS[@]}"; do
        curl -X POST -H "Authorization: Bearer $HA_TOKEN" \
            -H "Content-Type: application/json" \
            "$HA_URL/api/services/light/turn_off" \
            -d "{\"entity_id\": \"$light\"}" 2>/dev/null
    done
    echo "$(date): Світло на кухні вимкнено (немає руху 15 хв)" >> /tmp/kitchen_motion.log
}

# Перевіряємо чи є рух
motion_state=$(get_motion_state)

if [[ "$motion_state" == "off" ]]; then
    # Немає руху - чекаємо 15 хвилин
    sleep 900
    
    # Перевіряємо знову чи все ще немає руху
    motion_state=$(get_motion_state)
    
    if [[ "$motion_state" == "off" ]]; then
        # Перевіряємо чи світло увімкнене
        for light in "${KITCHEN_LIGHTS[@]}"; do
            if is_light_on "$light"; then
                turn_off_lights
                break
            fi
        done
    fi
fi
