# Contributing to python-project-template

This file is the single source of truth for working **on the template itself** —
not on a project generated from it. Generated projects have their own
`CONTRIBUTING.md` (see `template/CONTRIBUTING.md.jinja`).

## Read first

- [`PRINCIPLES.md`](PRINCIPLES.md) — the governing design rules. Every change
  to the template must be consistent with these; if a change would violate a
  principle, the principle wins unless amended.
- [`CHANGELOG.md`](CHANGELOG.md) — every notable change gets an entry under
  `[Unreleased]` in the same commit that introduces the change.
- [`docs/developing.md`](docs/developing.md) — repo layout, render smoketest,
  iterating locally.

## Workflow

1. **Plan** non-trivial changes first — name the principle that justifies the
   change, the files touched, and the risk. Get approval before editing.
2. **Execute** with small, atomic diffs. One logical change per commit.
3. **Verify** before committing:
   - `just -f _dev/justfile render-test` — five Copier scenarios render clean,
     JSON/TOML/YAML validate, Compose profiles resolve. This is the
     template's `just qa` equivalent.
   - `just -f _dev/justfile docs-build` — strict MkDocs build of the template
     docs site (`_dev/`).
   - Eyeball a real render: `copier copy --trust ../python-project-template
     /tmp/scratch` and inspect the output.
4. **Changelog** — add a `Keep a Changelog` entry under `[Unreleased]`
   describing the change (Added / Changed / Removed / Fixed). Drift between
   code and changelog fails review.
5. **Docs** — if the change affects a Copier prompt, a tool config, or the
   rendered project's behaviour, update `_dev/docs/options.md` (for prompts)
   and/or the relevant `template/docs/` page (for rendered-project behaviour)
   in the same commit.

## Principles that bind every change

- **Pareto over completeness** — a new prompt, hook, file, or guideline must
  justify its existence against a concrete recurring need. "Nice to have" is
  a rejection reason.
- **KISS** — one profile, one default model per tool, one quality gate. If a
  setting can be inlined to a sensible default, it is.
- **SPOT** — behaviour rules live in `AGENTS.md` and `agent-guidelines/*.md`; tool
  configs (`.claude/settings.json`, `opencode.json`, `.aider.conf.yml`,
  `.codex/config.toml`) carry only runtime glue. No rule in two places.
- **Quality gates non-negotiable** — `--no-verify` is the hardest line. If a
  hook is too slow, fix the hook.
- **Security by default** — any new credential surface (provider, hook, MCP
  server) requires the matching deny-rule or guard before it ships.
- **Living documentation** — a behaviour change without a doc/changelog entry
  in the same commit fails review.

## Render smoketest

The render smoketest is the template's verification gate — run it before every
commit that touches `copier.yml`, any `*.jinja` file, or `_dev/justfile`:

```bash
just -f _dev/justfile render-test
```

Five scenarios (see `_dev/justfile` comments for details):

1. Claude-Code-only, no sandbox (minimal path).
2. Full stack with Langfuse v3 + Crawl4AI (exercises every profile-gated `:?`
   guard).
3. Full stack with MLflow (the other Compose Jinja branch).
4. All four agents + Context7 + Python 3.14 (Codex config, granular OpenCode
   permissions, Context7-conditional, 3.14 tooling pins).
5. Codex (LiteLLM) + OpenCode (hybrid) + Context7=false + Python 3.12
   (Codex-LiteLLM AGENTS.md text, OpenCode hybrid model block, Context7
   else-branch, 3.12 tooling pins).

The test runs with `--defaults`, so a shift in `copier.yml` defaults moves the
covered scope with it instead of silently going stale.

## Git

- Work on a feature branch — never commit directly to `main`.
- Atomic commits, one logical change each, clear message.
- Propose a PR description when the branch is done.