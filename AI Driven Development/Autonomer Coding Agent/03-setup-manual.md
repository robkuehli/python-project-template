# Setup Manual: Autonomer lokaler Coding-Agent

**Status:** Draft v1
**Datum:** 2026-05-18
**Voraussetzungen:** Siehe `01-project-brief.md` und `02-adrs.md`

---

## Übersicht

Das Setup gliedert sich in fünf Phasen:

1. Hardware- und System-Vorbereitung
2. Modell-Backend (Ollama + Qwen3-Coder)
3. Tooling (OpenCode, Spec-Kit, Docker)
4. Projekt-Vorbereitung (Constitution, Templates, Sandbox)
5. Orchestrator und erster Testlauf

Gesamtdauer: ~4–6 Stunden für ein sauberes Setup. Plane einen ganzen Tag, falls du parallel lernen willst.

---

## Phase 1: Hardware- und System-Vorbereitung

### Checks vor Beginn

- macOS auf aktuellem Stand
- Mindestens 100 GB freier Speicher (Modell ~20 GB, Docker-Images, Caches, Worktrees)
- Stromkabel angeschlossen (kein Akku-Betrieb für nächtliche Runs)
- Energie-Einstellungen: "Verhindern, dass der Mac in den Ruhezustand wechselt" aktivieren
- macOS Firewall einsehen und ggf. Ausnahmen für Ollama (Port 11434) und OpenCode dokumentieren

### Achtung: Thermisches Verhalten

Der M4 Pro kommt bei dauerhafter LLM-Last über mehrere Stunden ins Throttling. Maßnahmen:
- CPU-Limit im Docker-Sandbox auf 70% setzen (siehe Phase 4)
- Laptop offen lassen oder auf erhöhter Unterlage – Belüftung nicht blockieren
- Falls möglich: Lüfter-Profil auf "performance" stellen (Tools wie Macs Fan Control)

---

## Phase 2: Modell-Backend

### Ollama installieren

```bash
brew install ollama
brew services start ollama
```

Verifizieren:
```bash
curl http://localhost:11434/api/tags
```

### Qwen3-Coder herunterladen

```bash
ollama pull qwen3-coder:30b
```

Test:
```bash
ollama run qwen3-coder:30b "Schreibe eine Python-Funktion is_prime(n)."
```

### Achtung: Tool-Calling verifizieren

Bevor du irgendwas anderes machst, prüfe **immer**, ob Tool-Calling wirklich funktioniert. Das ist der häufigste stille Fehlerfall in lokalen Setups.

Test-Prompt mit OpenAI-kompatiblem API-Call:
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder:30b",
    "messages": [{"role": "user", "content": "Welche Tools hast du? Liste sie auf."}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "list_files",
        "description": "List files in a directory",
        "parameters": {
          "type": "object",
          "properties": {"path": {"type": "string"}}
        }
      }
    }]
  }'
```

Erwartung: Response enthält einen `tool_calls`-Block. Falls nicht: anderes Modell pullen (z. B. `carnice-moe:35b`) oder Quantisierung wechseln.

### Context Window konfigurieren

Per Default nutzt Ollama 2K Context. Für unsere Use-Cases zu wenig.

```bash
# Modelfile mit erweitertem Context
cat > Modelfile.qwen3-coder-64k <<EOF
FROM qwen3-coder:30b
PARAMETER num_ctx 65536
PARAMETER temperature 0.0
EOF

ollama create qwen3-coder-64k -f Modelfile.qwen3-coder-64k
```

64K reicht für unsere PoCs. Mehr kostet RAM und Geschwindigkeit ohne klaren Mehrwert.

---

## Phase 3: Tooling

### OpenCode installieren

```bash
npm install -g opencode-ai@latest
```

OpenCode auf lokales Ollama zeigen:
```bash
opencode auth login
# Provider: "Custom OpenAI-compatible"
# URL: http://localhost:11434/v1
# Model: qwen3-coder-64k
# API key: (leer lassen oder "ollama")
```

Verifizieren:
```bash
opencode run "Welche Dateien sind im aktuellen Verzeichnis?"
```

### Spec-Kit installieren

Vorab: `uv` installieren, falls noch nicht vorhanden:
```bash
brew install uv
```

Dann:
```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

