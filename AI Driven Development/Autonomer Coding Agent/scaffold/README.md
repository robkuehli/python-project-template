# Scaffold — Autonomer Coding-Agent

Lauffähiges Skelett für den autonomen Overnight-Agenten. Begleitende Design-Docs: `../01-project-brief.md`, `../02-adrs.md`, `../05-orchestrator.md`, `../06-spec-workflow.md`.

> Status: 🧪 **Skelett** — als Startpunkt gedacht, vor dem ersten unbeaufsichtigten Overnight-Run verifizieren (siehe „Erst-Inbetriebnahme"). Cloud-Modell-Tags und die OpenCode-Plugin-API bewegen sich schnell — am Setup-Tag gegenprüfen.

## Was ist das

Ein Bash-Orchestrator startet pro PoC mehrere parallele OpenCode-Versuche in Docker-Sandboxes, jeder mit einem **lokalen Ollama-Worker**. Erst wenn alle lokalen Versuche das objektive Gate (`make check` grün + README) reißen, eskaliert er **budget-gated** auf Ollama-Cloud-Modelle. Du lieferst nur `spec.md`.

```
spec.md ──> run-agent.sh ──> 3x [git worktree + Docker-Sandbox + opencode run (lokal)]
                                   │
                                   ├─ verify_gate (make check) ──> .green? ──> Notification ✓
                                   │
                                   └─ alle rot ──> budget_can_escalate? ──> Cloud-Modell ──> verify ──> ✓ / nächstes Modell / aufgeben
```

## Dateien

| Pfad | Zweck |
|---|---|
| `opencode-autonomous.json` | OpenCode-Profil: lokaler Worker als Default, Cloud nur als benannte Eskalations-Ziele, `webfetch: allow`. |
| `opencode-autonomous-planreview.json` | Overlay (ADR-011): plan/reviewer auf günstigem Cloud-Open-Weight, Worker bleibt lokal. Aktiv bei `PLANNER_REVIEWER=on`. |
| `orchestrator/run-agent.sh` | Hauptskript: Phasen lokal → Eskalation → Notify. |
| `orchestrator/lib.sh` | Preflight, Worktrees, Worker-Prompt, objektives Verify-Gate. |
| `orchestrator/budget.sh` | Eskalations-Kontingent (Tag/Woche) als jq-Ledger. |
| `orchestrator/notify.sh` | Pushover/Telegram-Push. |
| `orchestrator/agent.env.example` | Konfiguration (Modelle, Limits, Budget). → nach `agent.env` kopieren. |
| `sandbox/Dockerfile` | Sandbox-Image (OpenCode + Python-Toolchain, non-root). |
| `sandbox/run-sandbox.sh` | Docker-Run-Wrapper: offener Egress, nur Worktree rw, `host.docker.internal`, `timeout`. |
| `templates/` | `constitution.md`, `AGENTS.md`, `.pre-commit-config.yaml`, `pyproject.toml`, `Makefile`, `spec.lite.md` — an die Guidelines verdrahtet. |
| `plugin/autonomous-guards.ts` | PreBash-Hard-Block + Egress-Audit + ruff-format. Ins PoC-Repo unter `.opencode/plugin/`. |

## Einmaliges Setup

```bash
# 1. Sandbox-Image bauen
docker build -t agent-sandbox:latest sandbox/

# 2. Ollama: lokales Modell ziehen, Cloud-Login
ollama pull qwen3-coder:30b
ollama signin                      # für Cloud-Eskalation; erzeugt OLLAMA_API_KEY
ollama pull qwen3-coder-next-cloud # Cloud-Tags vorab gegen `ollama list` verifizieren

# 3. Orchestrator konfigurieren
cp orchestrator/agent.env.example orchestrator/agent.env
$EDITOR orchestrator/agent.env     # OLLAMA_API_KEY, Modelle, Budget-Caps

# 4. Notifications (optional, mode 600)
mkdir -p ~/.config/agent && chmod 700 ~/.config/agent
printf 'NOTIFY_PROVIDER=pushover\nPUSHOVER_USER=...\nPUSHOVER_TOKEN=...\n' > ~/.config/agent/notify.env
chmod 600 ~/.config/agent/notify.env

# 5. Tooling auf dem Host
brew install jq                    # Budget-Ledger
```

## Pro PoC

```bash
mkdir ~/agent-projects/mein-poc && cd $_
git init
# Templates reinkopieren:
cp /pfad/scaffold/templates/{.pre-commit-config.yaml,pyproject.toml,Makefile,AGENTS.md} .
mkdir -p .specify/memory && cp /pfad/scaffold/templates/constitution.md .specify/memory/
mkdir -p .opencode/plugin && cp /pfad/scaffold/plugin/autonomous-guards.ts .opencode/plugin/
# Spec schreiben (klein: spec.lite.md als Vorlage; mittel: voller Spec-Kit-Flow, siehe 06-spec-workflow.md)
cp /pfad/scaffold/templates/spec.lite.md spec.md && $EDITOR spec.md
git add -A && git commit -m "chore: scaffold + spec"

# Lauf starten
/pfad/scaffold/orchestrator/run-agent.sh ~/agent-projects/mein-poc
```

Mit Planner/Reviewer-Schicht: `PLANNER_REVIEWER=on /pfad/scaffold/orchestrator/run-agent.sh ~/agent-projects/mein-poc`

## Erst-Inbetriebnahme (vor dem ersten Overnight-Run)

1. `shellcheck orchestrator/*.sh sandbox/run-sandbox.sh` — sauber?
2. **Tool-Calling verifizieren** (häufigster stiller Fehler lokaler Modelle): siehe `../03-setup-manual.md` Phase 2.
3. `host.docker.internal:11434` aus dem Container erreichbar? (`docker run --rm --add-host=host.docker.internal:host-gateway agent-sandbox curl -s http://host.docker.internal:11434/api/tags`)
4. Prüfen, ob OpenCode `{env:OLLAMA_BASE_URL}` in `baseURL` auflöst — sonst container-lokale Profilkopie mit hartem `host.docker.internal`.
5. **≥10 beobachtete Manual-Runs** mit Erfolgsquote ≥6/10, bevor du unbeaufsichtigt laufen lässt.
6. Sicherheits-Checkliste aus `../03-setup-manual.md` abhaken (keine Secret-Mounts etc.).
