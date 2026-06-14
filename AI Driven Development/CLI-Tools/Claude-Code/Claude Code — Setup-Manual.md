---
title: "Claude Code — Setup-Manual"
last_verified: 2026-05-21
status: current
sources:
  - https://code.claude.com/docs/en/settings
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/amazon-bedrock
  - https://code.claude.com/docs/en/llm-gateway
  - https://code.claude.com/docs/en/model-config
  - https://docs.litellm.ai/docs/tutorials/claude_responses_api
tags:
  - claude-code
  - setup
---

# Claude Code — Setup-Manual

Schritt-für-Schritt-Anleitung, um Claude Code mit allen drei Profilen produktiv zu nutzen. Vorausgesetzt wird ein macOS-Setup, Node 20+ und Zugriff auf den firmenseitigen **LiteLLM-Proxy**, der Anthropic-Modelle über **AWS Bedrock** ausliefert.

Pendant zu [[OpenCode — Setup-Manual]]. Wo OpenCode mehrere Provider über `opencode.json` registriert, bezieht Claude Code seine Modelle ausschließlich über die Anthropic-API-Form — hier über den LiteLLM-Gateway, der zu Bedrock übersetzt.

---

## 1. Installation

```bash
npm install -g @anthropic-ai/claude-code
claude --version   # erwartet: >= 2.1.x (Mai 2026)
```

