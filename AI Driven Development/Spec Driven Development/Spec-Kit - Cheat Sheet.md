---
tags:
  - docnote
  - sdd
  - spec-kit
  - cheatsheet
Creation Date: 2026-05-20
Last Modified: 2026-05-20
Finished: true
---

# Spec-Kit — Cheat Sheet (Greenfield)

> [!info] Use-Case
> Greenfield: neues Projekt von Null, neues Modul, strukturierter Aufbau gewünscht. Bei Brownfield: → [[OpenSpec - Cheat Sheet]].

## 1. Init (einmal pro Projekt)

```bash
specify init my-project --ai claude
cd my-project
specify check
```

> [!warning] `uv` als Prereq
> Bei `command not found: uv`: `curl -LsSf https://astral.sh/uv/install.sh | sh`. Python 3.11+ wird ebenfalls verlangt.

## 2. Constitution setzen (einmalig)

```
/speckit.constitution
```

Architektur-Leitplanken im Dialog definieren — z.B. Eval-Pflicht, Embedding-Pinning, TDD-Verpflichtung. Landet in `.specify/memory/constitution.md`.

> [!tip] Constitution-Verweis in `CLAUDE.md` nachpflegen
> Sonst zieht der Agent sie nicht automatisch. Siehe [[Spec-Kit - Setup]] §Memory-Architektur.

## 3. Feature-Loop (pro Feature)

```
/speckit.specify     # legt Branch + spec.md an (Was & Warum, KEINE Tech-Details)
/speckit.clarify     # Edge Cases, niemals überspringen
/speckit.plan        # plan.md + research.md + data-model.md
/speckit.tasks       # tasks.md mit [P]-Markern und Dateipfaden
/speckit.analyze     # Konsistenz-Check über alle Artefakte
/speckit.implement   # TDD-Loop, Tasks abarbeiten
```

> [!warning] `/speckit.clarify` ist der Schritt mit dem größten Impact
> Ambiguitäten = #1 Fehlergrund. Jede AI-Annahme durch explizite Entscheidung ersetzen.

> [!warning] `research.md` manuell prüfen
> Spec-Kit promptet oft Lib-Versionen, die ein paar Monate alt sind. Bei LangChain, llama-index, dbt besonders aufpassen.

> [!warning] `/speckit.analyze` ist nicht optional
> Vor `implement` ausführen, Findings adressieren, erneut analysieren bis grün. Größter Mehrwert ggü. manuellem SDD.

## 4. Review + Learnings (nach Implement)

```
# Separater Agent, eigene Session:
Reviewe Branch <feature> gegen .specify/specs/<feature>/spec.md
→ Findings + Learnings zurück in spec.md
→ CHANGELOG.md aktualisieren
```

> [!danger] Niemals den implementierenden Agent self-reviewen lassen
> Confirmation Bias. Neue Session oder Sub-Agent (`/agents review-against-spec`).

## Artefakt-Hierarchie

```
.specify/
├── memory/constitution.md          ← Leitplanken
└── specs/NNN-feature/
    ├── spec.md                     ← Was & Warum
    ├── plan.md                     ← Wie
    ├── research.md                 ← Lib-Validierung (manuell prüfen!)
    ├── data-model.md               ← Contracts, Schemas
    └── tasks.md                    ← Atomare Tasks, [P] = parallel
```

## Konflikt-Hierarchie (bei Widersprüchen)

```
Constitution > Spec > Plan > Tasks > Code
```

## Update

```bash
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git
specify version
```

→ Vollständiger Workflow: [[Spec-Kit - Workflow]] · Setup: [[Spec-Kit - Setup]]
