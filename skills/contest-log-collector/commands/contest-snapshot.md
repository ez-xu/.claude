---
description: Export the current AI Coding session from local staging into the demo repo's logs/ directory so it can be committed alongside the contestant's code.
---

The contestant just asked to capture / package / archive this session into the contest repo.

Privacy-first flow: always preview first, then ask for confirmation, then actually export.

Use the short command `contest-snapshot` (installed to `~/.local/bin/` by install.sh). If it is not found, fall back to the full python invocation `python3 ../.claude/skills/contest-log-collector/tools/export-session.py`.

Steps:

1. Run `contest-snapshot --latest` (no `--confirm`). This shows the
   contestant exactly which session(s) would be copied, but writes
   nothing. Display the preview output to the contestant.
2. Ask the contestant: "this is the session I would copy into the contest
   repo, OK to confirm?" Wait for an affirmative reply.
3. On confirmation, run `contest-snapshot --latest --confirm` to actually
   write the session into `logs/<github_login>/<date>/`.
4. If the contestant says they want a different session, refine the
   selection: `--today`, `--session <id>`, `--since <date>`, or `--all`.
   Always preview first, then add `--confirm`.
5. After exporting, remind the contestant to:
   `git add logs/ && git commit -s -m "logs: capture session" && git push`

If the export tool reports no sessions, tell the contestant their staging is
empty — possibly because the global hook is not installed or because no AI
session has ended yet.

If `contest-snapshot` is not found in PATH, use the full fallback:

```
python3 ../.claude/skills/contest-log-collector/tools/export-session.py --latest
python3 ../.claude/skills/contest-log-collector/tools/export-session.py --latest --confirm
```
