# Developing the template

How to work on the template itself — not on a generated project.

## Repo layout

```text
python-project-template/           # git root = Copier entry point
├── copier.yml                      # prompts, tasks, exclude rules (_subdirectory: "template")
├── README.md                       # GitHub landing page (dev)
├── .gitignore                      # dev gitignore
├── .github/workflows/docs.yml      # deploys THIS site to GitHub Pages
├── .claude/                        # agent config for the template development
├── _dev/                           # all dev-only files (never copied into a generated project)
│   ├── CHANGELOG.md                # template-eigener Changelog
│   ├── PRINCIPLES.md               # design principles
│   ├── roadmap.md
│   ├── TODO.md
│   ├── justfile                    # smoketests + docs recipes (invoke: `just -f _dev/justfile ...`)
│   ├── mkdocs.yml                  # config for THIS site (the template's docs)
│   └── docs/                       # THIS site's content (template-product docs)
└── template/                       # ← everything here renders INTO a generated project
    ├── mkdocs.yml.jinja            #   the generated project's own docs site
    ├── docs/                       #   the generated project's docs content
    ├── CHANGELOG.md.jinja          #   the generated project's changelog stub
    └── ...
```

The boundary that keeps the two doc sets apart is `_subdirectory: "template"` in
`copier.yml`: **only files under `template/` are rendered into a generated
project.** Anything outside it — including `_dev/docs/`, the root `README.md`,
`.github/`, `.claude/`, and `copier.yml` itself — stays in the template repo
and is never copied out. When you add documentation, the question is simply
*"does it describe the template, or the product built from it?"*:
template → `_dev/docs/`, product → `template/docs/`.

## Render smoketest

`render-test` generates three representative scenarios into `/tmp`, then
validates the rendered JSON configs and Docker-Compose files:

```bash
just -f _dev/justfile render-test
```

The four scenarios (see the justfile comments for full details):

- **Test 1** — Claude-Code-only, no sandbox (minimal path).
- **Test 2** — full stack with Langfuse v3 + Crawl4AI (exercises every
  profile-gated `:?` guard).
- **Test 3** — full stack with MLflow (the other Compose Jinja branch).
- **Test 4** — all four agents + Context7 + Python 3.14 (covers Codex
  `config.toml`, granular OpenCode permissions, Context7-conditional blocks,
  and 3.14 tooling pins).
- **Test 5** — Codex (LiteLLM) + OpenCode (hybrid) + Context7=false + Python
  3.12 (covers Codex-LiteLLM AGENTS.md text, OpenCode hybrid model block,
  Context7 else-branch, and 3.12 tooling pins; no sandbox → fast).

The test runs with `--defaults`, so a shift in `copier.yml` defaults moves the
covered scope with it instead of silently going stale.

## Iterating locally

Generate from your working copy (Variant B) to eyeball a real render before
pushing:

```bash
copier copy --trust ../python-project-template /tmp/scratch
```

## Building this docs site

From the git root:

```bash
just -f _dev/justfile docs          # serve locally with live reload (http://127.0.0.1:8000)
just -f _dev/justfile docs-build    # strict build into _dev/site/
```

Pushing to `main` triggers `.github/workflows/docs.yml`, which runs
`mkdocs gh-deploy --strict` and publishes this site to GitHub Pages. (The
generated project ships its *own* `docs.yml` workflow that deploys *its* site —
the two never collide because they live in different repos.)