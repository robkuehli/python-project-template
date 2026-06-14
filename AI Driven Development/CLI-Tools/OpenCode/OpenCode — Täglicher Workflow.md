---
title: "OpenCode — Täglicher Workflow"
last_verified: 2026-05-20
status: current
tags:
  - opencode
  - workflow
---

# OpenCode — Täglicher Workflow

Wie OpenCode konkret im Arbeitsalltag läuft — vom Profil-Wahl über die Plan→Execute→Verify-Schleife bis zum Wissens-Capture. Setzt das Setup aus [[OpenCode — Setup-Manual]] voraus.

```table-of-contents
```

---

## 1. Session-Start: Profil wählen

Die erste Entscheidung jeder Session ist das Profil. Faustregel:

| Situation | Profil | Befehl |
|---|---|---|
| Normaler Arbeitstag, gemischter Workload | Balanced | `oc` |
| Komplexe Architektur, harter Bug, kritisches Review | SOTA | `oc-sota` |
| Kundenprojekt mit personenbezogenen Daten | DSGVO | `oc-dsgvo` |
| Offline, Kosten-Null, Open-Weight-Experiment | Ollama | `oc-ollama` |

```bash
cd ~/projekte/mein-repo
oc                      # startet interaktive Session im Balanced-Profil
```

Das Profil bleibt für die ganze Session aktiv. Subagents erben ihre Modelle aus dem geladenen Profil. Profilwechsel = Session beenden, anderen Alias starten.

**Tipp:** Profil nach Kontext, nicht nach Gewohnheit. Eine 5-Minuten-Bugfix-Session braucht kein SOTA. Eine DSGVO-Kundensession darf *nie* versehentlich in Balanced laufen — `cd` ins Kundenverzeichnis und sofort `oc-dsgvo`.

---

## 2. Die Kern-Schleife: Plan → Execute → Verify

Für alles, was nicht trivial ist:

### Plan

In den `plan`-Mode wechseln (Primary Agent, schreibt nur Specs, implementiert nie):

```
> /plan
> Wir brauchen einen idempotenten Upsert für die dim_customer-Tabelle.
  Quelle ist ein täglicher Full-Load aus Salesforce. Schreibe eine Spec.
```

`plan` liefert: Goal · In Scope · Out of Scope · Approach mit Trade-offs · Risks · Verification · Open Questions. **Offene Fragen zuerst klären**, bevor es weitergeht.

### Execute

In den `build`-Mode wechseln und die freigegebene Spec übergeben:

```
> /build
> Implementiere die Spec aus plan/upsert-dim-customer.md. Halte den Diff klein.
```

`build` arbeitet auf einem Feature-Branch, schreibt Code + Tests, hält den Scope eng. Bei breitem Recon-Bedarf delegiert es an `researcher`, statt selbst den Kontext zuzumüllen.

### Verify

Verifikation ist der wertvollste Schritt — niemals überspringen:

```bash
make check          # pre-commit + pytest
```

Dann Review durch den Subagent:

```
> Spawn the reviewer subagent on the current diff.
```

`reviewer` prüft read-only gegen Spec, Konventionen, Security. Verdict: ship / fix-then-ship / needs-rework. Erst danach committen.

---

## 3. Subagent-Delegation im Alltag

Subagents halten den Hauptkontext sauber und nutzen das richtige Modell für die Teilaufgabe. Typische Delegationen:

```
> Spawn the researcher subagent to map every place we read SALESFORCE_TOKEN.
> Spawn the reviewer subagent over the diff before we merge.
> Spawn the security-auditor subagent over the auth module before we merge.
```

Wann delegieren statt selbst machen:

- **Read-heavy Recon** → `researcher` (schnelles Modell, isolierter Kontext)
- **Verifikation** → `reviewer` (unabhängig, read-only) bzw. `security-auditor` (Security-Pass)
- **Tests / Debugging / Refactoring** → kein eigener Subagent — im `build`-Mode die Skills `/test`, `/debug` nutzen
- **Git / Doku / Learnings** → direkt im `build`-Mode (`/capture` für Learnings; Commit-Konventionen in `AGENTS.md`)

