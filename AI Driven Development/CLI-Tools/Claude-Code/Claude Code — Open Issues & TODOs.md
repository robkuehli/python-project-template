---
title: "Claude Code — Open Issues & TODOs (zentral)"
tags:
  - claude-code
  - tracking
Creation Date: 2026-05-21
Last Modified: 2026-05-21
status: current
---

# Claude Code — Open Issues & TODOs

Zentrale Sammelstelle für alle offenen Punkte rund um das Claude-Code-Setup. Pendant zu [[OpenCode — Open Issues & TODOs]] — **eine** Stelle statt verstreuter Notizen.

Status-Konvention: `[ ]` offen · `[x]` erledigt · 🔭 beobachten (extern, kein eigener Task) · ⛔ blockiert.

---

## A. Erledigt durch das Review/Refactoring (2026-05-21)

- [x] **Ordner-Struktur an OpenCode angeglichen** — MOC, Setup-Manual, Best Practices (aktualisiert), Profil-Spezifikationen, Täglicher Workflow, Open Issues, `Agents/`, `Profile-Configs/`, `claude-config/README`.
- [x] **Best-Practices-Doc auf Mai 2026 gehoben** — Frontmatter ergänzt, gegen offizielle Docs verifiziert, falsche Claims korrigiert (siehe §H).
- [x] **3-Achsen-Modell auf Claude Code gemappt** — Plan Mode = Architect, Default = Coder, 3 Subagents. Kein `Primary/`-Ordner (CC hat keine Custom-Primaries).
- [x] **Subagent-Roster verschlankt** auf `researcher`, `reviewer`, `security-auditor` (Modell-Tiers via `inherit`/`haiku`).
- [x] **Inline-Hook-Bug identifiziert** — `PostToolUse`/`PreToolUse` in `settings.json` nutzten `$CLAUDE_TOOL_INPUT_FILE_PATH` / `$CLAUDE_TOOL_INPUT` (Env), korrekt ist **stdin-JSON** (`.tool_input.file_path` / `.tool_input.command`). Auf stdin/jq umgestellt.
- [x] **CLAUDE.md** um Mode-/Subagent-Mapping ergänzt; `@~/.claude/LEARNINGS.md`-Import behalten.

---

## B. LiteLLM / Bedrock-Konfiguration (Firmen-abhängig)

- [ ] **Integrationsweg festlegen** — Weg A (LiteLLM als Anthropic-Gateway via `ANTHROPIC_BASE_URL`) **oder** Weg B (`CLAUDE_CODE_USE_BEDROCK=1` + `ANTHROPIC_BEDROCK_BASE_URL` auf LiteLLM). Mit LiteLLM-Maintainer klären, welchen Endpunkt der Proxy bereitstellt. *(Setup-Manual §2.)*
- [ ] **Modell-Aliase verifizieren** — `claude-opus-4-7` / `claude-sonnet-4-6` / `claude-haiku-4-5` müssen den Namen in der Firmen-LiteLLM-`model_list` entsprechen (sonst `ANTHROPIC_DEFAULT_*_MODEL` anpassen).
- [ ] **`ANTHROPIC_BASE_URL` ersetzen** — `https://litellm.internal.example.com` durch echten Firmen-Endpoint in `settings.json`/`~/.zshrc` + allen Profilen.
- [ ] **Beta-Header-Verträglichkeit testen** — falls 4xx von Bedrock via LiteLLM: `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` setzen.
- [ ] **MCP-Server pro Projekt ergänzen** (`.mcp.json`), sobald Use-Cases konkret sind (z.B. Read-only-Postgres für Recon). Optional per Subagent via `mcpServers`-Frontmatter scopen.

## C. DSGVO-Checkliste (pro Kundenprojekt prüfen)

- [ ] **EU-Routing am Gateway erzwingen** — DSGVO-Compliance liegt in Claude Code an der **Routing-Schicht**: ein EU-gebundener LiteLLM-Key (`LITELLM_EU_KEY`), dessen Aliase ausschließlich auf Bedrock `eu-central-1`/`eu-west-1` zeigen. Mit Maintainer verifizieren.
- [ ] **`eu.`-Inference-Profiles** statt `us.` — falls Weg B (direkt Bedrock): `ANTHROPIC_DEFAULT_*_MODEL` auf `eu.anthropic.*` + `AWS_REGION=eu-central-1`.
- [ ] **Cross-Region-Inference auf US** explizit deaktiviert (LiteLLM-/Bedrock-seitig).
- [ ] **Kunden-spezifische `./CLAUDE.md`** mit Datenschutz-Hinweisen im Projekt-Root.
- [x] **`permissions.webfetch`/WebFetch auf `ask`** im DSGVO-Profil — bereits konfiguriert.
- [ ] **Scribe-Modell EU-gebunden** — der `SessionEnd`-Learning-Hook gibt das Transkript an ein Modell; im DSGVO-Profil `CLAUDE_LEARNINGS_MODEL` auf einen EU-Alias zeigen (kein Transkript in US-Region).
- [ ] ⛔ **DSGVO-Profil nicht produktiv** verwenden, bis B+C verifiziert sind.
- [ ] 🔭 **Volle Profil-Isolation via `CLAUDE_CONFIG_DIR`** für strikte Kundentrennung evaluieren (eigener Credential-/Agents-/Hooks-Satz pro Kunde).

