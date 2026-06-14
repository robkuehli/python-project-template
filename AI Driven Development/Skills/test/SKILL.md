---
name: test
description: "Leitet Tests direkt aus Spec, Plan oder Anforderung ab. Triggert für TDD-Workflows und vor jeder Delegation. Erzeugt Tests, die das WAS prüfen, nicht das WIE."
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

# Test — Tests aus Spec ableiten

Schreibt Testfälle, die die Akzeptanzkriterien einer Spec direkt prüfen. Interface-zentriert, nicht implementierungsnah.

## Trigger

- „Ich brauche Tests aus dieser Spec"
- Nach `/plan`, vor `/delegate` oder Implementation
- Expliziter Aufruf: `/test <spec-pfad>`

## Input

- Spec-Datei mit klaren Akzeptanzkriterien ODER
- Plan mit explizit testbaren Schritten

## Constraints

- **Tests prüfen das WAS, nicht das WIE.** Siehe `../../Guidelines/Testing Guidelines.md` und `../../Guidelines/Testing Guidelines (AI Agent).md`.
- **Tests sind initial rot.** Sie werden geschrieben, bevor die Implementation existiert.
- **Mocks nur an Systemgrenzen.** Externe HTTP-APIs, Datenbanken, Hardware. Niemals interne Module mocken.
- **Ein Verhalten pro Test.** Test-Name vervollständigt „It should …".
- **Parametrize statt Copy-Paste.** Input-Variation in Tabelle, nicht in fünf Test-Funktionen.

## Schritte

1. **Akzeptanzkriterien extrahieren** — aus der Spec, 1:1
2. **Pro Kriterium einen Test-Stub** — Name, geplante Assertion, Kommentar mit AC-Referenz
3. **Edge Cases mit Parametrize** — alle Edge Cases aus Spec werden zu Test-Cases
4. **Volatile Felder maskieren** — `dirty-equals` (`IsUUID`, `IsISOString`) statt fixer Werte
5. **Initial laufen lassen** — Tests müssen rot sein. Wenn grün: Test ist zu schwach.
6. **Test-Datei committen, status rot** — Implementierungs-Agent sieht „roter Test → grüner Test" als Ziel

## Output

Eine oder mehrere Test-Dateien unter `tests/unit/` oder `tests/integration/`. Format:

```python
"""
Tests für <Feature>.
Spec: specs/NNNN-<slug>.md
"""
import pytest
from dirty_equals import IsUUID, IsISOString
from src.<modul> import <funktion>


def test_<feature>_<verhalten>_<erwartung>():
    # AC #1 aus specs/NNNN-<slug>.md
    result = <funktion>(...)
    assert result == {...}


@pytest.mark.parametrize("input,expected", [...])
def test_<feature>_handles_<edge_case>(input, expected):
    # AC #2 aus specs/NNNN-<slug>.md
    ...
```

Plus kurze Test-Manifest-Notiz, was abgedeckt ist und was nicht (siehe `../../Guidelines/Testing Guidelines.md`).

## Anti-Patterns

- `assert result is not None` als einzige Aussage
- Mocks auf interne Funktionen, um Tests grün zu kriegen
- Implementierung schreiben, bevor Tests fertig sind
- Tests, die Snapshot-blindly committed wurden ohne Review
- Performance-Tests im selben Bucket wie Verhaltens-Tests

## Verweise

- Manifest: `../../Guidelines/Testing Guidelines.md`
- Operativ für Agent: `../../Guidelines/Testing Guidelines (AI Agent).md`
- Folgeskill: `/delegate` oder direkte Implementation
- Bei TDD: rote Tests bleiben rot, bis Implementation läuft
