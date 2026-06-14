---
tags:
  - docnote
  - agent-instructions
Creation Date: 2026-05-19
Last Modified: 2026-05-19
Finished: false
---
						
# Testing Guidelines for AI Coding Agents
*Based on interface-centered testing philosophy ("They Are Not Unit Tests" — Stanislav Zmiev)*

> **For Agent Memory Use.** This file is intended to be referenced directly by AI coding agents (Claude Code, OpenCode, Codex) — either via `@`-import in `CLAUDE.md`/`AGENTS.md` or as standalone agent instructions. Keep it imperative and prescriptive. The human-facing variant is `Testing Guidelines.md` (manifest form).

---

## Core Mandate

You write tests that protect **behavioral contracts**, not implementation details. A test exists to detect regressions in what a *consumer* observes — not to document how internal code is structured.

**Default assumption:** If a test would break due to an internal rename or refactor while the external behavior remains identical, the test is wrong by design. Do not write it that way.

---

## What to Test (and What Not to)

**Test the public contract:**
- HTTP endpoints: status codes, response body structure, relevant headers
- Public functions/methods: return values, raised exceptions, side effects visible to callers
- CLI commands: stdout, stderr, exit codes
- UI components: rendered output, user-visible state changes

**Do not test internal implementation:**
- Private helper functions (`_calculate_tax`, `_format_string`)
- Internal class attributes not exposed via public API
- The sequence of internal method calls
- Whether a specific private function was called (mock verification of internals)

---

## Mocking Rules

**Mock only external infrastructure** that crosses a process or network boundary:
- Third-party HTTP APIs → use `vcr.py` (record/replay) or `responses`
- Databases → use `Testcontainers` or a real in-memory/test DB, not manual mocks
- Hardware / system clocks / file system (when truly unavoidable) → mock sparingly at the boundary

**Never mock:**
- Internal business logic
- Functions within the same module or package
- Anything you could run cheaply in-process

If you find yourself mocking an internal function to make a test pass, stop. Redesign the test to call through the public interface instead.

---

## Assertion Strategy

**Be specific where it matters, permissive where it doesn't:**

```python
# Bad: breaks when unrelated fields change
assert response.json() == {
    "id": "abc-123",
    "name": "Alice",
    "created_at": "2024-01-15T10:30:00Z",  # volatile — will always fail
    "internal_counter": 42                   # irrelevant to consumer
}

# Good: protect the contract, ignore the noise
from dirty_equals import IsUUID, IsISOString
assert response.json() == {
    "id": IsUUID,
    "name": "Alice",
    "created_at": IsISOString,
}
```

Use `dirty-equals` matchers (`IsUUID`, `IsISOString`, `IsPositiveInt`, `IsDict`, etc.) for:
- Auto-generated IDs
- Timestamps
- Fields that are present but whose exact value is irrelevant to the contract

---

## Snapshot Testing

Use `inline-snapshot` for complex data structures where manual assertion writing is error-prone:

```python
from inline_snapshot import snapshot

def test_api_response():
    result = my_api_client.get_user(1)
    assert result == snapshot()  # auto-populated on first run
```

**Rules when using snapshots:**
1. Always review auto-generated snapshots before committing — never accept blindly
2. Use `dirty-equals` within snapshots for volatile fields
3. Keep snapshots granular: extract critical sub-structures into focused assertions rather than snapshotting entire large objects
4. For cross-version compatibility (e.g., different Pydantic versions), use nested/conditional snapshots

---

## Test Structure

**One behavior per test.** A test name should complete the sentence: *"It should..."*

```python
# Bad: testing multiple behaviors in one case
def test_user_creation():
    # creates user, validates email, checks default role, tests duplicate error — all in one

# Good: one concern per test
def test_create_user_returns_correct_structure():
def test_create_user_with_duplicate_email_raises_conflict():
def test_new_user_gets_viewer_role_by_default():
```

**Use parametrize for input variation, not copy-paste:**

```python
@pytest.mark.parametrize("invalid_email", ["notanemail", "", "a@", "@b.com"])
def test_create_user_rejects_invalid_email(invalid_email):
    with pytest.raises(ValidationError):
        create_user(email=invalid_email)
```

---

## Test Isolation

Every test must be independent:
- No shared mutable state between tests
- No dependency on test execution order
- Database state reset between tests (transactions, fixtures, or Testcontainers)
- No reliance on external services in unit/integration tests

Tests that are isolated can be parallelized. Tests that are not isolated produce flaky CI.

---

## When NOT to Write Tests

Do not write tests for:
- **Volatile / prototype code** actively being redesigned — mark it with `# pragma: no cover` or equivalent and remove tests when the interface stabilizes
- **Trivial delegation** — a function that does nothing but call another function with the same args
- **Framework internals** — Django's ORM, SQLAlchemy's session management, etc.
- **`__repr__` and debug methods** — exclude via coverage config

Do write tests for:
- Any public API endpoint or function a caller depends on
- Business logic with conditional branches
- Error handling and edge cases visible to consumers
- Integration boundaries (DB writes, external API calls via recorded fixtures)

---

## Coverage Interpretation

Coverage percentage alone is meaningless. Do not optimize for it.

- **A line being executed ≠ a line being verified**
- Target coverage on **critical business paths**, not on total line count
- Exclude non-critical code explicitly in config (debug utilities, `__repr__`, migration files)
- When in doubt about test quality, run mutation testing (`mutmut`) — surviving mutants reveal untested logic, not uncovered lines

---

## File and Naming Conventions

```
tests/
  unit/         # fast, no I/O, test public interfaces in isolation
  integration/  # real DB/infra via Testcontainers or test fixtures
  e2e/          # full-stack, slow, run selectively
```

- Test files: `test_<module_name>.py`
- Test functions: `test_<behavior_description>` (snake_case, descriptive)
- Fixtures: scoped as narrowly as possible (`function` > `module` > `session`)
- Use `pytest-fixture-classes` for complex, typed fixture setups

---

## Quick Reference Checklist

Before submitting any test, verify:

- [ ] Tests the public contract, not internal implementation
- [ ] Would survive a refactor that doesn't change behavior
- [ ] No mocks of internal functions
- [ ] Volatile fields handled with `dirty-equals` or similar
- [ ] Single behavior per test function
- [ ] Test is deterministic regardless of execution order
- [ ] External I/O uses recorded fixtures (`vcr.py`) or containers, not live services
- [ ] Snapshot updates reviewed, not blindly accepted
