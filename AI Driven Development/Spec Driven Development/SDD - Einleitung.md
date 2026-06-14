---
tags:
  - docnote
  - sdd
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# Spec-Driven Development — Einleitung

## Was es ist

Spec-Driven Development (SDD) macht die **Spezifikation eines Features zur Single Source of Truth, bevor implementiert wird**. Statt Anforderungen im Chat zu diskutieren und den Agenten direkt Code generieren zu lassen, entsteht zuerst ein persistiertes Artefakt — typischerweise eine oder mehrere Markdown-Dateien — das *Was* und *Warum* klärt, Edge Cases auflöst und Akzeptanzkriterien definiert. Erst danach geht es ins *Wie*.

Die Methode ist nicht neu (siehe Waterfall, RFC-Kultur, Design Docs). Was 2026 zählt: **Specs sind die explizite Antwort auf das Drift-Problem agentischer Coding-Tools.** Wenn der Agent Lücken in der Anforderung mit plausiblen Annahmen füllt, driftet das Ergebnis. Eine Spec entzieht ihm diese Lücken.

Die Kernidee bei der modernen SDD-Variante ist ein **mehrstufiger Refinement-Prozess**, in dem jedes Artefakt als Quality-Filter für das nächste dient:

```
Constitution (Leitplanken) → Spec (Was/Warum) → Plan (Wie) → Tasks (Roadmap) → Code
                                       ↑                                          |
                                       └────── Learnings zurück in Spec ──────────┘
```

