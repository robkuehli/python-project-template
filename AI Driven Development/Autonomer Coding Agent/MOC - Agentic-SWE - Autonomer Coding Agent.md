---
tags:
  - moc
Creation Date: "{{date: YYYY-MM-DD}}"
Last Modified:
---
Autonomer Coding-Agent: lokaler Ollama-Worker baut Greenfield-PoCs nach Spec, eskaliert budget-gated auf Ollama Cloud. Offener Sandbox-Egress (Doku ziehen). Verdrahtet an die Projekt-Guidelines (Testing/Pre-Commit/Changelog/Doku) und das verschlankte OpenCode-Sub-Agent-Setup.

## Design-Docs
- [[01-project-brief]] — Vision, Scope, Anforderungen, realistische Erfolgsquoten
- [[02-adrs]] — Architektur-Entscheidungen (ADR-001…008 + v2: ADR-009 Cloud-Eskalation, ADR-010 offener Egress, ADR-011 Planner/Reviewer, ADR-012 Budget, ADR-013 Bounding-Korrektur, ADR-014 Spec-Framework)
- [[03-setup-manual]] — Hardware/Modell/Tooling-Setup (Hinweis: `--max-turns`-Annahme durch ADR-013 korrigiert)
- [[04-escalation]] — Eskalations-Konzept Lokal→Ollama Cloud (formalisiert als ADR-009)
- [[05-orchestrator]] — Orchestrator, autonomer Loop, `.green`-Gate, Budget, Sub-Agent-Integration
- [[06-spec-workflow]] — SDD-Challenge + gestufter Spec-Workflow (Lite vs. Spec-Kit), Autoren-/Übergabe-Flow

## Lauffähiges Scaffold
- `scaffold/README.md` — Einstieg, Setup, Pro-PoC-Workflow, Erst-Inbetriebnahme
- `scaffold/opencode-autonomous.json` + `…-planreview.json` — OpenCode-Profile (Worker lokal / optional Planner-Reviewer Cloud)
- `scaffold/orchestrator/` — run-agent.sh, lib.sh, budget.sh, notify.sh, agent.env.example
- `scaffold/sandbox/` — Dockerfile, run-sandbox.sh (offener Egress)
- `scaffold/templates/` — constitution, AGENTS.md, .pre-commit-config, pyproject, Makefile, spec.lite.md
- `scaffold/plugin/autonomous-guards.ts` — PreBash-Guard + Egress-Audit + ruff-format