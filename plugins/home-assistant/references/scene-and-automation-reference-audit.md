# Scene and automation reference audit notes

Use this reference when Maxim asks to check scenes, buttons, or automation behavior that should trigger a scene.

## Key lesson from the bedroom romantic scene audit

Home Assistant scene `id`, scene entity_id, and display name may not match exactly. Do not assume a string referenced in an automation exists just because a scene with a similar display name exists.

Observed pattern:

- Real scene entity: `scene.spalnia_romantichne`
- Scene config id: `scene.spalnia_romantychne`
- Display name: `Спальня - Романтичне`
- Automation reference that failed: `scene.spalnia_romantychne`

The automation reference must be checked against `/api/states` entity_ids, not just scene config ids or names.

## Required workflow

1. Fetch all `scene.*` states and list:
   - `entity_id`
   - `attributes.friendly_name`
   - `attributes.id`
   - current state timestamp
2. Fetch scene configs with `/api/config/scene/config/<id>` using both:
   - `attributes.id` when available
   - object_id from `scene.<object_id>` as fallback
3. For any automation that calls a scene, fetch full automation config via `/api/config/automation/config/<automation_id>` and search for `scene.*` references.
4. Validate scene references against actual `/api/states` entity_ids.
5. Separately inspect scene contents, especially brightness/color fields:
   - HA `brightness: 255` means 100%.
   - `brightness: 51` is ~20%.
   - `brightness: 77` is ~30%.
   - `brightness_pct: 100` is also 100% when supported in service calls, but stored scene configs often use `brightness` 0-255.
6. Report exact findings before applying changes. Do not modify HA config unless Maxim explicitly approves.

## Common scene pitfalls

- `romantychne` vs `romantichne` transliteration mismatch.
- A scene can have config id that differs from entity_id.
- Similar scenes can coexist, e.g. `scene.spalnia_romantichne` and `scene.spalnia_romantika`; inspect both before deciding which is intended.
- “Unavailable” light entities may simply be physically switched off in Maxim's HA; do not treat that alone as a broken scene.
- Do not over-literalize user wording like “100% романтичне”: it may mean “fully correct as romantic lighting,” not brightness 100%. Validate the mood/intent as well as numeric fields.

## Bedroom romantic scene expectation

Maxim clarified that “романтичне світло” should be romantic/dim/warm, not bright 100%. Do **not** treat `brightness: 51` (~20%) or `brightness: 77` (~30%) as wrong solely because it is not 100%; that may be correct for a romantic scene.

When Maxim says “романтичне світло 100%”, interpret carefully: he may mean the scene should be **fully correct as romantic lighting**, not `brightness: 255`. Ask or infer from context before proposing a brightness increase.

Still verify automation references: the known issue is `scene.spalnia_romantychne` vs actual entity `scene.spalnia_romantichne`.