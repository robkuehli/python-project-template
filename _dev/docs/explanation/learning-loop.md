# Learning-Inbox (OpenCode, opt-in)

The Learning-Inbox is an **opt-in** private-memory layer for OpenCode. This
page is for template developers — it explains why the feature exists, how it
combines with the existing two-tier memory model, and the guardrail
trade-offs. For the generated-project view, see
`template/docs/explanation/learning-loop.md.jinja`.

## Why

OpenCode has no native Auto-Memory (unlike Claude Code's `autoMemoryEnabled`
and Codex's `features.memories`). Without it, the manual `/capture` skill is
the only learning path — and in practice it gets forgotten. The inbox closes
that gap with a Scribe role that proposes lessons automatically at SessionEnd,
while the human still curates the promote step.

## What it adds (when `include_opencode_learning_inbox` is true)

Under `template/{% if 'opencode' in coding_agents %}.opencode{% endif %}/`:

- `LEARNINGS.md` — canonical, git-tracked, loaded into context via the
  `instructions:` array in `opencode.json.jinja`.
- `LEARNINGS.inbox.md` — staging, git-tracked, **not** in context.
- `commands/capture.md` — the `/capture review` command (review inbox →
  promote kept proposals → mark `[x] promoted`).
- `plugins/capture-learnings.ts` — SessionEnd plugin (Scribe role). Reads the
  transcript via `session.messages`, sends a prompt + excerpt to
  `opencode run --model small_model`, appends returned proposals to the inbox.
  Never writes to `LEARNINGS.md`.
- `plugins/surface-inbox.ts` — SessionStart plugin. Counts `[ ] proposed:`
  lines and prints a reminder.

Plus edits to:

- `opencode.json.jinja` — adds `.opencode/LEARNINGS.md` to `instructions:`
  when enabled.
- `skills/capture/SKILL.md.jinja` — extends the "Two memory tiers" section
  and adds an OpenCode `/capture review` section.
- `AGENTS.md.jinja` — adds the OpenCode private-tier entry to the
  Self-improvement loop and the OpenCode-specifics memory bullet.
- `docs/explanation/working-with-agents.md.jinja` — updates the memory-tiers
  table and adds an OpenCode subsection.
- `docs/explanation/{% if ... %}learning-loop.md{% endif %}.jinja` — the
  generated-project explanation page (conditional).
- `mkdocs.yml.jinja` — conditional nav entry for the new page.
- `copier.yml` — new prompt `include_opencode_learning_inbox` and a
  re-split `shared_deny_write` (see Guards below).

Claude Code and Codex keep their native Auto-Memory plus the existing manual
`/capture` — **no duplication**. Aider remains without any private memory
(no hook system, no Auto-Memory).

## Two steps

1. **Stufe 1 (automatisch):** `capture-learnings.ts` listens on
   `session.idle`. When the transcript exceeds
   `OPENCODE_LEARNINGS_MIN_BYTES` (default 8192), it sends a prompt + the
   transcript to `opencode run --model small_model` and appends any returned
   proposals as `[ ] proposed:` to the inbox. The hook never writes to
   `LEARNINGS.md`.
2. **Stufe 2 (manuell):** `/capture review` reads the inbox, shows a keep/drop
   list, and on confirmation prepends kept entries to `LEARNINGS.md` (newest
   first) and marks the inbox line as `[x] promoted`.

> "Automatik beim Schreiben, Mensch beim Freigeben." The inbox collects, the
> human curates. `LEARNINGS.md` is the source of truth — only ever written
> after explicit confirmation.

## Guards (PRINCIPLE V)

This feature adds a new surface, so it required guard work before shipping:

- **No new credential surface.** The `small_model` is already declared in
  `opencode.json.jinja` (per tier: `qwen3:4b` local, `gpt-oss:20b-cloud`
  cloud, `qwen3:4b` hybrid). The plugin reuses the existing Ollama provider —
  no new tokens, no new MCP server.
- **`shared_deny_write` re-split.** `.opencode/**` was previously blanket-
  denied. To let `/capture review` write to `.opencode/LEARNINGS*.md`, the
  list now protects `.opencode/agents/**`, `.opencode/commands/**`,
  `.opencode/plugins/**`, and `opencode.json`, but keeps
  `.opencode/LEARNINGS*.md` writable. Mirrors the existing `.claude/`
  granularity (OWASP ASI06: the trust-sensitive tooling stays off-limits, the
  lesson store stays editable).
- **Hook never throws.** `capture-learnings.ts` swallows every failure path
  (missing inbox, short transcript, `opencode run` failure, timeout,
  `appendFileSync` failure). A SessionEnd hook must never block the session
  from ending.
- **Scribe output is capped at 16 KiB per session** so a drifting model can't
  bloat the git-tracked inbox without limit.
- **`LEARNINGS.md` is a secondary context-poisoning surface once promoted.**
  The Scribe reads the raw transcript, which may contain untrusted content
  (issues, docs, user pastes). `/capture review` is the human gate: reject any
  proposal that reads like an instruction to the agent ("always do X", "ignore
  Y") rather than a preventive rule — a planted instruction would persist
  across sessions via `instructions:` (OWASP ASI06).
- **Opt-in, not default.** `include_opencode_learning_inbox` defaults to
  `false` per PRINCIPLE I (Pareto) — only projects that want the loop pay the
  Scribe cost. Runtime opt-out via `OPENCODE_LEARNINGS_MIN_BYTES=0`.

## Risk: transcript excerpt leaves the driver

The Scribe call sends a prompt + a concatenated transcript excerpt to the
configured `small_model`. The excerpt may contain code snippets, file names,
or error text.

- **Ollama local** (`qwen3:4b`, hybrid's local small): nothing leaves the host.
- **Ollama Cloud** (`gpt-oss:20b-cloud`): the excerpt travels to the cloud
  provider. Review what your provider logs/retains before enabling in a
  regulated environment.

The plugin never sends the transcript anywhere except the configured
`small_model` — no third telemetry, no external MCP.

## SPOT (PRINCIPLE III)

`LEARNINGS.md` holds **project-specific lessons**, not behaviour rules for
agents — the agent-rule SPOT (`AGENTS.md` + `guidelines/*.md`) is unchanged.
The `/capture` skill is the only place that describes the capture procedure
(tool-agnostic). Tool-specific files (`commands/capture.md`, the plugins)
carry only the runtime glue each tool needs.

## Living documentation (PRINCIPLE VII)

This feature ships with:

- `_dev/CHANGELOG.md` — `[Unreleased]` entry.
- `_dev/docs/options.md` — new prompt row.
- `_dev/docs/decisions.md` — updated OpenCode memory decision.
- This page.
- `template/docs/explanation/learning-loop.md.jinja` — generated-project
  view.
- `template/docs/explanation/working-with-agents.md.jinja` — updated
  memory-tiers table + OpenCode subsection.
- `template/mkdocs.yml.jinja` — conditional nav entry.

## Verification

`just -f _dev/justfile render-test` covers the OpenCode-hybrid scenario (Test
5) but does **not** yet flip `include_opencode_learning_inbox=true`. When
extending coverage, add a scenario that answers the new prompt true and
asserts the rendered `opencode.json` contains the `.opencode/LEARNINGS.md`
`instructions:` entry, the two plugin files exist, and `commands/capture.md`
is present. Eyeball with:

```bash
copier copy --trust ../python-project-template /tmp/scratch
# answer opencode + include_opencode_learning_inbox=true
```

## Migration / removal

If OpenCode ships native Auto-Memory, drop this opt-in entirely: delete the
five conditional files under `.opencode/`, the `instructions:` entry, the
prompt in `copier.yml`, the nav entry, and this docs page. Restore
`.opencode/**` to `shared_deny_write` (or keep the granular split — it's
strictly safer).