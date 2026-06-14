---
name: explore
description: "Systematische Read-only-Analyse eines Codebase-Bereichs. Triggert, wenn ich einen unbekannten Codebereich verstehen muss, bevor ich ihn anfasse — Patterns, betroffene Dateien, offene Fragen sichtbar machen."
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft
  primary_agent: plan   # Architect-Mode; delegiert weite Reads an den researcher-Subagent
---

# Explore — Codebase verstehen

Read-only Recon eines Code-Bereichs. Liefert die Grundlage, auf der `/spec` oder `/plan` aufsetzen.

## Trigger

- „Was passiert hier im Code?"
- „Wie funktioniert Modul X?"
- „Wo greift Feature Y in den Code ein?"
- Vor einem `/spec`, wenn die Codebase nicht hinreichend bekannt ist
- Expliziter Aufruf: `/explore <pfad-oder-thema>`

## Input

- Pfad, Modul oder Thema, das untersucht werden soll
- Optional: konkrete Fragen, die beantwortet werden sollen
- Optional: Vorab-Hypothesen (werden überprüft, nicht bestätigt)

## Constraints

- **Read-only.** Keine Edits, keine Bash-Schreiboperationen, kein Code-Generieren.
- Tool-Set: `Read`, `Grep`, `Glob`, optional `Bash(git log/show/diff)`.
- Maximaler Scope: ein klar abgegrenztes Modul oder Verzeichnis. Bei größerem Scope: in Sub-Explorations zerlegen.

## Schritte

1. **Einstieg lokalisieren** — Entry-Points finden (CLI-Befehle, Routen, Public-Module). `Grep` nach gängigen Mustern (`main`, `app.py`, `routes`, `cli`).
2. **Strukturkarte** — Verzeichnishierarchie, wichtige Dateien, ungefähre LoC pro Datei.
3. **Patterns identifizieren** — Naming-Conventions, Error-Handling-Style, Test-Layout, Logging-Approach. Inkonsistenzen explizit notieren.
4. **Abhängigkeiten** — Imports zwischen Modulen, externe Libs, Datenstrom durch das System.
5. **Offene Fragen** — alles, was sich aus dem Code allein nicht erklären lässt. Diese Fragen sind der wichtigste Output, weil sie die nächste Spec antreiben.

## Output

Markdown-Block mit fester Struktur:

```markdown
## Explore: <thema>

### Strukturkarte
- <pfad>: <was lebt hier>

### Patterns
- Naming: <beobachtung>
- Errors: <beobachtung>
- Tests: <beobachtung>

### Datenfluss
<text oder mermaid-diagramm>

### Externe Abhängigkeiten
- <lib>: <wofür>

### Offene Fragen
1. <frage>
2. <frage>
```

Keine Empfehlungen, keine Pläne, keine Code-Vorschläge in diesem Output. Das ist Aufgabe von `/spec` und `/plan`.

## Anti-Patterns

- Implementierung vorschlagen, ohne dass `/spec` durchgelaufen ist
- Dateien anpassen („wo ich schon dabei bin")
- Halbe Hypothesen als gesichert verkaufen — Unsicherheit ist Teil des Outputs

## Verweise

- Folgeskill: `/spec` (wenn das nächste Feature definiert werden muss) oder `/plan` (wenn nur ein Refactoring ansteht)
- Agent: Explorer (read-only, günstiges Modell)
