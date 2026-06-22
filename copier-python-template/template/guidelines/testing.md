# Testing guidelines

Imperative rules for AI coding agents writing tests in this project.
Based on interface-centred testing ("They Are Not Unit Tests" — Stanislav Zmiev).

## Core mandate

Tests protect **behavioural contracts**, not implementation details. A test exists
to detect regressions in what a *consumer* observes — not to freeze how internal
code is structured.

> Default heuristic: if a test would break after an internal rename or refactor
> while external behaviour stays identical, the test is wrong by design.

A *unit* is not a technical artefact (function, class, module) — it's a behavioural
contract toward a consumer: a function with a public API, an HTTP endpoint, a CLI
command, a user-visible UI component. Anything else is internal.

**Hyrum's Law as guiding principle:** every observable behaviour becomes a de-facto
interface over time. Decide deliberately which contracts you protect, and which you
leave free for the implementation to change. Tests that pin down internals cause
*test-depression*: refactors break dozens of tests while observable behaviour stays
identical, draining team velocity and morale.

## Test desiderata

No test can satisfy all ideals at once — these are deliberate trade-offs, not
defects. The three properties with the highest long-term ROI:

- **Isolated** — order-independent and deterministic. Precondition for
  parallelisation and stable CI.
- **Behavioural** — fails immediately on behaviour changes, ignores internal
  structural changes. The behaviour is the contract; the code is not.
- **Structure-insensitive** — strongest lever against test-depression. A test that
  needs manual fixes after a behaviour-preserving refactor is conceptually broken.

> Composability often makes tests *both* faster and more meaningful: test each
> variability dimension separately, then combine — instead of one monolithic case
> per combination.

## What to test

- HTTP endpoints: status code, body structure, relevant headers
- Public functions/methods: return values, raised exceptions, observable side effects
- CLI commands: stdout / stderr / exit code
- UI components: rendered output, user-visible state changes

## What NOT to test

- Private helpers (`_calculate_tax`, `_format_string`)
- Internal class attributes not exposed via the public API
- The exact sequence of internal method calls
- Whether a specific private function was called (mock verification of internals)

## Mocking rules

**Mock only external infrastructure** that crosses a process or network boundary:

- Third-party HTTP APIs → `vcr.py` (record/replay) or `responses`
- Databases → `Testcontainers` or a real in-memory/test DB, never manual mocks
- Hardware / system clock / file system (when truly unavoidable) → mock sparingly at the boundary

**Never mock:** internal business logic, functions within the same package, or
anything you could run cheaply in-process. If you're mocking an internal function
to make a test pass, redesign the test to go through the public interface instead.

## Anti-patterns

Systematic causes of test-depression. Recognise and correct on sight:

| Anti-pattern | Symptom | Correction |
|---|---|---|
| **Mocking internals** | Tests break on internal rename; mocks drift from production reality. | Mock only external infrastructure. Run internal logic for real. |
| **Assertion overkill** | Brittle tests fail on irrelevant fields (timestamps, generated IDs). | Use `dirty-equals` (`IsUUID`, `IsISOString`) or extract focused sub-snapshots. |
| **Subtest abuse** | 200+-line monolithic test functions mixing multiple logic paths. | Split via `@pytest.mark.parametrize` or fixtures. |
| **Testing volatile code** | Tests for prototypes / actively redesigned code block iteration. | Exclude via coverage config (regex) and remove tests until the interface stabilises. |

## Assertion strategy

Be specific where it matters, permissive where it doesn't. Use
[`dirty-equals`](https://dirty-equals.helpmanual.io/) matchers (`IsUUID`,
`IsISOString`, `IsPositiveInt`, …) for auto-generated IDs, timestamps, and other
fields that are present but whose exact value isn't part of the contract.

```python
from dirty_equals import IsUUID, IsISOString

assert response.json() == {
    "id": IsUUID,
    "name": "Alice",
    "created_at": IsISOString,
}
```

## Snapshot testing

`inline-snapshot` for complex structures where manual assertion writing is
error-prone. Rules:

1. Review auto-generated snapshots before committing — never accept blindly.
2. Use `dirty-equals` inside snapshots for volatile fields.
3. Keep snapshots granular; extract critical sub-structures rather than
   snapshotting entire objects.

## One behaviour per test

A test name should complete *"It should…"*. Use `@pytest.mark.parametrize` for
input variation; don't copy-paste.

```python
@pytest.mark.parametrize("invalid_email", ["notanemail", "", "a@", "@b.com"])
def test_create_user_rejects_invalid_email(invalid_email):
    with pytest.raises(ValidationError):
        create_user(email=invalid_email)
```

## Test isolation

Every test must be independent: no shared mutable state, no order dependence,
database reset between tests (transactions, fixtures, or Testcontainers), no
reliance on live external services. Isolated tests can be parallelised; non-isolated
tests produce flaky CI.

## When NOT to write tests

- Volatile / prototype code in active redesign — mark with `# pragma: no cover`
  and remove tests when the interface stabilises.
- Trivial delegation (a function that just forwards args with no logic).
- Framework internals (ORM, session management, etc.).
- `__repr__` and debug-only methods — exclude via coverage config.

## Coverage interpretation

Coverage percentage alone is meaningless — *executed* is not *verified*. Target
coverage on critical business paths, not on total line count. When in doubt,
run mutation testing (`mutmut`); surviving mutants reveal untested logic, not
uncovered lines.

## File and naming conventions

```
tests/
  unit/         # fast, no I/O, public interfaces in isolation
  integration/  # real DB/infra via Testcontainers or fixtures
  e2e/          # full-stack, slow, run selectively
```

- Test files: `test_<module>.py`
- Test functions: `test_<behaviour_description>` (snake_case, descriptive)
- Fixtures scoped as narrowly as possible (`function` > `module` > `session`)
- Use [`pytest-fixture-classes`](https://github.com/zmievsa/pytest-fixture-classes)
  for typed, maintainable fixture setups.

## Architectural guardrails

Test quality is not accidental — it requires structures that make bad decisions
hard.

- **Architecture linting** via [`import-linter`](https://import-linter.readthedocs.io/):
  forbid test suites from importing business-logic internals or DB models directly,
  forcing them through public interfaces.
- **Thinnest testing layer**: cover ~90% of logic via narrow, interface-close
  wrappers. Delegate only the minimum to slow end-to-end tests.
- **Infrastructure isolation**: replace fragile manual mocks with `Testcontainers`
  (databases) and `vcr.py` (network interactions).
- **SQL fingerprinting**: detect N+1-query regressions proactively by snapshotting
  query fingerprints (e.g. `inline-snapshot-django`).

## Quick checklist

Before submitting a test, verify:

- [ ] Protects the public contract, not internal implementation
- [ ] Would survive a behaviour-preserving refactor
- [ ] No mocks of internal functions
- [ ] Volatile fields handled with `dirty-equals` or similar
- [ ] Single behaviour per test function
- [ ] Deterministic regardless of execution order
- [ ] External I/O via recorded fixtures or containers, not live services
- [ ] Snapshot updates reviewed, not blindly accepted
