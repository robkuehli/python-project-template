# copier-python-template

A reusable [Copier](https://copier.readthedocs.io) template for standard Python
projects, wired up with **uv**, **just**, **pre-commit**, and **MkDocs**.

📖 **Full documentation:** <https://robkuehli.github.io/python-project-template/>

## What you get

Generating a project produces:

- **uv** for dependencies/environments, with `[dependency-groups]` (`dev`, `docs`)
  and a pinned `.python-version` (3.12 / 3.13).
- **just** task runner (`install`, `qa`, `lint`, `format`, `typecheck`, `test`,
  `cov`, `docs`, `update`, `clean`).
- **pre-commit** with the full hook set: pre-commit-hooks hygiene, Ruff
  (lint + format), Bandit, Gitleaks, and local mypy / pylint / sqlfluff / pytest.
- **MkDocs** (Material) with **mkdocstrings** API docs, organised along
  [Diátaxis](https://diataxis.fr/).
- **GitHub Actions**: `ci.yml` (uv + pre-commit + pytest) and `docs.yml`
  (MkDocs → GitHub Pages), plus **Dependabot**.
- Agent setup: a root **`AGENTS.md`** (read by Claude Code, Codex CLI, Aider and
  OpenCode), plus optional `.claude/`, `.opencode/` (+ `opencode.json`), and
  `.aider.conf.yml`. Backend per tool: subscription / LiteLLM gateway / Ollama.
- A **`guidelines/`** folder and a **`skills/`** folder with the 9 workflow
  skills (`/explore`, `/spec`, `/plan`, `/test`, `/delegate`, `/review`,
  `/verify`, `/debug`, `/capture`).
- An optional **Docker-Compose sandbox** (isolated container, optional SearXNG,
  Crawl4AI, MLflow/Langfuse observability).
- Project hygiene: `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `.editorconfig`, `.gitignore`, `py.typed`, `.env` + `.env.template`.

## Quickstart

Requires **`uv`** on the PATH and a **Unix-like shell** (macOS, Linux, or
WSL2 + Developer Mode). `--trust` lets the post-generation tasks (`git init`,
`uv sync`, `uv run pre-commit install`) run.

```bash
uv tool install copier
copier copy --trust gh:robkuehli/python-project-template path/to/new-project
```

See the docs for details:

- **[Getting started](https://robkuehli.github.io/python-project-template/getting-started/)**
  — prerequisites and generating a project.
- **[Options reference](https://robkuehli.github.io/python-project-template/options/)**
  — every prompt, choice, and default.
- **[Example setups](https://robkuehli.github.io/python-project-template/examples/)**
  — three concrete answer combinations.
- **[Updating projects](https://robkuehli.github.io/python-project-template/updating/)**
  — pulling template changes downstream.
- **[Developing the template](https://robkuehli.github.io/python-project-template/developing/)**
  — repo layout and the render smoketest.

## Documentation layout

This repo carries **two** doc sets, kept apart by the `_subdirectory: "template"`
boundary in `copier.yml`:

- `copier-python-template/docs/` — docs for the **template** (this README's site).
  Never copied into generated projects.
- `template/docs/` — the MkDocs site that ships **inside every generated
  project**, documenting that project's own workflow.

Rule of thumb when adding docs: *does it describe the template, or the product
built from it?*
