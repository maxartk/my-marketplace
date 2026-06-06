---
name: home-assistant
description: Control Maxim's Home Assistant smart home — lights, media players, radio, TTS. Use when user mentions світло, музика, колонка, розетка, кухня, спальня, радіо, включи, вимкни, Хіт FM, Радіо Стрий.
version: 1.1.0
author: maxim-hermes
license: MIT
metadata:
  hermes:
    tags: [Smart-Home, Home-Assistant, Lights, Media, Radio, TTS]
---

# Home Assistant Smart Home Control

## Critical rules

- NEVER ask Maxim for HA token. Credentials are already configured on this machine.
- NEVER tell Maxim to create/send a Long-Lived Access Token.
- NEVER SSH to the HA host. Use HTTP API/scripts.
- HA URL: `http://100.85.118.55:8123`.
- Token is stored in `~/.config/home-assistant/config.json` and `~/.hermes/.env`; do not print it.
- If the user asks to control smart home, act immediately with tools/scripts and verify when practical.
- Use the skill scripts first. If a script is broken, fix the script immediately instead of silently falling back to ad-hoc `curl`.
- Before answering room/entity questions, check `references/entity-map.md`. Do not guess from fuzzy names alone.
- If Maxim supplies an `update.*` entity, treat it as an OTA/update entity and look for sibling `sensor.*` values before calling `update.install`.
- When reporting Home Assistant timestamps (`last_triggered`, `last_changed`, logbook rows, trace times), convert them to local Prague time (`Europe/Prague`) and do not mention UTC unless Maxim explicitly asks for raw technical timestamps.

## Known entities

- Kitchen speaker: `media_player.nestmini0954` — Google Nest Mini on kitchen.
- Bedroom speaker: `media_player.spalnia_3`.
- Bedroom relay: `switch.rele_spalnja`.
- Relay sensors:
  - `sensor.rele_spalnja_power` — power W.
  - `sensor.rele_spalnja_current` — current A.
  - `sensor.rele_spalnja_voltage` — voltage V.
  - `sensor.rele_spalnja_energy` — energy kWh.
  - `sensor.rele_spalnja_device_temperature` — relay temperature °C.
- Bedroom light group: `light.spalnia_svitlo` — group of all 4 lamps.
- Individual bedroom lamps:
  - `light.candle_lamp_w505z2_13`
  - `light.candle_lamp_w505z2_14` — favorite #2
  - `light.0x7cb94c78cdac0000` — спальня_1
  - `light.lampa_spalnia_2` — favorite #4 / спальня_2
- Bathroom entities (see `references/entity-map.md` before diagnosing):
  - `sensor.datchik_vologosti_tuja_humidity` — **bathroom air humidity**. Despite `tuja` in the name, Maxim identified this as the bathroom humidity sensor. Use this for “вологість в ванні”.
  - `sensor.datchik_vologosti_tuja_temperature` — temperature sibling for the same sensor.
  - `sensor.datchik_vologosti_tuja_battery` — battery sibling for the same sensor.
  - `update.datchik_vologosti_tuja` — OTA/update entity for that sensor, NOT the humidity value.
  - `light.svitlo_vanna` — group of both bathroom lamps.
  - `binary_sensor.datchik_zatoplennia_vanna_water_leak` — Zigbee2MQTT flood sensor; wet/dry only, not air humidity.
  - `binary_sensor.datchik_rukhu_vanna_occupancy` — Zigbee2MQTT motion sensor.
  - `sensor.aqara_temp_humidity_sensor_vologist*` — Aqara/HomeKit temp-humidity entities; do **not** use for bathroom humidity unless Maxim explicitly asks for Aqara.

## Scripts to use first

```bash
bash ~/.hermes/skills/smart-home/home-assistant/scripts/play_radio.sh <жанр> [кімната]
bash ~/.hermes/skills/smart-home/home-assistant/scripts/tts_spalnia.sh 'text in English'
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh state <entity_id>
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh states <entity_id>
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh search <text>
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh humidity ванна
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh humidity all
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh on <entity_id>
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh off <entity_id>
bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh call <domain> <service> '<json>'
python3 ~/.hermes/skills/smart-home/home-assistant/scripts/audit_ha.py
```

Use `audit_ha.py` for whole-system read-only audits. It writes `~/.hermes/audits/ha_audit_latest.json` and `~/.hermes/audits/ha_audit_latest.md`, separates service calls from entity references, and flags unavailable/unknown/restored automation problems without changing HA.

Rooms for radio: `кухня` (default), `спальня`, `обидві`.

Radio stations:
- `хіт` / `hit` / `hitfm` → Hit FM. If `https://tavr.tvstitch.com/HitFM` is silent, use `https://online.hitfm.ua/HitFM`.
- `стрій` / `stryi` / `стрий` → Stryi FM / Радіо Стрий.
- `промінь` / `promin` → Promin.
- `jazz` / `chill` / `sleep` → FluxFM streams.
- `bbc` / `voa` / `npr` → English learning radio.

