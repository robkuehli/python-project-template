#!/usr/bin/env bash
# notify.sh — eine Push-Notification ans Handy. Default Pushover, Telegram als Alternative.
# Aufruf: notify.sh "Titel" "Nachricht"
# Config (mode 600): ~/.config/agent/notify.env  mit z.B.
#   NOTIFY_PROVIDER=pushover
#   PUSHOVER_USER=...
#   PUSHOVER_TOKEN=...
# oder
#   NOTIFY_PROVIDER=telegram
#   TELEGRAM_BOT_TOKEN=...
#   TELEGRAM_CHAT_ID=...
set -euo pipefail

TITLE="${1:-Autonomer Coding Agent}"
MSG="${2:-}"
ENV_FILE="${NOTIFY_ENV:-$HOME/.config/agent/notify.env}"
[ -f "$ENV_FILE" ] && { set -a; . "$ENV_FILE"; set +a; }

case "${NOTIFY_PROVIDER:-none}" in
  pushover)
    curl -sf --max-time 10 https://api.pushover.net/1/messages.json \
      -F "token=${PUSHOVER_TOKEN}" -F "user=${PUSHOVER_USER}" \
      -F "title=${TITLE}" -F "message=${MSG}" >/dev/null \
      && echo "notify: pushover gesendet" || echo "notify: pushover fehlgeschlagen" >&2
    ;;
  telegram)
    curl -sf --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${TITLE}: ${MSG}" >/dev/null \
      && echo "notify: telegram gesendet" || echo "notify: telegram fehlgeschlagen" >&2
    ;;
  *)
    echo "notify (kein Provider konfiguriert): ${TITLE}: ${MSG}"
    ;;
esac
