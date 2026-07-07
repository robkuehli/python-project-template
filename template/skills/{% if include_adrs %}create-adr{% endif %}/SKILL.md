---
name: create-adr
description: Create and update architecture decision records (ADRs) for this repository. Use when asked to draft a new ADR, convert notes into ADR format, revise an existing ADR, or enforce ADR conventions in `docs/adr` using `docs/templates/adr-template.md`.
---

# Create ADR

## Overview

Create consistent ADR documents for this repository using the local template, numbering scheme, and writing conventions. Produce focused decisions with explicit rationale, trade-offs, and rejected alternatives, judged against this repository's ADR guidelines.

## Workflow

1. Identify scope and source material.
- Parse the user request and gather inputs from files such as existing ADRs in `docs/adr`.
- Extract one coherent decision scope per ADR. If this is not possible, present this to the user and offer a suggestion for a split of the scope. Do not split the scope yourself without user confirmation.

2. Inspect repository ADR conventions before writing.
- Read `docs/templates/adr-template.md`.
- Read existing `docs/adr/*.md` to preserve style and metadata conventions.
- Use the mechanical rules in `agent-guidelines/repo-adr-conventions.md` (numbering, filenames, metadata fields).
- Use the quality principles in `agent-guidelines/adr-guidelines.md` (what makes a decision record good, independent of this repo).

3. Scaffold the new ADR file directly (no external script).
- List `docs/adr` and determine the highest existing zero-padded numeric filename (for example `007.md`).
- Compute the next ID by incrementing that number by 1, zero-padded to three digits (`001` if the directory is empty). If filenames don't follow this pattern, stop and ask the user how to proceed instead of guessing.
- Copy the content of `docs/templates/adr-template.md`.
- Fill in the metadata block only:
  - `ADR ID`: `ADR-<next id>`
  - `Title`: the decision title
  - `Date`: today's date, ISO format `YYYY-MM-DD`
  - `Status`: leave blank unless the user provides one
  - `Owner`: user-provided value, otherwise the repository default from `agent-guidelines/repo-adr-conventions.md`
  - `Reviewers`: user-provided value, otherwise the repository default from `agent-guidelines/repo-adr-conventions.md`
- Write the result to `docs/adr/<next id>.md`. If that file already exists, stop and ask the user rather than overwriting it.
- Leave all other template sections and their order untouched at this stage.

4. Create or update ADR content.
- Set `## Context` to the problem statement (constraints, current state, risk).
- Put only the decision itself in `## Decision`.
- Use numbered, evidence-based points in `## Rationale`.
- Capture both upsides and downsides in `## Consequences`.
- List realistic rejected options in `## Alternatives Considered`.

5. Validate against the ADR guidelines before finishing.
- Walk through every criterion in `agent-guidelines/adr-guidelines.md` and check the drafted ADR against each one explicitly.
- Check that title, context, and decision are aligned and not contradictory.
- Ensure alternatives are materially different from the chosen option.
- Confirm wording is specific enough to implement and review.
- Keep sections concise and avoid repeating the same statement across sections.
- If an existing ADR is being revised rather than replaced, prefer superseding it with a new ADR over silently editing an accepted decision, unless the repository's conventions say otherwise.

## Editing Rules

- Keep the template section order unchanged.
- Keep one primary architectural decision per ADR unless the points are tightly coupled.
- Prefer concrete language over generic policy statements.
- Do not add repository-irrelevant ADR boilerplate.
- Never invent an ADR ID, date, or default owner/reviewer — derive them from the repository state or the conventions file.

## Resources

### agent-guidelines/
- `agent-guidelines/repo-adr-conventions.md`: repository-specific mechanics — file locations, numbering, metadata defaults.
- `agent-guidelines/adr-guidelines.md`: repository-independent quality principles for what makes an ADR good (the "ADR Desiderata"), used during drafting and validation.

### templates/
- `docs/templates/adr-template.md` (in the target repository, not in this skill): the section structure and metadata block to scaffold from.
