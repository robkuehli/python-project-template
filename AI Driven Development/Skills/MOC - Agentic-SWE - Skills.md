---
tags:
  - moc
Creation Date: 2026-05-20
Last Modified: 2026-05-20
---
# Skills

Skills sind ausführbare Workflow-Bundles, die ein AI-Agent bei passendem Kontext lädt und befolgt. Sie sind die operative Form der acht Skills aus [[Developer Workflow]] (`/explore`, `/spec`, `/plan`, `/test`, `/delegate`, `/review`, `/debug`, `/capture`).

## Cross-Tool-Format

Skills folgen der **Anthropic Agent Skills Spec**. Dasselbe Format wird gelesen von:

- **Claude Code** — `~/.claude/skills/` (global) + `.claude/skills/` (Projekt)
- **OpenCode** — `~/.config/opencode/skills/`, `.opencode/skills/`, **plus** `.claude/skills` und `.agents/skills` als Fallback-Pfade (Cross-Tool-Discovery seit Q1 2026)
- **Codex CLI** — `~/.codex/skills/`, `.codex/skills/`, `.agents/skills/`

Daraus folgt: **Skills in diesem Ordner werden von allen drei Tools genutzt**, wenn sie als Discovery-Pfad eingebunden werden. Genau dafür ist dieser Ordner gedacht.

## Skill-Format

```
Skills/
├── explore/
│   ├── SKILL.md              # Pflicht — YAML-Frontmatter + Body
│   ├── references/           # Optional — Lookup-Material
│   ├── assets/               # Optional — Templates, Beispiele
│   └── scripts/              # Optional — ausführbare Helfer
├── spec/
│   └── SKILL.md
└── …
```

### SKILL.md Frontmatter

```yaml
---
name: explore  # muss Ordnername matchen, lowercase + hyphens, 1–64 chars
description: "Systematische Read-only-Analyse…"  # PFLICHT — beschreibt, wann der Skill geladen wird
license: MIT
compatibility:  # optional — welche Tools den Skill lesen
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft        # draft → stable (mehrfach in echten Tasks bewährt) → deprecated (Body bleibt, Description warnt)
  primary_agent: build # Mode, der den Skill primär ausführt: plan (Architect) oder build (Coder)
  source:              # optional: Repo / Docs / URL der Inspiration
---
```

**Progressive Disclosure:** Agents laden zunächst nur `name` + `description`. Der Body wird erst bei tatsächlichem Bedarf nachgeladen. Heißt: Description muss aussagekräftig sein, Body darf länger sein, ohne den Token-Budget jedes Calls zu strapazieren.

