---
name: spec
description: >-
  Define a feature or non-trivial task with requirements, acceptance criteria,
  edge cases, and out-of-scope. Use before `/plan` when the work is big enough
  that "just code it" would surface ambiguity later.
---

# /spec

Produce a contract the implementation can be measured against. A spec is what
turns a vague intent into a falsifiable target.

## When to trigger

- Feature work, not a one-line fix.
- Multiple plausible interpretations of the user's request.
- The implementation will be delegated to an autonomous agent.

## When NOT to trigger

- Trivial change (1–2 files, no design choice). Go straight to `/plan` or just do it.

## Output shape

```markdown
# <Feature name> — Spec

## Goal
One sentence: what success looks like, observable.

## Requirements
- Functional requirement A
- Functional requirement B

## Acceptance criteria
- [ ] Concrete, testable assertion 1
- [ ] Concrete, testable assertion 2

## Edge cases
- What happens at empty/null/max input?
- Concurrent / partial-failure behaviour?

## Out of scope
- Explicit list of what this spec does NOT cover.

## Open questions
- Unresolved items that block writing tests or code.
```

## Rules

- **Acceptance criteria are tests.** If you can't write a pytest assertion for
  it, the criterion is too vague — rewrite it.
- **No implementation choices** in the spec. "Use Redis" belongs in `/plan`.
- **List Out-of-Scope explicitly.** This is what prevents scope creep during
  `/delegate`.
- **Open questions stop work.** If there are any, return to the user before
  writing tests or code.

## Feedback loop

If during `/spec` you hit a knowledge gap (how does an existing system actually
behave?), pause and run `/explore`. Don't guess into the spec.
