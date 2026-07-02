# python-project-template

A reusable [Copier](https://copier.readthedocs.io) template for standard Python
projects, wired up with **uv**, **just**, **pre-commit**, and **MkDocs**.

📖 **Full documentation:** <https://robkuehli.github.io/python-project-template/>

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

- `_dev/docs/` — docs for the **template** (this README's site).
  Never copied into generated projects.
- `template/docs/` — the MkDocs site that ships **inside every generated
  project**, documenting that project's own workflow.

Rule of thumb when adding docs: *does it describe the template, or the product
built from it?*

## What you get

For the full feature list see the **[docs home page](https://robkuehli.github.io/python-project-template/)**.
In short: **uv** + **just** + **pre-commit** (Ruff, Bandit, Gitleaks, mypy,
pylint, sqlfluff, pytest) + **MkDocs Material** with mkdocstrings, **GitHub
Actions** CI + Pages, **Dependabot**, an `AGENTS.md` plus optional `.claude/`,
`.opencode/`, `.aider.conf.yml` agent setups, a `guidelines/` and `skills/`
folder with the 9 workflow skills, an optional **Docker-Compose sandbox**, and
project hygiene files (CHANGELOG, CONTRIBUTING, CODE_OF_CONDUCT, .editorconfig,
.env + .env.template, py.typed).