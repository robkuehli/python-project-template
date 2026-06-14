---
title: "OpenCode — Profil-Spezifikationen"
last_verified: 2026-05-20
status: current
confidence: medium-high
sources:
  - https://platform.claude.com/docs/en/build-with-claude/claude-on-amazon-bedrock-legacy
  - https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude
  - https://learn.microsoft.com/en-us/answers/questions/5867930/timeline-for-claude-in-microsoft-foundry-to-run-on
  - https://ollama.com/blog/cloud-models
  - https://www.gerloff.dev/writing/claude-aws-azure-google-gdpr
tags:
  - opencode
  - profiles
  - models
---

# OpenCode — Profil-Spezifikationen

Vier Profile decken die typischen Konstellationen ab: kostenbewusster Standard-Tag, maximale Qualität, EU-Datenschutz, Open-Weight via Ollama. Jedes Profil dokumentiert **Anwendungsfall**, **Constraint** und **Modellwahl pro Sub-Agent**, mit Begründung.

Alle Profile teilen denselben **Agent-Roster** (verschlankt 2026-05-21 — Begründung: [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]]):

| Typ | Agent | Aufgabe |
|---|---|---|
| Primary | `build` | Coder-Mode — Implementierung, Standard-Coding-Loop |
| Primary | `plan` | Architect-Mode — Specs, Pläne, Design, Review |
| Subagent | `researcher` | Codebase-Recon, Pattern-Erkennung, read-only, isoliert |
| Subagent | `reviewer` | Unabhängiges Code-Review gegen Spec, read-only |
| Subagent | `security-auditor` | Secrets, Injection-Pfade, Permission-Misconfigurations |

Entfernt (reine Skill-Doppelungen): `planner`, `debugger`, `refactorer`, `docs-writer`, `test-generator`, `git-helper`. Ihre Funktion ist als Skill (`plan`/`debug`/`test`/`capture`) bzw. direkt im `build`-Mode abgedeckt; Learning-Capture übernimmt der SessionEnd-Hook + `/capture`.

Details zu jedem Agent: [Agents/](./Agents/).

---

## Profil 1: Balanced (Default)

**Anwendungsfall:** Tägliche Routine. Standard-Arbeitstag mit gemischtem Workload — Feature-Implementierung, kleinere Refactorings, Bugfixes, Dokumentation. Komplexes plant der `plan`-Agent gründlich, Routine-Implementierung läuft günstig.

**Constraint:**
- Mix aus Cloud (LiteLLM) und gelegentlich lokal (Ollama für Trivial-Tasks).
- Keine spürbare Qualitätseinbuße bei Planning oder Review.
- Token-Effizienz wichtiger als maximale Modellgröße.
- Default-Profil — wird ohne explizite Alias-Wahl genutzt.

**Begründung der Modellwahl:**
- **Claude Sonnet 4.6** als Default für Planning, Implementation, Review — beste Balance aus Coding-Qualität (SWE-bench), Reasoning und Preis.
- **GPT-5 mini (Azure EU)** für Routine-Code-Generierung und Test-Erstellung — token-effizienter als Claude bei reinen Code-Tasks, Azure-EU als Default schon hier (vermeidet US-Routing-Überraschungen).
- **Claude Haiku 4.5** für leichte Sub-Tasks (`researcher`) und als `small_model`.

| Agent | Modell | Begründung |
|---|---|---|
| `build` (primary) | `litellm/claude-sonnet-4-6` | Hauptarbeit, breiter Tool-Zugriff. Hält test/delegate/debug. |
| `plan` (primary) | `litellm/claude-sonnet-4-6` | Spec-Qualität rechtfertigt nicht Opus-Preis im Default |
| `reviewer` | `litellm/claude-sonnet-4-6` | Review braucht Verständnis von Spec + Code, Sonnet reicht |
| `researcher` | `litellm/claude-haiku-4-5` | Read-only-Recon, hohe Geschwindigkeit wichtiger als Tiefe |
| `security-auditor` | `litellm/claude-sonnet-4-6` | Security-Pass darf nicht oberflächlich sein |
| `small_model` | `litellm/claude-haiku-4-5` | OpenCode-intern für Title-Gen etc. |

Config-Datei: [`Profile-Configs/opencode-balanced.json`](./Profile-Configs/opencode-balanced.json).

---

## Profil 2: SOTA

**Anwendungsfall:** Maximale Qualität für komplexe Tasks. Architektur-Brainstorming für ein neues System, schwieriges Debugging mit unklarer Reproduktion, anspruchsvolles Greenfield-Engineering, Code-Review für kritische Module (Security, Concurrency, Distributed).

**Constraint:**
- Nur über LiteLLM verfügbare Frontier-Modelle (Claude via Bedrock oder direkt, GPT-5 via Azure).
- Kosten sind sekundär — Qualität ist primär.
- Keine Open-Weight-Modelle in Hauptrollen (für SOTA-Profil verfügbar, aber nicht kosteneffizienter als Frontier).

