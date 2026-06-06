#!/usr/bin/env python3
"""Read-only Home Assistant audit helper for Maxim's Hermes home-assistant skill.

Outputs JSON and Markdown reports under ~/.hermes/audits/.
Does not modify Home Assistant.
"""
from __future__ import annotations

import datetime as dt
import json
import os
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from zoneinfo import ZoneInfo

CONFIG_FILE = Path(os.environ.get("HA_CONFIG", str(Path.home() / ".config/home-assistant/config.json")))
OUT_DIR = Path(os.environ.get("HA_AUDIT_DIR", str(Path.home() / ".hermes/audits")))
PRAGUE = ZoneInfo("Europe/Prague")


def load_config() -> tuple[str, str]:
    cfg = json.loads(CONFIG_FILE.read_text())
    url = os.environ.get("HA_URL") or cfg.get("url") or "http://100.85.118.55:8123"
    token = os.environ.get("HA_TOKEN") or cfg.get("token")
    if not token:
        raise SystemExit(f"Missing HA token in {CONFIG_FILE}")
    return url.rstrip("/"), token


def api(url: str, token: str, path: str, method: str = "GET", data=None):
    cmd = [
        "curl",
        "-sS",
        "-H",
        f"Authorization: Bearer {token}",
        "-H",
        "Content-Type: application/json",
    ]
    if method != "GET":
        cmd += ["-X", method]
    if data is not None:
        cmd += ["-d", json.dumps(data)]
    cmd.append(url + path)
    p = subprocess.run(cmd, text=True, capture_output=True, timeout=60)
    if p.returncode != 0:
        return {"__error__": p.stderr, "__code__": p.returncode}
    try:
        return json.loads(p.stdout)
    except Exception:
        return {"__raw__": p.stdout[:2000]}


def prague_time(value):
    if not value:
        return "ніколи/немає"
    try:
        parsed = dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return parsed.astimezone(PRAGUE).strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return str(value)


