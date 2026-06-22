# Updating projects

When the template improves, pull the changes into an existing generated project.
This is run from inside the *generated* project, not the template repo.

```bash
cd path/to/new-project
copier update --trust --skip-answered   # or, equivalently: just update
```

Copier re-applies the template against the answers recorded in
`.copier-answers.yml`, shows you a diff, and leaves any conflicts as merge
markers. Review the diff, resolve conflicts, then commit.

## Re-answering a prompt

`--skip-answered` keeps your previous answers. Drop it (`copier update --trust`)
to be re-prompted for everything, or re-run a single decision by editing
`.copier-answers.yml` and running `just update`.

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