Die [Microsoft-Developer-Dokumentation zu Spec-Kit (Mai 2026)](https://developer.microsoft.com/blog/spec-driven-development-spec-kit) fasst die vier Grundpfeiler kompakt zusammen: *Intent-driven*, *Rich Specification*, *Multi-step Refinement*, *AI Reliance* — LLMs als strategische Partner für Interpretation, nicht als One-Shot-Generator.

## Wann es sich lohnt

✅ **Established** für diese Fälle:

| Aufgabe | Empfehlung |
|---|---|
| Neues Feature mit > 3 betroffenen Dateien | SDD |
| Schema-Änderung / Migration / Backfill | SDD (immer) |
| Refactoring mit API-Changes | SDD |
| Pipeline-Umbau (dbt-Modelle, Airflow-DAGs) | SDD |
| Neue RAG- oder Eval-Pipeline | SDD |
| Bug-Fix in 1–2 Dateien | Basis-Workflow (kein SDD) |
| Linting, Docstrings, Config-Änderung | Basis-Workflow |
| Spike / Prototyp / Wochenend-Hack | Basis-Workflow |

Faustregel von [Augment Code (April 2026)](https://www.augmentcode.com/guides/vibe-coding-vs-spec-driven-development):

> *"If you'd be annoyed to have the agent interpret requirements differently than you meant, you write the spec. If you could fix the output in a quick follow-up prompt, you skip the spec."*

## Was es konkret bringt

- **Weniger Token-Verschwendung.** Der Agent bekommt eine geklärte Spec statt einer vagen Chat-Diskussion. GitHub berichtet von ca. einer Größenordnung weniger "Regenerate-from-scratch"-Zyklen im Vergleich zu ad-hoc Prompting (siehe [Augment Code, 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools)).
- **Weniger Fehlimplementationen.** Edge Cases sind vorher entschieden, nicht während der Implementierung halluziniert.
- **Schnellere Reviews.** Reviewer (Mensch oder Agent) prüft gegen die Spec, nicht gegen eine flüchtige Chat-Historie.
- **Tool-Portabilität.** Eine versionierte Spec überlebt den Wechsel von Claude Code → OpenCode → Copilot. Sie ist das durable Artefakt, der Agent ist austauschbar.
- **Wissenstransfer.** Die Spec dokumentiert Entscheidungen für zukünftige Maintainer und für dich selbst in drei Monaten.

## Kritische Betrachtung

SDD is no free Lunch. Die kritischen Stimmen 2026 sind konsistent — wer SDD cargo-cultet, verbrennt Zeit ohne Gegenwert.

**Overhead vs. Nutzen.** Specs schreiben kostet Zeit *vor* der Implementation. Für triviale Tasks sind das pure Kosten ohne Gegenwert. [Mehrere Praxisberichte (DEV.to, Feb 2026)](https://dev.to/incomplete_developer/is-there-a-middle-ground-between-vibe-coding-and-spec-driven-development-31ek) beschreiben absurde Auswüchse — z.B. ein 4-User-Story-Spec mit 16 Akzeptanzkriterien für einen Einzeiler-Bugfix.

**Verbose Specs erschlagen den Vorteil.** Spec-Kit-Specs liegen typischerweise bei ~800 Zeilen, OpenSpec bei ~250 (siehe [Tim Chao, Spec-Tool-Vergleich Feb 2026](https://www.timchao.site/en/articles/sdd-tools-comparison-speckit-openspec-superpowers)). Wenn die Spec länger wird als die resultierende Implementation, hast du das Tool falsch eingesetzt.

**Falscher Reifegrad-Fit.** SDD lohnt sich für stabile, komplexe Projekte mit Integrationspunkten und mehreren Beteiligten. Für Solo-Spikes, schnell mutierende Prototypen oder reine CRUD-Apps ist der Prozess Overkill. Das schließt einen großen Teil der explorativen Data-Science-Arbeit ein.

**Drift bei langen Multi-Service-Initiativen.** Im [SDD-Tool-Vergleichstest von MarkTechPost (Mai 2026)](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/) zeigte sich bei mehrwöchigen Initiativen Drift zwischen Spec und Implementation, wenn nicht aktiv re-aligned wird. Specs sind keine Set-and-Forget-Artefakte.

**Spec-Pflege fällt oft unter den Tisch.** Wenn der Learnings-Abschnitt nicht nach jeder Iteration aktualisiert wird, driftet die Spec vom Code ab und wird in 6 Monaten zur irreführenden Doku. Das ist der häufigste Failure-Mode in Praxisberichten.

**Pragmatischer Mittelweg** (Konsens 2026): Vibe-coden zum Erkunden, dann formalisieren bevor es in Production geht. Spec als *Output* der Exploration, nicht zwingend als *Input*. Siehe auch [Thoughtworks-Position](https://thoughtworks.medium.com/spec-driven-development-d85995a81387).

## Bezug zu Robins Domänen

| Domäne | Typischer Einsatz |
|---|---|
| **Data Engineering** | Pipeline-Refactorings (z.B. dbt-Modell-Restrukturierung), Schema-Migrationen mit Backfill, neue Ingestion-Strecken. Brownfield dominiert → **OpenSpec** als Default. |
| **Data Science** | Spec als *Output* der Notebook-Exploration: erst frei explorieren, dann findings → Spec → Produktivierung. SDD im Notebook-Loop selbst meist overkill. |
| **AI Engineering** | Neue RAG-Pipelines, Agent-Architekturen, Eval-Setups. Häufig greenfield → **Spec-Kit** für strukturierten Aufbau, OpenSpec für iterative Erweiterungen. |

## Weiterführend

- [[SDD - Best Practices]] — was 2026 konkret funktioniert
- [[SDD - Tool-Empfehlungen]] — Spec-Kit vs. OpenSpec, Entscheidungskriterien
- [[Developer Workflow]] — wo SDD im Gesamt-Workflow andockt

## Quellen

- [Microsoft for Developers — Diving Into Spec-Driven Development With GitHub Spec Kit (2026)](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
- [Augment Code — What Is Spec-Driven Development?](https://www.augmentcode.com/guides/what-is-spec-driven-development)
- [Augment Code — Vibe Coding vs Spec-Driven Development (April 2026)](https://www.augmentcode.com/guides/vibe-coding-vs-spec-driven-development)
- [Augment Code — 6 Best Spec-Driven Development Tools for AI Coding in 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools)
- [Thoughtworks — Spec-driven development](https://thoughtworks.medium.com/spec-driven-development-d85995a81387)
- [Tim Chao — Spec Kit vs. OpenSpec vs. Superpowers (Feb 2026)](https://www.timchao.site/en/articles/sdd-tools-comparison-speckit-openspec-superpowers)
- [MarkTechPost — 9 Best AI Tools for Spec-Driven Development in 2026 (Mai 2026)](https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/)
- [DEV.to — Is There a Middle Ground Between Vibe Coding and Spec Driven Development? (Feb 2026)](https://dev.to/incomplete_developer/is-there-a-middle-ground-between-vibe-coding-and-spec-driven-development-31ek)
