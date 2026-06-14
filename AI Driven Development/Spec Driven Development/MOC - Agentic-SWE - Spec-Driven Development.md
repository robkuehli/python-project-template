---
tags:
  - moc
  - sdd
Creation Date: 2026-05-20
Last Modified: 2026-05-20
---

# Spec-Driven Development

Dieser Ordner bündelt Robins Arbeitsweise mit Spec-Driven Development (SDD): den Ansatz, die Spezifikation eines Features zur Single Source of Truth zu machen, *bevor* implementiert wird.

## Inhalt

| Datei | Inhalt |
|---|---|
| [[SDD - Einleitung]] | Was SDD ist, wann es sich lohnt, kritische Betrachtung |
| [[SDD - Best Practices]] | Was 2026 in der Praxis funktioniert, toolunabhängig |
| [[SDD - Tool-Empfehlungen]] | Spec-Kit vs. OpenSpec, Entscheidungskriterien |
| [[Spec-Kit - Setup]] | Installation und Initialisierung |
| [[Spec-Kit - Workflow]] | End-to-End-Ablauf mit Spec-Kit |
| [[Spec-Kit - Cheat Sheet]] | Tägliche Schnellreferenz (Greenfield-Default) |
| [[OpenSpec - Setup]] | Installation und Initialisierung |
| [[OpenSpec - Workflow]] | End-to-End-Ablauf mit OpenSpec |
| [[OpenSpec - Cheat Sheet]] | Tägliche Schnellreferenz (Brownfield-Default) |

## Lese-Reihenfolge

1. [[SDD - Einleitung]] — Konzept und Use-Case-Abgrenzung verstehen
2. [[SDD - Tool-Empfehlungen]] — entscheiden, welches Tool für die nächste Aufgabe passt
3. Tool-spezifisch: Setup → Workflow
4. [[SDD - Best Practices]] — als Referenz beim Arbeiten
5. Im Alltag: [[Spec-Kit - Cheat Sheet]] / [[OpenSpec - Cheat Sheet]] als Schnellreferenz

## Tool-Empfehlung in einem Satz

**OpenSpec für Brownfield-Iteration auf bestehenden Pipelines/Codebases (Default für Data Engineering), Spec-Kit für strukturierte Greenfield-Projekte (typisch in AI Engineering).**

Beide werden ✅ established gepflegt — siehe [[SDD - Tool-Empfehlungen]] für die Detailbegründung.

## Verzahnung mit dem Rest des Workspaces

- [[Developer Workflow]] — definiert die übergreifenden Skills und Modi. SDD ist die Ausarbeitung der Spec-Phase darin.
- [[MOC - Agentic-SWE - Guidelines]] — Code- und Test-Konventionen, gegen die SDD-Artefakte validiert werden.
- [[MOC - Agentic-SWE - Recherchen und Analysen]] — tagesaktuelle Tool-Recherchen, wenn sich an OpenSpec oder Spec-Kit etwas Substanzielles ändert.
