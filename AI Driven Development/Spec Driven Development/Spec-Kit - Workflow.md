---
tags:
  - docnote
  - sdd
  - spec-kit
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# Spec-Kit — Workflow

Voraussetzung: Spec-Kit ist installiert und initialisiert (siehe [[Spec-Kit - Setup]]).

## Workflow-Übersicht

```
┌──── PLAN-PHASE (Claude Code / OpenCode mit Spec-Kit Slash-Commands) ────┐
│                                                                          │
│  /speckit.constitution  →  Leitplanken setzen (einmalig, dann iterativ)  │
│  /speckit.specify       →  Feature definieren (legt Branch + spec.md an) │
│  /speckit.clarify       →  Edge Cases & Ambiguitäten eliminieren         │
│  /speckit.plan          →  Technische Architektur (plan.md, research.md) │
│  /speckit.tasks         →  Atomare Roadmap (tasks.md, [P]-Marker)        │
│  /speckit.analyze       →  Konsistenz-Check über alle Artefakte          │
│                                                                          │
├─────────────────── IMPLEMENT-PHASE ──────────────────────────────────────┤
│                                                                          │
│  /speckit.implement     →  Code-Generierung gemäß tasks.md (TDD)         │
│  (oder: Handoff an separaten Executor-Agent)                             │
│                                                                          │
├─────────────────── REVIEW-PHASE ─────────────────────────────────────────┤
│                                                                          │
│  Review-Agent prüft gegen spec.md                                        │
│  Learnings zurück in spec.md                                             │
│  CHANGELOG.md aktualisieren                                              │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Schritt 1: Constitution definieren

Einmal pro Projekt, danach selten ergänzt. Definiert die nicht-verhandelbaren Prinzipien.

```
/speckit.constitution
```

Der Agent fragt im Dialog ab, was die architektonischen Leitplanken sind. Beispiele für Robins Use-Cases:

```markdown
# Project Constitution — RAG-Service

## Non-Negotiable Principles

1. **Idempotency First**: Alle Ingestion-Routes müssen idempotent sein (Dedupe per content_hash).
2. **Eval-Driven**: Kein Merge ohne grünen Eval-Run (Recall@10 ≥ 0.8, MRR ≥ 0.6).
3. **Embedding-Version Pinning**: Embedding-Modell-Version ist Teil des Index-Names.
4. **Observability**: LangFuse-Tracing für jede Retrieval-Call mandatory.
5. **Cost Awareness**: Token-Counter in jedem LLM-Call, Cost-Estimate in PR-Description.
```

Die Constitution wird bei jedem Folgeschritt automatisch als Leitplanke herangezogen.

## Schritt 2: Feature spezifizieren

```
/speckit.specify
```

Effekte:
- Legt automatisch einen Feature-Branch an (z.B. `002-hybrid-retrieval`)
- Erstellt `.specify/specs/002-hybrid-retrieval/spec.md` aus dem Template
- Im Dialog wird das Feature definiert: User Story, Akzeptanzkriterien, Scope

**Wichtig**: Spec beschreibt *Was* und *Warum*, **keine** Frameworks/Libs/Versionen. Die kommen erst im Plan.

### spec.md — typische Sektionen

```markdown
---
id: 002
title: "Hybrid Retrieval für RAG-Pipeline"
status: draft
created: 2026-05-20
---

## Kontext / Problem
Aktuelle Pure-Dense-Retrieval verfehlt Recall bei keyword-lastigen Queries
(produktbezogene Anfragen mit SKU-Nummern).

## Ziel(e)
- [ ] Recall@10 ≥ 0.85 auf golden-query-set (aktuell 0.72)
- [ ] Latenz P95 < 300ms (aktuell 220ms)

## Non-Goals
- KEINE Reranker-Stage in dieser Iteration
- KEINE Änderungen am Embedding-Modell

## Akzeptanzkriterien
- [ ] Eval-Run grün auf golden-set
- [ ] Latenz P95 unter Threshold
- [ ] Backward-compatible mit bestehendem `/retrieve`-Endpoint

## Edge Cases
(noch leer, wird durch /speckit.clarify gefüllt)
```

## Schritt 3: Clarification — niemals überspringen

```
/speckit.clarify
```

Der Agent stellt gezielte Fragen, die typische AI-Annahmen ans Licht bringen:

- Was passiert bei leerer Query?
- Wie wird BM25 vs. Dense gewichtet — fix oder query-dependent?
- Was, wenn BM25 0 Hits liefert und Dense > 0?
- Maximale Top-K — pro Stage oder kombiniert?
- Sortierreihenfolge bei gleichen Scores?

Antworten landen im `## Clarifications`-Abschnitt der `spec.md`. **Dieser Schritt ist im manuellen SDD am häufigsten übersprungen worden — Spec-Kit erzwingt ihn als formale Phase.**

