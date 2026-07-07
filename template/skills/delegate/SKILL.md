---
name: delegate
description: >-
  Hand off a task to an autonomous agent. Bundle the spec, plan, tests, context,
  and constraints into a single brief the agent can act on without back-and-forth.
  Use before letting an agent run unattended.
---

# /delegate

The agent only knows what's in the bundle. Whatever isn't explicit will be
invented. Make the constraints loud.

## When to trigger

- A task that another agent (or another session) will pick up and run with
  minimal supervision.
- Tasks where you want a fresh-context agent to avoid your own framing bias.

## Pre-conditions

You must have all of these before calling `/delegate`:

- `/spec` output with acceptance criteria.
- `/plan` output with ordered steps.
- `/test` output (at least the names; implementation can come from the agent).

If any of these is missing, run them first — the agent will guess where you're
silent.

## Output shape

```markdown
# Agent brief: <task>

## Spec
<full spec, inline — don't link to a file the agent may not have>

## Plan
<full plan, inline>

## Tests to write / satisfy
<test names + one-line descriptions>

## Context the agent needs
- Files to read first: `path:line` references
- Existing conventions to follow: see `AGENTS.md`, `agent-guidelines/`
- Anything subtle that isn't obvious from the code

## Constraints
- MUST NOT touch files outside <scope>
- MUST run `just qa` and report results
- MUST stop and ask if it hits an open question rather than improvising

## Definition of done
- All acceptance criteria pass
- `just qa` is green
- Diff is minimal and on-scope
```

## Rules

- **Inline, not linked.** The downstream agent may not have access to files you
  reference. Spec + plan + tests live in the brief.
- **Constraints are explicit.** "Don't touch X" must be a sentence in the brief,
  not implied.
- **One brief per task.** Don't bundle unrelated tasks — the agent will conflate them.
- **No timeline / estimates.** Agents don't track wall clock; they'll lie about it.
