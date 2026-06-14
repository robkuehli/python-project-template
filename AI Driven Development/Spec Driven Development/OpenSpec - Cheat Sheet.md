---
tags:
  - docnote
  - sdd
  - openspec
  - cheatsheet
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# OpenSpec — Cheat Sheet (Brownfield)

> [!info] Use-Case
> Brownfield: Iteration auf bestehender Codebase, dbt-Pipeline-Refactoring, Schema-Migration, Erweiterung bestehender Services. Bei Greenfield: → [[Spec-Kit - Cheat Sheet]].

## 1. Init (einmal pro Projekt)

```bash
npm install -g @fission-ai/openspec@latest
cd existing-project
openspec init                   # Dialog: AI-Agent wählen, Brownfield bestätigen
openspec --version
```

> [!warning] Node 20.19.0+ Pflicht
> `nvm install 20 && nvm use 20` falls nötig.

> [!tip] Repomix MCP für Codebase-Context
> Bei großen bestehenden Codebases: Repomix MCP einrichten, *bevor* der erste Change vorgeschlagen wird. Ohne Context-Acquisition schreibt der Agent Specs, die bestehende Konventionen ignorieren.

## 2. Constitution + Stack einmal pflegen

`openspec/AGENTS.md` — Architektur-Prinzipien (Test-First, Idempotency, BackwardCompat, …).
`openspec/project.md` — Stack, Conventions, Naming, Error-Handling.

> [!tip] Verweis in Repo-`CLAUDE.md` ergänzen
> Sonst zieht Claude Code die OpenSpec-Constitution nicht. Siehe [[OpenSpec - Setup]] §Memory-Architektur.

## 3. Change-Loop (pro Iteration)

```
/opsx:propose <change-name>     # Change-Folder anlegen, Edge-Case-Dialog
/opsx:apply                     # Implementation, darf Spec mid-flight schärfen
# (Pre-Archive Review manuell!)
/opsx:archive                   # Delta-Specs ins openspec/specs/ mergen
```

> [!warning] Delta-Marker konsequent nutzen
> `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements` sind keine Doku-Floskeln — der Archive-Schritt foldet darauf basierend in den Master-Spec.

> [!warning] Pro Change höchstens einen Master-Spec touchen
> Sonst wird das Archive-Merging chaotisch. Lieber zweiter Change-Folder.

> [!danger] OpenSpec hat kein `/speckit.analyze`-Equivalent
> Drift-Check vor `archive` **manuell** oder per Sub-Agent. Sonst landet inkonsistente Spec im Master.

## 4. Pre-Archive Review (manuell)

```
Reviewe Branch gegen openspec/changes/<change-name>/
- Stimmen Delta-Specs mit implementiertem Code überein?
- Alle Akzeptanzkriterien aus proposal.md erfüllt?
- openspec/AGENTS.md (Constitution) eingehalten?
- Welche Learnings sollten in den Master-Spec einfließen?
```

Erst danach `/opsx:archive`.

## 5. Shortcut für simple Changes

```
/opsx:ff <change-name>          # Fast-Forward: alle Planungs-Artefakte in einem Schritt
```

> [!warning] `ff` nur wenn du das Feature mental schon durchgespielt hast
> Klärungstiefe niedriger. Bei komplexen Changes besser den normalen Propose-Dialog.

## Artefakt-Hierarchie

```
openspec/
├── AGENTS.md                       ← Constitution
├── project.md                      ← Stack & Conventions
├── specs/                          ← Living Master-Specs (current state)
│   └── <feature>/spec.md
└── changes/                        ← Active changes
    └── <change-name>/
        ├── proposal.md             ← Was & Warum, Akzeptanzkriterien
        ├── tasks.md                ← Atomare Roadmap
        ├── design.md               ← Optional, nur bei Architektur-Tiefe
        └── specs/<feature>/spec.md ← Delta-Spec (ADDED/MODIFIED/REMOVED)
```

## Drei-Phasen-Loop in einem Satz

```
Propose (Change-Folder + Edge Cases) → Apply (Implement + mid-flight Schärfen) → Archive (Delta → Master)
```

## Update

```bash
npm update -g @fission-ai/openspec
openspec --version
```

→ Vollständiger Workflow: [[OpenSpec - Workflow]] · Setup: [[OpenSpec - Setup]]
