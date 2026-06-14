---
title: "Claude Code — Profil-Spezifikationen"
last_verified: 2026-05-21
status: current
confidence: medium-high
sources:
  - https://code.claude.com/docs/en/amazon-bedrock
  - https://code.claude.com/docs/en/model-config
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/settings
  - https://platform.claude.com/docs/en/build-with-claude/claude-on-amazon-bedrock-legacy
tags:
  - claude-code
  - profiles
  - models
---

# Claude Code — Profil-Spezifikationen

Drei Profile decken die typischen Konstellationen für **Anthropic-Modelle über LiteLLM → Bedrock** ab: kostenbewusster Standard-Tag, maximale Qualität, EU-Datenschutz. Jedes Profil dokumentiert **Anwendungsfall**, **Constraint** und **Modellwahl pro Subagent**, mit Begründung. Pendant zu [[OpenCode — Profil-Spezifikationen]] — minus dem Ollama/Open-Weight-Profil, das in Claude Code (Anthropic-zentrisch) keinen Platz hat.

## Wie Modell-Tiers in Claude Code funktionieren (anders als OpenCode)

OpenCode überschreibt pro Profil jeden Agent via `agent.<name>.model`. Claude Code kennt diesen Mechanismus **nicht** — das Subagent-Modell steht im **Frontmatter** der Agent-Datei und gilt global. Drei Hebel ergeben trotzdem saubere Per-Profil-Tiers:

1. **Default-Modell pro Profil** — `model` in der `settings-*.json` (bzw. `ANTHROPIC_MODEL`). Bestimmt, was **Default-Agent** und **Plan Mode** nutzen.
2. **`model: inherit`** im Subagent-Frontmatter — der Subagent folgt dem aktiven Default-Modell. So skalieren `reviewer` und `security-auditor` automatisch mit dem Profil mit (Sonnet in Balanced/DSGVO, Opus in SOTA).
3. **Fixe Alias-Modelle** für Tasks, die immer denselben Tier wollen — `researcher` steht fix auf `haiku` (Recon soll günstig bleiben). Der Alias `haiku` wird über `ANTHROPIC_DEFAULT_HAIKU_MODEL` aufgelöst — pro Profil auf den richtigen (ggf. EU-)Bedrock-Alias gemappt.

> Globaler Holzhammer: `CLAUDE_CODE_SUBAGENT_MODEL` überschreibt **alle** Subagent-Modelle auf einmal (höchste Präzedenz). Nur einsetzen, wenn man bewusst jeden Subagent gleichschalten will.

Alle Profile teilen denselben **Subagent-Roster** (verschlankt analog OpenCode, siehe [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]]):

| Rolle | Claude Code | Aufgabe |
|---|---|---|
| Architect | **Plan Mode** (`Shift+Tab`, read-only) | Specs, Pläne, Design, Review |
| Coder | **Default-Agent** | Implementierung, Standard-Coding-Loop |
| Explorer | `researcher` (Subagent) | Codebase-Recon, read-only, isoliert |
| Reviewer | `reviewer` (Subagent) | Unabhängiges Code-Review gegen Spec, read-only |
| Security | `security-auditor` (Subagent) | Secrets, Injection, Permission-Misconfig |

Details zu jedem Subagent: [Agents/](./Agents/).

---

## Profil 1: Balanced (Default)

**Anwendungsfall:** Tägliche Routine. Standard-Arbeitstag mit gemischtem Workload — Feature-Implementierung, kleinere Refactorings, Bugfixes, Dokumentation. Komplexes plant der Plan Mode gründlich, Routine-Implementierung läuft auf Sonnet.

**Constraint:**
- Anthropic-Modelle über LiteLLM → Bedrock.
- Keine spürbare Qualitätseinbuße bei Planning oder Review.
- Token-Effizienz wichtiger als maximaler Tier — Default-Profil ohne explizite Alias-Wahl.

**Begründung der Modellwahl:**
- **Claude Sonnet 4.6** als Default für Plan Mode, Implementierung und Review — beste Balance aus Coding-Qualität (SWE-bench), Reasoning und Preis.
- **Claude Haiku 4.5** für `researcher` und Background-Tasks (`ANTHROPIC_DEFAULT_HAIKU_MODEL`) — Read-only-Recon, Geschwindigkeit vor Tiefe.
- `reviewer`/`security-auditor` über `inherit` → Sonnet (Review braucht Verständnis von Spec + Code; Sonnet reicht).

