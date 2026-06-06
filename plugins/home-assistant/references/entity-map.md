# Maxim Home Assistant Entity Map

This file is the source of truth for ambiguous or misnamed entities in Maxim's Home Assistant. Use it before guessing from friendly names.

## Golden rules

1. If Maxim gives an `update.*` entity, it is usually an OTA/update entity, not the sensor value itself. Look for sibling `sensor.*` entities with the same base name.
2. Do not infer room solely from the friendly name. Some entities are misnamed or reused.
3. For user-facing answers, report values, not entity archaeology. Only mention diagnostics if the requested entity is unavailable or ambiguous.
4. For Home Assistant timestamps, convert to Europe/Prague before reporting.

## Bathroom / ванна

### Bathroom humidity sensor — IMPORTANT

- User may refer to: `update.datchik_vologosti_tuja`
- Correct current humidity entity: `sensor.datchik_vologosti_tuja_humidity`
- Temperature sibling: `sensor.datchik_vologosti_tuja_temperature`
- Battery sibling: `sensor.datchik_vologosti_tuja_battery`
- Voltage sibling: `sensor.datchik_vologosti_tuja_voltage`
- OTA/update sibling: `update.datchik_vologosti_tuja`

Although the name says `tuja`, Maxim has identified this as the bathroom humidity sensor. When he asks “яка вологість в ванні”, use:

```bash
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh humidity ванна
# or
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh state sensor.datchik_vologosti_tuja_humidity
```

Never answer bathroom humidity from `sensor.aqara_temp_humidity_sensor_vologist*` unless Maxim explicitly asks for Aqara. Those Aqara sensors are unavailable HomeKit/Aqara Hub entities and caused a wrong diagnosis.

### Other bathroom entities

- `light.svitlo_vanna` — bathroom light group.
- `light.vanna1_2` — bathroom lamp 1.
- `binary_sensor.datchik_rukhu_vanna_occupancy` — bathroom motion sensor.
- `sensor.datchik_rukhu_vanna_battery` — bathroom motion battery.
- `sensor.datchik_rukhu_vanna_illuminance` — bathroom motion illuminance.
- `binary_sensor.datchik_zatoplennia_vanna_water_leak` — flood/leak sensor; HA friendly name contains “Вологість” because device_class moisture, but it is binary wet/dry, not air humidity.
- `sensor.datchik_zatoplennia_vanna_device_temperature` — flood sensor device temperature, not room humidity.

## Aqara Temp/Humidity Sensor entities

- `sensor.aqara_temp_humidity_sensor_vologist`
- `sensor.aqara_temp_humidity_sensor_vologist_2`
- `sensor.aqara_temp_humidity_sensor_vologist_3`

These are HomeKit Controller/Aqara Hub M3 entities and may be unavailable. They are not the bathroom humidity answer unless Maxim explicitly says Aqara. If all Aqara entities are unavailable, diagnose Aqara Hub M3/HomeKit Controller, but do not confuse that with the bathroom Zigbee2MQTT humidity sensor.

## Query recipes

### One exact entity

```bash
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh states sensor.datchik_vologosti_tuja_humidity
```

### Search by text

```bash
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh search vologosti
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh search vanna
```

### All humidity entities

```bash
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh humidity all
```

## Failure pattern from 2026-06-05

Wrong workflow:
1. User asked “Яка зараз вологість в ванні”.
2. Agent searched names containing vanna/bath/humid.
3. Agent picked unavailable Aqara Temp/Humidity entities and diagnosed Aqara Hub.
4. User corrected: the relevant entity is `update.datchik_vologosti_tuja`; the actual sensor is the sibling `sensor.datchik_vologosti_tuja_humidity`.

Correct workflow:
1. Check this entity map first.
2. Use `ha.sh humidity ванна`.
3. Answer directly: “У ванні зараз X%”.
4. If needed, add temperature/battery from the sibling entities.
