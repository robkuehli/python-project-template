# Eskalation: Lokal → Ollama Cloud

**Status:** Draft v1
**Datum:** 2026-05-19
**Voraussetzung:** Setup gemäß `01-project-brief.md`, `02-adrs.md`, `03-setup-manual.md`. Ergänzung zu ADR-002 (OpenCode) und ADR-003 (Qwen3-Coder lokal).

---

## Motivation

Der lokale Agent erreicht laut Brief realistisch 40–60 % Erfolg pro Einzelversuch. Bei drei parallelen Versuchen kommen wir auf gute Quoten — aber es gibt Nächte, in denen *alle drei* scheitern, weil das lokale Modell an einem bestimmten Pattern strukturell hängenbleibt. Stand heute liefert das Setup dann morgens nur `DEBUG_HYPOTHESES.md` und Frust.

Eskalation soll diese Nächte retten: wenn das lokale Modell wiederholt am gleichen Punkt fest hängt, übernimmt ein größeres Open-Weight-Modell aus Ollama Cloud — über **denselben Endpoint, dieselbe OpenCode-Session, gleichen Code-Pfad**. Nur der Modellname wechselt.

## Warum Ollama Cloud und nicht Frontier-API

ADR-002 hat OpenCode als Agent gewählt, ADR-003 Qwen3-Coder lokal. Die Eskalation soll diese Architekturlinie **nicht** verlassen:

- Gleicher API-Wire-Format (OpenAI-kompatibel) — kein Provider-Wechsel im Orchestrator
- Gleicher Daemon (`localhost:11434/v1`) — Cloud-Modelle laufen transparent über den lokalen Ollama-Daemon mit `:cloud`-Suffix
- Gleiche Auth-Mechanik — `OLLAMA_API_KEY` als Env-Var, kein zweiter Credential-Pfad
- Datenschutz vergleichbar — Ollama-Cloud ist Open-Weight-Hosting, kein US-Frontier-Vendor
- Kostenmodell — Ollama Cloud aktuell Limits, Usage-based Pricing angekündigt aber noch nicht GA (Stand April 2026, → Analysen prüfen)

Eine Eskalation nach Claude/GPT bleibt als zweite Stufe offen, ist aber bewusst nicht Standard. Wenn Ollama-Cloud-Modelle (Kimi K2.5, GLM-5, gpt-oss:120b, DeepSeek) auch scheitern, ist die Spec wahrscheinlich das Problem, nicht das Modell.

## Architektur-Skizze

```
┌─────────────────────────────────────────────────────────┐
│            Orchestrator (Bash, ~/agent-projects)         │
│                                                         │
│   for try in 1 2 3:                                     │
│     run worktree-$try with $LOCAL_MODEL                 │
│                                                         │
│   if all 3 failed:                                      │
│     escalate → worktree-4 mit $CLOUD_MODEL              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌───────────────────────────────────┐
        │   Ollama Daemon (localhost:11434) │
        │                                   │
        │   qwen3-coder-64k   ─ lokal       │
        │   gpt-oss:120b:cloud  ─ via Cloud │
        │   deepseek-r1:cloud   ─ via Cloud │
        │   kimi-k2:cloud       ─ via Cloud │
        └───────────────────────────────────┘
```

Eskalation = vier Versuche statt drei, der vierte mit anderem `model:`-Parameter.

## Trigger-Bedingung

Eskalation startet **nicht** automatisch nach jedem Fehlversuch. Das wäre teuer und meist wirkungslos, weil dasselbe Fundament-Problem dreimal scheitert.

Trigger: **Alle parallelen lokalen Versuche** haben in ihrem `DEBUG_HYPOTHESES.md` geschrieben und beendet, **oder** alle haben `max_iterations` erreicht. Erst dann lohnt sich ein größeres Modell.

Konkret im Orchestrator:

