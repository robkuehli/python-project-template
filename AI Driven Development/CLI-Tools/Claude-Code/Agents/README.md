---
title: "Agents — Claude Code Subagents"
last_verified: 2026-05-21
status: current
sources:
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/permission-modes
tags:
  - claude-code
  - agents
---

# Agents

Subagents für Claude Code. Jede Datei = ein Subagent, Konfiguration im YAML-Frontmatter, System-Prompt im Body. Pendant zum OpenCode-[`Agents/`](../../OpenCode/Agents/README.md)-Ordner — aber **nur Subagents**, kein `Primary/`.

## Warum kein `Primary/`-Ordner?

OpenCode besetzt den Architect/Coder-Split mit zwei **Custom Primary Agents** (`plan`/`build`), in die man per Tab wechselt. **Claude Code hat dieses Konzept nicht.** Der Split wird durch Bordmittel abgebildet:

| Rolle | Claude Code | Mechanik |
|---|---|---|
| **Architect** | **Plan Mode** | `Shift+Tab` toggelt read-only Plan Mode; Claude darf erkunden + planen, nichts schreiben. Recherche delegiert intern an den Built-in `Plan`-Subagent. |
| **Coder** | **Default-Agent** | der normale Claude-Code-Thread mit vollem Tool-Zugriff. |

Deshalb gibt es hier keine `architect.md`/`coder.md`. Ein Custom-Agent für „Coder" wäre nur über `claude --agent` als *Haupt-Thread-Ersatz* möglich — das überschreibt aber den kompletten System-Prompt und ist für den Alltag unnötig. Plan Mode + Default decken Architect + Coder vollständig ab.

> **Modell-Steuerung der Modes:** Plan Mode und Default teilen sich das aktive Modell. SOTA-Architektur = Plan Mode auf Opus; Routine-Coding = Default auf Sonnet. Wechsel per `/model` oder Profil. Siehe [[Claude Code — Profil-Spezifikationen]].

## Drei Achsen — Skills, Modes, Subagents

Identisch zum tool-agnostischen Modell aus [[Developer Workflow]], nur in Claude Code besetzt:

| Achse | Frage | Artefakt | Merkfläche |
|---|---|---|---|
| **Skills** | *Was* tue ich? | `Skills/*/SKILL.md` (cross-tool) | 8 Verben |
| **Modes** | *Wo* sitze ich? | Plan Mode / Default | 2 (Tastatur-Toggle) |
| **Subagents** | *Wie/womit* wird ausgeführt? | 3 Dateien hier | — auto-delegiert — |

## Struktur in diesem Ordner

```
Agents/
├── README.md              ← diese Datei
├── researcher.md          Explorer — Codebase-Recon, read-only, Haiku, kontext-isoliert
├── reviewer.md            Unabhängiges Code-Review gegen Spec (read-only, inherit)
└── security-auditor.md    Secrets, Injection, Permission-Checks (read-only, inherit)
```

Beim Install flach nach `~/.claude/agents/` kopieren ([[Claude Code — Setup-Manual]] §6). Projekt-spezifische Subagents kommen nach `.claude/agents/` (höhere Präzedenz).

> **Auswahl-Prinzip (verschlankt, Mai 2026):** Ein Subagent existiert nur bei echtem Mehrwert ggü. dem Haupt-Thread — **Kontext-Isolation** (`researcher`), **unabhängige read-only-Zweitmeinung** (`reviewer`), oder **distinkte Spezial-Checkliste** (`security-auditor`). Reine Skill-Doppelungen (planner, debugger, refactorer, docs-writer, test-generator, git-helper) wurden nicht angelegt — Anthropic dokumentiert Agent-Sprawl als Anti-Pattern (*„multiplies debug surface area, not throughput"*). Begründung: [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]].

## Built-in-Subagents (kommen ohne Datei)

Claude Code bringt eigene Subagents mit, die hier bewusst **nicht** dupliziert werden:

| Built-in | Modell | Zweck |
|---|---|---|
| `Explore` | Haiku | schnelle read-only Codebase-Suche (Alternative zu `researcher` für kurze Lookups) |
| `Plan` | inherit | Recherche während des Plan Mode |
| `general-purpose` | inherit | komplexe mehrstufige Tasks mit Exploration + Aktion |

`researcher` ist die *kuratierte* Variante von `Explore` mit fixem Output-Format und Haiku-Pinning; nützlich, wenn man die Recon-Disziplin explizit erzwingen will.

## Frontmatter-Felder (Claude Code)

| Feld | Zweck |
|---|---|
| `name` | eindeutiger Bezeichner (lowercase, Bindestriche) |
| `description` | **wann** Claude delegiert — Trigger für Auto-Delegation; „use proactively" erhöht die Trefferquote |
| `tools` | Allowlist interner Tools (kommagetrennt). Weglassen = erbt alle. Read-only = `Read, Grep, Glob` |
| `disallowedTools` | Denylist, von der vererbten/erlaubten Menge abgezogen |
| `model` | `sonnet` / `opus` / `haiku` / voll-ID / `inherit` (Default: `inherit`) |
| `color` | Anzeigefarbe in Tasklist/Transcript |

Weitere optionale Felder: `permissionMode`, `skills` (Preload), `mcpServers`, `hooks`, `memory`, `maxTurns`, `effort`, `isolation`, `background`.

## Modell-Auflösung

Reihenfolge (höchste zuerst): `CLAUDE_CODE_SUBAGENT_MODEL` (env, global) → per-Invocation-Parameter → Frontmatter-`model` → Haupt-Konversation. Deshalb:

- `researcher: model: haiku` — bleibt günstig, der `haiku`-Alias zeigt pro Profil via `ANTHROPIC_DEFAULT_HAIKU_MODEL` auf das richtige (ggf. EU-)Modell.
- `reviewer`/`security-auditor: model: inherit` — folgen dem Profil-Default (Sonnet in Balanced/DSGVO, Opus in SOTA).

## Tools & Sicherheit

Read-only-Agents withholden `Write`/`Edit`. `researcher` bekommt **kein** `Bash` (reine Datei-/Pattern-Analyse). `reviewer` und `security-auditor` bekommen `Bash` für `git diff`/`git log` — destruktive Kommandos sind durch die globalen `permissions.deny`-Regeln in `settings.json` abgesichert (Belt-and-Suspenders). Subagents können **keine** weiteren Subagents spawnen.
