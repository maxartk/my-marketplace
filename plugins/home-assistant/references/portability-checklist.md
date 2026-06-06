# Home Assistant Skill Portability Checklist

Use this when copying the `home-assistant` skill to another agent, machine, or Hermes instance.

## Files to copy

```bash
# Copy the entire skill directory
rsync -av ~/.hermes/skills/smart-home/home-assistant/ <destination>/.hermes/skills/smart-home/home-assistant/

# Ensure scripts are executable
chmod +x <destination>/.hermes/skills/smart-home/home-assistant/scripts/*.sh
chmod +x <destination>/.hermes/skills/smart-home/home-assistant/scripts/*.py
```

## Credentials the new agent needs

| Credential | Source on this machine | How to transfer |
|------------|------------------------|-----------------|
| HA token | `~/.config/home-assistant/config.json` | Copy the file, or create a new Long-Lived Access Token in HA and add it to the new agent's `~/.config/home-assistant/config.json` |
| HA URL | `http://100.85.118.55:8123` (from config) | If the new agent is on the same Tailscale/LAN, this URL works. Otherwise expose HA through a new tunnel/proxy. |

## Network requirements

- The new agent must reach `http://100.85.118.55:8123` (or another configured HA URL).
- `100.85.118.55` is a Tailscale IP. If the new agent is not on the same Tailscale network, either:
  - Add the new machine to the same Tailscale tailnet, OR
  - Use a different HA URL (e.g., `http://192.168.1.x:8123` on LAN, OR a Cloudflare Tunnel / reverse proxy).

## Verification steps

```bash
# 1. Check token exists
<destination_agent> cat ~/.config/home-assistant/config.json

# 2. Check network reachability
<destination_agent> curl -s -H "Authorization: Bearer $(jq -r .token ~/.config/home-assistant/config.json)" \
  http://100.85.118.55:8123/api/ | head -1
# Expected: {"message": "API running."}

# 3. Test a skill script
<destination_agent> bash ~/.hermes/skills/smart-home/home-assistant/scripts/ha.sh state sensor.rele_spalnja_power
```

## Things NOT to copy

- Do NOT copy `~/.config/home-assistant/config.json` into the skill directory itself. Keep it outside the skill tree.
- Do NOT embed tokens in SKILL.md or any script file.
- Do NOT push `config.json` to a public GitHub repository.
