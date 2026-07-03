# Changelog

All notable changes to **`python-project-template`** are documented here.

Format: [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

Scope: this file tracks the **template itself** — the Copier scaffold, its
questions, hooks, and the rendered files. Generated downstream projects keep
their own `CHANGELOG.md` (see `template/CHANGELOG.md.jinja`).

## [1.0.0] - 2026-06-03

### Added

- Docs: new "Context compression (optional)" explanation page covering
  Headroom and similar proxies — what they do, when they help, the risks
  (credential surface, SPOT/guardrail edits, tool-config collisions), and a
  self-install sketch. Not wired into the template: no Copier prompt, no
  generated config, no hook. Opt-in documentation only, per Pareto and
  Security-by-default.
