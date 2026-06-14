---
title: "Review — Developer-Workflow & CLI-Tool-Configs (Refactoring-Basis)"
created: 2026-05-29
last_verified: 2026-06-02
status: draft
confidence: medium-high
scope: Review + Refactoring-Plan (keine Umsetzung in dieser Session)
sources_anchor: §13
changelog:
  - "2026-06-02 — §7 Lokale Modellauswahl auf Basis der Deep Research aktualisiert (siehe [[Lokale Modelle auf M4 Pro - 20260602]]). Wichtigste Korrektur: qwen3-coder-next läuft nicht auf 48 GB (52 GB Footprint), Default ist jetzt qwen3-coder:30b. Researcher verschlankt auf qwen2.5-coder:7b. gpt-oss-safeguard:20b als dedizierter security-Pin. small_model auf llama3.2:1b. §1 und §6 Tier-Tabellen nachgezogen."
tags:
  - review
  - workflow
  - refactoring
  - claude-code
  - codex-cli
  - opencode
  - litellm
  - subagent-driven-development
---

# Review — Developer-Workflow & CLI-Tool-Configs (Refactoring-Basis)

Diese Review nimmt deinen aktuellen Stand (Mai 2026) gegen die aktuellen Best Practices für Claude Code, Codex CLI und OpenCode auf, prüft Complexity-Routing-Optionen mit LiteLLM-Backend und identifiziert Synergien zwischen den drei Tools. Ziel: konkrete Grundlage für ein KISS-Refactoring deiner Docs, Configs und Manuals.

```table-of-contents
```

---

## 1. TL;DR — was bleibt, was fällt

