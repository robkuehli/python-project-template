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
| `coding_agents` | multiselect | `claude_code`, `codex` | Claude Code (`.claude/`, `CLAUDE.md`), Codex CLI (AGENTS.md only), OpenCode (`.opencode/` + `opencode.json`), Aider (`.aider.conf.yml`). |
| `claude_provider` | choice | `litellm` | **conditional** (`claude_code` selected). LiteLLM gateway / Claude subscription. |
| `codex_provider` | choice | `subscription` | **conditional** (`codex` selected). ChatGPT subscription / LiteLLM gateway. |
| `aider_provider` | choice | `litellm` | **conditional** (`aider` selected). LiteLLM gateway / Ollama. |
| `aider_model` | str | `claude-sonnet-5`, or `ollama/qwen3-coder:30b` on Ollama | **conditional** (`aider` selected). Default model alias. |
| `ollama_subscription` | bool | `false` | **conditional** (`opencode` selected). Whether you ran `ollama signin`; required for Cloud/Hybrid tiers. |
| `ollama_tier` | choice | `hybrid` if subscribed, else forced `local` | **conditional** (`opencode` + `ollama_subscription`). Hybrid / Cloud / Local. |
| `include_context7` | bool | `false` | **conditional** (any of Claude Code, Codex, OpenCode selected). Enable the Context7 MCP server — fetches current library docs into the model context (solves stale-training-data for Python libs). Opt-in: requires Node on PATH; queries leave the sandbox (external service `mcp.context7.com`); adds a supply-chain factor (OWASP ASI04). Not available for Aider (no MCP support). |
| `litellm_base_url` | str | `https://litellm.internal.example.com` | **conditional** (any tool uses the gateway). Token lives in your shell, never committed. |
| `ollama_base_url` | str | `http://localhost:11434` | **conditional** (OpenCode, or Aider on Ollama). |

## Sandbox (Docker-Compose)

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `include_sandbox` | bool | `false` | Generate the isolated container sandbox (repo bind-mounted, host secrets unreachable). |
| `sandbox_observability` | choice | `mlflow` | **conditional** (`include_sandbox`). MLflow (single container) / Langfuse (LLM-native, v3 = 6 containers) / None. |
| `include_crawl4ai` | bool | `false` | **conditional** (`include_sandbox`). Playwright + Chromium sidecar for JS-rendered fetches (~1.4 GB image). |
| `sandbox_auto_init` | bool | `true` | **conditional** (`include_sandbox`). Auto-generate sandbox secrets into a git-ignored `.env` now (needs `--trust`); otherwise run `just sandbox-init` yourself. |

## Spec-Driven Development

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `sdd_framework` | choice | `none` | None (informal `/spec`) / OpenSpec (lightweight, brownfield, npm) / Spec-Kit (heavier, greenfield, uv). |
| `sdd_install_agent` | choice | first enabled agent (claude > codex > opencode) | **conditional** (`sdd_framework != none`). Which agent gets the SDD slash-commands. |

## Tooling extras

| Prompt | Type | Default | Notes |
| --- | --- | --- | --- |
| `include_sql` | bool | `true` | sqlfluff pre-commit hook + config. |
| `sql_dialect` | str | `ansi` | **conditional** (`include_sql`). e.g. `postgres`, `snowflake`, `bigquery`. |
| `license` | choice | `Proprietary` | Proprietary / MIT / Apache-2.0 — see below. |

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

`copier.yml` also defines `shared_deny_bash`, `shared_deny_read`,
`shared_deny_write`, and `shared_ask_bash` with `when: false`. These are **not**
prompted — they are the single source of truth for the agent permission lists and
are injected into the render context so every tool config (`.claude/settings.json`,
`opencode.json` granular `bash`/`edit`/`read` object syntax) stays in lockstep.
Edit them in `copier.yml`; do not duplicate them per tool.
