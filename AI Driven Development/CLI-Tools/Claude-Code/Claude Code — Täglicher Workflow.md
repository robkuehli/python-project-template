---
title: "Claude Code — Täglicher Workflow"
last_verified: 2026-05-21
status: current
tags:
  - claude-code
  - workflow
---

# Claude Code — Täglicher Workflow

Wie Claude Code konkret im Arbeitsalltag läuft — vom Profil-Wahl über die Plan→Execute→Verify-Schleife bis zum Wissens-Capture. Setzt das Setup aus [[Claude Code — Setup-Manual]] voraus. Pendant zu [[OpenCode — Täglicher Workflow]].

```table-of-contents
```

---

## 1. Session-Start: Profil wählen

Die erste Entscheidung jeder Session ist das Profil. Faustregel:

| Situation | Profil | Befehl |
|---|---|---|
| Normaler Arbeitstag, gemischter Workload | Balanced | `cc` |
| Komplexe Architektur, harter Bug, kritisches Review | SOTA | `cc-sota` |
| Kundenprojekt mit personenbezogenen Daten | DSGVO | `cc-dsgvo` |

```bash
cd ~/projekte/mein-repo
cc                      # startet interaktive Session im Balanced-Profil
```

Das Profil bleibt für die Session aktiv (es bestimmt das Default-Modell und das Routing). Subagents erben ihr Modell entweder fix (`researcher` = Haiku) oder über `inherit` aus dem aktiven Modell (`reviewer`, `security-auditor`) — Profilwechsel skaliert sie automatisch mit. Details: [[Claude Code — Profil-Spezifikationen]].

**Tipp:** Profil nach Kontext, nicht nach Gewohnheit. Eine 5-Minuten-Bugfix-Session braucht kein SOTA. Eine DSGVO-Kundensession darf *nie* versehentlich in Balanced laufen — `cd` ins Kundenverzeichnis und sofort `cc-dsgvo`.

---

## 2. Die Kern-Schleife: Plan → Execute → Verify

Für alles, was nicht trivial ist. In Claude Code spielen sich „Plan" und „Execute" nicht in zwei Custom-Agents ab, sondern über den **Plan Mode** und den **Default-Agent** desselben Threads.

### Plan (Architect-Sitz = Plan Mode)

Mit `Shift+Tab` in den **Plan Mode** wechseln (read-only — Claude darf erkunden und planen, aber nichts schreiben):

```
> [Plan Mode] Wir brauchen einen idempotenten Upsert für die dim_customer-Tabelle.
  Quelle ist ein täglicher Full-Load aus Salesforce. Nutze das /spec- und /plan-Skill.
```

Claude recherchiert (delegiert intern an den Built-in `Plan`-Subagent), liefert dann den Plan: Goal · In Scope · Out of Scope · Approach mit Trade-offs · Risks · Verification · Open Questions. **Offene Fragen zuerst klären.** Mit `Shift+Tab` zurück, dann Freigabe.

### Execute (Coder-Sitz = Default)

Im Default-Modus die freigegebene Spec/den Plan umsetzen:

```
> Implementiere den Plan. Halte den Diff klein, eine logische Änderung pro Commit. Nutze /test.
```

Bei breitem Recon-Bedarf nicht selbst den Kontext zumüllen, sondern delegieren:

```
> Use the researcher subagent to map all call sites of load_dim_customer before we touch it.
```

### Verify

Verifikation ist der wertvollste Schritt — niemals überspringen:

```bash
make check          # pre-commit + pytest
```

Dann unabhängiges Review durch den Subagent (frischer Kontext, read-only):

```
> Use the reviewer subagent on the current diff.
```

`reviewer` prüft gegen Spec, Konventionen, Security und gibt ein Verdict: ship / fix-then-ship / needs-rework. Erst danach committen.

---

## 3. Subagent-Delegation im Alltag

Subagents halten den Hauptkontext sauber und nutzen das passende Modell für die Teilaufgabe. Claude delegiert oft automatisch anhand der `description`; explizit geht es über natürliche Sprache oder `@agent-<name>`.

```
> Use the researcher subagent to find every place we read SALESFORCE_TOKEN.
> @agent-reviewer look at the diff before we merge.
> Use the security-auditor subagent over the auth module before we merge.
```

Wann delegieren statt selbst machen:

- **Read-heavy Recon** → `researcher` (Haiku, isolierter Kontext) — oder der Built-in `Explore`-Agent für schnelle Lookups.
- **Verifikation** → `reviewer` (unabhängig, read-only) bzw. `security-auditor` (Security-Pass).
- **Tests / Debugging / Refactoring** → kein eigener Subagent — im Default-Modus die Skills `/test`, `/debug` nutzen.
- **Git / Doku / Learnings** → direkt im Default-Modus (`/capture` für Learnings; Commit-Konventionen in `CLAUDE.md`).

> **Verbose-Output isolieren:** Test-Runs, Doc-Fetches, Log-Analysen produzieren viel Output. An einen Subagent delegieren, der nur die relevante Zusammenfassung zurückgibt — die Verbose-Ausgabe bleibt in dessen Kontext. Subagents können **keine** weiteren Subagents spawnen.

Bei hoher Kontext-Auslastung (siehe `CLAUDE.md` Kontext-Management): `/compact` bei ~70 %, `/clear` bei Themenwechsel; Sub-Tasks aktiv an Subagents auslagern statt im Main-Thread weiterzuwühlen.