## Schritt 4: Plan + Research

```
/speckit.plan
```

Hier kommt der Tech-Stack ins Spiel. Der Agent gleicht mit der Constitution ab und erzeugt:

| Artefakt | Inhalt |
|---|---|
| `plan.md` | Technische Strategie, gewählter Ansatz, Architektur-Skizze |
| `research.md` | Validierung von Lib-Versionen, API-Checks, Best Practices aus 2026 |
| `data-model.md` | Datenstrukturen, Contracts, DB-Schema-Diffs |

**Wichtig**: `research.md` manuell auf veraltete AI-Annahmen prüfen, besonders bei schnell evolvierenden Frameworks (LangChain, llama-index, dbt). Spec-Kit promptet hier oft Lib-Versionen, die ein paar Monate alt sind.

## Schritt 5: Task Breakdown

```
/speckit.tasks
```

Erzeugt `tasks.md` mit atomaren, TDD-strukturierten Tasks:

```markdown
- [ ] [P] Erstelle `tests/test_hybrid_retrieval.py` mit failing tests aus spec.md Akzeptanzkriterien
- [ ] [P] Erstelle `src/retrieval/bm25_indexer.py`-Stub mit Interface
- [ ] Implementiere `BM25Indexer.build()` (Test #1 wird grün)
- [ ] Implementiere `HybridRetriever.retrieve()` mit RRF-Fusion
- [ ] Add Eval-Hook in `evals/golden_set_eval.py`
- [ ] Update `docs/architecture.md` mit Hybrid-Diagramm
```

`[P]`-Marker = parallelisierbar. Explizite Dateipfade sind Pflicht — sonst halluziniert der Implementierungs-Agent eigene Strukturen.

## Schritt 6: Konsistenz-Check (Quality Gate)

```
/speckit.analyze
```

Prüft Kohärenz aller Artefakte:
- Anforderungen aus `spec.md`, die keine Tasks haben → Drift
- Widersprüche zwischen `plan.md` und `tasks.md`
- Abweichungen von der Constitution
- Fehlende Edge-Case-Behandlung

**Dieser Schritt existiert in keinem anderen SDD-Tool in dieser Form.** Größter Mehrwert von Spec-Kit gegenüber rohem Spec-Schreiben.

Output ist ein Report mit konkreten Findings. Vor `implement`: Findings adressieren, dann erneut `analyze`, bis grün.

## Schritt 7: Implementation

### Variante A — `/speckit.implement` (Single-Agent)

```
/speckit.implement
```

Der Agent arbeitet `tasks.md` ab, TDD-Loop, Tests grün, Iteration. Beste Wahl wenn Claude Code als Single-Agent-Setup läuft.

### Variante B — Handoff an separaten Executor

Für ein Zwei-Agent-Setup (Planer = Claude Code, Executor = OpenCode/Codex):

```
"Prepare Handoff"
```

(Custom-Command in `CLAUDE.md`, siehe [[Spec-Kit - Setup]] Memory-Architektur.) Generiert einen Task Brief mit Verweisen auf die Spec-Artefakte. Beispiel-Block:

```markdown
# TASK BRIEF — 002-hybrid-retrieval

## Ziel
Hybrid Retrieval (BM25 + Dense + RRF) als Default-Strategie im RAG-Service.

## Spec-Kit Referenzen
- Spec:  `.specify/specs/002-hybrid-retrieval/spec.md`
- Plan:  `.specify/specs/002-hybrid-retrieval/plan.md`
- Tasks: `.specify/specs/002-hybrid-retrieval/tasks.md`

## Scope
IN:  src/retrieval/, tests/test_retrieval*, evals/golden_set_eval.py
OUT: src/embedding/, src/api/ (außer Verdrahtung)

## Akzeptanzkriterien
- [ ] pytest tests/test_hybrid_retrieval.py grün
- [ ] Eval-Run grün (Recall@10 ≥ 0.85)
- [ ] pre-commit run --all-files grün
```

Executor implementiert strikt nach Spec-Artefakten.

## Schritt 8: Review gegen Spec

**Separater Agent**, neue Session, eigenes Context-Window:

```
/agents review-against-spec
```

Oder als One-Off:

```
Reviewe die Änderungen in diesem Branch gegen .specify/specs/002-hybrid-retrieval/spec.md.
Prüfe:
- Entspricht die Implementation der Spec?
- Gibt es Abweichungen oder fehlende Edge Cases?
- Sind die Constitution-Prinzipien eingehalten?
- Welche Learnings gehören in den Learnings-Abschnitt der Spec?
```

