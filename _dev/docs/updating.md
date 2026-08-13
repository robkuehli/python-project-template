# Updating projects

When the template improves, pull the changes into an existing generated project.
This is run from inside the *generated* project, not the template repo.

```bash
cd path/to/new-project
copier update --trust --skip-answered --skip-tasks   # or: just update
```

Copier re-applies the template against the answers recorded in
`.copier-answers.yml`, shows you a diff, and leaves any conflicts as merge
markers. Review the diff, resolve conflicts, then commit.

## Project-owned and template-owned files

Copier updates deliberately leave actively maintained project content outside
the merge:

- `CHANGELOG.md`
- `README.md`
- `docs/index.md`
- everything under `src/` and `tests/`

The template creates these files once as useful starters. After generation they
belong entirely to the project: updates neither overwrite them nor recreate
ones the project deleted. Configuration, CI, agent guidance, shared skills, and
template reference/how-to documentation remain template-owned and continue to
receive updates.

Post-generation tasks also run only during the initial `copier copy`. The
generated `just update` includes `--skip-tasks` so upgrades from older template
revisions cannot execute their historical task definitions; current task
definitions also reject Copier's internal quiet update renders. An update does
not rerun dependency installation, hook installation, sandbox secret bootstrap,
symlink setup, or Spec-Kit initialization. Run the relevant project recipe or
documented migration command explicitly when an update requires it.

## Re-answering a prompt

`--skip-answered` keeps your previous answers. Drop that flag while retaining
`--skip-tasks` to be re-prompted for everything, or re-run a single decision by
editing `.copier-answers.yml` and running `just update`.

## Changing the Python version

The version is pinned in several coordinated places, so the cleanest path is to
let Copier re-apply it consistently:

```bash
just update        # re-answer the "Python version" prompt
```

If you change it by hand instead, update all of: `.python-version`,
`requires-python` and `target-version` in `pyproject.toml`, `[tool.mypy]`
`python_version`, `[tool.pylint.main]` `py-version`, and
`default_language_version` in `.pre-commit-config.yaml`.

## Changing the license

Re-run `just update` and re-answer the `license` prompt, or edit the `[project]`
license field and classifiers in `pyproject.toml` by hand. See the
[license option](options.md#license) for what each choice emits.
