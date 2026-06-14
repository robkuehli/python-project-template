---
name: debug
description: "Systematische Fehlersuche statt Raten. Triggert wenn etwas nicht funktioniert und die Ursache nicht offensichtlich ist. Erzeugt Hypothesen, Diagnoseschritte und am Ende die identifizierte Ursache."
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

# Debug — Fehlerursache finden

Wissenschaftliche Methode für Fehler: Reproduzieren → Isolieren → Hypothesen → Test → Ursache.

## Trigger

- „Etwas funktioniert nicht"
- Bei fehlschlagenden Tests, Crashes, falschen Outputs
- Expliziter Aufruf: `/debug <symptom>`

## Input

- Konkretes Symptom (Fehlertext, falscher Output, Crash, Hang)
- Minimaler Reproduktionspfad ODER der Pfad, ihn herzustellen
- Optional: Logs, Stack Traces, letzter funktionierender Commit

## Constraints

- **Erst reproduzieren, dann hypothetisieren.** Ohne Reproduktion ist jede Hypothese reine Spekulation.
- **Eine Hypothese pro Experiment.** Mehrere Änderungen gleichzeitig verschleiern, was geholfen hat.
- **Nach drei erfolglosen Versuchen stoppen.** Hypothesen-Liste, was bisher ausprobiert wurde, was übrig bleibt. Dann nach mehr Kontext fragen.

## Schritte

1. **Reproduzieren** — minimaler, deterministischer Pfad zum Fehler
2. **Isolieren** — Was ist der kleinste Code-Bereich, der den Fehler enthält? Bisection im Diff (Git Bisect) oder im Code (binäre Suche)
3. **Hypothesen sammeln** — 2–3 plausible Ursachen, mit Begründung
4. **Hypothesen ranken** — wahrscheinlichste / einfachst zu prüfende zuerst
5. **Experiment** — eine Hypothese minimal-invasiv prüfen
6. **Ergebnis dokumentieren** — bestätigt oder verworfen, mit was-genau-passierte
7. **Bei Bestätigung:** Fix + Regressions-Test (siehe `/test`)
8. **Bei Verwerfung:** nächste Hypothese, oder bei drei Fehlschlägen: stoppen und Kontext einholen

## Output

```markdown
## Debug: <symptom>

### Reproduktion
<minimaler Schritt-für-Schritt>

### Isolierung
Fehler liegt in: <datei:zeile> oder <commit-range>

### Hypothesen
1. <hypothese> — Wahrscheinlichkeit: <einschätzung>, Prüfaufwand: <einschätzung>
2. <hypothese> — …
3. <hypothese> — …

### Experimente
- H1: <experiment> → Ergebnis: <verworfen weil … | bestätigt durch …>
- H2: <experiment> → Ergebnis: …

### Ursache
<konkrete root cause>

### Fix
- Code-Änderung: <datei:zeile>
- Regressions-Test: tests/<pfad>::<test>

### Learnings (für /capture)
- <satz>
```

Bei Stopp ohne Lösung:

```markdown
### Status: ungelöst nach 3 Hypothesen
Versucht:
- <experiment 1>
- <experiment 2>
- <experiment 3>

Offene Hypothesen:
- <hypothese>
- <hypothese>

Benötigter zusätzlicher Kontext:
- <was klären?>
```

## Anti-Patterns

- „Try this and see if it works" — keine Hypothese, kein Experiment
- Mehrere Änderungen gleichzeitig — Confounding
- Symptom-Fix statt Ursachen-Fix („Test schreiben, der das Verhalten erlaubt")
- Endlos-Debuggen ohne Stopp-Kriterium

## Verweise

- Folgeskill: `/test` (für Regressions-Test), `/capture` (für Learning)
- Quellenkonvention: bei produktiven Fehlern Logs als Quelle nennen, nicht aus dem Bauch
- Agent: Coder
