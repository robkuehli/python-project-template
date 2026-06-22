#!/usr/bin/env bash
#
# verify-on-stop.sh — Stop-Hook. Erinnert an die "Verify"-Stufe des
# Plan-Execute-Verify-Loops, wenn die Session mit uncommitted Diff endet.
# Ort: .claude/hooks/verify-on-stop.sh  ·  registriert in settings.json
#
# Default: SOFT-WARN (exit 0, Nachricht auf stderr).
# Opt-in HARD-BLOCK: `export CLAUDE_VERIFY_HARD_BLOCK=1` — dann wird Stop blockiert
# bis `just qa` grün ist. Claude Code überschreibt den Block nach 8 Wiederholungen.
#
# Hintergrund (Anthropic Best Practices): "A Stop hook runs your check as a
# script and blocks the turn from ending until it passes."
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR" || exit 0

# Kein Git-Repo → nichts zu verifizieren
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Kein Diff → fertig
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
  exit 0
fi

# Hard-Block-Modus: just qa muss grün sein
if [ "${CLAUDE_VERIFY_HARD_BLOCK:-0}" = "1" ] && [ -f justfile ] && command -v just >/dev/null 2>&1; then
  if ! just qa >/tmp/claude-verify-qa.log 2>&1; then
    jq -nc '{
      decision: "block",
      reason: "Stop blocked: `just qa` failed. Fix the errors (see /tmp/claude-verify-qa.log), then end the turn."
    }'
    exit 0
  fi
  exit 0
fi

# Soft-Modus: Reminder ohne Block
echo "📋 Uncommitted changes detected. Run \`just qa\` and verify with evidence before declaring done." >&2
exit 0