Findings zurück in die Spec, dann mergen.

## Schritt 9: Learnings & Changelog

Nach Implementation:

```
Aktualisiere .specify/specs/002-hybrid-retrieval/spec.md Learnings-Abschnitt mit:
- Was war anders als geplant?
- Welche Annahmen mussten korrigiert werden?
- Was würden wir beim nächsten Mal anders machen?

Ergänze im [Unreleased]-Abschnitt der CHANGELOG.md
(Format: Changelog-Guidelines.md beachten).
```

Spec-Kit pflegt keinen Changelog automatisch. Das ist Agent-gestützte Disziplin im Review-Schritt.

## Beispiel: RAG-Hybrid-Retrieval (durchgängig)

```bash
# 1. Constitution einmalig
claude
> /speckit.constitution
# (Dialog zu Eval-Pflicht, Embedding-Pinning, etc.)

# 2. Feature spezifizieren
> /speckit.specify
# (Dialog zu Hybrid-Retrieval-Feature)
# → .specify/specs/002-hybrid-retrieval/spec.md erstellt
# → Branch 002-hybrid-retrieval ausgecheckt

# 3. Edge Cases klären
> /speckit.clarify
# (Fragen zu BM25/Dense-Gewichtung, leeren Hits, etc.)

# 4. Plan + Research
> /speckit.plan
# → plan.md, research.md, data-model.md erstellt
# → Manuell research.md auf veraltete Lib-Versionen prüfen

# 5. Tasks
> /speckit.tasks
# → tasks.md mit atomaren Tasks und [P]-Markern

# 6. Konsistenz-Check
> /speckit.analyze
# → Report, Findings adressieren, erneut analyze bis grün

# 7. Implementation (single-agent)
> /speckit.implement
# (oder Handoff an OpenCode/Codex)

# 8. Review (separater Agent)
claude
> Reviewe Branch 002-hybrid-retrieval gegen Spec
# Findings, Learnings in Spec

# 9. CHANGELOG, Merge
```

## Best Practices in Spec-Kit-spezifisch

- **`/speckit.clarify` niemals überspringen**. Spec-Kit-Studien zeigen: das ist der Schritt, der den größten Unterschied macht.
- **`/speckit.analyze` vor jedem Handoff oder `/speckit.implement`**. Deckt Drift zwischen Artefakten auf, bevor Code entsteht.
- **`research.md` manuell prüfen**. Schützt vor veralteten AI-Annahmen.
- **Specs und Plans bei Bedarf manuell editieren**. Du bist Architect, nicht nur Zuschauer.
- **Constitution iterativ schärfen**. Nach jedem Feature: Gab es Constitution-Regeln, die gefehlt haben?
- **Tasks-File ist Vertrag**. Wenn der Executor anderswo hingeht, ist das Bug, nicht Feature.

Vollständige Best Practices: [[SDD - Best Practices]].

## Befehlsreferenz

```bash
# Setup (Terminal)
specify init <project> --ai <agent>     # Greenfield init
specify init . --here --force           # Brownfield init in current dir
specify check                           # Environment-Validierung
specify version                         # CLI-Version
```

```
# Workflow (Slash-Commands in der Agent-Session)
/speckit.constitution                   # Leitplanken
/speckit.specify                        # Feature definieren (legt Branch an)
/speckit.clarify                        # Edge Cases klären
/speckit.plan                           # Technische Architektur
/speckit.tasks                          # Task-Breakdown
/speckit.analyze                        # Konsistenz-Check (Quality Gate)
/speckit.implement                      # Implementation
/speckit.checklist                      # Quality-Checks generieren
/speckit.taskstoissues                  # Tasks zu GitHub Issues
```

## Quellen

- [GitHub — github/spec-kit](https://github.com/github/spec-kit)
- [Microsoft for Developers — Diving Into Spec-Driven Development With GitHub Spec Kit](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
- [LogRocket — Exploring spec-driven development with the new GitHub Spec Kit](https://blog.logrocket.com/github-spec-kit/)
- [Mosab Youssef — Spec Kit with Claude, Codex, and Gemini (April 2026)](https://ms3byoussef.medium.com/spec-kit-how-to-use-it-with-claude-codex-and-gemini-without-turning-your-project-into-3d4cdec2d7e1)
- [Rajeev Pentyala — GitHub Spec-Kit with Claude Code (Feb 2026)](https://rajeevpentyala.com/2026/02/22/github-spec-kit-with-claude-code-build-a-react-app-using-spec-driven-ai/)
- [Hidde de Smet — Spec-Kit Extensions](https://hiddedesmet.com/speckit-extensions)
