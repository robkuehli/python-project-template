# AIDD Template Principles

The governing principles for this Python project template (`python-project-template`)
and every project generated from it. Short, prescriptive, **load-bearing** —
every line earns its place.

For the *what* (tools, configs, commands), see
[`README.md`](../README.md) and
[`docs/reference/tools.md`](../template/docs/reference/tools.md.jinja)
in a generated project. This file is about the **why**.

> Note: This template is **not** developed with Spec-Driven Development.
> "Principles" here are the template's own design rules — not an SDD
> Spec-Kit `constitution.md`. Generated projects that opt into Spec-Kit get
> their own, separate `.specify/memory/constitution.md`.

---

## Mission

Give a developer one command (`copier copy`) and 60 seconds of prompts to get
a Python project that is:

- **Productive** with or without an AI coding agent — same commands, same gates,
  same conventions.
- **Backend-agnostic** across Claude Code, Codex CLI, Aider and OpenCode, with
  pluggable LiteLLM / subscription / Ollama backends per tool.
- **Safe to delegate** — secrets, quality gates and review hooks are wired up
  before the first agent prompt is typed.

The template is **finished** when a fresh generation needs no manual edits to
pass `just qa` and run an agent against the chosen backend.

---

## Core Principles

### I. Pareto over completeness (NON-NEGOTIABLE)

Ship the 20 % of config that handles 80 % of projects. The remaining 20 % of
projects fine-tune in their own repo — never in the template.

**Implication:** A new question, hook, file, or guideline must justify its
existence against a *concrete recurring need*. "Nice to have" is a rejection
reason, not a feature request.

### II. KISS over cleverness (NON-NEGOTIABLE)

One profile. One default model per tool. One quality gate (`just qa`). One
source of truth per fact. Toggling between three personas of the same tool is
banned by design.

**Implication:** If a setting can be inlined to a sensible default, it is.
If a Copier question can be skipped by inferring from another answer, it is.

### III. Single Source of Truth (SPOT)

Behaviour rules for AI agents live exclusively in **`AGENTS.md`** and
**`agent-guidelines/*.md`**. Tool-specific files (`.claude/settings.json`,
`opencode.json`, `.aider.conf.yml`, `CLAUDE.md`) carry only the glue that
each runtime needs — backend URL, model alias, hook wiring.

**Implication:** No rule is written in two places. `CLAUDE.md` redirects to
`AGENTS.md`. Codex, Aider and OpenCode load `AGENTS.md` natively or by config
reference. A rule change is a one-file change.

### IV. Quality gates are non-negotiable

A change is only done when `just qa` (lint + typecheck + test) passes. The
gate runs locally via `pre-commit`, and CI mirrors it exactly. CI may be
stricter (full integration suite, coverage floor) — **never weaker**.

**Implication:** `--no-verify` is the single hardest line in the
template. If a hook is too slow to keep, fix the hook, don't skip it.

### V. Security by default

Secrets never live in the repo: `gitleaks` and `detect-private-key` are
mandatory pre-commit hooks, `.env` is git-ignored, and `.env.template` only
documents shape — never values. Tool configs reference env vars; they never
contain tokens.

**Implication:** Adding any new credential surface (a new provider, a new
hook, a new MCP server) requires adding the matching deny-rule or guard
before the surface ships.

### VI. Workflow is a toolkit, not a process

The nine skills (`/explore`, `/spec`, `/plan`, `/test`, `/delegate`,
`/review`, `/verify`, `/debug`, `/capture`) are independent verbs. Pick what
the task needs; skip what it doesn't. Three orthogonal axes — Skills (what),
Modes (where), Subagents (how) — and only the first two are active mental load.

**Implication:** The template ships these skills as `SKILL.md` files but
prescribes no order. `Plan → Execute → Verify` is the only enforced sequence,
and Verify is the highest-value step — `/verify` is its own skill because a
review without evidence is a guess.

### VII. Living documentation

Docs follow [Diátaxis](https://diataxis.fr/): one document, one mode.
Documentation travels in the same commit as the code it describes — drift
cannot form if there is no gap. Reference is generated (`mkdocstrings`),
not hand-maintained.

**Implication:** A behaviour change without a doc/changelog entry in the same
commit fails review.

---

## Quality Standards

These are the minimum gates every generated project ships with:

- **Linting + formatting** — `ruff` (line length 100, Google docstrings)
- **Typing** — `mypy --strict`
- **Deeper linting** — `pylint` fail-under 9
- **Security** — `bandit` + `gitleaks` + `detect-private-key`
- **Tests** — `pytest`, interface-centric (see `agent-guidelines/testing.md`)
- **Docs** — `MkDocs` Material + `mkdocstrings`, Diátaxis layout
- **Changelog** — Keep a Changelog 1.1.0 + SemVer 2.0.0

Each gate is wired in `pre-commit` and surfaced through `just`.

---

## Governance

These principles supersede any conflicting rule in `AGENTS.md`,
`agent-guidelines/`, or skill files. When in doubt, the principles win.

**Amendments** to this file require:

1. A concrete failure or recurring friction that the current principles fail
   to prevent.
2. A proposed edit that adds, modifies, or removes **at most one principle**
   per amendment.
3. A bump of the version line below, with the date, and a `CHANGELOG.md` entry.

**Scope:** These principles govern the template itself. Generated projects
inherit them by reference — they may add project-specific guidelines under
`agent-guidelines/`, but they may not relax a principle without amending the
template upstream.

**Version**: 1.1.0 | **Ratified**: 2026-06-14 | **Last Amended**: 2026-06-18