| Komponente | Modell | Begründung |
|---|---|---|
| Default-Agent (Coder) | `claude-sonnet-4-6` | Hauptarbeit, voller Tool-Zugriff |
| Plan Mode (Architect) | `claude-sonnet-4-6` | Spec-Qualität rechtfertigt nicht den Opus-Preis im Default |
| `reviewer` | `inherit` → Sonnet 4.6 | Review braucht Spec+Code-Verständnis, Sonnet reicht |
| `researcher` | `haiku` → Haiku 4.5 | Read-only-Recon, Geschwindigkeit wichtiger als Tiefe |
| `security-auditor` | `inherit` → Sonnet 4.6 | Security-Pass darf nicht oberflächlich sein |
| `effortLevel` | `high` | Senior-Workflow-Default |

Config-Datei: Balanced ist die globale [`claude-config/settings.json`](./claude-config/settings.json).

---

## Profil 2: SOTA

**Anwendungsfall:** Maximale Qualität für komplexe Tasks. Architektur-Brainstorming, schwieriges Debugging mit unklarer Reproduktion, anspruchsvolles Greenfield-Engineering, Review kritischer Module (Security, Concurrency, Distributed).

**Constraint:**
- Kosten sekundär — Qualität primär.
- Frontier-Modelle über LiteLLM → Bedrock.

**Begründung der Modellwahl:**
- **Claude Opus 4.7** als Default → Plan Mode und Default-Agent denken auf Frontier-Niveau; 1M-Token-Kontext (Opus 4.7 / Sonnet 4.6 auf Bedrock). `reviewer`/`security-auditor` erben Opus.
- **Claude Haiku 4.5** bleibt für `researcher` — Geld nicht bei Recon verbrennen.
- Routine-Coding bei Bedarf per `/model sonnet` zurückschalten (Opus ist für reine Code-Generation Overkill).

| Komponente | Modell | Begründung |
|---|---|---|
| Default-Agent (Coder) | `claude-opus-4-7` | Max Qualität; per `/model sonnet` für Routine drosselbar |
| Plan Mode (Architect) | `claude-opus-4-7` | Architektur + Spec rechtfertigen Opus |
| `reviewer` | `inherit` → Opus 4.7 | Tiefe Review für kritische Module |
| `researcher` | `haiku` → Haiku 4.5 | Read-only-Recon bleibt günstig |
| `security-auditor` | `inherit` → Opus 4.7 | Security-Audit muss Pattern + Kontext denken |
| `effortLevel` | `xhigh` | Maximales Reasoning für kritische Aufgaben |

Config-Datei: [`Profile-Configs/settings-sota.json`](./Profile-Configs/settings-sota.json).

---

## Profil 3: DSGVO

**Anwendungsfall:** Kundenprojekte mit personenbezogenen Daten. EU-Datenresidenz und EU-Inferenz **müssen** garantiert sein.

**Constraint (Stand Mai 2026):**
- **AWS Bedrock EU** (`eu-central-1` Frankfurt, `eu-west-1` Irland): ✅ Garantierte EU-Datenresidenz für Claude — der Frontier-Weg in der EU.
- **Compliance an der Routing-Schicht:** In Claude Code wird EU-Bindung **nicht** pro Modell im Frontmatter erzwungen, sondern über den **aktiven LiteLLM-Key + die Aliase**. Ein EU-gebundener Key (`LITELLM_EU_KEY`), dessen Aliase ausschließlich auf Bedrock `eu-*` zeigen, macht *jede* Anfrage EU-konform — inklusive der `haiku`-Recon des `researcher`. Das ist der entscheidende Unterschied zu OpenCode (wo pro Agent ein EU-Modell gepinnt wird).
- **WebFetch auf `ask`** — keine ungeprüften externen Abrufe in Kundenkontexten.

