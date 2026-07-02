---
name: explore
description: >-
  Read-only reconnaissance of a codebase area. Use when you need to understand
  what's there before changing anything — affected files, patterns, dependencies,
  open questions. Always read-only, never edits files.
---

# /explore

Map the territory before you touch it. Output is a compact briefing so the
caller doesn't need to re-read everything.

## When to trigger

- You're new to the area the user is asking about.
- The user says "look into X", "understand how Y works", "where does Z live?".
- Before `/spec` or `/plan` when scope is fuzzy.

## How to work

1. **Glob + Grep** to map the surface: file layout, naming conventions, entry points.
2. **Read** the 3–8 files that look load-bearing. Don't read the long tail —
   that's how context gets blown.
3. Trace the data/call flow for the specific question. Stop at the edge of the
   user's question; don't drift.
4. Distinguish **fact** (it's in the code) from **inference** (your reading
   of intent). Label inference.

## Output shape

Always these four sections, in this order:

- **Relevant files** — `path` + one-line role.
- **Patterns observed** — naming, error style, layering, test style.
- **Dependencies** — internal imports, external libs.
- **Open questions** — anything ambiguous that needs the user before continuing.

## Guardrails

- Read-only. No edits, no commits.
- If you find more than ~10 files load-bearing, ask the user to narrow scope
  before continuing.
- Cite library/API claims with web search if they're not visible in the repo —
  training data is stale.
