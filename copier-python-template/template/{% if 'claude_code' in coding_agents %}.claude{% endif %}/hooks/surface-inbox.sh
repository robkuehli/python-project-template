#!/usr/bin/env bash
#
# surface-inbox.sh — SessionStart-Hook. Erinnert an offene Learning-Vorschläge.
# Ort: .claude/hooks/surface-inbox.sh  ·  registriert via "SessionStart" in settings.json
#
# Zählt offene "[ ] proposed"-Einträge in der Inbox und gibt einen Hinweis aus,
# damit der manuelle Promote-Schritt (/capture review) nicht vergessen wird.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
INBOX="${CLAUDE_LEARNINGS_INBOX:-$PROJECT_DIR/.claude/LEARNINGS.inbox.md}"
[ -f "$INBOX" ] || exit 0

PENDING=$(grep -c '^[[:space:]]*-[[:space:]]*\[ \] proposed' "$INBOX" 2>/dev/null || echo 0)
if [ "${PENDING:-0}" -gt 0 ]; then
  echo "📥 ${PENDING} offene Learning-Vorschläge in $(basename "$INBOX"). Promoten mit: /capture review"
fi
exit 0
