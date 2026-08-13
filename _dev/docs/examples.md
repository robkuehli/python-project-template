# Example setups

Three concrete answer combinations for common project shapes. Each block lists
every prompt Copier will ask in that constellation, in the order it asks them —
conditional prompts that are skipped (e.g. `litellm_base_url` when no tool uses
the gateway) are omitted. For the full prompt catalogue, see the
[Options reference](options.md).

## 1) Solo with Claude Code (subscription)

Single developer, interactive sessions, Pro/Max subscription. Smallest possible
agent surface — one tool, no gateway, no sandbox.

```text
project_name           → Customer Insights
project_slug           → customer-insights              # default derived from project_name
package_name           → customer_insights              # default derived from project_slug
project_description    → Customer churn analysis pipeline.
author_name            → Robin Kühling
author_email           → robin.kuehling@example.com
github_username        → robinkuehling
python_version         → 3.13
coding_agents          → Claude Code                    # multi-select: deselect the default Codex CLI
claude_provider        → Claude subscription (Pro/Max, /login)
include_sandbox        → no
sdd_framework          → None — informal /spec via the workflow skill is enough
include_sql            → no                             # turn on if the project touches SQL
license                → Proprietary
```

After generation:

```bash
cd my-project
claude                 # opens the REPL; on first run, type `/login` (one-time, opens browser)
                       # then drive via skills: /explore, /spec, /plan, /test, ...
```

The repo has `AGENTS.md` (shared brief), `CLAUDE.md` (Claude-specific
overrides) and `.claude/` (subagents `researcher`/`reviewer`/`security-auditor`,
hooks, the nine workflow skills). pre-commit + `just qa` are the verify gate.

## 2) Team setup with Claude Code + Codex (LiteLLM gateway)

Two tools sharing one brief (`AGENTS.md`), routed through the company's LiteLLM
gateway so model access, audit, and budgets sit in one place. Claude Code for
architecture/spec work, Codex CLI for fast implementation diffs.

```text
project_name           → Snowflake Pricing
project_slug           → snowflake-pricing
package_name           → snowflake_pricing
project_description    → Snowflake usage + pricing reporting service.
author_name            → Robin Kühling
author_email           → robin.kuehling@example.com
github_username        → your-company
python_version         → 3.13
coding_agents          → Claude Code, Codex CLI
claude_provider        → LiteLLM gateway (company / Bedrock / mixed)
codex_provider         → LiteLLM gateway (OpenAI-compatible)
litellm_base_url       → https://litellm.your-company.internal
include_sandbox        → no
sdd_framework          → Spec-Kit — structured, intent-driven, uv-based
include_sql            → yes
sql_dialect            → snowflake                      # or postgres, bigquery, ansi, …
license                → Proprietary
```

After generation, the gateway token lives in your shell, never in the repo.
Claude Code's base URL is pinned in `.claude/settings.json`. Codex deliberately
keeps provider routing user-scoped, so install the generated profile once per
machine:

```bash
# in your ~/.zshrc or a sourced env file (NOT committed):
export ANTHROPIC_AUTH_TOKEN="$LITELLM_TOKEN"
export OPENAI_API_KEY="$LITELLM_TOKEN"

cd my-project
mkdir -p ~/.codex
cp .codex/litellm.config.toml.example ~/.codex/litellm.config.toml
claude            # picks up the token; base URL comes from .claude/settings.json
codex --profile litellm
```

Both tools read the same `AGENTS.md` + `agent-guidelines/` + `skills/`. Use Claude
Code in Plan Mode for design discussions, hand the resulting plan to Codex
for execution — or vice versa.

## 3) OpenCode in the sandbox (interactive, local / hybrid)

OpenCode driven interactively from inside the Docker sandbox — repo bind-mounted
at `/workspace`, host secrets stay on the host. Hybrid tier means cloud frontier
models as the `large` default (via Ollama Cloud) and a local Qwen3 4B as
`small_model` for utility tasks. Langfuse runs alongside for prompt/cost tracing.

```text
project_name           → Risk Scorer
project_slug           → risk-scorer
package_name           → risk_scorer
project_description    → Risk scoring service.
author_name            → Robin Kühling
author_email           → robin.kuehling@example.com
github_username        → robinkuehling
python_version         → 3.13
coding_agents          → OpenCode
ollama_subscription    → yes                            # `ollama signin` done; required for cloud models
ollama_tier            → Hybrid — large = cloud frontier, small = best local (recommended)
ollama_base_url        → http://localhost:11434
include_sandbox        → yes
sandbox_observability  → Langfuse (LLM-native, cost + tracing + dashboards)
include_crawl4ai       → no                             # flip to yes for JS-rendered fetches
sdd_framework          → None — informal /spec via the workflow skill is enough
include_sql            → no
license                → Proprietary
```

After generation:

```bash
cd my-project

# One-time
just sandbox-build
ollama pull qwen3:4b                 # small_model for title gen / compaction
ollama signin                        # cloud auth — daemon forwards `:cloud` models

# Start supporting services (searxng + Langfuse) and drop into the sandbox shell
just sandbox-up
just sandbox-shell
#   inside the container:
#     opencode                       # interactive — drive via /explore, /spec, /plan, ...
#     just qa                        # quality gate runs identically here
```

`agent-checkpoint` (Git-tag baseline) and the PR-template's *Agent run* section
remain available for unattended Auto-Approve sessions, but no overnight
orchestrator ships with the template — keep a human in the loop until local
models are reliably MVP-grade.
