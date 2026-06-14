---
name: plan
description: "Zerlegt eine Aufgabe in geordnete, ausführbare Schritte. Triggert für kleine Tasks ohne Spec direkt, für komplexe Tasks nach /spec. Macht Abhängigkeiten und Reihenfolge sichtbar."
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft
  primary_agent: plan   # Architect-Mode (komplex); einfache Pläne laufen direkt im build/Coder-Mode
---

# Plan — Implementierung strukturieren

Übersetzt Spec oder Aufgabe in eine ausführbare Schrittfolge. Macht implizite Reihenfolge explizit.

## Trigger

- „Wie gehe ich das an?"
- Nach `/spec`, vor `/test` oder `/delegate`
- Bei kleinen Tasks: direkt ohne vorherige Spec
- Expliziter Aufruf: `/plan <thema>`

## Input

- Spec-Datei (bei komplexen Tasks) ODER
- Direkte Aufgabenbeschreibung (bei einfachen Tasks)

## Constraints

- **Schritte sind atomar** — ein Schritt = ein logischer Commit-fähiger Vorgang
- **Reihenfolge ist begründet** — Abhängigkeiten zwischen Schritten explizit
- **Tests sind nicht der letzte Schritt** — TDD: Test vor Implementation, sonst Spec-konformes Test-First
- Wenn ein Schritt eine Architektur-Entscheidung erfordert, die nicht in der Spec steht: stoppen, zurück zu `/spec`

## Schritte

1. **Spec parsen** (oder bei einfachen Tasks: Aufgabe rekapitulieren)
2. **Schritt-Liste entwerfen** — vom Test-Setup bis zur Verifikation
3. **Abhängigkeiten markieren** — was kann parallel laufen, was sequenziell
4. **Dateipfade nennen** — keine Schritte ohne konkrete Datei-Erwähnung
5. **Risiko-Schritte markieren** — wo kann es schiefgehen, was ist der Rollback

## Output

```markdown
## Plan: <thema>

### Vorbedingungen
- <pfad>: <muss-zustand>

### Schritte
1. [test] tests/unit/test_x.py — Test für Y schreiben (rot)
2. [code] src/x.py — Funktion implementieren (Tests grün)
3. [code] src/x.py — Edge Case Z hinzufügen
4. [docs] README.md — Quickstart-Sektion anpassen
5. [check] make check — Validation-Pipeline grün

### Abhängigkeiten
- 2 hängt von 1 ab (TDD: Test zuerst)
- 4 und 5 sind unabhängig, können parallel

### Risiken
- Schritt 2: könnte Schema-Migration triggern → in eigener Spec klären
```

Tags `[test]`, `[code]`, `[docs]`, `[check]`, `[refactor]` standardisieren Lesbarkeit.

## Anti-Patterns

- „Schritt 1: Feature umsetzen." — zu grob, nicht atomar
- Pläne ohne Dateipfade — Agent halluziniert Struktur
- Tests am Ende statt zuerst — verletzt TDD-Disziplin der Akzeptanzkriterien
- Mega-Schritte, die mehrere Commits umfassen würden

## Verweise

- **Macht NICHT:** keine Requirements, AC oder Edge Cases (er)finden — das ist `/spec`. Dieses Skill nimmt eine Spec/Aufgabe als gegeben und übersetzt sie in Schritte.
- Folgeskills: `/test`, `/delegate` (bei autonomer Übergabe), Direktimplementierung
- Bei Spec-Kit: `/speckit.plan` und `/speckit.tasks` ersetzen dieses Skill
- Mode: `plan` (Architect) bei komplexen Plänen, `build` (Coder) bei einfachen
