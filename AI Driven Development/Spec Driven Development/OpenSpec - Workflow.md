---
tags:
  - docnote
  - sdd
  - openspec
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# OpenSpec — Workflow

Voraussetzung: OpenSpec ist installiert und initialisiert (siehe [[OpenSpec - Setup]]).

## Workflow-Übersicht

OpenSpec kennt drei Phasen statt der sechs von Spec-Kit. Der Loop ist deutlich enger:

```
┌──────────────── PROPOSE ─────────────────────────────────────┐
│                                                               │
│  /opsx:propose <change-name>                                  │
│   → Change-Folder mit proposal.md, tasks.md, Delta-Specs      │
│   → AI klärt Edge Cases im Dialog                             │
│                                                               │
├──────────────── APPLY ────────────────────────────────────────┤
│                                                               │
│  /opsx:apply                                                  │
│   → Implementiert Tasks aus tasks.md                          │
│   → Artefakte dürfen mid-flight aktualisiert werden           │
│                                                               │
├──────────────── ARCHIVE ──────────────────────────────────────┤
│                                                               │
│  /opsx:archive                                                │
│   → Delta-Specs werden in openspec/specs/ gemerged            │
│   → Change-Folder wandert ins Archiv                          │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

Im Gegensatz zu Spec-Kit gibt es **keine harten Phase-Gates**: Während `apply` darf der Agent `proposal.md` oder die Delta-Specs aktualisieren, wenn sich beim Implementieren neue Erkenntnisse zeigen. Das ist das Delta-Modell als Live-Dokument-System.

## Schritt 1: Propose

```
/opsx:propose add-hybrid-retrieval
```

Effekte:

1. Legt `openspec/changes/add-hybrid-retrieval/` an
2. Erstellt:
   - `proposal.md` — Was & Warum, User-Stories, Akzeptanzkriterien
   - `tasks.md` — atomare Roadmap
   - `design.md` (optional, für nicht-triviale Architektur-Entscheidungen)
   - Delta-Specs als Unterordner `specs/<feature-name>/spec.md` mit `## ADDED`, `## MODIFIED`, `## REMOVED` Sektionen
3. AI führt Dialog: Edge Cases, Scope, Constraints

### proposal.md — typische Struktur

```markdown
# Change Proposal: add-hybrid-retrieval

## Problem
Pure-Dense-Retrieval verfehlt Recall bei keyword-lastigen Queries.

## Solution
Hybrid Retrieval mit BM25 + Dense + Reciprocal Rank Fusion (RRF).

## Acceptance Criteria
- [ ] Recall@10 ≥ 0.85 auf golden-query-set
- [ ] Latenz P95 < 300ms
- [ ] Backward-compatible mit /retrieve

## Out of Scope
- Reranker-Stage
- Embedding-Modell-Änderungen

## Edge Cases
- Leere Query → BM25 = 0, Dense = 0 → empty result mit warning log
- BM25 = 0 Hits, Dense > 0 → Dense-Result als Primary
- ...
```

### Delta-Spec Beispiel

OpenSpec arbeitet **delta-basiert**: Statt eine komplette Feature-Spec zu schreiben, beschreibst du die *Änderung* gegen den aktuellen Master-Spec-Zustand.

```markdown
# Spec Delta: retrieval

## ADDED Requirements

### Hybrid Retrieval Mode
- The retrieval service MUST support a hybrid mode combining BM25 and Dense retrieval.
- Fusion strategy MUST be Reciprocal Rank Fusion (RRF) with k=60.

#### Scenarios
- Query with keywords: BM25 leads, Dense supplements
- Query without keywords: Dense leads, BM25 supplements
- Empty query: empty result, no error

## MODIFIED Requirements

### /retrieve Endpoint
- The /retrieve endpoint MUST accept an optional `mode` parameter ("dense" | "hybrid").
- Default mode changes from "dense" to "hybrid" — see migration note.

## REMOVED Requirements

(none in this change)
```

Die Delta-Marker (`ADDED`, `MODIFIED`, `REMOVED`) machen explizit, was sich gegenüber dem Master-Spec ändert. Bei der Archive-Phase werden diese Deltas in den Master gefaltet.

## Schritt 2: Apply

```
/opsx:apply
```

Der Agent arbeitet `tasks.md` ab. Anders als bei Spec-Kit darf er während der Implementation:

- `proposal.md` ergänzen, wenn Edge Cases auftauchen
- Delta-Specs schärfen, wenn die Implementation zeigt, dass die ursprüngliche Spec zu vage war
- `tasks.md` umsortieren oder ergänzen

