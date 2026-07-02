---
name: debug
description: >-
  Systematic debugging — reproduce, isolate, diagnose, fix. Use when something
  is broken and the root cause isn't obvious. Stops and asks rather than
  guessing after 3 failed attempts.
---

# /debug

Debugging is hypothesis-driven, not random. Treat the bug as a *prediction*
mismatch: what does the code think it's doing, what is it actually doing,
where does the gap start?

## When to trigger

- A test fails and the reason isn't immediately obvious.
- Behaviour disagrees with the spec.
- A user reports a defect.

## Loop

1. **Reproduce.** A minimal, deterministic repro. If you can't reproduce, you
   can't fix — invest in the repro first.
2. **Isolate.** Bisect: which commit, which input, which branch of code is
   responsible? Trim the failing case until removing one more piece makes the
   bug disappear.
3. **Diagnose.** Form a hypothesis ("I think X causes Y because Z"). Predict
   what you'd see if the hypothesis were true, then check. If wrong, form a
   new hypothesis — don't accumulate undisproven ones.
4. **Fix.** Smallest change that addresses the root cause, not the symptom.
   Add a regression test that would have caught the bug.

## Output shape

```markdown
## Repro
<minimal command/input that triggers it>

## Hypotheses considered
- H1: ... — disproved by <observation>
- H2: ... — confirmed by <observation>

## Root cause
One sentence.

## Fix
<diff or description, plus the regression test>
```

## Rules

- **3-strike rule.** After 3 failed hypothesis cycles, stop and ask the user
  for more context instead of guessing.
- **No "fix the symptom" patches.** If `if x is None: x = []` makes the test
  green but you don't know *why* `x` was `None`, you didn't fix the bug.
- **Regression test is mandatory.** A bug that escaped once will escape again
  if nothing protects against it.
- **Don't refactor while debugging.** Land the fix first; clean up separately.
