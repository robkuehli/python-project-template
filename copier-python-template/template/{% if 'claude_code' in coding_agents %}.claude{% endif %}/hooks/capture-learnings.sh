#!/usr/bin/env bash
#
# capture-learnings.sh — SessionEnd-Hook für halbautomatische Learning-Capture.
# Ort: .claude/hooks/capture-learnings.sh  ·  registriert via "SessionEnd" in settings.json
#
# Pattern "Capture-Inbox": dieser Hook EXTRAHIERT Vorschläge in eine Staging-Datei.
# Er schreibt NIE in die kanonische LEARNINGS.md — das macht erst der manuelle
# Promote-Schritt (/capture review). Automatik beim Schreiben, Mensch beim Freigeben.
#
# Hook-Input kommt als JSON über stdin (.transcript_path / .cwd / .reason).
# Reason-Werte: clear | logout | prompt_input_exit | other.
set -euo pipefail

# --- Pfade -------------------------------------------------------------------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
INBOX="${CLAUDE_LEARNINGS_INBOX:-$PROJECT_DIR/.claude/LEARNINGS.inbox.md}"
# Scribe-Modell: günstig. Für EU/DSGVO-Arbeit auf einen EU-gebundenen Alias zeigen.
SCRIBE_MODEL="${CLAUDE_LEARNINGS_MODEL:-haiku}"

# --- Hook-Payload (JSON via stdin) -------------------------------------------
PAYLOAD=$(cat)
TRANSCRIPT=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty')
CWD=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty')

# Nichts zu tun, wenn kein Transkript vorliegt oder die Inbox fehlt.
{ [ -z "${TRANSCRIPT:-}" ] || [ ! -f "$TRANSCRIPT" ]; } && exit 0
[ -f "$INBOX" ] || exit 0
PROJECT=$(basename "${CWD:-$PROJECT_DIR}")
TODAY=$(date +%F)

# --- Extraktion ("propose") --------------------------------------------------
read -r -d '' PROMPT <<EOF || true
Du bist die Scribe-Rolle. Lies das folgende Session-Transkript und extrahiere
0..N HANDLUNGSRELEVANTE Learnings nach diesen Regeln:
- Eine Zeile pro Learning, Form: "Wenn X, dann Y prüfen, weil Z".
- KEIN Learning, das nur einmalig zutrifft. KEIN "sei vorsichtig mit ...".
- Nur was den GLEICHEN Fehler in einer ähnlichen Situation künftig verhindert.
- Wenn es nichts Substanzielles gibt: gib NICHTS aus (leere Antwort).

Format pro Eintrag (exakt, zwei Zeilen):
<!-- ${TODAY} | ${PROJECT} | kurzer kontext -->
- [ ] proposed: konkrete regel

Transkript folgt.
EOF

# claude -p liest den Prompt; das Transkript wird angehängt.
SUGGESTIONS=$(
  { printf '%s\n\n' "$PROMPT"; cat "$TRANSCRIPT"; } \
    | claude -p --model "$SCRIBE_MODEL" 2>/dev/null || true
)

if [ -n "${SUGGESTIONS//[[:space:]]/}" ]; then
  { printf '\n'; printf '%s\n' "$SUGGESTIONS"; } >> "$INBOX"
fi

exit 0
