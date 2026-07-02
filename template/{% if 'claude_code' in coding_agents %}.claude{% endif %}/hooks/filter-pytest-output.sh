#!/usr/bin/env bash
#
# filter-pytest-output.sh — PreToolUse-Hook für Bash. Reduziert verbose Test-
# und Lint-Outputs auf den relevanten Tail, damit der Kontext schlank bleibt.
# Ort: .claude/hooks/filter-pytest-output.sh  ·  registriert in settings.json
#
# Pattern (offizielle Anthropic-Cost-Doku):
# "Custom hooks can preprocess data before Claude sees it. Instead of reading
#  a 10,000-line log, a hook can grep and return only matching lines."
#
# Greift NUR bei den Standard-Quality-Gates (pytest, ruff, mypy, just qa|lint|test|typecheck).
# Modifiziert NICHT, wenn der User schon selbst piped/umleitet (`|`, `>`, `tee`).
set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# Pass-through wenn nichts zu filtern
[ -z "$CMD" ] && { printf '{}'; exit 0; }

# Pass-through wenn User schon eigene Pipeline definiert
case "$CMD" in
  *"|"*|*">"*|*"tee "*) printf '{}'; exit 0 ;;
esac

# Nur bekannte verbose Commands augmentieren
case "$CMD" in
  *pytest*|*"just test"*|*"just qa"*|*"just lint"*|*"just typecheck"*|*"ruff check"*|*"mypy "*)
    FILTERED="$CMD 2>&1 | tail -n 300"
    jq -nc \
      --arg c "$FILTERED" \
      '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "allow",
          updatedInput: { command: $c }
        }
      }'
    exit 0
    ;;
esac

printf '{}'
exit 0