## Radio recovery flow

If user says wrong station is playing or nothing is audible:
1. Stop target media player: `media_player/media_stop`.
2. Unmute and set volume ~0.55.
3. Call `media_player/play_media` directly with stream URL and `media_content_type: music` or `audio/mp3`.
4. Wait a few seconds.
5. Verify `state`, `media_content_id`, `volume_level`, `is_volume_muted`.
6. If HA says `playing` but user hears silence, try alternate URL or suggest Nest/Chromecast restart.

## Room/entity resolution workflow

For questions like “яка вологість/температура/світло в <room>”:
1. Check `references/entity-map.md` first for known aliases/misnamed entities.
2. Prefer exact mapped entity over fuzzy search. For bathroom humidity, use `ha.sh humidity ванна`.
3. If no exact mapping exists, run `ha.sh search <room>` and `ha.sh humidity all` / relevant domain list.
4. Distinguish entity domains:
   - `sensor.*` = numeric/current value.
   - `binary_sensor.*` = on/off (motion, leak, contact), not numeric humidity.
   - `update.*` = OTA firmware/update entity, not the measured value.
   - `button.*`, `select.*`, `number.*` = controls/configuration, not measurements unless explicitly asked.
5. If ambiguous, show the 2–5 candidate entities and ask Maxim which one, instead of confidently diagnosing the wrong device.
6. If a previous answer was wrong and Maxim is frustrated, do **not** continue broad diagnosis. Apologize once, check the entity map, run the exact mapped command, and answer with the corrected value first.

### Direct-answer rule for sensor questions

For simple state questions (“яка вологість”, “яка температура”, “чи є рух”, “чи тече вода”), answer in this order:
1. **Value first**: “У ванні зараз 66.3% вологості.”
2. Then only the minimal context that matters: entity name, battery, unavailable status, or ambiguity.
3. Avoid long explanations, unrelated room comparisons, or hub/integration diagnoses unless the requested sensor is actually unavailable after checking the mapped entity.

## Whole-system audit workflow

When Maxim asks to audit Home Assistant or make the skill reliable:
1. Treat it as a **whole-system audit**, not a narrow entity lookup. Do not get stuck on the last corrected sensor/device; audit the skill files, scripts, HA entities, automations, scenes, and device-health signals.
2. Run `python3 ~/.hermes/skills/smart-home/home-assistant/scripts/audit_ha.py` first.
3. Read `~/.hermes/audits/ha_audit_latest.md` for the human report and `ha_audit_latest.json` for machine-readable details.
4. Separate findings into:
   - local skill/script fixes (safe to patch immediately),
   - HA configuration changes (ask Maxim before applying),
   - intentionally-off/seasonal states,
   - physical/device power states (many `unavailable` lights/devices may simply be switched off or unpowered),
   - true broken references/missing entities.
5. Do not treat `domain.service` strings like `light.turn_on` as missing entities.
6. Do not automatically call every `unavailable` device broken. In Maxim's HA, `unavailable` often means the physical device is switched off/without power. Report it as “currently unavailable/offline” and only call it a fault if an expected always-on hub/bridge/sensor is unavailable or Maxim says it should be online.
7. Heating automations may be intentionally disabled during summer. Treat `opalennia_*`, TRV, and heating schedule automations that are `off` as seasonal/intentional unless Maxim asks to re-enable or it is heating season.
8. For restored/unavailable automations, report them as cleanup candidates; do not delete without Maxim's explicit approval.
9. Report concise priorities first: counts, broken automations, missing references, unavailable clusters, low batteries, and exact files generated.

## Scene and button automation checks

When Maxim asks to check scenes or says a scene should have a specific brightness:
1. Do not rely on scene display names alone. Fetch actual `scene.*` entity_ids from `/api/states` and full scene configs from `/api/config/scene/config/<id>`.
2. Compare automation references against real entity_ids; scene `attributes.id` may differ from entity_id.
3. For brightness, convert stored HA brightness values when needed: `255` = 100%, `51` ≈ 20%, `77` ≈ 30%.
4. Do not assume “романтичне світло 100%” means brightness 100%. Maxim clarified that romantic light should be romantic/dim/warm, not bright; “100%” may mean fully correct as a romantic scene.
5. If a scene is wrong or an automation references a non-existent scene, report exact intended patch and ask before changing HA.
6. See `references/scene-and-automation-reference-audit.md` for the full workflow and the bedroom romantic scene pitfall (`romantychne` vs `romantichne`).

## Direct API pattern

Use `~/.config/home-assistant/config.json` for URL/token. Do not print token.

For automation review/edit workflows, see `references/automation-review-and-edit.md`. Key points: read full automation config via `/api/config/automation/config/<id>` using the automation `id` (not entity_id), inspect logbook/history around the local Prague time, POST updates to that config endpoint, then call `automation.reload` and verify by re-fetching config/state.

