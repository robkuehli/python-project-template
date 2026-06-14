---
title: "OpenCode — Open Issues & TODOs (zentral)"
tags:
  - opencode
  - tracking
Creation Date: 2026-05-21
Last Modified: 2026-05-21
status: current
---

# OpenCode — Open Issues & TODOs

Zentrale Sammelstelle für alle offenen Punkte rund um das OpenCode-Setup. Aus den Einzeldateien hierher überführt (2026-05-21), damit es **eine** Stelle gibt statt verstreuter `_todo`-Blöcke, `_dsgvo_checklist`s und „Offene Punkte"-Sektionen. Die Quelldateien verweisen jetzt hierher.

Status-Konvention: `[ ]` offen · `[x]` erledigt · 🔭 beobachten (extern, kein eigener Task) · ⛔ blockiert.

---

## A. Erledigt durch das Review/Refactoring (2026-05-21)

- [x] **Plugin-Hook PostWrite `ruff format`** — umgesetzt in [`Config-Files/plugin/learnings-and-guards.ts`](Config-Files/plugin/learnings-and-guards.ts) (`tool.execute.after`). War: `opencode.json._todo`.
- [x] **Plugin-Hook PreBash-Guard** (Belt-and-Suspenders zu `permissions.deny`) — umgesetzt im selben Plugin (`tool.execute.before`). War: `opencode.json._todo`.
- [x] **Halbautomatische Learning-Capture** — Inbox-Pattern: SessionEnd-Hook (Claude Code) + `session.idle`-Plugin (OpenCode) → `LEARNINGS.inbox.md`, Promote via `/capture review`. Siehe [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]] §6.
- [x] **Agent-Roster verschlankt** 11 → 5 (`build`, `plan`, `reviewer`, `researcher`, `security-auditor`). `planner`/`debugger`/`refactorer`/`docs-writer`/`test-generator`/`git-helper` entfernt.

---

## B. LiteLLM / Modell-Konfiguration (Firmen-abhängig)

- [ ] **EU-Modell-IDs verifizieren** — `bedrock-claude-*-eu` und `azure-gpt-*-eu` sind Platzhalter. Mit Firmen-LiteLLM-Maintainer abklären, dass die IDs den echten Aliassen entsprechen. *(Quelle: `opencode.json._todo`, `Profil-Spezifikationen` Offene Punkte, `Profile-Configs/README`.)*
- [ ] **`baseURL` ersetzen** — `https://litellm.internal.example.com/v1` in allen vier Profilen + `opencode.json` durch echten Firmen-Endpoint. *(Quelle: `Profile-Configs/README`.)*
- [ ] ⛔ **DSGVO-Profil nicht produktiv** verwenden, bis B-Punkte verifiziert sind. *(Quelle: `Profile-Configs/README`.)*
- [ ] **MCP-Block pro Agent ergänzen**, sobald Use-Cases konkret sind (Plan: Read-only DB, Build: github, Researcher: filesystem). *(Quelle: `opencode.json._todo`.)*
- [ ] **Provider-Block-Duplikation auflösen** — OpenCode hat kein `$extends`; der Provider-Block ist in 4 Profilen + `opencode.json` dupliziert. Sobald native Inheritance kommt, oder per `jq`-Template-Build-Schritt umstellen. *(Quelle: `Profile-Configs/README`.)*

## C. DSGVO-Checkliste (pro Kundenprojekt prüfen)

- [ ] Bedrock-Endpoint zeigt auf `eu-central-1` oder `eu-west-1` — mit LiteLLM-Maintainer verifizieren.
- [ ] Cross-Region-Inference auf US-Regionen explizit deaktiviert.
- [ ] Modell-IDs entsprechen Firmen-LiteLLM-Aliases (siehe B).
- [ ] Kunden-spezifische `AGENTS.md` im Projekt-Root mit Datenschutz-Hinweisen.
- [x] `permissions.webfetch` auf `ask` — bereits in allen Profilen konfiguriert.
- [ ] **Learning-Extraktion in DSGVO auf lokales Modell** zeigen (kein Transkript in die Cloud) — `CLAUDE_LEARNINGS_MODEL` bzw. OpenCode-`small_model` im DSGVO-Profil auf Ollama. *(Neu aus Review.)*
- [ ] 🔭 **Azure-Foundry-Claude-EU:** sobald GA, DSGVO-Profil überdenken (eventuell zweispurig Bedrock + Azure EU für Redundanz). *(Quelle: `Profil-Spezifikationen`.)*

## D. Externe OpenCode-Issues (beobachten)

