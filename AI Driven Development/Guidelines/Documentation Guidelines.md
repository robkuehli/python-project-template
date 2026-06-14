---
tags:
  - docnote
Creation Date: 2026-05-19
Last Modified: 2026-05-21
Finished: true
---

# Das Dokumentations-Manifest
### Doku ist kein Artefakt, sondern ein Werkzeug für die nächste Person — Mensch oder Agent
*Rückgrat: [Diátaxis](https://diataxis.fr/) von Daniele Procida (entstanden bei Divio, vorgestellt auf der PyCon AU 2017: [„What nobody tells you about documentation"](https://www.youtube.com/watch?v=t4vKPhjcMZg)). Flankiert von Andrew Etter, Cyrille Martraire, Simon Willison und Michael Nygard.*

---

## Leitsatz

**Dokumentation existiert, damit die nächste Person — Mensch oder Agent — schneller produktiv wird.** Wenn ein Dokument das nicht leistet, ist es Ballast. Doku wird nicht für den Autor geschrieben, sondern für einen Leser, der in einem konkreten Moment eine konkrete Sache braucht.

---

## 1. Die Neudefinition: Es gibt nicht „die Doku" — es gibt vier

Die entscheidende Erkenntnis von [Diátaxis](https://diataxis.fr/) (in David Laings Worten die *„Grand Unified Theory of Documentation"*): **„There isn't one thing called documentation, there are four."** Schlechte Doku ist fast immer schlecht, weil sie versucht, alle vier gleichzeitig zu sein — ein Tutorial, das in Referenz-Details ertrinkt; eine Referenz, die in Tutorial-Händchenhalten abrutscht.

Jeder der vier Modi bedient einen anderen Leser in einem anderen Moment. Sie zu vermischen ist die Wurzel der meisten Doku-Frustration — analog zur *Test-Depression* im Test-Manifest.

---

## 2. Der Kompass: Vier Modi, zwei Fragen

Bei Unsicherheit *„Welche Art Doku ist das?"* entscheidet der [Diátaxis-Kompass](https://diataxis.fr/compass/) mit genau zwei Fragen: **Action oder Cognition? Acquisition oder Application?**

| Inhalt informiert… | …im Dienst von… | …also ist es… | Leitfrage des Lesers |
|---|---|---|---|
| **Action** (Handeln) | **Acquisition** (Lernen) | **Tutorial** | „Zeig mir, wie ich überhaupt anfange." |
| **Action** (Handeln) | **Application** (Arbeiten) | **How-to-Guide** | „Wie löse ich konkret Problem X?" |
| **Cognition** (Wissen) | **Application** (Arbeiten) | **Reference** | „Was genau erwartet/liefert X?" |
| **Cognition** (Wissen) | **Acquisition** (Lernen) | **Explanation** | „Warum ist das so gebaut?" |

**Regel:** Ein Dokument bedient genau einen Modus. Fühlt sich ein Text „off" an, ist es fast immer Mode-Mixing — Kompass anlegen, splitten.

Abbildung auf ein Repo:

| Modus | Wo es lebt |
|---|---|
| Tutorial | `docs/getting-started.md` — *ein* erfolgreicher erster Lauf, nicht vollständig |
| How-to | `docs/how-to/*.md` — Rezepte für reale Aufgaben |
| Reference | generierte API-Doku, `--help`, Config-Schema, dbt-`description`-Felder |
| Explanation | `docs/architecture.md`, ADRs, Design-Rationale |

---

## 3. Kernprinzipien

| Prinzip | Beschreibung |
|---|---|
| **Leser- statt Autor-zentriert** | Maßstab ist nicht „habe ich es aufgeschrieben", sondern „wird der Leser damit fertig". [Diátaxis-Qualität](https://diataxis.fr/quality/) misst am Bedürfnis, nicht an Vollständigkeit. |
| **Single Source of Truth** | Genau *eine* Quelle der Wahrheit; alles andere sind Referenzen (Links/Annotationen), keine Kopien. Wissen so nah wie möglich am Code halten — Cyrille Martraire, *[Living Documentation](https://www.oreilly.com/library/view/living-documentation-continuous/9780134689418/)* (2019). |
| **Docs-as-Code** | Lightweight Markup, im selben Repo wie der Code, versioniert, in PRs reviewt, via Static-Site-Generator publiziert — Andrew Etter, *[Modern Technical Writing](https://www.amazon.com/Modern-Technical-Writing-Introduction-Documentation-ebook/dp/B01A2QL9SS)* (2016). Doku im selben Repo reduziert Drift und senkt die Beitragsschwelle. |
| **Generieren statt pflegen** | API-Referenz, Diagramme, Glossare aus der Quelle ableiten. Handgepflegte Referenz divergiert garantiert (Martraire). |
| **Doku reist im selben Commit** | Implementation + Tests + Doku-Update + Issue-Link in *einem* fokussierten Commit — Simon Willison, *[The Perfect Commit](https://simonwillison.net/2022/Oct/29/the-perfect-commit/)* (2022-10-29). So entsteht Drift gar nicht erst. |
| **90 / 10** | 90 % der Zeit verstehen (testen, recherchieren), 10 % schreiben. Erst verstehen, dann formulieren (Etter). |

---

## 4. Living Documentation: Doku stirbt mit dem Code

**Doku ohne Pflege ist schlimmer als keine — sie ist aktiv irreführend.** Drift ist der eigentliche Gegner, nicht Lückenhaftigkeit. Die Gegenmittel sind mechanisch, nicht disziplinarisch:

- **Im Repo, nicht daneben.** Externe Tools (Confluence, Draw.io, Excalidraw) erzeugen Drift. Mermaid-Diagramme im Markdown sind versioniert und PR-reviewbar.
- **Im Commit, nicht hinterher** (Willison): Wer die Doku im selben Commit aktualisiert, hält sie definitionsgemäß synchron.
- **In CI erzwingen:** Docstring-Coverage via `interrogate` im Pre-Commit; API-Doku im CI bauen; README-Quickstart bei jedem Release auf frischer Umgebung laufen lassen — bricht er, vor dem Release fixen.
- **Append-only für Entscheidungen:** ADRs werden nie gelöscht oder geändert, nur per `Superseded by` ersetzt.

---

## 5. Anti-Patterns

| Anti-Pattern | Symptom | Korrektur |
|---|---|---|
| **Mode-Mixing** | Tutorial erstickt in Referenz-Details; Referenz hält Händchen. | Kompass anlegen, in vier Modi splitten. |
| **Wishful Documentation** | Doku beschreibt geplante Features als wären sie da. | Nur dokumentieren, was im aktuellen Code lebt. |
| **Copy-Paste-Wahrheit** | Dieselbe Info an drei Stellen, zwei davon veraltet. | Single Source of Truth + Referenzen (Martraire). |
| **Wall-of-Text-README** | Endlos-README ohne Struktur. | README = Eingangstor; Tiefe nach `docs/`. |
| **Doc-as-Comments** | Riesige Block-Kommentare statt Docstrings. | In Docstrings umziehen, dann generieren. |
| **Outdated Screenshots** | UI-Bilder, die nicht mehr passen. | Generieren (Playwright-Skript) oder weglassen. |

---

## 6. Praxis-Schicht (dünn)

Das Manifest ist abstrakt; vier Artefakte sind konkret genug, um sie hier festzuhalten.

**README — das Eingangstor.** Kein Diátaxis-Modus, sondern der Index: *Was ist das* (ein Satz), *Quickstart* (`git clone … && make setup && make test` muss reichen), *wichtigste Befehle*, *wo finde ich was* (`docs/`, `CHANGELOG.md`, `CLAUDE.md`). Tiefe Architektur, vollständige API, Tutorials → raus nach `docs/`.

**Docstrings = Reference-Vertrag** (Google Style, von `sphinx-napoleon`/`mkdocstrings` direkt verstanden). Pflicht für jede public Funktion/Klasse und jede nicht-triviale Logik; weglassen bei trivialen privaten Helpern und Property-Gettern.

```python
def fetch_episodes(podcast_id: str, limit: int = 50) -> list[Episode]:
    """Fetch episodes for a podcast, newest first.

    Args:
        podcast_id: The podcast's slug, e.g. "darknet-diaries".
        limit: Maximum number of episodes to return. Defaults to 50.

    Returns:
        Episodes ordered by publication date, newest first.

    Raises:
        PodcastNotFoundError: If the podcast slug is unknown.
    """
```

**ADR = Explanation-Artefakt** — Michael Nygard, *[Documenting Architecture Decisions](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions)* (2011-11-15). Kurz, nummeriert, append-only:

```markdown
# ADR-NNN: <Titel>
## Status
Proposed | Accepted | Deprecated | Superseded by ADR-MMM
## Context
Welche Situation erzwingt die Entscheidung?
## Decision
Was wurde entschieden — in einem Satz.
## Consequences
Positiv und negativ, beides ehrlich.
## Alternatives considered
Was wurde verworfen und warum?
```

Reales Beispiel: `../Autonomer Coding Agent/02-adrs.md`.

**Diagramme** als Mermaid im Markdown (C4 Level 1–2 reicht meist), damit sie versioniert und im PR reviewt werden.

---

## 7. Im Agenten-Zeitalter

`CLAUDE.md` / `AGENTS.md` / Constitution / Skills sind ebenfalls Dokumentation — nur ist der Leser ein Agent. Der Kompass gilt unverändert: ein Agent braucht **Reference** (Commands, Conventions) und **Explanation** (Architektur, Invarianten), praktisch nie Tutorials. Unter ~200 Zeilen halten, versionieren und reviewen wie Code.

Mapping auf die eigenen Domänen — Single Source of Truth wiegt doppelt, sobald ein Agent auf Basis der Doku *handelt*:

- **Data Engineering:** dbt-`description`-Felder sind generierte Reference; Pipeline-Verträge (Schemas, SLAs) als Explanation. Doku aus dem Modell ableiten, nicht daneben pflegen.
- **Data Science:** Notebook → reproduzierbarer Report; das *Warum* eines Experiments als Explanation, Parameter/Metriken als generierte Reference.
- **AI Engineering:** Model Cards und Eval-Reports sind Explanation + Reference in einem; Prompt- und RAG-Pipelines als versionierte Artefakte, nicht als Tribal Knowledge.

---

## Call to Action

```
Frag den Kompass: Action oder Cognition? Acquisition oder Application?
Schreibe vier Dinge, nicht eins — und nie zwei davon im selben Dokument.
Eine Wahrheit, der Rest sind Referenzen.
Doku lebt im Repo und reist im selben Commit wie der Code.
Generiere, was generierbar ist.
Verstehe erst, schreibe dann.
Doku ohne Pflege ist Lüge mit Verzögerung.
```

---

## Querverweise

- `Changelog Guidelines.md` — Release-Notes (Keep a Changelog)
- `Testing Guidelines.md` — Schwesternmanifest; Verhalten als Vertrag
- `Testing Guidelines (AI Agent).md` — operative AI-Variante
- `Pre-Commit Guidelines.md` — Doc-Linting (`interrogate`, Docstring-Coverage)
- `../Autonomer Coding Agent/02-adrs.md` — reales ADR-Beispiel
- `../CLI-Tools/Claude-Code/Claude Code — Best Practices.md` — `CLAUDE.md`-Patterns
