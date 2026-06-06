# Home Assistant automation review/edit notes

Use this for reviewing or adjusting Maxim's HA automations.

## Read automation config

Config endpoint works by automation `id` attribute, not entity_id:

- `GET /api/config/automation/config/<automation_id>`
- Example: `shower_water_saving_warning`
- `GET /api/config/automation/config/automation.<entity>` returns 404.

`/api/states/automation.<entity>` only shows runtime state/attributes such as `last_triggered`, `mode`, `current`; it does not show triggers/actions.

## Verify why an automation did/did not act

Check all of these before concluding:

1. Automation state: `/api/states/automation.<entity>`.
2. Full automation config: `/api/config/automation/config/<id>`.
3. Logbook around the relevant local time for trigger events.
4. History for trigger sensor and action entities around the same window.

For time display to Maxim, convert HA UTC timestamps to `Europe/Prague` and answer with Prague local time unless he explicitly asks for raw timestamps.

## Pattern discovered: long shower automation

Automation: `automation.water_saving_bathroom_shower_warning`, id `shower_water_saving_warning`.

It triggers on `sensor.datchik_vologosti_tuja_humidity` above 75% for a duration. When diagnosing missing light blinking, compare:

- humidity duration above threshold;
- light availability (`light.vanna1_2`, `light.vana2_2`) at trigger time;
- logbook trigger time.

A past case: humidity exceeded 75% briefly in the evening but dropped below threshold before the configured duration elapsed, so the automation did not trigger. Another case: automation triggered but both bathroom lamps were `unavailable`, so HA could not blink them.

## Safe edit workflow

Before editing an automation:

1. Fetch current JSON from `/api/config/automation/config/<id>`.
2. Save a local backup under `~/.hermes/backups/home-assistant/<id>-YYYYMMDD-HHMMSS.json`.
3. Modify JSON.
4. Submit with `POST /api/config/automation/config/<id>`; `PUT` returns 405 for this endpoint.
5. Call `POST /api/services/automation/reload`.
6. Re-fetch the config and verify changed fields.
7. Check `/api/states/automation.<entity>` remains `on` and `current` is sane.

Example successful change: first long-shower warning changed from `00:08:00` to `00:06:30`, with follow-up message text adjusted from 12/15 minutes to 10.5/13.5 minutes while preserving existing delays.