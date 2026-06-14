## Agents

Vier tool-agnostische Rollen. In OpenCode konkret besetzt durch 2 Primaries (`plan`/`build`, die Modes) + 2 on-demand-Subagents (`researcher`/`reviewer`) + `security-auditor` (autonomer Modus). Aktiv merken: nur die zwei Modes.

| Rolle | OpenCode-Agent | Rolle/Aufgabe | Modell-Tier | Tools |
|---|---|---|---|---|
| **Architect** | `plan` (primary) | Plant, spezifiziert, reviewed. Implementiert nie. | Stark (Opus / Sonnet) | Read, Grep, Glob, Write (nur Spec/Doc-`.md`) |
| **Coder** | `build` (primary) | Implementiert strikt nach Spec, schreibt Tests. | Coding-optimiert (Sonnet / GPT-5) | Read, Write, Edit, Bash, Glob, Grep |
| **Explorer** | `researcher` (subagent) | Read-only Codebase-Analyse, kontext-isoliert. | Schnell & günstig (Haiku / Qwen) | Read, Grep, Glob (kein Write, kein Bash) |
| **Scribe** | — `/capture`-Skill + SessionEnd-Hook — | Sichert Learnings (Inbox → Promote). | günstig/lokal (Haiku / Llama) | Append an LEARNINGS.inbox.md |

> Entfernt (2026-05-21, aggressiv verschlankt): `planner`, `debugger`, `refactorer`, `docs-writer`, `test-generator`, `git-helper` — reine Skill-Doppelungen ohne Isolations-/Tool-Mehrwert. Siehe [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]].

---

## Skills

| Skill | Trigger | Output | Beschreibung |
|---|---|---|---|
| `/explore` | „Ich verstehe diesen Bereich nicht" | Betroffene Dateien, Patterns, offene Fragen | Systematische Read-only-Analyse eines Codebase-Bereichs |
| `/spec` | „Ich muss ein Feature definieren" | Requirements, AC, Edge Cases, Out of Scope, Wissenslücken | Vollständige Spec für komplexe Tasks oder Features |
| `/plan` | „Wie gehe ich das an?" | Geordnete Schritte, Abhängigkeiten, Spec-Referenz | Leichtgewichtig für kleine Tasks; zerlegt eine Spec für große Tasks |
| `/test` | „Ich brauche Tests aus dieser Spec" | Testfälle mit Assertions, nach Akzeptanzkriterien geordnet | Leitet Tests direkt aus Spec oder Anforderung ab |
| `/delegate` | „Das soll ein Agent autonom umsetzen" | Agent-Bundle: Spec + Plan + Tests + Kontext + Constraints | Vollständiges Übergabepaket für autonome Agentenarbeit |
| `/review` | „Ich will die Änderungen prüfen" | Checkliste gegen Akzeptanzkriterien, Abweichungen, offene Punkte | Prüft gegen Spec, nicht nach freiem Urteil |
| `/debug` | „Etwas funktioniert nicht" | Hypothesen, Diagnoseschritte, Ursache | Systematisch statt raten |
| `/capture` | „Ich habe etwas gelernt" | CONVENTIONS.md / AGENTS.md Eintrag | Sichert Learnings für zukünftige Tasks |

---

## Skill → Agent Mapping

| Skill | Primärer Agent | Begründung |
|---|---|---|
| `/explore` | Explorer | Read-only, günstig, schnell – kein starkes Modell nötig |
| `/spec` | Architect | Erfordert strukturiertes Denken, Vollständigkeit, kein Improvisation |
| `/plan` | Architect (komplex) / Coder (einfach) | Für einfache Tasks reicht der Coder; für Architekturentscheidungen der Architect |
| `/test` | Coder | Tests sind Implementierungsarbeit, kein Architekturthema |
| `/delegate` | Coder | Implementierung ist Coder-Territory; Spec kommt vom Architect |
| `/review` | Architect | Review gegen Spec erfordert dasselbe Denkniveau wie die Spec-Erstellung |
| `/debug` | Coder | Debugging ist Implementierungsarbeit |
| `/capture` | Scribe | Einfache Dokumentationsaufgabe, lokales Modell ausreichend |

---

## Abhängigkeiten zwischen Skills

```
/explore  ──────────────────────────────────────────────────
                                                            │
/spec  ←── /explore (bei Wissenslücken zurück)             │
  │                                                         │
/plan  ←── /spec (für große Tasks)                         │
  │      └─ direkt (für kleine Tasks ohne Spec)            │
  │                                                         │
/test  ←── /spec oder /plan                                │
  │                                                         │
/delegate ←── /spec + /plan + /test                        │
  │                                                         │
/review ←── /delegate output                               │
  │                                                         │
/capture ←── /review (bei Learnings)                       │
                                                            │
/debug  ────────────────────────────────────────────────────
  (kann jederzeit unabhängig eingesetzt werden)
```
