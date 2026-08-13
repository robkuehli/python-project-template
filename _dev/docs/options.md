# Options reference

Every Copier prompt defined in `copier.yml`, in the order it is asked. Prompts
marked **conditional** only appear when their `when` rule holds — Copier skips
them otherwise. This page is the single place that documents prompt behaviour;
the [Getting started](getting-started.md) and [Example setups](examples.md)
pages link here rather than repeating it.

## Project identity

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `project_name` | str | — | Human-readable name, e.g. *My Awesome Project*. |
| `project_slug` | str | derived from `project_name` | Repo / directory name (kebab-case). |
| `package_name` | str | derived from `project_slug` | Importable package (snake_case). |
| `project_description` | str | *A standard Python project.* | One-line description. |
| `author_name` | str | *Your Name* | Maintainer name. |
| `author_email` | str | *you@example.com* | Maintainer email. |
| `github_username` | str | *your-username* | Used for URLs. |
| `python_version` | choice | `3.13` | `3.12` / `3.13` / `3.14`. 3.14 is stable since Oct 2025 and supported by Ruff 0.15, mypy 2.1, and Pylint 4.x. Bump the template when a newer release lands and the linter stack catches up. |

## AI coding agents

`coding_agents` is a **multi-select**; `AGENTS.md` is always created regardless
of the choice. Each selected agent unlocks a backend prompt.

| Prompt | Type | Default | Choices / notes |
| --- | --- | --- | --- |
| `coding_agents` | multiselect | `claude_code`, `codex` | Claude Code (`.claude/`, `CLAUDE.md`), Codex CLI (`.codex/`), Pi (`AGENTS.md` + `.agents/skills`), OpenCode (`.opencode/` + `opencode.json`), Aider (`.aider.conf.yml`). |
| `claude_provider` | choice | `litellm` | **conditional** (`claude_code` selected). LiteLLM gateway / Claude subscription. |
| `codex_provider` | choice | `subscription` | **conditional** (`codex` selected). ChatGPT subscription / LiteLLM gateway. |
| `aider_provider` | choice | `litellm` | **conditional** (`aider` selected). LiteLLM gateway / Ollama. |
| `aider_model` | str | `claude-sonnet-5`, or `ollama/qwen3-coder:30b` on Ollama | **conditional** (`aider` selected). Default model alias. |
| `ollama_subscription` | bool | `false` | **conditional** (`opencode` selected). Whether you ran `ollama signin`; required for Cloud/Hybrid tiers. |
| `ollama_tier` | choice | `hybrid` if subscribed, else forced `local` | **conditional** (`opencode` + `ollama_subscription`). Hybrid / Cloud / Local. |
| `include_context7` | bool | `false` | **conditional** (any of Claude Code, Codex, OpenCode selected). Enable the Context7 MCP server — fetches current library docs into the model context. Opt-in: requires Node on PATH; queries leave the sandbox; adds a supply-chain factor (OWASP ASI04). Pi and Aider have no built-in MCP support. |
| `litellm_base_url` | str | `https://litellm.internal.example.com` | **conditional** (any tool uses the gateway). Token lives in your shell, never committed. |
| `ollama_base_url` | str | `http://localhost:11434` | **conditional** (OpenCode, or Aider on Ollama). |

## Sandbox (Docker-Compose)

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `include_sandbox` | bool | `false` | Generate the isolated container sandbox (repo bind-mounted, host secrets unreachable). |
| `sandbox_observability` | choice | `mlflow` | **conditional** (`include_sandbox`). MLflow (single container) / Langfuse (LLM-native, v3 = 6 containers) / None. |
| `include_crawl4ai` | bool | `false` | **conditional** (`include_sandbox`). Playwright + Chromium sidecar for JS-rendered fetches (~1.4 GB image). |
| `sandbox_auto_init` | bool | `false` | **conditional** (`include_sandbox`). Secure default: do not write plaintext secrets. Prefer `op://…` 1Password references in `.env` plus `op run --env-file=.env -- just sandbox-up`; opt in only when local random plaintext values are acceptable. |

## CI/CD

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `cicd_provider` | choice | `github_actions` | **GitHub Actions**: `.github/workflows/ci.yml` runs canonical `just qa`, `docs.yml` builds strictly and deploys to GitHub Pages, plus `dependabot.yml`. **GitLab CI**: `.gitlab-ci.yml` runs canonical `just qa` and strict `just docs-build`; packaging and deployment stay project-specific. **None**: no CI/CD files. |

## Spec-Driven Development

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `sdd_framework` | choice | `none` | **conditional** (Claude Code, Codex, Pi, or OpenCode selected). None (informal `/spec`) / Spec-Kit (structured, intent-driven, uv). Aider has no Spec-Kit integration. |
| `sdd_install_agent` | choice | first enabled agent (claude > codex > pi > opencode) | **conditional** (`sdd_framework != none`). Which agent gets the Spec-Kit integration. |

## Tooling extras

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `include_sql` | bool | `true` | sqlfluff pre-commit hook + config. |
| `sql_dialect` | str | `ansi` | **conditional** (`include_sql`). e.g. `postgres`, `snowflake`, `bigquery`. |
| `license` | choice | `Proprietary` | Proprietary / MIT / Apache-2.0 — see below. |

Identity values are validated before rendering: repository slugs must be
lowercase kebab-case, package names must be non-keyword Python identifiers,
names/descriptions must be non-empty single lines, email and GitHub owner fields
must match their expected shape, and backend URLs accept only single-line
`http(s)` values without template/quoting characters. Structured outputs then
serialize free text with Jinja's JSON-compatible quoting.

## License

The `license` prompt drives `pyproject.toml`:

- **Proprietary** (default) — no `LICENSE` file is written and a
  `Private :: Do Not Upload` classifier is added, so an accidental
  `uv publish` / `twine upload` to PyPI is rejected. Use this for closed projects.
- **MIT** / **Apache-2.0** — emits the matching SPDX license field; add the
  corresponding `LICENSE` file yourself.

Changing it later means re-running `just update` and re-answering the prompt, or
editing the `[project]` license field and classifiers by hand.

## Hidden computed inputs

`copier.yml` also defines `tool_versions`, `shared_allow_bash`,
`shared_deny_bash`, `shared_deny_read`, `shared_deny_write`, and
`shared_ask_bash` with `when: false`. These are **not** prompted: the first map
pins executable tooling, while the permission lists are injected into
`.claude/settings.json` and `opencode.json` so both stay in lockstep. Edit the
canonical values in `copier.yml`; do not duplicate them per tool.