## D. Externe Claude-Code-Punkte (beobachten)

- [ ] 🔭 **`SessionEnd`-Zuverlässigkeit** — [Issue #34954](https://github.com/anthropics/claude-code/issues/34954): SessionEnd feuert nicht immer sauber. Fallback: `Stop`-Hook (pro Turn) mit Hash-Dedup. *(Best Practices §3, Review §10.)*
- [ ] 🔭 **`effortLevel`-Schema** — [Issue #52247](https://github.com/anthropics/claude-code/issues/52247): JSON-Schema listet `max` (noch) nicht im Enum, CLI akzeptiert es. Kosmetisch.
- [ ] 🔭 **Agent Teams / Fork-Mode** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `CLAUDE_CODE_FORK_SUBAGENT=1`) — experimentell. Bei Reife für parallele autonome Runs evaluieren; im Hybrid-Alltag noch nicht nötig.

## E. Setup / Skills

- [ ] **Symlink im echten Home einrichten** — `~/.claude/skills` → zentraler `Skills/`-Ordner.
- [ ] **Shell-Hooks ausführbar machen** beim Install: `chmod +x ~/.claude/hooks/*.sh`.
- [ ] **`statusline-command.sh`** bereitstellen oder den `statusLine`-Block aus `settings.json` entfernen (referenziert ein noch nicht vorhandenes Skript).
- [ ] **`enabledPlugins` verifizieren** — Marketplace-IDs (`@claude-plugins-official`) und Plugin-Namen gegen `claude plugin marketplace`/`/plugin` abgleichen; nur tatsächlich genutzte aktiv lassen (Token-Budget).
- [ ] **Helper-Skills evaluieren** aus `anthropics/skills` (`skill-creator` etc.) — projekt-lokal symlinken, nicht global.

## F. Learning-Hook produktiv härten

- [ ] **`SessionEnd`-Payload verifizieren** — `transcript_path`, `cwd`, `reason` + Transkript-Format gegen die [Hooks-Reference](https://code.claude.com/docs/en/hooks) testen, bevor produktiv (Fallback: `Stop`-Hook + Dedup).
- [ ] **Scribe-Extraktor-Prompt kalibrieren** — Bar empirisch so hoch, dass die Inbox nicht zumüllt.
- [ ] **`/capture review`-Promote-Logik** im `/capture`-Skill fertig (liest Inbox, du bestätigst, schreibt `LEARNINGS.md`, leert Inbox-Zeilen).

## G. Modellwahl / Kosten

- [ ] **Cost-Tracking** — LiteLLM-Telemetrie pro Profil über ~4 Wochen sammeln, dann Modellwahl evidenz-basiert re-evaluieren.
- [ ] **SOTA-Default überdenken** — aktuell main = Opus 4.7 (auch für Coding). Falls zu teuer: main = Sonnet, Opus nur in Plan Mode (`/model opus`) + für `reviewer`/`security-auditor` (via `inherit`).

## H. Korrigierte Claims aus dem alten Best-Practices-Doc (April 2026)

| Alte Behauptung | Befund (Mai 2026) | Korrektur |
|---|---|---|
| Hook-Input via `$CLAUDE_TOOL_INPUT_FILE_PATH` / `$CLAUDE_TOOL_INPUT` | Hooks erhalten **JSON über stdin** (`.tool_input.file_path`, `.tool_input.command`) | Inline-Hooks auf stdin/jq umgestellt |
| `/loop` als Built-in für autonome Runs | Kein dokumentierter Built-in-Command | Entfernt; autonome Parallelität → Agent Teams / Headless (`claude -p`) |
| `autoCompact: true` als settings.json-Key | Auto-Compaction ist default (~95 %), tunebar via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Auf env-Var/Default umformuliert |
| Hook-Typen `prompt` / `agent` | Bestätigt sind `command` und `http` (HTTP-Hooks via `allowedHttpHookUrls`) | Nur `command`/`http` belassen |
| `effortLevel` (inkl. `xhigh`) | **Gültig** (low/medium/high/xhigh/max; ab Sonnet 4.6 / Opus 4.6/4.7) | Beibehalten ✅ |
| Per-Agent-Modell wie OpenCode `agent.<name>.model` pro Profil | CC: Subagent-Modell steht im Frontmatter; Profil skaliert via `inherit` + `CLAUDE_CODE_SUBAGENT_MODEL` | Mechanik dokumentiert ([[Claude Code — Profil-Spezifikationen]]) |

---

## Quelldateien (überführt)

| Datei | Was hierher gehört |
|---|---|
| [`claude-config/settings.json`](claude-config/settings.json) | env-/Provider-Platzhalter, Plugin-Verifikation |
| [`Profile-Configs/`](Profile-Configs/) | EU-Alias-/Routing-Hinweise |
| [[Claude Code — Profil-Spezifikationen]] | „Offene Punkte" |
| [[Claude Code — Best Practices]] | korrigierte Claims (§H) |
