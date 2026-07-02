# Documentation guidelines

Imperative rules for AI coding agents writing or updating docs in this project.
Spine: [Diátaxis](https://diataxis.fr/) (Procida) + Docs-as-Code (Etter) +
Living Documentation (Martraire).

## Core mandate

**Documentation exists so the next reader — human or agent — becomes productive
faster.** Anything that doesn't serve that goal is ballast. Write for the
reader's moment of need, not for completeness.

## The four modes (Diátaxis)

There isn't *one* thing called documentation; there are four. Each serves a
different reader in a different moment. **Each document belongs to exactly one
mode.** Mixing modes is the root cause of most doc frustration.

| Content informs… | …in service of… | …so it's a… | Reader's question |
|---|---|---|---|
| **Action** | **Acquisition** (learning) | **Tutorial** | "Show me how to get started." |
| **Action** | **Application** (working) | **How-to guide** | "How do I solve problem X?" |
| **Cognition** | **Application** (working) | **Reference** | "What does X expect/return?" |
| **Cognition** | **Acquisition** (learning) | **Explanation** | "Why is it built this way?" |

Mapping to this repo:

| Mode | Lives in |
|---|---|
| Tutorial | *Not shipped by default.* Add `docs/getting-started.md` if/when the project has one canonical "first run" worth teaching. |
| How-to | `docs/how-to/*.md` — recipes for concrete tasks |
| Reference | generated API docs (`mkdocstrings`), `--help`, `docs/reference/` |
| Explanation | `docs/explanation/*.md`, ADRs, design rationale |

If a text feels "off", it's almost always mode-mixing. Apply the compass, split.

## Core principles

| Principle | Rule |
|---|---|
| **Reader-centric** | Measure: "does the reader finish their task?", not "did I write it down?" |
| **Single source of truth** | Exactly one canonical place per fact. Everything else links to it; no copies. |
| **Docs-as-code** | Markdown in the repo, versioned, PR-reviewed, published via MkDocs. |
| **Generate over maintain** | API reference, config schemas, glossaries — derive from source. Hand-maintained reference drifts, guaranteed. |
| **Travel in the same commit** | Code + tests + doc update ship together. Drift can't form if there's no gap. |
| **90 / 10** | 90 % understanding, 10 % writing. Understand first, then formulate. |

## Anti-patterns

| Anti-pattern | Symptom | Fix |
|---|---|---|
| Mode-mixing | Tutorial drowns in reference details; reference holds the reader's hand. | Apply the compass; split into four. |
| Wishful docs | Documents planned features as if they exist. | Document only what's in code today. |
| Copy-paste truth | Same fact in three places, two outdated. | One SoT, the rest are links. |
| Wall-of-text README | Endless README with no structure. | README = entry hall; depth → `docs/`. |
| Outdated screenshots | UI shots that no longer match. | Generate (Playwright) or omit. |

## Living documentation

Docs without maintenance are worse than no docs — they actively mislead. The
counter-measures are mechanical, not disciplinary:

- **In the repo, not next to it.** Mermaid in Markdown beats Confluence/Excalidraw.
- **In the commit, not after** (Willison's *Perfect Commit*).
- **Enforce in CI.** Docstring coverage via `interrogate` in pre-commit; build
  API docs in CI; run the README quickstart on a fresh environment per release.
- **Append-only for decisions.** ADRs are never deleted or rewritten — only
  superseded.

## The practical layer

**README — the entry hall.** Not a Diátaxis mode, but the index:
*what is this* (one sentence), *quickstart* (`git clone … && just install && just qa`
must suffice), *key commands*, *where to find what*. Deep architecture, full
API, tutorials → out to `docs/`.

**Docstrings — reference contract.** Google style (recognised by `mkdocstrings`).
Required for every public function/class and any non-trivial logic. Skip for
trivial private helpers and property getters.

```python
def fetch_episodes(podcast_id: str, limit: int = 50) -> list[Episode]:
    """Fetch episodes for a podcast, newest first.

    Args:
        podcast_id: The podcast's slug, e.g. "darknet-diaries".
        limit: Maximum number of episodes to return. Defaults to 50.

    Returns:
        Episodes ordered by publication date, newest first.

    Raises:
        PodcastNotFoundError: If the podcast slug is unknown.
    """
```

**ADR — explanation artefact** (Nygard format). Short, numbered, append-only:

```markdown
# ADR-NNN: <Title>
## Status
Proposed | Accepted | Deprecated | Superseded by ADR-MMM
## Context
What situation forces the decision?
## Decision
What was decided — in one sentence.
## Consequences
Positive and negative, honestly.
## Alternatives considered
What was rejected and why?
```

**Diagrams** as Mermaid in Markdown (C4 levels 1–2 are usually enough), so they
ship versioned and reviewed in the PR.

## Agent-facing docs

`AGENTS.md`, `CLAUDE.md`, skills, this guideline — these are documentation too,
just for an agent reader. The compass still applies: agents almost always need
**reference** (commands, conventions) and **explanation** (architecture,
invariants), rarely tutorials. Keep each file under ~200 lines, version it,
review it like code.
