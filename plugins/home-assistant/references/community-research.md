# Community Research Notes: Home Assistant + LLM / Voice / Entity Mapping

Research target: make Maxim's Hermes `home-assistant` skill more reliable and less prone to wrong entity guesses.

## Sources checked

- Reddit search result: `r/homeassistant` — “Which local LLMs give best results for voice assistant”
  - URL: https://www.reddit.com/r/homeassistant/comments/1qg80y1/which_local_llms_give_best_results_for_voice
  - Search snippet takeaway: users report better LLM behavior when adding aliases; one comment says adding the entity id as an alias and exposing scripts/entities helped.
- Reddit search result: `r/homeassistant` — “LLM Voice Assistant History of Entities…”
  - URL: https://www.reddit.com/r/homeassistant/comments/1odzowz/llm_voice_assistant_history_of_entities_is_there
  - Search snippet takeaway: users describe exposing/adding entity descriptions in alias fields to help LLM understand sensors.
- Reddit search result: `r/homeassistant` — “What are best practices for exposing Home Assistant entities…”
  - URL: https://www.reddit.com/r/homeassistant/comments/ccuphn/what_are_best_practices_for_exposing_home
  - Search snippet takeaway: be careful with entity names; avoid exposing/control ambiguity.
- Home Assistant Community search result: “Issues getting a local LLM to tell me temperatures, humidity, etc”
  - URL: https://community.home-assistant.io/t/issues-getting-a-local-llm-to-tell-me-temperatures-humidity-etc/801976/14
  - Search snippet takeaway: labels/tags and indexed entity library improve AI access to sensor values.
- Home Assistant Community search result: “Creating a Private, Agentic AI using Voice Assistant tools”
  - URL: https://community.home-assistant.io/t/fridays-party-creating-a-private-agentic-ai-using-voice-assistant-tools/855862
  - Search snippet takeaway: expose scripts/tools carefully; target by labels where possible.

Direct Reddit `.json` extraction from this server returned HTTP 403 (`Blocked`), consistent with the local `reddit-automation` skill. Web search snippets were used for high-level takeaways.

## Practical takeaways for this skill

1. **Aliases/entity map are mandatory.** LLMs cannot reliably infer rooms from HA names when names are historical/misleading (`tuja` actually bathroom humidity). Maintain `references/entity-map.md` as source of truth.
2. **Use scripts as tools.** Expose a simple `ha.sh humidity ванна` command instead of making the model invent curl/jq filters every time.
3. **Do not overload entity domains.** `update.*` must not be treated as sensor values. `binary_sensor.*` moisture is wet/dry, not air humidity.
4. **Ambiguity policy:** if no exact mapping exists, show candidates and ask instead of diagnosing a random unavailable entity.
5. **Descriptions beat names.** For future HA cleanup, add explicit aliases/labels/descriptions in HA where possible: `ванна humidity`, `bathroom air humidity`, `датчик вологості ванна` for the tuja sensor.
