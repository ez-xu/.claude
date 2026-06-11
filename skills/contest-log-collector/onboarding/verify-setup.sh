#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# openvela AI Contest - collector install verification script
# Run at the contestant demo repo root to verify everything install.sh set up is in place and healthy.

set -u

if ! command -v git >/dev/null; then
  echo "❌ git not found"; exit 1
fi
if ! command -v python3 >/dev/null; then
  echo "❌ python3 not found"; exit 1
fi
if ! command -v node >/dev/null; then
  echo "⚠️  node not found (only needed if using OpenCode)"
fi

if [ ! -d .git ]; then
  echo "❌ not in a git repository"; exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

PASS=0
FAIL=0

check_file() {
  local path="$1"
  local desc="$2"
  if [ -f "$path" ]; then
    echo "✅ $desc: $path"
    PASS=$((PASS+1))
  else
    echo "❌ $desc MISSING: $path"
    FAIL=$((FAIL+1))
  fi
}

check_executable() {
  local path="$1"
  local desc="$2"
  if [ -f "$path" ] && [ -x "$path" ]; then
    echo "✅ $desc: $path (executable)"
    PASS=$((PASS+1))
  elif [ -f "$path" ]; then
    echo "⚠️  $desc: $path (not executable, run: chmod +x $path)"
    FAIL=$((FAIL+1))
  else
    echo "❌ $desc MISSING: $path"
    FAIL=$((FAIL+1))
  fi
}

echo "─── files ───"
check_file ".opencode/plugins/contest-collector.js" "OpenCode plugin"
check_executable ".claude/hooks/contest-snapshot.sh" "Claude Code hook"
check_file ".claude/shared/snapshot_core.py" "Shared snapshot core"
check_file ".claude/shared/get_github_login.py" "GitHub login detector"
check_executable "tools/render-log.py" "Render tool (for judges)"

echo ""
echo "─── settings.json ───"
if [ -f .claude/settings.json ]; then
  if grep -q "contest-snapshot" .claude/settings.json; then
    echo "✅ .claude/settings.json registers contest-snapshot"
    PASS=$((PASS+1))
  else
    echo "⚠️  .claude/settings.json EXISTS but does NOT reference contest-snapshot"
    echo "    You need to merge .claude/contest-settings.snippet.json into it"
    FAIL=$((FAIL+1))
  fi
else
  if [ -f .claude/contest-settings.snippet.json ]; then
    echo "⚠️  .claude/settings.json missing. Snippet is at:"
    echo "    .claude/contest-settings.snippet.json (rename or merge it)"
    FAIL=$((FAIL+1))
  else
    echo "❌ no .claude/settings.json AND no snippet — re-run install.sh"
    FAIL=$((FAIL+1))
  fi
fi

echo ""
echo "─── env: TEAM_ID ───"
if [ -n "${TEAM_ID:-}" ]; then
  if echo "$TEAM_ID" | grep -qE '^team-[a-zA-Z0-9_-]+$'; then
    echo "✅ TEAM_ID env: $TEAM_ID"
    PASS=$((PASS+1))
  else
    echo "❌ TEAM_ID '$TEAM_ID' does not match team-<alnum> pattern"
    FAIL=$((FAIL+1))
  fi
elif [ -f .env ] && grep -qE '^TEAM_ID=team-' .env; then
  ENV_TEAM=$(grep -E '^TEAM_ID=' .env | head -1 | cut -d= -f2-)
  echo "⚠️  TEAM_ID not in env, but .env has: $ENV_TEAM"
  echo "    Source .env before launching AI: set -a && source .env && set +a"
  FAIL=$((FAIL+1))
else
  echo "❌ TEAM_ID not set anywhere"
  FAIL=$((FAIL+1))
fi

echo ""
echo "─── github_login detection ───"
DETECTOR=".claude/shared/get_github_login.py"
if [ -f "$DETECTOR" ]; then
  DETECT_OUT=$(python3 "$DETECTOR" "$REPO_ROOT" 2>/dev/null) || DETECT_OUT=""
  LOGIN_VAL=$(echo "$DETECT_OUT" | awk -F'\t' '{print $1}')
  LOGIN_SRC=$(echo "$DETECT_OUT" | awk -F'\t' '{print $2}')
  if [ -n "$LOGIN_VAL" ]; then
    echo "✅ github_login: $LOGIN_VAL  (source: $LOGIN_SRC)"
    PASS=$((PASS+1))
  else
    echo "❌ cannot detect github_login. Run 'gh auth login' or export GITHUB_LOGIN."
    FAIL=$((FAIL+1))
  fi
else
  echo "⚠️  detector script missing, skip"
fi

echo ""
echo "─── git remote ───"
if git remote -v | grep -q "origin"; then
  ORIGIN=$(git config --get remote.origin.url)
  echo "✅ origin: $ORIGIN"
  PASS=$((PASS+1))
else
  echo "❌ no git remote 'origin' configured"
  echo "   Add it: git remote add origin https://github.com/<you>/<repo>.git"
  FAIL=$((FAIL+1))
fi

echo ""
echo "─── non-whitelisted VS Code AI extensions ───"
WARN_EXTS=()
for ext_dir in ~/.vscode/extensions ~/.vscode-server/extensions; do
  [ -d "$ext_dir" ] || continue
  if find "$ext_dir" -maxdepth 1 -name "saoudrizwan.claude-dev*" 2>/dev/null | grep -q .; then
    WARN_EXTS+=("Cline (saoudrizwan.claude-dev)")
  fi
  if find "$ext_dir" -maxdepth 1 -name "rooveterinaryinc.roo-cline*" 2>/dev/null | grep -q .; then
    WARN_EXTS+=("Roo Code")
  fi
  if find "$ext_dir" -maxdepth 1 -name "github.copilot-chat*" 2>/dev/null | grep -q .; then
    WARN_EXTS+=("GitHub Copilot Chat")
  fi
done

if [ ${#WARN_EXTS[@]} -gt 0 ]; then
  echo "⚠️  Detected non-whitelisted VS Code AI extensions:"
  for ext in "${WARN_EXTS[@]}"; do
    echo "      - $ext"
  done
  echo "   Only OpenCode / Claude Code (CLI) / Codex / Kiro are supported."
  echo "   Sessions from these extensions WILL NOT be collected → may impact scoring."
fi

echo ""
echo "─── summary ───"
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo ""
echo "✅ All checks passed. Ready to start AI work."
