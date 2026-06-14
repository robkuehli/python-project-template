# Spec-Workflow & SDD-Challenge

**Status:** Draft v1 (2026-05-21)
**Bezug:** ADR-004 (Spec-Kit gewählt), ADR-014 (gestuft), `Spec Driven Development/SDD - Tool-Empfehlungen.md`

---

## Macht Spec-Driven Development hier überhaupt Sinn? (die Challenge)

Kurz: **ja — aber nicht der volle Zeremonien-Stack für jeden PoC.** Die ehrliche Differenzierung:

**Wofür SDD bei einem autonomen lokalen Agenten zwingend ist.** Ein autonomer Agent hat keinen Menschen, der mitten im Lauf eine Lücke klärt. Genau das macht eine präzise, *test-bare* Spec hier wertvoller als im interaktiven Alltag: Die Akzeptanzkriterien sind das einzige, woran der Agent (und das Verify-Gate) „fertig" festmachen kann. Eine vage Spec führt direkt zu Drift oder zu Code, der nicht prüfbar ist. Das ist kein SDD-Ritual, sondern die Grundlage, auf der das `.green`-Gate (ADR-005) überhaupt funktioniert. Karpathys Beobachtung zur „vibe coding"-Grenze gilt verschärft: ohne Spec ist autonomes Bauen ein Glücksspiel, mit Spec wird es ein begrenzter, prüfbarer Auftrag.

**Wo SDD zum Overhead wird.** Der volle Spec-Kit-Cascade (`constitution → specify → clarify → plan → tasks → analyze → implement`, ~800 Zeilen Multi-Artefakt) ist für einen 2-Datei-CLI-PoC teurer als der PoC selbst. Die projekteigene Analyse zitiert das wörtlich: Spec-Kit lohnt für *medium-to-large greenfield*, nicht für *small features / quick prototypes* (Hashrocket 2026; Spec-Kit-Discussion #1536). Den vollen Stack auf jeden Mini-PoC zu zwingen, wäre genau die „Test-Depression"-Falle, nur für Specs.

**Die Konsequenz (ADR-014): gestuft.**

| PoC-Größe | Spec-Form | Begründung |
|---|---|---|
| 1–3 Dateien, klares Pattern | **Lite-Spec** (`scaffold/templates/spec.lite.md`) | Ziel + Constraints + test-bare AKs + Out-of-Scope + ein I/O-Beispiel. Genug gegen Drift, kein Kaskaden-Overhead. |
| ~4–7 Dateien, MVP | **Voller Spec-Kit-Flow** | Architektur-Sorgfalt zahlt sich aus; `plan.md`/`tasks.md` als reviewbare Artefakte; eingebaute TDD-Erzwingung. |
| Brownfield-Iteration | **(nicht dieser Agent)** | OpenSpec-Domäne; der autonome Agent ist Greenfield. |

Warum Spec-Kit und nicht OpenSpec: Greenfield ist genau Spec-Kits Sweet Spot, OpenSpec ist brownfield-first (Delta-Specs auf einer living Master-Spec) — das passt zur Pipeline-Iteration im Alltag, nicht zum „PoC von Null". Quelle: die eigene `SDD - Tool-Empfehlungen.md`.

## Dein Workflow: Spec schreiben → übergeben → laufen lassen

```
abends (~15–30 min, du):
  1. Größe einschätzen → Lite-Spec ODER Spec-Kit-Flow
     Lite:     cp templates/spec.lite.md  spec.md  und ausfüllen
     Spec-Kit: specify init . ; /speckit.specify ; /speckit.clarify ; /speckit.plan ; /speckit.tasks
  2. constitution prüfen (templates/constitution.md → .specify/memory/) — Stack-Verbote für DIESEN PoC?
  3. git commit -m "chore: spec"     (Snapshot der Spec)

dann (autonom, Maschine):
  4. run-agent.sh ~/agent-projects/mein-poc

morgens (~30–60 min, du):
  5. Notification → Diff + Tests gegenlesen → polishen
```

Die Spec ist die **Schnittstelle** zwischen dir und dem Agenten. Alles, was du nicht in `spec.md`/`constitution.md` schreibst, erfindet der Agent (dokumentiert in `DECISIONS.md`) — manchmal gut, manchmal nicht. Investiere die Mühe in präzise, test-bare Akzeptanzkriterien; das ist der Hebel mit der höchsten Wirkung auf die nächtliche Erfolgsquote.

## Was eine gute autonome Spec ausmacht (Checkliste)

- **Akzeptanzkriterien als Verhalten am public contract**, nicht als Implementierungs-Vorgaben (deckt sich mit den Testing-Guidelines: „Wenn X, dann beobachtbares Y").
- **Out-of-Scope explizit** — der wirksamste Schutz gegen Scope-Creep eines autonomen Agenten.
- **Mindestens ein konkretes I/O-Beispiel pro Hauptpfad** — reduziert Halluzination drastisch.
- **Stack-Constraints in der constitution**, nicht in der Spec verstreut — eine Quelle der Wahrheit.
- **Realistischer Scope:** Brief Abschnitt 6 — ein 5–7-Datei-MVP gelingt lokal in ~25 % der Einzelversuche; halte den Scope klein genug, dass 3 Versuche + Eskalation eine echte Chance haben.

## SDD-Tool-Setup

Detaillierte Anleitungen liegen schon im Projekt: `Spec Driven Development/Spec-Kit - Setup.md` und `… - Workflow.md`. Für den autonomen Agenten relevant: Spec-Kit erzeugt Markdown-Artefakte, die der Worker im Worktree liest (`spec.md`, `plan.md`, `tasks.md`) — kein Tool-Lock-in zur Laufzeit, der Agent braucht nur die Dateien.

## Querverweise

- `02-adrs.md` ADR-004, ADR-014
- `Spec Driven Development/SDD - Tool-Empfehlungen.md` (Greenfield → Spec-Kit)
- `scaffold/templates/spec.lite.md`, `scaffold/templates/constitution.md`
- `Guidelines/Testing Guidelines (AI Agent).md` (Akzeptanzkriterien → Tests)
