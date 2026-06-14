---
tags:
  - docnote
  - sdd
  - openspec
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# OpenSpec — Setup Manual

Stand: OpenSpec `@latest` von [Fission AI](https://github.com/Fission-AI/OpenSpec) (Mai 2026). Rolling-Release über npm, keine fixe Versions-Pin-Empfehlung.

## Voraussetzungen

| Komponente | Version | Anmerkung |
|---|---|---|
| Node.js | **20.19.0+** | Hartes Mindest-Requirement |
| npm | aktuell | Kommt mit Node |
| Git | aktuell | OpenSpec arbeitet branchbasiert |
| AI-Agent | Claude Code / OpenCode / Cursor / Copilot / Cline / Windsurf | Wird beim Init abgefragt |

Node-Version prüfen:

```bash
node --version  # muss >= v20.19.0 sein
```

Wenn nicht: über `nvm` upgraden:

```bash
nvm install 20
nvm use 20
```

## Installation

### Global (empfohlen)

```bash
npm install -g @fission-ai/openspec@latest
```

`openspec` ist danach systemweit verfügbar.

### Per-Project (ohne globale Installation)

```bash
npx @fission-ai/openspec@latest init
```

Funktioniert für einmaligen Setup, danach läuft alles über die `openspec/`-Artefakte und die Slash-Commands im Agent — die CLI wird nach dem Init kaum noch gebraucht.

### Spezifische Version pinnen

```bash
npm install -g @fission-ai/openspec@<version>
```

Versionen unter [npmjs.com/package/@fission-ai/openspec](https://www.npmjs.com/package/@fission-ai/openspec).

### Verifikation

```bash
openspec --version
openspec --help
```

## Projekt initialisieren

### Standard-Init (Greenfield + Brownfield identisch)

```bash
cd your-project
openspec init
```

Der Init-Prompt fragt ab:

1. **Welchen AI-Coding-Assistant nutzt du?** (Claude Code, Cursor, Copilot, Cline, Windsurf, …)
2. **Projekt-Typ**: Brownfield (Codebase vorhanden) oder Greenfield?

Bei Brownfield: OpenSpec ergänzt sinnvolle Defaults für Context-Acquisition (siehe Workflow).

### Brownfield mit Repomix-MCP für Context

Für tiefere Context-Acquisition auf bestehender Codebase wird **Repomix MCP** empfohlen ([intent-driven.dev, März 2026](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/)). Repomix indiziert die Codebase und macht sie für den Agent durchsuchbar — vor dem ersten `/opsx:propose`.

Setup separat (nicht Teil von OpenSpec):

```bash
# Repomix als MCP-Server in Claude Code registrieren
# Siehe Repomix-Docs für den genauen Setup
```

## Generierte Verzeichnisstruktur

Nach `openspec init`:

```
openspec/
├── AGENTS.md                    # Lightweight Constitution + Agent-Regeln
├── README.md                    # OpenSpec-Doku, vom Init generiert
├── project.md                   # Projekt-Kontext (Stack, Conventions)
├── specs/                       # Living Master-Specs (nach Archive-Phase)
│   └── (initial leer, füllt sich über Zeit)
└── changes/                     # Active changes, Delta-Specs
    └── (leer bis erster /opsx:propose)
```

Plus: Slash-Commands werden in `.claude/commands/` (oder Agent-spezifisches Äquivalent) installiert.

### Was diese Verzeichnisse bedeuten

- **`specs/`** — Die Master-Spezifikation des aktuellen Systems. Wird durch jeden Archive-Schritt fortgeschrieben. Ein Living Document.
- **`changes/`** — Aktive und noch nicht archivierte Vorschläge. Jeder Change ist ein eigenes Unterverzeichnis mit `proposal.md`, ggf. `design.md`, `tasks.md` und Delta-Specs.
- **`openspec/AGENTS.md`** — Lightweight Equivalent zur Spec-Kit-Constitution. Architektur-Prinzipien, die für alle Changes gelten.
- **`openspec/project.md`** — Stack, Conventions, projektweite Kontext-Infos für den Agent.

## Memory-Architektur

OpenSpec ist deutlich lightweight gehalten als Spec-Kit — es gibt keine separate `.specify/memory/`-Konstruktion.

| Datei | Verantwortlich für | Gelesen von |
|---|---|---|
| `openspec/AGENTS.md` | Architektur-Prinzipien, projektweite Leitplanken | OpenSpec-Workflow (alle Phasen) |
| `openspec/project.md` | Stack, Conventions, Kontext | OpenSpec-Workflow |
| `CLAUDE.md` (Repo-Root) | Agent-Verhalten, Custom Commands | Claude Code |
| `AGENTS.md` (Repo-Root) | Executor-Regeln, QA-Befehle | OpenCode, Codex, … |

**Wichtig**: Es gibt zwei `AGENTS.md`-Dateien — eine im Repo-Root (für alle Agents allgemein), eine in `openspec/` (OpenSpec-spezifisch). Nicht verwechseln.

### Ergänzung in `CLAUDE.md`

```markdown
## OpenSpec
Specs leben in `openspec/`. Bei OpenSpec-Workflow:
- `openspec/AGENTS.md` ist die projektweite Constitution. IMMER lesen vor `/opsx:propose`.
- `openspec/project.md` ist der Stack-Kontext.
- Active Changes unter `openspec/changes/<change-name>/`.
- Archived Specs unter `openspec/specs/`.

Slash-Commands:
- `/opsx:propose <change-name>`     — neuen Change vorschlagen
- `/opsx:apply`                     — Tasks implementieren
- `/opsx:archive`                   — Change in Master-Spec mergen
```

### Lightweight `openspec/AGENTS.md` Beispiel

```markdown
# Project Constitution (OpenSpec)

## Non-Negotiable Principles

1. **Test-First**: Akzeptanzkriterien werden vor Implementation in Tests übersetzt.
2. **Idempotency**: Alle Mutationen sind idempotent.
3. **Backward Compatibility**: API-Changes brauchen Deprecation-Periode (1 Minor-Version).

## Stack
- Python 3.12, Poetry, Pydantic v2
- PostgreSQL 16, dbt-core 1.9
- Pytest + Hypothesis
```

## Verifikation

```bash
openspec --version                  # CLI installed?
ls openspec/                        # Verzeichnis vorhanden?
cat openspec/AGENTS.md              # Constitution-Stub vorhanden?
ls .claude/commands/                # Slash-Commands installiert?
```

Smoke-Test in der Agent-Session:

```
/opsx:propose dummy-test-change
```

Sollte einen Change-Folder unter `openspec/changes/dummy-test-change/` anlegen. Wenn ja: Setup steht. Danach den Test-Change einfach löschen:

```bash
rm -rf openspec/changes/dummy-test-change
```

## Update

```bash
npm update -g @fission-ai/openspec
openspec --version
```

OpenSpec ist rolling — Breaking Changes werden im [GitHub-Repo](https://github.com/Fission-AI/OpenSpec) angekündigt, aber sind selten. Bei größeren Updates ein kurzer `git log` im Repo schadet nicht.

## Häufige Probleme

| Problem | Ursache | Lösung |
|---|---|---|
| `node: command not found` | Node nicht installiert | `nvm install 20 && nvm use 20` |
| `Node version < 20.19.0` | Alte Node-Version | `nvm install 20.19.0 && nvm use 20.19.0` |
| Slash-Commands fehlen im Agent | Falscher Agent beim Init gewählt | `openspec init` erneut ausführen |
| `openspec/AGENTS.md` wird ignoriert | Agent kennt OpenSpec nicht | `CLAUDE.md` mit OpenSpec-Verweis ergänzen (siehe oben) |
| Brownfield-Specs zu generisch | Fehlende Context-Acquisition | Repomix MCP für Code-Indexing einrichten |

## Bezug zu Robins Setup

- **OpenCode-Support**: OpenSpec generiert markdown-only Artefakte und ist agent-agnostisch. Wenn OpenCode beim `openspec init` nicht in der Liste auftaucht: einen unterstützten Agent wählen und die Slash-Commands manuell als OpenCode-Custom-Commands portieren (über `~/.opencode/commands/` oder das OpenCode-Äquivalent).
- **Brownfield-Default**: Für Robins typischen Use-Case (Iteration auf bestehender Pipeline) ist OpenSpec strukturell besser passend als Spec-Kit. Siehe [[SDD - Tool-Empfehlungen]].
- **Lightweight passt zur Pipeline-Arbeit**: Eine Schema-Migration oder dbt-Modell-Erweiterung ist selten ein 800-Zeilen-Spec-Wert. OpenSpec mit ~250 Zeilen Output passt besser.

## Workflow

Nach erfolgreichem Setup: weiter mit [[OpenSpec - Workflow]].

## Quellen

- [GitHub — Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
- [OpenSpec Getting Started (offiziell)](https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md)
- [OpenSpec Commands Reference (offiziell)](https://github.com/Fission-AI/OpenSpec/blob/main/docs/commands.md)
- [npm — @fission-ai/openspec](https://www.npmjs.com/package/@fission-ai/openspec)
- [openspec.dev — Landing](https://openspec.dev/)
- [intent-driven.dev — OpenSpec Knowledge](https://intent-driven.dev/knowledge/openspec/)
- [intent-driven.dev — Brownfield Strategy (März 2026)](https://intent-driven.dev/blog/2026/03/10/spec-driven-development-brownfield/)
- [Rushi — OpenSpec Introduction](https://www.rushis.com/introduction-to-openspec/)
