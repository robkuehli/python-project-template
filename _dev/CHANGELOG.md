# Changelog

All notable changes to **`python-project-template`** are documented here.

Format: [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

Scope: this file tracks the **template itself** — the Copier scaffold, its
questions, hooks, and the rendered files. Generated downstream projects keep
their own `CHANGELOG.md` (see `template/CHANGELOG.md.jinja`).

## [Unreleased]

### Added

- **Optional CI/CD** via new Copier prompt `cicd_provider` (default
  `github_actions`, so existing renders are unchanged). Three choices:
  `github_actions` (the previous always-on `.github/workflows/ci.yml`,
  `docs.yml`, `dependabot.yml`), `gitlab_ci` (a new commented
  `.gitlab-ci.yml` baseline with `lint → test → build → push → deploy`
  stages), or `none` (no CI files). The GitLab pipeline gates
  `build`/`push`/`deploy` on protected refs (`$CI_COMMIT_REF_PROTECTED`),
  tags every image with the immutable commit SHA as a rollback anchor, and
  keeps `deploy` manual. The GitHub Actions files plus
  `pull_request_template.md` now render only for `github_actions` (conditional
  filenames); `dependabot.yml` and `pull_request_template.md` gained a
  `.jinja` suffix to support that. `shared_deny_write` and `AGENTS.md`'s
  guardrail list are now CI-provider-aware.

- ADR support (`include_adrs: bool, default: false`): `/create-adr` skill
  (`template/skills/{% if include_adrs %}create-adr{% endif %}/SKILL.md`),
  ADR template (`template/docs/{% if include_adrs %}templates{% endif %}/adr-template.md`),
  empty `docs/adr/` directory, and two agent-guidelines files
  (`template/agent-guidelines/adr-guidelines.md`,
  `template/agent-guidelines/repo-adr-conventions.md.jinja`). The conventions file
  injects `author_name` as the default ADR owner. All ADR files are gated behind
  `include_adrs`; a proactive `/create-adr` hint is injected into `AGENTS.md` when
  enabled.

### Changed

- Renamed `guidelines/` → `agent-guidelines/` in all generated projects: the
  top-level directory (`template/guidelines/` → `template/agent-guidelines/`),
  the MkDocs stub directory (`template/docs/guidelines/` →
  `template/docs/agent-guidelines/`), the nav section header (`Guidelines` →
  `Agent Guidelines`), and all path references across AGENTS.md.jinja, skills,
  explanation docs, tool configs (`.aider.conf.yml.jinja`, `opencode.json.jinja`),
  and this repo's own `AGENTS.md`, `README.md`, and `_dev/` docs.

## [1.0.0] - 2026-06-03

### Added

- Docs: new "Context compression (optional)" explanation page covering
  Headroom and similar proxies — what they do, when they help, the risks
  (credential surface, SPOT/guardrail edits, tool-config collisions), and a
  self-install sketch. Not wired into the template: no Copier prompt, no
  generated config, no hook. Opt-in documentation only, per Pareto and
  Security-by-default.
