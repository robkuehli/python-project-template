# copier-python-template

A reusable [Copier](https://copier.readthedocs.io) template for standard Python
projects, wired up with **uv**, **just**, **pre-commit**, and **MkDocs**.

## What you get

Generating a project produces:

- **uv** for dependencies/environments, with `[dependency-groups]` (`dev`, `docs`)
  and a `.python-version` (default 3.13; 3.12–3.15 selectable).
- **just** task runner (`install`, `qa`, `lint`, `format`, `typecheck`, `test`,
  `cov`, `docs`, `update`, `clean`).
- **pre-commit** with the full hook set: pre-commit-hooks hygiene, Ruff
  (lint + format), Bandit, Gitleaks, and local mypy / pylint / sqlfluff / pytest.
  All tool configs live in `pyproject.toml`, which the hooks read.
- **MkDocs** (Material) with **mkdocstrings** API docs and a changelog page.
  Content is split along [Diátaxis](https://diataxis.fr/): an *explanation*
  page (the tools and how just/Copier fit together) and a *how-to* page
  (using the template), alongside the API *reference*.
- **GitHub Actions**: `ci.yml` (uv + pre-commit + pytest) and `docs.yml`
  (MkDocs → GitHub Pages), plus **Dependabot**.
- Agent setup: a root **`AGENTS.md`** (read by Claude Code and Codex CLI),
  optional `.claude/`, `.opencode/` (+ `opencode.json`), and Copilot files.
- A **`guidelines/`** folder (changelog / testing / documentation standards) and
  a **`skills/`** folder using the `SKILL.md` format.
- Project hygiene: `CHANGELOG.md` (Keep a Changelog), `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `.editorconfig`, `.gitignore`, `py.typed`, `.env` + `.env.template`.

## Usage

```bash
uv tool install copier
# generate (use --trust to also run git init + uv sync + pre-commit install)
copier copy --trust gh:your-username/copier-python-template path/to/new-project
```

Answer the prompts (project name, package name, author, Python version, which
coding agents, whether to include SQL tooling, license).

## Updating downstream projects

When you improve this template, pull the changes into a generated project:

```bash
cd path/to/new-project
copier update --trust --skip-answered   # or: just update
```

## Notes & decisions

- **Python version** is consistent everywhere (pre-commit
  `default_language_version`, `.python-version`, mypy/ruff/pylint targets, CI).
- **sqlfluff** requires a `dialect`; it is set in `pyproject.toml`
  (`ansi` by default). If you don't use SQL, answer "no" to `include_sql`.
- **License** defaults to `Proprietary` (no LICENSE file is written, and a
  `Private :: Do Not Upload` classifier is added). Choose MIT/Apache-2.0 to
  emit an SPDX license field.
- Ruff and pylint overlap by design; duplicate rules are disabled in pylint to
  keep the output quiet.
