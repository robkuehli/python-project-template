# Project Brief: Autonomer lokaler Coding-Agent für Overnight-PoCs

**Status:** Draft v1
**Datum:** 2026-05-18
**Autor:** [Name]

---

## 1. Ausgangslage

Ich möchte einen autonom arbeitenden Coding-Agenten betreiben, der nach Feierabend und über Nacht kleine Software-Projekte für mich umsetzt. Der Agent soll auf meiner vorhandenen Hardware laufen und für die eigentliche Code-Generierung **keine laufenden API-Kosten** verursachen.

## 2. Vision

Ein Setup, in dem ich abends innerhalb von ~30 Minuten eine Spezifikation erstelle, der Agent diese über Nacht autonom umsetzt, und ich morgens einen funktionsfähigen Entwurf (PoC, Showcase oder kleines MVP) mit grünen Tests vorfinde, den ich in 30–60 Minuten zu produktionsnahem Code verfeinern kann.

Mentales Modell: "Junior-Entwickler, der parallel drei Versuche macht und mir morgens den besten Draft liefert."

## 3. Hardware

- MacBook Pro mit M4 Pro
- 48 GB Unified Memory
- macOS aktuell

## 4. Use-Cases

### In Scope
- **Proof of Concepts:** Technik-Evaluierungen, "Geht das überhaupt?"-Projekte
- **Showcases:** Demo-fähige kleine Anwendungen für Präsentationen
- **Kleine MVPs:** Bis ~5–7 Dateien, ein Stack pro Projekt
- **Bekannte Patterns:** CRUD-APIs, CLI-Tools, kleine Dashboards, Daten-Pipelines, Demo-Frontends

### Out of Scope
- Produktiver Code ohne menschliches Review
- Brownfield-Refactoring an existierenden größeren Codebases
- Architektur-Entscheidungen ohne menschliche Vorgabe
- Sicherheitskritischer Code (Auth, Crypto, Payments)
- Multi-Datei-Features über 10+ Dateien

## 5. Anforderungen

### Funktionale Anforderungen (Must)
- F1: Autonomer Betrieb über 4–8 Stunden ohne menschliche Intervention
- F2: Parallele Versuche (mindestens 3) pro Aufgabe in isolierten Arbeitsverzeichnissen
- F3: Test-getriebenes Vorgehen: Erst Tests, dann Implementierung, Abbruchkriterium = Tests grün
- F4: Notification beim Abschluss oder bei Eskalation (z. B. Telegram/Pushover)
- F5: Vollständige Reproduzierbarkeit: jede Iteration nachvollziehbar aus Git + Logs

### Nicht-funktionale Anforderungen (Must)
- N1: Keine API-Kosten für Code-Generierung (lokales Modell)
- N2: Sandboxing: Agent hat keinen Zugriff auf SSH-Keys, AWS-Credentials, persönliche `.env`-Dateien
- N3: Netzwerk-Restriktion: Nach initialem Dependency-Install kein Internetzugriff aus dem Sandbox
- N4: Rollback-fähig: Snapshot vor Run, `git reset --hard` möglich

### Komfort-Anforderungen (Should)
- K1: Spec-Schreiben darf ein Frontier-Modell nutzen (kostet pro Projekt < 1 €)
- K2: Morgendliche Zusammenfassung: welcher Versuch wie weit kam
- K3: Konfigurierbares Eskalations-Verhalten ("nach N Fehlversuchen aufhören und Hypothesen-Log schreiben")

## 6. Realistische Erfolgserwartungen

Basierend auf SWE-bench Verified und vergleichbaren Benchmarks (Stand Mai 2026):

| Aufgaben-Typ | Erfolgsrate pro Einzelversuch | Erfolgsrate bei 3 Parallel-Versuchen |
|---|---|---|
| Einfache PoC (1–3 Dateien, klares Pattern) | ~60% | ~94% |
| Mittlere PoC (3–5 Dateien) | ~40% | ~78% |
| Kleines MVP (5–7 Dateien) | ~25% | ~58% |

**Konsequenz:** Bei mittleren/kleinen MVPs muss ich mit 1–2 unbrauchbaren Versuchen pro Nacht rechnen. Das ist akzeptabel, solange einer der drei Versuche eine brauchbare Basis liefert.

## 7. Definition of Done (pro PoC)

Ein autonom erzeugter PoC gilt als erfolgreich, wenn:

1. Alle generierten Tests grün durchlaufen
2. `pre-commit run --all-files` mit Exit-Code 0 endet
3. `README.md` existiert und beschreibt, wie der PoC zu starten ist
4. Keine unerlaubten Aktionen im Audit-Log (Netzwerk-Calls außerhalb erlaubter Hosts, Datei-Zugriffe außerhalb Sandbox)

## 8. Budget & Zeit

- **Einmaliger Setup-Aufwand:** ~1 Arbeitstag
- **Laufende Kosten:** Strom (~0,3–0,5 kWh pro Nacht), gelegentlich Spec-Phase mit Frontier-Modell (<1 €/Projekt)
- **Mein Zeitaufwand pro PoC:** ~30 Min Spec abends + ~30–60 Min Review/Polish morgens

## 9. Erfolgs-Indikatoren nach 30 Tagen Betrieb

- Mindestens 60% der gestarteten PoCs liefern morgens einen brauchbaren Draft
- Durchschnittliche Polishing-Zeit < 90 Minuten
- Kein Sicherheitsvorfall (Secrets-Leak, unerlaubter Netzwerk-Zugriff)
- Mein subjektives Urteil: "Das spart mir echte Zeit beim Schreiben von Drafts"

## 10. Bewusst akzeptierte Risiken

- Manchmal "fake green" Tests (Tests existieren, prüfen aber nicht das Richtige) → mitigiert durch Test-Review am Morgen
- Code-Qualität auf Junior-Niveau, Refactoring nötig → ist beabsichtigt (siehe mentales Modell)
- Gelegentliches Modell-Verhalten "läuft im Kreis" → mitigiert durch `max_iterations` und Eskalations-Log
- Quantisierungs-bedingte Fehler in Edge-Cases → akzeptabel im PoC-Kontext
