# Changelog guidelines

Based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning 2.0.0](https://semver.org/).

## Format

The file is `CHANGELOG.md` in the repo root. Each version gets its own section,
newest first, dated in ISO format (`YYYY-MM-DD`).

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New search across the episode archive

## [1.2.0] - 2026-02-08

### Fixed
- Pagination on empty result sets
```

## Categories

Group changes into exactly these six categories:

| Category | When to use |
|---|---|
| **Added** | New features |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features that will be removed soon |
| **Removed** | Features that have been removed |
| **Fixed** | Bug fixes |
| **Security** | Security fixes |

## Do

- **Maintain `[Unreleased]`** — collects in-flight changes; becomes the new
  version at release time.
- **Write for humans, not machines** — say *what* changed and *why* it matters.
- **Assign every entry to a category** — group similar changes.
- **Use ISO dates** — `2026-02-08`, never `02/08/2026`.
- **Document deprecations** — users must know what will disappear before it does.
- **Highlight breaking changes** with a `BREAKING:` prefix in the entry.
- **Mark yanked releases**: `## [0.0.5] - 2014-12-13 [YANKED]`.

## Don't

- **Dump git log.** Commit messages aren't a changelog. Merge commits, typo
  fixes, doc-only changes don't belong here.
- **Inconsistent entries.** A patchy changelog is worse than none. If you keep
  it, keep it completely.
- **Ambiguous date formats.** `02/08/2026` — is that February or August? Always ISO 8601.
- **Empty categories.** Only list categories that have entries this release.
- **Technical commit details.** "Refactored internal query builder" doesn't help
  end users. Write the observable effect: "Search results now load 3× faster."

## When to add an entry

Any **user-visible or behavioural change** belongs in the changelog — public
API change, new dependency requirement, default-config change, security fix,
new CLI flag, performance characteristic the user can observe.

Skip internal refactors and code reorganisation that no external caller can
detect.

## Cutting a release

1. Move every entry under `[Unreleased]` into a new `## [X.Y.Z] - YYYY-MM-DD`
   section above it.
2. Empty the `[Unreleased]` section but keep the heading.
3. Tag the commit (`git tag vX.Y.Z`).
4. Choose the version bump per SemVer: MAJOR for breaking, MINOR for new
   compatible features, PATCH for bug fixes.