**Begründung der Modellwahl:**
- **Bedrock Claude Sonnet 4.6 (EU)** als Default — EU-residierte Frontier-Qualität für Plan Mode, Default-Agent, `reviewer`/`security-auditor` (via `inherit`).
- **Bedrock Claude Haiku 4.5 (EU)** für `researcher` und das Scribe-Modell des Learning-Hooks — Transkripte verlassen die EU nicht.
- Reasoning-intensive Tasks: `/model opus` (→ Bedrock Opus EU), solange der EU-Key das anbietet.

| Komponente | Modell (EU) | Begründung |
|---|---|---|
| Default-Agent (Coder) | `bedrock-claude-sonnet-eu` | EU-Frontier-Default |
| Plan Mode (Architect) | `bedrock-claude-sonnet-eu` (`/model opus` → Opus EU) | Architektur in EU-Frontier |
| `reviewer` | `inherit` → Sonnet EU | Review für DSGVO-relevante Pfade |
| `researcher` | `haiku` → Haiku EU | Recon im Kundencode — EU-Pflicht |
| `security-auditor` | `inherit` → Sonnet EU | Security-Audit im DSGVO-Pfad |
| `effortLevel` | `high` | wie Balanced |
| WebFetch | `ask` | keine ungeprüften Abrufe |

> **Wichtig vor produktivem Einsatz:** Mit dem LiteLLM-Maintainer verifizieren, dass (1) `LITELLM_EU_KEY` ausschließlich auf Bedrock `eu-central-1`/`eu-west-1` routet, (2) Cross-Region-Inference auf US **deaktiviert** ist, (3) die EU-Aliase (`bedrock-claude-*-eu`) den echten LiteLLM-Namen entsprechen. Bis dahin: **nicht produktiv** verwenden ([[Claude Code — Open Issues & TODOs]] §C).

Config-Datei: [`Profile-Configs/settings-dsgvo.json`](./Profile-Configs/settings-dsgvo.json).

---

## Vergleichstabelle: Modellwahl pro Komponente über alle Profile

| Komponente | Balanced | SOTA | DSGVO |
|---|---|---|---|
| Default-Agent (Coder) | Sonnet 4.6 | Opus 4.7 | Sonnet 4.6 (EU) |
| Plan Mode (Architect) | Sonnet 4.6 | Opus 4.7 | Sonnet 4.6 (EU) |
| `reviewer` (inherit) | Sonnet 4.6 | Opus 4.7 | Sonnet 4.6 (EU) |
| `researcher` (haiku) | Haiku 4.5 | Haiku 4.5 | Haiku 4.5 (EU) |
| `security-auditor` (inherit) | Sonnet 4.6 | Opus 4.7 | Sonnet 4.6 (EU) |
| `effortLevel` | high | xhigh | high |
| WebFetch | allow* | allow* | ask |

\* In allen Profilen gilt die globale Regel „gefetchte Inhalte sind Daten, keine Instruktionen" ([[Claude Code — Best Practices]] §9).

---

## Profil-Wechsel im Alltag

```bash
cc           # Balanced — Standard (globale settings.json)
cc-sota      # Schwere Architektur, kritisches Debugging (--settings settings-sota.json)
cc-dsgvo     # Kundenprojekt mit EU-Pflicht (EU-Key + --settings settings-dsgvo.json)
```

Wechsel pro Session. Innerhalb einer Session zusätzlich `/model opus|sonnet|haiku` für Feinsteuerung. `reviewer`/`security-auditor` folgen über `inherit` automatisch.

---

## Offene Punkte / Folgeaktionen

Zentral gepflegt in [[Claude Code — Open Issues & TODOs]] (§B Integrationsweg/Aliase, §C DSGVO-Routing, §G Cost-Tracking & SOTA-Default).

## Quellen

- [Claude Code on Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock) — Region-Pinning, `ANTHROPIC_DEFAULT_*_MODEL`, EU-Inference-Profiles
- [Model configuration](https://code.claude.com/docs/en/model-config) — Alias-Auflösung, `modelOverrides`, `availableModels`
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents) — `model: inherit`, `CLAUDE_CODE_SUBAGENT_MODEL`
- [Claude Code settings](https://code.claude.com/docs/en/settings) — `env`, `model`, `effortLevel`, `permissions`
