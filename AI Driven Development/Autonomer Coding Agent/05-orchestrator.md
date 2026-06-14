# Orchestrator & autonomer Loop

**Status:** Draft v1 (2026-05-21)
**Voraussetzung:** `01-project-brief.md`, `02-adrs.md` (insb. ADR-009…014), `scaffold/`
**Löst auf:** den TODO aus `04-escalation.md` (`.green`-Marker, Loop-Spezifikation)

---

## Idee in einem Satz

Du schreibst `spec.md`; der Orchestrator dreht so lange Versuche (erst lokal-parallel, dann budget-gated Cloud), bis ein Versuch das **objektive Gate** (`make check` grün + README) besteht — oder das Cloud-Kontingent aufgebraucht ist.

## Warum ein Bash-Orchestrator und kein Agent-Framework

ADR-007 bleibt gültig: drei Git-Worktrees + Bash + `wait` lösen das Parallelitäts-Problem ohne LangGraph/AutoGen-Komplexität. Der Orchestrator ist bewusst dumm — die Intelligenz steckt im Modell, das Stopp-Kriterium in `make check`. Das ist der Kern, warum das Setup debugbar bleibt: jeder Versuch ist ein eigenes Verzeichnis mit eigenem Log.

## Ablauf

```
            spec.md (+ optional plan.md/tasks.md)
                          │
                    [run-agent.sh]
                          │  preflight · git tag pre-agent-<id>
                          ▼
   ┌──────────────── Phase 1: lokal, parallel ────────────────┐
   │  wt-1            wt-2            wt-3                       │
   │  worktree+sandbox je: opencode run --dangerously-skip-    │
   │  permissions --agent build  (lokales Modell, timeout)     │
   │        │             │             │                       │
   │   verify_gate   verify_gate   verify_gate                  │
   └──────────────────────┬───────────────────────────────────┘
                          │  irgendein .green? ── ja ──► Notify ✓  EXIT 0
                          │  nein
                          ▼
   ┌──────────────── Phase 2: Cloud-Eskalation ───────────────┐
   │  for model in CLOUD_ESCALATION_MODELS:                    │
   │     budget_can_escalate? ── nein ──► Notify "Budget aus"  │
   │     budget_record · run_attempt(cloud) · verify_gate      │
   │        .green? ── ja ──► Notify ✓  EXIT 0                  │
   └──────────────────────┬───────────────────────────────────┘
                          │  alle Modelle/Budget erschöpft
                          ▼
                 Phase 3: aufgeben — Notify, Worktrees+Logs
                 bleiben stehen, DEBUG_HYPOTHESES.md prüfen   EXIT 1
```

## Das `.green`-Marker-Gate (war offener TODO)

Entscheidend: **nicht der Agent erklärt sich fertig, der Orchestrator verifiziert.** Der Agent darf am Ende `.agent-claims-done` schreiben — das ist nur ein Hinweis. Den Marker `.green` setzt ausschließlich `verify_gate` in `lib.sh`, und zwar in einem **frischen** Sandbox-Container:

```bash
docker run … -v "$wt":/workspace:rw \
  bash -lc 'make setup >/dev/null 2>&1 ; make check'
# rc==0  UND  README.md vorhanden  →  touch .green
```

`make check` = `pre-commit run --all-files` (ruff, ruff-format, mypy --strict, gitleaks, interrogate ≥80 %) **plus** `pytest`. Das ist das einzige akzeptierte Done-Kriterium (ADR-005). Frischer Container = keine Zustandsreste aus dem Run, der den PoC gebaut hat.

**Bekannte Lücke (bewusst):** „fake green" — Tests, die das Falsche prüfen — überlebt dieses Gate. Mitigation: `reviewer`-Subagent vor `.agent-claims-done`, optionales Mutation-Testing (`mutmut`) im morgendlichen Review, und der Mensch reviewt die Tests. Kein automatischer Schutz ist hier vollständig.

## Iterations-Grenzen ohne `--max-turns` (ADR-013)

`opencode run` hat **kein** Turn-Limit-Flag. Drei Grenzen ersetzen es:

| Grenze | Mechanik | Default |
|---|---|---|
| Zeit/Versuch | OS-`timeout` um `opencode run` (im Sandbox-Wrapper) | 90 min lokal / 60 min Cloud |
| Versuchszahl | äußere Loop: N parallel lokal + benannte Cloud-Modelle | 3 lokal + 2 Cloud |
| Cloud-Verbrauch | Budget-Kontingent (`budget.sh`) | 4/Tag, 15/Woche |

