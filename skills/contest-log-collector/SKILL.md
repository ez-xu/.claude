---
name: contest-log-collector
description: "Auto-collect AI coding session logs for the openvela AI contest. Listens to session-end events from supported AI tools (OpenCode / Claude Code / Codex / AIoT-IDE), converts conversation traces into JSONL, writes them to logs/<github_login>/<date>/, and git auto-commits + pushes to the contestant repo. Preinstalled by the contest organizers when creating contestant repos; contestants use it transparently with zero configuration. Trigger: contest log collection, AI coding logs, session capture, conversation archiving, AIoT-IDE log."
---

# Contest Log Collector — AI Coding Log Auto-Collector for the openvela AI Contest

This skill provides automatic AI coding log collection for the openvela AI contest. The contest organizers preinstall it into each contestant repo, and contestants work normally in their AI tools (Claude Code / AIoT-IDE / OpenCode / Codex). Logs land at `logs/<github_login>/` and are pushed back to the contestant repo automatically.

## What this skill provides

It implements the contest's submission requirement that AI coding logs be auto-collected by a preinstalled plugin into the repository's `logs/` directory, with no manual organizing or packaging required.

## Directory layout

```
contest-log-collector/
├─ SKILL.md                            # this file
├─ onboarding/
│  ├─ install.sh                       # main entry (called when org creates repos)
│  ├─ verify-setup.sh                  # health check
│  └─ JUDGE_GUIDE.md                   # judge guide (copied to contestant repo root)
├─ adapters/                           # 4-tool hooks/plugins
│  ├─ opencode/collector.js            # OpenCode V1 plugin
│  ├─ claude-code/                     # Claude Code Stop+SessionEnd hook
│  ├─ codex/                           # Codex Stop hook
│  └─ shared/                          # Claude+Codex shared Python core
│     ├─ snapshot_core.py
│     ├─ get_github_login.py           # 5-step priority chain to detect GitHub username
│     └─ get_github_login.js
├─ schema/
│  ├─ event.schema.json                # JSONL single-event contract
│  └─ manifest.schema.json             # index file contract
└─ tools/
   ├─ render-log.py                    # local rendering for judges (terminal/Markdown/HTML)
   └─ validate-log.py                  # tamper-detection validator (seq monotonicity + cross-field consistency)
```

## Organizer usage (preinstall when creating repos)

```bash
# Inside ops/create-repos.py, for each new contestant repo:
git clone --depth 1 -b dev-ai-contest-2026 \
  https://github.com/open-vela/.claude.git /tmp/clt
cd <contestant-repo-path>
bash /tmp/clt/skills/contest-log-collector/onboarding/install.sh \
  --team-id contest2026-042 \
  --github-login <login>
git add -A && git commit -m "init: contest-log-collector preinstalled"
git push
```

`install.sh` automatically:

- Installs `.claude/hooks/contest-snapshot.sh` + `.claude/shared/{snapshot_core.py, get_github_login.py}`
- Installs `.opencode/plugins/contest-collector.js`
- Installs `tools/render-log.py` + `tools/validate-log.py` (for judges)
- Installs `JUDGE_GUIDE.md` (judge guide)
- Writes `.env` (TEAM_ID + GITHUB_LOGIN)
- Updates `.gitignore`
- Emits `.claude/contest-settings.snippet.json` for the organizer to merge into `.claude/settings.json`

## Contestant usage

**Fully transparent.** Once the organizers preinstall it, contestants only need to:

1. Clone their assigned demo repo.
2. Launch their AI tool (Claude Code / AIoT-IDE / OpenCode / Codex).
3. Work with the AI as usual.

Logs are automatically:

- Written to `logs/<github_login>/<date>/<tool>__<sid>.jsonl`
- Auto-committed and pushed every 60 seconds (throttled) to the demo repo
- Retried with `git pull --rebase --autostash` on push failure (concurrent-safe for multi-member teams)

## Judge usage

Each contestant repo root contains `JUDGE_GUIDE.md`. Summary:

```bash
# Terminal preview (color)
python3 tools/render-log.py logs/<github_login>/

# Generate HTML evaluation report
python3 tools/render-log.py logs/<github_login>/ \
  --format html --out report.html

# Tamper-detection check
python3 tools/validate-log.py logs/
# ALL OK = data compliant
# ERRORS = contestant may have modified logs (seq gaps / cross-field inconsistency)
```

## Data contract

Required fields on every JSONL event:

- `schema_version` — currently 1.0
- `session_id` — internal session ID from the AI tool
- `team_id` — official anonymous repo identifier (e.g. `contest2026-042`)
- `github_login` — current member's GitHub username
- `tool` — opencode / claude-code / codex / kiro
- `seq` — per-session monotonic counter (core anti-tamper signal)
- `ts` — ISO 8601 UTC timestamp
- `role` — user / assistant / tool / system

Optional fields: `text` / `thinking` / `tool_name` / `tool_call_id` / `input` / `output` / `model` / `tokens_in` / `tokens_out` / `redacted_count`

## Security features

- **Auto redaction**: default regex rules cover `sk-*` (API key), `ghp_*` (GitHub token), `Bearer *` (auth header)
- **No truncation**: full content preserved — required for cross-team analysis over the multi-month contest
- **Observable failures**: errors are written to `errors/<ts>.err`, never silently swallowed
- **Refuse on missing TEAM_ID**: prevents misattributed data
- **Concurrent push safety**: multi-member teams use `git pull --rebase --autostash` retry

## Tool compatibility

| Tool | Form factor | Status |
|------|-------------|--------|
| Claude Code (primary contest tool) | CLI / AIoT-IDE embedded plugin | Fully supported |
| AIoT-IDE (primary contest tool) | VS Code fork + Claude Code plugin | Fully supported (reuses Claude Code adapter) |
| OpenCode | CLI / TUI / VS Code extension | Fully supported |
| Codex | CLI | Code complete; lacks real-environment validation |
| Kiro | IDE | Not yet implemented |

## License

Apache 2.0, matching the rest of the `open-vela/.claude` skills.
