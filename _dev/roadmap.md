You # Roadmap

Bewusst zurückgestellte oder geplante Template-Features. Kein Commitment auf
Reihenfolge oder Zeitpunkt.

## On hold

### OpenCode Learning-Inbox (Auto-Capture)

Opt-in-Feature, das OpenCode ein Auto-Memory-Äquivalent zu Claude Codes
`autoMemoryEnabled` / Codex `features.memories` geben sollte: ein
SessionEnd-Plugin (Scribe) extrahiert Learnings via `small_model` nach
`.opencode/LEARNINGS.inbox.md`, `/capture review` promotet sie manuell.

**Status:** implementiert auf Branch `feat/opencode-learning-inbox` (SHA
`3edccd1`), **nicht gemergt**. Das Gerüst (Copier-Prompt, deny-write-Split,
Docs, mkdocs-Nav, der manuelle `/capture review`-Pfad) ist sauber, aber das
Kernstück — die automatische Erfassung in `capture-learnings.ts` — ist mit der
aktuellen OpenCode-Plugin-API nicht sauber umsetzbar:

- `session.idle` liefert keine `messages` (nur `{ sessionId, filesModified }`);
  Transkript müsste über `client.session.messages()` geholt werden.
- `opencode run` nimmt den Prompt nicht über stdin, nur als Positional-Arg.
- `--model` braucht `provider/model`, nicht den Config-Key `small_model`.

**Zurückgestellt weil:** zu komplex für den Nutzen, solange OpenCode kein
natives Auto-Memory hat. Sobald das existiert, dieses Feature als dünnen
Wrapper darum neu bewerten — nicht als eigenes SessionEnd-Plugin.

## Ideen

- **Sandbox Egress-Restriction** — Copier-Switch `sandbox_restrict_egress:
  bool` + Sidecar-Egress-Proxy (z.B. tinyproxy mit Allowlist auf
  `api.anthropic.com`, `pypi.org`, `registry.npmjs.org`, `github.com`). Agent
  bekommt `HTTPS_PROXY`-env. Echt wirksam, aber großes Feature:
  Proxy-Container, Allowlist als Copier-Antwort, Test-Coverage, Doku —
  ~300 Zeilen zusätzlicher Template-Code.
