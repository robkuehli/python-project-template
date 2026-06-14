---
tags:
  - docnote
  - sdd
  - spec-kit
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# Spec-Kit — Setup Manual

Stand: Spec-Kit `v0.8.11` (Mai 2026). Sieht aus, als hätte sich an der grundlegenden Setup-Mechanik seit `v0.8.x` (März 2026, Plugin-Architektur-Migration) nichts geändert. Bei Update-Bedarf [Releases-Page](https://github.com/github/spec-kit/releases) prüfen.

## Voraussetzungen

| Komponente | Version | Anmerkung |
|---|---|---|
| Python | 3.11+ | Für `uv` als Runtime |
| Git | aktuell | Spec-Kit erstellt Feature-Branches automatisch |
| [`uv`](https://docs.astral.sh/uv/) | latest | Astral's Package-Manager, **empfohlene Install-Methode** |
| AI-Agent | Claude Code / OpenCode / Copilot / Cursor / Codex / Gemini CLI / … | 30+ Agents unterstützt |

`uv` installieren (falls noch nicht vorhanden):

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## Installation

### Persistent (empfohlen)

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

`specify` ist danach systemweit verfügbar.

### Spezifische Version pinnen

```bash
uv tool install specify-cli --force \
  --from git+https://github.com/github/spec-kit.git@v0.8.11
```

Vorgehen bei Update: `--force` notwendig, sonst nimmt `uv` die bestehende Installation. Siehe [Upgrade Guide](https://github.com/github/spec-kit/blob/main/docs/upgrade.md).

### Einmalig (ohne globale Installation)

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <projektname>
```

### Environment-Check

```bash
specify check
specify version
```

`specify check` validiert Python-Version, `uv`-Verfügbarkeit, Git-Setup. `specify version` zeigt installierte CLI-Version (sinnvoll wenn man später schaut, was auf dem PATH liegt).

## Projekt initialisieren

### Greenfield (neues Projekt)

```bash
specify init my-rag-pipeline --ai claude
cd my-rag-pipeline
```

`--ai` wählt den AI-Agenten, für den die Slash-Commands installiert werden. Optionen relevant für Robins Stack:

```bash
--ai claude         # Claude Code
--ai opencode       # OpenCode (zum Migrationszeitpunkt prüfen, ob unterstützt)
--ai copilot        # GitHub Copilot
--ai codex          # Codex CLI
--ai cursor         # Cursor
--ai gemini         # Gemini CLI
```

Vollständige Agent-Liste: [Spec-Kit Installation Guide](https://github.github.com/spec-kit/installation.html).

### Brownfield (bestehendes Repo)

```bash
cd existing-data-pipeline
specify init . --here --ai claude --force
```

`--here` injiziert das `.specify/`-Verzeichnis ins aktuelle Repo. `--force` ist nötig, wenn bereits Dateien vorhanden sind. Für Robins typischen Pipeline-Brownfield-Fall ist **OpenSpec** oft die bessere Wahl — siehe [[SDD - Tool-Empfehlungen]].

## Generierte Verzeichnisstruktur

Nach `specify init`:

```
.specify/
├── memory/
│   └── constitution.md          # Projekt-Grundgesetz, nicht-verhandelbare Prinzipien
├── scripts/
│   ├── check-prerequisites.sh   # Environment-Validierung
│   ├── common.sh                # Wiederverwendbare Logik
│   └── update-claude-md.sh      # Context-Synchronisierung für den Agent
├── specs/                       # Feature-Specs landen hier
│   └── 001-feature-name/
│       ├── spec.md              # Was & Warum (technologie-agnostisch)
│       ├── plan.md              # Technische Architektur (Wie)
│       ├── research.md          # Validierung von Libs, Versionen, APIs
│       ├── data-model.md        # Datenstrukturen und Contracts
│       └── tasks.md             # Atomare TDD-Roadmap mit [P]-Markern
└── templates/                   # Standardisierte Markdown-Vorlagen
```

Plus: Slash-Commands werden in `.claude/commands/` (oder dem Agent-spezifischen Äquivalent) installiert.

## Memory-Architektur

Mit Spec-Kit kommt eine dritte Wissensquelle ins Spiel — neben `CLAUDE.md` / `AGENTS.md`:

| Datei | Verantwortlich für | Gelesen von |
|---|---|---|
| `.specify/memory/constitution.md` | Architektur-Prinzipien, Tech-Stack-Entscheidungen, nicht-verhandelbare Regeln | Spec-Kit-Workflow (alle Phasen) |
| `CLAUDE.md` | Agent-Verhalten, Commands, Style | Claude Code |
| `AGENTS.md` | Executor-Regeln, QA-Befehle | OpenCode, Codex, Copilot, … |

### Ergänzung in `CLAUDE.md`

```markdown
## Project Constitution
Die architektonischen Leitplanken sind in `.specify/memory/constitution.md` definiert.
Alle Planungs- und Implementierungsentscheidungen MÜSSEN gegen die Constitution
geprüft werden.

## Spec-Kit Artefakte
Wenn ein Task einen Spec-Verweis enthält:
- Lies IMMER zuerst `.specify/specs/<feature>/spec.md`, dann `plan.md`, dann `tasks.md`.
- Bei Widersprüchen gilt: Constitution > Spec > Plan > Tasks > Code.
- Tasks mit [P] Marker dürfen parallelisiert werden.
```

### Ergänzung in `AGENTS.md`

```markdown
## Spec-Kit Kontext
- Spec-Kit-Artefakte unter `.specify/specs/<feature>/` sind Single Source of Truth.
- Arbeite Tasks aus `tasks.md` in der vorgegebenen Reihenfolge ab.
- Tasks mit [P] dürfen parallel laufen.
- Prüfe deine Arbeit gegen `.specify/memory/constitution.md`.
- Bei Widersprüchen zwischen Task Brief und Spec gilt die Spec.
```

## Verifikation

Nach Setup:

```bash
specify check                                  # Environment-Validierung
ls .specify/                                   # Verzeichnis vorhanden?
cat .specify/memory/constitution.md            # Constitution-Stub vorhanden?
ls .claude/commands/ 2>/dev/null || \          # Slash-Commands installiert?
  ls .codex/commands/                          # (Agent-abhängiger Pfad)
```

Smoke-Test in der Claude-Code-Session:

```
/speckit.constitution
```

Sollte einen Dialog zur Constitution-Definition starten. Wenn ja: Setup steht.

## Update

```bash
uv tool install specify-cli --force \
  --from git+https://github.com/github/spec-kit.git
specify version
```

Bei größeren Versionssprüngen die [CHANGELOG](https://github.com/github/spec-kit/blob/main/CHANGELOG.md) auf Breaking Changes prüfen. In der `0.8.x`-Linie gab es bisher keine Breaking Changes außerhalb des SemVer-Versprechens.

## Häufige Probleme

| Problem | Ursache | Lösung |
|---|---|---|
| `command not found: uv` | `uv` nicht installiert | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `specify init` schreibt nicht in bestehendes Verzeichnis | `--here` fehlt | `specify init . --here --force` |
| Slash-Commands fehlen in Claude Code | Falscher `--ai` Flag bei init | `specify init . --here --ai claude --force` re-init |
| Constitution wird ignoriert | `CLAUDE.md` referenziert sie nicht | Constitution-Verweis in `CLAUDE.md` ergänzen (siehe oben) |
| `specify check` failed | Python < 3.11 | Python 3.11+ über `pyenv` oder `uv python install 3.11` |

## Bezug zu Robins Setup

- **OpenCode-Support**: Spec-Kit ist Agent-agnostisch — die generierten Markdown-Artefakte funktionieren mit jedem Agent. Falls `--ai opencode` zum Init-Zeitpunkt nicht in der offiziellen Liste auftaucht, einfach `--ai claude` nutzen und in OpenCode die Slash-Commands manuell registrieren oder über die Artefakte arbeiten.
- **Sub-Agents für Review**: Der `/speckit.analyze`-Quality-Gate ersetzt nicht das Pattern "Review durch separaten Agent". Beide kombinieren, siehe [[SDD - Best Practices]] §5.

## Workflow

Nach erfolgreichem Setup: weiter mit [[Spec-Kit - Workflow]].

## Quellen

- [GitHub — github/spec-kit](https://github.com/github/spec-kit)
- [Spec-Kit Installation Guide (offiziell)](https://github.github.com/spec-kit/installation.html)
- [Spec-Kit Upgrade Guide](https://github.com/github/spec-kit/blob/main/docs/upgrade.md)
- [Spec-Kit v0.8.11 Release](https://github.com/github/spec-kit/releases/tag/v0.8.11)
- [Spec-Kit CHANGELOG](https://github.com/github/spec-kit/blob/main/CHANGELOG.md)
- [specify CLI Reference (DeepWiki)](https://deepwiki.com/github/spec-kit/4-specify-cli-reference)
