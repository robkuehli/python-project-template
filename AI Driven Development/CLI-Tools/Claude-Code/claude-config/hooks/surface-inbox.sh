#!/usr/bin/env bash
#
# surface-inbox.sh — SessionStart-Hook. Erinnert an offene Learning-Vorschläge.
# Speicherort (im echten Home): ~/.claude/hooks/surface-inbox.sh
# Eingebunden via "SessionStart" in ~/.claude/settings.json.
#
# Zählt offene "[ ] proposed"-Einträge in der Inbox und gibt einen Hinweis aus,
# damit der manuelle Promote-Schritt (/capture) nicht vergessen wird.
set -euo pipefail

INBOX="${CLAUDE_LEARNINGS_INBOX:-$HOME/.claude/LEARNINGS.inbox.md}"
[ -f "$INBOX" ] || exit 0

PENDING=$(grep -c '^\s*-\s*\[ \] proposed' "$INBOX" 2>/dev/null || echo 0)
if [ "${PENDING:-0}" -gt 0 ]; then
  echo "📥 ${PENDING} offene Learning-Vorschläge in $(basename "$INBOX"). Promoten mit: /capture review"
fi
exit 0
