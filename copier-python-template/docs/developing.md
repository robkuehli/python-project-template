# Developing the template

How to work on the template itself — not on a generated project.

## Repo layout

```text
python-project-template/          # git root
├── justfile                      # template smoketests + docs recipes
├── PRINCIPLES.md                 # design principles
├── .github/workflows/docs.yml    # deploys THIS site to GitHub Pages
└── copier-python-template/
    ├── copier.yml                # prompts, tasks, exclude rules
    ├── README.md                 # GitHub landing page
    ├── mkdocs.yml                # config for THIS site (the template's docs)
    ├── docs/                     # THIS site's content (template-product docs)
    └── template/                 # ← everything here renders INTO a generated project
        ├── mkdocs.yml.jinja      #   the generated project's own docs site
        ├── docs/                 #   the generated project's docs content
        └── ...
```

The boundary that keeps the two doc sets apart is `_subdirectory: "template"` in
`copier.yml`: **only files under `template/` are rendered into a generated
project.** Anything outside it — including this `docs/` tree — stays in the
template repo and is never copied out. When you add documentation, the question
is simply *"does it describe the template, or the product built from it?"*:
template → `copier-python-template/docs/`, product → `template/docs/`.

## Render smoketest

`just render-test` (from the git root) generates three representative scenarios
into `/tmp`, then validates the rendered JSON configs and Docker-Compose files:

```bash
just render-test
```

- **Test 1** — Claude-Code-only, no sandbox (minimal path).
- **Test 2** — full stack with Langfuse v3 + Crawl4AI (exercises every
  profile-gated `:?` guard).
- **Test 3** — full stack with MLflow (the other Compose Jinja branch).

The test runs with `--defaults`, so a shift in `copier.yml` defaults moves the
covered scope with it instead of silently going stale.

## Iterating locally

Generate from your working copy (Variant B) to eyeball a real render before
pushing:

```bash
copier copy --trust ../python-project-template/copier-python-template /tmp/scratch
```

## Building this docs site

From the git root:

```bash
just docs          # serve locally with live reload (http://127.0.0.1:8000)
just docs-build    # strict build into copier-python-template/site/
```

Pushing to `main` triggers `.github/workflows/docs.yml`, which runs
`mkdocs gh-deploy --strict` and publishes this site to GitHub Pages. (The
generated project ships its *own* `docs.yml` workflow that deploys *its* site —
the two never collide because they live in different repos.)
