#!/usr/bin/env bash
# run-agent.sh — Orchestrator fuer autonome Overnight-Runs.
#
#   ./run-agent.sh /pfad/zum/projekt
#
# Ablauf:  Preflight -> Snapshot -> [optional Planner] -> N parallele lokale Versuche
#          -> objektives Verify-Gate -> budget-gated Cloud-Eskalation -> Notification.
#
# Es gibt KEIN `opencode --max-turns`. Jeder Versuch wird per `timeout` (im Sandbox-Wrapper)
# hart begrenzt; der aeussere Loop begrenzt die Zahl der Versuche; das Budget begrenzt Cloud.
set -euo pipefail

PROJECT_DIR="$(cd "${1:?Usage: run-agent.sh <project-dir>}" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Config (override via env oder agent.env neben diesem Skript) ----------
[ -f "$SCRIPT_DIR/agent.env" ] && { set -a; . "$SCRIPT_DIR/agent.env"; set +a; }

LOCAL_MODEL="${LOCAL_MODEL:-ollama/qwen3-coder:30b}"
CLOUD_ESCALATION_MODELS="${CLOUD_ESCALATION_MODELS:-ollama/qwen3-coder-next-cloud ollama/glm-5.1-cloud}"
LOCAL_PARALLEL="${LOCAL_PARALLEL:-3}"
ATTEMPT_TIMEOUT="${ATTEMPT_TIMEOUT:-5400}"          # 90 min pro lokalem Versuch
CLOUD_ATTEMPT_TIMEOUT="${CLOUD_ATTEMPT_TIMEOUT:-3600}"
PLANNER_REVIEWER="${PLANNER_REVIEWER:-off}"          # ADR-011: optionale Schicht, default aus
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434/v1}"
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"    # Platzhalter genuegt fuer rein lokale Modelle

CONFIG_BASE="$SCAFFOLD_DIR/opencode-autonomous.json"
CONFIG_PLANREVIEW="$SCAFFOLD_DIR/opencode-autonomous-planreview.json"
ACTIVE_CONFIG="$CONFIG_BASE"
[ "$PLANNER_REVIEWER" = "on" ] && ACTIVE_CONFIG="$CONFIG_PLANREVIEW"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
WT_BASE="${WT_BASE:-$HOME/agent-projects/worktrees/$(basename "$PROJECT_DIR")-$RUN_ID}"
LOG_DIR="${LOG_DIR:-$HOME/agent-projects/logs/$RUN_ID-$(basename "$PROJECT_DIR")}"
mkdir -p "$WT_BASE" "$LOG_DIR"
RUN_LOG="$LOG_DIR/orchestrator.log"

# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"
# shellcheck source=budget.sh
. "$SCRIPT_DIR/budget.sh"

notify() { bash "$SCRIPT_DIR/notify.sh" "$@" || true; }

# --- ein Versuch: Worktree + Sandbox-Run + Verify -------------------------
run_attempt() {
  local id="$1" model="$2" tier="$3" cfg="$4" tmo="$5"
  local wt; wt="$(make_worktree "$id")"
  write_worker_prompt "$wt" "$tier"
  log "Versuch $id ($tier) Modell=$model timeout=${tmo}s -> $wt"
  bash "$SCAFFOLD_DIR/sandbox/run-sandbox.sh" "$wt" "$model" "$cfg" "$tmo" "@PROMPT.md" \
      > "$LOG_DIR/attempt-$id.log" 2>&1 || log "Versuch $id: opencode-Run endete non-zero (Timeout o. Fehler) — verifiziere trotzdem"
  verify_gate "$wt" && return 0 || return 1
}

main() {
  log "=== Autonomer Run $RUN_ID :: $(basename "$PROJECT_DIR") ==="
  log "Worker=$LOCAL_MODEL | Eskalation=[$CLOUD_ESCALATION_MODELS] | Planner/Reviewer=$PLANNER_REVIEWER"
  preflight
  budget_init

  # Snapshot fuer sauberen Rollback
  git -C "$PROJECT_DIR" tag "pre-agent-$RUN_ID" >/dev/null 2>&1 || true

  # --- Phase 1: parallele lokale Versuche ---------------------------------
  log "Phase 1: $LOCAL_PARALLEL parallele lokale Versuche"
  local id
  for id in $(seq 1 "$LOCAL_PARALLEL"); do
    run_attempt "$id" "$LOCAL_MODEL" "local" "$CONFIG_BASE" "$ATTEMPT_TIMEOUT" &
  done
  wait

  local winner
  if winner="$(pick_winner)"; then
    log "ERFOLG (lokal): $winner"
    notify "PoC fertig (lokal)" "$(basename "$PROJECT_DIR"): gruener Versuch in $(basename "$winner"). $(budget_report)"
    exit 0
  fi
  log "Alle lokalen Versuche rot."

  # --- Phase 2: Cloud-Eskalation (budget-gated, mehrere Modelle nacheinander)
  local cloud_id=100 model
  for model in $CLOUD_ESCALATION_MODELS; do
    if ! budget_can_escalate; then
      log "Budget aufgebraucht — keine weitere Eskalation."
      notify "Budget aufgebraucht" "$(basename "$PROJECT_DIR"): lokal gescheitert, Cloud-Budget aus. $(budget_report). DEBUG_HYPOTHESES.md pruefen."
      break
    fi
    cloud_id=$((cloud_id+1))
    log "Phase 2: Eskalation auf $model (Versuch $cloud_id)"
    notify "Eskalation" "$(basename "$PROJECT_DIR"): lokal gescheitert -> Cloud $model. $(budget_report)"
    budget_record "$model"
    if run_attempt "$cloud_id" "$model" "cloud" "$ACTIVE_CONFIG" "$CLOUD_ATTEMPT_TIMEOUT"; then
      winner="$(pick_winner)"
      log "ERFOLG (cloud $model): $winner"
      notify "PoC fertig (Cloud)" "$(basename "$PROJECT_DIR"): gruen via $model in $(basename "$winner"). $(budget_report)"
      exit 0
    fi
    log "Eskalation auf $model rot."
  done

  # --- Phase 3: aufgeben ---------------------------------------------------
  cleanup_worktrees
  log "Run gescheitert. Worktrees + Logs bleiben fuer Review: $WT_BASE , $LOG_DIR"
  notify "Run gescheitert" "$(basename "$PROJECT_DIR"): kein gruener Versuch. $(budget_report). Siehe DEBUG_HYPOTHESES.md in den Worktrees."
  exit 1
}

main "$@"
