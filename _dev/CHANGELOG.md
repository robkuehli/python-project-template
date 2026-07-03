# Changelog

All notable changes to **`python-project-template`** are documented here.

Format: [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

Scope: this file tracks the **template itself** — the Copier scaffold, its
questions, hooks, and the rendered files. Generated downstream projects keep
their own `CHANGELOG.md` (see `template/CHANGELOG.md.jinja`).

## [Unreleased]

### Added

- **OpenCode Learning-Inbox** (opt-in via new Copier prompt
  `include_opencode_learning_inbox`, default `false`, only shown when
  `opencode` is in `coding_agents`). OpenCode has no native Auto-Memory
  (unlike Claude Code's `autoMemoryEnabled` and Codex's `features.memories`).
  The inbox adds a git-tracked staging layer: `.opencode/LEARNINGS.md`
  (canonical, in context via `opencode.json` `instructions:`) +
  `.opencode/LEARNINGS.inbox.md` (staging, not in context). A SessionEnd
  plugin (`capture-learnings.ts`) auto-extracts learning proposals from the
  transcript via the configured `small_model` (Scribe role); `/capture review`
  promotes kept proposals manually. "Automatik beim Schreiben, Mensch beim
  Freigeben." Claude Code and Codex keep their native Auto-Memory plus the
  existing manual `/capture` — no duplication. New generated docs page
  `docs/explanation/learning-loop.md` (conditional) explains the concept and
  risks (PRINCIPLE V: transcript excerpt leaves the driver when `small_model`
  is a cloud model).
- `shared_deny_write` in `copier.yml` re-split: `.opencode/**` is no longer
  blanket-denied. `.opencode/agents/**`, `.opencode/commands/**`,
  `.opencode/plugins/**`, and `opencode.json` stay protected (OWASP ASI06);
  `.opencode/LEARNINGS*.md` stays writable so `/capture review` can promote.
  Mirrors the existing `.claude/` granularity.

## [1.0.0] - 2026-06-03

### Added

- Docs: new "Context compression (optional)" explanation page covering
  Headroom and similar proxies — what they do, when they help, the risks
  (credential surface, SPOT/guardrail edits, tool-config collisions), and a
  self-install sketch. Not wired into the template: no Copier prompt, no
  generated config, no hook. Opt-in documentation only, per Pareto and
  Security-by-default.