- [ ] 🔭 **[#19344](https://github.com/anomalyco/opencode/issues/19344)** — kein agent-scoped Skill-Loading (alle Skill-Descriptions in jedem Agent-Kontext). Wenn gefixt: explizite Spawn-Anweisungen in Skill-Bodies entfernen, ggf. `skills:`-Frontmatter pro Agent nutzen.
- [ ] 🔭 **[#13188](https://github.com/anomalyco/opencode/issues/13188)** — Token-Kosten skalieren linear mit Skill-Anzahl. Wenn gefixt: Skill-Sammlung global erweitern. Bis dahin: Skill-Set bei 8 halten.
- [ ] 🔭 **[#15805](https://github.com/anomalyco/opencode/issues/15805)** — Skill-Body im Chat-Stream sichtbar. Bis dahin: Bodies kurz halten, Details in `references/`.
- [ ] 🔭 **#8832 / #16331** — `permissions` nicht 100% bulletproof. Belt-and-Suspenders: PreBash-Guard-Plugin (erledigt) + shell-seitige Guards (pre-commit, gitleaks). *(Quelle: `Best Practices`.)*

## E. Setup / Skills

- [ ] **Symlinks im echten Home einrichten** — `~/.claude/skills`, `~/.config/opencode/skills` → zentraler `Skills/`-Ordner. *(Quelle: Skills-MOC.)*
- [ ] **`.opencode/skills`-Anbindung** im Setup-Manual des autonomen Agenten ergänzen. *(Quelle: Skills-MOC.)*
- [ ] **Helper-Skills evaluieren** aus `anthropics/skills` (`skill-creator`, `claude-api`, ggf. `frontend-design`) — projekt-lokal symlinken, nicht global. *(Quelle: Skills-MOC.)*
- [ ] **`references/spec-template.md`** für das `/spec`-Skill noch schreiben. *(Quelle: `Skills/spec/SKILL.md`.)*
- [ ] **`status: draft` → `stable`** für die real bewährten Skills heben (Robins Urteil, welche). *(Neu aus Review.)*
- [ ] **Shell-Hooks ausführbar machen** beim Install: `chmod +x ~/.claude/hooks/*.sh`. *(Neu aus Review.)*

## F. Learning-Hook produktiv härten (neu, aus Review §10)

- [ ] **Claude-Code-`SessionEnd`-Payload** verifizieren — `transcript_path`, `cwd`, `reason` + Transkript-Format gegen die [Hooks-Reference](https://code.claude.com/docs/en/hooks) testen, bevor produktiv. Fallback `Stop`-Hook + Dedup falls SessionEnd unzuverlässig ([#34954](https://github.com/anthropics/claude-code/issues/34954)).
- [ ] **OpenCode-Plugin fertigstellen** — `session.idle`-Payload + `client`-API gegen [Docs](https://opencode.ai/docs/plugins/) verifizieren; Transkript-Abruf + Modell-Aufruf im `TODO(verify)` in [`plugin/learnings-and-guards.ts`](Config-Files/plugin/learnings-and-guards.ts) implementieren; Dedup einbauen.
- [ ] **Scribe-Extraktor-Prompt kalibrieren** — Bar empirisch so hoch, dass die Inbox nicht zumüllt.

## G. Modellwahl / Kosten

- [ ] **Cost-Tracking** — LiteLLM-Telemetrie pro Profil über ~4 Wochen sammeln, dann Modellwahl evidenz-basiert re-evaluieren. *(Quelle: `Profil-Spezifikationen`.)*
- [ ] **Ollama-Hardware-Tuning** — Quantisierungs-/Modell-Empfehlungen für M1 Pro 32 GB ergänzen (kleinere lokale Modelle). *(Quelle: `Profil-Spezifikationen`.)*

---

## Quelldateien (überführt)

| Datei | Was hierher kam |
|---|---|
| [`Config-Files/opencode.json`](Config-Files/opencode.json) | `_todo`-Block |
| [`Profile-Configs/opencode-dsgvo.json`](Profile-Configs/opencode-dsgvo.json) | `_dsgvo_checklist` |
| [`OpenCode — Profil-Spezifikationen`](OpenCode%20—%20Profil-Spezifikationen.md) | „Offene Punkte / Folgeaktionen" |
| [`OpenCode — Best Practices`](OpenCode%20—%20Best%20Practices.md) | „Offene Punkte" + Pain-Points-Issues |
| [`Profile-Configs/README`](Profile-Configs/README.md) | Platzhalter-/Inheritance-Hinweise |
| [[Docs/AI Driven Development/Skills/MOC - Agentic-SWE - Skills\|Skills-MOC]] | „Offen / zu verfeinern" |
