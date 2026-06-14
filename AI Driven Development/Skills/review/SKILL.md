---
name: review
description: "Prüft Änderungen gegen die Spec, nicht gegen freies Urteil. Triggert nach jeder Implementierung — eigener Code oder Agent-Output. Erkennt Drift zwischen Spec und Implementierung, sammelt Learnings."
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft
  primary_agent: plan   # Architect-Mode; delegiert an reviewer-Subagent für unabhängiges read-only-Review
---

# Review — Änderungen prüfen

Verifikation gegen Spec und Akzeptanzkriterien. Nicht zu verwechseln mit Style-Review (das macht der Linter) oder freiem Code-Review (das ist subjektiv).

## Trigger

- „Ich will die Änderungen prüfen"
- Nach `/delegate`, sobald der Implementierer fertig ist
- Vor jedem Merge auf `main` / `master`
- Expliziter Aufruf: `/review <branch-oder-pr>`

## Input

- Branch oder Commit-Range
- Spec-Datei, gegen die geprüft wird

## Constraints

- **Gegen Spec, nicht gegen Geschmack.** Wenn die Spec etwas nicht fordert, ist „könnte schöner sein" kein Review-Kommentar.
- **Hypothesen-frei.** Keine vermuteten Bugs ohne Reproduktion.
- **Drift markieren, nicht stillschweigend übernehmen.** Wenn die Implementierung von der Spec abweicht, ist eines von beiden zu korrigieren.

## Schritte

1. **Diff lesen** — vollständigen Changeset durchgehen, betroffene Dateien notieren
2. **Spec abgleichen** — jedes Akzeptanzkriterium gegen Implementierung prüfen
3. **Tests laufen lassen** — `make check`, `pytest`, ggf. Integration-Suite
4. **Out-of-Scope-Check** — Wurden Dateien geändert, die laut Scope OUT waren?
5. **Edge Cases verifizieren** — sind die Edge Cases der Spec wirklich getestet (nicht nur erwähnt)?
6. **Learnings extrahieren** — was hat überrascht, was würde ich beim nächsten Mal anders machen?

## Output

```markdown
## Review: <branch>

### Akzeptanzkriterien-Status
- [x] AC#1 — erfüllt, Test test_x.py:line_42
- [x] AC#2 — erfüllt
- [ ] AC#3 — NICHT erfüllt — siehe Abweichung 1

### Abweichungen
1. <konkrete Stelle>: Spec sagt X, Code macht Y. Ursache: <vermutung>. Fix-Vorschlag: <option a oder b>

### Out-of-Scope-Änderungen
- src/<datei>: nicht in Scope, aber geändert. Begründung erforderlich.

### Drift / Spec-Update nötig
- Spec-Sektion X ist nicht mehr aktuell — soll Spec angepasst werden oder Code zurückgedreht?

### Tests
- Coverage: 87% (≥ 80% ✓)
- pre-commit: grün
- Edge Case A: nicht im Test gesichert — Test ergänzen

### Learnings (für /capture)
- <satz>
- <satz>
```

## Anti-Patterns

- Style-Kommentare im Review — gehört in den Linter
- „Sieht gut aus, merge ich" ohne AC-Check
- Drift stillschweigend akzeptieren
- Learnings nicht festhalten (siehe `/capture`)

## Verweise

- Voraussetzung: Spec mit klaren AC
- Folgeskill: `/capture` (für Learnings) oder zurück zu `/spec`/`/delegate` bei Drift
- Bei Spec-Kit-Workflow: `/speckit.analyze` läuft *vor* der Implementierung, dieser Skill *nach* der Implementierung
