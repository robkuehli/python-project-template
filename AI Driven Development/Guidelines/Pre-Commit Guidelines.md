---
tags:
  - docnote
Creation Date: 2026-05-19
Last Modified: 2026-05-19
Finished: false
---

# Pre-Commit Guidelines

Verbindliche Regeln für die Validation-Pipeline in Projekten mit AI-Agenten. Python-fokussiert, Stack: **pre-commit + ruff + mypy + pytest**.

## Warum pre-commit überhaupt

AI-Agenten produzieren Code in Bursts. Ohne automatisches Gate kommen Bursts in den Commit, die das Repo verschmutzen: Formatierung springt zwischen Stilen, ungenutzter Code bleibt, Typ-Annotationen werden inkonsistent.

`pre-commit` löst das, indem jedes Commit eine objektive Hürde nimmt. Der Agent sieht das Gate, der Mensch sieht das Gate, beide lernen dieselben Regeln.

**Pflicht für jedes Projekt mit Agent-Workflow.** Ausnahme nur für Throwaway-Spikes (<1 Tag Lebensdauer).

## Grundprinzipien

1. **Schnell genug, um zu greifen.** Wenn `pre-commit run` mehr als 10 s pro Commit kostet, wird er umgangen. Schwere Sachen (vollständige Test-Suite) gehört in CI, nicht in pre-commit.
2. **Auto-Fix, wo möglich.** Formatter laufen mit `--fix`, sodass der Agent nicht im Loop über Format-Diffs stolpert.
3. **Failure ist informativ.** Hook-Output zeigt, was falsch ist und wie es zu reparieren ist. `Hook failed.` ohne Details ist ein kaputter Hook.
4. **Eine Quelle der Wahrheit.** `pyproject.toml` konfiguriert ruff, mypy, pytest, coverage. Keine `.flake8`/`.isort.cfg`/`mypy.ini`-Splitkonfig.

## Empfohlene Hook-Pipeline

In dieser Reihenfolge in `.pre-commit-config.yaml`:

### Phase 1: Strukturelle Sicherheit

```yaml
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v5.0.0
  hooks:
    - id: check-yaml
    - id: check-toml
    - id: check-json
    - id: check-added-large-files
      args: ["--maxkb=500"]
    - id: end-of-file-fixer
    - id: trailing-whitespace
    - id: mixed-line-ending
      args: ["--fix=lf"]
    - id: detect-private-key
- repo: https://github.com/gitleaks/gitleaks
  rev: v8.21.0
  hooks:
    - id: gitleaks
```

Diese Phase verhindert, dass irgendwas Strukturell-Kaputtes oder Geheimes überhaupt in einen Commit kommt. `gitleaks` ist Pflicht — Agenten kopieren manchmal `.env`-Snippets aus Examples in Tests.

### Phase 2: Lint + Format (Python)

```yaml
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.7.0
  hooks:
    - id: ruff           # Linter (mit --fix)
      args: ["--fix", "--exit-non-zero-on-fix"]
    - id: ruff-format    # Formatter
```

`ruff` ersetzt `black`, `isort`, `flake8`, `pyupgrade` und etliche weitere — eine Tool-Chain, ein Config-Block. `--exit-non-zero-on-fix` sorgt dafür, dass Auto-Fixes als Failure gewertet werden, damit sie als eigener Commit landen und im PR sichtbar sind.

### Phase 3: Typ-Check

```yaml
- repo: https://github.com/pre-commit/mirrors-mypy
  rev: v1.13.0
  hooks:
    - id: mypy
      additional_dependencies:
        - pydantic
        - types-requests
        - types-PyYAML
      args: ["--strict"]
```

`--strict` ist die Default-Empfehlung. Wo Strictness zu teuer ist (Legacy-Module), gezielt per `pyproject.toml` lockern, nicht global abschalten:

```toml
[[tool.mypy.overrides]]
module = "legacy.*"
ignore_errors = true
```

### Phase 4: Schnelle Tests (optional)

```yaml
- repo: local
  hooks:
    - id: pytest-quick
      name: pytest (quick)
      entry: pytest -x -m "not slow and not integration"
      language: system
      pass_filenames: false
      always_run: true
```

Nur die schnelle Unit-Test-Subset (`not slow and not integration`). Komplette Suite gehört in CI. Wer das nicht zur Verfügung hat (Solo-Projekt ohne CI), packt es trotzdem in den pre-commit, aber mit einem Time-Budget.

### Phase 5: Doc-Linting (optional aber empfohlen)

```yaml
- repo: https://github.com/econchick/interrogate
  rev: 1.7.0
  hooks:
    - id: interrogate
      args: ["--fail-under=80", "src/"]
```

Erzwingt Docstring-Coverage. Bremst Agenten, die Tests + Code schreiben, aber Doku „später" machen wollen.

## pyproject.toml: zentrale Konfiguration