**Begründung der Modellwahl:**
- **Claude Opus 4.7** für alles, was Reasoning braucht — Planning, Review, Debugging, Security-Audit. 1M-Token-Kontext, beste Performance auf SWE-bench Verified (Stand Mai 2026).
- **Claude Sonnet 4.6** für Implementierung und Refactoring — Opus ist Overkill für reine Code-Generation; Sonnet liefert vergleichbare Code-Qualität bei niedrigeren Kosten und schnellerem Throughput.
- **Haiku** weiter für `researcher` und `small_model` — Geld nicht bei Recon verbrennen.

| Agent | Modell | Begründung |
|---|---|---|
| `build` (primary) | `litellm/claude-sonnet-4-6` | Implementierung — Sonnet ist Sweet Spot, Opus-Overkill. Hält test/delegate/debug. |
| `plan` (primary) | `litellm/claude-opus-4-7` | Architektur und Spec-Qualität rechtfertigen Opus |
| `reviewer` | `litellm/claude-opus-4-7` | Tiefe Review für kritische Module |
| `researcher` | `litellm/claude-sonnet-4-6` | Anspruchsvollere Recon-Tasks, Haiku zu flach |
| `security-auditor` | `litellm/claude-opus-4-7` | Security-Audit muss Pattern + Kontext denken |
| `small_model` | `litellm/claude-haiku-4-5` | OpenCode-intern |

Config-Datei: [`Profile-Configs/opencode-sota.json`](./Profile-Configs/opencode-sota.json).

---

## Profil 3: DSGVO

**Anwendungsfall:** Kundenprojekte mit personenbezogenen Daten oder anderen DSGVO-relevanten Inhalten. EU-Datenresidenz und EU-Inferenz **müssen** garantiert sein.

**Constraint (Stand Mai 2026):**
- **AWS Bedrock EU** (`eu-central-1` Frankfurt, `eu-west-1` Irland): ✅ Garantierte EU-Datenresidenz für Claude. Einziger Frontier-Weg für Claude in EU.
- **Azure AI Foundry — Claude:** ❌ Auch wenn als EU-Deployment konfiguriert, läuft die tatsächliche Inferenz aktuell auf Anthropic-Servern in den USA. Microsoft hat "Coming 2026" als Status, aber noch nicht GA. **Nicht DSGVO-konform für Claude.**
- **Azure AI Foundry — OpenAI:** ✅ EU-Deployment möglich und etabliert. GPT-5 mini / GPT-5 als EU-Inferenz nutzbar.
- **Ollama lokal:** ✅ Komplett lokal, kein Cloud-Transfer. Für Sub-Tasks wo Modell-Qualität sekundär ist.
- **Ollama Cloud:** ❌ US-basiert. **Nicht im DSGVO-Profil verwenden.**

**Begründung der Modellwahl:**
- **Bedrock Claude Sonnet 4.6 (EU)** als Default — EU-residierte Frontier-Qualität für Hauptarbeit (`build`, `researcher`).
- **Bedrock Claude Opus 4.7 (EU)** für Reasoning-intensive Tasks (`plan`, `reviewer`, `security-auditor`).
- **Lokales Ollama (Llama 3.2 3B)** für `small_model` — Daten verlassen die Maschine nicht.

| Agent | Modell | Begründung |
|---|---|---|
| `build` (primary) | `litellm/bedrock-claude-sonnet-eu` | EU-Frontier-Default |
| `plan` (primary) | `litellm/bedrock-claude-opus-eu` | Architektur in EU-Frontier |
| `reviewer` | `litellm/bedrock-claude-opus-eu` | Tiefe Review für DSGVO-relevante Pfade |
| `researcher` | `litellm/bedrock-claude-sonnet-eu` | Recon im Kundencode — EU-Pflicht |
| `security-auditor` | `litellm/bedrock-claude-opus-eu` | Security-Audit zu kritisch für Sonnet im DSGVO-Pfad |
| `small_model` | `ollama/llama3.2:3b` | Title-Gen lokal, keine Cloud-Sprünge |

> **Wichtig vor produktivem Einsatz:** Die `bedrock-claude-*-eu`-Modellnamen müssen mit der Firmen-LiteLLM-Konfiguration übereinstimmen. Mit dem LiteLLM-Maintainer verifizieren, dass:
> 1. Bedrock-Endpoint auf `eu-central-1` oder `eu-west-1` zeigt.
> 2. Cross-Region-Inference auf US-Regionen **explizit deaktiviert** ist.
> 3. Modell-IDs den hier verwendeten Pseudonamen entsprechen (oder hier anpassen).

Config-Datei: [`Profile-Configs/opencode-dsgvo.json`](./Profile-Configs/opencode-dsgvo.json).

---

## Profil 4: Ollama

**Anwendungsfall:** Datensensitive Tasks ohne Cloud-Anbindung (Offline, Flugzeug, isoliertes Netz), Kosten-Null-Betrieb für Routine, Experimente mit großen Open-Weight-Modellen ohne Vendor-Lock. Plus: gezielte Spezialaufgaben über Ollama Cloud (Open-Weight 120B–671B-Modelle) für Tasks, die lokal nicht laufen würden.