```bash
LOCAL_FAILS=0
for try in 1 2 3; do
  bash run-worktree.sh "$try" "$LOCAL_MODEL" || LOCAL_FAILS=$((LOCAL_FAILS+1))
done

if [ "$LOCAL_FAILS" -eq 3 ]; then
  echo "Alle lokalen Versuche fehlgeschlagen → Eskalation"
  bash run-worktree.sh "escalated" "$CLOUD_MODEL" "--max-turns 30"
fi
```

## Konfiguration

### Voraussetzungen

- Ollama Cloud Account mit aktivem `OLLAMA_API_KEY` (siehe `03-setup-manual.md`, Sektion „Ollama Cloud Account")
- Gewähltes Cloud-Modell mindestens einmal manuell getestet:
  ```bash
  OLLAMA_API_KEY=... ollama run gpt-oss:120b:cloud "Hello"
  ```
- Tool-Calling auf dem Cloud-Modell verifiziert (gleicher Test wie in Phase 2 des Setup-Manuals, aber gegen `:cloud`-Modell)

### Modell-Kandidaten

| Modell | Stärken | Kostenklasse | Empfehlung |
|---|---|---|---|
| `gpt-oss:120b:cloud` | Allround, gutes Tool-Calling | Mittel | Default-Eskalation |
| `deepseek-r1:cloud` | Reasoning, Debugging | Mittel | Bei Debugging-Failures |
| `qwen3-coder:480b:cloud` | Coding-spezialisiert, sehr groß | Hoch | Wenn Code-Logik das Problem ist |
| `glm-5:cloud` | Schnell, breit | Mittel | Wenn `gpt-oss` nicht ausreicht |
| `kimi-k2:cloud` | Long Context | Mittel | Bei großen Codebases |

Modell-Wahl als Env-Variable im Orchestrator, nicht hardcoded.

### Orchestrator-Anpassung

`run-agent.sh` bekommt einen zusätzlichen Eskalations-Block. Ungetestetes Skelett:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$1"
LOCAL_MODEL="${LOCAL_MODEL:-qwen3-coder-64k}"
CLOUD_MODEL="${CLOUD_MODEL:-gpt-oss:120b:cloud}"
MAX_PARALLEL=3
LOG_DIR="$HOME/agent-projects/logs/$(date +%F)-$(basename "$PROJECT_DIR")"
mkdir -p "$LOG_DIR"

run_attempt() {
  local id="$1" model="$2" extra="${3:-}"
  local wt="${PROJECT_DIR}.wt-${id}"
  git -C "$PROJECT_DIR" worktree add "$wt" -b "agent-attempt-$id"
  (
    cd "$wt"
    docker run --rm \
      --cpus="2.8" --memory="6g" --network=none \
      -v "$wt:/workspace:rw" \
      -e OPENCODE_MODEL="ollama/$model" \
      ${OLLAMA_API_KEY:+-e OLLAMA_API_KEY="$OLLAMA_API_KEY"} \
      agent-sandbox:latest \
      bash -c "opencode run --max-turns ${MAX_TURNS:-20} $extra < spec.md"
  ) > "$LOG_DIR/$id.log" 2>&1
}

# Phase 1: lokale Parallel-Versuche
fails=0
for id in $(seq 1 "$MAX_PARALLEL"); do
  run_attempt "$id" "$LOCAL_MODEL" &
done
wait

# Erfolg = mindestens ein Worktree mit grünen Tests
if ls "${PROJECT_DIR}.wt-"*/.green 2>/dev/null | grep -q .; then
  bash notify.sh "Erfolg: $(ls "${PROJECT_DIR}.wt-"*/.green | head -1)"
  exit 0
fi

# Phase 2: Eskalation
bash notify.sh "Lokale Versuche fehlgeschlagen — eskaliere auf $CLOUD_MODEL"
MAX_TURNS=30 run_attempt "cloud" "$CLOUD_MODEL"

if [ -f "${PROJECT_DIR}.wt-cloud/.green" ]; then
  bash notify.sh "Eskalation erfolgreich: $CLOUD_MODEL"
else
  bash notify.sh "Eskalation fehlgeschlagen — DEBUG_HYPOTHESES.md prüfen"
  exit 1
fi
```

`.green` ist eine Marker-Datei, die der Agent am Ende eines erfolgreichen Runs schreibt (TDD-Grün + pre-commit grün). Details → noch zu spezifizieren in `05-orchestrator.md` (TODO).

## Sicherheits-Implikationen

Eskalation lockert eine Auflage aus dem Brief: **N3 (kein Netzwerk-Zugriff nach Initial-Install)** muss für den Cloud-Run aufgeweicht werden, weil der Ollama-Daemon den Cloud-Endpoint braucht. Vorgehen:

- Eskalations-Worktree läuft mit eingeschränkter Allowlist (`--network host` ist tabu, stattdessen Netzwerk-Namespace mit Allowlist auf Ollama-Cloud-Endpoint)
- Alternative für Setups ohne saubere Allowlist-Mechanik: Eskalations-Worktree läuft *außerhalb* des Docker-Sandbox, dafür mit Read-Only-Workspace und explizitem File-Diff-Audit am Ende
- Audit-Log muss vermerken, dass dieser Run im Cloud-Modus lief

## ADR-Erweiterung (Vorschlag)

Anhang an `02-adrs.md`:

```markdown
## ADR-009: Cloud-Eskalation via Ollama Cloud

### Status
Accepted

### Kontext
Lokale Modelle scheitern in ~25 % der Nächte bei kleineren MVPs (5–7 Dateien). Das Setup soll diese Fälle automatisch retten, ohne den Architekturstil aus ADR-002/003 zu verlassen.

### Entscheidung
Nach drei fehlgeschlagenen lokalen Versuchen startet der Orchestrator einen vierten Versuch mit einem größeren Open-Weight-Modell via Ollama Cloud (`:cloud`-Suffix). Gleicher API-Endpoint, gleicher OpenCode-Code-Pfad, nur anderer Modellname.

### Konsequenzen
**Positiv:**
- Strukturell minimaler Eingriff — eine Code-Verzweigung im Orchestrator
- Keine Frontier-API-Kosten als Default
- Open-Weight bleibt der Standard, Datenfluss bleibt vergleichbar transparent

**Negativ:**
- N3 (`--network none`) muss für diesen einen Run aufgeweicht werden
- Zusätzliche Auth (`OLLAMA_API_KEY`) im Setup
- Ollama-Cloud-Verfügbarkeit ist eine neue externe Abhängigkeit

### Verworfene Alternativen
- **Frontier-API (Claude Opus/GPT-Codex):** Bessere Erfolgswahrscheinlichkeit, aber Bruch mit ADR-002 (keine Frontier-Modelle als Default) und höhere Kosten pro Run.
- **Sequenzielle lokale Re-Tries mit anderem lokalen Modell:** Bringt wenig — wenn das primäre lokale Modell strukturell versagt, schafft es ein anderes 30-B-Modell oft auch nicht.
```

## Offene Punkte

- [ ] Konkrete Allowlist-Mechanik für den Cloud-Run (Docker Netzwerk-Namespace vs. Außerhalb-Container)
- [ ] `.green`-Marker-Spezifikation in `05-orchestrator.md` ausarbeiten
- [ ] Tool-Calling-Verifikation pro Kandidaten-Modell — sobald Ollama-Cloud-Account aktiv ist, in `Analysen und Recherchen/ollama-cloud-modelle-stand-*.md` festhalten
- [ ] Eskalations-Notification mit Modell-Name und Kostenhinweis ergänzen (`notify.sh`)
- [ ] Kosten-Cap pro Nacht via Wrapper, sobald Ollama Usage-based Pricing GA ist

## Querverweise

- `01-project-brief.md` — N3 Netzwerk-Restriktion
- `02-adrs.md` ADR-002 (OpenCode), ADR-003 (Qwen3-Coder), ADR-006 (Docker-Sandboxing)
- `03-setup-manual.md` Phase 2 (Tool-Calling-Test), Phase 5 (Orchestrator)
- `../Analysen und Recherchen/codex-profile-config-erkenntnisse.md` (historisch) — Hinweis: Ollama-Cloud-Modelle sind via gleichem Daemon ansprechbar