Bei > 50 % Kontext-Auslastung (siehe `AGENTS.md` Kontext-Management): aktiv an Subagents auslagern statt im Main-Thread weiterzuwühlen.

---

## 4. Profilwechsel mitten im Tag — typische Anlässe

```bash
# Bug, der sich gegen Sonnet wehrt → kurz auf SOTA hochziehen
oc-sota
> build-Mode, /debug — race condition in the async batch writer,
  three attempts in Balanced failed.

# Kunde ruft an, du springst ins DSGVO-Projekt
cd ~/kunden/foo-bank
oc-dsgvo

# Zug ohne WLAN → lokal weiterarbeiten
oc-ollama
```

Nichts geht verloren: Specs, Pläne und Status liegen als `*.md` im Repo. Eine neue Session im anderen Profil liest sie über `AGENTS.md`/`instructions` wieder ein.

---

## 5. Session-Ende: Wissen capturen

Learnings werden halbautomatisch gesichert — das ist der **Self-Improvement Loop** (Inbox-Pattern, siehe [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]] §6):

1. **Automatisch beim Session-Ende:** das Plugin `learnings-and-guards.ts` (Event `session.idle`) extrahiert Vorschläge und hängt sie als `[ ] proposed` an `LEARNINGS.inbox.md`.
2. **Manuell bestätigen:** `/capture review` promotet die guten Vorschläge nach `~/.config/opencode/LEARNINGS.md`. Nur dieser Schritt schreibt in die Wahrheit → Schutz vor Müll. Manuelle Einzelerfassung bleibt: `/capture <thema>`.

Format in `~/.config/opencode/LEARNINGS.md`:

```markdown
<!-- 2026-05-20 | foo-bank-dwh | dbt incremental ohne unique_key macht silent full-refresh -->
- Bei incremental models IMMER unique_key setzen und mit `dbt run --full-refresh false` gegenprüfen.
```

Faustregel: Jeder Fehler, den OpenCode gemacht hat und der vermeidbar war, wird **einmal** als LEARNINGS-Zeile dokumentiert — nicht als flüchtiges In-Session-Feedback, das die nächste Session vergisst. So sinkt die Fehlerwiederholung über alle künftigen Sessions und Projekte (compounding engineering).

---

## 6. Verdichtung: LEARNINGS → Best Practices

Periodisch (z.B. monatlich) die `LEARNINGS.md` durchgehen:

- Wiederkehrende Muster → in `02-best-practices.md` als Pattern aufnehmen.
- Projekt-spezifische Lessons → in die jeweilige Projekt-`AGENTS.md` verschieben.
- Veraltete Einträge (Tool-Bug gefixt, Workaround obsolet) → streichen.

Das hält `LEARNINGS.md` schlank und das Token-Budget unter Kontrolle (Issue #13188 lässt grüßen).

---

## 7. Ein typischer Tag, verdichtet

```bash
# 09:00 — Feature-Arbeit (plan-Mode = Architect)
cd ~/projekte/pipeline && oc
> plan-Mode: /spec + /plan für neuen Ingest-Task
# Freigabe, Tab zu build:
> build-Mode: /test, implementieren, make check, reviewer-Subagent, commit

# 11:30 — hartnäckiger Bug
oc-sota
> build-Mode: /debug … root cause, Regression-Test, fix

# 14:00 — Kundentermin-Vorbereitung (DSGVO)
cd ~/kunden/bank && oc-dsgvo
> researcher-Subagent … bestehende Auth-Flows mappen
> security-auditor-Subagent … vor dem Merge

# 17:30 — Zugfahrt heim, offline
oc-ollama
> build-Mode: README für das neue Modul; /capture für Learnings

# Session-Ende: Hook schlägt Learnings vor → nächste Session: /capture review
```

---

## Querverweise

- [[OpenCode — Setup-Manual]] — Installation und Aliase
- [[OpenCode — Best Practices]] — Pattern, Sicherheit, Pitfalls
- [[OpenCode — Profil-Spezifikationen]] — Modellwahl pro Profil/Agent
- [`Agents/`](./Agents/) — Rollen und Tool-Sets der Agents
- `../../Autonomer Coding Agent/04-escalation.md` — Eskalation lokal → Cloud
