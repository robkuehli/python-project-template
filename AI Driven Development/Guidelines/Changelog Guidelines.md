---
tags:
  - docnote
Creation Date: 2026-04-24
Last Modified: 2026-04-24
Finished: true
---
Basierend auf [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Format

Die Datei heißt `CHANGELOG.md` und steht im Repo-Root. Jede Version hat einen eigenen Abschnitt, neueste zuerst. Datum im ISO-Format (`YYYY-MM-DD`).

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Neue Suchfunktion für Episoden-Archiv

## [1.2.0] - 2026-02-08

### Fixed
- Pagination bei leeren Ergebnissen
```

## Kategorien

Änderungen werden in genau diese Kategorien gruppiert:

| Kategorie | Wann verwenden |
|-----------|---------------|
| **Added** | Neue Features |
| **Changed** | Änderungen an bestehender Funktionalität |
| **Deprecated** | Features, die bald entfernt werden |
| **Removed** | Entfernte Features |
| **Fixed** | Bugfixes |
| **Security** | Sicherheitslücken geschlossen |

## Do's

- **`[Unreleased]`-Abschnitt pflegen** — sammelt laufende Änderungen und wird beim Release zur neuen Version.
- **Für Menschen schreiben, nicht für Maschinen** — klar beschreiben, was sich geändert hat und warum es relevant ist.
- **Jeden Eintrag einer Kategorie zuordnen** — gleichartige Änderungen gruppieren.
- **Datum im ISO-Format** — immer `YYYY-MM-DD`, keine regionalen Formate.
- **Deprecations dokumentieren** — Nutzer müssen wissen, was bald wegfällt, bevor es entfernt wird.
- **Breaking Changes hervorheben** — mit `BREAKING:` Präfix im Eintrag kennzeichnen.
- **Yanked Releases markieren** — `## [0.0.5] - 2014-12-13 [YANKED]`

## Don'ts

- **Keine Git-Log-Dumps** — Commit Messages sind kein Changelog. Merge-Commits, Typo-Fixes und Dokumentationsänderungen gehören nicht rein.
- **Keine inkonsistenten Einträge** — wenn der Changelog gepflegt wird, dann vollständig. Ein lückenhafter Changelog ist schlimmer als keiner.
- **Keine unklaren Datumsformate** — kein `02/08/2026` (ist das Februar oder August?). Immer ISO 8601.
- **Keine leeren Kategorien** — nur Kategorien auflisten, die auch Einträge haben.
- **Keine technischen Commit-Details** — "Refactored internal query builder" interessiert Endnutzer nicht. Stattdessen: "Suchergebnisse laden jetzt 3x schneller".
