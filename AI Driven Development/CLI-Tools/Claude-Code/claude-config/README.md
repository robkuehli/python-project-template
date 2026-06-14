---
title: "claude-config — Globale Claude-Code-Defaults"
last_verified: 2026-05-21
status: current
tags:
  - claude-code
  - config
---

# claude-config

Globale Defaults für meine Claude-Code-Installation. Diese Dateien gehören final nach `~/.claude/`, hier liegen sie versioniert als Source of Truth. Pendant zu [`OpenCode/Config-Files/`](../../OpenCode/Config-Files/README.md).

## Inhalt

| Datei | Ziel-Pfad | Zweck |
|---|---|---|
| [`settings.json`](./settings.json) | `~/.claude/settings.json` | Basis-Config (= Balanced): `model`, `effortLevel`, `env` (Provider), Permissions, Hooks, Plugins |
| [`CLAUDE.md`](./CLAUDE.md) | `~/.claude/CLAUDE.md` | Globale Anweisungen — wer ich bin, Kommunikation, Modes/Subagents, harte Regeln |
| [`LEARNINGS.md`](./LEARNINGS.md) | `~/.claude/LEARNINGS.md` | Self-Improvement-Loop: kanonische Lessons (via `@`-Import im Kontext) |
| [`LEARNINGS.inbox.md`](./LEARNINGS.inbox.md) | `~/.claude/LEARNINGS.inbox.md` | Staging-Puffer für automatische Vorschläge (NICHT im Kontext); Promote via `/capture review` |
| [`hooks/capture-learnings.sh`](./hooks/capture-learnings.sh) | `~/.claude/hooks/` | `SessionEnd`-Hook: extrahiert Learning-Vorschläge → Inbox |
| [`hooks/surface-inbox.sh`](./hooks/surface-inbox.sh) | `~/.claude/hooks/` | `SessionStart`-Hook: erinnert an offene Vorschläge |

## settings.json vs. CLAUDE.md — die zwei Schichten

Wie bei OpenCode (`opencode.json` vs. `AGENTS.md`) trennt Claude Code strukturelle Konfiguration von der Wissensbasis:

- **`settings.json`** — strukturell: Modell, Reasoning-Tiefe, Provider-`env`, Permissions (allow/ask/deny), Hooks, aktive Plugins.
- **`CLAUDE.md`** — Markdown-Fließtext, der bei jeder Session in den Kontext geladen wird. Verhaltenssteuerung, keine Doku. Lädt `LEARNINGS.md` per `@~/.claude/LEARNINGS.md` ein.

Lade-/Präzedenz-Reihenfolge der Settings (niedrig → hoch): User (`~/.claude/settings.json`) → Project (`.claude/settings.json`) → Project-local (`.claude/settings.local.json`) → `--settings`-Overlay → Managed (Enterprise). Memory-Hierarchie analog: `~/.claude/CLAUDE.md` → `./CLAUDE.md` → `./CLAUDE.local.md`.

## Self-Improvement Loop (halbautomatisch, Inbox-Pattern)

`CLAUDE.md` bleibt **strukturell stabil**. Neue Lessons gehen ausnahmslos in `LEARNINGS.md` als Append. So bleibt die Hauptstruktur lesbar, das **Instruction-Budget** (~200 Zeilen) unter Kontrolle, und Wissen wächst ohne Refactoring.

Zwei Stufen:

1. **Propose (automatisch):** `hooks/capture-learnings.sh` (`SessionEnd`) liest das Transkript, ruft ein günstiges Scribe-Modell und hängt Vorschläge als `[ ] proposed` an `LEARNINGS.inbox.md` (Staging, nicht im Kontext).
2. **Confirm (manuell):** `/capture review` promotet bestätigte Einträge nach `LEARNINGS.md`. Nur dieser Schritt schreibt in die Wahrheit → Schutz vor Müll.

Format pro Eintrag:

```markdown
<!-- YYYY-MM-DD | Projektname | Was schiefgelaufen ist -->
- Konkrete Regel, die das Problem in Zukunft verhindert
```

Einträge neueste zuerst. Hintergrund: [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]] §6.

## Hooks — Input-Mechanik

Claude-Code-Hooks erhalten ihre Daten als **JSON über stdin** (z.B. `.tool_input.file_path`, `.tool_input.command`, `.transcript_path`, `.cwd`, `.reason`). **Nicht** über Env-Variablen wie `$CLAUDE_TOOL_INPUT_FILE_PATH`. Die Skripte und die Inline-Hooks in `settings.json` parsen daher stdin via `jq`/`python3`. `$CLAUDE_PROJECT_DIR` steht als Pfad-Anker zur Verfügung. Details: [[Claude Code — Best Practices]] §3.

## Installations-Befehl

```bash
mkdir -p ~/.claude/hooks
cp ./settings.json        ~/.claude/settings.json
cp ./CLAUDE.md            ~/.claude/CLAUDE.md
cp ./LEARNINGS.md         ~/.claude/LEARNINGS.md
cp ./LEARNINGS.inbox.md   ~/.claude/LEARNINGS.inbox.md
cp ./hooks/*.sh           ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
```

Detaillierter Setup-Prozess: [[Claude Code — Setup-Manual]].