Updates laufen über denselben Befehl. Bei Major-Updates die [Release-Notes](https://github.com/anthropics/claude-code/releases) prüfen. Bedrock-bezogene Features (z.B. Mantle, Startup-Model-Checks) brauchen mindestens v2.1.94.

---

## 2. Provider-Anbindung: LiteLLM → Bedrock

Claude Code spricht nur die **Anthropic-API-Form**. Es gibt zwei saubere Wege, darüber Bedrock-Modelle zu beziehen:

### Weg A (empfohlen): LiteLLM als Anthropic-kompatibler Gateway

Der firmenseitige LiteLLM-Proxy stellt einen `/v1/messages`-Endpunkt bereit und routet intern auf Bedrock. Claude Code zeigt per `ANTHROPIC_BASE_URL` dorthin:

```bash
# ~/.zshrc (bzw. ~/.zprofile für Login-Shells)

# LiteLLM-Gateway (firmenseitig, übersetzt Anthropic → Bedrock)
export ANTHROPIC_BASE_URL="https://litellm.internal.example.com"
export ANTHROPIC_AUTH_TOKEN="sk-litellm-..."     # LiteLLM Virtual Key (NICHT committen)

# Alias-Auflösung: was sonnet/opus/haiku auf dem Gateway bedeuten.
# Müssen mit den Modell-Namen im Firmen-LiteLLM (model_list) übereinstimmen.
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-7"
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-6"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5"

# Gateway-Hygiene
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
# Falls LiteLLM→Bedrock an Anthropic-spezifischen Beta-Headern scheitert:
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"
```

> **Wichtig:** Bei einem Nicht-Anthropic-Host hinter `ANTHROPIC_BASE_URL` sind manche Features eingeschränkt (z.B. bestimmte Beta-Header). Den Token niemals in eine committed Datei schreiben — immer aus der Shell-Env beziehen.

### Weg B (Alternative): Bedrock direkt

Wenn der LiteLLM-Proxy einen reinen Bedrock-Passthrough anbietet (oder du direkt mit AWS-Credentials arbeitest):

```bash
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="eu-central-1"                 # Pflicht; wird NICHT aus ~/.aws gelesen
export ANTHROPIC_BEDROCK_BASE_URL="https://litellm.internal.example.com"  # optional: LiteLLM als Bedrock-Gateway

# Modell-Pinning (cross-region inference profiles). EU = eu.-Präfix.
export ANTHROPIC_DEFAULT_OPUS_MODEL="eu.anthropic.claude-opus-4-7"
export ANTHROPIC_DEFAULT_SONNET_MODEL="eu.anthropic.claude-sonnet-4-6"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="eu.anthropic.claude-haiku-4-5-20251001-v1:0"
```

Bei Bedrock sind `/login`/`/logout` deaktiviert (Auth läuft über AWS-Credentials bzw. den Gateway). Für SSO-Refresh: `awsAuthRefresh` in `settings.json` (siehe [Amazon-Bedrock-Doc](https://code.claude.com/docs/en/amazon-bedrock)).

> **Dieses Setup nutzt Weg A** als Default und reserviert die `eu.`-Bedrock-IDs aus Weg B für das DSGVO-Profil ([[Claude Code — Profil-Spezifikationen]]). Welche der beiden Spuren der Firmen-LiteLLM erwartet, mit dem Maintainer klären — siehe [[Claude Code — Open Issues & TODOs]] §B.

---

## 3. Verzeichnis-Layout anlegen

```bash
mkdir -p ~/.claude/{agents,hooks,profiles}

# Globale Files — Inhalte siehe claude-config/ in diesem Ordner
touch ~/.claude/{CLAUDE.md,settings.json,LEARNINGS.md,LEARNINGS.inbox.md}
```

Die Soll-Struktur:

```
~/.claude/
├── settings.json                # Default-Profil (= Balanced); Provider-env, Permissions, Hooks
├── CLAUDE.md                    # Globale Instruktionen (lädt LEARNINGS.md via @-Import)
├── LEARNINGS.md                 # Self-Improvement Loop (kanonisch, im Kontext)
├── LEARNINGS.inbox.md           # Staging-Puffer für Learning-Vorschläge (nicht im Kontext)
├── statusline-command.sh        # optional: Statusline-Skript (von settings.json referenziert)
├── agents/                      # Subagents: researcher, reviewer, security-auditor
├── hooks/                       # capture-learnings.sh, surface-inbox.sh
├── profiles/                    # settings-sota.json, settings-dsgvo.json (Overlays)
└── skills/                      # Symlink → zentraler Skills/-Ordner
```

---

## 4. Globale `settings.json` (Default-Profil = Balanced)

Den vollständigen Inhalt findest du in [`claude-config/settings.json`](./claude-config/settings.json). Kopieren nach `~/.claude/`:

```bash
cp "./claude-config/settings.json"        ~/.claude/settings.json
cp "./claude-config/CLAUDE.md"            ~/.claude/CLAUDE.md
cp "./claude-config/LEARNINGS.md"         ~/.claude/LEARNINGS.md
cp "./claude-config/LEARNINGS.inbox.md"   ~/.claude/LEARNINGS.inbox.md
cp "./claude-config/hooks/"*.sh           ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

`settings.json` enthält die Balanced-Defaults: `model: "sonnet"`, `effortLevel: "high"`, die `env`-Provider-Variablen (sofern nicht in `~/.zshrc`), Permissions (allow/ask/deny) und die Hook-Registrierungen.

---

## 5. Profil-Configs anlegen

Profile sind **Settings-Overlays**, die per `--settings`-Flag geladen werden und die globale `settings.json` mit höherer Präzedenz überschreiben. Inhalte: [`Profile-Configs/`](./Profile-Configs/).

```bash
cp ./Profile-Configs/settings-sota.json   ~/.claude/profiles/
cp ./Profile-Configs/settings-dsgvo.json  ~/.claude/profiles/
```

Shell-Aliase in `~/.zshrc`:

```bash
# Claude Code Profile
alias cc='claude'                                                  # Balanced (globale settings.json)
alias cc-sota='claude --settings ~/.claude/profiles/settings-sota.json'
alias cc-dsgvo='ANTHROPIC_AUTH_TOKEN="$LITELLM_EU_KEY" claude --settings ~/.claude/profiles/settings-dsgvo.json'
```

Das DSGVO-Profil setzt zusätzlich den EU-gebundenen LiteLLM-Key inline (aus `~/.zshrc`-Variable `LITELLM_EU_KEY`), damit das Routing garantiert auf Bedrock EU zeigt.

> **Alternative für volle Isolation:** Statt `--settings`-Overlays kann jedes Profil ein eigenes `CLAUDE_CONFIG_DIR` bekommen (`CLAUDE_CONFIG_DIR=~/.claude-dsgvo claude`) — eigener Settings-, Agents-, Hooks- und Credential-Satz. Schwerer zu warten (Agents/Hooks dupliziert), aber maximale Trennung. Für DSGVO-Kundentrennung erwägenswert; im Alltag reichen `--settings`-Overlays. Siehe [[Claude Code — Profil-Spezifikationen]].

---

## 6. Subagents installieren

Claude Code entdeckt Subagents als Markdown-Dateien (YAML-Frontmatter + System-Prompt-Body) in `~/.claude/agents/` (User-Scope) bzw. `.claude/agents/` (Projekt-Scope, höhere Präzedenz).

```bash
cp ./Agents/researcher.md        ~/.claude/agents/
cp ./Agents/reviewer.md          ~/.claude/agents/
cp ./Agents/security-auditor.md  ~/.claude/agents/
```

Verifikation in einer Claude-Code-Session:

```
/agents
```

Erwartet im **Library**-Tab: `researcher`, `reviewer`, `security-auditor` (plus Built-ins `Explore`, `Plan`, `general-purpose`).

> **Kein `Primary/`-Ordner:** Architect/Coder werden in Claude Code nicht durch Custom-Agents, sondern durch **Plan Mode** (read-only) und den **Default-Agent** abgebildet. Siehe [Agents/README](./Agents/README.md). Dateien auf Platte werden erst nach Session-Neustart geladen; über `/agents` erstellte Agents sofort.

---

## 7. Skill-Symlink (Cross-Tool)

Die zentrale Skill-Sammlung wird einmalig für Claude Code sichtbar gemacht (dieselben Skills, die OpenCode und Codex lesen):

```bash
SKILLS_DIR="/Users/rkuehling/Library/Mobile Documents/iCloud~md~obsidian/Documents/Dev-Zettelkasten/Docs/AI Driven Development/Skills"

mkdir -p ~/.claude
ln -sfn "$SKILLS_DIR" ~/.claude/skills
```

Claude Code entdeckt Skills in `~/.claude/skills/` (global) und `.claude/skills/` (projekt-lokal). Helfer-Skills aus `anthropics/skills` (z.B. `skill-creator`) bei Bedarf **projekt-lokal** symlinken, nicht global — siehe [[Claude Code — Best Practices]] §6.

---

## 8. Pro-Projekt-Setup (Repo-lokal)

```bash
# Im Repo-Root
touch CLAUDE.md            # Projekt-Konventionen (commit, Team-weit)
touch CLAUDE.local.md      # Persönliche Notizen (gitignored)
echo "CLAUDE.local.md" >> .gitignore

mkdir -p .claude/agents .claude/commands   # optional: Projekt-Subagents & Slash-Commands
touch .mcp.json            # optional: Projekt-MCP-Server (committed)
```

Claude Code lädt die Memory-Hierarchie automatisch: `~/.claude/CLAUDE.md` → `./CLAUDE.md` (vom CWD aufwärts) → `./CLAUDE.local.md`. Projekt-`./CLAUDE.md` überschreibt globale Defaults; stack-spezifische Konventionen (ruff-Regeln, dbt-Struktur) gehören hierhin.

---

## 9. Validierung

Nach dem Setup folgendes durchspielen:

```bash
# 1. Claude Code startet und nutzt das Default-Profil
cc
> /status
# erwartet: Provider-Zeile zeigt den LiteLLM-Endpoint; Modell = Sonnet 4.6

# 2. Profil-Wechsel ändert das Modell
cc-sota
> /status
# erwartet: Modell = Opus 4.7

# 3. Subagent-Discovery
> /agents
# erwartet: researcher, reviewer, security-auditor sichtbar

# 4. Subagent-Spawn (Kontext-Isolation)
> Use the researcher subagent to map where DATABASE_URL is read in this repo.
# erwartet: researcher läuft read-only, liefert kompakte Zusammenfassung

# 5. Plan Mode (Architect-Sitz)
> [Shift+Tab bis "plan mode on"] Entwirf eine Spec für einen idempotenten Upsert in dim_customer.
# erwartet: read-only Plan, keine Edits

# 6. Skill-Discovery
> Welche Skills sind verfügbar?
# erwartet: explore, spec, plan, test, delegate, review, debug, capture

# 7. Hook: Secret-Schutz greift
> Lies die Datei .env
# erwartet: durch permissions.deny blockiert
```

Sind 1–3, 6 und 7 grün, ist das Kernkonzept validiert. 4 und 5 zeigen, dass Delegation und Plan-Mode korrekt arbeiten.

---

## 10. Häufige Stolperfallen

| Problem | Ursache | Fix |
|---|---|---|
| `claude: command not found` | npm-Global-Bin nicht im `$PATH` | `echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.zshrc` |
| Alle Anfragen schlagen mit 4xx fehl | Beta-Header an Bedrock via LiteLLM | `export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` |
| `sonnet`/`opus`/`haiku` zeigen auf falsches Modell | `ANTHROPIC_DEFAULT_*_MODEL` nicht gesetzt / falscher Alias | env-Variablen gegen Firmen-LiteLLM `model_list` abgleichen |
| Profil-Wechsel hat keinen Effekt | `--settings`-Pfad falsch oder env überschreibt Settings | `cc-sota` → `/status` prüfen; env-Vars haben Vorrang vor `settings.json` |
| DSGVO-Anfrage läuft über US-Region | falscher LiteLLM-Key / kein `eu.`-Alias | `LITELLM_EU_KEY` + EU-Aliase im DSGVO-Profil verifizieren (§B Open Issues) |
| Subagent wird nicht gefunden | Datei nach Session-Start abgelegt | Session neu starten oder Agent über `/agents` anlegen |
| `AGENTS.md`/`CLAUDE.md` wird ignoriert | Datei außerhalb der Memory-Hierarchie | im Repo-Root ablegen oder per `@pfad` einbinden |
| Hook formatiert nicht | Inline-Hook nutzt falschen Input-Mechanismus | Hooks lesen JSON über **stdin** (`.tool_input.file_path`), nicht über Env-Vars — siehe [[Claude Code — Best Practices]] §3 |

---

## Querverweise

- [[Claude Code — Best Practices]] — Pattern, Mechaniken, Sicherheit
- [[Claude Code — Profil-Spezifikationen]] — Modellwahl pro Profil und Subagent begründet
- [`claude-config/`](./claude-config/) — Inhalte für globale Defaults
- [`Profile-Configs/`](./Profile-Configs/) — Inhalte für die drei Profile
- `../../Autonomer Coding Agent/04-escalation.md` — Eskalation lokal → Cloud