Eine Datei, vier Tools. Beispiel-Block:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = [
    "E", "F", "W",           # pyflakes + pycodestyle
    "I",                     # isort
    "UP",                    # pyupgrade
    "B",                     # bugbear
    "C4",                    # comprehensions
    "RET",                   # returns
    "SIM",                   # simplify
    "ARG",                   # unused arguments
    "PTH",                   # pathlib over os.path
    "RUF",                   # ruff-specific
]
ignore = ["E501"]            # line-length via formatter
extend-select = ["D"]        # pydocstyle (siehe Docstring-Hook)

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.mypy]
python_version = "3.12"
strict = true
warn_unused_ignores = true
warn_redundant_casts = true
show_error_codes = true

[tool.pytest.ini_options]
minversion = "8.0"
addopts = ["-ra", "--strict-markers", "--strict-config"]
testpaths = ["tests"]
markers = [
    "slow: tests langsamer als 1 s",
    "integration: braucht externe Ressourcen",
]

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
fail_under = 80
exclude_lines = [
    "pragma: no cover",
    "raise NotImplementedError",
    "if TYPE_CHECKING:",
]
```

## Installation und Bootstrapping

```bash
# einmalig im Projekt
uv tool install pre-commit
pre-commit install                    # Git-Hook installieren
pre-commit install --hook-type commit-msg  # für conventional-commits, optional
pre-commit run --all-files            # initialer Sweep
```

Beim Klonen für neue Maintainer (oder einen frischen Agent-Sandbox):

```bash
make setup           # macht `pre-commit install` als Teil von setup
```

`Makefile`-Snippet:

```makefile
.PHONY: setup
setup:
	uv sync
	uv run pre-commit install
	uv run pre-commit install --hook-type commit-msg

.PHONY: check
check:
	uv run pre-commit run --all-files
	uv run pytest

.PHONY: fix
fix:
	uv run ruff check --fix .
	uv run ruff format .
```

`make check` ist das, was der Agent zum Verifizieren benutzt. `make fix` ist das, was der Agent läuft, wenn `check` rot ist.

## Agent-Integration

In `CLAUDE.md` / `AGENTS.md` einbinden:

```markdown
## Validation
- Vor jedem Commit `make check` ausführen
- Bei Failure: `make fix`, dann erneut `make check`
- Wenn `make check` nach 2 Fix-Runden noch rot ist: stoppen und Problem berichten
- Niemals Hooks mit `--no-verify` umgehen
```

Der Hook „niemals `--no-verify`" ist die einzige starre Regel — alles andere ist Auto-Fix-tauglich.

## CI-Spiegel

Pre-commit ist Local Gate. CI muss die gleichen Hooks plus die teuren Sachen:

```yaml
# .github/workflows/ci.yml (skizziert)
- run: uv run pre-commit run --all-files
- run: uv run pytest --cov=src --cov-fail-under=80
- run: uv run pytest -m integration
```

CI darf strenger sein als pre-commit (Coverage-Gate, vollständige Integration-Suite), aber **nie weniger streng**. Sonst entsteht Drift, in der CI Fehler findet, die pre-commit hätte fangen sollen.

## Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|---|---|---|
| `--no-verify` als Gewohnheit | Hook wird umgangen, Drift sammelt sich | Hook-Lauf so schnell machen, dass er nicht stört |
| Hook ohne Auto-Fix | Endlos-Loop „Hook failed, fix manually" | `--fix` und `--write` aktivieren |
| Inkonsistente Tool-Versionen | `ruff` lokal anders als in CI | `rev:` in `.pre-commit-config.yaml` pinnen, `pre-commit autoupdate` periodisch |
| `mypy` mit `ignore_errors` global | Strict-Mode wird gelogen | Per-Modul-Overrides, nie global |
| Pre-Commit als CI-Ersatz | Test-Suite läuft komplett im Hook | Schwere Sachen in CI |

## Maintenance

- **Monatlich** `pre-commit autoupdate` laufen lassen, Diff reviewen, committen
- **Bei Tool-Upgrades** in `pyproject.toml` immer beide Stellen (pre-commit-rev + Tool selbst) zusammen heben
- **Bei neuen Pattern-Mängeln** (Agent macht wiederholt denselben Fehler) erst prüfen, ob ein ruff-Rule existiert, sonst Lokal-Hook schreiben

## Querverweise

- `Testing Guidelines.md` — Test-Konfiguration im pyproject.toml
- `Documentation Guidelines.md` — Docstring-Coverage via `interrogate`
- `Changelog Guidelines.md` — optional conventional-commits-Hook
- `../CLI-Tools/Claude-Code/Claude Code — Best Practices.md` — Hooks im Claude-Code-Lifecycle (anderer Hook-Begriff, gleicher Geist)

## Offen / zu verfeinern

- [ ] Beispiel für custom local-Hook (z.B. SQL-Linter via `sqlfluff`)
- [ ] Pre-Push-Hooks vs. Pre-Commit-Hooks — Aufgabenverteilung
- [ ] Hook-Set für TypeScript/JavaScript-Repos als Schwester-Datei