def walk_strings(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from walk_strings(v, f"{path}.{k}" if path else str(k))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from walk_strings(v, f"{path}[{i}]")
    elif isinstance(obj, str):
        for match in re.findall(r"\b[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z0-9_]+\b", obj):
            yield path, match


def is_real_battery_sensor(entity):
    attrs = entity.get("attributes", {})
    eid = entity["entity_id"]
    if not eid.startswith("sensor."):
        return False
    return attrs.get("device_class") == "battery" or eid.endswith("_battery") or "battery_level" in eid or "batareia" in eid


def main():
    url, token = load_config()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    config = api(url, token, "/api/config")
    states = api(url, token, "/api/states")
    services = api(url, token, "/api/services")
    if not isinstance(states, list):
        raise SystemExit(f"Failed to fetch states: {states}")

    entity_ids = {s["entity_id"] for s in states}
    state_by = {s["entity_id"]: s for s in states}
    service_names = set()
    if isinstance(services, list):
        for domain in services:
            d = domain.get("domain")
            for service in domain.get("services", {}).keys():
                service_names.add(f"{d}.{service}")

    by_domain = Counter(s["entity_id"].split(".", 1)[0] for s in states)
    bad = [s for s in states if s.get("state") in ("unavailable", "unknown")]
    updates = [s for s in states if s["entity_id"].startswith("update.")]
    battery = []
    for s in states:
        if is_real_battery_sensor(s):
            try:
                battery.append((float(s["state"]), s["entity_id"], s.get("attributes", {}).get("friendly_name")))
            except Exception:
                pass
    battery.sort()

    automations = [s for s in states if s["entity_id"].startswith("automation.")]
    automation_configs = []
    for s in automations:
        aid = s.get("attributes", {}).get("id")
        conf = api(url, token, f"/api/config/automation/config/{aid}") if aid else {"__error__": "missing id"}
        automation_configs.append({"entity_id": s["entity_id"], "id": aid, "state_obj": s, "config": conf})

    likely_domains = {
        "light", "switch", "sensor", "binary_sensor", "climate", "media_player", "scene", "automation",
        "input_boolean", "input_number", "input_select", "notify", "vacuum", "button", "number", "select",
        "cover", "script", "remote", "fan", "lock", "weather", "device_tracker",
    }
    seasonal_heating_off = []
    automation_issues = []
    for ac in automation_configs:
        refs = defaultdict(set)
        for path, ref in walk_strings(ac["config"]):
            if ref in service_names or ref.startswith(("mdi.", "http.")):
                continue
            refs[ref].add(path)
        missing, unavailable, unknown = [], [], []
        for ref, paths in refs.items():
            domain = ref.split(".", 1)[0]
            if ref not in entity_ids:
                if domain in likely_domains:
                    missing.append({"entity_id": ref, "paths": sorted(paths)[:8]})
            else:
                state = state_by[ref]["state"]
                item = {"entity_id": ref, "friendly": state_by[ref].get("attributes", {}).get("friendly_name"), "paths": sorted(paths)[:8]}
                if state == "unavailable":
                    unavailable.append(item)
                elif state == "unknown":
                    unknown.append(item)
        restored = ac["state_obj"].get("attributes", {}).get("restored")
        if missing or unavailable or unknown or restored or ac["state_obj"].get("state") in ("unavailable", "unknown"):
            automation_issues.append({
                "automation": ac["entity_id"],
                "name": ac["state_obj"].get("attributes", {}).get("friendly_name"),
                "state": ac["state_obj"].get("state"),
                "id": ac["id"],
                "last_triggered": ac["state_obj"].get("attributes", {}).get("last_triggered"),
                "restored": restored,
                "missing": missing,
                "unavailable": unavailable,
                "unknown": unknown,
            })

    clusters = Counter()
    for s in bad:
        eid = s["entity_id"]
        fn = (s.get("attributes", {}).get("friendly_name") or "").lower()
        if "aqara" in eid or "aqara" in fn:
            clusters["Aqara/HomeKit unavailable"] += 1
        elif "koridor" in eid or "коридор" in fn:
            clusters["Koridor unavailable/unknown"] += 1
        elif "spal" in eid or "спаль" in fn:
            clusters["Spalnia unavailable/unknown"] += 1
        elif "kukhn" in eid or "кух" in fn:
            clusters["Kitchen unavailable/unknown"] += 1
        elif eid.startswith("automation.") and s.get("attributes", {}).get("restored"):
            clusters["Restored/unavailable automations"] += 1
        else:
            clusters["Other"] += 1

    report = {
        "generated_at": dt.datetime.now(PRAGUE).isoformat(),
        "ha_config": config,
        "counts": {
            "states": len(states),
            "domains": dict(by_domain),
            "unavailable_unknown": len(bad),
            "updates": len(updates),
            "automations": len(automations),
            "automation_issues": len(automation_issues),
        },
        "bad_clusters": clusters.most_common(),
        "unavailable_unknown": [
            {"entity_id": s["entity_id"], "state": s["state"], "friendly_name": s.get("attributes", {}).get("friendly_name")}
            for s in bad
        ],
        "updates": [
            {"entity_id": s["entity_id"], "state": s["state"], "friendly_name": s.get("attributes", {}).get("friendly_name"),
             "installed": s.get("attributes", {}).get("installed_version"), "latest": s.get("attributes", {}).get("latest_version")}
            for s in updates
        ],
        "battery": [{"percent": v, "entity_id": eid, "friendly_name": fn} for v, eid, fn in battery],
        "off_automations": [
            {"entity_id": s["entity_id"], "friendly_name": s.get("attributes", {}).get("friendly_name"), "last_triggered": s.get("attributes", {}).get("last_triggered")}
            for s in automations
            if s.get("state") == "off"
            and not any(token in (s["entity_id"] + " " + (s.get("attributes", {}).get("friendly_name") or "")).lower() for token in ["opalennia", "опал", "termogolov", "термоголов", "trv"])
        ],
        "seasonal_heating_off": [
            {"entity_id": s["entity_id"], "friendly_name": s.get("attributes", {}).get("friendly_name"), "last_triggered": s.get("attributes", {}).get("last_triggered"), "note": "Usually intentional in summer"}
            for s in automations
            if s.get("state") == "off"
            and any(token in (s["entity_id"] + " " + (s.get("attributes", {}).get("friendly_name") or "")).lower() for token in ["opalennia", "опал", "termogolov", "термоголов", "trv"])
        ],
        "automation_issues": automation_issues,
    }

    stamp = dt.datetime.now(PRAGUE).strftime("%Y%m%d_%H%M%S")
    json_path = OUT_DIR / f"ha_audit_{stamp}.json"
    latest_json = OUT_DIR / "ha_audit_latest.json"
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2))
    latest_json.write_text(json.dumps(report, ensure_ascii=False, indent=2))

    md = []
    md.append("# Home Assistant Audit")
    md.append("")
    md.append(f"Generated: {dt.datetime.now(PRAGUE).strftime('%Y-%m-%d %H:%M:%S')} Europe/Prague")
    md.append("")
    md.append("## Summary")
    for k, v in report["counts"].items():
        if k != "domains":
            md.append(f"- {k}: {v}")
    md.append("")
    md.append("## Clusters")
    for name, count in report["bad_clusters"]:
        md.append(f"- {name}: {count}")
    md.append("")
    md.append("## Lowest batteries")
    for item in report["battery"][:15]:
        md.append(f"- {item['entity_id']}: {item['percent']}% — {item['friendly_name']}")
    md.append("")
    md.append("## Off automations (non-heating; review intent)")
    for item in report["off_automations"]:
        md.append(f"- {item['entity_id']} — {item['friendly_name']}; last: {prague_time(item['last_triggered'])}")
    md.append("")
    md.append("## Seasonal heating automations currently off")
    md.append("These are usually intentional during summer in Maxim's HA unless he says heating should be active.")
    for item in report["seasonal_heating_off"]:
        md.append(f"- {item['entity_id']} — {item['friendly_name']}; last: {prague_time(item['last_triggered'])}")
    md.append("")
    md.append("## Automation issues / references to check")
    for issue in automation_issues:
        md.append(f"### {issue['automation']} — {issue.get('name')}")
        md.append(f"- State: {issue['state']}; last: {prague_time(issue.get('last_triggered'))}; restored: {issue.get('restored')}")
        if issue["missing"]:
            md.append("- Missing references:")
            for m in issue["missing"]:
                md.append(f"  - `{m['entity_id']}` at {', '.join(m['paths'])}")
        if issue["unavailable"]:
            md.append("- Unavailable references:")
            for u in issue["unavailable"][:12]:
                md.append(f"  - `{u['entity_id']}` — {u.get('friendly')}")
            if len(issue["unavailable"]) > 12:
                md.append(f"  - ... +{len(issue['unavailable']) - 12} more")
        if issue["unknown"]:
            md.append("- Unknown references:")
            for u in issue["unknown"]:
                md.append(f"  - `{u['entity_id']}` — {u.get('friendly')}")
        md.append("")
    md_path = OUT_DIR / f"ha_audit_{stamp}.md"
    latest_md = OUT_DIR / "ha_audit_latest.md"
    md_text = "\n".join(md)
    md_path.write_text(md_text)
    latest_md.write_text(md_text)

    print(json.dumps({"json": str(json_path), "markdown": str(md_path), "counts": report["counts"], "clusters": report["bad_clusters"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
