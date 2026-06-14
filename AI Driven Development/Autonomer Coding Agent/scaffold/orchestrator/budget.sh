#!/usr/bin/env bash
# budget.sh — Eskalations-Budget fuer Ollama Cloud.
# shellcheck shell=bash
#
# Stand Mai 2026: Ollama Cloud ist SUBSCRIPTION-basiert (Free/$0, Pro $20, Max $100) mit
# Session-Limits (Reset alle 5 h) + Weekly-Limits — KEIN per-Token/$-Meter (metered "coming soon").
# Quelle: https://ollama.com/pricing , https://devtoolhub.com/ollama-cloud-free-vs-pro-limits-pricing-2026/
#
# Konsequenz: "Budget aufgebraucht" == selbst gesetztes Kontingent an Cloud-ESKALATIONEN,
# nicht ein Euro-Betrag. Wir fuehren ein lokales Ledger und kappen pro Tag + pro Woche.
# Sobald Ollama metered Pricing GA hat: hier zusaetzlich `opencode stats`-Kosten gegen ein
# Euro-Cap pruefen (TODO unten).

LEDGER="${CLOUD_LEDGER:-$HOME/.config/agent/cloud-ledger.json}"
MAX_CLOUD_PER_DAY="${MAX_CLOUD_PER_DAY:-4}"
MAX_CLOUD_PER_WEEK="${MAX_CLOUD_PER_WEEK:-15}"

budget_init() {
  mkdir -p "$(dirname "$LEDGER")"
  [ -f "$LEDGER" ] || echo '[]' > "$LEDGER"
}

# Anzahl Cloud-Eskalationen seit <seconds> Sekunden
_count_since() {
  local since_epoch=$1
  jq --argjson t "$since_epoch" '[.[] | select(.epoch >= $t)] | length' "$LEDGER"
}

budget_can_escalate() {
  budget_init
  local now day week
  now=$(date +%s); day=$((now - 86400)); week=$((now - 604800))
  local d w; d=$(_count_since "$day"); w=$(_count_since "$week")
  if [ "$d" -ge "$MAX_CLOUD_PER_DAY" ];  then log "Budget: Tages-Cap erreicht ($d/$MAX_CLOUD_PER_DAY)";  return 1; fi
  if [ "$w" -ge "$MAX_CLOUD_PER_WEEK" ]; then log "Budget: Wochen-Cap erreicht ($w/$MAX_CLOUD_PER_WEEK)"; return 1; fi
  log "Budget ok (heute $d/$MAX_CLOUD_PER_DAY, Woche $w/$MAX_CLOUD_PER_WEEK) -> Eskalation erlaubt"
  return 0
}

budget_record() {
  local model="$1"
  budget_init
  local tmp; tmp=$(mktemp)
  jq --arg m "$model" --arg p "$(basename "$PROJECT_DIR")" --argjson e "$(date +%s)" \
     '. + [{epoch:$e, iso:(now|todate), project:$p, model:$m}]' "$LEDGER" > "$tmp" && mv "$tmp" "$LEDGER"
  log "Budget: Cloud-Eskalation verbucht ($model)"
}

budget_report() {
  budget_init
  local now day week; now=$(date +%s); day=$((now-86400)); week=$((now-604800))
  printf 'Cloud-Eskalationen: heute %s/%s, Woche %s/%s' \
    "$(_count_since "$day")" "$MAX_CLOUD_PER_DAY" "$(_count_since "$week")" "$MAX_CLOUD_PER_WEEK"
}

# TODO(metered-GA): wenn Ollama usage-based Pricing GA ist, hier zusaetzlich
#   opencode stats --days 7 --models  parsen und gegen ein EUR_CAP pruefen.