Das ist **bewusst** so designed — die [OpenSpec-Doku](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md) betont, dass der erste Wurf einer Spec nie perfekt ist und das Delta-Modell für genau diese mid-flight Korrekturen gebaut ist.

### `/opsx:ff` als Shortcut

```
/opsx:ff add-hybrid-retrieval
```

Fast-Forward: generiert alle Planungsdokumente (proposal, tasks, design, delta-specs) in einem Rutsch. Vergleichbar mit Spec-Kit's `/speckit.specify` + `/speckit.plan` + `/speckit.tasks` in einem Befehl. Nützlich, wenn du das Feature schon mental durchgespielt hast und nicht mehrere Dialog-Runden brauchst.

Trade-off: Klärungstiefe ist niedriger — bei komplexen Changes lieber den einzelnen Propose-Dialog durchlaufen.

## Schritt 3: Archive

```
/opsx:archive
```

Effekte:

1. Die Delta-Specs (`## ADDED`, `## MODIFIED`, `## REMOVED`) werden in `openspec/specs/<feature-name>/spec.md` gefaltet → der Master-Spec wird zum neuen "current state"
2. Der Change-Folder wandert nach `openspec/archive/` (oder wird gelöscht, je nach Config)
3. Der Change ist abgeschlossen

**Hier entsteht das Living Document**: Nach jedem Archive ist `openspec/specs/` der vollständige, aktuelle System-Zustand. Kein "wo war die Spec für Feature X nochmal?" — alles in einer durchsuchbaren Hierarchie.

## Beispiel: dbt-Modell-Refactoring (durchgängig)

Klassischer Robin-Brownfield-Fall: Bestehendes dbt-Projekt, ein Modell soll auf incremental umgestellt werden.

```bash
# 1. Propose
claude
> /opsx:propose convert-fct-orders-incremental
# (Dialog zu inkrementelle Strategie, Backfill, Unique-Key, Late-Arriving-Data)
# → openspec/changes/convert-fct-orders-incremental/proposal.md
# → tasks.md mit konkreten dbt-Build-Steps
# → specs/fct_orders/spec.md mit ## MODIFIED-Sektion

# 2. Optional: design.md schärfen
# Inkrementelle Strategie: 'insert_overwrite' wegen partitionierten Tabelle
# Unique-Key: order_id
# Lookback-Window: 7 Tage für Late-Arriving-Data

# 3. Apply
> /opsx:apply
# (Agent modifiziert das dbt-Modell, fügt Test hinzu)
# → models/marts/fct_orders.sql aktualisiert
# → models/marts/schema.yml mit neuen Tests
# → tests/test_fct_orders_incremental.sql

# Während Apply: Edge-Case "Backfill-Strategie für Initial-Load" wird relevant
# → Agent ergänzt proposal.md, schreibt tasks.md neu

# 4. Verifikation
# pytest grün
# dbt test grün
# dbt build --select fct_orders+ erfolgreich
# Backfill-Skript getestet auf Dev-Daten

# 5. Archive
> /opsx:archive
# → openspec/specs/fct_orders/spec.md aktualisiert (current state)
# → Change-Folder archiviert
# → CHANGELOG.md aktualisieren (manuell oder Agent-gestützt)
```

## Beispiel: Brownfield mit Repomix-Context

Für tiefere Context-Acquisition auf großer bestehender Codebase ([intent-driven.dev, März 2026](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/)):

```bash
# 1. Repomix MCP indiziert die Codebase
# (Setup in Claude-Code-Config, einmalig)

# 2. Vor dem ersten Propose: Codebase explorieren lassen
claude
> Use Repomix to explore the retrieval module. Summarize:
> - Current architecture
> - Key abstractions
> - Conventions (naming, error handling, logging)
# → Agent baut sich Context auf

# 3. Propose mit Context
> /opsx:propose add-reranker-stage
# → Proposal respektiert bestehende Patterns
```

Ohne diesen Context-Acquisition-Schritt schreibt der Agent oft Specs, die bestehende Konventionen ignorieren — der häufigste Brownfield-Failure-Mode.

## Custom-Profile statt Default-Propose

Für Robins Use-Case ist [laut intent-driven.dev (März 2026)](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/) ein **Custom OpenSpec-Profile** dem Default-Propose oft überlegen:

> *"In brownfield projects, reviewing each artifact individually gives you more control over what gets generated. During the explore phase, pass context about the existing codebase using Repomix MCP, which educates the AI on the brownfield codebase before spec writing begins."*

Das Custom-Profile ist im Wesentlichen ein angepasstes Slash-Command, das den Explore-Schritt separat ausführt und dann pro Artefakt einen eigenen Dialog macht (statt einem großen "produce everything"-Schritt).