Innerhalb eines `opencode run` loopt das Modell selbst (Tool-Call → Tool-Call), bis es fertig ist, abbricht oder `timeout` zuschlägt. Schlägt `timeout` zu, fehlt `.green` → gilt als Fehlversuch, sauber.

## Budget (ADR-012)

`budget.sh` führt ein jq-Ledger (`~/.config/agent/cloud-ledger.json`). Vor jeder Cloud-Eskalation: `budget_can_escalate` prüft Tages- + Wochen-Cap. Das ist die Antwort auf „bis das Ollama-Cloud-Budget aufgebraucht ist" — solange Ollama subscription-basiert abrechnet (kein €-Meter, Stand Mai 2026). `budget_report` hängt den Stand an jede Notification.

## Optionale Planner/Reviewer-Schicht (ADR-011)

`PLANNER_REVIEWER=on` → der Orchestrator nutzt `opencode-autonomous-planreview.json` statt des Basis-Profils. Damit laufen `plan`/`reviewer`/`security-auditor` auf einem günstigen Cloud-Open-Weight (Default `gpt-oss:20b-cloud`), während `build` (Worker) lokal bleibt. Default **off** — erst einschalten, wenn die lokale Qualität es rechtfertigt. Jeder Plan-/Review-Call zählt aufs Budget.

## Sub-Agent-Integration (Sub-Agent Development)

Der Worker (`build`) spawnt nach den bestehenden OpenCode-Agent-Definitionen:
- `researcher` (read-only, isoliert) für breite Codebase-/Doku-Recon — hält den Worker-Kontext sauber;
- `reviewer` (read-only, frischer Kontext) für ein unabhängiges Review gegen die Spec, **bevor** `.agent-claims-done` geschrieben wird;
- `security-auditor` (read-only) als Pflicht-Pass am Ende im autonomen Modus (Secrets, Injection, Permissions — relevant gerade weil der Egress offen ist).

Reine Skill-Arbeit (`plan`/`test`/`debug`) ist **kein** Subagent (Review 2026-05-21: Agent-Sprawl vermeiden). Die drei behaltenen Subagents haben echten Mehrwert: Kontext-Isolation, unabhängige Zweitmeinung, Spezial-Checkliste.

## Was du am Morgen tust

1. Notification lesen (Erfolg/Eskalation/Budget/Fehlschlag + Budget-Stand).
2. Bei Erfolg: `git diff pre-agent-<id>` im grünen Worktree, **Tests gegenlesen** (fake-green?), `.agent-egress-audit.log` überfliegen.
3. Bei Fehlschlag: `DEBUG_HYPOTHESES.md` der Worktrees lesen — oft ist die Spec das Problem, nicht das Modell.
4. Worktrees nach dem Review aufräumen: `git worktree remove`.

## Offene Punkte

- [ ] `make setup` im Verify-Container braucht Netz (uv sync) — bei offenem Egress ok, aber Cache-Mount erwägen, um Wiederholungs-Downloads zu sparen.
- [ ] OpenCode-`{env:OLLAMA_BASE_URL}`-Auflösung in `baseURL` praktisch verifizieren (sonst container-lokale Profilkopie).
- [ ] `reviewer`/`security-auditor` im rein-lokalen Modus laufen auf dem 30B-Worker-Modell — Qualität der Self-Review messen; ggf. nur mit `PLANNER_REVIEWER=on` sinnvoll.
- [ ] Mutation-Testing-Pass (`mutmut`) als optionaler vierter Gate-Schritt gegen fake-green.

## Querverweise

- `02-adrs.md` ADR-005 (TDD-Gate), ADR-007 (Worktrees+Bash), ADR-009…014
- `scaffold/orchestrator/` (run-agent.sh, lib.sh, budget.sh, notify.sh)
- `scaffold/sandbox/` (Dockerfile, run-sandbox.sh)
- [OpenCode CLI — opencode.ai/docs/cli](https://opencode.ai/docs/cli/) (Stand 2026-05-21: kein `--max-turns`)
- [Ollama Pricing — ollama.com/pricing](https://ollama.com/pricing)