**Der Workflow selbst (das Konzept) ist zeitgemäß.** Die acht Skills, die Plan→Execute→Verify-Schleife, das Architect/Coder/Explorer/Scribe-Rollenmodell, das LEARNINGS-Inbox-Pattern und der Anthropic-Skills-Spec-Cross-Tool-Ansatz entsprechen 1:1 dem, was 2026 als state-of-the-art gilt (Boris Cherny, Anthropic Eng, [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/subagent-driven-development), [OpenAI Codex Skills](https://developers.openai.com/codex/skills)). Hier muss inhaltlich nichts geändert werden.

**Wovon du dich verabschieden willst — und das ist richtig:**

- **Profil-Matrizen pro Tool** (Balanced/SOTA/DSGVO/Ollama) sind überengineert für ein Ein-Personen-Setup. Boris Cherny argumentiert konsistent für KISS-Config und stabile, schlanke CLAUDE.md mit In-Session-Switching ([Pragmatic Engineer, Mai 2026](https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny), [How Boris Uses Claude Code](https://howborisusesclaudecode.com/)) — dazu zählt explizit die Trennung von Modell-Default (settings) und ad-hoc-Modellwechsel (`/model`). KISS-Variante: **eine Default-Config pro Tool, `/model`-Switching in der Session.**
- **DSGVO als eigenes Profil** ist überflüssig wenn EU-Routing am LiteLLM-Key/Virtual-Key hängt — du wählst dann nicht mehr „dsgvo" als Profil, sondern setzt vor `cd ~/kunden/foo-bank` einfach `export LITELLM_API_KEY=$LITELLM_EU_KEY`. (Mehr in §7.)
- **SOTA als eigenes Profil** ist obsolet, sobald du `effortLevel`/`model_reasoning_effort` per Subagent pinnst und `/model opus` für einzelne Sessions nutzt.

**Was neu dazukommt:** ein dritter aktiver CLI (Codex CLI für GPT-5.X-Modelle inkl. mini/nano/codex), ein expliziter Subagent-Driven-Development-Pattern für automatisches Modell-Downgrading bei mechanischen Tasks (3-stufig: Opus/Sonnet/Haiku, GPT-5.5/mini/nano, gpt-oss:120b/qwen3-coder/llama3.2), zentrales `Globals/`-Verzeichnis im Workspace als Single Source für `AGENTS.md` + `CLAUDE.md` (gesynct via Symlink), und 1Password-CLI für Secret-Auflösung statt Plain-Text-`export`.

**Maturity-Schnellcheck:**
- ✅ Established: Plan→Execute→Verify, CLAUDE.md/AGENTS.md, SKILL.md-Standard, Subagents mit pinned cheap models
- 🧪 Emerging: Codex CLI Subagents (TOML, GA April 2026), Cross-Tool-SKILL.md-Discovery in OpenCode (Q1 2026)
- 💡 Experimental: LiteLLM Complexity Router, Claude Code Agent Teams, Fork Mode

---

## 2. Ist-Stand-Bewertung — was deine Docs sagen vs. was du brauchst

| Doku-Bereich | Ist-Stand (Mai 2026) | Bewertung | Aktion |
|---|---|---|---|
| `Developer Workflow.md` | 8 Skills, 4 Rollen, 3 Betriebsarten — tool-agnostisch | ✅ Bleibt | Nur Tooling-Anker um Codex-CLI ergänzen |
| `Anforderungen an das CLI-Tool.md` | Beschreibt 5 Profile als Hard Requirement | ⚠️ Überholt durch neue Zielsetzung | §3.3 (Profile) reduzieren auf „OpenCode: 2 Profile, andere Tools: keine" |
| `CLAUDE.md` (Workspace, projektweite Instr.) | Konzeptionell solide | ✅ Bleibt | Behavioral Rules unverändert |
| `Claude Code — Profil-Spezifikationen.md` | 3 Profile (Balanced/SOTA/DSGVO) | ❌ Streichen | Ersetzen durch „Claude Code — Modellwahl" (1 Default, In-Session-Switching) |
| `Claude-Code/Profile-Configs/` | 2 alternative settings*.json | ❌ Streichen | Nur globale `claude-config/settings.json` behalten |
| `OpenCode — Profil-Spezifikationen.md` | 4 Profile (Balanced/SOTA/DSGVO/Ollama) | ⚠️ Reduzieren auf 2 | „local-only" + „cloud+local" — siehe §7 |
| `OpenCode/Profile-Configs/` | 4 alternative json-Files | ⚠️ Reduzieren auf 2 | `opencode-local.json` + `opencode-cloud.json` |
| `Codex CLI` (im Workspace) | Existiert nur in Altreferenzen (LiteLLM Router) | 🆕 Anlegen | Neuer Ordner `CLI-Tools/Codex-CLI/` analog zu Claude-Code/OpenCode |
| `Skills/` (8 SKILL.md) | Cross-tool, ✅ Etabliert | ✅ Bleibt | Discovery-Pfade pro Tool dokumentieren (Codex ergänzen) |
| `Sub-Agents/` (zentral) + Agents/ (pro Tool) | Tool-spezifisch, dupliziert | ⚠️ Konsolidieren | Eine **konzeptionelle Rollendefinition** zentral, pro Tool nur die tool-spezifische Frontmatter-Realisierung |
| `LiteLLM/` (Complexity Router Referenz) | Als „zukünftige Überlegung" markiert | ✅ Bleibt | Status bestätigen — siehe §6 |
| `Autonomer Coding Agent/` | Eigenständiger Spezial-Workflow | ✅ Bleibt | Nicht Teil dieses Refactorings |

---

## 3. Tool-Stack — drei Rollen, drei CLIs

Die Aufteilung, die du anstrebst, ergibt im Mai 2026 **vendor-strategisch** Sinn — jedes Tool ist in seinem Lane das stärkste:

```
┌──────────────┬─────────────────────────┬──────────────────────────────┐
│ CLI          │ Modelle (via Backend)   │ Sweet Spot                   │
├──────────────┼─────────────────────────┼──────────────────────────────┤
│ Claude Code  │ Anthropic via LiteLLM   │ Architektur, Refactoring,    │
│              │ (Opus/Sonnet/Haiku)     │ DataEng/AI-Eng Reasoning,    │
│              │                         │ Hook-/Plugin-Reichtum        │
├──────────────┼─────────────────────────┼──────────────────────────────┤
│ Codex CLI    │ OpenAI via LiteLLM      │ TDD-Loops, schnelle Code-    │
│              │ (GPT-5.x, GPT-5-Codex)  │ Generation, Tool-Use-Tasks   │
├──────────────┼─────────────────────────┼──────────────────────────────┤
│ OpenCode     │ Ollama lokal + Cloud    │ Datensensitive Sessions,     │
│              │ (qwen3-coder, gpt-oss,  │ Offline, Experimente,        │
│              │  llama3.x)              │ Open-Weight-Vendor-Frei      │
└──────────────┴─────────────────────────┴──────────────────────────────┘
```

Diese Trennung ist sauber, **wenn** du die Tools nicht als „austauschbare Frontends fürs gleiche Modell" missverstehst — denn dann würdest du gegen die jeweilige Stärke arbeiten. Faustregel: das Modell wählt das Tool, nicht umgekehrt. Implikation:

- **Claude Code mit GPT-Modellen über LiteLLM zu betreiben ist nicht der Default-Pfad** — Claude Code erwartet die Anthropic-Tool-Use-API-Form ([Claude Code Docs](https://code.claude.com/docs/en/amazon-bedrock)). LiteLLM kann zwar GPT→Anthropic-Form übersetzen, aber Tool-Use-Roundtrips und Reasoning-Felder verhalten sich nicht 1:1 — pragmatisch heißt das: GPT-Modelle laufen in Codex CLI, nicht in Claude Code.
- **Codex CLI mit Claude über LiteLLM** ginge technisch ([LiteLLM Codex Tutorial](https://docs.litellm.ai/docs/tutorials/openai_codex)), aber du verschenkst die GPT-5-Codex-spezifischen Stärken.
- **OpenCode mit Cloud-Modellen** funktioniert nativ — willst du aber laut Setup-Ziel nicht (Cloud-Coverage haben Claude Code + Codex schon).

> ⚠️ **Edge Case:** Wenn du Ollama Cloud im Cloud+Local-Profil aktivierst, läuft das technisch über denselben Daemon mit `:cloud`-Suffix — keine Profil-Trennung nötig, du wählst das Modell pro Session per `/model`. Reines local-Profil nutzt nur Modelle ohne `:cloud`-Suffix.

---

## 4. Was du dir gleich sparen kannst — der KISS-Hebel

Der größte Komplexitätsanteil deines aktuellen Setups steckt nicht im Workflow-Konzept, sondern in **drei Mehrfachpflege-Schichten**:

1. **Profile pro Tool** (Balanced/SOTA/DSGVO/Ollama) — 7 alternative Config-Files (3 Claude + 4 OpenCode).
2. **Agent-Definitionen pro Tool** — `researcher`/`reviewer`/`security-auditor` in jedem Tool separat gepflegt, plus zentrale `Sub-Agents/`-Beschreibung.
3. **Profil-Spezifische Modellwahl-Tabellen** — pro Profil pro Agent eine Mappingsmatrix.

**Wenn alle drei Schichten wegfallen, schrumpft die Wartungsoberfläche um geschätzt ~60%, ohne dass du an Workflow-Mächtigkeit verlierst.** Die Mächtigkeit liegt in den Skills und dem Subagent-Pattern — nicht in den Profilen.

Die Vereinfachung pro Tool:

| Tool | Vorher | Nachher |
|---|---|---|
| Claude Code | 3 Profile, 3 settings.json, 3 Modellwahl-Tabellen | 1 settings.json, `/model opus\|sonnet\|haiku` in-session |
| Codex CLI | (noch nicht aktiv besetzt) | 1 config.toml, `--model`/Subagent-`model_reasoning_effort` |
| OpenCode | 4 Profile, 4 opencode.json | 2 opencode.json (local-only, cloud+local), `/model`-Switch innerhalb |

---

## 5. Subagent-Driven Development — der Routing-Motor

Das ist der Kern deiner Frage: **„Einfache Tasks sollten automatisch an günstigere Modelle gehen."** Stand Mai 2026 ist das **tool-seitig** der Standard, nicht via LiteLLM (mehr dazu in §6).

### Pattern (tool-agnostisch)

[obra/superpowers — subagent-driven-development](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md) hat das Pattern Stand März 2026 zur Referenz gemacht:

```
Plan (im Main-Thread, teures Reasoning-Modell)
   ↓
Dispatch: für jede atomare Task einen FRESH Subagent
   ↓
   ├─ Mechanische Implementierung → günstiges Modell (Haiku / GPT-5-mini / Qwen3-Coder 30B)
   ├─ Recon / Pattern-Erkennung   → günstiges Modell + read-only Tools
   ├─ Spec-Compliance-Review      → günstiges Modell, gegen Spec
   └─ Code-Quality-Review         → mittleres Modell, gegen Conventions
   ↓
Synthesize im Main-Thread → Commit / nächster Loop
```

Drei Eigenschaften machen das Pattern wirksam: (a) **Fresh Context** je Subagent — keine Verschmutzung des Plan-Kontexts; (b) **Modell-Downgrade** auf das günstige Tier für mechanische Arbeit; (c) **Two-Stage Review** (Spec → Quality) als Verifikationsschleife.

### Wie es jedes deiner Tools umsetzt

| Tool | Mechanik | Cheap-Tier-Default | Hard-Pin pro Subagent |
|---|---|---|---|
| **Claude Code** | Subagent-Frontmatter `model: haiku` oder `inherit` + `Explore`-Built-in auf Haiku | Haiku 4.5 | `~/.claude/agents/researcher.md` mit `model: haiku` ([Docs](https://code.claude.com/docs/en/sub-agents)) |
| **Codex CLI** | TOML-Custom-Agent + `model_reasoning_effort = "minimal"` | `gpt-5-mini` + `effort=minimal` | `~/.codex/agents/researcher.toml` ([OpenAI Subagents](https://developers.openai.com/codex/subagents)) |
| **OpenCode** | Agent-Frontmatter `model:` oder Inheritance vom Primary; `small_model` für Title-Gen etc. | `ollama/qwen2.5-coder:7b` (4.7 GB, ~85 t/s) | `~/.config/opencode/agent/researcher.md` mit `model:` ([Docs](https://opencode.ai/docs/agents/)) |

### Konkretes Beispiel: ein Read-Heavy-Recon-Task

Annahme: Plan-Mode hat festgelegt, dass vor der eigentlichen Implementierung alle Aufruferseiten von `load_dim_customer` gemapped werden müssen.

**Claude Code:**
```
> Use the researcher subagent to map all call sites of load_dim_customer
  before we touch it.
```
→ Claude delegiert an `researcher`, der auf Haiku läuft (~15× günstiger als Opus), liefert eine strukturierte Summary, der Plan-Mode-Thread bleibt unbelastet.

**Codex CLI:**
```
> Spawn researcher to map all call sites of load_dim_customer.
```
→ `~/.codex/agents/researcher.toml` mit `model = "gpt-5-mini"` und `model_reasoning_effort = "minimal"`. Subagent läuft isoliert, Parent-Kontext bleibt clean.

**OpenCode:**
```
> @researcher map all call sites of load_dim_customer
```
→ Agent-Frontmatter pinnt `model: ollama/qwen2.5-coder:7b` (4.7 GB, ~85 t/s — läuft in beiden Profilen lokal, isoliert vom Build-Agenten).

**Kostenersparnis:** [Augment Code Routing Guide](https://www.augmentcode.com/guides/ai-model-routing-guide) belegt 51% Kostenersparnis vs. uniformer Frontier-Nutzung bei dreistufiger Routing-Strategie. Dein Tier-Mapping:

| Tier | Claude (CC) | OpenAI (Codex) | Ollama (OC) |
|---|---|---|---|
| **Reasoning / Architekt** | Opus 4.7 | GPT-5.5 (full) + `model_reasoning_effort=high` | gpt-oss:120b-cloud (cloud+local) / gpt-oss:20b (local) |
| **Standard / Coder** | Sonnet 4.6 | GPT-5.5-codex | qwen3-coder-next:cloud (cloud+local) / **qwen3-coder:30b** (local) |
| **Mechanik / Recon** | Haiku 4.5 | GPT-5-mini oder GPT-5-nano + `model_reasoning_effort=minimal` | **qwen2.5-coder:7b** (lokal in beiden Profilen) |
| **Trivial (small_model)** | Haiku 4.5 | GPT-5-nano | **llama3.2:1b** (lokal) |

> 💡 GPT-5-nano ist Stand Mai 2026 das günstige OpenAI-Pendant zu Haiku — schneller und billiger als GPT-5-mini, aber begrenzte Reasoning-Tiefe. Faustregel: Recon/Klassifikation → nano; Test-Generierung/Refactoring eines Funktionsbodys → mini; Bug-Hunt mit unklarer Reproduktion → full.

---

## 6. Complexity Routing — LiteLLM vs. Tool-seitig

Du wolltest explizit wissen, wie das mit LiteLLM-Backend aussieht. Kurzfassung: **die Tool-seitige Variante schlägt die LiteLLM-Variante in deinem konkreten Setup.**

### Option A: LiteLLM Complexity Router

✅ Existiert, ist GA-fähig, [docs.litellm.ai/docs/proxy/auto_routing](https://docs.litellm.ai/docs/proxy/auto_routing) — Rule-Based-Scoring auf Prompt-Länge, Reasoning-Keywords, Kontexttiefe. 60–80% Kostenersparnis möglich, sub-Millisekunde Latenz.

**Aber für dich:**
- 🚫 LiteLLM ist bei dir **firmenseitig betrieben** — Routing-Strategie-Änderung = Team-Abstimmung
- 🚫 [Open Issues](https://github.com/BerriAI/litellm/issues/23247) Mai 2026: Complexity Router bricht bei Multi-Modal-Messages und `/v1/responses`-Endpoint — Codex CLI nutzt aber genau diese (`responses`-Format)
- 🚫 Routing-Entscheidung verlagert sich raus aus dem Tool — du verlierst die Möglichkeit, pro Task hard-zu-pinnen
- ⚠️ Selbst-hosten möglich (FOSS, MIT), aber löst sich gegen das vorhandene Firmen-LiteLLM auf — doppelte Infrastruktur

**Fazit:** Halt's als „zukünftige Überlegung" — die Referenz-Doku `litellm-complexity-router-referenz.md` kann bleiben, der Status bleibt nicht implementiert.

### Option B: Tool-seitiges Routing (Empfehlung)

✅ Jedes Tool kann es selbst, mit unterschiedlicher Mechanik:

**Claude Code — drei Hebel:**
1. **Subagent-Frontmatter** `model: haiku|sonnet|opus|inherit` — pinned pro Subagent
2. **`/model` in-Session** — manueller Switch des Main-Thread-Modells
3. **`effortLevel: low|medium|high|xhigh|max`** — Reasoning-Tiefe ohne Modellwechsel ([Docs](https://code.claude.com/docs/en/settings))

**Codex CLI — vier Hebel:**
1. **TOML-Custom-Agent** mit eigenem `model` + `model_reasoning_effort` ([Custom Agents](https://codex.danielvaughan.com/2026/04/27/codex-cli-custom-agent-definitions-toml-specialised-subagents/))
2. **`model_reasoning_effort = "minimal|low|medium|high|xhigh"`** — Anlog zu Claudes `effortLevel`
3. **`--model` CLI-Flag** — pro Session
4. **Inheritance** — Subagents erben ohne `model`-Feld vom Parent

**OpenCode — drei Hebel:**
1. **Agent-Frontmatter `model:`** — pinned pro Agent
2. **Default `model` + `small_model`** in `opencode.json` — eingebaute Mini-Complexity-Heuristik (Title-Gen etc. → `small_model`)
3. **`/model` in-TUI** — manueller Switch

**Trade-off:** Keine *automatische* Klassifikation pro Prompt — das macht nur LiteLLM. **Aber:** Du hast bereits die *strukturelle* Klassifikation über Skills/Agents (`/explore` → Recon-Agent auf Haiku; `/spec` → Plan-Mode auf Opus). Das ist die deklarative Variante derselben Idee — und sie ist explizit, debuggbar und ohne Kosten-Drift.

> 💡 **Synergie-Idee:** Statt LiteLLM-Routing erweitere deine Skill-Definitionen um `metadata.model_tier: minimal|standard|reasoning`. Jeder Skill weiß, welches Tier er braucht — das Tool mappt das Tier auf sein konkretes Modell. So ist die Routing-Logik im versionierten SKILL.md statt im Proxy-Config.

---

## 7. OpenCode-Profile + Ollama-Modellauswahl

Du willst nur OpenCode mit zwei Profilen. **`local` heißt wirklich lokal** (nur Modelle auf deinem M4 Pro 48 GB, keine API-Calls — nicht mal an LiteLLM für Recherche). `cloud+local` ergänzt das um Ollama-Cloud-Modelle über denselben Daemon.

### 7.1 Wieso nicht MiniMax / GLM / Kimi / Qwen3-Coder-Next lokal?

Berechtigte Frage — Stand Juni 2026 sind das die SWE-Bench-stärksten Open-Weight-Modelle. Aber **keines läuft auf deinem M4 Pro 48 GB** (Quantization-Footprints, verifiziert in [[Lokale Ollama Modelle auf M4 Pro - 20260602]]):

| Modell                                | SWE-Bench Verified            | Lokales Minimum (Q4_K_M)       | Auf 48 GB lauffähig?                                                                                       |
| ------------------------------------- | ----------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| MiniMax M2.5 / M2.7                   | 80.2% / 56.22% (Pro)          | 108 GB (Q4 UD-IQ4_XS)          | ❌ Nein ([Novita VRAM Guide](https://blogs.novita.ai/can-you-run-minimax-m2-5-locally-vram-reality-check/)) |
| GLM-5.1                               | 77.8%                         | 281 GB (Q2) / 805 GB (Q8)      | ❌ Nein ([Unsloth GLM-5](https://unsloth.ai/docs/models/glm-5))                                             |
| GLM-4.6                               | ~75%                          | 135 GB (Unsloth UD-Q2)         | ❌ Nein ([Unsloth GLM-4.6](https://unsloth.ai/docs/models/tutorials/glm-4.6-how-to-run-locally))            |
| Kimi K2.6                             | 76.8% (K2.5)                  | ~250 GB+ (1T MoE, 32B active)  | ❌ Nein                                                                                                     |
| DeepSeek V4                           | 73% (V3.2)                    | 200 GB+ (685B MoE, 37B active) | ❌ Nein                                                                                                     |
| **Qwen3-Coder-Next**                  | 70.6% (80B MoE / 3B active)   | **52 GB (Q4_K_M)**             | ❌ **Nein — Korrektur: Footprint übersteigt 48 GB; massives SSD-Swapping, t/s bricht ein**                  |
| Llama 3.3 70B                         | ~58%                          | ~42 GB                         | ❌ Nein — blockiert OS-Headroom                                                                             |
| Llama 4 Scout (109B MoE / 17B active) | k.A.                          | 65 GB                          | ❌ Nein                                                                                                     |
| Codestral 22B                         | ~52%                          | ~13 GB                         | ❌ Nein — restriktive Mistral-Research-Lizenz (keine kommerzielle Nutzung)                                  |
| gpt-oss:120b                          | ~74%                          | 80 GB+ (Q4)                    | ❌ Nein — nur via Cloud                                                                                     |
| **qwen3-coder:30b**                   | ~70% (via SWE-Agent Scaffold) | **18 GB (Q4_K_M)**             | ✅ **Ja — 30.5B MoE / 3.3B active, der eigentliche Frontier-Lokal-Coder**                                   |
| **gpt-oss:20b**                       | ~62% (o4-mini-äquivalent)     | **14 GB (MXFP4)**              | ✅ Ja                                                                                                       |
| qwen2.5-coder:7b                      | ~39%                          | ~4.7 GB                        | ✅ Ja — für researcher                                                                                      |
| llama3.2:1b                           | n/a                           | ~1.3 GB                        | ✅ Ja — für small_model                                                                                     |

Wegen MoE-Architektur muss bei MiniMax M2.7 zwar nur 46 B active sein, **aber der gesamte Expert-Pool liegt im Memory** — daher das 108-GB-Minimum. Bei `qwen3-coder-next` ist es das Active-Set + Routing-Header, das den 52-GB-Footprint erzwingt. Genau diese Falle macht „kleine active params" als einziges Hardware-Kriterium irreführend.

**Konsequenz:** Für `local` ist **qwen3-coder:30b** (30.5B MoE, 3.3B active, 18 GB Q4_K_M, Februar 2026 release) der Default — nicht qwen3-coder-next. MiniMax, GLM, Kimi und qwen3-coder-next nutzen wir nur via `cloud+local` (Ollama Cloud).

### 7.2 Modellauswahl pro Agent-Rolle

Die ausführliche Evaluation pro Rolle mit Top-1/Top-2/Watch-list, Footprint-Tabellen und Quellen liegt im Research-Doc [[Lokale Ollama Modelle auf M4 Pro - 20260602]]. Hier nur die Top-1-Pins für die schnelle Übernahme in die Configs (Stand 2026-06-02, Deep Research bestätigt):

| Rolle | Top 1 (`local`) | Top 1 (`cloud+local`) | Diversity-Argument |
|---|---|---|---|
| `build` | `ollama/qwen3-coder:30b` (18 GB, 256K ctx) | `ollama/qwen3-coder-next:cloud` (80B MoE) | Qwen-Familie für Code-Generation |
| `plan` | `ollama/gpt-oss:20b` (14 GB, Reasoning-Modus) | `ollama/gpt-oss:120b-cloud` | **andere Familie als build** (OpenAI-trained) |
| `researcher` | `ollama/qwen2.5-coder:7b` (4.7 GB, ~85 t/s) | dito **lokal** | klein genug für parallelen Betrieb zu build |
| `reviewer` | `ollama/gpt-oss:20b` (geteilt mit plan) | `ollama/gpt-oss:120b-cloud` | **Cross-Family-Review**: build=Qwen, reviewer=OpenAI |
| `security-auditor` | `ollama/gpt-oss-safeguard:20b` (14 GB, Policy-trained) | `ollama/gpt-oss:120b-cloud` | dedizierte Sicherheits-Inferenz, Apache-2.0 |
| `small_model` | `ollama/llama3.2:1b` (1.3 GB, ~200 t/s) | dito **lokal** | Sub-Sekunde Latenz, Hintergrund-tauglich |

**Kernerkenntnisse aus der Research, die das KISS-Setup tragen:**

- **Memory-Budget:** Build (qwen3-coder:30b, 18 GB) + Reviewer/Plan/Security (gpt-oss-Variante, 14 GB) + Researcher (qwen2.5-coder:7b, 4.7 GB) + small_model (llama3.2:1b, 1.3 GB) = ~38 GB. Mit 16 GB OS/Tool-Headroom passt das aufs 48-GB-Budget mit ~6 GB Reserve.
- **Diversity ist messbar wirksam:** Build auf Qwen-Lineage, Plan/Review/Security auf OpenAI-gpt-oss-Lineage — der Review-Agent erkennt systematische Fehlerklassen des Coders, die ein gleichfamiliäres Modell teilt.
- **Researcher bleibt in beiden Profilen lokal** (auch `cloud+local`) — Recon ist read-heavy, ohne Reasoning-Bedarf; jeder Cloud-Roundtrip frisst den Speed-Vorteil des günstigen Modells.
- **Security-Auditor: gpt-oss-safeguard:20b** ist eine policy-tuned Variante von gpt-oss:20b mit dediziertem Sicherheits-Training — sie liefert nicht nur „found vulnerability X", sondern auch die Richtlinien-Begründung. Praxistauglicher als allgemeines Reasoning für SQL-Injection-/AuthZ-Misconfig-Pässe.

> ⚠️ **MLX vs. GGUF (relevant für deine Apple-Silicon-Hardware):** MLX-Builds sind auf M4 Pro 30–50% schneller (qwen3-coder:30b: ~80 t/s MLX vs. ~50 t/s GGUF), aber Ollamas Tool-Call-Integration für GGUF ist robuster und folgt dem OpenAI-Function-Calling-Standard 1:1. MLX-Workflows brauchen `mlx-lm` o.ä. als Tool-Parser-Middleware, die in agentic Loops zusätzliche Fehleroberfläche schafft. **Empfehlung: GGUF via Ollama als Default**, MLX nur für reine Generation-Tasks (z.B. Doku-Generierung) erwägen.

> ⚙️ **Memory-Hygiene:** Ollama hält ungenutzte Modelle 5 Min im VRAM. Bei parallelen Subagent-Dispatches kann das den Hauptthread strangulieren. `OLLAMA_NUM_PARALLEL=1` in `~/.zshrc` setzen oder per Hook nach Subagent-Stop explizit `ollama stop <name>` aufrufen.

### 7.3 Resultierende Config-Files

#### Profil 1: `local` (M4 Pro 48 GB, kein Cloud-Hop irgendeiner Art)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "_comment": "Profil 'local': NUR Modelle auf diesem Rechner. Kein Cloud-Suffix, kein LiteLLM. Modellauswahl verifiziert in 'Lokale Modelle auf M4 Pro - 20260602'.",
  "provider": {
    "ollama": {
      "name": "Ollama (lokal, M4 Pro 48 GB)",
      "baseURL": "http://localhost:11434/v1",
      "models": {
        "qwen3-coder:30b":       { "name": "Qwen3 Coder 30B MoE/3.3B active (18 GB Q4_K_M, 256K ctx)" },
        "gpt-oss:20b":           { "name": "gpt-oss 20B MoE/3.6B active (14 GB MXFP4, Reasoning-Modus)" },
        "gpt-oss-safeguard:20b": { "name": "gpt-oss-safeguard 20B (14 GB, policy-tuned für Security)" },
        "qwen2.5-coder:7b":      { "name": "Qwen2.5 Coder 7B (4.7 GB, ~85 t/s — Researcher)" },
        "llama3.2:1b":           { "name": "Llama 3.2 1B (1.3 GB, ~200 t/s — small_model)" }
      }
    }
  },
  "model":       "ollama/qwen3-coder:30b",
  "small_model": "ollama/llama3.2:1b",
  "agent": {
    "build":            { "model": "ollama/qwen3-coder:30b" },
    "plan":             { "model": "ollama/gpt-oss:20b" },
    "researcher":       { "model": "ollama/qwen2.5-coder:7b" },
    "reviewer":         { "model": "ollama/gpt-oss:20b" },
    "security-auditor": { "model": "ollama/gpt-oss-safeguard:20b" }
  }
}
```

#### Profil 2: `cloud+local` (Ollama Cloud + lokaler Daemon)

> ℹ️ **Pre-Research-Stand.** Die Cloud-Modellauswahl wartet noch auf den Cloud-Brief aus [[Research Briefs - Ollama-Modelle für OpenCode Agents (2026-05-29)]]. Die unten stehende Config ist die Best-Guess-Variante vom 2026-05-29 mit den lokal-Pins, die nach der Deep Research vom 2026-06-02 nachgezogen wurden. Researcher und small_model bleiben bewusst **lokal**, auch in diesem Profil.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "_comment": "Profil 'cloud+local': Ollama Cloud für Frontier-Open-Weight + lokale Modelle für Recon/small. KEINE LiteLLM-Anbindung. Cloud-Pins werden nach Cloud-Brief-Research final fixiert.",
  "provider": {
    "ollama": {
      "name": "Ollama (lokal + Cloud)",
      "baseURL": "http://localhost:11434/v1",
      "apiKey": "{env:OLLAMA_API_KEY}",
      "models": {
        "qwen2.5-coder:7b":          { "name": "Qwen2.5 Coder 7B (lokal, Researcher)" },
        "llama3.2:1b":               { "name": "Llama 3.2 1B (lokal, small_model)" },
        "qwen3-coder-next:cloud":    { "name": "Qwen3 Coder Next 80B (Cloud, Build-Default)" },
        "gpt-oss:120b-cloud":        { "name": "gpt-oss 120B (Cloud, Reasoning)" },
        "minimax-m2.5:cloud":        { "name": "MiniMax M2.5 (Cloud, Watch-list, pending Cloud-Brief)" },
        "glm-5.1:cloud":             { "name": "GLM-5.1 (Cloud, Watch-list, pending Cloud-Brief)" },
        "kimi-k2.6:cloud":           { "name": "Kimi K2.6 (Cloud, Watch-list, pending Cloud-Brief)" }
      }
    }
  },
  "model":       "ollama/qwen3-coder-next:cloud",
  "small_model": "ollama/llama3.2:1b",
  "agent": {
    "build":            { "model": "ollama/qwen3-coder-next:cloud" },
    "plan":             { "model": "ollama/gpt-oss:120b-cloud" },
    "researcher":       { "model": "ollama/qwen2.5-coder:7b" },
    "reviewer":         { "model": "ollama/gpt-oss:120b-cloud" },
    "security-auditor": { "model": "ollama/gpt-oss:120b-cloud" }
  }
}
```

### 7.4 Profile-Switching

```bash
# In ~/.zshrc
alias oc-local='OPENCODE_CONFIG=~/.config/opencode/opencode-local.json OLLAMA_NUM_PARALLEL=1 opencode'
alias oc='OPENCODE_CONFIG=~/.config/opencode/opencode-cloud.json OLLAMA_NUM_PARALLEL=1 opencode'  # Default
```

> 💡 **Beobachtung:** Im `cloud+local`-Profil läuft `researcher` weiter lokal (qwen2.5-coder:7b), weil Recon kein Frontier-Reasoning braucht — die Cloud-Modelle bleiben Plan/Build/Reviewer vorbehalten. Das ist Subagent-Driven Development in seiner offensichtlichsten Form. Cloud-Brief soll prüfen, ob ein Sonnet-Level-8B-Modell als Cloud-Researcher-Alternative auftaucht; bis dahin lokal.

> 🧪 **Watch-list MiniMax/GLM/Kimi:** Im Config-File registriert, aber per Default nicht zugewiesen — wartet auf den Cloud-Brief. Wechseln per `/model` in der Session oder Agent-Block lokal anpassen.

---

## 8. Skills & Agents — Synergien und Duplikate

### 8.1 Skills — **echter** Cross-Tool-Pool

Skills folgen der [Anthropic Agent Skills Spec](https://www.agensi.io/learn/agent-skills-open-standard) und sind als **einziger Artefakt-Typ in deinem Setup wirklich tool-agnostisch**. Stand Mai 2026 lesen alle drei deiner Tools dasselbe Format:

| Tool | Discovery-Pfade (Priorität hoch→niedrig) |
|---|---|
| **Claude Code** | `.claude/skills/`, `~/.claude/skills/` |
| **Codex CLI** | `.codex/skills/`, `~/.codex/skills/`, `.agents/skills/` ([Codex Skills Guide](https://www.agensi.io/learn/codex-cli-skills-install-skill-md)) |
| **OpenCode** | `.opencode/skills/`, `~/.config/opencode/skills/`, **Fallback:** `.claude/skills`, `.agents/skills` ([Issue #19344-Kontext](https://github.com/anomalyco/opencode/issues/19344)) |

**Konsequenz für dein Setup:** Ein zentraler `Skills/`-Ordner, drei Symlinks. **Keine Duplikate.** Du hast das bereits richtig angelegt — ändere nur den Codex-Pfad (`~/.codex/skills/`-Symlink ergänzen).

⚠️ **Caveat OpenCode (Issue #19344):** OpenCode lädt Skills *global* in den Kontext jedes Agents (keine per-Agent-Filterung). Bei vielen Skills steigen Token-Kosten linear. Bis Fix: nur die 8 Workflow-Skills global halten, helper-Skills projekt-lokal scopen.

### 8.2 Agents — **tool-spezifisch**, das bleibt so

Anders als Skills sind Agents tool-spezifisch — Format, Frontmatter-Felder und Discovery-Pfade unterscheiden sich grundlegend:

| Aspekt | Claude Code | Codex CLI | OpenCode |
|---|---|---|---|
| Format | `~/.claude/agents/<name>.md` (YAML+Body) | `~/.codex/agents/<name>.toml` (TOML) | `~/.config/opencode/agent/<name>.md` (YAML+Body) |
| Primary-Konzept | ❌ kein Custom-Primary (Plan Mode + Default) | ❌ kein Custom-Primary (planning_mode) | ✅ Custom-Primaries (`plan`/`build`) |
| Modell-Feld | `model: haiku\|sonnet\|opus\|inherit` | `model = "gpt-5"` + `model_reasoning_effort` | `model: "<provider>/<modell>"` |
| Tool-Restriction | `tools:` Allowlist | `sandbox_mode` | `tools: { read: true, write: false, ... }` |
| Read-Only Built-in | `Explore` (Haiku) | `explore` | `general`, `explore` |

**Empfehlung:** Trenne **konzeptionelle Rolle** von **tool-spezifischer Implementierung**.

- **Zentral** (z.B. `Sub-Agents/researcher.md`): Beschreibt die *Rolle* — was ist der Auftrag, welche Tools darf er, welches Modell-Tier (z.B. `minimal`), welcher Output.
- **Pro Tool** (`Claude-Code/Agents/researcher.md`, `Codex-CLI/agents/researcher.toml`, `OpenCode/Agents/Subagents/researcher.md`): Nur die tool-spezifische Frontmatter, Verweis auf die zentrale Rollendefinition für den Body.

Konkretes Beispiel `researcher` (skizziert):

```yaml
# ~/.claude/agents/researcher.md (Claude Code-Realisierung)
---
name: researcher
description: "Read-only code recon. Use proactively when broad codebase mapping is needed."
model: haiku
tools: [Read, Grep, Glob]
---
{{> ../../Sub-Agents/researcher.body.md }}
```

```toml
# ~/.codex/agents/researcher.toml (Codex-Realisierung)
name = "researcher"
description = "Read-only code recon. Use proactively when broad codebase mapping is needed."
model = "gpt-5-mini"
model_reasoning_effort = "minimal"
sandbox_mode = "read-only"
developer_instructions_file = "../../Sub-Agents/researcher.body.md"
```

```yaml
# ~/.config/opencode/agent/researcher.md (OpenCode-Realisierung)
---
name: researcher
description: "Read-only code recon. Use proactively when broad codebase mapping is needed."
mode: subagent
model: litellm/claude-haiku-4-5
tools: { read: true, grep: true, glob: true, write: false, edit: false, bash: false }
---
{{> ../../../Sub-Agents/researcher.body.md }}
```

**Wartungseffekt:** Body einmal pflegen. Modell-/Tool-Frontmatter pro Tool aktuell halten. Das ist deutlich weniger Duplikation als die heutigen vollständig separaten Files.

> ⚠️ **Realitätscheck:** Keines der Tools unterstützt nativ `{{> include}}` im Frontmatter-Body. Konkrete Realisierung: entweder Symlink des Body-Files, oder ein kleines Generierungsskript im Install (`opencode-config/install.sh`), das beim Rollout den Body inline ersetzt. KISS-Variante: Symlink, eine Quelle, kein Tooling.

### 8.3 AGENTS.md / CLAUDE.md — überlappend, aber tool-bedingt

[AGENTS.md ist 2026 Open Standard](https://developers.openai.com/codex/guides/agents-md) — von Cursor, Aider, Codex, OpenCode gelesen. Claude Code nutzt nativ `CLAUDE.md`, kann aber `AGENTS.md` über `@import` einbinden.

**KISS-Strategie:**
- `AGENTS.md` (zentral, im Repo-Root oder `~/.config/`) = Single Source of Truth für Coding-Conventions, Git-Workflow, Validation Pipeline, harte Regeln. Wird gelesen von Codex CLI und OpenCode direkt.
- `~/.claude/CLAUDE.md` = enthält nur Claude-Code-spezifisches (Hooks, Plan-Mode-Hinweise, Slash-Commands) + `@~/path/to/AGENTS.md` als Import. Boris Cherny dokumentiert genau dieses Pattern ([How Boris Uses Claude Code](https://howborisusesclaudecode.com/)).
- `LEARNINGS.md` (separat, append-only) = via `@`-Import bzw. `instructions:` in beiden Tools eingebunden.

So pflegst du **eine** Conventions-Quelle. Tool-spezifische Settings (Hook-Pfade, Permission-Regeln) bleiben bei dem Tool, das sie nutzt.

---

## 9. Konkrete Refactoring-Roadmap

### Phase 1 — Profile abräumen (1 Stunde)

- [ ] `Claude-Code/Profile-Configs/` löschen (settings-sota.json, settings-dsgvo.json)
- [ ] `Claude-Code/Claude Code — Profil-Spezifikationen.md` → ersetzen durch `Claude Code — Modellwahl.md` (kurz: 1 Default-Modell, `/model`-Switching, `effortLevel`, Subagent-Pins)
- [ ] `OpenCode/Profile-Configs/` reduzieren auf `opencode-local.json` + `opencode-cloud.json` (siehe §7); alte 4 Files in `_archive/` verschieben
- [ ] `OpenCode — Profil-Spezifikationen.md` → ersetzen durch `OpenCode — Modellwahl.md` (2 Profile, `/model`-Switch, `small_model`-Heuristik)
- [ ] `Anforderungen an das CLI-Tool.md` §3 (Profile) auf die neue Realität ziehen — von „4 Profile Hard Requirement" auf „1–2 pro Tool, Rest in-session"

### Phase 2 — Codex CLI einführen (1–2 Stunden)

- [ ] Neuer Ordner `CLI-Tools/Codex-CLI/` analog zu `OpenCode/`:
  - `Codex-CLI — Setup-Manual.md` (Install via npm, LiteLLM-Proxy-Anbindung via `model_provider = "litellm"`, AGENTS.md-Symlink, Skills-Symlink)
  - `Codex-CLI — Best Practices.md` (AGENTS.md-Hierarchie, Custom Agents in TOML, `model_reasoning_effort`, Subagents)
  - `Codex-CLI — Täglicher Workflow.md` (Plan→Execute→Verify in Codex; Planning Mode, Subagent-Dispatch)
  - `codex-config/config.toml` (Default-Config: 1 Profile statt mehrere)
  - `agents/researcher.toml`, `agents/reviewer.toml`, `agents/security-auditor.toml`
- [ ] `Developer Workflow.md` §Tooling-Anker: Codex CLI als drittes Tool aufnehmen
- [ ] `Skills/MOC - Agentic-SWE - Skills.md` Cross-Tool-Tabelle um Codex-Discovery-Pfade verifizieren (war schon angelegt, prüfen)

### Phase 3 — Subagent-Driven Development als Pattern dokumentieren (2 Stunden)

- [ ] Neue Datei `Sub-Agents/Subagent-Driven Development.md` mit:
  - Pattern aus [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md)
  - Realisierung in jedem der drei Tools (siehe §5)
  - Two-Stage Review (Spec → Quality)
  - Wann *nicht* einsetzen (triviale Tasks <2h, einzelne Bugfixes)
- [ ] `Skills/_TEMPLATE/SKILL.md` erweitern um optionales `metadata.model_tier: minimal|standard|reasoning` (siehe §6 Synergie-Idee)
- [ ] In jedem `Skills/*/SKILL.md`: `metadata.model_tier` ergänzen, sodass Tools die strukturelle Klassifikation lesen können

### Phase 4 — Skills & Agents konsolidieren (2 Stunden)

- [ ] Zentrale Rollendefinitionen anlegen: `Sub-Agents/researcher.body.md`, `reviewer.body.md`, `security-auditor.body.md` — enthält den eigentlichen System-Prompt
- [ ] Pro Tool: Frontmatter-only-Files anlegen, die per Symlink auf den zentralen Body verweisen (siehe §8.2)
- [ ] Alte Tool-spezifische Agent-Files mit duplizierten Bodies in `_archive/` verschieben
- [ ] In jedem Tool-Setup-Manual: §6 (Install) um den Symlink-Schritt für Body-Files ergänzen

### Phase 5 — Globale Configs zentralisieren (2 Stunden)

- [ ] Neuer Ordner `Globals/` im Workspace (siehe §11.2 Struktur)
- [ ] `Globals/AGENTS.md` (~120 Zeilen) — tool-agnostische Conventions aus heutiger `OpenCode/Config-Files/AGENTS.md` herausziehen, projekt-/tool-spezifisches entfernen
- [ ] `Globals/CLAUDE.md` (~40 Zeilen) — `@AGENTS.md`-Import + Claude-Code-spezifika (Plan Mode, `/model`, `effortLevel`, Hook-Verweise)
- [ ] `Globals/LEARNINGS.md` + `LEARNINGS.inbox.md` — aus heutigen `claude-config/` / `OpenCode/Config-Files/` zusammenführen
- [ ] `Globals/claude-settings.json` — Template ohne profil-spezifische Modell-Aliase
- [ ] `Globals/opencode-local.json` + `Globals/opencode-cloud.json` — siehe §7.3
- [ ] `Globals/codex-config.toml` — Default-Provider LiteLLM, Subagent-Verweise
- [ ] `Globals/install.sh` schreiben (siehe §11.2) — idempotente Symlinks
- [ ] Old: `OpenCode/Config-Files/`, `Claude-Code/claude-config/` als `_archive/` markieren oder löschen

### Phase 6 — 1Password-Integration (30 Min)

- [ ] 1Password-Vault `Dev` anlegen mit Items: `LiteLLM`, `LiteLLM-EU`, `Ollama-Cloud`, ggf. `Anthropic-Direct`, `OpenAI-Direct` (§12.3)
- [ ] `~/.zshrc` Erweiterung committen (in `Globals/zshrc.snippet` ablegen + im Setup-Manual referenzieren) — siehe §12.2
- [ ] Für autonomen Agent: Service Account anlegen + `OP_SERVICE_ACCOUNT_TOKEN` im `Autonomer Coding Agent/scaffold/sandbox/run-sandbox.sh` setzen
- [ ] Verifizieren: `op read 'op://Dev/LiteLLM/api_key'` liefert Wert; `cc` / `codex` / `oc` starten ohne Key-Prompt

### Phase 7 — Verifikation (30 Min, nach Umsetzung)

- [ ] Mit jedem Tool eine Test-Session: `/explore` → korrekter Subagent + korrektes Modell, `/spec` → Plan-Mode-Äquivalent, `/delegate` → Subagent dispatched
- [ ] `/model`-Switch testen in jedem Tool — Default-Modell-Wechsel innerhalb der Session
- [ ] Für `local`-OpenCode-Profil: Offline-Test (WLAN aus) — muss laufen
- [ ] `cc-eu` (DSGVO-Session) testen — verifizieren, dass der EU-Key tatsächlich aktiv ist (LiteLLM-Dashboard)
- [ ] `last_verified`-Daten in den geänderten Files setzen
- [ ] `MOC - Agentic-SWE - …` MOCs nach Umbenennungen aktualisieren (Obsidian-Links)

**Geschätzter Gesamtaufwand:** 8–10 Stunden, aufteilbar auf 2–3 Sessions. Phasen 1–2 sind unabhängig; Phasen 3–6 bauen aufeinander auf.

---

## 10. Entscheidungen (Stand 2026-05-29)

Die zuvor offenen Punkte sind entschieden:

1. ✅ **Globale Configs im Workspace, gesynct ins Home-Dir.** Workspace ist Single Source of Truth für `AGENTS.md`, `CLAUDE.md` und die zugehörigen `settings.json`/`opencode.json`/`config.toml`-Templates. Symlinks ins Home-Dir versorgen die Tools. Strukturdetails in §12.
2. ✅ **Symlink** für Body-Sharing zwischen Agents und für globale Configs.
3. ✅ **`local` heißt strikt lokal** — nur Ollama auf `localhost:11434`, kein LiteLLM, keine Cloud-Roundtrips. Auch nicht für Recherche.
4. ✅ **DSGVO über LiteLLM Virtual Key**, nicht über ein eigenes Profil. EU-Key wird über 1Password injiziert (siehe §13). Pro Kundenprojekt eine `./AGENTS.md` mit Hinweis auf den zu nutzenden Key.
5. ✅ **Autonomer Coding Agent bleibt eigenständig** und wird durch das `local`-Profil von OpenCode abgedeckt — der Use-Case (offline, sandboxed, lange Loops) passt zur Hardware-Constraint des `local`-Profils.

---

## 11. AGENTS.md + CLAUDE.md — Struktur und globale Verteilung

### 11.1 Grundlagen aus den Best Practices (Mai 2026)

Frontier-Modelle folgen ca. **150–200 Instruktionen** zuverlässig — danach sinkt Compliance messbar ([HumanLayer: Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md), Mai 2026). Konsens der aktuellen Best-Practice-Texte:

- **Unter 200 Zeilen** als working ceiling, **unter 100 Zeilen** als Ziel
- **Spezifische Regeln** statt „write clean code" — jede Zeile muss die Frage „würde der Agent ohne diese Regel einen Fehler machen?" mit ja beantworten
- **WHAT/WHY/HOW-Struktur** (Tech-Stack / Projekt-Zweck / Arbeitsweise)
- **Append-only LEARNINGS** separat halten (via `@import` bzw. `instructions:`)
- **Hierarchie:** global → projekt → projekt-lokal (gitignored)

### 11.2 Workspace-Repo als Single Source

Du pflegst alles im Obsidian-Workspace (`Docs/AI Driven Development/`). Symlinks ins Home-Dir aktivieren die globalen Configs auf der Maschine:

```
Workspace (Source of Truth)
└── Docs/AI Driven Development/
    ├── Globals/                              ← NEU (Phase 5)
    │   ├── AGENTS.md                         ← tool-agnostische Conventions
    │   ├── CLAUDE.md                         ← Claude-Code-spezifisch + @import AGENTS.md
    │   ├── LEARNINGS.md                      ← append-only Lessons
    │   ├── LEARNINGS.inbox.md                ← Staging vom Hook
    │   ├── claude-settings.json              ← ~/.claude/settings.json Template
    │   ├── opencode-local.json               ← ~/.config/opencode/opencode-local.json
    │   ├── opencode-cloud.json               ← ~/.config/opencode/opencode-cloud.json
    │   ├── codex-config.toml                 ← ~/.codex/config.toml
    │   └── install.sh                        ← legt alle Symlinks/Imports an
    ├── Sub-Agents/                           ← zentrale Rollendefinitionen
    │   ├── researcher.body.md
    │   ├── reviewer.body.md
    │   └── security-auditor.body.md
    ├── Skills/                               ← bleibt unverändert
    │   └── …
    └── CLI-Tools/                            ← Manuals + Tool-Frontmatter
        ├── Claude-Code/Agents/               ← Frontmatter-only Files
        ├── Codex-CLI/agents/                 ← TOML-only Files
        └── OpenCode/Agents/                  ← Frontmatter-only Files
```

`install.sh` (skizziert, idempotent):

```bash
#!/usr/bin/env bash
set -euo pipefail
GLOBALS="$HOME/Docs/AI Driven Development/Globals"

# Claude Code
mkdir -p "$HOME/.claude/agents"
ln -sf "$GLOBALS/CLAUDE.md"          "$HOME/.claude/CLAUDE.md"
ln -sf "$GLOBALS/LEARNINGS.md"       "$HOME/.claude/LEARNINGS.md"
ln -sf "$GLOBALS/claude-settings.json" "$HOME/.claude/settings.json"
# Agents pro Tool: Frontmatter-File symlinked, Body via @-Import in jedem File

# Codex CLI
mkdir -p "$HOME/.codex/agents"
ln -sf "$GLOBALS/AGENTS.md"          "$HOME/.codex/AGENTS.md"
ln -sf "$GLOBALS/codex-config.toml"  "$HOME/.codex/config.toml"

# OpenCode
mkdir -p "$HOME/.config/opencode/agent"
ln -sf "$GLOBALS/AGENTS.md"          "$HOME/.config/opencode/AGENTS.md"
ln -sf "$GLOBALS/LEARNINGS.md"       "$HOME/.config/opencode/LEARNINGS.md"
ln -sf "$GLOBALS/opencode-local.json"  "$HOME/.config/opencode/opencode-local.json"
ln -sf "$GLOBALS/opencode-cloud.json"  "$HOME/.config/opencode/opencode-cloud.json"

# Skills (cross-tool über alle drei Discovery-Pfade)
ln -sfn "$HOME/Docs/AI Driven Development/Skills" "$HOME/.claude/skills"
ln -sfn "$HOME/Docs/AI Driven Development/Skills" "$HOME/.codex/skills"
ln -sfn "$HOME/Docs/AI Driven Development/Skills" "$HOME/.config/opencode/skills"

echo "✓ Globals installed via symlinks. Edit in workspace, changes are live."
```

### 11.3 Aufgabenverteilung AGENTS.md ↔ CLAUDE.md

Da Claude Code primär `CLAUDE.md` liest und OpenCode/Codex `AGENTS.md`, hier eine saubere Trennung:

| Datei | Inhalt | Konsument |
|---|---|---|
| `AGENTS.md` (~120 Zeilen) | Tech-Stack, Coding-Verhalten, Git-Workflow, Validation-Pipeline, Recherche/Quellen, harte Regeln (MUSS / DARF NICHT). Alles tool-agnostisch. | Codex CLI, OpenCode (direkt) |
| `CLAUDE.md` (~40 Zeilen) | `@AGENTS.md`-Import + Claude-Code-spezifika: Plan-Mode-Konvention, Slash-Commands, Hook-Verweise, `effortLevel`-Default. | Claude Code (direkt) |
| `LEARNINGS.md` (append-only) | Datierte Einträge pro Lesson. Wächst, wird periodisch verdichtet. | Alle drei via Import/Instructions |

> 💡 **`@import` in CLAUDE.md:** Claude Code unterstützt `@<pfad>` als Inline-Include ([Boris Cherny's CLAUDE.md-Pattern](https://howborisusesclaudecode.com/)). `@~/Docs/AI Driven Development/Globals/AGENTS.md` zieht die zentrale AGENTS.md beim Session-Start mit ein — du pflegst die Conventions an einer Stelle.

### 11.4 Pro-Projekt-Overlay

Pro Repo bleibt der bestehende Mechanismus:

- `./AGENTS.md` — projekt-spezifische Conventions, Tech-Stack-Eigenheiten, DSGVO-Hinweise (z.B. „nutze LITELLM_EU_KEY"), dbt-Layout
- `./CLAUDE.md` — `@./AGENTS.md`-Import + ggf. Claude-Code-spezifisches
- `./CLAUDE.local.md` / `./AGENTS.local.md` — persönlich, gitignored

Settings-Präzedenz: global → projekt → projekt-lokal — alle mergen, late wins.

---

## 12. Secrets via 1Password CLI — kein Plain-Text-`export`

Du willst Keys (LiteLLM EU/US, Ollama Cloud, ggf. Anthropic-Direct) aus 1Password ziehen statt sie als plain `export` in der Shell zu halten. Stand Mai 2026 sind die offiziellen Patterns dafür stabil ([1Password Developer Docs](https://developer.1password.com/docs/cli/secrets-environment-variables/)).

### 12.1 Drei Patterns — wann welches

| Pattern | Wann | Vorteil | Nachteil |
|---|---|---|---|
| `op read` | Einmaliges Auflösen beim Shell-Start (~/.zshrc) | Simpel, `$LITELLM_API_KEY` ist normal verfügbar | Wert steht plain im Memory der Shell-Session |
| `op run -- cmd` | Pro CLI-Start | Secrets nur im Subprocess, Maskierung im Output | Muss bei jedem CLI-Start aufgerufen werden, kein Alias-Reuse |
| `op inject` | Template-Files (z.B. settings.json) | Wenn das Tool kein `{env:...}` kann | Schreibt die aufgelöste Datei auf Disk — Schutz schwächer |

### 12.2 Empfehlung für deinen Stack

**Tools mit `{env:...}`-Support (OpenCode):** Verwende `op run` als Alias-Wrapper. So bleibt der Key nur im Subprocess.

**Tools mit nativem Env-Var-Lookup (Claude Code, Codex):** Verwende `op read` einmal im Shell-Start, ggf. mit Session-Cache.

```bash
# ~/.zshrc — Pattern für Claude Code und Codex
# Beim Login einmalig auflösen, kein Plain-Text im File:
export LITELLM_API_KEY="$(op read 'op://Dev/LiteLLM/api_key')"
export LITELLM_EU_KEY="$(op read 'op://Dev/LiteLLM-EU/api_key')"
export OLLAMA_API_KEY="$(op read 'op://Dev/Ollama-Cloud/api_key')"

# Aliase für CLI-Starts — nutzen die env-Vars:
alias cc='claude'
alias codex='codex'

# Pattern für DSGVO-Sessions: EU-Key vor cd setzen
cc-eu() {
  ANTHROPIC_AUTH_TOKEN="$LITELLM_EU_KEY" claude "$@"
}
codex-eu() {
  env OPENAI_API_KEY="$LITELLM_EU_KEY" codex "$@"
}

# Alternative für OpenCode mit op run (Key nur im Subprocess):
alias oc='op run -- opencode'
alias oc-local='OPENCODE_CONFIG=~/.config/opencode/opencode-local.json op run -- opencode'
```

> 💡 **Service Account für Headless-Runs:** Für den autonomen Coding-Agent (lange Loops ohne dich am Bildschirm) brauchst du einen [1Password Service Account](https://zatoima.github.io/en/1password-cli-service-account-setup/) mit `OP_SERVICE_ACCOUNT_TOKEN` — Biometric-Unlock funktioniert dort nicht. Nur die Vaults freigeben, die der Agent braucht.

### 12.3 Vault-Struktur (Vorschlag)

```
1Password Vault "Dev"
├── LiteLLM/             api_key  (Standard, US-Routing)
├── LiteLLM-EU/          api_key  (DSGVO, EU-only Virtual Key)
├── Ollama-Cloud/        api_key
├── Anthropic-Direct/    api_key  (optional Fallback bei LiteLLM-Outage)
└── OpenAI-Direct/       api_key  (optional Fallback)
```

Secret References sind dann `op://Dev/<Item>/api_key`. Stabil über Item-Renames, weil 1Password intern IDs nutzt.

### 12.4 Was sich für die Configs ändert

In `opencode-cloud.json` bleibt `"apiKey": "{env:OLLAMA_API_KEY}"` — OpenCode löst die Env-Var auf, die von `op run` oder vom Login-`op read` gesetzt wurde. In `~/.claude/settings.json` bleibt `ANTHROPIC_AUTH_TOKEN` via Env (Claude Code löst Env-Vars im `env`-Block auf). In `~/.codex/config.toml` referenziert `env_key = "OPENAI_API_KEY"` die gleiche Variable.

**Kein API-Key landet je auf Disk.** Das bewahrt das KISS-Versprechen, weil alle drei Tools das gleiche Auflösungs-Pattern nutzen.

---

---

## 13. Quellen

**Best Practices & Konzepte:**
- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) (Anthropic, 2026)
- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents) (Anthropic, 2026)
- [Building agents with the Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) — Agent-Sprawl, Single Responsibility
- [Building Claude Code with Boris Cherny](https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny) (Pragmatic Engineer / Boris Cherny) — Compounding Engineering, KISS-CLAUDE.md
- [How Boris Uses Claude Code](https://howborisusesclaudecode.com/) — `@`-Imports, LEARNINGS-Pattern
- [How the Creator of Claude Code Actually Uses Claude Code](https://getpushtoprod.substack.com/p/how-the-creator-of-claude-code-actually) (2026)
- [How to Make Claude Code Better Every Time — Kieran Klaassen](https://creatoreconomy.so/p/how-to-make-claude-code-better-every-time-kieran-klaassen) — Plan → Work → Assess → Compound

**Subagent-Driven Development:**
- [obra/superpowers — subagent-driven-development SKILL](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md) (Jesse Vincent, Stand März 2026)
- [Claude Code Subagents: A 2026 Practical Guide — Tembo.io](https://www.tembo.io/blog/claude-code-subagents)
- [Best AI Model for Coding Agents in 2026: A Routing Guide](https://www.augmentcode.com/guides/ai-model-routing-guide) — 51% Kostenersparnis mit dreistufigem Routing
- [Pick the Right Claude Code Model for Every Task — DEV](https://dev.to/klement_gunndu/pick-the-right-claude-code-model-for-every-task-1p6a)

**Codex CLI:**
- [Configuration Reference — Codex](https://developers.openai.com/codex/config-reference) (OpenAI, 2026)
- [Advanced Configuration — Codex](https://developers.openai.com/codex/config-advanced) — Profiles, model_reasoning_effort
- [Subagents — Codex](https://developers.openai.com/codex/subagents) (OpenAI, 2026)
- [Custom instructions with AGENTS.md — Codex](https://developers.openai.com/codex/guides/agents-md) (OpenAI, 2026)
- [Agent Skills — Codex](https://developers.openai.com/codex/skills) (OpenAI, GA Dezember 2025)
- [Codex CLI Custom Agent Definitions: Building Specialised Subagents with TOML Configuration](https://codex.danielvaughan.com/2026/04/27/codex-cli-custom-agent-definitions-toml-specialised-subagents/) (April 2026)
- [Reasoning Effort Tuning: Minimal to xhigh](https://codex.danielvaughan.com/2026/03/27/reasoning-effort-tuning/) (März 2026)
- [Use subagents and custom agents in Codex — Simon Willison](https://simonwillison.net/2026/Mar/16/codex-subagents/) (März 2026)
- [The Codex CLI Customisation Stack](https://codex.danielvaughan.com/2026/04/12/codex-cli-customisation-stack-unified-system/) (April 2026)
- [Using LiteLLM with OpenAI Codex (LiteLLM Docs)](https://docs.litellm.ai/docs/tutorials/openai_codex)

**OpenCode:**
- [Agents — OpenCode Docs](https://opencode.ai/docs/agents/) — Mode-Feld, Subagent-Inheritance
- [Providers — OpenCode Docs](https://opencode.ai/docs/providers/) — Custom Provider, Ollama-Integration
- [Models — OpenCode Docs](https://opencode.ai/docs/models/) — `model` + `small_model`
- [OpenCode-Ollama Integration](https://docs.ollama.com/integrations/opencode) (Ollama Docs)
- [Issue #19344 — Skills sind global geladen](https://github.com/anomalyco/opencode/issues/19344)
- [opencode-model-router (Plugin, Marco Jardim)](https://github.com/marco-jardim/opencode-model-router)

**LiteLLM:**
- [Auto Routing — LiteLLM Docs](https://docs.litellm.ai/docs/proxy/auto_routing) — Complexity Router
- [Issue #23247 — Complexity Router fails with multi-modal](https://github.com/BerriAI/litellm/issues/23247)
- [Issue #25134 — Complexity Router does not support /v1/responses](https://github.com/BerriAI/litellm/issues/25134) — relevant für Codex
- [How to Route LLM Traffic by Cost and Complexity](https://agentbus.sh/posts/how-to-route-llm-traffic-by-cost-and-complexity/) — Vergleich Routing-Strategien

**Cross-Tool-Standards:**
- [What Is the Agent Skills Open Standard? — agensi.io](https://www.agensi.io/learn/agent-skills-open-standard) — SKILL.md Format
- [AGENTS.md Playbook 2026: Codex CLI Hierarchy + Monorepo](https://www.codegateway.dev/en/blog/agents-md-playbook-2026)
- [AI Agent Skills Guide 2026: SKILL.md — The Prompt Index](https://www.thepromptindex.com/how-to-use-ai-agent-skills-the-complete-guide.html)
- [Claude Code vs Codex vs OpenCode (2026) — Medium](https://medium.com/@unicodeveloper/claude-code-vs-codex-vs-opencode-which-ai-coding-agent-is-actually-the-best-in-2026-baa9f6fd5374)

**CLAUDE.md / AGENTS.md Best Practices:**
- [Writing a good CLAUDE.md — HumanLayer Blog](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — Instruction-Budget, WHAT/WHY/HOW
- [Complete Guide to CLAUDE.md and AGENTS.md 2026 — Data Science Collective](https://medium.com/data-science-collective/the-complete-guide-to-ai-agent-memory-files-claude-md-agents-md-and-beyond-49ea0df5c5a9)
- [CLAUDE.md Best Practices: The Complete Guide to Context Engineering](https://blink.new/blog/claude-md-best-practices)
- [Creating the Perfect CLAUDE.md — Dometrain](https://dometrain.com/blog/creating-the-perfect-claudemd-for-claude-code/)
- [Implementing CLAUDE.md and Agent Skills — Matthew Groff](https://www.groff.dev/blog/implementing-claude-md-agent-skills)

**Lokale Ollama-Modellauswahl (Primärquelle für §7):**
- [[Lokale Ollama Modelle auf M4 Pro - 20260602]] — Deep-Research-Ergebnis vom 2026-06-02, Pflicht-Lektüre vor Profil-Anpassungen. Ergänzt durch:

**Open-Weight-Modelle & Lokale Inferenz (Mai 2026):**
- [SWE-Bench Leaderboard Mai 2026](https://www.marc0.dev/en/leaderboard)
- [SWE-rebench Leaderboard](https://swe-rebench.com/) — repo-scale Benchmark
- [Best Open-Source & Open-Weight Coding Models (2026) — Kilo](https://kilo.ai/open-source-models)
- [Best Ollama Models 2026 — Morph](https://www.morphllm.com/best-ollama-models)
- [Best Local AI Coding Models 2026: Qwen Coder Beats Claude — Local AI Master](https://localaimaster.com/models/best-local-ai-coding-models)
- [Ollama Cloud In-Depth Comparison Mai 2026](https://note.com/zephel01/n/n250a7ecd880c?hl=en-US) — Free/Pro/Max Pläne
- [Qwen3-Coder-Next: Local Coding Agents Guide](https://dev.to/sienna/qwen3-coder-next-the-complete-2026-guide-to-running-powerful-ai-coding-agents-locally-1k95)
- [Qwen3-Coder on Ollama](https://ollama.com/library/qwen3-coder-next)
- [MiniMax M2.5 VRAM Requirements: Local Deployment Guide — Novita](https://blogs.novita.ai/can-you-run-minimax-m2-5-locally-vram-reality-check/)
- [GLM-4.6 Run Locally Guide — Unsloth](https://unsloth.ai/docs/models/tutorials/glm-4.6-how-to-run-locally)
- [GLM-5 How to Run Locally — Unsloth](https://unsloth.ai/docs/models/glm-5)
- [MiniMax-M2.7 Run Locally — Unsloth](https://unsloth.ai/docs/models/minimax-m27)

**1Password CLI:**
- [Load secrets into the environment — 1Password Developer](https://developer.1password.com/docs/cli/secrets-environment-variables/)
- [How to store secrets in 1Password CLI and load them into ZSH — Gruntwork](https://www.gruntwork.io/blog/how-to-securely-store-secrets-in-1password-cli-and-load-them-into-your-zsh-shell-when-needed)
- [Setting Up Non-Interactive Authentication with Service Accounts — zatoima](https://zatoima.github.io/en/1password-cli-service-account-setup/)

---

## Querverweise (im Workspace)

- [[Developer Workflow]] — bleibt konzeptionell unverändert, Tooling-Anker erweitern
- [[Anforderungen an das CLI-Tool]] — §3 (Profile) auf neue Realität ziehen
- [[Complexity Routing]] — Status „LiteLLM-Router weiter zukünftige Überlegung" bestätigen
- [[MOC - Agentic-SWE - Claude Code]] / [[MOC - Agentic-SWE - OpenCode]] / *(neu)* `MOC - Agentic-SWE - Codex CLI` anlegen
- [[Skill-Agent-Mappings]] — Codex-Spalte ergänzen
- [[Lokale Ollama Modelle auf M4 Pro - 20260602]] — Lokale Modellauswahl, Quellen-Basis für §7
- [[Research Briefs - Ollama-Modelle für OpenCode Agents (2026-05-29)]] — Brief 2 (Cloud) noch offen
