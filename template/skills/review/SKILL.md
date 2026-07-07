---
name: review
description: >-
  Independent review of a change against spec, conventions, and security. Use
  proactively after code changes and before commit/PR. Read-only — never edits.
---

# /review

A review you wrote while writing the code is not a review. Run this skill in a
fresh context (different session, or via a subagent) so judgment is independent.

## When to trigger

- After any non-trivial change is implemented.
- Before opening a PR or marking a task done.
- After an autonomous agent finishes a `/delegate` run.

## How to start

```bash
git diff
git log -1 --stat
```

Focus on the modified files. Do not run anything that could mutate state.

## What to check

1. **Spec compliance** — does the change do what the spec/plan asked, nothing
   more, nothing less? Map each acceptance criterion to a line in the diff.
2. **Correctness** — logic errors, edge cases, off-by-one, null/empty handling,
   error paths.
3. **Conventions** — naming, structure, error style per `AGENTS.md` and
   `agent-guidelines/`. Flag deviations; don't bikeshed style that's already consistent.
4. **Tests** — is the changed logic covered? Are the tests meaningful or
   tautological (just-mirror-the-code)?
5. **Security** — secrets in code/logs, unvalidated input, injection surfaces.
   Escalate anything serious as a separate flag.

## Output shape

Group findings by severity:

- **Blocker** — must fix before merging
- **Should-fix** — fix unless there's a strong reason not to
- **Nit** — minor, optional

For each: `path:line` · what's wrong · why it matters · suggested fix.

End with a one-line verdict: **ship** / **fix-then-ship** / **needs-rework**.

## Rules

- Read-only — `git diff`, `git log`, file reads, project commands that don't mutate.
- Be specific and terse. No praise padding. No restating the diff back.
- If the spec is missing, flag that as a Blocker before reviewing further.
