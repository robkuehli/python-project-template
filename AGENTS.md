# AGENTS.md

Single source of truth for AI coding agents working on **python-project-template**
(the Copier template itself — not a project generated from it).

The governing design principles live in [`_dev/PRINCIPLES.md`](./_dev/PRINCIPLES.md).
Treat that file as the constitution: when a change conflicts with a principle,
the principle wins unless amended. The workflow and verification gates are in
[`_dev/CONTRIBUTE.md`](./_dev/CONTRIBUTE.md). This file covers the commands,
conventions, and guardrails an agent needs day-to-day.

## Setup & commands

There is no `pyproject.toml` at the repo root — the template itself has no
Python package. All work goes through `just` recipes in `_dev/justfile`:

- Render smoketest (the template's `just qa`): `just -f _dev/justfile render-test`
- Docs build (strict): `just -f _dev/justfile docs-build`
- Docs serve (live reload): `just -f _dev/justfile docs`
- Eyeball a real render: `copier copy --trust ../python-project-template /tmp/scratch`

Invoke from the repo root: `just --justfile _dev/justfile <recipe>`.

## Repo layout

```
python-project-template/           # git root = Copier entry point
├── copier.yml                      # prompts, tasks, exclude rules (_subdirectory: "template")
├── README.md                       # GitHub landing page (dev)
├── AGENTS.md                       # THIS file — agent guidance for template work
├── CLAUDE.md                       # redirects here (SPOT)
├── .gitignore
├── .github/workflows/docs.yml      # deploys the template docs to GitHub Pages
├── .claude/                        # agent config for template development
├── _dev/                           # all dev-only files (never copied into a generated project)
│   ├── PRINCIPLES.md               # design principles (the constitution)
│   ├── CONTRIBUTE.md               # workflow + verification gates
│   ├── CHANGELOG.md                # template changelog (Keep a Changelog)
│   ├── roadmap.md
│   ├── justfile                    # smoketests + docs recipes
│   ├── mkdocs.yml                  # config for the template docs site
│   └── docs/                       # the template docs site content
└── template/                       # ← everything here renders INTO a generated project
    ├── *.jinja                     #   Copier-rendered files
    ├── docs/                       #   the generated project's own docs site
    └── ...
```

The boundary is `_subdirectory: "template"` in `copier.yml`: **only files under
`template/` are rendered into a generated project.** Everything outside it
(`_dev/`, root `README.md`, `.github/`, `.claude/`, `copier.yml`, this file)
stays in the template repo. When adding docs, ask: *does it describe the
template, or the product built from it?* Template → `_dev/docs/`, product →
`template/docs/`.

## Conventions

- **Jinja files** end in `.jinja` (or `.jinja` embedded in a Copier conditional
  filename like `{% if 'codex' in coding_agents %}.codex{% endif %}/config.toml.jinja`).
  Conditional filenames render only when their guard is true.
- **SPOT** — behaviour rules for generated projects live in
  `template/AGENTS.md.jinja` and `template/agent-guidelines/*.md`. Tool-specific
  configs (`template/.claude/settings.json.jinja`,
  `template/opencode.json.jinja`, `template/.aider.conf.yml.jinja`,
  `template/.codex/config.toml.jinja`) carry only runtime glue. No rule in two
  places. A rule change is a one-file change.
- **Shared permission lists** (`shared_allow_bash`, `shared_deny_bash`,
  `shared_deny_read`, `shared_deny_write`, `shared_ask_bash`) live once in
  `copier.yml` with
  `when: false` and are injected into the render context so every tool config
  stays in lockstep. Edit them in `copier.yml`; do not duplicate per tool.
- **Docs follow Diátaxis** — see `template/agent-guidelines/documentation.md` for the
  generated-project standard; the template's own docs (`_dev/docs/`) follow the
  same split.

## How to work

- **Ask before acting** when info is missing, the request is ambiguous, scope
  is unclear, or a design decision (schema, API, structure, prompt change) is
  involved. Bundle questions; never silently assume. Trivial, unambiguous
  tasks: just do it.
- **Do exactly what was asked** — no uninvited features, refactors, or
  "while I'm here" changes. For large changes, propose a plan and wait for
  approval (see `_dev/CONTRIBUTE.md` workflow).
- **Respect the principles** (`_dev/PRINCIPLES.md`). If a request would violate
  a principle (e.g. adding a "nice to have" prompt violates Pareto, duplicating
  a rule violates SPOT), flag it and cite the principle before proceeding.
- **Plan → Execute → Verify** — plan non-trivial work first; execute with a
  small diff; verify with the render smoketest + docs-build. Verification is
  the highest-value step; skipping it turns the loop into guessing.
- **Living documentation** — a behaviour change without a doc/changelog entry
  in the same commit fails review. Update `_dev/CHANGELOG.md` under
  `[Unreleased]` and the relevant docs page in the same diff.

## Verification

A change is only done when:

1. `just -f _dev/justfile render-test` passes (eight scenarios render clean,
   JSON/TOML/YAML validate, Compose profiles resolve).
2. `just -f _dev/justfile docs-build` passes (strict MkDocs build of
   `_dev/`).
3. `_dev/CHANGELOG.md` has an entry under `[Unreleased]` describing the change.
4. Affected docs (`_dev/docs/options.md` for prompt changes, `template/docs/`
   for rendered-project behaviour) are updated in the same commit.

## Guardrails

- Never commit secrets — `.env` is git-ignored; tool configs reference env
  vars, never tokens.
- **Don't edit your own guardrails** unless the user asked for that specific
  change. Files that define what agents may do (`AGENTS.md`, `CLAUDE.md`,
  `_dev/PRINCIPLES.md`, `copier.yml` shared_* lists, `.claude/settings.json`)
  are off-limits for uninvited edits.
- **MCP servers are supply chain** — any new MCP surface (Context7, custom
  servers) requires a deny-rule or guard review before it ships (OWASP ASI04).
- Update `_dev/CHANGELOG.md` (Keep a Changelog, newest first, dated) in the
  same change that alters behaviour.
- MUST ask before deleting files or making irreversible changes.
- MUST NOT touch files outside the task's scope without flagging it.
- A change is only done when the render smoketest + docs-build pass.

## Git

- Work on a feature branch — never commit directly to `main`.
- Atomic commits, one logical change each, clear message.
- Propose a PR description when the branch is done.
