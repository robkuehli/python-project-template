---
title: "Config-Files — Globale OpenCode-Defaults"
last_verified: 2026-05-20
status: current
tags:
  - opencode
  - config
---

# Config-Files

Globale Defaults für meine OpenCode-Installation. Diese Dateien gehören final nach `~/.config/opencode/`, hier liegen sie versioniert als Source of Truth.

## Inhalt

| Datei | Ziel-Pfad | Zweck |
|---|---|---|
| [`opencode.json`](./opencode.json) | `~/.config/opencode/opencode.json` | Basis-Config (entspricht Balanced); Provider-Block, Default-Modelle, Permissions, Hooks |
| [`AGENTS.md`](./AGENTS.md) | `~/.config/opencode/AGENTS.md` | Globale Anweisungen — wer ich bin, wie kommuniziert wird, harte Regeln |
| [`LEARNINGS.md`](./LEARNINGS.md) | `~/.config/opencode/LEARNINGS.md` | Self-Improvement-Loop: kanonische Lessons (via `instructions:` im Kontext) |
| [`LEARNINGS.inbox.md`](./LEARNINGS.inbox.md) | `~/.config/opencode/LEARNINGS.inbox.md` | Staging-Puffer für automatische Vorschläge (NICHT im Kontext); Promote via `/capture review` |
| [`plugin/learnings-and-guards.ts`](./plugin/learnings-and-guards.ts) | `~/.config/opencode/plugin/` | Plugin: Learning-Capture (`session.idle`) + ruff-format + PreBash-Guard |

## Warum kein `CLAUDE.md`?

OpenCode kennt das `CLAUDE.md`-Konzept nicht. Stattdessen wird über `instructions:` in `opencode.json` jeder Markdown-File geladen, der als globale Wissensbasis dienen soll. Das ergibt dieselbe Wirkung wie `CLAUDE.md`, nur dass der Lade-Pfad explizit konfigurierbar ist.

## Self-Improvement Loop (halbautomatisch, Inbox-Pattern)

`AGENTS.md` bleibt **strukturell stabil**. Neue Lessons gehen ausnahmslos in `LEARNINGS.md` als Append. So bleibt die Hauptstruktur lesbar, das Token-Budget unter Kontrolle, und Wissen wächst ohne Refactoring.

Zwei Stufen:

1. **Propose (automatisch):** `plugin/learnings-and-guards.ts` extrahiert beim `session.idle`-Event Vorschläge und hängt sie als `[ ] proposed` an `LEARNINGS.inbox.md` (Staging, nicht im Kontext).
2. **Confirm (manuell):** `/capture review` promotet bestätigte Einträge in `LEARNINGS.md`. Nur dieser Schritt schreibt in die Wahrheit → Schutz vor Müll.

Format pro Eintrag:

```markdown
<!-- YYYY-MM-DD | Projektname | Was schiefgelaufen ist -->
- Konkrete Regel, die das Problem in Zukunft verhindert
```

Einträge neueste zuerst. Hintergrund: [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]] §6.

## Installations-Befehl

```bash
cp ./opencode.json ~/.config/opencode/opencode.json
cp ./AGENTS.md     ~/.config/opencode/AGENTS.md
cp ./LEARNINGS.md  ~/.config/opencode/LEARNINGS.md
cp ./LEARNINGS.inbox.md ~/.config/opencode/LEARNINGS.inbox.md
mkdir -p ~/.config/opencode/plugin && cp ./plugin/learnings-and-guards.ts ~/.config/opencode/plugin/
```

Detaillierter Setup-Prozess: [[OpenCode — Setup-Manual]].
