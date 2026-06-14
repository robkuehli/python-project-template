---
title: "OpenCode — Übersicht"
last_verified: 2026-05-20
status: current
tags:
  - opencode
  - cli-tools
  - index
---

# OpenCode

Dieser Ordner beschreibt meine produktive OpenCode-Nutzung — vom Setup über die Profile bis zum täglichen Workflow.

OpenCode ist ein Open-Source CLI-Coding-Agent, der **Provider-agnostisch** mit Claude, GPT, Open-Weight-Modellen via LiteLLM, AWS Bedrock, Azure AI Foundry und Ollama (lokal + Cloud) arbeitet. Eine zentrale Stärke ist die **Per-Agent-Modell-Wahl** und das **Profil-Konzept** über mehrere `opencode.json`-Files.

## Inhaltsverzeichnis

1. [[OpenCode — Setup-Manual]] — Installation, Auth, Provider-Setup, Skill-Symlinks, Validierung
2. [[OpenCode — Best Practices]] — Pattern, Pitfalls, Workarounds, Sicherheit
3. [Config-Files/](./Config-Files/) — Globale Defaults: `AGENTS.md`, `LEARNINGS.md`, `opencode.json`
4. [[OpenCode — Profil-Spezifikationen]] — Anwendungsfall, Constraint, Modell pro Sub-Agent für alle vier Profile
5. [Profile-Configs/](./Profile-Configs/) — Eine `opencode.json` pro Profil (Balanced, SOTA, DSGVO, Ollama)
6. [Agents/](./Agents/) — Markdown-Agent-Definitionen, getrennt nach `Primary/` und `Subagents/`
7. [[OpenCode — Täglicher Workflow]] — Daily Routine: Session-Start, Profil-Wechsel, Verifikation, Wissens-Capture
8. [[OpenCode — Open Issues & TODOs]] — **zentrale** Sammelstelle aller offenen Punkte (Modell-IDs, DSGVO, Issues, Setup, Learning-Hook)

## Profile auf einen Blick

| Profil | Anwendungsfall | Default-Modell | Provider |
|---|---|---|---|
| **Balanced** | Standard-Arbeitstag, kostenbewusst | Claude Sonnet 4.6 | LiteLLM (Claude + Azure GPT) |
| **SOTA** | Komplexe Architektur, schwieriges Debugging | Claude Opus 4.7 | LiteLLM (Frontier) |
| **DSGVO** | Kundenprojekte mit EU-Datenschutz | Bedrock Claude Sonnet EU | LiteLLM → Bedrock EU + Azure EU + lokales Ollama |
| **Ollama** | Lokal/Cloud Open-Weight, Offline-fähig | qwen3-coder:480b:cloud | Ollama (lokal + Cloud) |

Aktivierung im Alltag über Shell-Aliase (`oc`, `oc-sota`, `oc-dsgvo`, `oc-ollama`).

## Beziehung zu anderen Ordnern

- **`../Claude-Code/`** — Pendant für Anthropic Claude Code. Strukturell parallel aufgebaut.
- **`../../Skills/`** — Cross-Tool-Skill-Sammlung, via Symlink in `~/.config/opencode/skills/` eingebunden.
- **`../../Guidelines/`** — Stack-unabhängige Engineering-Regeln, referenziert aus `Config-Files/AGENTS.md`.
- **`../../Autonomer Coding Agent/`** — Lokaler Coding-Daemon, eskaliert bei Bedarf auf OpenCode-Sessions.