> **Caveat (OpenCode, Issue #19344 / #13188 / #15805, Stand Mai 2026):** OpenCode lädt aktuell *alle* discoverten Skills in den Kontext jedes Agents (kein per-Agent-Filter). Bei vielen Skills steigen Token-Kosten linear. Bis das gefixt ist: nur die wirklich gebrauchten Skills im Discovery-Pfad halten oder per Projekt-`.opencode/skills` scopen.


## Skills in diesem Ordner

| Skill      | Trigger                               | Output                                                    | Agent ([[Skill-Agent-Mappings]]) | SKILL.md                                                    |
| ---------- | ------------------------------------- | --------------------------------------------------------- | -------------------------------- | ----------------------------------------------------------- |
| `explore`  | „Ich verstehe diesen Bereich nicht"   | Betroffene Dateien, Patterns, offene Fragen               | Explorer                         | [[Docs/AI Driven Development/Skills/explore/SKILL\|SKILL]]  |
| `spec`     | „Ich muss ein Feature definieren"     | Requirements, AC, Edge Cases, Out of Scope, Wissenslücken | Architect                        | [[Docs/AI Driven Development/Skills/spec/SKILL\|SKILL]]     |
| `plan`     | „Wie gehe ich das an?"                | Geordnete Schritte, Abhängigkeiten, Spec-Referenz         | Architect/Coder                  | [[Docs/AI Driven Development/Skills/plan/SKILL\|SKILL]]     |
| `test`     | „Ich brauche Tests aus dieser Spec"   | Testfälle mit Assertions, nach AC geordnet                | Coder                            | [[Docs/AI Driven Development/Skills/test/SKILL\|SKILL]]     |
| `delegate` | „Das soll ein Agent autonom umsetzen" | Agent-Bundle: Spec + Plan + Tests + Kontext + Constraints | Coder                            | [[Docs/AI Driven Development/Skills/delegate/SKILL\|SKILL]] |
| `review`   | „Ich will die Änderungen prüfen"      | Checkliste gegen AC, Abweichungen, offene Punkte          | Architect                        | [[Docs/AI Driven Development/Skills/review/SKILL\|SKILL]]   |
| `debug`    | „Etwas funktioniert nicht"            | Hypothesen, Diagnoseschritte, Ursache                     | Coder                            | [[Docs/AI Driven Development/Skills/debug/SKILL\|SKILL]]    |
| `capture`  | „Ich habe etwas gelernt"              | CONVENTIONS.md / AGENTS.md Eintrag                        | Scribe                           | [[Docs/AI Driven Development/Skills/capture/SKILL\|SKILL]]  |

## Quellen-Kuratierung — woher Inspiration und fertige Skills

Die folgenden Repos sind die aktuell relevanten Quellen für Skills#

### Offiziell

- **[anthropics/skills](https://github.com/anthropics/skills)** — Anthropic-eigene Skills (~135k Stars, 17 offizielle Skills). Top-Picks: `frontend-design`, `document-skills`, `claude-api`, `skill-creator`, `remotion-best-practices`.
- **[simonw/claude-skills](https://github.com/simonw/claude-skills)** — Mirror der `/mnt/skills`-Inhalte aus dem Claude-Code-Interpreter (Anthropic Production-Skills). Sehr nützlich als Referenz für Skill-Struktur und Python-Helpers.

### Community-Frameworks

- **[obra/superpowers](https://github.com/obra/superpowers)** (Jesse Vincent) — ~174k Stars, seit Jan 2026 im offiziellen Anthropic-Marketplace. **Cross-Tool-Support inkl. OpenCode.** 12 dokumentierte Skills in Phasen-Workflow: Brainstorming → TDD (RED-GREEN-REFACTOR) → Subagent-Driven-Development → Code-Review. Aktuelle Releases v5.0.7 (März–Mai 2026).

### Awesome-Listen

- **[hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** — kuratiertes Flaggschiff. Editorial gepflegt, tote Tools werden entfernt.
- **[ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)** — breite Sammlung mit Workflow-Fokus.
- **[travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills)** — Skills-only.

### Eigene Strategie

Die 8 Skills in diesem Ordner **maßgeschneidert** auf den Workflow aus [[Developer Workflow]], nicht aus den Repos kopiert. Aber:

- **Inspiration** für Struktur und Edge-Case-Behandlung aus `anthropics/skills` und `obra/superpowers` ziehen
- **Spezifische Helper-Skills** (z.B. `frontend-design`, `document-skills`) bei Bedarf zusätzlich symlinken oder kopieren — die müssen nicht neu geschrieben werden
- Bei wiederkehrenden Patterns aus der eigenen Arbeit → in den passenden Skill aufnehmen (Self-Improvement-Loop)

## Konventionen für eigene Skills

Für das Erstellen neuer Skills gibt es ein Template: [[Docs/AI Driven Development/Skills/_TEMPLATE/SKILL|SKILL]]

1. **Description ist die Suchanfrage.** Sie muss die typische Frage des Nutzers paraphrasieren. „Spec schreiben" ist schwach, „Vollständige Spec für komplexes Feature erstellen, inkl. Edge Cases, Out of Scope, Wissenslücken" ist stark.
2. **Body ist ein Rezept, keine Theorie.** Schritt-für-Schritt, mit Beispiel-Output am Ende.
3. **Referenzen explizit.** Wenn der Skill ein Template braucht, liegt es unter `references/`, nicht inline.
4. **Idempotenz.** Wiederholtes Ausführen darf nichts kaputt machen — wenn der Skill Dateien schreibt, ist `--force` zu vermeiden.
5. **Side-Effects benannt.** Wenn der Skill Tools ausführt (z.B. `pytest`), das vorne im Body benennen.
6. **Stack-spezifisches geht in eigene Datei.** Globale Skills sind tech-stack-agnostisch. Python-spezifische Defaults landen in der Projekt-`AGENTS.md` oder `CLAUDE.md`, nicht im globalen Skill.

## Offen / zu verfeinern

Offene Skill- und Setup-Punkte sind zentral gepflegt in [[Docs/AI Driven Development/CLI-Tools/OpenCode/OpenCode — Open Issues & TODOs|OpenCode — Open Issues & TODOs]] §E (Symlinks, Helper-Skills, `.opencode/skills`-Anbindung, `spec-template.md`, `status: draft → stable`).