For scene/button automation reference audits, see `references/scene-and-automation-reference-audit.md`. Key points: list actual `scene.*` entity_ids from `/api/states`, compare them against `attributes.id` and automation `scene.*` references, and inspect brightness/color semantically before declaring a scene correct. Numeric brightness matters (`255` = 100%), but names like “романтичне” imply dim/warm mood lighting unless Maxim explicitly asks for maximum brightness.

For entity aliases, misleading names, and community/Reddit takeaways about LLM-friendly Home Assistant naming, see `references/entity-map.md`, `references/current-entity-inventory.md`, and `references/community-research.md`.

When reporting HA timestamps to Maxim, convert API UTC timestamps to Prague local time (`Europe/Prague`) and do not mention UTC unless he explicitly asks for raw technical timestamps.

## Bedroom relay interpretation

When Maxim asks whether a Home Assistant automation is written well:
1. Read the automation config from `/api/config/automation/config/<automation_id>` (use the `id` attribute from `/api/states/automation.<name>`, not the entity_id).
2. Check current states of all referenced sensors/lights/switches/media players to verify entity IDs exist and support the requested service data.
3. Check `/api/config` for `time_zone` and report any timestamps in Prague local time.
4. If useful, query logbook around the last trigger to confirm the trigger source, but do not run the automation unless Maxim asks.
5. Review for durable behavior problems, especially: missing scene/snapshot restore before blinking/changing lights; hardcoded Telegram targets; repeated persistent notifications without `notification_id`; `mode` choice; triggers based only on humidity/temperature without occupancy or trend context.
6. Give a concise verdict with concrete fixes, not just a dump of YAML/JSON.

## Bedroom relay interpretation

When Maxim asks “скільки бере струм/живлення” for bedroom relay, report power first, then current/voltage.
- ~8–10 W = active charging.
- ~0.5–3 W = finished / maintenance / idle charger.
- 0 W after relay off = disconnected.

## Skill portability (sharing to another agent)

When Maxim wants to share this skill to another agent or another Hermes instance:

1. **What to copy** — the entire skill directory:
   ```
   ~/.hermes/skills/smart-home/home-assistant/
   ├── SKILL.md
   ├── references/
   └── scripts/
   ```
   Do NOT copy the token files — they are outside the skill tree.

2. **What the receiving agent needs to gain access**:
   - **HA token** — stored in `~/.config/home-assistant/config.json` or `~/.hermes/.env`. The new agent must obtain its own token or Maxim must copy the credential file.
   - **Network reachability** — the new agent must be able to reach `http://100.85.118.55:8123`. This means either:
     - Same Tailscale network (100.x.x.x is Tailscale), OR
     - Same LAN, OR
     - HA exposed through a reverse proxy/tunnel with a new URL.
   - **Script permissions** — `chmod +x` all `.sh` files in `scripts/` after copying.

3. **Do NOT hardcode personal credentials inside the skill** — keep tokens in `~/.config/home-assistant/config.json` or `.env`, never inside SKILL.md or scripts. The skill already follows this rule; verify it stays true after any edits.

4. **Publishing to GitHub** — if Maxim wants to push this skill to a private repo for sharing:
   - Use the `github-auth` skill to verify GitHub access first.
   - The token in `~/.hermes/.env` must be a real GitHub PAT (starts with `ghp_` or `github_pat_`), not a placeholder like `GITHUB...GDbr`.
   - See `references/portability-checklist.md` for a full copy-paste checklist.

## Pitfalls

- Do not ask for HA token — it is already configured.
- Do not claim there is no Home Assistant skill. This file is the skill.
- Do not say only generic built-in `homeassistant` toolset exists; use this Maxim-specific workflow and scripts.
- `homeassistant.local` DNS is unreliable; use `100.85.118.55`.
- Do not turn off `light.spalnia_svitlo` when only some bedroom lamps should change; it controls all 4 lamps.
- For radio, script success can be misleading; if Maxim reports silence/wrong station, use recovery flow.
- Bathroom humidity is `sensor.datchik_vologosti_tuja_humidity`. `update.datchik_vologosti_tuja` is only the OTA/update entity; do not call `update.install` unless an update is actually available and Maxim asked to install it.
- Do not use `sensor.aqara_temp_humidity_sensor_vologist*` for bathroom humidity unless Maxim explicitly says Aqara. That previous mistake produced a false Aqara Hub diagnosis.
- Aqara sensors (temperature/humidity) connect via **HomeKit Controller** through the Aqara Hub M3, NOT Zigbee2MQTT. If all Aqara entities become `unavailable` simultaneously, diagnose the **Aqara Hub M3 / HomeKit Controller** integration first (power, Wi-Fi, repair pairing), not individual sensors.
- Bathroom flood (`binary_sensor.datchik_zatoplennia_vanna_water_leak`) and motion (`binary_sensor.datchik_rukhu_vanna_occupancy`) sensors are on Zigbee2MQTT and will remain online even when the Aqara hub drops.
