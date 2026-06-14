---
tags:
  - docnote
  - sdd
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# SDD — Best Practices (Stand Mai 2026)

Diese Sammlung destilliert, was 2026 in der Praxis funktioniert — toolunabhängig. Tool-spezifische Workflows stehen in den jeweiligen Workflow-Dokumenten.

## 1. Spec als Contract schreiben, nicht als Marketing-Copy

Eine Spec, die ausführt, was sich Stakeholder wünschen, ist Prosa. Eine Spec, gegen die ein Agent implementiert, ist ein **Contract**: kurz, strukturiert, testbar, mit expliziten Edge Cases und Akzeptanzkriterien.

Faustregel: Wenn ein Akzeptanzkriterium sich nicht in einen Test übersetzen lässt, ist die Spec zu vage. Mehr dazu bei [Augment Code (April 2026)](https://www.augmentcode.com/guides/vibe-coding-vs-spec-driven-development).

```markdown
## Akzeptanzkriterien
- [ ] Bei leerer Eingabe wird `ValidationError("input required")` geworfen
- [ ] Duplikate werden per (user_id, timestamp) deduped, neuester gewinnt
- [ ] `pre-commit run --all-files` läuft grün
- [ ] Migration ist reversibel (Down-Migration vorhanden)
```

Nicht: *"sollte robust mit Edge Cases umgehen"*.

## 2. Edge Cases vor der Implementation klären — formalisiert

Ambiguitäten sind 2026 weiterhin der **#1 Fehlergrund** bei AI-Implementationen ([MarkTechPost-Vergleich Mai 2026](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/)). Beide großen Tools (Spec-Kit, OpenSpec) haben dafür eigene Phasen:

- Spec-Kit: `/speckit.clarify` als eigene Phase mit persistierten Antworten in der `Clarifications`-Sektion der `spec.md`
- OpenSpec: Klärung passiert während `/opsx:propose`, persistiert in `proposal.md`

**Niemals überspringen.** Der Standardsatz von Tim Chao bringt es auf den Punkt: *"Du ersetzt jede AI-Annahme durch eine explizite Entscheidung"* ([Tim Chao, Feb 2026](https://www.timchao.site/en/articles/sdd-tools-comparison-speckit-openspec-superpowers)).

Konkrete Fragen, die in dieser Phase beantwortet sein müssen:

- Was passiert bei leerer Eingabe / NULL / Empty Result?
- Wie wird mit Duplikaten umgegangen?
- Maximale Limits, Paginierung, Timeouts?
- Sortierreihenfolge, Tiebreakers?
- Welcher Fehlertyp wird geworfen? Welcher Status-Code?
- Idempotenz: Was, wenn der gleiche Request zweimal kommt?

## 3. Non-Goals explizit definieren

Scope-Schutz funktioniert nur, wenn explizit steht, was *nicht* gemacht wird. Sonst füllt der Agent Lücken proaktiv.

```markdown
## Non-Goals
- KEINE Änderungen am bestehenden Auth-Modul
- KEINE neuen Migrations in dieser PR (folgt in #1234)
- KEINE Performance-Optimierung — nur Funktionalität
```

Beide Tools modellieren das anders, aber der Effekt ist identisch: Der Agent weiß, wo er **nicht** hingehört.

## 4. Tech-Stack erst im Plan, nicht in der Spec

Die Spec beschreibt *Was* und *Warum*. Frameworks, Datenbanken, Versionen gehören in `plan.md` (Spec-Kit) oder `design.md` (OpenSpec). Begründung: Eine technologie-agnostische Spec überlebt Stack-Migrationen und Tool-Wechsel.

Das ist auch der Hebel für **Living Specs across Tools** (siehe [InfoWorld, April 2026](https://www.infoworld.com/article/4166817/vibe-coding-or-spec-driven-development-how-to-choose.html)): Dieselbe Spec funktioniert in Claude Code, Cursor, Copilot — der Agent ist austauschbar, die Spec bleibt.

## 5. Separater Review-Agent statt Self-Verification

Der **am wenigsten genutzte und gleichzeitig wirkungsvollste Pattern** 2026: Implementierender Agent verifiziert nicht seine eigene Arbeit. Stattdessen prüft ein separater Agent (oder eine neue Session, oder ein Sub-Agent) die Änderungen gegen die Spec.

In Claude Code praktisch:

```
/agents review-against-spec  # Sub-Agent in eigener Context-Window-Sitzung
```

In Spec-Kit: `/speckit.analyze` als Konsistenz-Check zwischen den Artefakten (Spec ↔ Plan ↔ Tasks).

Siehe [Augment Code zu Best Practices 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools).

## 6. Constitution als Leitplanken auf Projekt-Ebene

Architektur-Entscheidungen, die für *alle* Features gelten ("Static First", "Zero External Dependencies", "TDD-Verpflichtung"), gehören nicht in jede einzelne Spec. Sie gehören in eine zentrale Constitution.

- Spec-Kit: `.specify/memory/constitution.md` (persistiert, vom Tool referenziert)
- OpenSpec: `openspec/AGENTS.md` (gleicher Mechanismus, anderer Name)
- Tool-agnostisch: `CLAUDE.md` / `AGENTS.md` im Repo-Root

Die Constitution wird bei jedem Spec-Schritt automatisch als Leitplanke herangezogen. Verhindert willkürliche AI-Entscheidungen und Architektur-Drift.

## 7. Learnings zurück in die Spec

Nach jeder Implementation: Was haben wir gelernt? Was war anders als geplant? **Diese Lessons gehören als `## Learnings`-Sektion zurück in die Spec.**

Warum kritisch: Ohne diesen Loop driftet die Spec vom Code ab und wird in 6 Monaten irreführend. Mit dem Loop entsteht ein Living Document, das zukünftige Agenten und Maintainer profitieren lässt.

Häufigster Failure-Mode (2026 weiterhin): Implementation läuft durch, PR ist gemerged, Spec-Update fällt unter den Tisch.

## 8. Brownfield: Context Acquisition zuerst

Auf bestehenden Codebases ist Spec-Schreiben aus dem Bauch heraus gefährlich. Der Agent muss zuerst verstehen, was schon da ist.

- OpenSpec ist hier nativ besser: brownfield-first, delta-basiert (`ADDED` / `MODIFIED` / `REMOVED`-Marker)
- Spec-Kit: `/speckit.analyze` vor `/speckit.specify` für initiale Context Acquisition
- Tool-agnostisch: Erst die Codebase indexieren (Repomix MCP o.Ä.), dann spezifizieren

Siehe [intent-driven.dev (März 2026)](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/) für eine ausführliche Brownfield-Strategie.

## 9. Spec auf Diff-Größe begrenzen

Ein Spec entspricht ungefähr **einer PR-Größe** (1-3 Tage Arbeit, < 500 LoC Diff). Größere Features werden in Sub-Specs zerlegt.

OpenSpec macht das nativ durch die Change-Folder-Struktur (eine Change = eine Spec). Bei Spec-Kit muss man das selbst disziplinieren — der Workflow lädt zur Mega-Spec ein.

Konsequenz wenn ignoriert: 800+ Zeilen Spec, niemand reviewt sie, Drift entsteht.

## 10. Spec-Format an Editor anpassen

Specs leben am besten direkt im Repo (`specs/` oder `.specify/specs/` oder `openspec/`). Damit:

- Versionierung über Git
- Branch-pro-Spec (beide Tools machen das automatisch)
- Reviews in PRs neben dem Code
- Spec wird mit dem Repo geclont — kein "wo war die Spec nochmal?"

## Anti-Patterns

| Anti-Pattern | Konsequenz |
|---|---|
| Spec überspringen bei "kleinen" Features | Kleine Features werden groß, dann fehlt der Rahmen |
| Tech-Details in der Spec | Kopplung an Stack, verliert Portabilität |
| AI blind vertrauen bei Edge Cases | Agent füllt Lücken mit plausiblen, aber falschen Annahmen |
| Mega-Spec für Mega-Feature | Niemand reviewt 800 Zeilen, Drift entsteht |
| Learnings nicht zurückschreiben | Spec driftet vom Code, wird nutzlos |
| Self-Review durch implementierenden Agent | Confirmation Bias, blinde Flecken bleiben |
| Spec-Kit auf Brownfield zwingen | Hoher Overhead, OpenSpec wäre passender |
| OpenSpec auf Greenfield zwingen | Fehlende Constitution-Disziplin, weniger Struktur |
| Spec nicht testbar formulieren | Akzeptanzkriterien werden zu Wischiwaschi |

## Bezug zu Robins Domänen

**Data Engineering.** Spec-Inhalt fokussiert auf Schema-Diffs, Backfill-Strategie, Idempotenz von Pipelines, erwartete Indizes, EXPLAIN-Erwartungen. Akzeptanzkriterien als Data-Quality-Checks (z.B. `dbt test` grün, Row-Counts within Tolerance).

**Data Science.** SDD greift erst nach der Exploration — typischerweise wenn ein Notebook-Prototyp in einen produktiven Service migriert wird. Spec als Output der Exploration, nicht Input.

**AI Engineering.** Specs für RAG-Pipelines klären: Chunk-Size-Policy, Embedding-Modell-Version, Retrieval-Strategie (BM25/dense/hybrid), Eval-Setup (LLM-as-Judge vs. golden set). Akzeptanzkriterien als Eval-Scores mit Threshold.

## Quellen

- [Augment Code — What Is Spec-Driven Development?](https://www.augmentcode.com/guides/what-is-spec-driven-development)
- [Augment Code — Vibe Coding vs Spec-Driven Development (2026)](https://www.augmentcode.com/guides/vibe-coding-vs-spec-driven-development)
- [Augment Code — 6 Best Spec-Driven Development Tools for AI Coding in 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools)
- [InfoWorld — Vibe coding or spec-driven development? How to choose (April 2026)](https://www.infoworld.com/article/4166817/vibe-coding-or-spec-driven-development-how-to-choose.html)
- [Tim Chao — Spec Kit vs. OpenSpec vs. Superpowers (Feb 2026)](https://www.timchao.site/en/articles/sdd-tools-comparison-speckit-openspec-superpowers)
- [MarkTechPost — 9 Best AI Tools for Spec-Driven Development in 2026](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/)
- [intent-driven.dev — SDD with Brownfield Projects (März 2026)](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/)
- [Thoughtworks — Spec-driven development](https://thoughtworks.medium.com/spec-driven-development-d85995a81387)
