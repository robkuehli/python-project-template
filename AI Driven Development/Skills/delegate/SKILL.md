---
name: delegate
description: "Übergibt eine vollständig vorbereitete Aufgabe an einen Coding-Agent. Triggert wenn Spec + Plan + Tests vorhanden und ich die Implementierung autonom laufen lassen will. Erzeugt ein Agent-Bundle, das alle Lücken vorab schließt."
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft
  primary_agent: build   # Coder-Mode
---

# Delegate — Aufgabe an Agenten übergeben

Schnürt das Übergabepaket so, dass der Implementierungs-Agent **keine Annahmen** mehr treffen muss.

## Trigger

- „Das soll ein Agent autonom umsetzen"
- Vor einem autonomen Run (vgl. `../../Autonomer Coding Agent/`)
- Expliziter Aufruf: `/delegate <spec-pfad>`

## Input — alle drei MÜSSEN existieren

- Vollständige Spec mit Edge Cases und Akzeptanzkriterien (`/spec`)
- Konkreter Plan mit atomaren Schritten (`/plan`)
- Test-Stubs in initial rotem Zustand (`/test`)

Fehlt eines davon: **stoppen, fehlendes Artefakt zuerst erstellen**. Delegation ohne Grundlage produziert garantiert Drift.

## Constraints

- **Kein Agent-Brief länger als 2 KB Kontext-relevanter Text.** Verweise auf Spec-Datei statt Inline-Kopie.
- **Scope IN und OUT explizit.** Welche Dateien darf der Agent anfassen, welche nicht.
- **Done-Kriterien sind objektiv prüfbar.** Tests grün, pre-commit grün, Coverage über Schwelle.
- **Eskalations-Regel benannt.** Was tun, wenn N Iterationen nicht reichen — `DEBUG_HYPOTHESES.md` schreiben und stoppen.

## Schritte

1. **Vollständigkeit prüfen** — Spec + Plan + Tests vorhanden, AC eindeutig, Tests rot
2. **Scope-Liste erzeugen** — Dateien IN (read+write), Dateien OUT (read-only oder gar nicht)
3. **Agent-Bundle schreiben** — strukturierter Brief mit allen Verweisen
4. **Eskalations-Regel anhängen** — wann der Agent stoppt
5. **Übergabe** — Bundle als Prompt an den Coder-Agent geben, Output-Pfad für `DEBUG_HYPOTHESES.md` definieren

## Output — Agent Bundle

```markdown
# TASK BRIEF

## Ziel
<1 Satz, direkt aus Spec>

## Quellen (zwingend lesen)
- Spec: specs/NNNN-<slug>.md
- Plan: specs/NNNN-<slug>.plan.md
- Tests: tests/unit/test_<feature>.py (aktuell rot)

## Scope
IN: <pfade die geändert werden dürfen>
OUT: <pfade die nicht angefasst werden>

## Done-Kriterien
- [ ] pytest mit allen Tests aus Scope grün
- [ ] make check (ruff + mypy + pytest) grün
- [ ] Coverage ≥ 80% (siehe pyproject.toml)
- [ ] CHANGELOG.md [Unreleased]-Sektion ergänzt

## Eskalation
Nach 3 Iterationen ohne Fortschritt: stoppen, DEBUG_HYPOTHESES.md schreiben mit:
- Was wurde versucht
- Warum es scheiterte
- 2–3 Hypothesen

## Constraints
- Strikt nach Spec, keine ungebetenen Features
- Atomare Commits, eine logische Änderung pro Commit
- Nichts außerhalb Scope-IN ändern
```

## Anti-Patterns

- Delegation ohne Tests — Agent kann nicht objektiv „fertig" feststellen
- „Mach mal Feature X" als Bundle — vollständige Anti-These dieses Skills
- Scope OUT nicht definiert — Agent ändert irgendwo am Rand etwas mit
- Eskalations-Regel weggelassen — Agent loopt bis Token-Limit

## Verweise

- Voraussetzungen: `/spec`, `/plan`, `/test`
- Folgeskill: `/review` nach Abschluss
- Autonomer Modus: `../../Autonomer Coding Agent/` mit Orchestrator, Worktrees, Eskalation
