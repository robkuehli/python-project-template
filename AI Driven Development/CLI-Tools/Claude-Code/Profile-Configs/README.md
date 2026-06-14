---
title: "Profile-Configs — Settings-Overlays pro Profil"
last_verified: 2026-05-21
status: current
tags:
  - claude-code
  - profiles
  - config
---

# Profile-Configs

Eine Settings-Datei pro Nicht-Default-Profil. Claude Code kennt keine nativen `[profiles.*]`-Blöcke — die Profil-Logik läuft über das **`--settings`-Flag**, das eine zusätzliche Settings-Datei mit höherer Präzedenz über die globale `~/.claude/settings.json` legt (Settings mergen über alle Quellen; bei Permissions gewinnt deny → ask → allow).

## Inhalt

| Datei | Profil | Aktivierung |
|---|---|---|
| *(globale `claude-config/settings.json`)* | **Balanced** — Standard-Arbeitstag | `cc` |
| [`settings-sota.json`](./settings-sota.json) | **SOTA** — Maximum Quality | `cc-sota` |
| [`settings-dsgvo.json`](./settings-dsgvo.json) | **DSGVO** — EU-Datenresidenz | `cc-dsgvo` |

Begründung der Modellwahl pro Profil: [[Claude Code — Profil-Spezifikationen]].

## Was ein Overlay setzt

Ein Overlay enthält nur, was vom Balanced-Default **abweicht**:

- `model` — Default-Modell (Alias `sonnet`/`opus`, vom Gateway via `ANTHROPIC_DEFAULT_*_MODEL` aufgelöst).
- `effortLevel` — Reasoning-Tiefe (`high` / `xhigh`).
- `env` — Alias→Modell-Mapping (in DSGVO auf EU-Bedrock-Aliase umgebogen).
- `permissions` — in DSGVO: WebFetch auf `ask`.

Das **Default-Modell** zieht über `model: inherit` die Subagents `reviewer`/`security-auditor` mit; `researcher` bleibt fix auf `haiku` (dessen Alias-Ziel das Overlay-`env` bestimmt — in DSGVO also EU-Haiku). Siehe [Agents/README](../Agents/README.md).

## Installations-Befehl

```bash
mkdir -p ~/.claude/profiles
cp ./settings-sota.json   ~/.claude/profiles/
cp ./settings-dsgvo.json  ~/.claude/profiles/
```

Aliase in `~/.zshrc` siehe [[Claude Code — Setup-Manual]] §5.

## Secrets bleiben außerhalb der committeten Dateien

`ANTHROPIC_AUTH_TOKEN` (LiteLLM-Key) steht **nie** in diesen Dateien. Der Balanced-/SOTA-Key kommt aus `~/.zshrc`; der EU-gebundene DSGVO-Key wird im `cc-dsgvo`-Alias inline gesetzt (`ANTHROPIC_AUTH_TOKEN="$LITELLM_EU_KEY"`).

## Anpassung an die echte Firmen-LiteLLM-Konfiguration

Die `env`-Blöcke enthalten **Platzhalter**:

- Aliase wie `claude-sonnet-4-6`, `bedrock-claude-sonnet-eu` müssen den Namen in der Firmen-LiteLLM-`model_list` entsprechen. Mit dem Maintainer abklären.
- `ANTHROPIC_BASE_URL` wird global (in `settings.json`/`~/.zshrc`) gesetzt; die Overlays erben es.

Solange nicht verifiziert: das DSGVO-Profil **nicht produktiv** verwenden ([[Claude Code — Open Issues & TODOs]] §C).

## Volle Isolation als Alternative

Für strikte Kundentrennung kann statt `--settings` ein eigenes `CLAUDE_CONFIG_DIR` pro Profil genutzt werden (eigener Settings-/Agents-/Hooks-/Credential-Satz). Schwerer zu warten, aber maximal getrennt — siehe [[Claude Code — Setup-Manual]] §5.