### Docker Desktop

Installieren von der offiziellen Seite oder:
```bash
brew install --cask docker
```

Wichtige Einstellungen (Docker Desktop → Settings):
- Resources → Memory: 8 GB (nicht mehr – Modell braucht den Rest)
- Resources → CPUs: 70% deiner verfügbaren Cores
- File Sharing: nur das geplante Projekt-Verzeichnis freigeben, **nicht** das gesamte Home

### Pushover (optional, für Notifications)

- Pushover-App auf Handy installieren
- Account anlegen (~5 € einmalig)
- API-Token in einer Datei `~/.config/agent/pushover.env` speichern (Mode 600!)

```bash
mkdir -p ~/.config/agent
chmod 700 ~/.config/agent
echo "PUSHOVER_USER=dein_user_key" >> ~/.config/agent/pushover.env
echo "PUSHOVER_TOKEN=dein_app_token" >> ~/.config/agent/pushover.env
chmod 600 ~/.config/agent/pushover.env
```

---

## Phase 4: Projekt-Vorbereitung

### Projekt-Repo initialisieren

```bash
mkdir ~/agent-projects
cd ~/agent-projects
mkdir mein-erster-poc
cd mein-erster-poc
git init
specify init .
```

### Constitution-Datei (kritisch!)

Bearbeite `.specify/memory/constitution.md` mit deinen projekt-spezifischen Regeln. Dies wird vor jedem Agent-Run gelesen.

Beispiel-Template:

```markdown
# Project Constitution

## Tech Stack (verbindlich)
- Python 3.12+
- pytest für Tests
- FastAPI für Web-APIs
- Pydantic v2 für Validierung
- ruff für Linting
- black für Formatting

## Code-Stil
- Type-Hints überall, auch für interne Funktionen
- Docstrings im Google-Stil
- Maximal 50 Zeilen pro Funktion
- Maximal 300 Zeilen pro Datei

## Verbote (NON-NEGOTIABLE)
- KEIN `eval()`, `exec()`, `os.system()`, `subprocess.shell=True`
- KEINE eigenen Crypto-Implementierungen
- KEINE Klartext-Secrets im Code
- KEINE globalen Variablen außer Konstanten
- KEINE bare `except:` Klauseln

## Testing
- Mindestens 80% Coverage
- Jede public Funktion hat mindestens einen Happy-Path-Test und einen Error-Case-Test
- Test-Dateien neben Source: `module.py` → `test_module.py`

## Dependency-Regeln
- Nur Packages aus `requirements-allowed.txt` installieren
- Wenn neues Dependency nötig: in `DEPENDENCY_REQUEST.md` notieren, NICHT installieren

## Done-Kriterium
- pytest exit code 0
- ruff check exit code 0
- pre-commit run --all-files exit code 0
- README.md existiert mit Run-Instruktionen
```

### Pre-Commit-Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      - id: detect-private-key
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
      - id: ruff-format
```

Installieren:
```bash
pre-commit install
```

### Docker-Sandbox-Image bauen

```dockerfile
# Dockerfile.agent-sandbox
FROM python:3.12-slim

RUN apt-get update && apt-get install -y \
    git curl build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 agent
USER agent
WORKDIR /workspace

# Erlaubte Tools vorinstallieren
RUN pip install --user pytest ruff pre-commit

