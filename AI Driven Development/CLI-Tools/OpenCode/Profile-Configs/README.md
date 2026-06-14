---
title: "Profile-Configs — Eine opencode.json pro Profil"
last_verified: 2026-05-20
status: current
tags:
  - opencode
  - profiles
  - config
---

# Profile-Configs

Eine eigenständige `opencode.json` pro Profil. OpenCode kennt keine nativen `[profiles.<name>]`-Blöcke (wie Codex CLI) — die Profil-Logik läuft über `OPENCODE_CONFIG`-Env-Var, die auf die jeweilige Datei zeigt.

## Inhalt

| Datei | Profil | Aktivierung |
|---|---|---|
| [`opencode-balanced.json`](./opencode-balanced.json) | **Balanced** — Standard-Arbeitstag | `oc` (Default-Alias) |
| [`opencode-sota.json`](./opencode-sota.json) | **SOTA** — Maximum Quality | `oc-sota` |
| [`opencode-dsgvo.json`](./opencode-dsgvo.json) | **DSGVO** — EU-Datenresidenz | `oc-dsgvo` |
| [`opencode-ollama.json`](./opencode-ollama.json) | **Ollama** — Lokal + Cloud | `oc-ollama` |

Begründung der Modellwahl pro Profil und Sub-Agent: [[OpenCode — Profil-Spezifikationen]].

## Installations-Befehl

```bash
cp ./opencode-*.json ~/.config/opencode/configs/
```

Aliase in `~/.zshrc` siehe [[OpenCode — Setup-Manual]] §5.

## Warum jede Config den vollen Provider-Block enthält

OpenCode hat (Stand Mai 2026) **kein** `$extends`-Mechanismus. Die Provider-Definition wird daher in jeder Config dupliziert. Die Duplizierung kostet Wartung — bei Schema-Änderungen alle vier Files anpassen.

Sobald OpenCode ein offizielles Profile- oder Inheritance-Konzept liefert, sollten wir auf einen Build-Schritt (z.B. `jq`-Templates) oder native Mechanik umstellen.

## Anpassung an die echte Firmen-LiteLLM-Konfiguration

Die Provider-Blöcke enthalten **Platzhalter**:

- `baseURL: https://litellm.internal.example.com/v1` — durch echten Firmen-Endpoint ersetzen.
- Modell-IDs wie `bedrock-claude-opus-eu`, `azure-gpt-5-mini-eu` — müssen den Aliases im Firmen-LiteLLM entsprechen. Mit dem Maintainer abklären.

Solange nicht verifiziert: das DSGVO-Profil **nicht produktiv** verwenden.
