---
description: Export the current AI Coding session from local staging into the demo repo's logs/ directory so it can be committed alongside the contestant's code.
---

The contestant just asked to capture / package / archive this session into the contest repo.

Steps:

1. Run `python3 tools/export-session.py --latest` to copy the most recent
   staged session into `logs/<github_login>/<date>/`.
2. If the contestant says something like "all of today" / "本次开机以来",
   run `python3 tools/export-session.py --today` instead.
3. If the contestant names a specific session id, run
   `python3 tools/export-session.py --session <id>`.
4. After exporting, remind the contestant to:
   `git add logs/ && git commit -s -m "logs: capture session" && git push`

If the export tool reports no sessions, tell the contestant their staging is
empty — possibly because the global hook is not installed or because no AI
session has ended yet.
