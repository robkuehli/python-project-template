#!/usr/bin/env bash
#
# verify-on-stop.sh — Codex Stop-Hook. Erinnert an die "Verify"-Stufe des
# Plan-Execute-Verify-Loops, wenn die Session mit uncommitted Diff endet.
# Ort: .codex/hooks/verify-on-stop.sh  ·  registriert in config.toml [hooks.Stop]
#
# Default: SOFT-WARN (exit 0, Nachricht auf stderr).
# Opt-in HARD-BLOCK: `export CODEX_VERIFY_HARD_BLOCK=1` — dann wird Stop blockiert
# bis `just qa` grün ist.
#
# Parity mit .claude/hooks/verify-on-stop.sh und .opencode/plugins/verify-on-stop.ts.
set -euo pipefail

PROJECT_DIR="${CODEX_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR" || exit 0

# Kein Git-Repo → nichts zu verifizieren
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Kein Diff → fertig
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
  exit 0
fi

# Hard-Block-Modus: just qa muss grün sein
if [ "${CODEX_VERIFY_HARD_BLOCK:-0}" = "1" ] && [ -f justfile ] && command -v just >/dev/null 2>&1; then
  if ! just qa >/tmp/codex-verify-qa.log 2>&1; then
    echo "Stop blocked: \`just qa\` failed. Fix the errors (see /tmp/codex-verify-qa.log), then end the turn." >&2
    exit 2
  fi
  exit 0
fi

# Soft-Modus: Reminder ohne Block
echo "📋 Uncommitted changes detected. Run \`just qa\` and verify with evidence before declaring done." >&2
exit 0