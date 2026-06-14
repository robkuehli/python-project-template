#!/usr/bin/env bash
# run-sandbox.sh — startet EINEN OpenCode-Run in einer Docker-Sandbox.
#
# Sicherheitsmodell (ADR-006 + ADR-010): Egress ist OFFEN (Agent soll Doku ziehen).
# Isolation kommt NICHT aus Netzwerk-Abschottung, sondern aus:
#   - non-root user im Container (Dockerfile: uid 1000 'agent')
#   - die EINZIGE beschreibbare Host-Bind-Mount ist der Worktree ($WT)
#   - KEINE Mounts von ~/.ssh ~/.aws ~/.config persoenlichen .env (Negativ-Kontrolle unten)
#   - Resource-Limits (CPU/RAM/PIDs), tmpfs /tmp
#   - bash-deny-Guards im OpenCode-Profil + Plugin (Belt-and-Suspenders)
#   - harte Zeitgrenze via `timeout` (es gibt KEIN opencode --max-turns)
#
# Aufruf:
#   run-sandbox.sh <worktree_dir> <model> <config_file> <timeout_secs> <prompt_or_@file>
#
# Beispiel:
#   run-sandbox.sh /path/wt-1 ollama/qwen3-coder:30b ./opencode-autonomous.json 5400 @PROMPT.md
set -euo pipefail

WT="$1"            # Worktree-Verzeichnis (Host-Pfad), wird rw gemountet
MODEL="$2"         # provider/model, z.B. ollama/qwen3-coder:30b
CONFIG_FILE="$3"   # Pfad zum OpenCode-Profil (Host), wird ro gemountet
TIMEOUT_SECS="$4"  # harte Obergrenze pro Versuch (Wall-Clock)
PROMPT="$5"        # Prompt-Text oder @datei (relativ zum Worktree)

IMAGE="${AGENT_SANDBOX_IMAGE:-agent-sandbox:latest}"
CPUS="${SANDBOX_CPUS:-2.8}"          # ~70% von 4 P-Cores (M4 Pro) — Throttling vermeiden
MEM="${SANDBOX_MEM:-6g}"
PIDS="${SANDBOX_PIDS:-512}"

CONFIG_DIR="$(cd "$(dirname "$CONFIG_FILE")" && pwd)"
CONFIG_BASENAME="$(basename "$CONFIG_FILE")"

# host.docker.internal -> Host-Ollama-Daemon (macOS Docker Desktop). 'localhost' im Container
# waere der Container selbst, nicht der Host-Daemon auf Port 11434.
OLLAMA_BASE_URL_IN_CONTAINER="${OLLAMA_BASE_URL_IN_CONTAINER:-http://host.docker.internal:11434/v1}"

: "${OLLAMA_API_KEY:?OLLAMA_API_KEY muss gesetzt sein (auch fuer lokale Modelle als Platzhalter ok)}"

# --- Negativ-Kontrolle: sicherstellen, dass keine Secret-Pfade im Worktree liegen ---
if find "$WT" -maxdepth 3 \( -name '.env' -o -name 'id_rsa*' -o -name '*.pem' \) 2>/dev/null | grep -q .; then
  echo "WARN: Secret-artige Dateien im Worktree gefunden — pruefen vor dem Run!" >&2
fi

# Prompt: '@datei' -> via --file anhaengen (NICHT als String "@datei" uebergeben — das waere der
# literale Prompt). Sonst PROMPT als Message. opencode run -f haengt Dateiinhalt an die Message.
OC="opencode run --dangerously-skip-permissions --format json --agent build"
if [ "${PROMPT#@}" != "$PROMPT" ]; then
  INNER="timeout --signal=TERM --kill-after=60 ${TIMEOUT_SECS}s ${OC} -f '${PROMPT#@}' 'Erfuelle den Auftrag in der angehaengten Datei vollstaendig und autonom.'"
else
  INNER="timeout --signal=TERM --kill-after=60 ${TIMEOUT_SECS}s ${OC} '${PROMPT}'"
fi

exec docker run --rm \
  --name "agent-$(basename "$WT")-$$" \
  --cpus="$CPUS" \
  --memory="$MEM" \
  --memory-swap="$MEM" \
  --pids-limit="$PIDS" \
  --tmpfs /tmp:size=512m \
  --add-host=host.docker.internal:host-gateway \
  -e HOME=/home/agent \
  -e OLLAMA_BASE_URL="$OLLAMA_BASE_URL_IN_CONTAINER" \
  -e OLLAMA_API_KEY="$OLLAMA_API_KEY" \
  -e OPENCODE_CONFIG="/opencode-config/$CONFIG_BASENAME" \
  -e OPENCODE_ENABLE_EXA="${OPENCODE_ENABLE_EXA:-true}" \
  -e OPENCODE_DISABLE_AUTOUPDATE=true \
  -v "$WT":/workspace:rw \
  -v "$CONFIG_DIR":/opencode-config:ro \
  -w /workspace \
  "$IMAGE" \
  bash -lc "$INNER"
