---
name: spec
description: "Vollständige Spezifikation für komplexe Tasks oder neue Features. Triggert vor jeder Implementierung mit unklaren Edge Cases, unklarem Scope oder Risiko für AI-Annahmen. Erzwingt explizite Antworten auf Edge Cases."
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft
  primary_agent: plan   # Architect-Mode
---

# Spec — Feature spezifizieren

Übersetzt eine vage Idee in ein vollständiges, prüfbares Markdown-Artefakt. Single Source of Truth für die Implementierung.

## Trigger

- „Ich muss ein Feature definieren"
- „Wie soll X funktionieren?"
- Vor `/plan`, wenn nicht alle Edge Cases klar sind
- Expliziter Aufruf: `/spec <kurztitel>`

## Input

- Feature-Idee oder Problem-Beschreibung
- Optional: Output eines vorherigen `/explore`
- Optional: vorhandene ähnliche Specs als Vorbild

## Constraints

- **Was und Warum, nicht Wie.** Technische Implementierungsdetails kommen erst in `/plan`.
- **Edge Cases sind Pflicht.** Wer nicht explizit beantwortet wurde, wird vom Implementierer halluziniert.
- **Out of Scope ist genauso wichtig wie In Scope.**
- Bei Wissenslücken: in eigener Sektion auflisten, **nicht durch Annahmen füllen**.

## Schritte

1. **Kontext** — was ist das Problem, wer ist betroffen, aktuelles vs. gewünschtes Verhalten
2. **Ziele** — messbare Outcomes
3. **Non-Goals** — was explizit nicht zum Scope gehört
4. **Edge Cases klären** — durch gezielte Rückfragen, **nicht** durch eigene Annahmen
5. **Akzeptanzkriterien** — was muss prüfbar wahr sein, damit „fertig" gilt
6. **Wissenslücken markieren** — alles, was offen bleibt

## Output

Datei: `specs/NNNN-<feature-slug>.md` (oder bei Spec-Kit: `.specify/specs/NNN-<feature>/spec.md`).

Pflicht-Sektionen:

```markdown
---
id: NNNN
title: "<Feature>"
status: draft
created: YYYY-MM-DD
---

## Kontext / Problem

## Ziele

## Non-Goals

## Edge Cases & Clarifications
- Frage: Antwort
- Frage: Antwort

## Akzeptanzkriterien (Definition of Done)
- [ ] …

## Wissenslücken
- offen: …

## Learnings
(wird nach Implementierung gefüllt)
```

## Anti-Patterns

- Technische Details (DB-Schema, API-Signaturen) in der Spec — gehört in `/plan`
- Edge Cases überspringen, weil „die werden sich im Code zeigen"
- Vage AC ohne testbare Aussage („soll performant sein")
- Spec nach Implementierung nicht aktualisieren (Drift)

## Verweise

- **Macht NICHT:** keine Implementierungsdetails (Schritte, DB-Schema, API-Signaturen) — das ist `/plan`. Spec bleibt bei WAS + WARUM.
- Folgeskills: `/plan`, `/test`
- Bei Spec-Kit: `/speckit.specify` und `/speckit.clarify` ersetzen dieses Skill
- Template: `references/spec-template.md` (TODO: noch zu schreiben)
- Konvention: `../../Guidelines/Documentation Guidelines.md`
