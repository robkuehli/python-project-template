---
title: "Agents — OpenCode Markdown-Agents"
last_verified: 2026-05-20
status: current
sources:
  - https://opencode.ai/docs/agents/
  - https://deepwiki.com/anomalyco/opencode/3.2-agent-system
tags:
  - opencode
  - agents
---

# Agents

Markdown-Agents für OpenCode. Jede Datei = ein Agent, Dateiname = Agent-ID. Konfiguration im YAML-Frontmatter, System-Prompt im Body.

## Sind Agents tool-spezifisch (nicht global wie Skills)?

**Ja — mit einer wichtigen Präzisierung.** Deine Annahme ist korrekt: anders als Skills (die dem Cross-Tool-Anthropic-Standard folgen und über Symlinks von Claude Code, OpenCode und Codex gleichzeitig gelesen werden), sind Agents **tool-spezifisch**. OpenCode-Agents leben in `~/.config/opencode/agent/` und nutzen OpenCode-eigene Frontmatter-Felder (`mode`, `tools`, `model`, `temperature`). Sie sind nicht zu Claude Codes `~/.claude/agents/` oder Codex' Agent-Format kompatibel — Format und Discovery-Pfad unterscheiden sich.

Die Konsequenz: Wir pflegen Agents **pro Tool getrennt**. Dieser Ordner ist die OpenCode-Quelle; das Claude-Code-Pendant lebt unter `../../Claude-Code/`.

**Warum der Unterschied?** Skills beschreiben *was* getan wird (Workflow-Wissen, modell- und tool-agnostisch). Agents beschreiben *wie* ein Tool eine Rolle besetzt — inklusive tool-spezifischer Mechanik (welche internen Tools erlaubt sind, welches Modell, welcher Mode). Diese Mechanik ist nicht portierbar, also bleibt der Agent beim Tool.

## Drei Achsen — Skills, Modes, Subagents

Der Workflow lebt auf drei **orthogonalen** Achsen. Nur die ersten beiden musst du dir aktiv merken; die Subagents werden von den Primaries automatisch gespawnt.

| Achse | Frage | Artefakt | Merkfläche |
|---|---|---|---|
| **Skills** | *Was* tue ich? | `Skills/*/SKILL.md` (cross-tool) | 8 Verben: explore · spec · plan · test · delegate · review · debug · capture |
| **Modes** | *Wo* sitze ich? | OpenCode primary `plan` / `build` | 2 Modes (Tab-Switch) |
| **Subagents** | *Wie/womit* wird ausgeführt? | ≤3 Subagents | — auto-gespawnt — |

Die vier Konzept-Rollen aus [[Developer Workflow]] mappen 1:1:

| Rolle | OpenCode-Agent | Skills, die er hält |
|---|---|---|
| **Architect** | `plan` (primary) | explore, spec, plan, review |
| **Coder** | `build` (primary) | test, delegate, debug |
| **Explorer** | `researcher` (subagent) | explore (read-only, isoliert) |
| **Scribe** | — kein stehender Agent — | capture-Skill + SessionEnd-Hook |

> **Naming:** „plan" bezeichnet bewusst zwei getrennte Dinge auf zwei Achsen — das `/plan`-**Skill** (ein Verb) und den `plan`-**Mode** (der Architect-Sitz). Es gibt keinen `planner`-Subagent mehr; taktische Schritt-Zerlegung ist schlicht das `/plan`-Skill im `build`-Mode.

## Primary Agents vs. Subagents

OpenCode kennt zwei Agent-Typen ([Docs](https://opencode.ai/docs/agents/)):

- **Primary Agents** (`mode: primary`) — die Hauptassistenten, in die man per Tab/Mode-Switch direkt hineinwechselt. OpenCode bringt `build` und `plan` als Built-ins mit; wir überschreiben sie mit eigenen Definitionen (deshalb behalten sie diese Namen — ein eigener `architect`/`coder`-Name würde einen *dritten* Primary neben den Built-ins erzeugen).
- **Subagents** (`mode: subagent`) — spezialisierte Assistenten, die ein Primary Agent für abgegrenzte Tasks delegiert (oder die man mit `@name` direkt anspricht). Built-ins sind `general` und `explore`.

Setzt man `mode` nicht, ist der Default `all` (Agent ist sowohl als Primary wählbar als auch delegierbar).

## Struktur in diesem Ordner

```
Agents/
├── README.md            ← diese Datei
├── Primary/
│   ├── build.md            Coder-Mode — Implementation-Loop, hält test/delegate/debug
│   └── plan.md             Architect-Mode — Specs, Pläne, Design, Review
└── Subagents/
    ├── researcher.md       Explorer — Codebase-Recon, read-only, günstiges Modell
    ├── reviewer.md         Unabhängiges Code-Review gegen Spec (read-only)
    └── security-auditor.md Secrets, Injection, Permission-Checks (read-only)
```

> **Auswahl-Prinzip (aggressiv verschlankt, Mai 2026):** Ein Subagent existiert nur bei echtem Mehrwert ggü. dem Primary — **Kontext-Isolation** (`researcher`), **unabhängige read-only-Zweitmeinung** (`reviewer`), oder **distinkte Spezial-Checkliste** (`security-auditor`, primär für den autonomen Modus). Reine Skill-Doppelungen (planner, debugger, refactorer, docs-writer, test-generator, git-helper) wurden entfernt — siehe [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]]. Begründung: Anthropic dokumentiert Agent-Sprawl als Anti-Pattern (*„multiplies debug surface area, not throughput"*).

> Die Trennung in `Primary/` und `Subagents/` ist eine **Repo-Ordnungs-Konvention**. OpenCode entdeckt Agents flach in `~/.config/opencode/agent/`. Beim Install werden beide Unterordner flach zusammenkopiert — siehe [[OpenCode — Setup-Manual]] §6.

## Modell-Auflösung

Im Frontmatter steht ein **Default-Modell**. Das tatsächlich genutzte Modell wird pro Profil über `agent.<name>.model` in der aktiven `opencode.json` überschrieben (siehe [[OpenCode — Profil-Spezifikationen]]). Das Frontmatter-Modell greift nur, wenn das Profil den Agent nicht explizit mappt.

## Tools-Feld

OpenCode steuert pro Agent, welche internen Tools verfügbar sind — als Map `toolname: true|false`. Read-only-Agents (reviewer, researcher, security-auditor) deaktivieren `write`, `edit` und `bash` hart. Das ist die wichtigste Sicherheitsschicht auf Agent-Ebene.

## Skill→Agent-Spawn-Workaround (Issue #19344)

Bis OpenCode deklaratives Skill→Agent-Binding unterstützt ([Issue #19344](https://github.com/anomalyco/opencode/issues/19344), Mai 2026 offen), enthält jeder Workflow-Skill, der Delegation braucht, im Body eine explizite Spawn-Anweisung an den passenden Agent (z.B. „Spawn the researcher subagent…" oder „Spawn the reviewer subagent…"). OpenCode befolgt das zuverlässig. Details: [[OpenCode — Best Practices]] §6.
