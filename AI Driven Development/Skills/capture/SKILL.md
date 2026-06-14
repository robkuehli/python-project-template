---
name: capture
description: "Sichert Learnings nach Implementierung, Review oder Debug-Session in der passenden Wissensquelle. Triggert wenn etwas gelernt wurde, das in einer ähnlichen Situation in Zukunft helfen würde."
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft
  primary_agent: build   # Scribe-Rolle = dieses Skill + SessionEnd-Hook, kein stehender Agent mehr
---

# Capture — Learnings sichern

Compounding Engineering: jedes dokumentierte Learning verhindert Wiederholung des gleichen Fehlers. Ohne `/capture` geht das Wissen mit dem Conversation-Kontext verloren.

## Zwei Stufen — propose & confirm

Capture ist halbautomatisch (Inbox-Pattern):

1. **Propose (automatisch).** Ein SessionEnd-Hook (`~/.claude/hooks/capture-learnings.sh`) bzw. ein OpenCode-Plugin (`session.idle`) liest das Transkript, extrahiert mit einem günstigen/lokalen Modell 0..N Vorschläge und hängt sie als `[ ] proposed` an die **Staging-Inbox** (`LEARNINGS.inbox.md`). Diese Datei ist *nicht* im Kontext.
2. **Confirm (manuell, `/capture review`).** Du gehst die Vorschläge durch und promotest nur die guten in die kanonische `LEARNINGS.md`. Nur dieser Schritt schreibt in die Wahrheit — der Schutz vor Müll-Einträgen.

Der direkte Aufruf `/capture <thema>` (manuelle Einzelerfassung) bleibt weiter möglich und überspringt die Inbox.

## Trigger

- „Ich habe etwas gelernt"
- Nach `/review`, wenn unter „Learnings" Substanz steht
- Nach `/debug`, sobald die Ursache identifiziert wurde
- Expliziter Aufruf: `/capture <thema>`

## Input

- Konkretes Learning (Bug, Pattern, Falle, Best Practice)
- Kontext (Projekt, Datum, was gerade gemacht wurde)
- Anwendbarkeit: nur für dieses Projekt? Für alle Projekte? Für einen bestimmten Stack?

## Constraints

- **Eine Zeile pro Learning.** Wenn es länger sein muss, ist es kein Learning, sondern ein Doc.
- **Handlungsrelevant.** „Sei vorsichtig mit X" ist kein Learning. „Wenn X, dann Y prüfen, weil Z" ist eines.
- **Adressat passt zur Wissensquelle.** Persönlich → `~/.claude/LEARNINGS.md`. Projekt → `./CLAUDE.md` oder `./CONVENTIONS.md`. Agent-spezifisch → `./AGENTS.md`.

## Schritte

1. **Learning formulieren** — eine Zeile, plus minimaler Kontext
2. **Wissensquelle bestimmen** — Tabelle unten anwenden
3. **Eintrag schreiben** — Format einhalten (siehe Output)
4. **Quelle pflegen** — wenn die Datei voll wird (> 200 Zeilen): konsolidieren, nicht ergänzen

## Promote-Modus (`/capture review`)

Wird aufgerufen, wenn offene Vorschläge in der Inbox liegen (der SessionStart-Hook erinnert daran).

1. **Inbox lesen** — `LEARNINGS.inbox.md`, alle `[ ] proposed`-Zeilen.
2. **Pro Vorschlag entscheiden** — keep / edit / discard. Bar: handlungsrelevant, nicht einmalig (siehe Anti-Patterns).
3. **Wissensquelle bestimmen** — Tabelle unten; ein Vorschlag kann projekt- statt personenweit gehören.
4. **Promoten** — bestätigte Einträge im Zielformat in die kanonische Quelle (`LEARNINGS.md` / `CONVENTIONS.md` / `AGENTS.md`) schreiben, **newest first**.
5. **Inbox aufräumen** — promotete Zeile auf `[x] promoted` setzen oder entfernen; verworfene löschen. Inbox bleibt schlank.

**Idempotenz:** Mehrfaches `review` darf keine Duplikate erzeugen — bereits promotete (`[x]`) Zeilen werden übersprungen.

## Wissensquellen-Mapping

| Adressat | Datei | Wann |
|---|---|---|
| Persönliches Memory, projekt-übergreifend | `~/.claude/LEARNINGS.md` (eingebunden via `@` in `CLAUDE.md`) | Ich mache denselben Fehler in mehreren Projekten |
| Projekt-Konventionen für Menschen | `<projekt>/CONVENTIONS.md` | Konvention, die jeder Maintainer kennen muss |
| Projekt-Agent-Anweisungen | `<projekt>/CLAUDE.md`, `<projekt>/AGENTS.md` | Agent macht in diesem Projekt einen bestimmten Fehler |
| Spec-Kit-Constitution | `.specify/memory/constitution.md` | Architektur-Leitplanke fürs ganze Projekt |
| Spec Learnings | `specs/NNNN-<slug>.md` Sektion „Learnings" | Spezifisches Feature-Learning |

## Output

### LEARNINGS.md-Eintrag

```markdown
<!-- 2026-05-19 | projektname | Was schiefgelaufen ist -->
- Konkrete Regel, die das Problem in Zukunft verhindert
```

### CONVENTIONS.md-Eintrag

```markdown
## <Topic>

- **Was:** kurze Aussage
- **Warum:** Begründung in einem Satz
- **Beispiel:** code/Pfad-Verweis
```

### Spec-Learnings-Eintrag

```markdown
## Learnings

- <satz mit Datum> — was würde ich beim nächsten Mal anders machen
```

## Anti-Patterns

- Roman statt einzeiliger Regel
- „Sei besser bei X" — kein konkretes Verhalten
- Learnings, die nur einmal vorgekommen wären — nicht jeder Bug ist ein Learning
- Learnings ohne Kontext (Datum, Projekt) — werden in 6 Monaten unverständlich

## Verweise

- Voraussetzung: meist `/review` oder `/debug` voraus
- Self-Improvement-Loop: siehe `../../CLI-Tools/Claude-Code/Claude Code — Best Practices.md`, Sektion „Self-Improvement Loop (compounding engineering)" — Grundlagen: Boris Cherny (Claude-Code-Best-Practices: stabile `CLAUDE.md` + append-only `LEARNINGS.md`) + Kieran Klaassen (compound engineering)
- Beispiel-LEARNINGS.md: `../../CLI-Tools/Claude-Code/claude-config/LEARNINGS.md`
- Agent: Scribe (lokales Modell, leichtgewichtig)
