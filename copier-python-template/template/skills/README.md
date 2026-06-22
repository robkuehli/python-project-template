# Skills

Reusable, on-demand procedures for coding agents, in the open
[Agent Skills](https://agents.md) `SKILL.md` format. Each skill is a folder
with a `SKILL.md` file (name + description in frontmatter, then Markdown
instructions) that an agent loads only when relevant.

## The Pareto skill set

The nine skills below are tool-agnostic and cover the bulk of an
AI-assisted development workflow. Activate them by referencing the slash-style
name in conversation (`/explore`, `/spec`, …) — the agent's runtime resolves
each to the matching `SKILL.md`.

| Skill | Trigger | Output |
|---|---|---|
| [`/explore`](explore/SKILL.md) | Need to understand a codebase area | Relevant files, patterns, open questions |
| [`/spec`](spec/SKILL.md) | Define a feature | Requirements, acceptance criteria, edge cases, out-of-scope |
| [`/plan`](plan/SKILL.md) | Structure an implementation | Ordered steps with dependencies and verification |
| [`/test`](test/SKILL.md) | Derive tests from a spec | Pytest functions mapped to acceptance criteria |
| [`/delegate`](delegate/SKILL.md) | Hand off to an autonomous agent | Self-contained brief: spec + plan + tests + constraints |
| [`/review`](review/SKILL.md) | Review a change | Findings grouped by severity, one-line verdict |
| [`/verify`](verify/SKILL.md) | Prove the change works | Fresh evidence (command + output) mapped to acceptance criteria |
| [`/debug`](debug/SKILL.md) | Find a root cause | Repro, hypotheses, root cause, fix + regression test |
| [`/capture`](capture/SKILL.md) | Save a learning | One-line rule with date and *why* |

## How they compose

```
/explore → /spec → /plan → /test → /delegate → /review → /verify → /capture
                                                   │
                                                   └─→ /debug  (any time)
```

- `/plan` replaces `/spec` for small tasks and decomposes a spec for big ones.
- `/delegate` consumes `/spec` + `/plan` + `/test`. Without that foundation,
  the receiving agent fills the gaps with guesswork.
- `/review` checks correctness; `/verify` proves the change works on the
  current diff. Both run before declaring done — `/verify` is the gate that
  blocks "looks fine" claims without evidence.
- `/capture` is not an appendix to `/review` — it's a separate step, because
  learnings die otherwise.

## Adding a new skill

Add a folder under `skills/` containing one `SKILL.md`:

```
skills/<name>/SKILL.md
```

Keep skills small and focused — under ~80 lines is the working norm. The
frontmatter `description:` is what the agent uses to decide whether to load
the skill, so write it as "**what** it does and **when** to use it".
