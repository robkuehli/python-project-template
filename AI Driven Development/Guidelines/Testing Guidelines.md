---
tags:
  - docnote
Creation Date: 2026-05-19
Last Modified: 2026-05-19
Finished: false
---

# Das Moderne Test-Manifest
### Fokus auf Wertschöpfung und End-User-Funktionalität
*Basierend auf [„They Are Not Unit Tests"](https://www.youtube.com/watch?v=9MWXHbF9cPA) von Stanislav Zmiev*

---

## 1. Die Neudefinition der „Unit"

Die entscheidende Erkenntnis der modernen Testphilosophie: Eine *Unit* ist kein technisches Artefakt (Funktion, Klasse, Modul), sondern ein **Verhaltensvertrag gegenüber einem Konsumenten**. Was als Unit gilt, bestimmt ausschließlich die Nutzerperspektive:

- Eine einzelne Funktion mit klarer Public API (z. B. `os.walk`)
- Ein HTTP-Endpunkt inklusive Statuscodes, Headers und Body-Struktur
- Eine visuelle GUI-Komponente aus Sicht des Nutzers

Wer interne Implementierungsdetails testet, gießt Architekturentscheidungen in Beton. Das Resultat ist **Test-Depression**: Refactorings brechen Dutzende Tests, obwohl das beobachtbare Verhalten identisch bleibt. Dieses Phänomen vernichtet Team-Moral und Entwicklungsgeschwindigkeit gleichermaßen.

**Hyrum's Law als Leitprinzip:** Jedes sichtbare Verhalten wird über Zeit zum de-facto Interface. Tests müssen bewusst entscheiden, welche dieser Verträge aktiv geschützt werden — und welche Freiheit der Implementierung überlassen bleibt.

---

## 2. Kernprinzipien der Interface-zentrierten Teststrategie

| Prinzip | Beschreibung |
|---|---|
| **Öffentliche Verträge schützen** | Validiere, was der Konsument sieht: JSON-Strukturen, CLI-Outputs, HTTP-Antworten — nicht interne Hilfsfunktionen wie `calculate_tax()`. |
| **Strukturinsensitivität** | Ein Test darf nicht scheitern, weil Code verschoben oder eine private Funktion umbenannt wurde, solange das externe Verhalten stabil bleibt. |
| **ROI vor Coverage-Metrik** | Wir werden für Produkte bezahlt, die nicht brechen, nicht für das Schreiben von Tests. Eine hohe Coverage-Zahl ohne Aussagekraft ist eine Vanity Metric. |
| **Interface-Lebenszyklus** | Tests sterben mit ihrem Feature. Dead Tests für verwaiste interne Funktionen sind technische Schulden, die Ressourcen verbrennen und das Signal-Rausch-Verhältnis der Suite verschlechtern. |

---

## 3. Test Desiderata: Die Ökonomie der Testeigenschaften

Kein Test kann alle Ideale gleichzeitig erfüllen — das sind bewusste Trade-offs, keine Fehler. Ein erfahrener Engineer steuert diese Spannungsfelder aktiv.

Die drei Eigenschaften mit dem höchsten ROI für langfristige Wartbarkeit:

**Isolated** — Tests sind reihenfolgeunabhängig und deterministisch. Isolation ist die Voraussetzung für Parallelisierung und stabile CI-Pipelines.

**Behavioral** — Tests reagieren auf Verhaltensänderungen sofort, bleiben aber unempfindlich gegenüber internen Strukturänderungen. Das Verhalten ist das Vertragsobjekt, nicht der Code.

**Structure-insensitive** — Der stärkste Hebel gegen Test-Depression. Ein Test, der nach einem internen Refactoring manuell angepasst werden muss, ohne dass sich das Verhalten geändert hat, ist konzeptionell fehlerhaft.

> **Architektonisches Schlupfloch:** Durch *Composability* lassen sich Tests oft gleichzeitig schneller und aussagekräftiger machen — indem verschiedene Variabilitätsdimensionen separat getestet und kombiniert werden.

---

## 4. Anti-Patterns: Systematische Ursachen für Test-Depression

| Anti-Pattern | Symptom | Korrektur |
|---|---|---|
| **Mocking von Internals** | Tests brechen bei Umbenennung interner Funktionen; Mocks spiegeln die Produktionsrealität nicht wider. | Mocks ausschließlich für externe Infrastruktur (Third-Party-APIs, Hardware). Interne Logik real mitlaufen lassen. |
| **Assertion Overkill** | Brittle Tests scheitern wegen irrelevanter Felder (z. B. Timestamps, generierte IDs im JSON). | `dirty-equals` nutzen (`IsUUID`, `IsISOString`) oder gezielte Snapshot-Extraktion. |
| **Subtest-Missbrauch** | Monolithische Testfälle mit 200+ Zeilen mischen mehrere Logikpfade. | Logik in parametrisierte Tests oder Fixtures auslagern. |
| **Testen von volatilen Code** | Tests für Prototypen oder Code in aktiver Iteration bremsen Innovation und frustrieren das Team. | Volatilen Code explizit via Regex-Config von der Coverage ausnehmen. |

---

## 5. Snapshot Testing: Erwartungen automatisieren

Inline Snapshots (z. B. via `inline-snapshot`) minimieren den manuellen Wartungsaufwand drastisch: Erwartungswerte werden automatisch generiert und direkt in den Quellcode integriert — formatkonform mit dem Projekt-Linter (black, ruff).

**Best Practices:**

1. **Review-Disziplin ist nicht optional.** Snapshot-Updates niemals blind akzeptieren. Ein unbedachter Tastendruck zementiert einen Bug als neuen Standard.
2. **Dynamische Daten maskieren.** `dirty-equals` innerhalb von Snapshots für flüchtige Felder verwenden.
3. **Granularität wahren.** Kritische Teilbereiche großer Strukturen in separate Snapshots extrahieren (Zen of Python: *Readability counts*).
4. **Cross-Version-Stabilität.** Verschachtelte Snapshots für verschiedene Bibliotheksversionen (z. B. Pydantic v1 vs. v2) nutzen.

---

## 6. Testqualität messen: Mutation Testing schlägt Coverage

100 % Code-Coverage ist erreichbar, ohne eine einzige sinnvolle Assertion zu schreiben. Coverage misst Ausführung, nicht Verifikation — sie ist als alleinige Qualitätsmetrik wertlos.

**Mutation Testing** (z. B. mit `mutmut`) ist die Lösung: Der Quellcode wird systematisch manipuliert (`>` zu `>=`, `True` zu `False`), und geprüft, ob die Test-Suite den induzierten Fehler erkennt. Ein überlebender Mutant entlarvt tote Testabdeckung.

**Clean Coverage als Ziel:** Konzentration auf die funktionale Absicherung geschäftskritischer Pfade. Unkritischer Code (Debug-Logik, `__repr__`-Methoden) wird explizit via Konfiguration ignoriert. Nur so bleibt die Test-Suite ein scharfes Präzisionsinstrument.

---

## 7. Architektonische Leitplanken (Guardrails)

Testqualität ist kein Zufall — sie erfordert technische Strukturen, die schlechte Entscheidungen erschweren.

- **Architektur-Linting** via `import-linter`: Importverbote von Business-Logik oder DB-Modellen direkt in Test-Suiten erzwingen die Nutzung öffentlicher Interfaces.
- **Thinnest Testing Layer**: 90 % der Logik über schmale, interface-nahe Wrapper testen. Nur das Nötigste an langsame Systemtests delegieren.
- **Infrastruktur-Isolation**: Fragile manuelle Mocks durch `Testcontainers` (Datenbanken) oder `vcr.py` (Netzwerk-Interaktionen) ersetzen.
- **Type-Hinted Fixtures**: `pytest-fixture-classes` für typisierte, wartbare Testdaten-Setups verwenden.
- **SQL-Fingerprinting**: N+1-Query-Probleme durch Snapshotting von SQL-Fingerprints proaktiv identifizieren (z. B. `inline-snapshot-django`).

---

## Call to Action

```
Teste das WAS, nicht das WIE.
Automatisiere Erwartungen mit Inline Snapshots.
Miss Qualität mit Mutation Testing, nicht mit Coverage.
Nutze Container und VCR statt fiktiver Mocks.
Parallelisiere durch strikte Zustandsisolation.
Lass Tests mit ihren Features sterben.
```

---

## Querverweise

- `Testing Guidelines (AI Agent).md` — Operative Variante dieser Philosophie für AI-Coding-Agenten
- `Pre-Commit Guidelines.md` — Validierungs-Pipeline (ruff, mypy, pytest, mutmut)
- `Documentation Guidelines.md` — Docstrings als Vertragsdokumentation
- `../Spec Driven Development/` — Spec-Akzeptanzkriterien als Vertrag (entspricht dem „Was" hier)
- `../Developer Workflow.md` — Skill `/test` operationalisiert dieses Manifest