ENV PATH="/home/agent/.local/bin:${PATH}"
```

Build:
```bash
docker build -f Dockerfile.agent-sandbox -t agent-sandbox:latest .
```

### Test-Manifest

Die Datei `TEST_MANIFEST.md` definiert, wie getestet wird (du erstellst sie noch separat). Mindestens enthalten:

- Test-Framework
- Test-Verzeichnisstruktur
- Naming-Convention
- Coverage-Anforderung
- Welche Test-Kategorien existieren (unit, integration, e2e)
- Was nicht getestet werden muss (z. B. trivialer Getter/Setter)

---

## Phase 5: Orchestrator und erster Testlauf

### Verzeichnisstruktur

```
~/agent-projects/
├── orchestrator/
│   ├── run-agent.sh           # Haupt-Skript
│   ├── notify.sh              # Pushover-Hook
│   └── escalation.sh          # Bei Loop-Detection
├── projects/
│   └── mein-erster-poc/       # Pro PoC ein Verzeichnis
│       ├── .specify/
│       ├── spec.md
│       └── ...
└── logs/
    └── 2026-05-18-mein-erster-poc/
        ├── worktree-1.log
        ├── worktree-2.log
        └── worktree-3.log
```

### Erster Testlauf (manuell, im Augenzeugen-Modus)

**Vor dem ersten Overnight-Run: mindestens 10 Manual-Runs mit Beobachtung.**

Workflow:
1. Spec abends im Frontier-Modell schreiben (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`)
2. Ergebnisse als `spec.md`, `plan.md`, `tasks.md` ins Repo committen
3. Snapshot: `git tag pre-agent-$(date +%s)`
4. **Im Auge behalten**, was der Agent macht. Notizen:
   - Geht er sinnvoll vor?
   - Schreibt er Tests, die wirklich was prüfen?
   - Loopt er irgendwo?
   - Macht er gefährliche Aktionen?

Erst wenn die Erfolgsquote bei ≥6/10 liegt, ist das Setup reif für Overnight.

### Eskalations-Regel in der Constitution dokumentieren

Ergänze die Constitution:

```markdown
## Eskalations-Verhalten
Wenn nach 3 Iterationen die Tests nicht grün werden:
1. Stoppe die Implementierung
2. Schreibe `DEBUG_HYPOTHESES.md` mit:
   - Was hast du versucht?
   - Was war das Ergebnis?
   - Welche 2-3 Hypothesen hast du, warum es nicht funktioniert?
3. Beende die Session mit Exit-Code 1
```

### Resource-Limits im Sandbox

```bash
docker run \
  --cpus="2.8" \              # 70% von 4 Performance-Cores
  --memory="6g" \
  --memory-swap="6g" \        # Swap deaktivieren
  --storage-opt size=5G \     # Disk-Quota
  --network none \            # Nach Initial-Install
  --read-only \               # Filesystem read-only außer Volumes
  --tmpfs /tmp:size=500m \
  -v "$PWD:/workspace:rw" \
  -v "$HOME/.cache/pip:/home/agent/.cache/pip:ro" \
  agent-sandbox:latest \
  bash -c "opencode run --max-turns 20 < spec.md"
```

---

## Sicherheits-Checkliste vor dem ersten Overnight-Run

Bevor du den Agenten unbeaufsichtigt laufen lässt, hake jeden Punkt einzeln ab:

- [ ] `~/.ssh` ist **nicht** in den Docker-Container gemountet
- [ ] `~/.aws`, `~/.gcp`, `~/.config` sind **nicht** gemountet
- [ ] Keine `.env`-Dateien außerhalb des Projekt-Verzeichnisses zugänglich
- [ ] Docker-Container läuft mit `--network none` (nach Initial-Install)
- [ ] CPU-Limit gesetzt (≤70%)
- [ ] Disk-Quota gesetzt (≤5 GB pro Worktree)
- [ ] Git-Snapshot vor dem Run erstellt
- [ ] `max_iterations: 20` in OpenCode-Config
- [ ] Notifications funktionieren (Test-Push)
- [ ] Logs landen außerhalb des Sandbox in `~/agent-projects/logs/`
- [ ] Pre-Commit-Hooks im Projekt installiert
- [ ] Constitution.md gelesen und auf aktuelles Projekt angepasst
- [ ] Test-Manifest existiert und ist in der Constitution referenziert

