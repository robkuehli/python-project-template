---
name: plan
description: >-
  Turn a task or spec into an ordered set of implementation steps with explicit
  dependencies. Lightweight for small tasks; decomposes a spec for big ones.
  Use before any non-trivial code change.
---

# /plan

Bridge between intent and code. A plan is what the human approves before code
starts being written.

## When to trigger

- Any non-trivial change. "Non-trivial" = more than ~2 files or any design choice.
- After `/spec` for big work.
- Before `/delegate` — the autonomous agent needs an ordered plan.

## When NOT to trigger

- Single-line fix or obvious refactor with no design choice.

## Output shape

```markdown
# Plan: <task title>

## Spec reference
Link to spec, or "ad-hoc — see request above."

## Steps
1. <verb-first step> → <expected outcome>
2. <next step> → <outcome>   (depends on 1)
3. …

## Risks / unknowns
- What could go wrong, what's unverified.

## Verification
- How we will know each step worked (test, command, observed behaviour).
```

## Rules

- **Verb-first steps.** "Add validation to `User.create`" not "Validation".
- **One logical change per step.** If a step needs >50 lines of diff, split it.
- **Mark dependencies.** Steps that can run in parallel should say so.
- **Plan is approved before code.** Present the plan, wait for the human, then
  execute.

## Plan → Execute → Verify

This skill is the *Plan* step of the loop defined in **AGENTS.md → "Plan → Execute
→ Verify"**. After approval, execute with small diffs; close the loop with
`/verify`. Don't redefine the discipline here — keep one source of truth.
