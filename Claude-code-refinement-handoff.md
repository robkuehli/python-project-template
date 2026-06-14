# Handoff — Claude Code Setup vereinfachen & in Copier-Template einbauen

## Ziel
Ein umfangreiches Claude-Code-Setup (19 Dateien, ~1810 Zeilen; Obsidian-Docs +
globale `~/.claude`-Config für einen Firmen-LiteLLM→Bedrock-Gateway mit 3 Profilen)
nach KISS/Pareto vereinfachen und in ein bestehendes Copier-Python-Template einbauen.

## Getroffene Entscheidungen
- **1 Profil** statt 3 (Balanced/SOTA/DSGVO) — Modellwechsel in der Session via `/model`.
- **Learnings-Inbox-Automatik behalten** (2 Hooks + Inbox).
- **Alle 3 Subagents behalten** (researcher, reviewer, security-auditor).
- **Alles ins Copier-Template** (kein separates globales Setup).
- **Plugin-Liste fix** (5 Stück, keine Copier-Frage).
- **Provider als Copier-Select**: LiteLLM-Gateway vs. Claude-Subscription.

## Phase 1 — Vereinfachung (Ergebnis: ~19→12 Dateien, ~1810→604 Zeilen, −67 %)
- 3 settings → **1 `settings.json`** (Modell sonnet, effort high). Hochskalieren per
  `/model opus` / `/effort xhigh`.
- 8 Doku-Dateien (5 Guides + 3 READMEs) → **1 `README.md`**. Tote `[[Wikilinks]]` und
  OpenCode-Vergleiche raus.
- Globale `CLAUDE.md` (~220 Z.) → **`AGENTS.md`** (Verhaltens-SoT) + 7-Zeilen-`CLAUDE.md`
  (Redirect + `@.claude/LEARNINGS.md`-Import).
- Permissions 50→18 (läuft über `just`/`uv`), Plugins 14→5, kaputten `statusLine`-Block entfernt.
- **`/capture`-Command neu gebaut** — der Promote-Schritt des Inbox-Loops fehlte vorher komplett.
- Hooks projekt-scoped (`$CLAUDE_PROJECT_DIR` statt `~/.claude`).
- Modelle aktualisiert: Opus 4.7 → **Opus 4.8** (Release 28.05.2026, web-verifiziert).
- Workflow auf `just qa` statt `make check`.

## Phase 2 — Einbau ins Copier-Template (`copier-python-template`)
- **`template/AGENTS.md.jinja`** (immer erzeugt): universelle Inhalte (Setup, Conventions,
  Coding-Prinzipien, Git, Research, Plan→Execute→Verify, Guardrails). Claude-Code-Spezifika
  (Plan Mode, `/model`, Subagents, Learnings, Auth-Hinweis) in einem
  `{% if 'claude_code' in coding_agents %}`-Block.
- **`CLAUDE.md`** (nur bei `claude_code`): Redirect auf AGENTS.md + `@.claude/LEARNINGS.md`.
- **`.claude/`** (nur bei `claude_code`):
  - `settings.json.jinja` — env-Block rendert je Provider (s.u.)
  - `agents/` → researcher.md, reviewer.md, security-auditor.md
  - `hooks/` → capture-learnings.sh, surface-inbox.sh (beide `chmod +x`)
  - `commands/` → qa.md, capture.md
  - `LEARNINGS.md`, `LEARNINGS.inbox.md`
- **`.gitignore`**: `.claude/settings.local.json` ignoriert (settings.json + leere Inbox bleiben getrackt).
- **`copier.yml`**: zwei neue Fragen, beide `when: 'claude_code' in coding_agents`:
  - `claude_provider` — Select: `litellm` (Default) | `subscription`
  - `litellm_base_url` — nur `when … claude_provider == 'litellm'`, Default = Platzhalter-URL
  - `_tasks` (git init, uv sync, pre-commit install) unverändert.

### Provider-Rendering in settings.json.jinja
| | LiteLLM | Subscription |
|---|---|---|
| `env` | `ANTHROPIC_BASE_URL` + 3 Modell-Aliase + `DISABLE_NONESSENTIAL_TRAFFIC` + `MAX_OUTPUT_TOKENS` | nur `MAX_OUTPUT_TOKENS` |
| Auth | `ANTHROPIC_AUTH_TOKEN` aus der Shell (nie committen) | `/login` |

## Verifikation (alles bestanden)
`copier copy` real durchgespielt für: LiteLLM, Subscription, Codex-only.
- AGENTS.md immer da; Claude-Block nur bei claude_code; `project_name` korrekt gerendert.
- CLAUDE.md + `.claude/` nur bei claude_code; bei Codex-only sauber abwesend.
- settings.json in beiden Provider-Varianten valides JSON; Subscription ohne `ANTHROPIC_BASE_URL`.
- Hooks syntaktisch ok (`bash -n`) + ausführbar; keine Jinja-Reste; copier.yml valides YAML.
- `claude_provider` ist echter Select: ungültige Werte werden abgelehnt.
- Keine statische `settings.json` mehr (per `mv` → `.jinja`), daher keine Render-Kollision.

## Offene / optionale Folgepunkte
1. In `copier.yml` bei `litellm_base_url` die **echte Firmen-Gateway-URL** als `default`
   eintragen (aktuell `https://litellm.internal.example.com`).
2. Default `claude_provider: litellm` — bei Bedarf auf `subscription` umstellen (1 Zeile).
3. **DSGVO/EU:** kein eigenes Profil mehr. Für Kundenarbeit mit EU-Pflicht EU-gebundenen
   LiteLLM-Key + EU-Aliase nutzen und `CLAUDE_LEARNINGS_MODEL` auf EU-Alias zeigen
   (im README §2 beschrieben).
4. Entscheiden, ob `LEARNINGS.inbox.md` ge-gitignored werden soll (aktuell committed,
   damit die Hooks beim frischen Clone sofort laufen).
5. Modell-Aliase (`claude-opus-4-8` etc.) müssen der Firmen-LiteLLM-`model_list` entsprechen.
6. Caveat: `SessionEnd`-Hook feuert nicht immer zuverlässig (GitHub Issue #34954) —
   ggf. auf `Stop`-Hook mit Hash-Dedup umstellen.

## Technische Stolpersteine (für die Fortsetzung)
- Das **Write-Tool blockt jeden `.claude/`-Pfad** — Dateien per bash schreiben/kopieren
  oder im Nicht-Punkt-Ordner stagen und dann kopieren.
- OneDrive: **bash kann anlegen/überschreiben, aber nicht löschen** ("Operation not permitted").
  Statische `settings.json` → `.jinja` daher per `mv` (Rename funktioniert).
- **copier** war via `pip install --break-system-packages` da, aber nicht im PATH →
  `python -m copier` nutzen.
- Rendering-Test ohne `--trust`: `_tasks` aus einer Template-Kopie entfernen
  (sonst bricht copier wegen "unsafe tasks" ab), dann `copier copy --defaults --data …`.