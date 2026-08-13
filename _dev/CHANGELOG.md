# Changelog

All notable changes to **`python-project-template`** are documented here.

Format: [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

Scope: this file tracks the **template itself** — the Copier scaffold, its
questions, hooks, and the rendered files. Generated downstream projects keep
their own `CHANGELOG.md` (see `template/CHANGELOG.md.jinja`).

## [Unreleased]

### Added

- **Multi-agent Spec-Kit projects** for selected Claude Code, Codex, and Pi
  integrations. `sdd_install_agent` now chooses the default integration while
  the other selected, multi-install-safe integrations are installed alongside
  it. Mixed OpenCode installs remain an explicit manual `--force` opt-in.

- **Opt-in global sandbox instructions** via
  `just sandbox-enable-user-instructions`. The helper displays detected
  standard Claude/Codex user instruction sources, asks for confirmation, and
  creates a git-ignored Compose override with only those sources mounted
  read-only. It prefers Codex `AGENTS.override.md`, never merges into repository
  guidance, never mounts complete agent configuration directories, and refuses
  to overwrite an existing override.

- **Template repository CI** now runs the canonical eight-scenario render
  smoketest and strict template documentation build on every push and pull
  request, with read-only repository permissions and cancellation of stale runs.

- **Pi Coding Agent support** as a fifth `coding_agents` choice. Pi uses the
  shared root `AGENTS.md` and the same canonical workflow skills exposed through
  `.agents/skills`; the sandbox installs the official Pi package with npm
  lifecycle scripts disabled. Spec-Kit's `pi` integration is selectable.

- **Optional CI/CD** via new Copier prompt `cicd_provider` (default
  `github_actions`, so existing renders are unchanged). Three choices:
  `github_actions` (the previous always-on `.github/workflows/ci.yml`,
  `docs.yml`, `dependabot.yml`), `gitlab_ci` (a new commented
  `.gitlab-ci.yml` baseline that runs `just qa` and strict `just docs-build`),
  or `none` (no CI files). Packaging, image publishing, and deployment remain
  project-specific because the generic template cannot infer a delivery target.
  The GitHub Actions files plus
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

- Project-authored `CHANGELOG.md`, `README.md`, `docs/index.md`, `src/**`, and
  `tests/**` are now rendered once and excluded from Copier updates. Generation
  tasks are copy-only, so updates no longer rerun environment, hook, sandbox,
  symlink, or Spec-Kit bootstrap steps.
- Added Copier validators for project/package identity, human-readable
  single-line fields, email, GitHub owner, backend URLs, model aliases, and SQL
  dialects. Free-text values are context-quoted in TOML/YAML/JSON/Python output,
  and the render gate now proves both invalid-input rejection and quoted-value
  round trips.
- Amended Quality Principle IV to version 1.2.1: `just qa` remains the single
  gate, with static checks in Pre-Commit and tests executed once as its final
  step. GitHub and GitLab CI now invoke that canonical command, Ruff 0.16.2 is
  synchronized between the project environment and its immutable hook commit,
  and stale five-scenario/CI wording was corrected.
- Tightened agent permissions around a shared Bash allowlist. Claude Code and
  OpenCode now auto-allow only canonical quality/read-only commands; WebFetch,
  dependency/tool installation, Git mutations, Docker/sandbox operations,
  external-directory access, and unknown shell commands require approval.
  Secret-path coverage and protected persistent-context surfaces now include
  common cloud/package credential files, `agent-guidelines/`, `skills/`, the
  Spec-Kit constitution, and `uv.lock`.
- Sandbox secret handling now defaults to no plaintext `.env` generation and
  documents 1Password `op://…` references resolved via `op run`. The project
  `.env` is masked inside the container so Bash cannot bypass agent read-denies,
  while a clearly documented `agent-home` volume persists CLI logins across
  ephemeral shells and is destroyed by `sandbox-nuke`.
- Hardened executable supply-chain inputs: GitHub Actions and Pre-Commit hooks
  are commit-pinned, automated installs use exact package versions, Spec-Kit is
  fixed to a reviewed commit, sandbox and CI base images use manifest digests,
  service images use digests, and CI dependency syncs enforce `uv.lock` with
  `--frozen`. The Dockerfile no longer executes remote `curl | shell`
  installers; it copies Node from a pinned build stage and installs uv/just
  through pinned Python packages. Claude's statusline now renders its pinned
  ccusage version instead of leaking an unresolved Copier expression.
- Corrected Codex CLI integration against current official configuration:
  GPT-5.6 is the project default; `default_permissions` no longer conflicts
  with `sandbox_mode`; custom subagents use the required schema and native
  auto-discovery; the Stop hook emits valid JSON and avoids recursive blocking;
  repository skills are exposed through `.agents/skills`; and LiteLLM routing
  is provided as a user-scoped Codex profile because project config cannot
  override providers or credentials.
- Replaced inaccurate cross-agent "feature parity" claims with explicit
  capability documentation and synchronized CI/CD, agent, Python-version, and
  render-scenario docs with the actual template behavior.
- Spec-Kit bootstrap now installs integration assets even when the selected
  agent executable is not yet installed on the generation host; the render
  gate verifies Pi's generated prompts and Spec-Kit metadata.
- Renamed `guidelines/` → `agent-guidelines/` in all generated projects: the
  top-level directory (`template/guidelines/` → `template/agent-guidelines/`),
  the MkDocs stub directory (`template/docs/guidelines/` →
  `template/docs/agent-guidelines/`), the nav section header (`Guidelines` →
  `Agent Guidelines`), and all path references across AGENTS.md.jinja, skills,
  explanation docs, tool configs (`.aider.conf.yml.jinja`, `opencode.json.jinja`),
  and this repo's own `AGENTS.md`, `README.md`, and `_dev/` docs.

### Removed

- Removed OpenSpec from the SDD prompt, generation task, sandbox image, examples,
  and rendered documentation. Spec-Kit remains the single optional SDD
  framework, avoiding OpenSpec's second project-wide `AGENTS.md` source. The SDD
  prompt is skipped for Aider-only projects because Spec-Kit has no Aider
  integration.

### Fixed

- Prevented `copier update` from replacing maintained project changelog and
  product content with template starter files or recreating intentionally
  deleted source/test files.
- Made the render smoketest stage a generated project and execute its real
  `just qa` and strict `just docs-build` gates, eliminating the previous
  Pre-Commit false pass on an untracked fresh render. Copier now preserves final
  newlines in Jinja output, the machine-owned `.copier-answers.yml` is excluded
  from EOF rewriting, the skills overview is rendered as Jinja, and stale
  template-doc navigation entries were removed.

## [1.0.0] - 2026-06-03

### Added

- Docs: new "Context compression (optional)" explanation page covering
  Headroom and similar proxies — what they do, when they help, the risks
  (credential surface, SPOT/guardrail edits, tool-config collisions), and a
  self-install sketch. Not wired into the template: no Copier prompt, no
  generated config, no hook. Opt-in documentation only, per Pareto and
  Security-by-default.
