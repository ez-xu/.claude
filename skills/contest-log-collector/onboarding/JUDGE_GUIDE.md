# Judge's Guide for Reading `logs/`

<!-- install.sh copies this file to the contestant repo root as JUDGE_GUIDE.md -->

## TL;DR

```bash
# 1. Clone the contestant repo
git clone https://github.com/<contest-org>/<demo-repo>
cd <demo-repo>

# 2. View all sessions for a member (terminal, colored)
python3 tools/render-log.py logs/<github_login>/

# 3. Generate an HTML report for a single session (open in browser)
python3 tools/render-log.py \
  logs/<github_login>/<date>/<tool>__<session_id>.jsonl \
  --format html --out report.html
```

## Repository layout

```
<demo-repo>/
├─ src/                  # contestant work
├─ logs/
│  ├─ <github_login_a>/  # all sessions for member A
│  │  ├─ manifest.json   # member A's index
│  │  └─ <date>/<tool>__<session_id>.jsonl
│  └─ <github_login_b>/  # member B, same structure
└─ tools/
   ├─ render-log.py      # render JSONL to terminal / Markdown / HTML
   └─ validate-log.py    # tamper-detection (seq monotonicity, cross-field consistency)
```

## Validate data integrity (run on suspect teams)

```bash
python3 tools/validate-log.py logs/

# ALL OK     => data is compliant
# ERRORS     => this team may have modified logs
#               (seq gaps, team_id mismatch, etc.)
```

## Batch-generate HTML reports (grading workflow)

```bash
for member in logs/*/; do
  login=$(basename "$member")
  python3 tools/render-log.py "$member" \
    --format html --out reports/$login.html
done
# Browse each HTML in reports/ to grade members one by one.
```

## Data contract (fields judges care about)

Every JSONL event contains:

- `seq`           — monotonically increasing per session. **Gaps or duplicates indicate suspicious data.**
- `role`          — user / assistant / tool / system
- `tool`          — opencode / claude-code / codex / kiro
- `text`          — message content (full, never truncated)
- `thinking`      — AI reasoning (when exposed by the tool)
- `tool_name` / `tool_call_id` / `input` / `output` — full tool-call chain (read / edit / bash, etc.)
- `model`         — model in use
- `tokens_in` / `tokens_out` — token usage
- `redacted_count` — number of auto-redactions (API keys, tokens)

`manifest.json` top-level fields: `team_id` / `github_login` / `sessions[]`. These must be consistent across all files.