---

## 4. Profilwechsel mitten im Tag — typische Anlässe

```bash
# Bug, der sich gegen Sonnet wehrt → kurz auf SOTA hochziehen
cc-sota
> /debug — race condition in the async batch writer, three attempts in Balanced failed.

# Alternativ ohne Session-Wechsel: nur das Modell hochziehen
> /model opus

# Kunde ruft an, du springst ins DSGVO-Projekt
cd ~/kunden/foo-bank
cc-dsgvo

# Routine-Coding in SOTA wieder günstiger machen
> /model sonnet
```

Nichts geht verloren: Specs, Pläne und Status liegen als `*.md` im Repo. Eine neue Session liest sie über `CLAUDE.md`/`@`-Importe wieder ein.

> **Mode vs. Modell:** Plan Mode (`Shift+Tab`) und das aktive Modell (`/model`) sind orthogonal. SOTA-Architektur = Plan Mode **auf Opus**. Routine-Coding = Default-Modus auf Sonnet. Innerhalb einer SOTA-Session kannst du jederzeit per `/model` zwischen Opus (Reasoning) und Sonnet (Implementierung) wechseln.

---

## 5. Session-Ende: Wissen capturen

Learnings werden halbautomatisch gesichert — das ist der **Self-Improvement Loop** (Inbox-Pattern, siehe [[Review - Agentic-SWE Setup, Skills & Learning-Automatisierung (2026-05-21)]] §6):

1. **Automatisch beim Session-Ende:** der `SessionEnd`-Hook (`~/.claude/hooks/capture-learnings.sh`) liest das Transkript, ruft ein günstiges „Scribe"-Modell (Haiku) und hängt Vorschläge als `[ ] proposed` an `LEARNINGS.inbox.md` (Staging, nicht im Kontext).
2. **Beim nächsten Start:** der `SessionStart`-Hook (`surface-inbox.sh`) erinnert an offene Vorschläge.
3. **Manuell bestätigen:** `/capture review` promotet die guten Vorschläge nach `~/.claude/LEARNINGS.md`. Nur dieser Schritt schreibt in die Wahrheit → Schutz vor Müll. Manuelle Einzelerfassung bleibt: `/capture <thema>`.

Format in `~/.claude/LEARNINGS.md` (eingebunden via `@~/.claude/LEARNINGS.md` in `CLAUDE.md`):

```markdown
<!-- 2026-05-20 | foo-bank-dwh | dbt incremental ohne unique_key macht silent full-refresh -->
- Bei incremental models IMMER unique_key setzen und mit `dbt run --full-refresh false` gegenprüfen.
```

Faustregel: Jeder vermeidbare Fehler wird **einmal** als LEARNINGS-Zeile dokumentiert — nicht als flüchtiges In-Session-Feedback, das die nächste Session vergisst. So sinkt die Fehlerwiederholung über alle künftigen Sessions und Projekte (*compounding engineering*).

> Optional: Subagent-Memory (`memory: project` im Subagent-Frontmatter) gibt z.B. dem `reviewer` ein persistentes Notizverzeichnis, das über Sessions wächst. Bewusst sparsam einsetzen — siehe [[Claude Code — Best Practices]] §6.

---

## 6. Verdichtung: LEARNINGS → Best Practices

Periodisch (z.B. monatlich) die `LEARNINGS.md` durchgehen:

- Wiederkehrende Muster → in [[Claude Code — Best Practices]] als Pattern aufnehmen.
- Projekt-spezifische Lessons → in die jeweilige Projekt-`CLAUDE.md` verschieben.
- Veraltete Einträge (Tool-Bug gefixt, Workaround obsolet) → streichen.

Das hält `LEARNINGS.md` schlank und das **Instruction-Budget** unter Kontrolle (CLAUDE.md + LEARNINGS unter ~200 Zeilen halten; jede Zeile muss die Frage „würde Claude ohne sie einen Fehler machen?" mit ja beantworten).

---

## 7. Ein typischer Tag, verdichtet

```bash
# 09:00 — Feature-Arbeit
cd ~/projekte/pipeline && cc
> [Plan Mode] /spec + /plan für neuen Ingest-Task → Freigabe
> [Default] /test, implementieren, make check, reviewer-Subagent, commit

# 11:30 — hartnäckiger Bug
cc-sota
> /debug … root cause, Regression-Test, fix       (/model sonnet für die Implementierung)

# 14:00 — Kundentermin-Vorbereitung (DSGVO)
cd ~/kunden/bank && cc-dsgvo
> researcher-Subagent … bestehende Auth-Flows mappen
> security-auditor-Subagent … vor dem Merge

# 17:30 — Doku & Abschluss
> [Default] README für das neue Modul; /capture für Learnings

# Session-Ende: SessionEnd-Hook schlägt Learnings vor → nächste Session: /capture review
```

---

## Querverweise

- [[Claude Code — Setup-Manual]] — Installation und Aliase
- [[Claude Code — Best Practices]] — Pattern, Sicherheit, Mechaniken
- [[Claude Code — Profil-Spezifikationen]] — Modellwahl pro Profil/Subagent
- [Agents/](./Agents/) — Rollen und Tool-Sets der Subagents
- `../../Autonomer Coding Agent/04-escalation.md` — Eskalation lokal → Cloud