## Review-Pattern in OpenSpec

OpenSpec hat **kein eingebautes `analyze`-Equivalent** zu Spec-Kit. Der Konsistenz-Check muss manuell oder über einen Sub-Agent erfolgen.

Empfehlung — vor `/opsx:archive`:

```
Reviewe die Änderungen in diesem Branch gegen openspec/changes/add-hybrid-retrieval/
- Stimmen die Delta-Specs mit dem implementierten Code überein?
- Sind alle Akzeptanzkriterien aus proposal.md erfüllt?
- Wurde openspec/AGENTS.md (Constitution) eingehalten?
- Welche Learnings sollten in den Master-Spec einfließen?
```

Ohne diesen Review-Schritt ist die Drift-Anfälligkeit von OpenSpec höher als bei Spec-Kit ([MarkTechPost-Vergleich Mai 2026](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/)).

## Best Practices spezifisch für OpenSpec

- **Delta-Marker konsequent nutzen**. `ADDED` / `MODIFIED` / `REMOVED` sind keine Doku-Floskeln, sondern werden von Agent und Mensch maschinell unterschieden.
- **Pro Change höchstens einen Master-Spec touchen** (oder zwei eng verwandte). Sonst wird das Archive-Merging chaotisch.
- **`design.md` nur wenn nötig**. Für einfache Changes reicht `proposal.md` + Delta-Specs. `design.md` ist für Architektur-Entscheidungen, die separate Begründung verdienen.
- **Repomix MCP für jede non-trivial Brownfield-Initiative**. Ohne Context-Acquisition driftet die Spec von der Codebase.
- **Custom-Profile statt Default für reife Codebases**. Mehr Kontrolle, weniger Auto-Generation.
- **Pre-Archive Review manuell oder per Sub-Agent**. OpenSpec fängt Drift nicht automatisch ab.
- **Master-Specs in `openspec/specs/` regelmäßig durchblättern**. Sie sind die Living Documentation und müssen lesbar bleiben.

Vollständige Best Practices: [[SDD - Best Practices]].

## Befehlsreferenz

```bash
# Setup (Terminal)
npm install -g @fission-ai/openspec@latest     # Installation
openspec init                                  # Projekt initialisieren
openspec --version                             # Version-Check
```

```
# Workflow (Slash-Commands in der Agent-Session)
/opsx:propose <change-name>                    # Neuen Change vorschlagen
/opsx:new <change-name>                        # Alias / Variante von propose
/opsx:ff <change-name>                         # Fast-forward: alle Planungs-Artefakte in einem Schritt
/opsx:apply                                    # Tasks implementieren
/opsx:archive                                  # Change in Master-Spec mergen
```

## OpenSpec vs. Spec-Kit — Workflow-Vergleich

| Schritt | Spec-Kit | OpenSpec |
|---|---|---|
| Constitution / Leitplanken | `/speckit.constitution` (separates Artefakt) | `openspec/AGENTS.md` (manuell gepflegt) |
| Feature vorschlagen | `/speckit.specify` | `/opsx:propose` |
| Edge Cases klären | `/speckit.clarify` (separate Phase) | Im Propose-Dialog integriert |
| Technische Planung | `/speckit.plan` | `design.md` (optional) |
| Task-Breakdown | `/speckit.tasks` | Im Propose enthalten |
| Konsistenz-Check | `/speckit.analyze` | **fehlt — manuell via Sub-Agent** |
| Implementation | `/speckit.implement` | `/opsx:apply` |
| Spec-Update danach | Manuell (Learnings-Sektion) | `/opsx:archive` (automatisches Merge) |

Für volle Tool-Bewertung siehe [[SDD - Tool-Empfehlungen]].

## Quellen

- [GitHub — Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
- [OpenSpec Commands Reference](https://github.com/Fission-AI/OpenSpec/blob/main/docs/commands.md)
- [OpenSpec Concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md)
- [OPSX Workflow System (DeepWiki)](https://deepwiki.com/Fission-AI/OpenSpec/3-opsx-workflow-system)
- [intent-driven.dev — OpenSpec](https://intent-driven.dev/knowledge/openspec/)
- [intent-driven.dev — Brownfield Strategy (März 2026)](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/)
- [Khaled Ea — Spec Driven Development: Fixing the AI Coding Pipeline with OpenSpec and Claude Code](https://khaledea.substack.com/p/spec-driven-development-fixing-the)
- [Rushi — OpenSpec Cheatsheet](http://www.rushis.com/openspec-cheatsheet/)
- [QubitTool — OpenSpec Tutorial 2026](https://qubittool.com/blog/openspec-sdd-tutorial)
