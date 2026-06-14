---
tags:
  - docnote
  - sdd
  - spec-kit
  - openspec
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# SDD — Tool-Empfehlungen

## TL;DR

| Use-Case | Tool |
|---|---|
| Greenfield-Projekt, neues Feature von Null | ✅ **Spec-Kit** |
| Brownfield-Iteration auf bestehender Codebase | ✅ **OpenSpec** |
| Robins Default (Data-Pipeline-Iteration) | **OpenSpec** |
| Robins Greenfield-Default (neue RAG-/Eval-Pipeline) | **Spec-Kit** |

Beide werden gepflegt, beide unterstützen Claude Code, Cursor, Copilot, OpenCode (Spec-Kit über `--ai`-Flag, OpenSpec über `openspec init`-Prompt). **Beide sind ✅ Established** Stand Mai 2026.

Nicht empfohlen / niedrige Priorität: Kiro (AWS-Lock-in), Tessl, BMAD, Agent OS, GSD, Superpowers — siehe [MarkTechPost-Vergleich Mai 2026](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/).

## Direktvergleich

| Kriterium | Spec-Kit | OpenSpec |
|---|---|---|
| **Maturity** | ✅ Established (>90k Stars, GitHub-Maintained) | ✅ Established (Fission AI, schnelles Wachstum) |
| **Sprache** | Python (`uv tool install`) | TypeScript / Node.js (`npm install -g`) |
| **Aktuelle Version** (Mai 2026) | `v0.8.11` | `@latest` (rolling) |
| **Setup-Aufwand** | Mittel (`uv` als Prereq) | Niedrig (`npm install`) |
| **Sweet Spot** | Greenfield, > 3 Dateien Scope | Brownfield, Delta-Iteration |
| **Workflow-Phasen** | 6+: constitution → specify → clarify → plan → tasks → analyze → implement | 3: propose → apply → archive |
| **Spec-Volumen (typisch)** | ~800 Zeilen Multi-Artifact | ~250 Zeilen Single Change |
| **Artefakte pro Feature** | `spec.md`, `plan.md`, `research.md`, `data-model.md`, `tasks.md` | `proposal.md`, `tasks.md`, `design.md` (optional), Delta-Specs |
| **Spec-Modell** | Eine Spec pro Feature (isoliert) | Delta-Specs auf eine living Master-Spec |
| **Delta-Marker** | Nein (Spec-Per-Feature) | Ja (`ADDED`, `MODIFIED`, `REMOVED`) |
| **Brownfield-Support** | OK über `/speckit.analyze`, aber sekundär | Nativ, Primärfokus |
| **Constitution-Konzept** | Ja (`.specify/memory/constitution.md`) | Lightweight (`openspec/AGENTS.md`) |
| **Slash-Commands** | `/speckit.*` (8 Commands) | `/opsx:*` (3 Commands + Varianten) |
| **Agent-Support** | 30+ Agents (Claude Code, Copilot, Cursor, Gemini, OpenCode, …) | Claude Code, Cursor, Copilot, Cline, Windsurf |
| **Plugin-Architektur** | Ja, seit März 2026 | Nein |
| **Drift-Sicherung** | `/speckit.analyze` als Quality Gate | Delta-Modell macht Drift explizit |
| **Quelle für Quick-Check** | [github/spec-kit](https://github.com/github/spec-kit) | [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) |

## Wann welches Tool?

### Spec-Kit wählen, wenn …

- Greenfield-Projekt oder eigenständiges neues Modul ohne tiefe Kopplung zur bestehenden Codebase
- Du Wert auf einen formalisierten Multi-Step-Refinement-Prozess legst (Constitution, Plan, Research, Data Model als separate Artefakte)
- Architektur-Entscheidungen explizit dokumentiert werden sollen (`plan.md`, `research.md` als reviewbare Artefakte)
- Das Team größer als 2-3 Personen ist und Specs als Living Documentation dienen
- Du Quality-Gates wie `/speckit.analyze` brauchst, um Konsistenz zwischen Artefakten zu prüfen

Konkrete Robin-Beispiele:
- Neuer RAG-Service von Grund auf
- Neues Eval-Framework für LLM-Komponenten
- Neue Daten-Plattform-Komponente, separate Code-Base

### OpenSpec wählen, wenn …

- Brownfield: Bestehende Codebase, an der inkrementell weiterentwickelt wird
- Iteration in vielen kleinen Changes statt eines großen Feature-Wurfs
- Du Delta-Sichtbarkeit brauchst — was *konkret* ändert sich gegenüber dem aktuellen Zustand?
- Schneller Workflow gewünscht (3 statt 6+ Phasen)
- TypeScript-/Node-Stack bereits da
- Spec-Volumen soll niedrig bleiben (Review-Aufwand begrenzen)

Konkrete Robin-Beispiele:
- dbt-Modell-Refactoring in bestehendem Warehouse
- Erweiterung eines bestehenden Airflow-DAGs um neue Sources
- Neue Eval-Metric in bestehende Eval-Pipeline einbauen
- Schema-Migration mit Backfill auf produktiver Datenbank

### Beide Tools parallel?

Möglich, aber nicht empfohlen. Die Specs sind nicht interoperabel — eine Spec-Kit-Spec lässt sich nicht ohne Aufwand in OpenSpec überführen. Wenn beides im Einsatz ist, gilt: **ein Repo, ein Tool.** Die Wahl trifft man beim Setup.

Ausnahme: Wer schon ein Spec-Kit-Repo hat, kann OpenSpec parallel für neue Brownfield-Initiativen nutzen, ohne das bestehende Spec-Kit-Setup zu touchen. Die beiden ignorieren sich gegenseitig.

## Was ich für Robin empfehle

Stand Mai 2026, gegeben dass Data Engineering / Data Science / AI Engineering überwiegend an **bestehenden Pipelines und Modellen** arbeitet:

**Default: OpenSpec.** Lightweight, brownfield-stark, schnelle Iteration. Passt zu typischer Pipeline-Arbeit.

**Greenfield-Eskalation: Spec-Kit.** Wenn ein neues Projekt von Null startet und Architektur-Sorgfalt wichtig ist (z.B. neue AI-Engineering-Plattform-Komponente), lohnt der Mehraufwand der Multi-Artifact-Kaskade.

Detaillierte Setup-Anleitungen und Workflows:

- [[Spec-Kit - Setup]] | [[Spec-Kit - Workflow]]
- [[OpenSpec - Setup]] | [[OpenSpec - Workflow]]

## Stimmen aus der Community

> *"OpenSpec is brownfield-first, with most tools assuming you're starting fresh, while OpenSpec focuses on mature codebases where the real struggle is figuring out how the current system works."*
> — [intent-driven.dev](https://intent-driven.dev/knowledge/openspec/), 2026

> *"Spec Kit works well for medium-to-large greenfield features where upfront planning investment pays off, but should be avoided for small features, quick prototypes, or brownfield work on legacy codebases where overhead exceeds return on investment."*
> — [Hashrocket — OpenSpec vs Spec Kit (2026)](https://hashrocket.com/blog/posts/openspec-vs-spec-kit-choosing-the-right-ai-driven-development-workflow-for-your-team)

> *"OpenSpec produced lighter specifications around 250 lines compared to Spec Kit's heavier output around 800 lines, considerably reducing review overhead."*
> — [Tim Chao, Feb 2026](https://www.timchao.site/en/articles/sdd-tools-comparison-speckit-openspec-superpowers)

> *"Pros and Cons of Spec Kit compared to OpenSpec - Greenfield/Brownfield development"*
> — [Spec-Kit Discussion #1536](https://github.com/github/spec-kit/discussions/1536) (offizielle Anerkennung der Use-Case-Trennung durch das Spec-Kit-Team)

## Quellen

- [GitHub — github/spec-kit](https://github.com/github/spec-kit)
- [GitHub — Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
- [Spec-Kit v0.8.11 Release Notes](https://github.com/github/spec-kit/releases/tag/v0.8.11)
- [Hashrocket — OpenSpec vs Spec Kit (2026)](https://hashrocket.com/blog/posts/openspec-vs-spec-kit-choosing-the-right-ai-driven-development-workflow-for-your-team)
- [intent-driven.dev — Spec Kit vs OpenSpec](https://intent-driven.dev/knowledge/spec-kit-vs-openspec/)
- [Tim Chao — Spec Kit vs. OpenSpec vs. Superpowers (Feb 2026)](https://www.timchao.site/en/articles/sdd-tools-comparison-speckit-openspec-superpowers)
- [MarkTechPost — 9 Best AI Tools for Spec-Driven Development in 2026 (Mai 2026)](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/)
- [Augment Code — 6 Best Spec-Driven Development Tools for AI Coding in 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools)
- [Spec-Kit Discussion #1536 — Pros and Cons vs OpenSpec](https://github.com/github/spec-kit/discussions/1536)
