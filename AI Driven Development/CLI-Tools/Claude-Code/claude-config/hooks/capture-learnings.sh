#!/usr/bin/env bash
#
# capture-learnings.sh — SessionEnd-Hook für halbautomatische Learning-Capture.
# Speicherort (im echten Home): ~/.claude/hooks/capture-learnings.sh
# Eingebunden via "SessionEnd" in ~/.claude/settings.json.
#
# Pattern: "Capture-Inbox". Dieser Hook EXTRAHIERT Vorschläge (automatisch) in eine
# Staging-Datei. Er schreibt NIE in die kanonische LEARNINGS.md — das macht erst
# der manuelle Promote-Schritt (/capture-Skill). Automatik beim Schreiben,
# Mensch beim Freigeben. Schützt vor Müll-Einträgen.
#
# Status: 🧪 emerging — Payload-Felder + Transkript-Format gegen die aktuelle
#         Hooks-Reference (https://code.claude.com/docs/en/hooks) verifizieren.
#
# Reason-Werte (Stand Mai 2026): clear | logout | prompt_input_exit | other.
set -euo pipefail

# --- Konfiguration -----------------------------------------------------------
INBOX="${CLAUDE_LEARNINGS_INBOX:-$HOME/.claude/LEARNINGS.inbox.md}"
# Extraktions-Modell ("Scribe"): günstig/lokal. Für DSGVO-Projekte auf ein
# lokales Ollama-Modell zeigen, damit kein Transkript in die Cloud geht.
SCRIBE_MODEL="${CLAUDE_LEARNINGS_MODEL:-haiku}"

# --- Hook-Payload (JSON via stdin) -------------------------------------------
PAYLOAD=$(cat)
TRANSCRIPT=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty')
CWD=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty')
REASON=$(printf '%s' "$PAYLOAD" | jq -r '.reason // "other"')

# Nichts zu tun, wenn kein Transkript vorliegt.
[ -z "${TRANSCRIPT:-}" ] || [ ! -f "$TRANSCRIPT" ] && exit 0
PROJECT=$(basename "${CWD:-unknown}")
TODAY=$(date +%F)

# --- Extraktion ("propose") --------------------------------------------------
read -r -d '' PROMPT <<EOF || true
Du bist die Scribe-Rolle. Lies das folgende Session-Transkript und extrahiere
0..N HANDLUNGSRELEVANTE Learnings nach diesen Regeln:
- Eine Zeile pro Learning, Form: "Wenn X, dann Y prüfen, weil Z".
- KEIN Learning, das nur einmalig zutrifft. KEIN "sei vorsichtig mit ...".
- Nur was den GLEICHEN Fehler in einer ähnlichen Situation künftig verhindert.
- Wenn es nichts Substanzielles gibt: gib EINE leere Antwort (nichts ausgeben).

Format pro Eintrag (exakt, zwei Zeilen):
<!-- ${TODAY} | ${PROJECT} | kurzer kontext -->
- [ ] proposed: konkrete regel

Transkript folgt.
EOF

# claude -p liest den Prompt; das Transkript wird angehängt.
# Bei leerer Modell-Antwort wird nichts in die Inbox geschrieben.
SUGGESTIONS=$(
  { printf '%s\n\n' "$PROMPT"; cat "$TRANSCRIPT"; } \
    | claude -p --model "$SCRIBE_MODEL" 2>/dev/null || true
)

if [ -n "${SUGGESTIONS//[[:space:]]/}" ]; then
  {
    printf '\n'
    printf '%s\n' "$SUGGESTIONS"
  } >> "$INBOX"
fi

exit 0
