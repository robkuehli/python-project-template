---
name: verify
description: >-
  Prove a change works before claiming it's done. Use right before saying
  "finished", before committing, or before opening a PR. Output is the evidence,
  not the assertion.
---

# /verify

The *Verify* step of the loop defined in **AGENTS.md → "Plan → Execute → Verify"**
— distilled to its mechanics. The rule is simple: **no completion claims
without fresh evidence**.

## When to trigger

- You are about to say a task is done.
- You are about to commit, push, or open a PR.
- An autonomous run is about to end its turn.

## The gate (five steps, in order)

1. **Identify** the check that proves the change works (tests, build, linter,
   screenshot diff, manual run output).
2. **Run** it — fresh, this turn. "It passed earlier" doesn't count.
3. **Read** the actual output, not the summary.
4. **Verify** every acceptance criterion is satisfied. If a criterion has no
   matching evidence, the gate fails.
5. **Report** the evidence (command + relevant lines), then claim done.

## Red flags that mean you skipped the gate

- "Should work", "probably fine", "this looks correct" — without running anything.
- Reusing the output of an earlier turn as proof for a later change.
- Claiming a feature works because related tests passed.
- Calling something done before `just qa` ran on the current diff.

## What evidence looks like

Bad: *"Tests pass."*
Good: *"`just test tests/test_auth.py` → `5 passed in 0.42s`. Edge case
`test_logout_during_refresh` exercises the bug fix in `auth.py:147`."*

## Rules

- Verify on the **current** diff, not a stale state.
- If verification fails, fix the cause and re-verify. Don't ship "yellow".
- If you can't construct a check, say so explicitly rather than ship blind.
- After 3 verification failures on the same change, stop and ask for context.
