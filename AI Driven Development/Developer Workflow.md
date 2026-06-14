---
Last Modified: 2026-05-20
---
# Philosophie

Kein starrer Prozess, sondern ein Toolkit. Der Workflow besteht aus einzelnen Skills, die situativ eingesetzt werden – nicht als Pflichtschritte in einer festen Reihenfolge.

Jeder Skill hat einen klaren Trigger (wann), einen definierten Input (womit) und einen definierten Output (was rauskommt). Skills lassen sich beliebig kombinieren und überspringen.

---

# Zwei Arbeitsmodi

## Einfache Tasks

Aufgabe unter 2 Stunden, bekannte Codebase, du sitzt selbst am Steuer.

Ablauf: `/explore` (wenn nötig) → `/plan` → direkt umsetzen → `/review`

Kein formales Spec-Dokument, keine Agent-Delegation. Der Overhead wäre größer als der Nutzen.

## Komplexe Tasks

Größeres Feature, unbekannte Codebase, oder Delegation an einen Agenten der autonom arbeitet.

Ablauf: `/explore` → `/spec` → `/plan` → `/test` → `/delegate` → `/review` → `/capture`

Nicht alle Schritte sind immer nötig. Die Entscheidung liegt beim Entwickler. Der Workflow zwingt nicht – er strukturiert.

**Faustregel:** Wenn du jeden Commit selbst reviewst und keinen Agenten autonom laufen lässt, brauchst du den vollen Ablauf nicht.

---

# Drei Betriebsarten

**Solo** – du implementierst selbst, AI als Gesprächspartner und Reviewer.

**Hybrid (Status Quo)** – du führst die Planung, ein Agent übernimmt Teile der Implementierung unter deiner Aufsicht. Das ist der primäre Modus, den dieser Workflow optimieren soll.

**Delegiert** – du lieferst eine vollständige Spec und einen Plan, der Agent arbeitet autonom bis zur Review.

---

# Die 8 Skills

| Skill | Trigger | Output |
|---|---|---|
| `/explore` | Codebase oder Bereich verstehen | Betroffene Dateien, Patterns, offene Fragen |
| `/spec` | Feature oder komplexe Aufgabe definieren | Requirements, Akzeptanzkriterien, Edge Cases, Out of Scope |
| `/plan` | Implementierung strukturieren | Geordnete Schritte, Abhängigkeiten, Spec-Referenz |
| `/test` | Tests aus Spec ableiten | Testfälle mit Assertions, geordnet nach Kriterien |
| `/delegate` | Aufgabe an Agenten übergeben | Agent-Bundle: Spec, Plan, Tests, Kontext, Constraints |
| `/review` | Änderungen prüfen | Checkliste, Abweichungen, offene Punkte |
| `/debug` | Fehlerursache finden | Hypothesen, Diagnoseschritte, identifizierte Ursache |
| `/capture` | Learnings sichern | Eintrag in CONVENTIONS.md oder AGENTS.md |

## Wie Skills zusammenwirken

`/plan` ersetzt `/spec` für kleine Tasks und zerlegt eine Spec für große Tasks in Schritte. Kein separater Breakdown-Schritt nötig.

`/delegate` konsumiert den Output von `/spec` und `/plan`. Ohne diese Grundlage erfindet der Agent Lücken selbst.

`/capture` ist kein Anhang von `/review`. Es ist ein eigenständiger Schritt, weil Learnings sonst verloren gehen.

---

# Feedback-Schleifen

Beim Schreiben einer Spec können Wissenslücken auftauchen, die einen Schritt zurück zu `/explore` erfordern. Das ist kein Fehler, sondern Teil des Prozesses.

Wenn ein Agent während der Implementierung feststellt, dass die Spec einen Fall nicht abdeckt: Stop, zurück zu `/spec`, nicht improvisieren.

---

# Drei Achsen — was du dir merken musst

Der Workflow lebt auf drei **orthogonalen** Achsen. Aktiv merken musst du dir nur die ersten beiden:

- **Skills (das WAS):** 8 Verben — `/explore`, `/spec`, `/plan`, `/test`, `/delegate`, `/review`, `/debug`, `/capture`. Single Source of Truth, tool-agnostisch.
- **Modes (das WO):** 2 OpenCode-Primaries, zwischen denen du per Tab switchst — `plan` und `build`.
- **Subagents (das WIE):** ≤3, werden von den Primaries **automatisch gespawnt** — nicht deine Merkfläche.

> „plan" bezeichnet bewusst zwei Dinge auf zwei Achsen: das `/plan`-**Skill** (Verb) und den `plan`-**Mode** (Architect-Sitz). Es gibt keinen `planner`-Subagent.

# Agent-Rollen → OpenCode-Mapping

Die vier Rollen sind tool-agnostisch; in OpenCode konkret besetzt durch:

| Rolle | Aufgabe | OpenCode-Agent | Skills |
|---|---|---|---|
| **Architect** | Plant, spezifiziert, reviewed. Implementiert nie. | `plan` (primary / Mode) | explore, spec, plan, review |
| **Coder** | Implementiert strikt nach Spec. | `build` (primary / Mode) | test, delegate, debug |
| **Explorer** | Read-only Codebase-Analyse, kontext-isoliert. | `researcher` (subagent) | explore |
| **Scribe** | Sichert Learnings. | — kein stehender Agent — `/capture`-Skill + SessionEnd-Hook | capture |

Zusätzlich on-demand gespawnt: `reviewer` (unabhängiges read-only-Review, von `plan` bei `/review`) und `security-auditor` (Spezial-Checkliste, v.a. im autonomen Modus). Details: [[Skill-Agent-Mappings]] und die OpenCode-[`Agents/README`](CLI-Tools/OpenCode/Agents/README.md). Begründung der Verschlankung: [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]].

In **Claude Code** sind dieselben Rollen anders besetzt (kein Custom-Primary-Konzept):

| Rolle | Claude Code | Skills |
|---|---|---|
| **Architect** | **Plan Mode** (`Shift+Tab`, read-only) | explore, spec, plan, review |
| **Coder** | **Default-Agent** | test, delegate, debug |
| **Explorer** | `researcher`-Subagent (oder Built-in `Explore`) | explore |
| **Scribe** | — `/capture`-Skill + `SessionEnd`-Hook | capture |

Details: [[MOC - Agentic-SWE - Claude Code]] und die Claude-Code-[`Agents/README`](CLI-Tools/Claude-Code/Agents/README.md).

---

# Tooling-Anker

Dieser Workflow ist tool-agnostisch, wird aber primär gegen folgende Stack-Wahl umgesetzt:

- **Orchestrator CLI:** OpenCode
- **Cloud-Modelle:** Über zentralen LiteLLM-Proxy (firmenseitig, nicht selbst betrieben)
- **Lokale Modelle:** Direkt gegen Ollama (`localhost:11434/v1`), inkl. Ollama Cloud via `:cloud`-Suffix
- **SDD-Framework:** OpenSpec als Default (Brownfield/Pipeline-Iteration), Spec-Kit für Greenfield — siehe [[SDD - Tool-Empfehlungen]] in `Spec Driven Development/`
- **Best-Practice-Bundles:** Pro Tool ein eigenes Memory-Set — `CLI-Tools/Claude-Code/claude-config/` für Claude Code, `CLI-Tools/OpenCode/Config-Files/` für OpenCode
- **Autonomer Modus:** Spezial-Setup unter `Autonomer Coding Agent/`