---

## Häufige Fehler und Pitfalls

### "Modell läuft, aber Tool-Calling funktioniert nicht"
Symptom: Agent chattet nur, ruft keine Tools auf.
Ursache: Modell-Template oder Ollama-Version stimmt nicht. Falsche Quantisierung.
Lösung: Anderes Modell testen (`carnice-moe:35b`), Ollama auf aktuellste Version, Tool-Calling-Test aus Phase 2 wiederholen.

### "Agent installiert wilde Dependencies"
Symptom: Morgens findest du seltsame Pakete in der `requirements.txt`.
Ursache: Constitution enthält keine Dependency-Regel oder der Agent ignoriert sie.
Lösung: Dependency-Whitelist in Constitution, Sandbox nach Initial-Install auf `--network none` zwingen.

### "Tests sind grün, aber Code funktioniert nicht"
Symptom: "Fake green" – Tests prüfen das Falsche.
Ursache: Lokales Modell hat Test-Logik so geschrieben, dass sie immer durchgeht.
Lösung: Test-Review-Routine am Morgen. Optional: Mutation-Testing-Tool in den Workflow.

### "Mac ist morgens heiß und alles langsam"
Symptom: Throttling, Lüfter Vollgas, System langsam.
Ursache: Zu hohe Last über zu lange Zeit.
Lösung: CPU-Limit weiter senken (60%), Lüfter-Profil anpassen, ggf. nur 2 statt 3 Worktrees parallel.

### "Worktrees blockieren sich gegenseitig"
Symptom: Mehrere Agenten greifen auf dieselbe Datei zu, Race-Conditions.
Ursache: Worktrees teilen `.git/` aber sollten getrennte Working-Trees haben.
Lösung: Bei `git worktree add` sicherstellen, dass jeder Worktree in seinem eigenen Branch arbeitet.

### "Spec-Kit-Output passt nicht zum lokalen Modell"
Symptom: Frontier-Modell schreibt eine Spec, die viel komplexer ist als das lokale Modell umsetzen kann.
Ursache: Spec-Phase nimmt zu viel auf einmal.
Lösung: In der Spec-Phase explizit als Constraint angeben: "Implementation erfolgt durch ein lokales 30B-Modell, halte den Scope klein."

---

## Wartung und Iteration

### Wöchentlich
- Logs der Woche durchsehen: wo scheitert der Agent typisch?
- Constitution anpassen, wenn wiederholte Probleme auftreten
- `requirements-allowed.txt` aktualisieren, wenn neue legitime Bedürfnisse auftauchen

### Monatlich
- Modell-Update prüfen (`ollama pull qwen3-coder:30b`)
- Spec-Kit Update prüfen
- Erfolgsquote auswerten: läuft das System noch wie geplant?

### Bei Major-Updates
- Modell-Wechsel oder neue Quantisierung: zuerst 10 Manual-Runs zur Verifikation
- Bevor du einer neuen Modell-Version Overnight-Vertrauen schenkst

---

## Was als Nächstes?

Wenn das Basis-Setup nach 30 Tagen läuft, mögliche Erweiterungen:

- **Mutation Testing** gegen Fake-Green-Tests (mutmut, cosmic-ray)
- **Diff-Summary durch lokales Modell** am Run-Ende
- **Hermes Agent** obenauf, falls du mit deinem Agent über Telegram chatten willst
- **Spezialisierte Modelle** für Spezial-Tasks (z. B. Frontend-fokussiertes Modell für UI-PoCs)
- **CI-Integration:** Erfolgreiche PoCs automatisch in einen Schaukasten-Repo pushen
