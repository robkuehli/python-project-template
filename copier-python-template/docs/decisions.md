# Decisions

Notable design choices baked into the template. For the broader philosophy, see
[`PRINCIPLES.md`](https://github.com/robkuehli/python-project-template/blob/main/PRINCIPLES.md)
in the repo root.

- **Python version is consistent everywhere.** The chosen version is pinned in
  lockstep across pre-commit `default_language_version`, `.python-version`,
  mypy/ruff/pylint targets, and CI. The choice list is deliberately limited to
  releases the linter stack fully supports.
- **Agent permission lists are a single source of truth.** `shared_deny_bash`,
  `shared_deny_read`, `shared_deny_write`, and `shared_ask_bash` live once in
  `copier.yml` and are injected into every tool config, so `.claude/settings.json`
  and `opencode.json` can never drift apart.
- **License defaults to Proprietary.** No `LICENSE` file is written and a
  `Private :: Do Not Upload` classifier blocks an accidental PyPI upload. Opt
  into MIT/Apache-2.0 explicitly.
- **sqlfluff requires a dialect.** It is set in `pyproject.toml` (`ansi` by
  default). If the project has no SQL, answer "no" to `include_sql` to drop the
  hook entirely.
- **Ruff and pylint overlap by design.** Duplicate rules are disabled in pylint
  to keep the output quiet rather than dropping either tool.
- **The sandbox favours a small default footprint.** MLflow (one container) is
  the default observability service; Langfuse v3 (six containers) is opt-in for
  when LLM cost/trace dashboards are actually needed.
