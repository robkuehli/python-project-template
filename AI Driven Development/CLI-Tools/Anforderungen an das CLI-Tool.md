---
Last Modified: 2026-05-20
---
## Kontext

Das CLI-Tool ist die primäre Schnittstelle für den AI-assistierten Entwicklungsworkflow. Es orchestriert Skills, Agents und Modelle. Stand Mai 2026 ist **OpenCode** das Werkzeug erster Wahl. Cloud-Modelle laufen über einen **firmenseitig betriebenen LiteLLM-Proxy**, lokale Modelle laufen direkt gegen einen lokalen Ollama-Daemon (inkl. Ollama Cloud via `:cloud`-Suffix über denselben Daemon).

---

## Kern-Anforderungen

### 1. Skill-Agent-Binding

Wenn ein Skill aufgerufen wird, soll der passende Agent aktiviert werden.

Beispiel: `/spec` → Architect-Agent, `/capture` → Scribe-Agent.

Das Binding soll deklarativ konfigurierbar sein, nicht im Prompt hart-kodiert.

**Aktueller Status (OpenCode):** **Nicht nativ unterstützt.** 
* Skills werden global geladen und sind für jeden Agent sichtbar (Issue #19344). 
+ Workaround: Skill-Body enthält explizite Spawn-Anweisung des passenden Subagents.

### 2. Per-Agent-Modell-Konfiguration

Jeder Agent soll ein eigenes Modell haben, unabhängig vom Default-Modell der Session.

- Architect: starkes Reasoning-Modell (z.B. Claude Opus 4.7)
- Coder: schnelles Coding-Modell (z.B. GPT-Codex / Claude Sonnet)
- Explorer: günstiges Read-only-Modell (z.B. Claude Haiku)
- Scribe: lokales Modell (Ollama)

**Aktueller Status (OpenCode):** **Nativ unterstützt** 
+ über `model:`-Feld im Agent-Frontmatter (Markdown-File mit YAML-Frontmatter unter `~/.config/opencode/agent/<name>.md` oder `.opencode/agent/<name>.md`).

### 3. Profile mit unterschiedlichen Modellen pro Agent

Dasselbe Setup soll in verschiedenen Tiers laufen:

- **Default / Balanced** (solide, kostenbewusst, Standard-Arbeitstag)
- **SOTA** (beste verfügbare Modelle für komplexe Tasks)
- **DSGVO konform** (Frontier-Modelle mit EU-Datenresidenz & EU-Inference)
- **EU-Souverän** (Modelle von europäischen Unternehmen mit Data Residency & Inference in der EU, z.B. Mistral über Le Plateforme, aktuell nicht verfügbar)
- **Ollama** (lokal & große Open-Weight-Modelle über Ollama Cloud)

Profil-Wechsel soll den Modell-Tier für alle Agents gleichzeitig ändern, ohne einzelne Agent-Configs anfassen zu müssen.

**Aktueller Status (OpenCode):** **Nicht nativ unterstützt.** 
+ Keine TOML-`[profiles.*]` wie z.B. in Codex CLI.
+ Workaround-Strategien:
	- **Strategie A:** Mehrere `opencode.json`-Files, ausgewählt per `OPENCODE_CONFIG=…`-Env-Variable. Profil-Wechsel = Env-Wechsel.
	- **Strategie B:** Ein `opencode.json` mit Agent-Definitionen pro Tier (z.B. `architect-sota`, `architect-local`) und Shell-Alias zur Auswahl. Schwerer zu warten, aber transparenter.
	- **Strategie C:** Logische Modell-Aliase in der LiteLLM-Config (`sota/architect`, `eu/architect`, …) und Default-Wechsel per Env. Bedingt durch fremdverwaltetes LiteLLM nur für Cloud-Modelle nutzbar.

Empfehlung: **Strategie A** als Default.

### 4. Multi-Model-Support

Gleichzeitige Unterstützung von:

- **Anthropic-Modellen** (Claude Haiku, Sonnet, Opus) — bevorzugt direkt oder via LiteLLM
- **OpenAI-Modellen** (GPT-4.x, GPT-5.x, Codex-Modelle) — via Azure AI Foundry / LiteLLM
- **Lokalen Modellen** via Ollama (`localhost:11434/v1`)
- **Ollama Cloud Modellen** via gleichem Daemon mit `:cloud`-Suffix

Der Wechsel zwischen Anbietern soll keine Code-Änderung erfordern — nur Konfiguration.

**Aktueller Status (OpenCode):** **Nativ unterstützt.** 
* Pro Agent `model: "<provider>/<modell>"`. 
* Provider werden in `opencode.json` registriert.

### 5. Read-only-Modus für bestimmte Agents

Explorer und Reviewer dürfen keine Dateien schreiben oder Commands ausführen. Tool-Permissions sollen pro Agent konfigurierbar sein.

**Aktueller Status (OpenCode):** **Unterstützt**. 
* Im Agent-Frontmatter via `tools:`-Feld (z.B. `tools: [Read, Grep, Glob]`). 
* Built-in Agent `plan` ist bereits standardmäßig Read-only (außer in `.opencode/plans/*.md`).

### 6. Skills als versionierbare Dateien

Skills leben als `SKILL.md`-Dateien im Repo und sind git-versioniert. Sowohl globale Skills (für alle Projekte) als auch projekt-spezifische Skills sind unterstützt. Cross-Tool-Format gemäß Anthropic Agent Skills Spec.

**Aktueller Status (OpenCode):** **Nativ unterstützt seit Q1 2026**. Discovery-Pfade in dieser Reihenfolge:

- `.opencode/skills/` (Projekt)
- `~/.config/opencode/skills/` (Global)
- `.claude/skills/`, `~/.claude/skills/` (Cross-Tool-Discovery, Claude-Code-kompatibel)
- `.agents/skills/`, `~/.agents/skills/` (Cross-Tool-Discovery, Codex-kompatibel)

Daraus folgt: Zentraler `Skills/`-Ordner (siehe `Skills/README.md`) kann via Symlink in alle drei Tools zugleich eingebunden werden.

---

## Nice-to-have

**Automatische Profil-Erkennung** — z.B. offline → automatisch Local-Profil aktivieren.

**Spend-Tracking pro Agent** — über LiteLLM-Spend-Reports (Firmen-Dashboard), falls verfügbar.

**Explizite Skill-Invocation** — Skills sollen sowohl durch direkte Erwähnung (`$spec`) als auch durch natürlichsprachliche Beschreibung getriggert werden können. **OpenCode:** beides funktioniert (Description-basiertes Matching + explizite Aufrufe via `/skill <name>` oder eigene Slash-Commands).

**Per-Agent-MCP** — bestimmte Agents bekommen Zugriff auf bestimmte MCP-Server (z.B. Architect mit Read-Only-DB-Zugriff, Coder ohne). **OpenCode:** unterstützt, MCP-Block pro Agent.

**Hooks** — Pre-/Post-Tool-Hooks für Audit, Logging, Format-on-Write. **OpenCode:** über Plugin-System.

---

## Nicht-Anforderungen

- Kein vollständig automatisierter Workflow ohne menschliche Entscheidungspunkte (außer im autonomen Modus, siehe `Autonomer Coding Agent/`)
- Keine feste Reihenfolge von Skills
- Kein separates Frontend oder GUI
- Keine eigene Modell-Hosting-Infrastruktur außer Ollama lokal

---