**Constraint:**
- Nur Ollama-Provider — lokal (`localhost:11434`) und Cloud (`:cloud`-Suffix).
- **Hardware lokal:** M4 Pro 48 GB. Realistisch ca. 32 GB für Modelle, 16 GB für OS + Tools. Auf M1 Pro 32 GB entsprechend skalieren.
- Kein OpenAI/Anthropic-Vendor-Lock.
- Cloud-Modelle nur, wenn Daten US-zulässig sind. Für DSGVO-Daten: Profil 3 verwenden.

**Begründung der Modellwahl:**
- **Qwen3-Coder 480B (Ollama Cloud)** als Code-Default — Stand Mai 2026 stärkstes Open-Weight für agentisches Coding via Ollama Cloud, gut auf SWE-bench.
- **gpt-oss 120B (Ollama Cloud)** für Reasoning-Tasks (`plan`, `reviewer`, `security-auditor`) — solides Reasoning-Modell, kleiner Footprint als 480B, schnellere Antworten.
- **Qwen3-Coder 30B lokal** für Recon und Routine — läuft auf M4 Pro flüssig (ca. 18 GB), keine Cloud-Latenz.
- **Llama 3.2 3B** für `small_model` — sub-1-GB-Footprint, ideal für Trivial-Tasks.

| Agent | Modell | Begründung |
|---|---|---|
| `build` (primary) | `ollama/qwen3-coder:480b-cloud` | Bestes Open-Weight für Coding (Cloud, SWE-bench) |
| `plan` (primary) | `ollama/gpt-oss:120b-cloud` | Reasoning-stark, Open-Source, kleinerer Cloud-Spend als 480B |
| `reviewer` | `ollama/gpt-oss:120b-cloud` | Review profitiert von Reasoning |
| `researcher` | `ollama/qwen3-coder:30b` | Lokal, Read-only-Recon |
| `security-auditor` | `ollama/gpt-oss:120b-cloud` | Reasoning + Pattern-Erkennung |
| `small_model` | `ollama/llama3.2:3b` | Lokal, Title-Gen, OpenCode-intern |

> **Voraussetzung:** `ollama signin` ausgeführt, `OLLAMA_API_KEY` in `~/.zshrc` gesetzt. Lokale Modelle vorab via `ollama pull` ziehen.

Config-Datei: [`Profile-Configs/opencode-ollama.json`](./Profile-Configs/opencode-ollama.json).

---

## Vergleichstabelle: Modellwahl pro Agent über alle Profile

| Agent | Balanced | SOTA | DSGVO | Ollama |
|---|---|---|---|---|
| `build` | Sonnet 4.6 | Sonnet 4.6 | Bedrock Sonnet EU | qwen3-coder:480b-cloud |
| `plan` | Sonnet 4.6 | Opus 4.7 | Bedrock Opus EU | gpt-oss:120b-cloud |
| `reviewer` | Sonnet 4.6 | Opus 4.7 | Bedrock Opus EU | gpt-oss:120b-cloud |
| `researcher` | Haiku 4.5 | Sonnet 4.6 | Bedrock Sonnet EU | qwen3-coder:30b |
| `security-auditor` | Sonnet 4.6 | Opus 4.7 | Bedrock Opus EU | gpt-oss:120b-cloud |
| `small_model` | Haiku 4.5 | Haiku 4.5 | Llama 3.2 3B (lokal) | Llama 3.2 3B (lokal) |

---

## Profil-Wechsel im Alltag

```bash
oc           # Balanced — Standard
oc-sota      # Schwere Architektur, kritisches Debugging
oc-dsgvo     # Kundenprojekt mit EU-Pflicht
oc-ollama    # Offline / Open-Weight / Kosten-Null
```

Wechsel pro Session — Subagents erben das Modell aus dem aktuell geladenen Profil über das `agent.<name>.model`-Mapping.

---

## Offene Punkte / Folgeaktionen

Zentral gepflegt in [[OpenCode — Open Issues & TODOs]] (§B Modell-IDs/Endpoint, §C Azure-EU, §G Cost-Tracking & Ollama-Hardware-Tuning).

## Quellen

- [Claude on AWS Bedrock — EU Regions](https://platform.claude.com/docs/en/build-with-claude/claude-on-amazon-bedrock-legacy)
- [Claude in Microsoft Foundry — EU-Status](https://learn.microsoft.com/en-us/answers/questions/5867930/timeline-for-claude-in-microsoft-foundry-to-run-on)
- [Deploy Claude in Microsoft Foundry](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude)
- [Ollama Cloud Models Blog](https://ollama.com/blog/cloud-models)
- [Claude on AWS vs Azure vs GCP — GDPR Data Residency 2026](https://www.gerloff.dev/writing/claude-aws-azure-google-gdpr)
