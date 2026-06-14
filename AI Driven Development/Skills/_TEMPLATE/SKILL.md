---
name: _template
description: TEMPLATE — kopiere diesen Ordner, benenne ihn um, passe name + description an.
license: MIT
compatibility:
  - claude-code
  - opencode
  - codex
metadata:
  owner: robin
  status: draft        # draft → stable (mehrfach in echten Tasks bewährt) → deprecated
  primary_agent: build # Mode, der dieses Skill primär ausführt: plan (Architect) oder build (Coder)
  source:              # optional: Repo / Docs / URL der Inspiration
---

# Template Skill

> Kurzbeschreibung dieses Skills in einem Satz. Was er löst, wann er greift.

## Trigger

Wann lade ich diesen Skill? Konkrete Phrasen aufzählen:
- „Beispiel-Trigger 1"
- „Beispiel-Trigger 2"
- Plus expliziter Aufruf: `/<name>` oder `$<name>`

## Input

Was der Skill *braucht*, um zu funktionieren:
- Dateipfade, Spec-Referenzen, Kontextangaben

## Schritte

1. **Schritt 1** — was tun
2. **Schritt 2** — was tun
3. **Schritt 3** — was tun

Bei Lücken oder Ambiguität: **stoppen und nachfragen**, nicht improvisieren.

## Output

Genau definiertes Artefakt:
- Pfad / Format
- Pflicht-Sektionen
- Was im Output stehen MUSS, was DARF NICHT drinstehen

## Beispiel

```markdown
# Beispiel-Output …
```

## Verweise

- Was der Skill *nicht* macht (→ Verweis auf anderen Skill)
- Welche Datei/Konvention gilt zusätzlich
