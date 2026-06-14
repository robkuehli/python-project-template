---
title: "OpenCode — Setup-Manual"
last_verified: 2026-05-20
status: current
sources:
  - https://opencode.ai/docs/
  - https://opencode.ai/docs/config/
  - https://opencode.ai/docs/agents/
  - https://opencode.ai/docs/providers/
  - https://docs.litellm.ai/docs/tutorials/opencode_integration
tags:
  - opencode
  - setup
---

# OpenCode — Setup-Manual

Schritt-für-Schritt-Anleitung, um OpenCode mit allen vier Profilen produktiv zu nutzen. Vorausgesetzt wird ein macOS-Setup, Homebrew, Node 20+ und ein aktiver LiteLLM-Endpunkt.

---

## 1. Installation

OpenCode wird als Node-Paket verteilt. Globale Installation:

```bash
npm install -g opencode-ai@latest
opencode --version   # erwartet: >= 0.x (Mai 2026)
```

Updates laufen über denselben Befehl. Bei Major-Updates die [Release-Notes](https://github.com/anomalyco/opencode/releases) prüfen — der Config-Schema kann Breaking Changes haben.

### Ollama (für Profile DSGVO + Ollama)

```bash
brew install ollama
brew services start ollama          # Daemon dauerhaft im Hintergrund

# Lokale Basismodelle ziehen
ollama pull qwen3-coder:30b         # Default-Coder, ca. 18 GB
ollama pull llama3.2:3b             # small_model + scribe-Tasks
ollama pull deepseek-r1:14b         # Optional: Reasoning lokal

# Ollama Cloud aktivieren (Account auf ollama.com nötig)
ollama signin
export OLLAMA_API_KEY="<dein-key>"  # in ~/.zshrc persistieren
```

Cloud-Modelle behält der gleiche Daemon, das `:cloud`-Suffix entscheidet, wohin geroutet wird.

---

## 2. Verzeichnis-Layout anlegen

```bash
mkdir -p ~/.config/opencode/{configs,agent}

# Globale Files anlegen — Inhalte siehe Config-Files/ in diesem Ordner
touch ~/.config/opencode/{AGENTS.md,LEARNINGS.md,opencode.json}
```

Die Soll-Struktur:

```
~/.config/opencode/
├── opencode.json                # Default-Profil (= Balanced)
├── AGENTS.md                    # Globale Instruktionen
├── LEARNINGS.md                 # Self-Improvement Loop (kanonisch)
├── LEARNINGS.inbox.md           # Staging-Puffer für Learning-Vorschläge (nicht im Kontext)
├── configs/
│   ├── opencode-balanced.json
│   ├── opencode-sota.json
│   ├── opencode-dsgvo.json
│   └── opencode-ollama.json
├── agent/                       # Alle Agents flach: build, plan, researcher, reviewer, security-auditor (OpenCode-Discovery-Pfad)
├── plugin/                      # Plugin: learnings-and-guards.ts (capture + ruff + bash-guard)
└── skills/                      # Symlink → zentraler Skills/-Ordner
```

> Hinweis: OpenCode entdeckt Agents standardmäßig **flach** unter `~/.config/opencode/agent/` (Singular). Im Repo sind sie aus Ordnungsgründen in `Agents/Primary/` und `Agents/Subagents/` getrennt; beim Install werden beide Unterordner **flach** nach `agent/` kopiert (kein Symlink) — siehe Abschnitt 6.

---

## 3. Auth & Secrets

Drei Env-Variablen in `~/.zshrc` (bzw. `~/.bashrc`) eintragen:

```bash
# Firmen-LiteLLM (Cloud-Modelle via Proxy)
export LITELLM_API_KEY="sk-..."
export LITELLM_BASE_URL="https://litellm.internal.example.com/v1"

# Ollama Cloud (optional, nur für :cloud-Modelle)
export OLLAMA_API_KEY="..."
```

`LITELLM_BASE_URL` ist nur lesbar, falls die Configs ihn referenzieren — wir setzen die URL aber primär in den `opencode.json`-Files unter `provider.litellm.baseURL`. Die Env-Var bleibt als Override-Möglichkeit.

**Wichtig:** Secrets nie in `opencode.json` committen — immer über `{env:VARNAME}`-Platzhalter referenzieren.

---

## 4. Globale `opencode.json` (Default-Profil)

Default-Profil ist Balanced. Den vollständigen Inhalt findest du in [`Config-Files/opencode.json`](./Config-Files/opencode.json). Kopieren nach:

```bash
cp ./Config-Files/opencode.json ~/.config/opencode/opencode.json
cp ./Config-Files/AGENTS.md     ~/.config/opencode/AGENTS.md
cp ./Config-Files/LEARNINGS.md  ~/.config/opencode/LEARNINGS.md
```

---

## 5. Profil-Configs anlegen

```bash
cp ./Profile-Configs/opencode-balanced.json ~/.config/opencode/configs/
cp ./Profile-Configs/opencode-sota.json     ~/.config/opencode/configs/
cp ./Profile-Configs/opencode-dsgvo.json    ~/.config/opencode/configs/
cp ./Profile-Configs/opencode-ollama.json   ~/.config/opencode/configs/
```

Shell-Aliase in `~/.zshrc`:

```bash
# OpenCode Profile
alias oc='OPENCODE_CONFIG=~/.config/opencode/configs/opencode-balanced.json opencode'
alias oc-sota='OPENCODE_CONFIG=~/.config/opencode/configs/opencode-sota.json opencode'
alias oc-dsgvo='OPENCODE_CONFIG=~/.config/opencode/configs/opencode-dsgvo.json opencode'
alias oc-ollama='OPENCODE_CONFIG=~/.config/opencode/configs/opencode-ollama.json opencode'
```

Nach `source ~/.zshrc` (oder neuem Terminal) sind die Aliase aktiv.

---

## 6. Agents installieren

OpenCode entdeckt Agents in `~/.config/opencode/agent/` (Markdown mit YAML-Frontmatter, Dateiname = Agent-ID).

Primary Agents (`mode: primary`) und Subagents (`mode: subagent`) landen alle in einem flachen Ordner. In diesem Repo trennen wir aus Ordnungsgründen auf `Agents/Primary/` und `Agents/Subagents/`. Beim Install kopieren wir flach zusammen:

```bash
mkdir -p ~/.config/opencode/agent
cp ./Agents/Primary/*.md     ~/.config/opencode/agent/
cp ./Agents/Subagents/*.md   ~/.config/opencode/agent/
```

Verifikation:

```bash
opencode agents list
# erwartet: build, plan, reviewer, researcher, security-auditor
```

---

## 7. Skill-Symlink (Cross-Tool)

Die zentrale Skill-Sammlung im Workspace wird einmalig für OpenCode (und parallel für Claude Code, Codex) sichtbar gemacht:

```bash
SKILLS_DIR="/Users/rkuehling/Library/Mobile Documents/iCloud~md~obsidian/Documents/Dev-Zettelkasten/Docs/AI Driven Development/Skills"

# OpenCode
mkdir -p ~/.config/opencode
ln -sfn "$SKILLS_DIR" ~/.config/opencode/skills

# Cross-Tool: Claude Code + Codex (OpenCode liest beide Pfade ebenfalls)
mkdir -p ~/.claude ~/.agents
ln -sfn "$SKILLS_DIR" ~/.claude/skills
ln -sfn "$SKILLS_DIR" ~/.agents/skills
```

---

## 8. Pro-Projekt-Setup (Repo-lokal)

Für jedes Projekt, das eigene Konventionen hat:

```bash
# Im Repo-Root
touch AGENTS.md         # Projekt-Konventionen (commit)
touch AGENTS.local.md   # Persönliche Notizen (gitignored)
echo "AGENTS.local.md" >> .gitignore

# Optional: Projekt-spezifische Config
touch opencode.json     # nur wenn Projekt von globalen Defaults abweicht
```

OpenCode lädt `AGENTS.md` und `AGENTS.local.md` im Repo-Root automatisch. Die globalen `AGENTS.md` / `LEARNINGS.md` werden über `instructions: ["AGENTS.md", "LEARNINGS.md"]` in `~/.config/opencode/opencode.json` referenziert und gemerged.

---

## 9. Validierung

Nach dem Setup folgendes durchspielen:

```bash
# 1. OpenCode startet und sieht das Default-Profil
oc run "Welches Modell antwortet hier?"
# erwartet: Claude Sonnet 4.6 (Balanced-Default)

# 2. Profil-Wechsel ändert das Modell
oc-sota run "Welches Modell antwortet hier?"
# erwartet: Claude Opus 4.7

# 3. Lokales Ollama läuft
oc-ollama run "Welches Modell antwortet hier?"
# erwartet: Ollama-Modell (z.B. qwen3-coder oder gpt-oss:120b:cloud je nach Config)

# 4. EU-Profil
oc-dsgvo run "Welches Modell antwortet hier?"
# erwartet: Bedrock Claude EU oder Azure GPT EU

# 5. Per-Agent-Modell
oc run --agent plan "Welches Modell?"
oc run --agent build "Welches Modell?"
# erwartet: zwei unterschiedliche Modelle in derselben Profil-Config

# 6. Subagent-Spawn
oc run "Spawn the reviewer subagent and ask it which model it is."
# erwartet: reviewer-Subagent antwortet mit seinem Modell

# 7. Skill-Discovery
oc run "Liste alle verfügbaren Skills."
# erwartet: explore, spec, plan, test, delegate, review, debug, capture
```

Wenn 1–4 und 7 grün sind, ist das Kernkonzept validiert. 5 und 6 sind „nice to have" — ohne sie funktioniert das Setup, ist aber nicht voll ausgeschöpft.

---

## 10. Häufige Stolperfallen

| Problem | Ursache | Fix |
|---|---|---|
| `opencode: command not found` nach Install | npm-Global-Bin nicht in `$PATH` | `echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.zshrc` |
| Profil-Wechsel hat keinen Effekt | `OPENCODE_CONFIG` nicht exportiert | Alias-Definition prüfen: muss `OPENCODE_CONFIG=… opencode` (inline-Env), nicht `export …` davor |
| `LITELLM_API_KEY` wird nicht erkannt | Env-Var nicht in Login-Shell | In `~/.zprofile` statt `~/.zshrc` setzen (oder neue Terminal-Session öffnen) |
| Ollama-Cloud-Modelle ohne Auth | `OLLAMA_API_KEY` fehlt oder `ollama signin` nicht ausgeführt | beides nachholen |
| Agent wird nicht gefunden | Datei in `~/.config/opencode/agent/` statt `agents/` (oder umgekehrt) | OpenCode-Version prüfen — Schema hat zwischen 0.x-Versionen gewechselt; `opencode agents list` zeigt den erwarteten Pfad |
| AGENTS.md wird nicht geladen | Nicht in `instructions:` der aktiven Config eingetragen | Eintrag in `opencode.json` ergänzen oder Repo-AGENTS.md direkt im Projekt-Root ablegen |

---

## Querverweise

- [[OpenCode — Best Practices]] — Pattern und Anti-Pattern im Alltag
- [[OpenCode — Profil-Spezifikationen]] — Modell-Wahl pro Profil und Sub-Agent begründet
- [`Config-Files/`](./Config-Files/) — Inhalte für globale Defaults
- [`Profile-Configs/`](./Profile-Configs/) — Inhalte für die vier Profile
