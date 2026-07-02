# Getting started

## Prerequisites

- **`uv`** on the PATH. The post-generation tasks (`uv sync`, `uv run
  pre-commit install`) need it; see
  [Astral's install guide](https://docs.astral.sh/uv/getting-started/installation/).
- **Unix-like shell** — macOS, Linux, or Windows with **WSL2 + Developer Mode**.
  One of the post-generation tasks rebuilds a `docs/skills` symlink via
  `ln -s`, which requires symlink support. Plain Windows (PowerShell / cmd
  without WSL2) is not supported.

## Install Copier

```bash
uv tool install copier
```

## Generate a new project

`--trust` is required so the post-generation tasks (`git init`, `uv sync`,
`uv run pre-commit install`, sandbox/SDD bootstrap) actually run.

**Variant A — from GitHub** (always uses the latest commit on `main`; pass
`--vcs-ref <tag-or-branch>` to pin):

```bash
copier copy --trust gh:robkuehli/python-project-template path/to/new-project
```

**Variant B — from a local clone** (when you've checked the template out
already and want to iterate on it before pushing):

```bash
# absolute path
copier copy --trust ~/Code-Projects/python-project-template \
            path/to/new-project

# or relative path
copier copy --trust ../python-project-template my-project
```

## Answer the prompts

Copier asks for project identity, which coding agents to wire up, backend per
tool, optional sandbox + SDD framework, SQL tooling, and license. Every prompt,
its choices, defaults, and conditional `when` rules are documented in the
**[Options reference](options.md)**. For ready-made combinations, see the
**[Example setups](examples.md)**.

With `--trust`, Copier finishes by running `git init`, `uv sync`, and installing
the git hooks, so the generated project is ready for `just qa` immediately.
