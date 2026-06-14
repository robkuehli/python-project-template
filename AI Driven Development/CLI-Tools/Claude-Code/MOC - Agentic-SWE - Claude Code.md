---
title: "Claude Code — Übersicht"
last_verified: 2026-05-21
status: current
tags:
  - claude-code
  - cli-tools
  - index
---

# Claude Code

Dieser Ordner beschreibt meine produktive Claude-Code-Nutzung — vom Setup über die Profile bis zum täglichen Workflow. **Strukturell parallel zum [[MOC - Agentic-SWE - OpenCode|OpenCode-Ordner]]**, aber an die Mechanik von Claude Code angepasst (kein Provider-agnostischer Multi-Model-Layer wie OpenCode; stattdessen Anthropic-Modelle über den firmenseitigen **LiteLLM-Proxy → AWS Bedrock**).

Claude Code ist Anthropics terminal-natives Coding-Agent-CLI. Zentrale Mechaniken, die dieses Setup nutzt: **Plan Mode** (read-only Architect-Sitz), **Subagents** (kontext-isolierte Spezialisten in `~/.claude/agents/`), **Hooks** (Lifecycle-Automatisierung), **Skills** (cross-tool, geteilt mit OpenCode) und **Permissions** (allow/ask/deny in `settings.json`).

## Inhaltsverzeichnis

1. [[Claude Code — Setup-Manual]] — Installation, LiteLLM→Bedrock-Auth, Profile, Subagent-Install, Skill-Symlink, Validierung
2. [[Claude Code — Best Practices]] — Pattern, Mechaniken (Plan Mode, Subagents, Hooks), Pitfalls, Sicherheit
3. [claude-config/](./claude-config/) — Globale Defaults: `CLAUDE.md`, `settings.json`, `LEARNINGS.md`, Hooks
4. [[Claude Code — Profil-Spezifikationen]] — Anwendungsfall, Constraint, Modell pro Subagent für alle drei Profile
5. [Profile-Configs/](./Profile-Configs/) — Eine `settings-*.json` pro Profil (Balanced, SOTA, DSGVO)
6. [Agents/](./Agents/) — Subagent-Definitionen (`researcher`, `reviewer`, `security-auditor`)
7. [[Claude Code — Täglicher Workflow]] — Daily Routine: Plan-Mode/Default, Subagent-Delegation, Verify, Wissens-Capture
8. [[Claude Code — Open Issues & TODOs]] — **zentrale** Sammelstelle aller offenen Punkte (Modell-IDs, DSGVO, Hook-Härtung, Setup)

## Profile auf einen Blick

Drei Profile decken die Anthropic-via-Bedrock-Konstellationen ab. **Ollama/Open-Weight ist bewusst nicht enthalten** — Claude Code ist Anthropic-zentrisch; für lokale/Open-Weight-Modelle ist OpenCode das Werkzeug (siehe [[MOC - Agentic-SWE - OpenCode]]).

| Profil | Anwendungsfall | Default-Modell | Routing |
|---|---|---|---|
| **Balanced** | Standard-Arbeitstag, kostenbewusst | Claude Sonnet 4.6 | LiteLLM → Bedrock |
| **SOTA** | Komplexe Architektur, schwieriges Debugging, kritisches Review | Claude Opus 4.7 | LiteLLM → Bedrock |
| **DSGVO** | Kundenprojekte mit EU-Datenschutz | Claude Sonnet 4.6 (Bedrock EU) | LiteLLM → Bedrock `eu-central-1` |

Aktivierung im Alltag über Shell-Aliase (`cc`, `cc-sota`, `cc-dsgvo`) — Details: [[Claude Code — Setup-Manual]] §5.

## Die drei Achsen in Claude Code

Der Workflow lebt auf denselben drei orthogonalen Achsen wie bei OpenCode ([[Developer Workflow]]), nur anders besetzt:

| Achse | Frage | In Claude Code | Merkfläche |
|---|---|---|---|
| **Skills** | *Was* tue ich? | `Skills/*/SKILL.md` (cross-tool, via Symlink in `~/.claude/skills/`) | 8 Verben: explore · spec · plan · test · delegate · review · debug · capture |
| **Modes** | *Wo* sitze ich? | **Plan Mode** (read-only, `Shift+Tab`) = Architect · **Default** = Coder | 2 Modes (Tastatur-Toggle) |
| **Subagents** | *Wie/womit* wird ausgeführt? | 3 Subagents in `~/.claude/agents/` | — auto-delegiert — |

> **Unterschied zu OpenCode:** OpenCode besetzt den Architect/Coder-Split mit zwei *Custom Primary Agents* (`plan`/`build`). Claude Code hat **keine** Custom-Primaries — der Split wird durch den eingebauten **Plan Mode** (Architect, read-only) und den **Default-Agent** (Coder) abgebildet. Es gibt daher keine `Primary/`-Agent-Dateien; nur Subagents sind Dateien. Details: [Agents/README](./Agents/README.md).

## Rollen-Mapping (tool-agnostisch → Claude Code)

| Rolle | Aufgabe | Claude Code | Skills |
|---|---|---|---|
| **Architect** | Plant, spezifiziert, reviewed. Implementiert nie. | **Plan Mode** (`Shift+Tab`) | explore, spec, plan, review |
| **Coder** | Implementiert strikt nach Spec. | **Default-Agent** | test, delegate, debug |
| **Explorer** | Read-only Codebase-Analyse, kontext-isoliert. | `researcher`-Subagent (auch: Built-in `Explore`) | explore |
| **Scribe** | Sichert Learnings. | — kein stehender Agent — `/capture`-Skill + `SessionEnd`-Hook | capture |

On-demand gespawnt: `reviewer` (unabhängiges read-only-Review) und `security-auditor` (Spezial-Checkliste, v.a. autonomer Modus).

## Beziehung zu anderen Ordnern

- **`../OpenCode/`** — Pendant für den Open-Source-Orchestrator. Strukturell parallel; Skills und Guidelines sind geteilt.
- **`../../Skills/`** — Cross-Tool-Skill-Sammlung, via Symlink in `~/.claude/skills/` eingebunden.
- **`../../Guidelines/`** — Stack-unabhängige Engineering-Regeln, referenziert aus `claude-config/CLAUDE.md`.
- **`../../Autonomer Coding Agent/`** — Lokaler Coding-Daemon; Claude Code ist eine der Eskalations-Zielumgebungen.
- **[[Anforderungen an das CLI-Tool]]** — die Anforderungen, gegen die beide Tools bewertet werden.
