# copier-python-template

A reusable [Copier](https://copier.readthedocs.io) template for standard Python
projects, wired up with **uv**, **just**, **pre-commit**, and **MkDocs**.

!!! info "Two doc sites, two audiences"
    **This site** documents the *template* — how to generate a project from it,
    what every prompt does, and how to develop the template itself. The docs that
    ship *inside* a generated project (the day-to-day developer workflow, tools,
    skills, API reference) live in that project's own MkDocs site.

## What you get

Generating a project produces:

- **uv** for dependencies/environments, with `[dependency-groups]` (`dev`, `docs`)
  and a `.python-version` (default 3.13; 3.12–3.13 selectable — bump when
  Ruff/mypy/pylint catch up to newer target-version flags).
- **just** task runner (`install`, `qa`, `lint`, `format`, `typecheck`, `test`,
  `cov`, `docs`, `update`, `clean`).
- **pre-commit** with the full hook set: pre-commit-hooks hygiene, Ruff
  (lint + format), Bandit, Gitleaks, and local mypy / pylint / sqlfluff / pytest.
  All tool configs live in `pyproject.toml`, which the hooks read.
- **MkDocs** (Material) with **mkdocstrings** API docs and a changelog page.
  Content is split along [Diátaxis](https://diataxis.fr/).
- **GitHub Actions**: `ci.yml` (uv + pre-commit + pytest) and `docs.yml`
  (MkDocs → GitHub Pages), plus **Dependabot**.
- Agent setup: a root **`AGENTS.md`** (read by Claude Code, Codex CLI, Aider and
  OpenCode), plus optional `.claude/`, `.opencode/` (+ `opencode.json`), and
  `.aider.conf.yml`. Backend per tool: subscription / LiteLLM gateway / Ollama.
- A **`guidelines/`** folder (testing / documentation / changelog standards) and
  a **`skills/`** folder with the 9 workflow skills (`/explore`, `/spec`, `/plan`,
  `/test`, `/delegate`, `/review`, `/verify`, `/debug`, `/capture`) in
  `SKILL.md` format.
- An optional **Docker-Compose sandbox** that bind-mounts the repo into an
  isolated container so agents can't reach host secrets, with optional SearXNG,
  Crawl4AI, and LLM observability (MLflow / Langfuse).
- Project hygiene: `CHANGELOG.md` (Keep a Changelog), `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `.editorconfig`, `.gitignore`, `py.typed`,
  `.env` + `.env.template`.

## Where to go next

- **[Getting started](getting-started.md)** — prerequisites and generating your
  first project.
- **[Options reference](options.md)** — every Copier prompt, its choices, and
  defaults.
- **[Example setups](examples.md)** — three concrete answer combinations.
- **[Updating projects](updating.md)** — pulling template changes into an
  existing project.
- **[Developing the template](developing.md)** — repo layout and the render
  smoketest.
- **[Decisions](decisions.md)** — notable design choices.
